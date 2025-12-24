# Requirements: WTA-003

**Source**: [WTA-003](./WTA-003.md)
**Generated**: 2025-12-24
**CR Type**: Feature Enhancement

## Introduction

WTA-003 extends the `git wt-rm` command to detect unmerged commits before branch deletion and provide options for merging unmerged work. Currently, `wt-rm` uses `git branch -D` which force-deletes branches without checking for unmerged commits, risking loss of work. The enhancement adds merge protection, merge execution capabilities, and automation support while maintaining backward compatibility for branches without unmerged commits.

## Requirements

### Requirement 1: Unmerged Commit Detection

**Objective**: As a developer using `wt-rm`, I want the system to detect unmerged commits before deleting a branch, so that I don't accidentally lose work that hasn't been merged.

#### Acceptance Criteria

1. WHEN the `wt-rm` command is executed, the `Unmerged Detector` shall check if the target branch contains commits not present in the current branch.
2. WHILE the branch has unmerged commits, the `wt-rm` command shall prevent deletion unless the user explicitly opts out.
3. WHEN the branch has no unmerged commits, the `wt-rm` command shall proceed with deletion using the existing deletion logic.

### Requirement 2: Interactive Merge Prompt

**Objective**: As a developer removing a worktree with unmerged commits, I want to be prompted with the option to merge, so that I can preserve my work without manually running merge commands.

#### Acceptance Criteria

1. WHEN unmerged commits are detected AND no merge mode flag is specified AND `autoMerge` config is false, the `Prompt Handler` shall display a prompt asking whether to merge into the current branch.
2. WHEN the user responds with `y` or `yes` (case-insensitive) to the merge prompt, the `Merge Orchestrator` shall execute merge into the current branch.
3. WHEN the user responds with `n` or `no` (case-insensitive) to the merge prompt, the `wt-rm` command shall preserve the branch and worktree without modification.
4. IF the `WT_TEST_RESPONSE` environment variable is set, THEN the `Prompt Handler` shall read response from the variable instead of prompting interactively.

### Requirement 3: Explicit Merge Flag (--merge)

**Objective**: As a developer who knows I want to merge, I want to use a `--merge` flag to bypass prompting, so that I can efficiently remove worktrees without interaction.

#### Acceptance Criteria

1. WHEN the `--merge` flag is provided, the `Flag Parser` shall set the merge mode to "current branch".
2. WHEN merge mode is "current branch" and unmerged commits exist, the `Merge Orchestrator` shall execute merge into the current branch without prompting.
3. IF a merge conflict occurs during merge, THEN the `Merge Orchestrator` shall preserve the worktree and branch, exit with error code 2, and display an error message.
4. WHEN the merge completes successfully, the `Branch Deleter` shall proceed with branch deletion.

### Requirement 4: Explicit Target Merge Flag (--merge-to TARGET)

**Objective**: As a developer who wants to merge into a specific branch, I want to use `--merge-to TARGET`, so that I can merge into main, master, or any other target branch.

#### Acceptance Criteria

1. WHEN the `--merge-to TARGET` flag is provided, the `Flag Parser` shall set the merge mode to "explicit target" and store the target branch name.
2. WHEN merge mode is "explicit target", the `Merge Orchestrator` shall switch to the target branch, merge the worktree branch, and switch back to the original branch.
3. WHILE the current branch already matches the target branch, the `Merge Orchestrator` shall skip the branch switch operation.
4. IF the target branch does not exist, THEN the `Merge Orchestrator` shall exit with error code 1 and display "Target branch not found".
5. WHEN the merge completes successfully, the `Branch Deleter` shall proceed with branch deletion.

### Requirement 5: Auto-Merge Configuration

**Objective**: As a developer who always wants to merge unmerged work, I want to set `worktree.wt.autoMerge = true`, so that merge happens automatically without prompting or flags.

#### Acceptance Criteria

1. WHEN the `autoMerge` config is set to `true`, `on`, `yes`, or `1`, the `Flag Parser` shall enable auto-merge mode.
2. WHILE auto-merge mode is enabled AND unmerged commits are detected, the `Merge Orchestrator` shall execute merge into the current branch without prompting.
3. WHEN auto-merge mode is disabled (default: `false`), the `wt-rm` command shall require either a merge flag or interactive prompt response to proceed with merge.
4. WHEN a merge flag (`--merge` or `--merge-to`) is provided, the `Flag Parser` shall override the `autoMerge` config setting.

