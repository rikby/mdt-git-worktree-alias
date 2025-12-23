# Requirements: WTA-002

**Source**: [WTA-002](../WTA-002-decouple-mdt-integration-from-core-worktree-alias-.md)
**Generated**: 2025-12-23
**Baseline**: [WTA-001/requirements.md](../WTA-001/requirements.md)

## Introduction

WTA-002 decouples worktree alias functionality from MDT-specific integration, enabling generic ticket formatting for any project. While WTA-001 requires `.mdt-config.toml` for auto-prefix behavior, WTA-002 provides configurable ticket formatting (prefix, zero-padding) through git config that works with any ticket system (Jira, GitHub Issues, etc.). MDT projects retain auto-detection behavior, and all configurations can be overridden via git config.

**Note**: This release uses a new `worktree.wt.*` configuration namespace. Existing `worktree.defaultPath` configurations must be migrated to `worktree.wt.defaultPath` manually.

## Requirements

### Requirement 1: Generic Ticket Prefix Configuration

**Objective**: As a developer, I want to configure a ticket prefix for my project, so that I can use short ticket numbers without typing the full ticket identifier.

#### Acceptance Criteria

1. WHEN user sets `worktree.wt.prefix` to `"ABC-"` and executes `git wt 101`, the system shall create worktree with branch name `ABC-101`.
2. WHEN user sets `worktree.wt.prefix` to `"#"` and executes `git wt 42`, the system shall create worktree with branch name `#42`.
3. WHEN user sets `worktree.wt.prefix` to any value and executes `git wt feature-login`, the system shall create worktree with branch name `feature-login` (text input, no prefix applied).
4. IF `worktree.wt.prefix` is not configured, THEN the system shall use the input value as-is without adding any prefix.

### Requirement 2: Zero-Padding Configuration

**Objective**: As a developer, I want to configure zero-padding for ticket numbers, so that branches sort consistently (e.g., `001`, `002`, `003`).

#### Acceptance Criteria

1. WHEN user sets `worktree.wt.zeroPadDigits` to `3` and executes `git wt 7`, the system shall create worktree with branch name where the number portion is zero-padded to 3 digits (e.g., `WTA-007` with prefix `WTA-`, or `007` without prefix).
2. WHEN user sets `worktree.wt.zeroPadDigits` to `4` and executes `git wt 12`, the system shall create worktree with branch name where the number portion is zero-padded to 4 digits (e.g., `PROJ-0012`).
3. WHEN `worktree.wt.zeroPadDigits` is not configured, THEN the system shall use the numeric input as-is without zero-padding.
4. WHEN user provides input larger than the configured digit count (e.g., zeroPadDigits=3, input=1234), the system shall use the number as-is without truncation.

### Requirement 3: Input Type Detection and Handling

**Objective**: As a developer, I want the system to intelligently handle different input formats, so that I can use short numbers, full ticket names, or feature branch names interchangeably.

#### Acceptance Criteria

1. WHEN user executes `git wt PROJ-123` (already contains hyphen and prefix pattern), the system shall create worktree with branch name `PROJ-123` unchanged.
2. WHEN user executes `git wt 101` (pure numeric), the system shall apply prefix and zero-padding if configured.
3. WHEN user executes `git wt feature-auth` (contains letters), the system shall create worktree with branch name `feature-auth` unchanged, ignoring any configured prefix.
4. WHEN user executes `git wt-rm PROJ-456`, the system shall apply the same input detection logic as worktree creation to locate the correct worktree.

### Requirement 4: MDT Auto-Detection with Configuration Precedence

**Objective**: As an MDT project developer, I want automatic prefix configuration while retaining override capability, so that I get sensible defaults without manual configuration.

#### Acceptance Criteria

1. WHEN repository contains `.mdt-config.toml` with `code = "WTA"` and user executes `git wt 12`, the system shall create worktree with branch name `WTA-012` (auto-prefix + zero-padding to 3 digits).
2. WHEN repository contains `.mdt-config.toml` AND user has set `worktree.wt.prefix`, the system shall use the git config value instead of the MDT code.
3. WHEN repository contains `.mdt-config.toml` AND user has set `worktree.wt.zeroPadDigits`, the system shall use the git config value instead of the default 3 digits.
4. IF `.mdt-config.toml` exists but `code` field is missing or empty, THEN the system shall fall back to git config or use input as-is.

