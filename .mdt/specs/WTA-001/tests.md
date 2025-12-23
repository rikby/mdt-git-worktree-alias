# Tests: WTA-001

**Mode**: Feature (existing implementation)
**Source**: git_config_alias_worktree.sh
**Generated**: 2025-12-23
**Scope**: Complete worktree alias functionality

## Test Configuration

| Setting | Value |
|---------|-------|
| Framework | Bats (Bash Automated Testing System) |
| Test Directory | `test/` |
| Test Command | `bats test/` |
| Status | Tests document existing implementation |

## Bats Test Framework Setup

### Isolated Environment Strategy

Tests use an isolated git environment to prevent affecting user's git config:

```bash
# Pattern: Override HOME for git commands
git_test() {
    HOME="${ISOLATED_GIT_HOME:-/tmp/wta-test-home}" git "$@"
}

# Usage in tests:
git_test config --global worktree.defaultPath ".gitWT/{worktree_name}"
git_test wt 123  # Uses alias from isolated config
```

#### How Isolation Works

```
Your Real Environment:
  ~/.gitconfig  ←  NEVER TOUCHED by tests

ISOLATED_GIT_HOME = /tmp/wta-git-home-XXXXXX
  └── .gitconfig
      ├── alias.wt = !f() { ... }
      └── alias.wt-rm = !f() { ... }

Test Repository: /tmp/bats-test-dir-XXXXXX
  (uses git_test which reads from ISOLATED_GIT_HOME)
```

#### Critical Rule: Always Use `git_test`

```bash
# WRONG - affects your real git config
git config --global alias.wt ...
git wt 123

# CORRECT - isolated to test environment
git_test config --global alias.wt ...
git_test wt 123
```

### Running Tests

```bash
# Install Bats via Homebrew
brew install bats-core bats-assert bats-file bats-support

# Run all tests
bats test/

# Run specific test file
bats test/wt_ticket_validation.bats

# Run with verbose output
bats --verbose test/

# Run with timing information
bats --timing test/

# Run specific test by name
bats --filter "accepts: 3-digit ticket number" test/
```

### Installing Bats Helper Libraries

```bash
# Add as git submodules (recommended for CI)
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git test/test_helper/bats-file

# Initialize submodules
git submodule update --init --recursive

# Run using submodule bats
./test/bats/bin/bats test/
```

## Test Files Overview

| File | Purpose | Scenarios |
|------|---------|-----------|
| `wt_ticket_validation.bats` | Ticket format validation | 6 |
| `wt_project_code_resolution.bats` | MDT config integration | 5 |
| `wt_path_resolution.bats` | Path placeholder handling | 7 |
| `wt_error_handling.bats` | Error messages and edge cases | 5 |
| `wt_rm_removal.bats` | Worktree removal with safety | 6 |
| `wt_integration.bats` | End-to-end workflows | 6 |

**Total**: 35 test scenarios

## Test Specifications

### Ticket Validation (`wt_ticket_validation.bats`)

Tests for 3-digit ticket number format validation and extraction.

```gherkin
Scenario: rejects input without 3-digit ticket number
  Given a git repository with worktree alias configured
  When the user runs "git wt abc"
  Then the command should fail with exit code 3
  And the output should contain "Must include 3-digit ticket number"

Scenario: accepts 3-digit ticket number
  Given a git repository with worktree alias configured
  When the user runs "git wt 123"
  Then the command should not show format validation error

Scenario: accepts project-prefixed format
  Given a git repository with worktree alias configured
  When the user runs "git wt MDT-123"
  Then the command should not show format validation error
```

### Project Code Resolution (`wt_project_code_resolution.bats`)

Tests for automatic project code detection from `.mdt-config.toml`.

```gherkin
Scenario: reads project code from .mdt-config.toml
  Given a repository with .mdt-config.toml containing code = "TEST"
  When the user runs "git wt 123"
  Then the worktree name should be "TEST-123"

Scenario: fallback to plain number when config missing
  Given a repository without .mdt-config.toml
  When the user runs "git wt 123"
  Then the worktree name should be "123"

Scenario: preserves existing prefix
  Given a repository with .mdt-config.toml
  When the user runs "git wt MDT-123"
  Then the worktree name should remain "MDT-123"
```

### Path Resolution (`wt_path_resolution.bats`)

Tests for `worktree.defaultPath` configuration and placeholder substitution.

```gherkin
Scenario: substitutes {worktree_name} placeholder
  Given worktree.defaultPath = ".gitWT/{worktree_name}"
  When constructing worktree path for "WTA-123"
  Then the path should be ".gitWT/WTA-123"

Scenario: substitutes {project_dir} placeholder
  Given worktree.defaultPath = "../{project_dir}_{worktree_name}"
  And the repository basename is "my-project"
  When constructing worktree path for "WTA-123"
  Then the path should be "../my-project_WTA-123"

Scenario: expands tilde to HOME directory
  Given worktree.defaultPath = "~/worktrees/{worktree_name}"
  When constructing worktree path
  Then "~" should be expanded to $HOME

Scenario: handles absolute paths
  Given worktree.defaultPath = "/worktrees/{worktree_name}"
  When constructing worktree path
  Then should use --no-relative-paths flag
```

