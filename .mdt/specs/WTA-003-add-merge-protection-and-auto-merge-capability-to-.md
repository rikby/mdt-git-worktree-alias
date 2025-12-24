---
code: WTA-003
status: Proposed
dateCreated: 2025-12-24T14:46:40.460Z
type: Feature Enhancement
priority: High
dependsOn: WTA-004
---

# Add merge protection and auto-merge capability to git wt-rm

## 1. Description

### Problem
- Current `wt-rm` uses `git branch -D` which force-deletes branches without checking for unmerged commits
- No mechanism to merge branches before deletion, risking loss of unmerged work
- No detection or prompting when branches contain unmerged commits
- Users must manually check branch status before running `wt-rm`

### Affected Areas
- `install_aliases.sh` - `wt-rm` alias function (lines 165-325)
- Branch deletion logic (line 316)
- User interaction prompts (lines 278-292, 310-320)

### Scope
- **In scope**:
  - Unmerged commit detection before branch deletion
  - `--merge` flag for automatic merge before deletion
  - `--force` flag to bypass unmerged protection
  - Interactive prompt when unmerged commits detected
  - Merge conflict handling
- **Out of scope**:
  - Changes to `git wt` (worktree creation)
  - Remote branch operations
  - Worktree path resolution logic

## 2. Desired Outcome

### Success Conditions
- When `wt-rm` detects unmerged commits, it must prompt user before deleting branch
- When user responds with `y*` (case-insensitive), system must merge the branch
- When user responds with `n*` (case-insensitive), branch must be preserved
- When `--merge` flag provided, system must perform merge without prompting
- When `--force` flag provided, system must skip unmerged protection checks
- When merge succeeds, branch must be deleted
- When merge fails (conflicts), system must stop and preserve worktree/branch

### Constraints
- Must maintain backward compatibility with existing `wt-rm` usage
- Must respect `WT_TEST_RESPONSE` environment variable for automated testing
- Must use same path resolution logic as current implementation
- Must preserve existing confirmation prompts for worktree removal
- Must not change behavior for branches without unmerged commits

### Non-Goals
- Not adding rebase capability (only merge)
- Not handling remote branch deletion
- Not modifying the `git wt` command

## 3. Open Questions

| Area | Question | Constraints |
|------|----------|-------------|
| Merge target | Which branch should unmerged work be merged into? | Must support common workflows (main/master/upstream) |
| Conflict handling | What state should worktree/branch be in after merge conflict? | User must be able to resolve conflicts manually |
| Current worktree | What happens if user tries to remove worktree they are currently in? | Git will fail - should we detect earlier? |
| Uncommitted changes | Should we detect uncommitted changes before attempting worktree removal? | `git worktree remove` will fail - should we warn? |
| --force semantics | Should --force also skip confirmation prompts and/or remove worktrees with uncommitted changes? | Must balance safety with power-user needs |
| Flag combinations | What happens with --merge --force together? | Must define clear precedence |
| Quiet mode | Should there be a --quiet flag for automated/non-interactive use? | Must support automation/CI use cases |

### Known Constraints
- Must integrate with existing `_wt_resolve_worktree_path()` function
- Must integrate with existing `_wt_build_worktree_name()` function
- Must preserve `WT_TEST_RESPONSE` support for testing
- Git version compatibility: 2.15+ for worktree support

### Decisions Deferred
- Implementation approach (determined by `/mdt:architecture`)
- Specific merge target selection logic
- Exact error messages and user prompts
- Exit codes for different failure scenarios

## 4. Acceptance Criteria

### Functional (Outcome-focused)
- [ ] `git wt-rm 123` detects unmerged commits and prompts user
- [ ] User responding `y` or `yes` (case-insensitive) triggers merge operation
- [ ] User responding `n` or `no` (case-insensitive) preserves branch
- [ ] `git wt-rm --merge 123` performs merge without prompting
- [ ] `git wt-rm --force 123` deletes branch regardless of unmerged status
- [ ] Successful merge results in branch deletion
- [ ] Failed merge (conflicts) preserves worktree and branch with error message
- [ ] Branches without unmerged commits behave identically to current implementation

### Non-Functional
- [ ] Exit code 0 when operation completes successfully
- [ ] Exit code non-zero when operation fails
- [ ] `WT_TEST_RESPONSE` environment variable is respected for automation
- [ ] No changes to behavior when no unmerged commits exist

### Edge Cases
- What happens when merge target branch does not exist
- What happens when worktree has uncommitted changes
- What happens when user is currently inside the worktree being removed
- What happens when multiple worktrees reference the same branch
- What happens when branch is already deleted but worktree remains
- What happens when merge target has unrelated conflicts

## 5. Verification

### How to Verify Success
- **Manual verification**: 
  - Create feature branch with commits not in main
  - Run `git wt-rm <ticket>` and verify prompt appears
  - Test `y` response: verify merge happens, branch deletes
  - Test `n` response: verify branch preserved
  - Test `--merge` flag: verify automatic merge and deletion
  - Test `--force` flag: verify deletion without prompts
  - Test merge conflict: verify worktree preserved, error shown
- **Automated verification**:
  - Use `WT_TEST_RESPONSE` to simulate user input
  - Verify exit codes for each scenario
  - Verify branch state after each operation