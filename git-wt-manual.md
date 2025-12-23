# Git Worktree Manager (`git wt`) - Complete Guide

Transform complex git worktree management into simple, ticket-based development. `git wt 101` automatically creates isolated workspaces using dynamic path templates and project codes, replacing lengthy git commands with intelligent defaults.

## Quick Start

### 1. First-time Setup
```bash
# Set your worktree location (choose one):
git config --global worktree.wt.defaultPath ".gitWT/{worktree_name}"      # Inside repo
git config --global worktree.wt.defaultPath "~/worktrees/{worktree_name}"  # Outside repo
git config worktree.wt.defaultPath "~/home/my-project-{worktree_name}" # Custom location

# NEW: Include project directory name (e.g., super-mario)
git config --global worktree.wt.defaultPath "/worktrees/{project_dir}-{worktree_name}"
git config --global worktree.wt.defaultPath "../{project_dir}_{worktree_name}"

# Or set per-repo:
git config worktree.wt.defaultPath ".gitWT/{worktree_name}"
```

### 2. Create Worktrees
```bash
# Just 3 digits (reads project code from .prj-config.toml)
git wt 101

# Full ticket name
git wt PRJ-101

# Custom ticket format
git wt PROJ-123
```

### 3. Remove Worktrees
```bash
# Remove by ticket number (automatically finds path)
git wt-rm 101
git wt-rm PRJ-101
git wt-rm PROJ-123

# Manual removal (require full path)
git worktree remove path/to/worktree
```

### 4. Work with Worktrees
```bash
# List all worktrees
git worktree list

# Clean up stale worktrees
git worktree prune
```

