# Git Worktree Alias

> Simple Git aliases for ticket-based development with worktrees

Transform complex git worktree commands into simple ticket-based workflows. Create isolated workspaces for tickets using `git wt 101` instead of lengthy worktree commands. Integrates with the MDT (Markdown Ticket) system for automatic project code resolution.

## Features

- **Quick worktree creation** - `git wt 101` creates isolated workspace for ticket WTA-101
- **Smart project code detection** - Reads project code from `.mdt-config.toml`
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
git config --global worktree.defaultPath ".gitWT/{worktree_name}"

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

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{worktree_name}` | Branch/worktree name | WTA-123 |
| `{project_dir}` | Repository folder name | worktree-alias |

## Resources

- [Comprehensive Documentation](git-wt-manual.md)
- [MDT Ticket System](https://github.com/andkirby/markdown-ticket)
- [Report Issues](https://github.com/rikby/mdt-worktree-alias/issues)

## License

MIT License
