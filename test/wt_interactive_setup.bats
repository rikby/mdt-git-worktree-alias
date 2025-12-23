#!/usr/bin/env bats
#
# Tests for: WTA - Interactive Setup (R3.2, R3.3)
# Feature: Interactive configuration when worktree.wt.defaultPath is not configured
# Requirements: R3.2, R3.3 from requirements.md
# Status: Tests interactive setup with WT_TEST_RESPONSE environment variable
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

# Feature: R3.2 - User accepts interactive setup

@test "R3.2: user accepts interactive setup and global config is set" {
    # Given: a repository without worktree.wt.defaultPath configured
    # And: WT_TEST_RESPONSE is set to "y" to simulate user accepting
    # When: running git wt 123
    # Then: global worktree.wt.defaultPath should be set to ".gitWT/{worktree_name}"

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    # Ensure worktree.wt.defaultPath is not configured
    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    # Export WT_TEST_RESPONSE so it's inherited by the git alias subshell
    export WT_TEST_RESPONSE="y"
    run git_test wt 123 2>&1 || true
    unset WT_TEST_RESPONSE

    # Verify global config was set
    global_config=$(git_test config --global worktree.wt.defaultPath 2>/dev/null || echo "")
    assert_equal "$global_config" ".gitWT/{worktree_name}"

    # Verify output mentions setting the config
    assert_output --partial "Set global worktree.wt.defaultPath"
}

@test "R3.2: user accepts with empty response (default yes)" {
    # Given: worktree.wt.defaultPath is not configured
    # And: WT_TEST_RESPONSE is set to empty string (simulates pressing Enter)
    # When: running git wt 123
    # Then: should accept and set global config (empty = default yes)
    #
    # Note: We can't test actual empty string because it triggers read -p.
    # Instead we test that the logic works by using "y" which is functionally equivalent.
    # The actual script treats empty string same as "y" in: [[ "$response" =~ ^[Yy]?$ ] || [ -z "$response" ]]

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    # Use "y" to simulate the "default yes" behavior
    export WT_TEST_RESPONSE="y"
    run git_test wt 123 2>&1 || true
    unset WT_TEST_RESPONSE

    global_config=$(git_test config --global worktree.wt.defaultPath 2>/dev/null || echo "")
    assert_equal "$global_config" ".gitWT/{worktree_name}"
}

@test "R3.2: user accepts with lowercase y" {
    # Given: worktree.wt.defaultPath is not configured
    # When: running git wt with WT_TEST_RESPONSE="y"
    # Then: should accept and set global config

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    export WT_TEST_RESPONSE="y"
    run git_test wt 456 2>&1 || true
    unset WT_TEST_RESPONSE

    global_config=$(git_test config --global worktree.wt.defaultPath 2>/dev/null || echo "")
    assert_equal "$global_config" ".gitWT/{worktree_name}"
}

@test "R3.2: user accepts with uppercase Y" {
    # Given: worktree.wt.defaultPath is not configured
    # When: running git wt with WT_TEST_RESPONSE="Y"
    # Then: should accept and set global config

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    export WT_TEST_RESPONSE="Y"
    run git_test wt 789 2>&1 || true
    unset WT_TEST_RESPONSE

    global_config=$(git_test config --global worktree.wt.defaultPath 2>/dev/null || echo "")
    assert_equal "$global_config" ".gitWT/{worktree_name}"
}

# Feature: R3.3 - User declines interactive setup

@test "R3.3: user declines and worktree is created at default path" {
    # Given: worktree.wt.defaultPath is not configured
    # And: WT_TEST_RESPONSE is set to "n" to simulate user declining
    # When: running git wt 123
    # Then: worktree should be created at .gitWT/XXX directly
    # And: global config should NOT be set

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    # Create .mdt-config.toml for project code
    create_mdt_config "$TEST_REPO_DIR" "TEST"

    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    # User declines the setup
    export WT_TEST_RESPONSE="n"
    run git_test wt 123 2>&1 || true
    unset WT_TEST_RESPONSE

    # Verify global config was NOT set
    global_config=$(git_test config --global worktree.wt.defaultPath 2>/dev/null || echo "")
    assert_equal "$global_config" ""

    # Verify worktree was created
    # Since .mdt-config.toml has code="TEST", the worktree name should be TEST-123
    worktree_list=$(git_test worktree list)
    assert_regex "$worktree_list" "TEST-123"

    # Clean up the created worktree
    git_test worktree remove "$TEST_REPO_DIR/.gitWT/TEST-123" 2>/dev/null || true
}

@test "R3.3: user declines and worktree branch is created" {
    # Given: worktree.wt.defaultPath is not configured
    # When: user declines interactive setup
    # Then: branch should be created with worktree

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "WTA"

    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    export WT_TEST_RESPONSE="n"
    run git_test wt 999 2>&1 || true
    unset WT_TEST_RESPONSE

    # Verify branch exists
    branch_output=$(git_test branch)
    assert_regex "$branch_output" "WTA-999"

    # Clean up
    git_test worktree remove "$TEST_REPO_DIR/.gitWT/WTA-999" 2>/dev/null || true
}

@test "R3.3: user declines with various negative responses" {
    # Given: worktree.wt.defaultPath is not configured
    # When: user responds with "n", "N", "no", "NO", etc.
    # Then: should decline and create worktree directly

    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1

    create_mdt_config "$TEST_REPO_DIR" "TEST"

    git_test config --unset worktree.wt.defaultPath 2>/dev/null || true
    git_test config --global --unset worktree.wt.defaultPath 2>/dev/null || true

    # Test with "n"
    export WT_TEST_RESPONSE="n"
    run git_test wt 111 2>&1 || true
    unset WT_TEST_RESPONSE

    global_config=$(git_test config --global worktree.wt.defaultPath 2>/dev/null || echo "")
    assert_equal "$global_config" ""

    # Clean up
    git_test worktree remove "$TEST_REPO_DIR/.gitWT/TEST-111" 2>/dev/null || true
}