---

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Usage](#usage)
5. [Worktree Management](#worktree-management)
6. [Advanced Features](#advanced-features)
7. [IDE Integration](#ide-integration)
8. [Troubleshooting](#troubleshooting)
9. [Examples](#examples)

---

## Overview

`git wt` is a custom Git alias that simplifies creating worktrees for ticket-based development. It automatically:

- Extracts ticket numbers from input
- Reads project configuration from `.prj-config.toml`
- Creates worktrees in configurable locations
- Generates IntelliJ IDEA scope files for focused development
- Supports both relative and absolute paths

### Key Benefits

- **Isolated Development**: Each ticket gets its own worktree
- **IDE Scoping**: Automatic IDEA scope creation for ticket-specific file filtering
- **Flexible Paths**: Store worktrees inside or outside the repository
- **Smart Naming**: Automatically constructs worktree names from project config

---

## Installation

### Prerequisites

- Git 2.15+ (for worktree support)
- Bash/Zsh shell
- Optional: IntelliJ IDEA (for automatic scope support)

### Install the Alias

Use the command from this gist file:
https://gist.github.com/andkirby/e44e984a061a6b61b02249721d11677b#file-git_config_alias_worktree-sh

---

## Configuration

### Global Configuration

Set default worktree location for all repositories:

```bash
# Inside repository (recommended)
git config --global worktree.wt.defaultPath ".gitWT/{worktree_name}"

# Outside repository
git config --global worktree.wt.defaultPath "~/worktrees/{worktree_name}"

# Custom location with project prefix
git config --global worktree.wt.defaultPath "~/home/my-project-{worktree_name}"

# Using $HOME directly (no ~ expansion needed)
git config --global worktree.wt.defaultPath "$HOME/worktrees/{worktree_name}"

# NEW: Include project directory name (e.g., super-mario)
git config --global worktree.wt.defaultPath "/worktrees/{project_dir}-{worktree_name}"
git config --global worktree.wt.defaultPath "../{project_dir}_{worktree_name}"
```

### Local Configuration

Set worktree location for current repository only:

```bash
# Relative to repository root
git config worktree.wt.defaultPath ".gitWT/{worktree_name}"

# Absolute path
git config worktree.wt.defaultPath "/Users/username/worktrees/{worktree_name}"

# Without placeholder (will append worktree name)
git config worktree.wt.defaultPath ".gitWT"

# NEW: Include project directory name
git config worktree.wt.defaultPath "../{project_dir}_{worktree_name}"
git config worktree.wt.defaultPath "~/workspaces/{project_dir}-{worktree_name}"
```

### Project Configuration

Configure project code in `.mdt-config.toml`:

```toml
[project]
name = "Markdown Ticket"
code = "MDT"
cr_path = "docs/CRs"
```

### Ticket Prefix and Zero-Padding Configuration

Set ticket formatting for numeric inputs:

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

### Checking Configuration

```bash
# Check current configuration
git config worktree.wt.defaultPath          # Local config
git config --global worktree.wt.defaultPath # Global config
git config worktree.wt.prefix              # Ticket prefix
git config worktree.wt.zeroPadDigits        # Zero-padding digits

# Check all git configs
git config --list | grep worktree
```

---

## Usage

### Basic Usage

```bash
# Create worktree with just ticket number
git wt 101
# Output: Creates WTA-101 if project code is WTA in .mdt-config.toml

# Create worktree with full ticket name
git wt WTA-101

# Create worktree with custom prefix
git wt PROJ-123
```

### Managing Worktrees

```bash
# List all worktrees
git worktree list

# Switch to a worktree
cd path/to/worktree

# Remove a worktree (deletes branch unless used elsewhere)
git worktree remove path/to/worktree

# Remove worktree but keep branch
git worktree remove --force path/to/worktree

# Clean up stale worktree references
git worktree prune
```

---

## Worktree Management

### Creating Worktrees (`git wt`)

The `git wt` command creates isolated workspaces:

```bash
# Basic usage - just ticket number
git wt 101          # Creates worktree for PRJ-101 (reads project code)

# Full ticket name
git wt PRJ-101      # Creates worktree for PRJ-101

# Custom project codes
git wt PROJ-123     # Creates worktree for PROJ-123
```

**Features:**
- Automatically reads project code from `.prj-config.toml`
- Uses configurable path templates with placeholders
- Creates branches automatically
- Supports both relative and absolute paths

### Removing Worktrees (`git wt-rm`)

The `git wt-rm` command safely removes worktrees using the same ticket logic:

```bash
# Remove by ticket number (automatically finds worktree path)
git wt-rm 101       # Removes PRJ-101 worktree and branch
git wt-rm PRJ-101   # Removes PRJ-101 worktree and branch
git wt-rm PROJ-123  # Removes PROJ-123 worktree and branch
```

**Safety Features:**
- **Path Discovery**: Automatically finds worktree using same config logic as `git wt`
- **Interactive Confirmation**: Prompts before removing worktree and branch
- **Smart Branch Cleanup**: Offers to delete branch if no other worktrees use it
- **Error Handling**: Lists available worktrees if target not found

**Removal Process:**
1. Finds worktree path using `worktree.wt.defaultPath` configuration (with fallback to legacy `worktree.defaultPath`)
2. Confirms removal with user
3. Removes worktree directory
4. Optionally deletes the branch if safe

**Example Output:**
```bash
$ git wt-rm 101
Found worktree: /projects/my-project/.gitWT/PRJ-101
Branch: PRJ-101

Remove worktree and branch? [y/N] y
✓ Removed worktree: /projects/my-project/.gitWT/PRJ-101
Delete branch "PRJ-101"? [y/N] y
✓ Deleted branch: PRJ-101
✓ Worktree removal completed
```

### Manual Worktree Management

For advanced usage, you can still use native git commands:

```bash
# List all worktrees
git worktree list

# Manual removal (requires full path)
git worktree remove /path/to/worktree

# Remove worktree but keep branch
git worktree remove --force /path/to/worktree

# Clean up stale worktree references
git worktree prune
```

---

## Advanced Features

### Path Handling

The script automatically handles:

1. **Relative Paths**: Relative to repository root
   - Config: `.gitWT/{worktree_name}`
   - Result: `/repo/root/.gitWT/PRJ-101`

2. **Absolute Paths**: Full paths from filesystem root
   - Config: `~/worktrees/{worktree_name}`
   - Result: `/Users/username/worktrees/PRJ-101`

3. **Home Directory**: Both `~` and `$HOME` supported
   - Config: `~/worktrees/{worktree_name}` or `$HOME/worktrees/{worktree_name}`

4. **Appending**: If no `{worktree_name}` placeholder
   - Config: `.gitWT`
   - Result: `.gitWT/PRJ-101`

5. **NEW: Project Folder Placeholder**: Uses repository folder name
   - Config: `/worktrees/{project_dir}-{worktree_name}`
   - From repo `/projects/super-mario`, creates: `/worktrees/super-mario-PRJ-123`

   - Config: `../{project_dir}_{worktree_name}`
   - From repo `/projects/super-mario`, creates: `/projects/super-mario_PRJ-123`

### Available Placeholders

- `{worktree_name}`: The branch/worktree name (e.g., PRJ-123, PROJ-456)
- `{project_dir}`: Basename of git repository (e.g., super-mario, my-project)

### Error Handling

The script provides clear error messages:

```bash
# Missing ticket number
$ git wt abc
error: Must include 3-digit ticket number. E.g. "123" or "TICKET-123"

# Worktree already exists
$ git wt 101
error: Worktree already exists at /path/to/worktree
To remove it: git worktree remove /path/to/worktree

# Branch exists without worktree
$ git wt 101
error: Branch "WTA-101" already exists but has no worktree
To create worktree for existing branch: git worktree add /path/to/worktree WTA-101
```

### Migration from worktree.defaultPath

**Note**: The configuration namespace has changed from `worktree.defaultPath` to `worktree.wt.defaultPath`. Existing configurations still work via fallback support.

For migration instructions and breaking changes, see [Release Notes](RELEASE_NOTES.md).

### Interactive Setup

When `worktree.wt.defaultPath` is not configured, the script:

1. Shows warning with explanation
2. Provides examples of different configurations
3. Offers to set default configuration
4. Falls back to `.gitWT/{worktree_name}` if declined

---

## Examples

### Example 1: Standard Setup

```bash
# Initial setup
cd ~/projects/my-project
git config --global worktree.wt.defaultPath ".gitWT/{worktree_name}"

# Create worktrees
git wt 101  # Creates .gitWT/WTA-101
git wt 102  # Creates .gitWT/WTA-102

# Work on ticket 101
cd .gitWT/WTA-101
# (IDEA automatically has ticket 101 scope)
```

### Example 2: External Worktrees

```bash
# Setup external location
mkdir -p ~/workspaces
git config --global worktree.wt.defaultPath "~/workspaces/{worktree_name}"

# Create worktree
git wt 205  # Creates ~/workspaces/WTA-205

# List worktrees
git worktree list
# ~/projects/my-project           abc1234 [main]
# ~/workspaces/WTA-205                 def5678 [WTA-205]
```

### Example 3: Multiple Projects

```bash
# Project A (MDT prefix)
cd ~/projects/project-a
git config worktree.wt.defaultPath ".gitWT/{worktree_name}"
git wt 001  # Creates .gitWT/WTA-001

# Project B (PROJ prefix)
cd ~/projects/project-b
git config worktree.wt.prefix "PROJ-"
git config worktree.wt.defaultPath ".gitWT/{worktree_name}"
git wt 001  # Creates .gitWT/PROJ-001
```

### Example 4: Project Folder Integration

```bash
# From /projects/super-mario repository
git config --global worktree.wt.defaultPath "/worktrees/{project_dir}-{worktree_name}"

# Creates /worktrees/super-mario-WTA-345
git wt 345

# Relative to parent directory
git config worktree.wt.defaultPath "../{project_dir}_{worktree_name}"

# From /projects/super-mario, creates: /projects/super-mario_WTA-345
git wt 345
```

### Example 5: Custom Path Structure

```bash
# Organized by year
git config --global worktree.wt.defaultPath "~/worktrees/2025/{worktree_name}"

# Creates ~/worktrees/2025/WTA-345
git wt 345

# Combine project directory with organization
git config --global worktree.wt.defaultPath "~/worktrees/{project_dir}/{worktree_name}"

# From /projects/super-mario, creates: ~/worktrees/super-mario/WTA-345
git wt 345
```

### Example 6: Recover from Stale Worktree

```bash
# Worktree directory deleted but reference remains
git worktree list
# ~/.gitWT/WTA-123  abcdef0 [WTA-123]

# Clean up stale reference
git worktree prune

# Recreate worktree
git wt 123
error: Branch "WTA-123" already exists but has no worktree
# Use the suggested command:
git worktree add .gitWT/WTA-123 WTA-123
```

### Example 7: Worktree Removal with `git wt-rm`

```bash
# List worktrees
git worktree list
# ~/projects/my-project          abc1234 [main]
# ~/projects/my-project/.gitWT/WTA-101  def5678 [WTA-101]

# Remove by ticket number
git wt-rm 101
Found worktree: ~/projects/my-project/.gitWT/WTA-101
Branch: WTA-101

Remove worktree and branch? [y/N] y
✓ Removed worktree: ~/projects/my-project/.gitWT/WTA-101
Delete branch "WTA-101"? [y/N] y
✓ Deleted branch: WTA-101
✓ Worktree removal completed

# Try to remove non-existent worktree
git wt-rm 999
error: Worktree not found at ~/projects/my-project/.gitWT/WTA-999
Listing existing worktrees:
# ~/projects/my-project          abc1234 [main]
```

### Example 8: GitHub-style Hash Prefixes

```bash
# Configure GitHub-style ticket numbering
git config --global worktree.wt.prefix "#"
git config --global worktree.wt.zeroPadDigits 4

# Create worktrees
git wt 42       # Creates #0042
git wt 7        # Creates #0007

# Works with wt-rm too
git wt-rm 42    # Removes #0042
```

### Example 9: JIRA-style Project Keys

```bash
# Configure JIRA-style project with zero-padding
git config --global worktree.wt.prefix "PROJ-"
git config --global worktree.wt.zeroPadDigits 5

# Create worktrees
git wt 123      # Creates PROJ-00123
git wt 7        # Creates PROJ-00007

# Remove by number or full name
git wt-rm 123   # Removes PROJ-00123
git wt-rm PROJ-00123  # Also works
```

### Example 10: Feature Branch Mode

When working with feature branches (no prefix applied):

```bash
# Configure for numeric tickets
git config --global worktree.wt.prefix "TICKET-"

# Numeric inputs get prefix
git wt 42       # Creates TICKET-42

# Text inputs pass through unchanged
git wt feature-login   # Creates feature-login
git wt bugfix-ui       # Creates bugfix-ui

# Removal works with both formats
git wt-rm 42     # Removes TICKET-42
git wt-rm feature-login  # Removes feature-login
```

---

## Best Practices

1. **Consistent Naming**: Always use the same project prefix across repositories
2. **Regular Cleanup**: Run `git worktree prune` periodically
3. **Backup Strategy**: Worktrees share `.git` directory, backup the main repo
4. **IDE Integration**: Use the automatic IDEA scopes for focused development
5. **Configuration**: Use global config for personal preferences, local for team standards

## Tips

- Use `git worktree add` directly for existing branches
- Combine with other git aliases: `git config --global alias.sw 'cd $(git worktree list | grep $(git branch --show-current) | cut -f1)'`
- Create aliases for common operations: `git config --global alias.wtlist 'git worktree list'`
- Use with git hooks for additional automation