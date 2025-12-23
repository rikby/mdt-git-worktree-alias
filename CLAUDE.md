# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides Git worktree aliases for ticket-based development, designed to integrate with the MDT (Markdown Ticket) system. It enables developers to quickly create isolated workspaces for different tickets using simple commands like `git wt 101`.

## Key Components

### Core Files
- `install_aliases.sh` - Main script containing Git aliases for worktree management
- `git-wt-manual.md` - Comprehensive documentation and usage guide

### MDT Integration
- Project uses MDT system for ticket management
- Project code is "WTA" (worktree-alias)
- Tickets are stored in `.mdt/specs/` directory
- Uses MCP mdt-all for ticket management

## Common Commands

### Setting up worktree aliases
```bash
# Apply the aliases to your git config
source install_aliases.sh

# Or download and apply directly
curl -fsSL https://raw.githubusercontent.com/rikby/mdt-git-worktree-alias/main/install_aliases.sh | bash
```

### Worktree management
```bash
# Create worktree for ticket
git wt 101                    # Creates WTA-101 worktree
git wt WTA-101               # Same as above

# Remove worktree
git wt-rm 101                # Removes WTA-101 worktree and branch

# List worktrees
git worktree list
```

### Configuration
```bash
# Set default worktree path
git config --global worktree.defaultPath ".gitWT/{worktree_name}"
git config worktree.defaultPath "~/worktrees/{worktree_name}"
```

### MDT Commands
```bash
# List projects (uses WTA as project code)
cat .mdt-config.toml | grep 'code = '

# List tickets
mcp__mdt-all__list_crs --project WTA
```

## Architecture

### Worktree Alias System
The script provides two main Git aliases:

1. **`git wt`** - Creates worktrees with intelligent path resolution
   - Reads project code from `.mdt-config.toml`
   - Supports configurable path templates with placeholders
   - Auto-creates branches and directories
   - Handles both relative and absolute paths

2. **`git wt-rm`** - Safely removes worktrees
   - Uses same path resolution logic as creation
   - Interactive confirmation for safety
   - Smart branch cleanup when safe

### Path Placeholders
- `{worktree_name}` - The branch/worktree name (e.g., WTA-123)
- `{project_dir}` - Basename of git repository

### Error Handling
The system includes comprehensive error handling for:
- Missing configuration (interactive setup)
- Duplicate worktrees
- Existing branches without worktrees
- Invalid ticket formats

## Development Notes

- The script integrates with https://github.com/andkirby/markdown-ticket
- Requires Git 2.15+ for worktree support
- Uses Bash/Zsh shell features
- Optional IntelliJ IDEA integration support
- Ticket numbers must be 3-digit format (e.g., 123, MDT-123)