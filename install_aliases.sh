

git config --global alias.wt '!f() {
    # Shared function to resolve worktree path with placeholder substitution
    _wt_resolve_worktree_path() {
        local worktree_name="$1"
        local default_path="$2"

        # Get project directory name (basename of git root)
        local project_dir="$(basename "$(git rev-parse --show-toplevel)")"

        # Replace {project_dir} placeholder first, then {worktree_name}
        if [[ "$default_path" == *"{project_dir}"* ]]; then
            local default_path_with_project=$(echo "$default_path" | sed "s/{project_dir}/$project_dir/g")
        else
            local default_path_with_project="$default_path"
        fi

        if [[ "$default_path_with_project" == *"{worktree_name}"* ]]; then
            local worktree_path=$(echo "$default_path_with_project" | sed "s/{worktree_name}/$worktree_name/g")
        else
            default_path_with_project="${default_path_with_project%/}"
            worktree_path="$default_path_with_project/$worktree_name"
        fi

        # Expand ~ to $HOME
        worktree_path="${worktree_path/#\~/$HOME}"

        echo "$worktree_path"
    }

    # Shared function to build worktree name with intelligent input transformation
    _wt_build_worktree_name() {
        local input="$1"

        # 1. Check if already prefixed (e.g., PROJ-123, ABC-123)
        if [[ "$input" =~ ^[A-Z]+-[0-9]+$ ]]; then
            echo "$input"
            return
        fi

        # 2. Check if pure numeric
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            # Read git config (check local, then global)
            local prefix=$(git config worktree.wt.prefix 2>/dev/null || git config --global worktree.wt.prefix 2>/dev/null)
            local pad_digits=$(git config worktree.wt.zeroPadDigits 2>/dev/null || git config --global worktree.wt.zeroPadDigits 2>/dev/null)

            # If not in git config, check MDT
            if [ -z "$prefix" ]; then
                local dot_config="$(git rev-parse --show-toplevel)/.mdt-config.toml"
                if [ -f "$dot_config" ]; then
                    local project_code=$(grep "^code = " "$dot_config" | cut -d"=" -f2 | tr -d " \"")
                    if [ -n "$project_code" ]; then
                        prefix="${project_code}-"
                        pad_digits="${pad_digits:-3}"  # Default to 3 for MDT
                    fi
                fi
            fi

            # Apply zero-padding
            if [ -n "$pad_digits" ]; then
                input=$(printf "%0${pad_digits}d" "$input")
            fi

            # Apply prefix
            if [ -n "$prefix" ]; then
                input="${prefix}${input}"
            fi
        fi

        # 3. Text input (contains letters, no dash-number pattern) - pass through unchanged
        echo "$input"
    }

    worktree_input="$1"

    if [ -z "$worktree_input" ]; then
        echo "Usage: git wt <ticket-number>"
        echo "Example: git wt 101"
        echo "Example: git wt PROJ-101"
        exit 1
    fi

    # Build worktree name using shared function
    worktree=$(_wt_build_worktree_name "$worktree_input")

    # Check new namespace first, fall back to old for migration
    default_path=$(git config worktree.wt.defaultPath 2>/dev/null || git config worktree.defaultPath 2>/dev/null || git config --global worktree.wt.defaultPath 2>/dev/null || git config --global worktree.defaultPath 2>/dev/null)

    if [ -z "$default_path" ]; then
        echo "warning: worktree.wt.defaultPath is not configured" >&2
        echo ""
        echo "This setting defines where worktrees are created. Use placeholders: {worktree_name}, {project_dir}"
        echo "If {worktree_name} is not in the path, it will be appended."
        echo "Examples:"
        echo "  - Relative: .gitWT/{worktree_name}  (creates worktrees inside repo)"
        echo "  - Relative: .gitWT  (worktree_name will be appended: .gitWT/MDT-122)"
        echo "  - Absolute: ~/worktrees/{worktree_name}  (creates worktrees outside repo)"
        echo "  - With project: /worktrees/{project_dir}-{worktree_name}"
        echo "  - Relative: ../{project_dir}_{worktree_name}"
        echo ""
        echo "Placeholders:"
        echo "  - {worktree_name}: The branch/worktree name (e.g., MDT-123)"
        echo "  - {project_dir}: Basename of git repository (e.g., super-mario)"
        echo ""
        echo "To set globally: git config --global worktree.wt.defaultPath \".gitWT/{worktree_name}\""
        echo "To set locally:  git config worktree.wt.defaultPath \"~/worktrees/{worktree_name}\""
        echo ""

        # Support WT_TEST_RESPONSE for automated testing
        local response="${WT_TEST_RESPONSE:-}"
        if [[ -z "$response" ]]; then
            read -p "Set global config to default (.gitWT/{worktree_name})? [Y/n] " response
        fi

        if [[ "$response" =~ ^[Yy]?$ ]] || [ -z "$response" ]; then
            git config --global worktree.wt.defaultPath ".gitWT/{worktree_name}"
            default_path=".gitWT/{worktree_name}"
            echo "Set global worktree.wt.defaultPath to: $default_path"
        else
            worktree_path="$(git rev-parse --show-toplevel)/.gitWT/$worktree"
            parent_dir=$(dirname "$worktree_path")
            [ ! -d "$parent_dir" ] && mkdir -p "$parent_dir"
            git worktree add "$worktree_path" -b "$worktree"
            echo "Created worktree: $worktree_path"
            echo "Branch: $worktree"
            exit 0
        fi
    fi

    # Resolve worktree path using shared function
    worktree_path=$(_wt_resolve_worktree_path "$worktree" "$default_path")

    if [[ "$worktree_path" == /* ]]; then
        relative_flag="--no-relative-paths"
    else
        repo_root="$(git rev-parse --show-toplevel)"
        worktree_path="$repo_root/$worktree_path"
        relative_flag="--relative-paths"
    fi

    if [ -d "$worktree_path" ]; then
        echo "error: Worktree already exists at $worktree_path" >&2
        echo "To remove it: git worktree remove $worktree_path" >&2
        exit 1
    fi

    if git show-ref --verify --quiet "refs/heads/$worktree"; then
        echo "error: Branch \"$worktree\" already exists but has no worktree" >&2
        echo "To create worktree for existing branch: git worktree add $relative_flag \"$worktree_path\" \"$worktree\"" >&2
        exit 2
    fi

    parent_dir=$(dirname "$worktree_path")
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi

    git worktree add $relative_flag "$worktree_path" -b "$worktree"
    echo "Created worktree: $worktree_path"
    echo "Branch: $worktree"
    echo "Using config: worktree.wt.defaultPath = $default_path"
}; f'

git config --global alias.wt-rm '!f() {
    # Shared function to resolve worktree path with placeholder substitution
    _wt_resolve_worktree_path() {
        local worktree_name="$1"
        local default_path="$2"

        # Get project directory name (basename of git root)
        local project_dir="$(basename "$(git rev-parse --show-toplevel)")"

        # Replace {project_dir} placeholder first, then {worktree_name}
        if [[ "$default_path" == *"{project_dir}"* ]]; then
            local default_path_with_project=$(echo "$default_path" | sed "s/{project_dir}/$project_dir/g")
        else
            local default_path_with_project="$default_path"
        fi

        if [[ "$default_path_with_project" == *"{worktree_name}"* ]]; then
            local worktree_path=$(echo "$default_path_with_project" | sed "s/{worktree_name}/$worktree_name/g")
        else
            default_path_with_project="${default_path_with_project%/}"
            worktree_path="$default_path_with_project/$worktree_name"
        fi

        # Expand ~ to $HOME
        worktree_path="${worktree_path/#\~/$HOME}"

        echo "$worktree_path"
    }

    # Shared function to build worktree name with intelligent input transformation
    _wt_build_worktree_name() {
        local input="$1"

        # 1. Check if already prefixed (e.g., PROJ-123, ABC-123)
        if [[ "$input" =~ ^[A-Z]+-[0-9]+$ ]]; then
            echo "$input"
            return
        fi

        # 2. Check if pure numeric
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            # Read git config (check local, then global)
            local prefix=$(git config worktree.wt.prefix 2>/dev/null || git config --global worktree.wt.prefix 2>/dev/null)
            local pad_digits=$(git config worktree.wt.zeroPadDigits 2>/dev/null || git config --global worktree.wt.zeroPadDigits 2>/dev/null)

            # If not in git config, check MDT
            if [ -z "$prefix" ]; then
                local dot_config="$(git rev-parse --show-toplevel)/.mdt-config.toml"
                if [ -f "$dot_config" ]; then
                    local project_code=$(grep "^code = " "$dot_config" | cut -d"=" -f2 | tr -d " \"")
                    if [ -n "$project_code" ]; then
                        prefix="${project_code}-"
                        pad_digits="${pad_digits:-3}"  # Default to 3 for MDT
                    fi
                fi
            fi

            # Apply zero-padding
            if [ -n "$pad_digits" ]; then
                input=$(printf "%0${pad_digits}d" "$input")
            fi

            # Apply prefix
            if [ -n "$prefix" ]; then
                input="${prefix}${input}"
            fi
        fi

        # 3. Text input (contains letters, no dash-number pattern) - pass through unchanged
        echo "$input"
    }

    worktree="$1"

    if [ -z "$worktree" ]; then
        echo "Usage: git wt-rm <ticket-number>"
        echo "Example: git wt-rm 101"
        echo "Example: git wt-rm PROJ-101"
        exit 1
    fi

    # Build worktree name using shared function (same as wt)
    worktree=$(_wt_build_worktree_name "$worktree")

    # Check new namespace first, fall back to old for migration
    default_path=$(git config worktree.wt.defaultPath 2>/dev/null || git config worktree.defaultPath 2>/dev/null || git config --global worktree.wt.defaultPath 2>/dev/null || git config --global worktree.defaultPath 2>/dev/null)

    if [ -z "$default_path" ]; then
        echo "warning: worktree.wt.defaultPath is not configured" >&2
        echo "Using default path: .gitWT/{worktree_name}" >&2
        default_path=".gitWT/{worktree_name}"
    fi

    # Resolve worktree path using shared function
    worktree_path=$(_wt_resolve_worktree_path "$worktree" "$default_path")

    if [[ "$worktree_path" == /* ]]; then
        # Absolute path, use as-is
        :
    else
        # Relative path, convert to absolute from repo root
        repo_root="$(git rev-parse --show-toplevel)"
        worktree_path="$repo_root/$worktree_path"
    fi

    # Check if worktree exists
    if [ ! -d "$worktree_path" ]; then
        echo "error: Worktree not found at $worktree_path" >&2
        echo "Listing existing worktrees:" >&2
        git worktree list
        exit 1
    fi

    # Confirm removal
    echo "Found worktree: $worktree_path"
    echo "Branch: $worktree"
    echo ""

    # Support WT_TEST_RESPONSE for automated testing
    # Reads first line and updates WT_TEST_RESPONSE for sequential prompts
    local response="${WT_TEST_RESPONSE:-}"
    if [[ -n "$response" ]]; then
        # Read first line for current prompt
        response=$(echo "$response" | head -n 1)
        # Update WT_TEST_RESPONSE to remove consumed line for next prompt
        export WT_TEST_RESPONSE=$(echo "${WT_TEST_RESPONSE}" | tail -n +2)
    elif [ "${WT_TEST_RESPONSE+isset}" = "isset" ]; then
        # WT_TEST_RESPONSE is set but empty - treat as "no" to avoid hang in tests
        response="n"
    else
        read -p "Remove worktree and branch? [y/N] " response
    fi

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    # Remove the worktree
    if git worktree remove "$worktree_path"; then
        echo "✓ Removed worktree: $worktree_path"
    else
        echo "error: Failed to remove worktree" >&2
        echo "You may need to manually remove the directory and prune the worktree:" >&2
        echo "  rm -rf \"$worktree_path\"" >&2
        echo "  git worktree prune" >&2
        exit 1
    fi

    # Check if branch is used elsewhere
    if git show-ref --verify --quiet "refs/heads/$worktree"; then
        # Branch exists, check if it has other worktrees
        other_worktrees=$(git worktree list | grep -c "\[$worktree\]")
        if [ "$other_worktrees" -eq 0 ]; then
            # Support WT_TEST_RESPONSE for automated testing
            # Reads first line and updates WT_TEST_RESPONSE for sequential prompts
            local branch_response="${WT_TEST_RESPONSE:-}"
            if [[ -n "$branch_response" ]]; then
                # Read first line for current prompt
                branch_response=$(echo "$branch_response" | head -n 1)
                # Update WT_TEST_RESPONSE to remove consumed line for next prompt
                export WT_TEST_RESPONSE=$(echo "${WT_TEST_RESPONSE}" | tail -n +2)
            elif [ "${WT_TEST_RESPONSE+isset}" = "isset" ]; then
                # WT_TEST_RESPONSE is set but empty - treat as "no" to avoid hang in tests
                branch_response="n"
            else
                read -p "Delete branch \"$worktree\"? [y/N] " branch_response
            fi
            if [[ "$branch_response" =~ ^[Yy]$ ]]; then
                git branch -d "$worktree"
                echo "✓ Deleted branch: $worktree"
            else
                echo "Branch \"$worktree\" kept"
            fi
        fi
    fi

    echo "✓ Worktree removal completed"
}; f'