### Requirement 5: Configuration Namespace

**Objective**: As a developer, I want a consistent configuration namespace, so that settings are organized and discoverable.

#### Acceptance Criteria

1. WHEN user sets `worktree.wt.defaultPath`, the system shall use this value as the worktree path template.
2. WHEN user sets `worktree.wt.prefix`, the system shall use this value as the ticket prefix for numeric inputs.
3. WHEN user sets `worktree.wt.zeroPadDigits`, the system shall use this value for zero-padding ticket numbers.

### Requirement 6: Consistent Behavior Across Commands

**Objective**: As a developer, I want `git wt` and `git wt-rm` to handle input identically, so that worktree removal works seamlessly with worktree creation.

#### Acceptance Criteria

1. WHEN user creates worktree with `git wt 101` (resulting in branch `PROJ-101`), THEN user can remove it with `git wt-rm 101` and the system shall locate the correct worktree.
2. WHEN user creates worktree with `git wt PROJ-101`, THEN user can remove it with `git wt-rm PROJ-101` or `git wt-rm 101` (if prefix is configured).
3. WHILE both `git wt` and `git wt-rm` are available in the same repository, the system shall apply identical prefix, zero-padding, and input detection logic.

## Artifact Mapping

| Req ID | Requirement Summary | Primary Artifact | Integration Points |
|--------|---------------------|------------------|-------------------|
| R1.1-R1.4 | Generic ticket prefix configuration | `install_aliases.sh` | Git config system |
| R2.1-R2.4 | Zero-padding configuration | `install_aliases.sh` | Git config system |
| R3.1-R3.4 | Input type detection and handling | `install_aliases.sh` | Terminal input parsing |
| R4.1-R4.4 | MDT auto-detection with precedence | `install_aliases.sh` | `.mdt-config.toml`, Git config |
| R5.1-R5.3 | Configuration namespace | `install_aliases.sh` | Git config system |
| R6.1-R6.3 | Consistent behavior across commands | `install_aliases.sh` | Git worktree system |

## Traceability

| Req ID | CR Section | Acceptance Criteria |
|--------|------------|---------------------|
| R1.1-R1.4 | Problem, Desired Outcome | Functional AC-4 |
| R2.1-R2.4 | Problem, Desired Outcome | Functional AC-5 |
| R3.1-R3.4 | Scope, Acceptance Criteria | Functional AC-1, AC-2, Edge Cases |
| R4.1-R4.4 | Scope, Acceptance Criteria | Functional AC-3, Edge Cases |
| R5.1-R5.3 | Non-Functional | Functional AC-6 |
| R6.1-R6.3 | Problem | Non-Functional AC-2 |

## Non-Functional Requirements

### Reliability
- IF `.mdt-config.toml` is malformed or unreadable, THEN the system shall fall back to git config or continue with input as-is.
- IF git config is unreadable, THEN the system shall continue with default behavior (no prefix, no padding).

### Consistency
- The `git wt` and `git wt-rm` commands shall apply identical prefix, zero-padding, and input type detection logic.
- Configuration values (`worktree.wt.prefix`, `worktree.wt.zeroPadDigits`, `worktree.wt.defaultPath`) shall be read consistently across both commands.

### Extensibility
- WHEN user requires custom ticket formatting beyond prefix and zero-padding, THEN the system shall support git alias wrappers or shell functions for additional transformation.

## Extension Rule

The system supports extensibility through standard git configuration and shell customization:

1. **Custom prefix**: Set `worktree.wt.prefix` to any string value
2. **Custom padding**: Set `worktree.wt.zeroPadDigits` to any positive integer
3. **Custom workflows**: Create git aliases that wrap `git wt` for team-specific naming conventions

Example wrapper for feature branches:
```bash
git config alias.feature '!f() { git wt "feature-$1"; }; f'
git feature login    # Creates branch: feature-login
```

---
*Generated from WTA-002 by /mdt:requirements*
