---
code: WTA-001
status: Proposed
dateCreated: 2025-12-22T17:01:34.218Z
type: Feature Enhancement
priority: Medium
---

# Git Worktree Manager Implementation

## 1. Description

### Problem
- Git worktree management requires complex commands and path knowledge
- Manual worktree creation leads to inconsistent organization
- No integration with ticket-based development workflows
- Missing automated branch/worktree cleanup processes

### Affected Artifacts
- `git_config_alias_worktree.sh` - Git alias definitions for `wt` and `wt-rm`
- `git-wt-manual.md` - Complete documentation and usage guide
- Git configuration system (`worktree.defaultPath` setting)
- `.mdt-config.toml` integration for project code detection

### Scope
- **Changes**: Creates two git aliases (`wt`, `wt-rm`) with full path template support
- **Unchanged**: Existing git worktree functionality, repository structure

## 2. Decision

### Chosen Approach
Implement git aliases that automate worktree creation/removal using ticket numbers and configurable path templates.

### Rationale
- Reduces cognitive load: `git wt 101` instead of complex git commands
- Enforces consistency: All worktrees follow same naming/path patterns
- Integrates with existing tools: Reads project codes from `.mdt-config.toml`
- Flexible configuration: Supports multiple path strategies via placeholders
- Safe operations: Interactive confirmations and error handling

## 3. Alternatives Considered

| Approach | Key Difference | Why Rejected |
|----------|---------------|--------------|
| **Chosen Approach** | Git aliases with path templates | **ACCEPTED** - Transparent, no external dependencies |
| Shell script wrapper | Separate script file | Requires PATH management, less discoverable |
| Git hooks | Automated on branch creation | Too implicit, user loses control |
| Manual commands | Use native git worktree | Too complex for daily use |

## 4. Artifact Specifications

### New Artifacts

| Artifact | Type | Purpose |
|----------|------|---------|
| `git_config_alias_worktree.sh` | Git alias config | `wt` and `wt-rm` command definitions |
| `git-wt-manual.md` | Documentation | Complete usage guide and examples |

### Modified Artifacts

| Artifact | Change Type | Modification |
|----------|-------------|--------------|
| Git global config | Config added | `alias.wt` and `alias.wt-rm` |
| Git local config | Config added | `worktree.defaultPath` setting |

### Integration Points

| From | To | Interface |
|------|----|-----------|
| `.mdt-config.toml` | Git alias | Project code reading |
| Git config | Alias script | Path template resolution |
| Terminal | Git commands | `git wt` and `git wt-rm` |

### Key Patterns
- Template substitution: `{worktree_name}`, `{project_dir}` placeholders
- Ticket validation: 3-digit number extraction from input
- Path resolution: Relative vs absolute path handling

## 5. Acceptance Criteria
### Functional
- [ ] `git wt 101` creates worktree at configured path with branch MDT-101
- [ ] `git wt MDT-101` creates worktree with explicit ticket name
- [ ] `git wt-rm 101` removes worktree and branch with confirmation
- [ ] Path templates support both relative and absolute paths
- [ ] Project code auto-detection from `.mdt-config.toml`
- [ ] Interactive setup when `worktree.defaultPath` not configured

### Non-Functional
- [ ] Error messages provide clear remediation steps
- [ ] All operations work with Bash/Zsh shells
- [ ] No external dependencies beyond Git 2.15+
- [ ] Backward compatible with existing worktrees

### Testing
- Unit: Ticket number extraction and validation
- Integration: Path template resolution with various configs
- Manual: Create/remove worktrees with different path patterns

> Full EARS requirements: [requirements.md](./requirements.md)
## 6. Verification

### By CR Type
- **Feature**: Aliases `wt` and `wt-rm` exist and expected workflows work
- **Documentation**: Manual covers all configuration options and use cases

## 7. Deployment

### Installation Steps
```bash
# Add git aliases
git config --global alias.wt '!f() { ... }; f'
git config --global alias.wt-rm '!f() { ... }; f'

# Configure default path
git config --global worktree.defaultPath ".gitWT/{worktree_name}"
```