# Release Notes

## v0.2.0 (2025-12-23)

**Generic Configuration Model** - Decoupled from MDT-specific integration, now supports any ticket system.

### New Features

- **Configurable ticket prefix** - Set custom prefixes via `worktree.wt.prefix`
- **Zero-padding support** - Format ticket numbers with `worktree.wt.zeroPadDigits`
- **Generic input handling** - Accepts any input (tickets, feature branches, text)
- **New config namespace** - All settings now under `worktree.wt.*`

### Configuration Examples

```bash
# GitHub-style (hash prefix)
git config worktree.wt.prefix "#"

# JIRA-style (project key + zero-padding)
git config worktree.wt.prefix "PROJ-"
git config worktree.wt.zeroPadDigits 4

# MDT projects still work with auto-detection
# (.mdt-config.toml code field used automatically)
```

### Breaking Changes

**Config namespace renamed**: `worktree.defaultPath` → `worktree.wt.defaultPath`

- Your existing `worktree.defaultPath` configurations will still work (fallback support)
- New namespace takes precedence when both are set
- Migration recommended (see below)

### Migration Guide

#### Check if you need to migrate

```bash
# Check if you have old config
git config worktree.defaultPath
git config --global worktree.defaultPath
```

#### Single repository migration

```bash
# Migrate to new namespace
old_path=$(git config worktree.defaultPath)
git config worktree.wt.defaultPath "$old_path"
git config --unset worktree.defaultPath
```

#### Global migration

```bash
# Migrate to new namespace
old_path=$(git config --global worktree.defaultPath)
git config --global worktree.wt.defaultPath "$old_path"
git config --global --unset worktree.defaultPath
```

### Behavior Changes

| Input | v0.1.0 | v0.2.0 |
|-------|-------|-------|
| `git wt abc` | ❌ Error (no 3-digit) | ✅ Creates `abc` |
| `git wt 12` | Creates `12` | Creates `PROJ-012` (with padding) |
| `git wt feature-login` | ❌ Error | ✅ Creates `feature-login` |

### Removed Tests

3 tests removed (tested obsolete behavior):
- `error: rejects input without 3-digit ticket number`
- `error: rejects input with 2-digit number`
- `error: invalid ticket number format`

---

## v0.1.0 (2025-12-23)

Initial release. Git worktree aliases for creating ticket-based development workspaces with MDT integration.

- Worktree creation and removal aliases (`git wt`, `git wt-rm`)
- Automatic project code detection from MDT config
- Configurable worktree path templates
- Interactive first-time setup
- Comprehensive test coverage

---
