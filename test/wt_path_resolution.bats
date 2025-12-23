#!/usr/bin/env bats
#
# Tests for: WTA - Path Resolution
# Feature: worktree.defaultPath configuration and placeholder substitution
# Requirements: Derived from git_config_alias_worktree.sh
#
# Note: These are integration tests that call the actual git wt alias
#

setup() {
    load 'test_helper/common-setup.bash'
    _common_setup
}

teardown() {
    if [[ -n "$TEST_REPO_DIR" && -d "$TEST_REPO_DIR" ]]; then
        cleanup_test_repo "$TEST_REPO_DIR"
    fi
    _common_teardown
}

# Feature: Path Placeholder Substitution

@test "substitutes: {worktree_name} placeholder in path" {
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    git_test config worktree.defaultPath ".gitWT/{worktree_name}"

    run git_test wt 123 2>&1 || true

    assert_output --partial ".gitWT/WTA-123"

    if [ -d "$TEST_REPO_DIR/.gitWT/WTA-123" ]; then
        git_test worktree remove "$TEST_REPO_DIR/.gitWT/WTA-123" 2>/dev/null || true
    fi
}

@test "substitutes: {project_dir} placeholder in path" {
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    expected_project_dir="$(basename "$TEST_REPO_DIR")"
    git_test config worktree.defaultPath "../${expected_project_dir}_{worktree_name}"

    run git_test wt 456 2>&1 || true

    assert_output --partial "${expected_project_dir}_WTA-456"

    worktree_location="../${expected_project_dir}_WTA-456"
    resolved_path="$TEST_REPO_DIR/$worktree_location"
    if [ -d "$resolved_path" ]; then
        git_test worktree remove "$resolved_path" 2>/dev/null || true
    fi
}

@test "appends: worktree name when placeholder not present" {
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    git_test config worktree.defaultPath ".gitWT"

    run git_test wt 789 2>&1 || true

    assert_output --partial ".gitWT/WTA-789"

    if [ -d "$TEST_REPO_DIR/.gitWT/WTA-789" ]; then
        git_test worktree remove "$TEST_REPO_DIR/.gitWT/WTA-789" 2>/dev/null || true
    fi
}

@test "expands: tilde (~) to HOME directory" {
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    git_test config worktree.defaultPath "~/worktrees/{worktree_name}"

    run git_test wt 321 2>&1 || true

    assert_output --partial "worktrees/WTA-321"

    if [ -d "$HOME/worktrees/WTA-321" ]; then
        git_test worktree remove "$HOME/worktrees/WTA-321" 2>/dev/null || true
    fi
}

@test "handles: absolute paths correctly" {
    TEST_REPO_DIR=$(mktemp -d)
    TEST_WORKTREE_BASE=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    git_test config worktree.defaultPath "$TEST_WORKTREE_BASE/{worktree_name}"

    run git_test wt 654 2>&1 || true

    assert_output --partial "$TEST_WORKTREE_BASE/WTA-654"

    if [ -d "$TEST_WORKTREE_BASE/WTA-654" ]; then
        git_test worktree remove "$TEST_WORKTREE_BASE/WTA-654" 2>/dev/null || true
    fi
    rmdir "$TEST_WORKTREE_BASE" 2>/dev/null || true
}

@test "handles: relative paths with repo root" {
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    git_test config worktree.defaultPath ".gitWT/{worktree_name}"

    run git_test wt 987 2>&1 || true

    repo_root="$(git_test rev-parse --show-toplevel)"
    assert_output --partial "$repo_root/.gitWT/WTA-987"

    if [ -d "$TEST_REPO_DIR/.gitWT/WTA-987" ]; then
        git_test worktree remove "$TEST_REPO_DIR/.gitWT/WTA-987" 2>/dev/null || true
    fi
}

@test "combines: multiple placeholders correctly" {
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"
    expected_project_dir="$(basename "$TEST_REPO_DIR")"
    git_test config worktree.defaultPath "~/worktrees/{project_dir}/{worktree_name}"

    run git_test wt 111 2>&1 || true

    assert_output --partial "worktrees/$expected_project_dir/WTA-111"

    if [ -d "$HOME/worktrees/$expected_project_dir/WTA-111" ]; then
        git_test worktree remove "$HOME/worktrees/$expected_project_dir/WTA-111" 2>/dev/null || true
    fi
}
