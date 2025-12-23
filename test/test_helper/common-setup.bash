#!/usr/bin/env bash
#
# Common setup for Bats tests
# Provides isolated test environment fixtures
#

# =============================================================================
# Isolated Git Environment Setup
# =============================================================================

# Create an isolated HOME directory for git config
# This prevents test git aliases from affecting user's actual git config
create_isolated_git_env() {
    local iso_home="$1"
    mkdir -p "$iso_home"
    export ISOLATED_GIT_HOME="$iso_home"
}

# Git wrapper that uses isolated HOME
git_test() {
    HOME="${ISOLATED_GIT_HOME:-/tmp/wta-test-home}" git "$@"
}

# Install git wt aliases into isolated environment
install_wt_aliases() {
    local iso_home="${1:-$ISOLATED_GIT_HOME}"
    local script_path="${2:-$PROJECT_ROOT/git_config_alias_worktree.sh}"

    if [[ ! -f "$script_path" ]]; then
        echo "Error: Script not found: $script_path" >&2
        return 1
    fi

    # Source the script which installs git config aliases
    # The aliases will be installed to $ISOLATED_GIT_HOME/.gitconfig
    HOME="$iso_home" bash "$script_path"
}

# Cleanup isolated git environment
cleanup_isolated_git_env() {
    if [[ -n "$ISOLATED_GIT_HOME" && -d "$ISOLATED_GIT_HOME" ]]; then
        rm -rf "$ISOLATED_GIT_HOME"
    fi
    unset ISOLATED_GIT_HOME
}

# =============================================================================
# Assertion Helpers
# =============================================================================

# Stub functions for bats-assert
assert() {
    "$@"
}

assert_equal() {
    if [[ "$1" != "$2" ]]; then
        echo "Assertion failed: expected '$2', got '$1'" >&2
        return 1
    fi
}

assert_output() {
    local expected="$1"
    local partial=""
    local regexp=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --partial|-p)
                partial=1
                shift
                ;;
            --regex|-e)
                regexp=1
                shift
                ;;
            *)
                expected="$1"
                shift
                ;;
        esac
    done

    if [[ -n "$partial" ]]; then
        if [[ "$output" != *"$expected"* ]]; then
            echo "Assertion failed: output does not contain '$expected'" >&2
            echo "Output: $output" >&2
            return 1
        fi
    elif [[ -n "$regexp" ]]; then
        if [[ ! "$output" =~ $expected ]]; then
            echo "Assertion failed: output does not match regex '$expected'" >&2
            echo "Output: $output" >&2
            return 1
        fi
    else
        if [[ "$output" != "$expected" ]]; then
            echo "Assertion failed: expected '$expected'" >&2
            echo "Output: $output" >&2
            return 1
        fi
    fi
}

refute_output() {
    local unexpected="$1"
    local partial=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --partial|-p)
                partial=1
                shift
                ;;
            *)
                unexpected="$1"
                shift
                ;;
        esac
    done

    if [[ -n "$partial" ]]; then
        if [[ "$output" == *"$unexpected"* ]]; then
            echo "Assertion failed: output should not contain '$unexpected'" >&2
            echo "Output: $output" >&2
            return 1
        fi
    else
        if [[ "$output" == "$unexpected" ]]; then
            echo "Assertion failed: output should not be '$unexpected'" >&2
            echo "Output: $output" >&2
            return 1
        fi
    fi
}

assert_regex() {
    if [[ ! "$1" =~ $2 ]]; then
        echo "Assertion failed: '$1' does not match regex '$2'" >&2
        return 1
    fi
}

refute_regex() {
    if [[ "$1" =~ $2 ]]; then
        echo "Assertion failed: '$1' should not match regex '$2'" >&2
        return 1
    fi
}

assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Command failed with status $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Command succeeded but should have failed" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Stub functions for bats-file
assert_dir_exists() {
    if [[ ! -d "$1" ]]; then
        echo "Assertion failed: directory '$1' does not exist" >&2
        return 1
    fi
}

assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        echo "Assertion failed: file '$1' does not exist" >&2
        return 1
    fi
}

assert_file_exist() {
    assert_file_exists "$@"
}

_common_setup() {
    # Get the project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"

    # Set PATH for test executables
    PATH="$PROJECT_ROOT:$PATH"

    # Create isolated git environment (prevents pollution of user's git config)
    ISOLATED_GIT_HOME="$(mktemp -d -t wta-git-home-XXXXXX)"
    create_isolated_git_env "$ISOLATED_GIT_HOME"

    # Install git wt aliases into isolated environment
    install_wt_aliases "$ISOLATED_GIT_HOME" "$PROJECT_ROOT/git_config_alias_worktree.sh"

    # Export for use in tests
    export PROJECT_ROOT
    export PATH
    export ISOLATED_GIT_HOME
}

_common_teardown() {
    # Clean up isolated git environment
    cleanup_isolated_git_env
}

# Create a temporary git repository for testing
create_test_repo() {
    local test_dir="$1"
    mkdir -p "$test_dir"
    cd "$test_dir" || return 1

    # Use git_test so it picks up the global aliases from ISOLATED_GIT_HOME
    git_test init -q
    git_test config user.email "test@example.com"
    git_test config user.name "Test User"

    # Create initial commit
    touch README.md
    git_test add README.md
    git_test commit -q -m "Initial commit"

    echo "$test_dir"
}

# Clean up test repository
cleanup_test_repo() {
    local test_dir="$1"
    if [[ -d "$test_dir" ]]; then
        rm -rf "$test_dir"
    fi
}

# Create .mdt-config.toml for testing
create_mdt_config() {
    local repo_dir="$1"
    local project_code="${2:-WTA}"

    cat >"$repo_dir/.mdt-config.toml" <<EOF
[project]
ticketsPath = ".mdt/specs"
id = "worktree-alias"
name = "worktree alias"
code = "$project_code"
startNumber = 1
counterFile = ".mdt-next"
description = "Git worktree aliases for MDT project"
repository = "https://github.com/rikby/mdt-worktree-alias"
path = "."
EOF
}

# Source the git alias functions for testing
load_git_wt_functions() {
    # Source the main script to get functions
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/git_config_alias_worktree.sh"
}