### Requirement 6: Force Delete Flag (--delete-unmerged)

**Objective**: As a developer who wants to intentionally discard unmerged work, I want to use `--delete-unmerged`, so that I can remove branches and worktrees without merging.

#### Acceptance Criteria

1. WHEN the `--delete-unmerged` flag is provided, the `Flag Parser` shall set the force delete mode.
2. WHILE force delete mode is enabled, the `Branch Deleter` shall use `git branch -D` to delete the branch regardless of unmerged commit status.
3. WHEN force delete mode is enabled, the `wt-rm` command shall skip merge prompts and merge execution.

### Requirement 7: Quiet Mode Flag (--quiet)

**Objective**: As a developer using automation or CI/CD pipelines, I want to use `--quiet`, so that the command operates non-interactively using default behaviors.

#### Acceptance Criteria

1. WHEN the `--quiet` flag is provided, the `Flag Parser` shall set quiet mode.
2. WHILE quiet mode is enabled AND unmerged commits are detected AND `autoMerge` is true, the `Merge Orchestrator` shall merge into the current branch without prompting.
3. WHILE quiet mode is enabled AND unmerged commits are detected AND `autoMerge` is false, the `wt-rm` command shall fail with error without prompting.
4. WHEN quiet mode is enabled, the `Prompt Handler` shall skip all interactive prompts and use default behaviors.

### Requirement 8: Flag Conflict Detection

**Objective**: As a developer, I want to receive clear error messages when I specify conflicting flags, so that I can correct my command instead of experiencing unexpected behavior.

#### Acceptance Criteria

1. WHEN both `--merge` and `--merge-to TARGET` flags are provided together, the `Flag Parser` shall exit with error code 3 and display "Conflicting flags".
2. WHEN both `--merge` and `--delete-unmerged` flags are provided together, the `Flag Parser` shall exit with error code 3 and display "Conflicting flags".
3. WHEN both `--merge-to TARGET` and `--delete-unmerged` flags are provided together, the `Flag Parser` shall exit with error code 3 and display "Conflicting flags".

### Requirement 9: Error Handling and Edge Cases

**Objective**: As a developer, I want clear error messages and preserved state when errors occur, so that I can recover without losing work.

#### Acceptance Criteria

1. IF a merge conflict occurs during merge execution, THEN the `Merge Orchestrator` shall preserve the worktree and branch in their current state, exit with error code 2, and display an error message.
2. IF the user is currently inside the worktree being removed, THEN the `wt-rm` command shall exit with error code 1 and display "Cannot remove current worktree".
3. IF the worktree contains uncommitted changes, THEN the Git `worktree remove` command shall fail with a Git error message and preserve the worktree.
4. WHEN multiple worktrees reference the same branch, the `Branch Deleter` shall delete the branch only after all associated worktrees are removed.
5. WHEN the branch is already deleted but the worktree remains, the `wt-rm` command shall remove the worktree only.

### Requirement 10: Exit Codes

**Objective**: As a developer or automation script, I want consistent exit codes, so that I can programmatically determine the outcome of the `wt-rm` command.

#### Acceptance Criteria

1. WHEN the `wt-rm` command completes successfully (worktree removed, branch deleted), the command shall exit with code 0.
2. WHEN a general error occurs (invalid usage, worktree not found, target branch not found), the command shall exit with code 1.
3. WHEN a merge fails due to conflicts or merge errors, the command shall exit with code 2.
4. WHEN invalid flag combinations are detected, the command shall exit with code 3.

### Requirement 11: Backward Compatibility

**Objective**: As a developer using the existing `wt-rm` command, I want branches without unmerged commits to behave identically to the current implementation, so that my workflow is not disrupted.

#### Acceptance Criteria

1. WHEN the target branch has no unmerged commits, the `wt-rm` command shall proceed with deletion using `git branch -d` without invoking merge logic.
2. WHEN no merge-related flags are provided and the branch has no unmerged commits, the `wt-rm` command shall follow the existing deletion workflow.
3. WHILE the branch is fully merged into the current branch, the `Unmerged Detector` shall skip merge detection prompts and proceed to deletion.

---

## Artifact Mapping

