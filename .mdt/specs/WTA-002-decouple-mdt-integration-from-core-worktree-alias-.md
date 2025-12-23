---
code: WTA-002
status: Implemented
dateCreated: 2025-12-23T07:35:08.028Z
type: Architecture
priority: Medium
---

# Decouple MDT Integration from Core Worktree Alias Functionality

## 1. Description

### Problem

- Core worktree functionality is tightly coupled to `.mdt-config.toml` file reading
- Users without MDT system cannot benefit from the wt alias tool
- Project code resolution logic (~28 lines) is duplicated between `wt` and `wt-rm` aliases
- Tool cannot support alternative ticket systems (Jira, GitHub Issues, etc.)
- Hardcoded path to `.mdt-config.toml` prevents flexible configuration sources

### Affected Areas

- Core alias logic: Path templating, worktree creation/removal, validation
- Project code resolution: Currently reads from `.mdt-config.toml` file only
- Configuration: Git config system for path templates
- Documentation: Usage examples and installation guides

### Scope

- **In scope**: Extract MDT integration into pluggable provider pattern
- **Out of scope**: Changing existing worktree creation/removal behavior, path placeholder system

## 2. Desired Outcome

### Success Conditions

- Users without `.mdt-config.toml` can use wt alias with full ticket names (e.g., `git wt PROJ-123`)
- MDT users retain auto-prefix behavior (`git wt 101` → `WTA-101`)
- Project code can be configured via git config (alternative to file-based)
- Provider pattern allows adding new ticket system integrations without modifying core
- Core script size reduced by extracting provider logic

### Constraints

- Must maintain backward compatibility with existing MDT integration
- Cannot change existing `git wt` / `git wt-rm` command syntax
- Must support both `.mdt-config.toml` and git config sources
- Must preserve all current error handling and validation behavior

### Non-Goals

- Not changing path placeholder system (`{worktree_name}`, `{project_dir}`)
- Not modifying worktree creation/removal git commands
- Not adding new dependencies beyond Git 2.15+

## Architecture Design
> **Extracted**: Complex architecture — see [architecture.md](.mdt/specs/WTA-002/architecture.md)

**Summary**:
- Pattern: Configuration-Driven Formatting — generic settings define worktree name transformation
- Components: 4 (2 aliases + 2 shared functions)
- Key constraint: Single-file git alias format, input can be anything (numbers or text)

**Configuration** (`worktree.wt.*` namespace):
- `prefix` — Prefix added to numeric inputs only (e.g., `"ABC-"`, `"#"`)
- `zeroPadDigits` — Zero-pad numbers to N digits (e.g., `3` → `001`)
- `defaultPath` — Path template (renamed from `worktree.defaultPath`, backward compatible)

**Extension Rule**: No code changes needed — just set `worktree.wt.prefix` and `worktree.wt.zeroPadDigits` via git config
## 4. Acceptance Criteria
### Functional (Outcome-focused)

- [ ] User can run `git wt 101` without `.mdt-config.toml` (creates branch "101")
- [ ] User can run `git wt PROJ-123` without `.mdt-config.toml` (creates branch "PROJ-123")
- [ ] User with `.mdt-config.toml` gets auto-prefix behavior unchanged
- [ ] User can configure prefix via `worktree.wt.prefix` git config
- [ ] User can configure zero-padding via `worktree.wt.zeroPadDigits` git config
- [ ] Migration documentation provided for `worktree.defaultPath` → `worktree.wt.defaultPath`

### Non-Functional

- [ ] Core script reduced by ~20-30 lines (shared functions extraction)
- [ ] No duplication between `wt` and `wt-rm` aliases
- [ ] All existing tests updated to use new config namespace
- [ ] Installation process updated with migration instructions

### Edge Cases

- [ ] Text input (non-numeric) passes through without prefix
- [ ] Already-prefixed input (`PROJ-123`) used as-is
- [ ] `.mdt-config.toml` exists but `code` field is empty → fall back to git config
- [ ] Neither file nor git config has prefix → use input as-is
- [ ] Both `.mdt-config.toml` and git config have prefix → git config takes precedence

> **Full EARS requirements**: [requirements.md](./requirements.md) — behavioral requirements specification
## 5. Verification

### How to Verify Success

- **Manual verification**: Test `git wt` commands in repo without `.mdt-config.toml`
- **Manual verification**: Test `git wt` commands in repo with `.mdt-config.toml` (existing behavior preserved)
- **Automated verification**: Existing Bats test suite passes without modification
- **Documentation**: README and manual updated with new configuration options
- **Code review**: No duplicated project code resolution logic between aliases