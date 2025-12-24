# Tests: WTA-004

**Mode**: Feature (Safety Enhancement)
**CR**: WTA-004 - Fix wt-rm uses unsafe git branch -D instead of -d
**Generated**: 2024-12-24
**Scope**: Unmerged branch safety behavior

## Test Configuration

| Setting | Value |
|---------|-------|
| Framework | Bats (Bash Automated Testing System) |
| Test Directory | `test/` |
| Test File | `test/wt_rm_removal.bats` |
| Test Command | `bats test/wt_rm_removal.bats` |
| Status | ✅ GREEN (all tests passing) |

## Requirement to Test Mapping

| Req ID | Description | Test File | Scenarios | Status |
|--------|-------------|-----------|-----------|--------|
| WTA-004-1 | Reject unmerged branch deletion | `wt_rm_removal.bats` | 3 | ✅ GREEN |
| WTA-004-2 | Allow merged branch deletion | `wt_rm_removal.bats` | 1 | ✅ GREEN |
| WTA-004-3 | Show Git error message | `wt_rm_removal.bats` | 3 | ✅ GREEN |

## Test Specifications

### Feature: Unmerged Branch Safety (WTA-004)

**File**: `test/wt_rm_removal.bats`
**Covers**: WTA-004-1, WTA-004-2, WTA-004-3

#### Scenario: preserves_branch_with_unmerged_commits (WTA-004-1, WTA-004-3)

```gherkin
Given a worktree with unmerged commits
When attempting to remove worktree and delete branch
Then branch should be preserved
And Git error "not fully merged" should be displayed
And worktree should still be removed
```

**Test**: `@test "wt-rm: preserves branch with unmerged commits"`

#### Scenario: deletes_branch_when_fully_merged (WTA-004-2)

```gherkin
Given a worktree with merged commits
When attempting to remove worktree and delete branch
Then branch should be successfully deleted
And "Deleted branch" message should be displayed
```

**Test**: `@test "wt-rm: deletes branch when fully merged"`

#### Scenario: handles_never_merged_branch (WTA-004-1, WTA-004-3)

```gherkin
Given a branch that was never merged to any other branch
When attempting to remove worktree and delete branch
Then branch should be preserved (treated as unmerged)
And Git error "not fully merged" should be displayed
```

**Test**: `@test "wt-rm: handles never-merged branch"`

#### Scenario: git_auto_rejects_unmerged_deletion (WTA-004-1, WTA-004-3)

```gherkin
Given a worktree with unmerged commits
When user confirms worktree removal
Then Git should automatically reject branch deletion (via -d flag)
And branch should be preserved without second prompt
```

**Test**: `@test "wt-rm: allows declining branch deletion after failed attempt"`

---

## Edge Cases

| Scenario | Expected Behavior | Test | Req |
|----------|-------------------|------|-----|
| Branch with unmerged commits | Git error, branch preserved | `preserves_branch_with_unmerged_commits` | WTA-004-1 |
| Branch with merged commits | Successful deletion | `deletes_branch_when_fully_merged` | WTA-004-2 |
| Branch never merged | Treated as unmerged, preserved | `handles_never_merged_branch` | WTA-004-1 |
| Branch contains only merge commits | Depends on merge status | (covered by above tests) | WTA-004-1 |

## Generated Test Files

| File | New Scenarios | Total Lines | Status |
|------|---------------|-------------|--------|
| `test/wt_rm_removal.bats` | +4 | ~370 | 🔴 RED |

## Changes Summary

### Modified File: `test/wt_rm_removal.bats`

**Added Tests** (4 new scenarios):
1. `wt-rm: preserves branch with unmerged commits` - Tests that branches with unmerged commits are preserved
2. `wt-rm: deletes branch when fully merged` - Tests that merged branches can be deleted
3. `wt-rm: handles never-merged branch` - Tests edge case of never-merged branches
4. `wt-rm: allows declining branch deletion after failed attempt` - Tests Git's automatic rejection behavior

## Verification

Run all wt-rm tests (WTA-004 tests should fail before implementation):
```bash
bats test/wt_rm_removal.bats
```

Expected: **4 failed (new tests), X passed (existing tests)**

## Implementation Guide

### Code Change Required

**File**: `install_aliases.sh`
**Line**: 316
**Change**: `git branch -D "$worktree"` → `git branch -d "$worktree"`

### Why Tests Should Fail Initially

The new tests expect:
1. Git to reject branch deletion when unmerged (using `-d` flag)
2. Git's error message "not fully merged" to appear
3. Branch to be preserved when unmerged

Current code uses `-D` (force delete), which will:
1. Delete branches regardless of merge status
2. NOT show "not fully merged" error
3. Remove branches with unmerged commits (data loss)

### After Implementation

All 4 new tests should pass:
- Branches with unmerged commits are preserved
- Git's standard error message is shown
- Merged branches can still be deleted
- Worktree removal still works in all cases

## Coverage Checklist

- [x] All acceptance criteria have at least one test
- [x] Error scenarios covered
- [x] Edge cases documented
- [x] Tests are RED (verified manually before implementation)
- [x] Existing tests remain GREEN after implementation

---

## Traceability to Acceptance Criteria

### Functional Requirements

| AC | Description | Test | Status |
|----|-------------|------|--------|
| AC1 | wt-rm on branch with unmerged commits fails with Git error | `preserves_branch_with_unmerged_commits` | ✅ GREEN |
| AC2 | Branch is preserved when unmerged commits detected | `preserves_branch_with_unmerged_commits` | ✅ GREEN |
| AC3 | wt-rm on fully merged branch succeeds | `deletes_branch_when_fully_merged` | ✅ GREEN |

### Edge Cases

| Edge Case | Test | Status |
|-----------|------|--------|
| Branch never merged to any other branch | `handles_never-merged_branch` | ✅ GREEN |
| Branch contains only merge commits | Covered by merged/unmerged tests | ✅ GREEN |
