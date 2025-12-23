git config --global alias.wt '!f() {
    worktree="$1"

    if [ -z "$worktree" ]; then
        echo "Usage: git wt <ticket-number>"
        echo "Example: git wt 101"
        echo "Example: git wt MDT-101"
        exit 1
    fi

    if [[ ! "$worktree" =~ [0-9][0-9][0-9] ]]; then
        echo "error: Must include 3-digit ticket number. E.g. \"123\" or \"MDT-123\"" >&2
        exit 3
    fi

    ticket_number=$(echo "$worktree" | grep -Eo "[0-9][0-9][0-9]")

    # check integration with https://github.com/andkirby/markdown-ticket
    if [[ "$worktree" =~ ^[0-9][0-9][0-9]$ ]]; then
        dot_config="$(git rev-parse --show-toplevel)/.mdt-config.toml"
        if [ -f "$dot_config" ]; then
            project_code=$(grep "^code = " "$dot_config" | cut -d"=" -f2 | tr -d " \"")
            if [ -n "$project_code" ]; then
                worktree="${project_code}-${ticket_number}"
            else
                worktree="${ticket_number}"
            fi
        else
            worktree="${ticket_number}"
        fi
    fi

    # Check local config first, then global
    default_path=$(git config worktree.defaultPath 2>/dev/null || git config --global worktree.defaultPath 2>/dev/null)

    if [ -z "$default_path" ]; then
        echo "warning: worktree.defaultPath is not configured" >&2
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
        echo "To set globally: git config --global worktree.defaultPath \".gitWT/{worktree_name}\""
        echo "To set locally:  git config worktree.defaultPath \"~/worktrees/{worktree_name}\""
        echo ""

        # Support WT_TEST_RESPONSE for automated testing
        local response="${WT_TEST_RESPONSE:-}"
        if [[ -z "$response" ]]; then
            read -p "Set global config to default (.gitWT/{worktree_name})? [Y/n] " response
        fi

        if [[ "$response" =~ ^[Yy]?$ ]] || [ -z "$response" ]; then
            git config --global worktree.defaultPath ".gitWT/{worktree_name}"
            default_path=".gitWT/{worktree_name}"
            echo "Set global worktree.defaultPath to: $default_path"
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

    # Get project directory name (basename of git root)
    project_dir="$(basename "$(git rev-parse --show-toplevel)")"

    # Replace {project_dir} placeholder first, then {worktree_name}
    if [[ "$default_path" == *"{project_dir}"* ]]; then
        default_path_with_project=$(echo "$default_path" | sed "s/{project_dir}/$project_dir/g")
    else
        default_path_with_project="$default_path"
    fi

    if [[ "$default_path_with_project" == *"{worktree_name}"* ]]; then
        worktree_path=$(echo "$default_path_with_project" | sed "s/{worktree_name}/$worktree/g")
    else
        default_path_with_project="${default_path_with_project%/}"
        worktree_path="$default_path_with_project/$worktree"
    fi

    # Expand ~ to $HOME
    worktree_path="${worktree_path/#\~/$HOME}"

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
    echo "Using config: worktree.defaultPath = $default_path"
}; f'

git config --global alias.wt-rm '!f() {
    worktree="$1"

    if [ -z "$worktree" ]; then
        echo "Usage: git wt-rm <ticket-number>"
        echo "Example: git wt-rm 101"
        echo "Example: git wt-rm MDT-101"
        exit 1
    fi

    if [[ ! "$worktree" =~ [0-9][0-9][0-9] ]]; then
        echo "error: Must include 3-digit ticket number. E.g. \"123\" or \"MDT-123\"" >&2
        exit 3
    fi

    ticket_number=$(echo "$worktree" | grep -Eo "[0-9][0-9][0-9]")

    # check integration with https://github.com/andkirby/markdown-ticket
    if [[ "$worktree" =~ ^[0-9][0-9][0-9]$ ]]; then
        dot_config="$(git rev-parse --show-toplevel)/.mdt-config.toml"
        if [ -f "$dot_config" ]; then
            project_code=$(grep "^code = " "$dot_config" | cut -d"=" -f2 | tr -d " \"")
            if [ -n "$project_code" ]; then
                worktree="${project_code}-${ticket_number}"
            else
                worktree="${ticket_number}"
            fi
        else
            worktree="${ticket_number}"
        fi
    fi

    # Check local config first, then global
    default_path=$(git config worktree.defaultPath 2>/dev/null || git config --global worktree.defaultPath 2>/dev/null)

    if [ -z "$default_path" ]; then
        echo "warning: worktree.defaultPath is not configured" >&2
        echo "Using default path: .gitWT/{worktree_name}" >&2
        default_path=".gitWT/{worktree_name}"
    fi

    # Get project directory name (basename of git root)
    project_dir="$(basename "$(git rev-parse --show-toplevel)")"

    # Replace {project_dir} placeholder first, then {worktree_name}
    if [[ "$default_path" == *"{project_dir}"* ]]; then
        default_path_with_project=$(echo "$default_path" | sed "s/{project_dir}/$project_dir/g")
    else
        default_path_with_project="$default_path"
    fi

    if [[ "$default_path_with_project" == *"{worktree_name}"* ]]; then
        worktree_path=$(echo "$default_path_with_project" | sed "s/{worktree_name}/$worktree/g")
    else
        default_path_with_project="${default_path_with_project%/}"
        worktree_path="$default_path_with_project/$worktree"
    fi

    # Expand ~ to $HOME
    worktree_path="${worktree_path/#\~/$HOME}"

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
    local response="${WT_TEST_RESPONSE:-}"
    if [[ -z "$response" ]]; then
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
            local branch_response="${WT_TEST_RESPONSE:-}"
            if [[ -z "$branch_response" ]]; then
                read -p "Delete branch \"$worktree\"? [y/N] " branch_response
            fi
            if [[ "$branch_response" =~ ^[Yy]$ ]]; then
                git branch -D "$worktree"
                echo "✓ Deleted branch: $worktree"
            else
                echo "Branch \"$worktree\" kept"
            fi
        fi
    fi

    echo "✓ Worktree removal completed"
}; f'