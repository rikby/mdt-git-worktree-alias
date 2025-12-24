# Tests Writing Guidelines

This document establishes goals and approaches for writing effective tests for the Git Worktree Alias system.

## Core Principles

### 1. Test Behavior, Not Implementation

Tests should verify **what the system does**, not **how it does it**.

**Good**: Test the observable effect of running a command
```bats
@test "creates worktree with project-prefixed branch name" {
    # Given: repository with MDT config
    # When: user runs git wt 123
    # Then: branch named MDT-123 should exist
    git_test config worktree.defaultPath ".gitWT/{worktree_name}"
    run git_test wt 123 2>&1

    git_test show-ref --verify --quiet "refs/heads/MDT-123"
}
```

**Avoid**: Duplicating implementation logic in tests
```bats
@test "extracts ticket number" {
    # This tests grep/regex, not the system behavior
    ticket_number=$(echo "123" | grep -Eo "[0-9][0-9][0-9]")
    assert_equal "$ticket_number" "123"
}
```

**Why**: Implementation details change. Behavior stays stable. Testing implementation creates fragile tests that break when you refactor code without changing functionality.

### 2. Use Given-When-Then Structure

Each test should clearly document:
- **Given**: The initial state and setup
- **When**: The action being tested
- **Then**: The expected outcome

This pattern makes tests self-documenting and easier to review.

```bats
@test "creates worktree at configured path" {
    # Given: repository with configured default path
    TEST_REPO_DIR=$(mktemp -d)
    create_test_repo "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR" || return 1
    git_test config worktree.defaultPath ".gitWT/{worktree_name}"

    # When: user creates worktree for ticket 123
    run git_test wt 123 2>&1

    # Then: worktree directory should exist
    assert_directory_exist "$TEST_REPO_DIR/.gitWT/MDT-123"
}
```

### 3. Test Through the Public Interface

Tests should interact with the system the same way a user would: through commands, configuration, and filesystem state.

**Test via**:
- Command execution (`git wt`, `git wt-rm`)
- Configuration files (`git config`, `.mdt-config.toml`)
- Filesystem state (directories, files, git refs)
- Exit codes and output

**Avoid**:
- Calling internal functions directly
- Inspecting private implementation state
- Mocking core behavior that should be tested

### 4. One Logical Assertion Per Test

Each test should verify one behavior or outcome. Multiple assertions are acceptable if they verify a single logical condition.

```bats
@test "validates ticket format and shows error" {
    # This tests one behavior: format validation
    run git_test wt invalid 2>&1

    assert_failure
    assert_output --partial "Must include 3-digit ticket number"
    assert_equal "$status" 3
}
```

### 5. Use Descriptive Test Names

Test names should describe what is being tested, not how.

| Poor | Good |
|------|------|
| "test_regex_extraction" | "extracts ticket number from prefixed input" |
| "test_path_logic" | "creates worktree at relative path" |
| "error_test_1" | "shows error when worktree already exists" |

## Test Categories

### Functional Tests

Verify the system does what it's supposed to do:
- Creating worktrees with various configurations
- Removing worktrees with safety checks
- Path resolution for different templates
- Project code detection and prefixing

### Error Handling Tests

Verify graceful failure:
- Invalid input formats
- Missing configuration
- Duplicate worktrees
- Orphaned branches
- Filesystem issues

### Integration Tests

Verify end-to-end workflows:
- Complete create-use-remove cycle
- Multi-step scenarios
- Configuration interactions

## Testing Automation Support

### Environment Variable Automation

Commands that prompt for user input must support automated testing via `WT_TEST_RESPONSE`. This enables CI/CD testing without interactive input.

**Single prompt**: `WT_TEST_RESPONSE="y"`
**Multiple prompts**: `WT_TEST_RESPONSE="y:n"` (colon-separated, processed sequentially)
**Quiet mode**: `--quiet` flag skips all prompts

### Configuration Value Testing

Boolean config settings should accept multiple true/false equivalents. Test all variants:

- **True values**: `true`, `on`, `yes`, `1`
- **False values**: `false`, `off`, `no`, `0`
- **Unset**: Verify default behavior when config not set

### Testing Guidelines

1. Always test environment variable support for interactive commands
2. Test multi-prompt sequences using colon-separated `WT_TEST_RESPONSE` values
3. Test all config value variants (true/false/on/off/yes/no/1/0)
4. Test unset config to verify default behavior
5. Test flag overrides where flags take precedence over config

## Common Anti-Patterns

### Testing Implementation Details

```bats
# Avoid: Tests specific shell commands used
ticket_number=$(echo "$input" | grep -Eo "[0-9][0-9][0-9]")

# Prefer: Tests actual command behavior
run git_test wt 123
assert_success
```

### Brittle String Matching

```bats
# Avoid: Exact string matching on help text
assert_equal "$output" "exact help message here"

# Prefer: Partial matching for error identifiers
assert_output --partial "Must include 3-digit"
```

### Test Code Duplication

```bats
# Avoid: Same logic tested multiple times
@test "extracts from 123" { ... }
@test "extracts from 456" { ... }
@test "extracts from 789" { ... }

# Prefer: One representative test per category
@test "extracts ticket number from plain input" { ... }
```

## Test Isolation

Each test should:
- Create its own test repository/fixtures
- Clean up after itself in `teardown()`
- Not depend on other tests
- Be runnable in any order

## Coverage Goals

Aim for coverage of:
- **User-facing behaviors**: All documented use cases
- **Error paths**: Each error condition
- **Edge cases**: Empty values, special characters, boundary conditions
- **Integration points**: Config files, git commands, filesystem

Do NOT aim for:
- 100% line coverage (leads to testing implementation)
- Coverage of private helper functions
- Testing standard library behavior (git, bash builtins)

## When Tests Fail

A failing test should indicate:
1. **What behavior broke** (clear test name)
2. **How to reproduce** (minimal test case)
3. **What was expected** (assertion message)

Tests are documentation. When they fail, they should explain the intended behavior.
