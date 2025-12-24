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
  - `--merge` flag for merging into current branch
  - `--merge-to TARGET` flag for explicit target with checkout workflow
  - `--delete-unmerged` flag to bypass unmerged protection (renamed from `--force`)
  - `--quiet` flag for non-interactive automation
  - `worktree.wt.autoMerge` config for auto-merge (default: false, accepts: true/on/yes/1)
  - Interactive prompt when unmerged commits detected (if auto-merge not enabled)
  - Merge conflict handling (Git default - preserve for resolution)
- **Out of scope**:
  - Changes to `git wt` (worktree creation)
  - Remote branch operations
  - Worktree path resolution logic
## Architecture Design
> **Extracted**: Complex architecture — see [architecture.md](./architecture.md)

**Summary**:
- Pattern: Command Workflow with Flag Modulation
- Components: 6 (Flag Parser, Unmerged Detector, Merge Orchestrator, Branch Deleter, Prompt Handler, main logic)
- Key constraint: CurrentMerge reached via `--merge` OR `autoMerge=true|on|yes|1` (default: false)

**Key Decisions**:
- `--merge` — Merge into current branch (no checkout needed)
- `--merge-to TARGET` — Explicit target with checkout workflow
- `--delete-unmerged` — Bypass merge protection (renamed from `--force` for clarity)
- `--quiet` — Skip all prompts for automation
- `worktree.wt.autoMerge` — Config enabling same behavior as `--merge` (default: false, accepts: true/on/yes/1)
- Git default conflict handling — Leave worktree in conflicted state for manual resolution

**Extension Rule**: To add new flag, add parsing in `_wt_parse_flags()` (limit 30 lines) and behavior case in main logic (limit 80 lines).
## Desired Outcome
(This section removed during clarification - content was under Open Questions)
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
- [ ] `git wt-rm 123` detects unmerged commits and prompts user (when autoMerge=false, no --merge flag)
- [ ] User responding `y` or `yes` (case-insensitive) triggers merge into current branch
- [ ] User responding `n` or `no` (case-insensitive) preserves branch
- [ ] `git wt-rm --merge 123` merges into current branch without prompting
- [ ] `git wt-rm --merge-to main 123` switches to main, merges, switches back
- [ ] `git wt-rm --delete-unmerged 123` deletes branch regardless of unmerged status
- [ ] `git wt-rm --quiet 123` uses defaults without prompting
- [ ] When `worktree.wt.autoMerge=true`, auto-merge behaves as if `--merge` was passed
- [ ] Successful merge results in branch deletion
- [ ] Failed merge (conflicts) preserves worktree and branch with error message
- [ ] Branches without unmerged commits behave identically to current implementation
### Non-Functional
- [ ] Exit code 0 when operation completes successfully
- [ ] Exit code non-zero when operation fails
- [ ] `WT_TEST_RESPONSE` environment variable is respected for automation
- [ ] No changes to behavior when no unmerged commits exist

### Edge Cases
- [ ] Merge target branch does not exist → error message, branch preserved
- [ ] Worktree has uncommitted changes → Git error, worktree preserved
- [ ] User currently inside worktree being removed → error message, abort
- [ ] Multiple worktrees reference same branch → only delete if no other worktrees
- [ ] Branch already deleted but worktree remains → remove worktree only
- [ ] Merge target has unrelated conflicts → Git default (conflicted state)
- [ ] `--merge` when not on target branch → error "not on target branch"
- [ ] `--merge` + `--delete-unmerged` together → error "conflicting flags"
### Requirements Specification
- [`requirements.md`](./requirements.md) — EARS-formatted behavioral requirements
## 5. Verification
### How to Verify Success
- **Manual verification**: 
  - Create feature branch with commits not in main
  - Run `git wt-rm <ticket>` and verify prompt appears (mergeOn=false)
  - Test `y` response: verify merge into current branch, branch deletes
  - Test `n` response: verify branch preserved
  - Test `--merge` flag: verify merge into current branch without prompting
  - Test `--merge-to main` flag: verify checkout workflow, merge, branch deletes
  - Test `--delete-unmerged` flag: verify deletion without prompts
  - Test `--quiet` flag: verify no prompts, respects mergeOn config
  - Test merge conflict: verify worktree preserved, error shown
- **Automated verification**:
  - Use `WT_TEST_RESPONSE` to simulate user input
  - Verify exit codes: 0 (success), 1 (general error), 2 (merge failed), 3 (invalid flags)
  - Verify branch state after each operation

### Session 2025-12-24
- Q: Architecture renamed --force to --delete-unmerged. Should acceptance criteria use the new name? → A: Use --delete-unmerged
- Q: Acceptance criteria say '--merge 123' but architecture specifies '--merge TARGET 123'. Which is correct? → A: Support both. --merge (into the current branch), --merge-to TARGET <- requires branch name. BUT: is it even possible to do merge without activating a target branch?
- Q: Should we support both --merge (current branch) and --merge-to TARGET (explicit) merge modes? → A: Support both, but worktree.wt.mergeOn = true, default: false. If Auto-merge is ON, it's simply replacement for passing --merge.
- Q: Should worktree.wt.mergeOn default to true or false? → A: false (safer)
- Q: Section 'Desired Outcome' is empty but 'Open Questions' has content. Fix structure? → A: Remove empty
- Q: Config naming - mergeOn vs autoMerge? → A: Use autoMerge. Logic: --merge OR autoMerge=true|on|yes|1 → CurrentMerge, default: false

**Applied Updates:**
- Updated Scope: Changed `--force` to `--delete-unmerged`, added `--merge`, `--merge-to TARGET`, `--quiet` flags, specified `autoMerge` config (default: false, accepts: true/on/yes/1)
- Updated Functional acceptance criteria: Replaced `--force` with `--delete-unmerged`, added `--merge` and `--merge-to` cases, clarified auto-merge behavior
- Updated Edge Cases: Added specific scenarios for `--merge` usage, flag conflicts, error conditions
- Updated Verification: Reflects new flag names and exit codes
- Removed empty "Desired Outcome" section (content was under "Open Questions")
- Updated architecture.md: Changed all `mergeOn` references to `autoMerge`, updated state flows to show `--merge OR autoMerge=true` → CurrentMerge
- Updated config reading pattern to accept `true|on|yes|1` as true values

**Key Architecture Clarifications:**
1. Two merge modes: `--merge` (into current branch) and `--merge-to TARGET` (with checkout workflow)
2. Config name: `autoMerge` (not `mergeOn`)
3. Config default: `false` (safer, fail-safe)
4. Config accepted values: `true`, `on`, `yes`, `1` (all enable auto-merge)
5. CurrentMerge state reached via: `--merge` flag OR `autoMerge=true|on|yes|1`
6. When auto-merge enabled, behaves identically to `--merge` flag (merge into current branch)