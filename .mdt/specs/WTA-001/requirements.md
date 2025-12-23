# Requirements: WTA-001

**Source**: [WTA-001](../../../docs/CRs/WTA/WTA-001.md)
**Generated**: 2025-12-22
**CR Type**: Feature Enhancement

## Introduction

The Git Worktree Manager provides simplified ticket-based development workflows through two Git aliases (`wt` and `wt-rm`) that automate worktree creation and removal using configurable path templates. The system integrates with the MDT (Markdown Ticket) system to read project codes and enforce consistent naming conventions across development workspaces.

## Requirements

### Requirement 1: Worktree Creation Automation

**Objective**: As a developer, I want to create isolated workspaces for tickets using simple commands, so that I can work on features without manual path management.

#### Acceptance Criteria

1. WHEN user executes `git wt 101` with 3-digit ticket number, the `git wt alias` shall create worktree at path specified by `worktree.defaultPath` configuration.
2. WHEN user executes `git wt MDT-101` with full ticket name, the `git wt alias` shall create worktree using the exact ticket name as branch identifier.
3. WHILE `.mdt-config.toml` exists with project code, the `git wt alias` shall prepend project code to numeric ticket numbers.
4. IF ticket number format is invalid (not 3 digits), THEN the `git wt alias` shall exit with error code 3 and display format examples.

### Requirement 2: Path Template Resolution

**Objective**: As a developer, I want flexible worktree location configuration, so that I can organize worktrees according to team or personal preferences.

#### Acceptance Criteria

1. WHEN `worktree.defaultPath` contains `{worktree_name}` placeholder, the `git wt alias` shall substitute it with the resolved ticket name.
2. WHEN `worktree.defaultPath` contains `{project_dir}` placeholder, the `git wt alias` shall substitute it with repository basename.
3. WHEN `worktree.defaultPath` lacks `{worktree_name}` placeholder, the `git wt alias` shall append ticket name to configured path.
4. WHEN path starts with `~`, the `git wt alias` shall expand it to user's HOME directory.
5. WHEN path is relative, the `git wt alias` shall resolve it relative to repository root with `--relative-paths` flag.

### Requirement 3: Interactive Configuration Management

**Objective**: As a new user, I want guided setup when configuration is missing, so that I can start using the system without prior knowledge.

#### Acceptance Criteria

1. WHEN `worktree.defaultPath` is not configured, the `git wt alias` shall display warning with configuration examples.
2. WHEN user accepts default setup, the `git wt alias` shall set global `worktree.defaultPath` to `.gitWT/{worktree_name}`.
3. WHEN user declines default setup, the `git wt alias` shall create worktree at `.gitWT/{worktree_name}` for current operation only.

### Requirement 4: Worktree Removal with Safety

**Objective**: As a developer, I want to safely remove worktrees and clean up branches, so that I can maintain a clean workspace without accidental data loss.

#### Acceptance Criteria

1. WHEN user executes `git wt-rm 101`, the `git wt-rm alias` shall locate worktree using same path resolution as creation.
2. WHEN worktree is found, the `git wt-rm alias` shall prompt for confirmation before removal.
3. WHEN worktree removal succeeds, the `git wt-rm alias` shall offer to delete the branch if no other worktrees use it.
4. IF worktree path does not exist, THEN the `git wt-rm alias` shall display error and list existing worktrees.
5. IF branch has no associated worktrees, THEN the `git wt-rm alias` shall offer optional branch deletion.

### Requirement 5: Error Handling and Validation

**Objective**: As a developer, I want clear error messages with remediation steps, so that I can quickly resolve configuration and operational issues.

#### Acceptance Criteria

1. WHEN worktree already exists at target path, the `git wt alias` shall exit with error code 1 and provide removal command.
2. WHEN branch exists without worktree, the `git wt alias` shall exit with error code 2 and provide manual creation command.
3. WHEN parent directory doesn't exist, the `git wt alias` shall create it automatically before worktree creation.
4. WHEN git worktree removal fails, the `git wt-rm alias` shall provide manual cleanup instructions.

### Requirement 6: Git Integration Compatibility

**Objective**: As a developer, I want the aliases to work seamlessly with existing Git functionality, so that I can combine them with standard Git workflows.

#### Acceptance Criteria