### Error Handling (`wt_error_handling.bats`)

Tests for error detection and user-friendly messages.

```gherkin
Scenario: detects duplicate worktree
  Given a worktree directory already exists at ".gitWT/WTA-123"
  When the user attempts to create another with same name
  Then should exit with code 1
  And should show message "Worktree already exists at <path>"

Scenario: detects branch without worktree
  Given a branch "WTA-123" exists but has no worktree
  When the user attempts to create worktree
  Then should exit with code 2
  And should show helpful remediation message

Scenario: prompts for configuration on missing config
  Given worktree.defaultPath is not configured
  When the user runs "git wt 123"
  Then should show warning with configuration examples
```

### Worktree Removal (`wt_rm_removal.bats`)

Tests for safe worktree and branch removal.

```gherkin
Scenario: validates ticket number
  Given the git wt-rm command
  When executed with non-numeric input "abc"
  Then should exit with code 3

Scenario: uses same path resolution as git wt
  Given worktree.defaultPath = ".gitWT/{worktree_name}"
  When running "git wt-rm 123"
  Then should resolve path using same logic as "git wt"

Scenario: errors when worktree not found
  Given no worktree exists at resolved path
  When running "git wt-rm 999"
  Then should exit with code 1
  And should list existing worktrees
```

### Integration Workflows (`wt_integration.bats`)

Tests for end-to-end scenarios.

```gherkin
Scenario: complete workflow with MDT integration
  Given a repository with .mdt-config.toml containing code = "WTA"
  And worktree.defaultPath = ".gitWT/{worktree_name}"
  When the user runs "git wt 123"
  Then should create worktree at ".gitWT/WTA-123"
  And should create branch "WTA-123"

Scenario: creates worktree outside repository
  Given worktree.defaultPath with absolute path
  When the user runs "git wt 789"
  Then should create worktree at absolute path outside repo

Scenario: creates parent directories
  Given worktree path with non-existent parent directories
  When creating worktree
  Then should create parent directories automatically
```

## Test Organization

```
test/
├── test_helper/
│   ├── common-setup.bash         # Shared fixtures and setup
│   ├── bats-support/             # Submodule (optional)
│   ├── bats-assert/              # Submodule (optional)
│   └── bats-file/                # Submodule (optional)
├── wt_ticket_validation.bats     # Ticket format validation
├── wt_project_code_resolution.bats # MDT integration
├── wt_path_resolution.bats       # Path placeholder handling
├── wt_error_handling.bats        # Error messages
├── wt_rm_removal.bats            # Worktree removal
└── wt_integration.bats           # End-to-end workflows
```

## Test Helper Functions

### `create_test_repo <directory>`
Creates an isolated git repository for testing:
- Initializes new git repo
- Sets user config
- Creates initial commit

### `cleanup_test_repo <directory>`
Removes test repository directory.

### `create_mdt_config <directory> <project_code>`
Creates `.mdt-config.toml` with specified project code.

### `_common_setup()`
Standard Bats setup that:
- Loads helper libraries (bats-support, bats-assert, bats-file)
- Sets PROJECT_ROOT
- Creates isolated git environment

## Running Tests in CI

```yaml
# Example GitHub Actions
- name: Install Bats
  run: brew install bats-core bats-assert bats-file bats-support

- name: Run tests
  run: bats test/
```

```yaml
# Example Docker
FROM ubuntu:latest
RUN apt-get update && apt-get install -y git bash
RUN git clone https://github.com/bats-core/bats-core.git /opt/bats
ENV PATH="/opt/bats/bin:${PATH}"
COPY . /app
WORKDIR /app
CMD ["bats", "test/"]
```

## Edge Cases Covered

| Scenario | Expected Behavior | Test File |
|----------|-------------------|-----------|
| Empty/invalid ticket number | Exit code 3, error message | wt_ticket_validation.bats |
| 2-digit number | Exit code 3, error message | wt_ticket_validation.bats |
| 4+ digit number | Contains 3-digit sequence, passes | wt_ticket_validation.bats |
| Empty project code in config | Falls back to plain ticket number | wt_project_code_resolution.bats |
| Missing .mdt-config.toml | Falls back to plain ticket number | wt_project_code_resolution.bats |
| Relative path without placeholder | Appends worktree name | wt_path_resolution.bats |
| Absolute path | Uses --no-relative-paths flag | wt_path_resolution.bats |
| Tilde in path | Expands to $HOME | wt_path_resolution.bats |
| Branch exists without worktree | Exit code 2, helpful message | wt_error_handling.bats |
| Worktree already exists | Exit code 1, path shown | wt_error_handling.bats |
| Worktree not found for removal | Lists existing worktrees | wt_rm_removal.bats |
| Nested path directories | Creates parent directories | wt_integration.bats |

## See Also

- [tests-writing-guideline.md](../../../tests-writing-guideline.md) - Testing philosophy and best practices
- [requirements.md](./requirements.md) - EARS-formatted requirements
