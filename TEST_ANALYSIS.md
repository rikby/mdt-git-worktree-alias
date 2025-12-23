# Bats Test Analysis for worktree-alias

## Problem Summary

The Bats tests in `test/wt_integration.bats` are not working correctly due to several issues:

### 1. **Git Aliases Not Installed**
- The main script `git_config_alias_worktree.sh` contains Git alias definitions:
  ```bash
  git config --global alias.wt '!f() { ... }; f'
  ```
- However, these aliases are **never installed** in the test environment
- Tests try to call `git wt` but the alias doesn't exist

### 2. **Tests Test Implementation Logic, Not Git Commands**
- The test file reimplements the same logic inline:
  ```bash
  # From test/wt_integration.bats
  worktree_input="123"
  ticket_number=$(echo "$worktree_input" | grep -Eo "[0-9][0-9][0-9]")
  project_code=$(grep "^code = " "$dot_config" | cut -d"=" -f2 | tr -d " \"")
  ```
- This tests the implementation, not the actual Git command behavior

### 3. **Missing Bats Helper Libraries**
- Tests load these libraries:
  - `test_helper/bats-support/load`
  - `test_helper/bats-assert/load`
  - `test_helper/bats-file/load`
- Only `test_helper/common-setup.bash` exists

## Solutions

### Solution 1: Install Git Aliases Before Tests

Create a setup script that installs the aliases:
```bash
#!/bin/bash
# Install Git aliases for testing
git config --global alias.wt '!f() {
    # Copy the function implementation here
}; f'
```

### Solution 2: Test the Logic Directly

Extract the core logic into a testable function:
```bash
# test_worktree_logic.bash
worktree_logic() {
    local worktree="$1"
    # Implementation logic here
}
```

### Solution 3: Create Proper Stubs

Add missing Bats helper stubs to `test_helper/common-setup.bash`:
```bash
assert() { "$@"; }
assert_equal() { [[ "$1" == "$2" ]]; }
assert_regex() { [[ "$1" =~ $2 ]]; }
```

## Recommended Test Structure

```
test/
├── test_helper/
│   ├── common-setup.bash
│   └── stubs/
│       ├── bats-support.bash
│       ├── bats-assert.bash
│       └── bats-file.bash
├── worktree_logic.bats  # Test the extracted logic
└── integration.bats    # Test actual Git commands (if aliases installed)
```

## Current Test Issues

1. **Syntax Error in Test**: Line 10 in `wt_integration.bats` has `load 'test_helper/common-setup'` which should be `load 'test_helper/common-setup.bash'`

2. **Missing Functions**: The test uses `create_test_repo`, `create_mdt_config`, etc., but these are defined in `common-setup.bash` after they're used

3. **Interactive Prompts**: The original script has interactive prompts (`read -p`) which will fail in automated tests

## Files Created for Fix

1. `/test/test_helper/common-setup.bash` - Updated with proper stubs
2. `/test_simple.bash` - Simple test script demonstrating the logic
3. `/test/test_worktree_alias.bats` - Proper Bats test file
4. `/run_tests.bash` - Test runner with proper setup
5. `/test_setup.bash` - Git alias installation script

## How to Run Tests

1. **Simple Logic Test**:
   ```bash
   chmod +x test_simple.bash
   ./test_simple.bash
   ```

2. **Bats Test**:
   ```bash
   bats test/test_worktree_alias.bats
   ```

3. **Complete Test Suite**:
   ```bash
   ./run_tests.bash
   ```

## Key Takeaways

1. **Git aliases must be installed** before testing them
2. **Test the logic directly** rather than reimplementing it
3. **Use proper stubs** for missing Bats libraries
4. **Avoid interactive prompts** in automated tests
5. **Separate unit tests** (logic) from **integration tests** (Git commands)

The original tests were testing the right behavior but in the wrong way. By extracting the logic into testable functions and providing proper stubs, the tests will now work correctly.