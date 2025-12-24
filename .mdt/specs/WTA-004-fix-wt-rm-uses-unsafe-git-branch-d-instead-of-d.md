---
code: WTA-004
status: Implemented
dateCreated: 2025-12-24T14:47:36.214Z
type: Bug Fix
priority: High
blocks: WTA-003
implementationDate: 2025-12-24
implementationNotes: Changed git branch -D to git branch -d on line 328 of install_aliases.sh. Also improved WT_TEST_RESPONSE handling to support sequential multi-line responses for automated testing (lines 283-293 and 316-326). All 79 tests pass including 4 new tests for WTA-004.
---

# Fix wt-rm uses unsafe git branch -D instead of -d

## 1. Description

### Problem
- Current `wt-rm` uses `git branch -D` (force delete) which removes branches without checking for unmerged commits
- Unmerged commits are silently discarded, risking permanent data loss
- Users expect standard Git safety behavior where unmerged branches are protected by default

### Affected Areas
- `install_aliases.sh` - `wt-rm` alias function, line 316

### Scope
- **Changes**: Change `git branch -D` to `git branch -d`
- **Unchanged**: All other `wt-rm` behavior (worktree removal, prompts, path resolution)

## 2. Desired Outcome

### Success Conditions
- When `wt-rm` attempts to delete a branch with unmerged commits, Git rejects the deletion
- Standard Git error message is displayed indicating branch is not fully merged
- Branch is preserved, allowing user to manually merge or force-delete if intended

### Constraints
- Must maintain existing confirmation prompt flow (lines 310-320)
- Must preserve `WT_TEST_RESPONSE` environment variable support

## 3. Acceptance Criteria

### Functional
- [ ] `wt-rm` on branch with unmerged commits fails with standard Git error
- [ ] Branch is preserved when unmerged commits detected
- [ ] `wt-rm` on fully merged branch succeeds (same as current behavior)

### Edge Cases
- What happens when branch was never merged to any other branch
- What happens when branch contains only merge commits

## 4. Verification

### How to Verify Success
- **Manual verification**:
  1. Create worktree with unique commits: `git wt 001`, make commits
  2. Run `git wt-rm 001`
  3. Verify Git error appears: "error: The branch 'WTA-001' is not fully merged"
  4. Verify branch still exists: `git branch | grep WTA-001`
- **Automated verification**:
  - Script creates worktree with unmerged commits
  - Run `wt-rm` and verify exit code is non-zero
  - Verify branch still exists in refs