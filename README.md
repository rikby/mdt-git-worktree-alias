# Git Worktree Alias

> Simple Git aliases for ticket-based development with worktrees

Transform complex git worktree commands into simple ticket-based workflows. Create isolated workspaces for tickets using `git wt 101` instead of lengthy worktree commands. Integrates with the MDT (Markdown Ticket) system for automatic project code resolution.

## Features

- **Quick worktree creation** - `git wt 101` creates isolated workspace for ticket WTA-101
- **Smart project code detection** - Reads project code from `.mdt-config.toml`
- **Configurable ticket prefix** - Set custom prefixes for numeric inputs
- **Zero-padding support** - Format ticket numbers with leading zeros
- **Flexible path templates** - Configure worktree locations with placeholders
- **Safe worktree removal** - `git wt-rm 101` removes worktrees with confirmation prompts
- **Relative and absolute paths** - Store worktrees inside or outside your repository

## Quick Start

### Prerequisites

- Git 2.15+ (for worktree support)
- Bash or Zsh shell

### Installation

```bash
# Download and apply the alias to your git config
curl -fsSL https://raw.githubusercontent.com/rikby/mdt-git-worktree-alias/main/install_aliases.sh | bash
```

### Basic Usage

```bash
# Configure worktree location (one-time setup)
git config --global worktree.defaultPath "../{project_dir}-{worktree_name}"

# Create a worktree for ticket 101
git wt 101
# Output: Creates .gitWT/WTA-101 (reads project code from .mdt-config.toml)

# Remove the worktree when done
git wt-rm 101
```

## Usage

### Creating Worktrees

```bash
# Use just the ticket number (reads project code from .mdt-config.toml)
git wt 101          # Creates WTA-101

# Use full ticket name
git wt WTA-101      # Creates WTA-101
git wt MDT-205      # Creates MDT-205
```

### Configuring Paths

```bash
# Inside repository
git config --global worktree.defaultPath ".gitWT/{worktree_name}"

# Outside repository (absolute path)
git config --global worktree.defaultPath "~/worktrees/{worktree_name}"

# Include project directory name
git config --global worktree.defaultPath "/worktrees/{project_dir}-{worktree_name}"
```

### Removing Worktrees

```bash
# Remove by ticket number
git wt-rm 101       # Finds and removes WTA-101 worktree and branch

# List all worktrees
git worktree list
```

**Note**: `wt-rm` uses safe branch deletion. If a branch has unmerged commits, the branch is preserved and Git displays a "not fully merged" message. To force delete, use `git branch -D <branch>` manually.

## Testing

```bash
# Run the test suite
bats test/
```

Example output:
```
...
47 tests, 0 failures
```

## Configuration

### Worktree Path (NEW namespace)

```bash
# Recommended: Use new worktree.wt.defaultPath namespace
git config --global worktree.wt.defaultPath ".gitWT/{worktree_name}"

# Legacy: worktree.defaultPath still supported (with fallback)
git config --global worktree.defaultPath ".gitWT/{worktree_name}"
```

### Ticket Prefix and Zero-Padding (NEW)

For non-MDT projects or custom formatting:

```bash
# Set ticket prefix for numeric inputs
git config --global worktree.wt.prefix "ABC-"
git wt 42          # Creates ABC-42

# Set zero-padding for ticket numbers
git config --global worktree.wt.zeroPadDigits 3
git wt 7           # Creates ABC-007

# GitHub-style (hash prefix)
git config --global worktree.wt.prefix "#"
git wt 42          # Creates #42

# JIRA-style (project key + zero-padding)
git config --global worktree.wt.prefix "ASD22-"
git config --global worktree.wt.zeroPadDigits 4
git wt 7           # Creates ASD22-0007
```

### MDT Projects (auto-detection)

Projects with `.mdt-config.toml` get automatic prefix + zero-padding:

```toml
# .mdt-config.toml
code = "WTA"
```

```bash
git wt 12          # Creates WTA-012 (auto)
```

Git config settings override MDT defaults:

```bash
git config worktree.wt.prefix "CUSTOM-"
git wt 12          # Creates CUSTOM-012 (git config wins)
```

### Input Type Detection

The system intelligently handles different input formats:

```bash
# Already prefixed - passes through unchanged
git wt PROJ-123    # Creates PROJ-123

# Pure numeric - applies prefix and zero-padding
git wt 42          # Creates ABC-042 (with prefix="ABC-", zeroPadDigits=3)

# Text input - passes through unchanged (prefix ignored)
git wt feature-login  # Creates feature-login
```

### Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{worktree_name}` | Branch/worktree name | WTA-123 |
| `{project_dir}` | Repository folder name | worktree-alias |

## Resources

- [Comprehensive Documentation](git-wt-manual.md)
- [Release Notes & Migration Guide](RELEASE_NOTES.md)
- [MDT Ticket System](https://github.com/andkirby/markdown-ticket)
- [Report Issues](https://github.com/rikby/mdt-worktree-alias/issues)

## License

MIT License