| Req ID | Requirement Summary | Primary Artifact | Integration Points |
|--------|---------------------|------------------|-------------------|
| R1.1 | Detect unmerged commits on wt-rm execution | `install_aliases.sh` → `_wt_has_unmerged()` | `git branch --merged` |
| R1.2 | Prevent deletion when unmerged commits exist | `install_aliases.sh` → `wt-rm` main logic | `_wt_has_unmerged()` |
| R1.3 | Proceed with deletion when no unmerged commits | `install_aliases.sh` → `wt-rm` main logic | `_wt_has_unmerged()` |
| R2.1 | Display merge prompt when unmerged detected | `install_aliases.sh` → `_wt_prompt()` | `WT_TEST_RESPONSE` env var |
| R2.2 | Execute merge on "y" or "yes" response | `install_aliases.sh` → `_wt_merge_branch()` | `git merge` |
| R2.3 | Preserve branch on "n" or "no" response | `install_aliases.sh` → `wt-rm` main logic | Exit without deletion |
| R2.4 | Read response from WT_TEST_RESPONSE when set | `install_aliases.sh` → `_wt_prompt()` | `WT_TEST_RESPONSE` env var |
| R3.1 | Parse --merge flag | `install_aliases.sh` → `_wt_parse_flags()` | Bash argument parsing |
| R3.2 | Execute merge into current branch without prompt | `install_aliases.sh` → `_wt_merge_branch()` | `git merge` |
| R3.3 | Handle merge conflicts with error code 2 | `install_aliases.sh` → `_wt_merge_branch()` | `git merge` exit code |
| R3.4 | Delete branch after successful merge | `install_aliases.sh` → `Branch Deleter` | `git branch -d` |
| R4.1 | Parse --merge-to TARGET flag | `install_aliases.sh` → `_wt_parse_flags()` | Bash argument parsing |
| R4.2 | Switch to target, merge, switch back | `install_aliases.sh` → `_wt_merge_branch()` | `git checkout`, `git merge` |
| R4.3 | Skip branch switch when already on target | `install_aliases.sh` → `_wt_merge_branch()` | `git branch --show-current` |
| R4.4 | Error when target branch not found | `install_aliases.sh` → `_wt_merge_branch()` | `git rev-parse` |
| R4.5 | Delete branch after successful merge | `install_aliases.sh` → `Branch Deleter` | `git branch -d` |
| R5.1 | Enable auto-merge from config | `install_aliases.sh` → `_wt_parse_flags()` | `git config worktree.wt.autoMerge` |
| R5.2 | Auto-merge into current when enabled | `install_aliases.sh` → `_wt_merge_branch()` | `git merge` |
| R5.3 | Default to false without config | `install_aliases.sh` → `_wt_parse_flags()` | `git config worktree.wt.autoMerge` |
| R5.4 | Flags override autoMerge config | `install_aliases.sh` → `_wt_parse_flags()` | Flag precedence logic |
| R6.1 | Parse --delete-unmerged flag | `install_aliases.sh` → `_wt_parse_flags()` | Bash argument parsing |
| R6.2 | Use git branch -D when enabled | `install_aliases.sh` → `Branch Deleter` | `git branch -D` |
| R6.3 | Skip merge prompts when enabled | `install_aliases.sh` → `wt-rm` main logic | Flag state check |
| R7.1 | Parse --quiet flag | `install_aliases.sh` → `_wt_parse_flags()` | Bash argument parsing |
| R7.2 | Auto-merge in quiet mode when config true | `install_aliases.sh` → `_wt_merge_branch()` | `git merge` |
| R7.3 | Fail in quiet mode when config false | `install_aliases.sh` → `wt-rm` main logic | Exit with error |
| R7.4 | Skip prompts in quiet mode | `install_aliases.sh` → `_wt_prompt()` | Flag state check |
| R8.1 | Error on --merge + --merge-to conflict | `install_aliases.sh` → `_wt_parse_flags()` | Flag validation |
| R8.2 | Error on --merge + --delete-unmerged conflict | `install_aliases.sh` → `_wt_parse_flags()` | Flag validation |
| R8.3 | Error on --merge-to + --delete-unmerged conflict | `install_aliases.sh` → `_wt_parse_flags()` | Flag validation |
| R9.1 | Preserve state on merge conflict | `install_aliases.sh` → `_wt_merge_branch()` | `git merge` exit code |
| R9.2 | Error when in current worktree | `install_aliases.sh` → `wt-rm` main logic | `$GIT_DIR` comparison |
| R9.3 | Git error on uncommitted changes | Git built-in behavior | `git worktree remove` |
| R9.4 | Delete branch only after all worktrees removed | `install_aliases.sh` → `Branch Deleter` | `git worktree list` |
| R9.5 | Remove worktree when branch already deleted | `install_aliases.sh` → `wt-rm` main logic | Error handling |
| R10.1 | Exit code 0 on success | `install_aliases.sh` → `wt-rm` main logic | Exit statement |
| R10.2 | Exit code 1 on general error | `install_aliases.sh` → `wt-rm` main logic | Exit statement |
| R10.3 | Exit code 2 on merge failure | `install_aliases.sh` → `_wt_merge_branch()` | Exit statement |
| R10.4 | Exit code 3 on flag conflict | `install_aliases.sh` → `_wt_parse_flags()` | Exit statement |
| R11.1 | Use git branch -d when no unmerged | `install_aliases.sh` → `Branch Deleter` | `git branch -d` |
| R11.2 | Follow existing workflow when no unmerged | `install_aliases.sh` → `wt-rm` main logic | Existing code paths |
| R11.3 | Skip merge prompts when fully merged | `install_aliases.sh` → `_wt_has_unmerged()` | `git branch --merged` |