1. The `git wt alias` shall use `git worktree add` command with appropriate flags for relative/absolute paths.
2. The `git wt-rm alias` shall use `git worktree remove` command for safe directory removal.
3. WHEN worktree operations complete, the aliases shall display created/removed paths and branch names.
4. All operations shall maintain compatibility with Git 2.15+ worktree functionality.

## Artifact Mapping

| Req ID | Requirement Summary | Primary Artifact | Integration Points |
|--------|---------------------|------------------|-------------------|
| R1.1 | Numeric ticket worktree creation | `git_config_alias_worktree.sh` | `.mdt-config.toml` |
| R1.2 | Full ticket name worktree creation | `git_config_alias_worktree.sh` | Git worktree system |
| R1.3 | Project code auto-detection | `git_config_alias_worktree.sh` | `.mdt-config.toml` |
| R1.4 | Ticket format validation | `git_config_alias_worktree.sh` | Terminal output |
| R2.1 | Worktree name placeholder substitution | `git_config_alias_worktree.sh` | Git config system |
| R2.2 | Project directory placeholder substitution | `git_config_alias_worktree.sh` | Git repository metadata |
| R2.3 | Placeholder fallback behavior | `git_config_alias_worktree.sh` | Path handling logic |
| R2.4 | Home directory expansion | `git_config_alias_worktree.sh` | Shell environment |
| R2.5 | Relative path resolution | `git_config_alias_worktree.sh` | Git worktree flags |
| R3.1 | Missing configuration guidance | `git_config_alias_worktree.sh` | Terminal output |
| R3.2 | Default configuration acceptance | `git_config_alias_worktree.sh` | Git global config |
| R3.3 | Fallback operation mode | `git_config_alias_worktree.sh` | Local execution path |
| R4.1 | Worktree path discovery | `git_config_alias_worktree.sh` | Git config system |
| R4.2 | Removal confirmation prompt | `git_config_alias_worktree.sh` | User interaction |
| R4.3 | Branch cleanup offering | `git_config_alias_worktree.sh` | Git branch management |
| R4.4 | Missing worktree error handling | `git_config_alias_worktree.sh` | Git worktree list |
| R4.5 | Orphaned branch detection | `git_config_alias_worktree.sh` | Git worktree references |
| R5.1 | Duplicate worktree error | `git_config_alias_worktree.sh` | Git worktree validation |
| R5.2 | Orphaned branch error | `git_config_alias_worktree.sh` | Git branch checking |
| R5.3 | Parent directory creation | `git_config_alias_worktree.sh` | Filesystem operations |
| R5.4 | Failed removal guidance | `git_config_alias_worktree.sh` | Manual cleanup instructions |
| R6.1 | Native Git command usage | `git_config_alias_worktree.sh` | Git worktree API |
| R6.2 | Standard Git removal commands | `git_config_alias_worktree.sh` | Git worktree API |
| R6.3 | Operation completion reporting | `git_config_alias_worktree.sh` | User feedback |
| R6.4 | Git version compatibility | `git_config_alias_worktree.sh` | Git 2.15+ features |

## Traceability

| Req ID | CR Section | Acceptance Criteria |
|--------|------------|---------------------|
| R1.1-R1.4 | Problem | Functional AC-1, AC-2, AC-3 |
| R2.1-R2.5 | Problem | Functional AC-4 |
| R3.1-R3.3 | Problem | Functional AC-6 |
| R4.1-R4.5 | Problem | Functional AC-3, AC-5 |
| R5.1-R5.4 | Problem | Non-Functional AC-1 |
| R6.1-R6.4 | Problem | Non-Functional AC-2, AC-3 |

## Non-Functional Requirements

### Reliability
- IF `.mdt-config.toml` is missing or malformed, THEN the system shall continue operation using numeric ticket only.
- IF Git operations fail, THEN the system shall provide specific error messages with exit codes for scripting.

### Consistency
- The `git wt` and `git wt-rm` aliases shall use identical path resolution logic for configuration and placeholder substitution.
- All error messages shall follow consistent format with remediation steps.

### Usability
- WHEN configuration is missing, the system shall provide clear examples showing relative vs absolute path options.
- WHEN operations complete successfully, the system shall display exact paths created/removed for verification.

---
*Generated from WTA-001 by /mdt:requirements*