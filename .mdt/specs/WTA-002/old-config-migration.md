  # Git config migration summary
  ## Single repo
```bash
git config worktree.wt.defaultPath "$(git config worktree.defaultPath)"
git config --unset worktree.defaultPath
```
## Global
```bash
git config --global worktree.wt.defaultPath "$(git config --global worktree.defaultPath)"
git config --global --unset worktree.defaultPath
```