## Traceability

| Req ID | CR Section | Acceptance Criteria |
|--------|------------|---------------------|
| R1.1-R1.3 | Section 2: Problem | AC: "git wt-rm 123 detects unmerged commits" |
| R2.1-R2.4 | Section 2: Problem, Scope | AC: "User responding y/yes triggers merge", "User responding n/no preserves branch" |
| R3.1-R3.4 | Section 2: Scope | AC: "git wt-rm --merge 123 merges without prompting" |
| R4.1-R4.5 | Section 2: Scope | AC: "git wt-rm --merge-to main 123 switches, merges, switches back" |
| R5.1-R5.4 | Section 2: Scope | AC: "worktree.wt.autoMerge=true enables auto-merge" |
| R6.1-R6.3 | Section 2: Scope | AC: "git wt-rm --delete-unmerged 123 deletes regardless" |
| R7.1-R7.4 | Section 2: Scope | AC: "git wt-rm --quiet 123 uses defaults without prompting" |
| R8.1-R8.3 | Section 4: Edge Cases | AC: "--merge + --delete-unmerged together → error" |
| R9.1-R9.5 | Section 4: Edge Cases, Section 5: Verification | AC: "Failed merge preserves worktree", "Currently in worktree → error", etc. |
| R10.1-R10.4 | Section 4: Non-Functional | AC: "Exit code 0 when success", "Exit code non-zero when fails" |
| R11.1-R11.3 | Section 2: Scope (Out of scope) | AC: "Branches without unmerged commits behave identically" |

## Non-Functional Requirements

### Performance
- WHEN unmerged detection runs, the `_wt_has_unmerged()` function shall complete within 1 second for repositories with up to 10,000 commits.
- WHEN merge execution runs, the `_wt_merge_branch()` function shall complete within 5 seconds for merges with up to 100 commits, excluding conflict resolution time.

### Reliability
- WHEN the `wt-rm` command is executed, the command shall preserve the worktree and branch state if any error occurs after merge starts.
- IF the merge operation is interrupted (SIGINT/SIGTERM), THEN the command shall preserve the current Git state without partial deletion.

### Consistency
- WHILE multiple `wt-rm` operations may run concurrently on different worktrees, each operation shall not interfere with other worktree states.
- WHEN `autoMerge` config is enabled, the behavior shall be identical to providing the `--merge` flag.

### Maintainability
- WHEN new flags are added, the `_wt_parse_flags()` function shall not exceed 45 lines of code.
- WHEN merge logic is modified, the `_wt_merge_branch()` function shall not exceed 60 lines of code.
- WHEN the main orchestration logic is modified, the wt-rm main logic shall not exceed 120 lines of code.

### Usability
- WHEN an error occurs, the error message shall clearly indicate the problem and suggest resolution steps.
- WHEN conflicting flags are provided, the error message shall list which flags conflict.
- WHEN a merge conflict occurs, the error message shall indicate that the worktree is preserved for manual resolution.

### Testability
- WHEN the `WT_TEST_RESPONSE` environment variable is set, the command shall use it for all prompts in order.
- WHEN automated tests run, the exit codes shall reliably indicate the type of failure (1=general, 2=merge, 3=flags).

---
*Generated from WTA-003 by /mdt:requirements*
