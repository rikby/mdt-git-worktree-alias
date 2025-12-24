# Tests: WTA-003

**Mode**: Feature
**Source**: requirements.md
**Generated**: 2025-12-24
**Scope**: Merge Protection and Auto-Merge Capability

## Test Configuration

| Setting | Value |
|---------|-------|
| Framework | Bats (Bash Automated Testing System) |
| Test Directory | `/Users/kirby/home/worktree-alias/test/` |
| Test File | `wt_rm_merge_protection.bats` |
| Test Command | `bats test/wt_rm_merge_protection.bats` |
| Status | 🔴 RED (implementation pending) |

## Requirement → Test Mapping

| Req ID | Description | Test Name | Scenarios | Status |
|--------|-------------|-----------|-----------|--------|
| R1.1-R1.3 | Unmerged Commit Detection | `detects unmerged commits before deletion`<br>`proceeds with deletion when no unmerged commits` | 2 | 🔴 RED |
| R2.1-R2.4 | Interactive Merge Prompt | `merges when user responds yes to prompt`<br>`preserves branch when user responds no to prompt`<br>`respects WT_TEST_RESPONSE environment variable`<br>`accepts case-insensitive yes responses` | 4 | 🔴 RED |
| R3.1-R3.4 | Explicit Merge Flag | `merges without prompt when --merge flag provided`<br>`preserves worktree on merge conflict with --merge flag`<br>`exits with code 2 on merge failure` | 3 | 🔴 RED |
| R4.1-R4.5 | Explicit Target Merge Flag | `merges to explicit target branch with --merge-to`<br>`skips branch switch when already on target`<br>`errors when target branch does not exist` | 3 | 🔴 RED |
| R5.1-R5.4 | Auto-Merge Configuration | `auto-merges when config is true`<br>`auto-merges when config is 'on'`<br>`auto-merges when config is 'yes'`<br>`auto-merges when config is '1'`<br>`prompts when autoMerge config is false`<br>`flags override autoMerge config` | 6 | 🔴 RED |
| R6.1-R6.3 | Force Delete Flag | `deletes unmerged branch with --delete-unmerged flag`<br>`skips merge prompts with --delete-unmerged flag` | 2 | 🔴 RED |
| R7.1-R7.4 | Quiet Mode Flag | `auto-merges in quiet mode when config is true`<br>`fails in quiet mode when autoMerge is false`<br>`skips all prompts in quiet mode` | 3 | 🔴 RED |
| R8.1-R8.3 | Flag Conflict Detection | `errors on --merge and --merge-to conflict`<br>`errors on --merge and --delete-unmerged conflict`<br>`errors on --merge-to and --delete-unmerged conflict` | 3 | 🔴 RED |
| R9.1-R9.5 | Error Handling and Edge Cases | `errors when removing current worktree`<br>`preserves worktree on merge conflict`<br>`removes worktree when branch already deleted` | 3 | 🔴 RED |
| R10.1-R10.4 | Exit Codes | `exits with code 0 on successful removal`<br>`exits with code 1 on general error`<br>`exits with code 3 on invalid flag combination` | 3 | 🔴 RED |
| R11.1-R11.3 | Backward Compatibility | `behaves identically to current implementation when no unmerged` | 1 | 🔴 RED |

**Total**: 33 test scenarios covering 11 requirements

## Test Specifications

### Feature: Unmerged Commit Detection (R1)

#### Scenario: detects_unmerged_commits_before_deletion (R1.1, R1.2)

```gherkin
Given a worktree with unmerged commits
When wt-rm is executed without merge flags
Then the system should detect unmerged commits and prompt user
And the worktree and branch should be preserved when user declines
```

**Test**: `@test "wt-rm: detects unmerged commits before deletion"`

#### Scenario: proceeds_with_deletion_when_no_unmerged_commits (R1.3)

```gherkin
Given a worktree with fully merged commits
When wt-rm is executed
Then the system should proceed with deletion without merge prompt
And the worktree and branch should be removed successfully
```

**Test**: `@test "wt-rm: proceeds with deletion when no unmerged commits"`

---

### Feature: Interactive Merge Prompt (R2)

#### Scenario: merges_when_user_responds_yes_to_prompt (R2.1, R2.2)

```gherkin
Given unmerged commits are detected
When user responds 'y' or 'yes' (case-insensitive)
Then the system should execute merge into the current branch
And should delete the worktree and branch after successful merge
```

**Test**: `@test "wt-rm: merges when user responds yes to prompt"`

#### Scenario: preserves_branch_when_user_responds_no_to_prompt (R2.1, R2.3)

```gherkin
Given unmerged commits are detected
When user responds 'n' or 'no' (case-insensitive)
Then the system should preserve the worktree and branch
And should show 'Cancelled' message
```

**Test**: `@test "wt-rm: preserves branch when user responds no to prompt"`

#### Scenario: respects_WT_TEST_RESPONSE_environment_variable (R2.4)

```gherkin
Given unmerged commits are detected
When WT_TEST_RESPONSE environment variable is set
Then the system should read response from the variable instead of prompting
And should use the response to make merge decision
```

**Test**: `@test "wt-rm: respects WT_TEST_RESPONSE environment variable"`

#### Scenario: accepts_case_insensitive_yes_responses (R2.2)

```gherkin
Given unmerged commits are detected
When user responds with Y, YES, Yes, y, or yes
Then the system should accept all variants as affirmative response
And should execute merge for all variants
```

**Test**: `@test "wt-rm: accepts case-insensitive yes responses"`

---

### Feature: Explicit Merge Flag (R3)

#### Scenario: merges_without_prompt_when_merge_flag_provided (R3.1, R3.2, R3.4)

```gherkin
Given unmerged commits exist
When --merge flag is provided
Then the system should merge into current branch without prompting
And should delete worktree and branch after successful merge
```

**Test**: `@test "wt-rm: merges without prompt when --merge flag provided"`

#### Scenario: preserves_worktree_on_merge_conflict_with_merge_flag (R3.3)

```gherkin
Given unmerged commits that will cause merge conflict
When --merge flag is provided and merge conflicts
Then the system should preserve worktree and branch
And should exit with error code 2
And should display error message about conflict
```

**Test**: `@test "wt-rm: preserves worktree on merge conflict with --merge flag"`

#### Scenario: exits_with_code_2_on_merge_failure (R3.3, R10.3)

```gherkin
Given merge operation fails due to conflict or error
When --merge flag is provided
Then the system should exit with error code 2
And should preserve worktree and branch state
```

**Test**: `@test "wt-rm: exits with code 2 on merge failure"`

---

### Feature: Explicit Target Merge Flag (R4)

#### Scenario: merges_to_explicit_target_branch_with_merge_to (R4.1, R4.2, R4.5)

```gherkin
Given unmerged commits exist
When --merge-to TARGET flag is provided
Then the system should switch to target branch
And should merge the worktree branch
And should switch back to original branch
And should delete worktree and branch after successful merge
```

**Test**: `@test "wt-rm: merges to explicit target branch with --merge-to"`

#### Scenario: skips_branch_switch_when_already_on_target (R4.3)

```gherkin
Given user is already on the target branch
When --merge-to current_branch flag is provided
Then the system should skip branch switch operation
And should merge directly into current branch
```

**Test**: `@test "wt-rm: skips branch switch when already on target"`

#### Scenario: errors_when_target_branch_does_not_exist (R4.4, R10.2)

```gherkin
Given unmerged commits exist
When --merge-to specifies non-existent target branch
Then the system should exit with error code 1
And should display error message "Target branch not found"
And should preserve worktree and branch
```

**Test**: `@test "wt-rm: errors when target branch does not exist"`

---

### Feature: Auto-Merge Configuration (R5)

#### Scenario: auto_merges_when_config_is_true (R5.1, R5.2)

```gherkin
Given autoMerge config is set to true
When unmerged commits are detected
Then the system should execute merge into current branch without prompting
And should delete worktree and branch after successful merge
```

**Test**: `@test "wt-rm: auto-merges when config is true"`

#### Scenario: auto_merges_for_all_accepted_config_values (R5.1, R5.2)

```gherkin
Given autoMerge config is set to one of: true, on, yes, 1
When unmerged commits are detected
Then the system should execute merge automatically for all values
And should behave identically to --merge flag
```

**Tests**:
- `@test "wt-rm: auto-merges when config is 'on'"`
- `@test "wt-rm: auto-merges when config is 'yes'"`
- `@test "wt-rm: auto-merges when config is '1'"`

#### Scenario: prompts_when_autoMerge_config_is_false (R5.1, R5.3)

```gherkin
Given autoMerge config is set to false
When unmerged commits are detected
Then the system should prompt user for merge decision
And should NOT auto-merge
```

**Test**: `@test "wt-rm: prompts when autoMerge config is false"`

#### Scenario: flags_override_autoMerge_config (R5.4)

```gherkin
Given autoMerge config is true
When --delete-unmerged flag is provided
Then the flag should override the config
And the system should delete without merging
```

**Test**: `@test "wt-rm: flags override autoMerge config"`

---

### Feature: Force Delete Flag (R6)

#### Scenario: deletes_unmerged_branch_with_delete_unmerged_flag (R6.1, R6.2)

```gherkin
Given unmerged commits exist
When --delete-unmerged flag is provided
Then the system should use git branch -D to delete branch
And should skip merge prompts and execution
And should successfully delete worktree and branch
```

**Test**: `@test "wt-rm: deletes unmerged branch with --delete-unmerged flag"`

#### Scenario: skips_merge_prompts_with_delete_unmerged_flag (R6.1, R6.3)

```gherkin
Given unmerged commits exist
When --delete-unmerged flag is provided
Then the system should skip all merge-related prompts
And should proceed directly to deletion
```

**Test**: `@test "wt-rm: skips merge prompts with --delete-unmerged flag"`

---

### Feature: Quiet Mode Flag (R7)

#### Scenario: auto_merges_in_quiet_mode_when_config_is_true (R7.1, R7.2, R7.4)

```gherkin
Given autoMerge config is true
When --quiet flag is provided
Then the system should auto-merge without any prompts
And should successfully delete worktree and branch
```

**Test**: `@test "wt-rm: auto-merges in quiet mode when config is true"`

#### Scenario: fails_in_quiet_mode_when_autoMerge_is_false (R7.1, R7.3, R7.4)

```gherkin
Given autoMerge config is false
When --quiet flag is provided and unmerged commits exist
Then the system should fail with error
And should NOT prompt for user input
And should preserve worktree and branch
```

**Test**: `@test "wt-rm: fails in quiet mode when autoMerge is false"`

#### Scenario: skips_all_prompts_in_quiet_mode (R7.1, R7.4)

```gherkin
Given any prompts would be shown (worktree removal, branch deletion)
When --quiet flag is provided
Then the system should skip all interactive prompts
And should use default behaviors
```

**Test**: `@test "wt-rm: skips all prompts in quiet mode"`

---

### Feature: Flag Conflict Detection (R8)

#### Scenario: errors_on_merge_and_merge_to_conflict (R8.1, R10.4)

```gherkin
Given conflicting merge flags are provided
When both --merge and --merge-to TARGET flags are present
Then the system should exit with error code 3
And should display error message "Conflicting flags"
```

**Test**: `@test "wt-rm: errors on --merge and --merge-to conflict"`

#### Scenario: errors_on_merge_and_delete_unmerged_conflict (R8.2, R10.4)

```gherkin
Given conflicting intent flags are provided
When both --merge and --delete-unmerged flags are present
Then the system should exit with error code 3
And should display error message "Conflicting flags"
```

**Test**: `@test "wt-rm: errors on --merge and --delete-unmerged conflict"`

#### Scenario: errors_on_merge_to_and_delete_unmerged_conflict (R8.3, R10.4)

```gherkin
Given conflicting intent flags are provided
When both --merge-to TARGET and --delete-unmerged flags are present
Then the system should exit with error code 3
And should display error message "Conflicting flags"
```

**Test**: `@test "wt-rm: errors on --merge-to and --delete-unmerged conflict"`

---

### Feature: Error Handling and Edge Cases (R9)

#### Scenario: errors_when_removing_current_worktree (R9.2, R10.2)

```gherkin
Given user is currently inside the worktree being removed
When wt-rm is executed
Then the system should exit with error code 1
And should display error message "Cannot remove current worktree"
And should preserve the worktree and branch
```

**Test**: `@test "wt-rm: errors when removing current worktree"`

#### Scenario: preserves_worktree_on_merge_conflict (R9.1, R9.3)

```gherkin
Given merge operation results in conflict
When merge is attempted via --merge or --merge-to
Then the system should preserve worktree and branch in current state
And should exit with error code 2
And should leave Git in conflicted state for manual resolution
```

**Test**: `@test "wt-rm: preserves worktree on merge conflict"`

#### Scenario: removes_worktree_when_branch_already_deleted (R9.5)

```gherkin
Given worktree exists but branch has already been deleted
When wt-rm is executed
Then the system should remove the worktree
And should not attempt to delete the branch again
```

**Test**: `@test "wt-rm: removes worktree when branch already deleted"`

---

### Feature: Exit Codes (R10)

#### Scenario: exits_with_code_0_on_successful_removal (R10.1)

```gherkin
Given valid worktree with merged or no commits
When wt-rm completes successfully
Then the system should exit with code 0
And both worktree and branch should be removed
```

**Test**: `@test "wt-rm: exits with code 0 on successful removal"`

#### Scenario: exits_with_code_1_on_general_error (R10.2)

```gherkin
Given general error condition occurs
When wt-rm encounters worktree not found or invalid usage
Then the system should exit with code 1
```

**Test**: `@test "wt-rm: exits with code 1 on general error"`

#### Scenario: exits_with_code_3_on_invalid_flag_combination (R10.4)

```gherkin
Given invalid flag combination is provided
When wt-rm is executed with conflicting flags
Then the system should exit with code 3
And should display error about conflicting flags
```

**Test**: `@test "wt-rm: exits with code 3 on invalid flag combination"`

---

### Feature: Backward Compatibility (R11)

#### Scenario: behaves_identically_to_current_implementation_when_no_unmerged (R11.1, R11.2, R11.3)

```gherkin
Given worktree with fully merged commits
When wt-rm is executed without any merge-related flags
Then the system should follow the existing deletion workflow
And should use git branch -d (not -D)
And should NOT show merge prompts
And should behave identically to current implementation
```

**Test**: `@test "wt-rm: behaves identically to current implementation when no unmerged"`

---

## Edge Cases

| Scenario | Expected Behavior | Test | Req |
|----------|-------------------|------|-----|
| User in current worktree | Error code 1, preserve state | `errors when removing current worktree` | R9.2 |
| Merge conflict | Error code 2, preserve conflicted state | `preserves worktree on merge conflict` | R9.1 |
| Branch already deleted | Remove worktree only | `removes worktree when branch already deleted` | R9.5 |
| Target branch not found | Error code 1, show error | `errors when target branch does not exist` | R4.4 |
| Flag conflicts | Error code 3, show conflicting flags | Multiple conflict tests | R8.1-R8.3 |
| Case-insensitive responses | Accept all variants | `accepts case-insensitive yes responses` | R2.2 |
| Multiple autoMerge values | All enable auto-merge | Multiple config value tests | R5.1 |

## Generated Test Files

| File | Scenarios | Lines | Status |
|------|-----------|-------|--------|
| `test/wt_rm_merge_protection.bats` | 33 | ~900 | 🔴 RED |

## Test Structure

The test file is organized into feature sections:

1. **Unmerged Commit Detection** (2 tests)
2. **Interactive Merge Prompt** (4 tests)
3. **Explicit Merge Flag** (3 tests)
4. **Explicit Target Merge Flag** (3 tests)
5. **Auto-Merge Configuration** (6 tests)
6. **Force Delete Flag** (2 tests)
7. **Quiet Mode Flag** (3 tests)
8. **Flag Conflict Detection** (3 tests)
9. **Error Handling and Edge Cases** (3 tests)
10. **Exit Codes** (3 tests)
11. **Backward Compatibility** (1 test)

## Verification

Run all tests (should all fail before implementation):

```bash
cd /Users/kirby/home/worktree-alias
bats test/wt_rm_merge_protection.bats
```

Expected: **33 failed, 0 passed** (all tests RED)

## Coverage Checklist

- [x] All 11 requirements have at least one test
- [x] Error scenarios covered (conflicts, missing targets, flag conflicts)
- [x] Edge cases documented (current worktree, branch deleted, case sensitivity)
- [x] Exit codes verified (0, 1, 2, 3)
- [x] Backward compatibility tested
- [x] Interactive and automated modes covered
- [x] All flag combinations tested
- [x] Configuration values tested (true, on, yes, 1, false)
- [ ] Tests are RED (verified manually - pending implementation)

## For Implementation

Each implementation task should reference which tests it will make GREEN:

| Task | Makes GREEN |
|------|-------------|
| Implement `_wt_has_unmerged()` helper | `detects unmerged commits before deletion`, `proceeds with deletion when no unmerged commits` |
| Implement `_wt_prompt()` helper with WT_TEST_RESPONSE | `respects WT_TEST_RESPONSE environment variable`, `accepts case-insensitive yes responses` |
| Implement `_wt_parse_flags()` helper | All flag-related tests (merge, merge-to, delete-unmerged, quiet) |
| Implement `_wt_merge_branch()` helper for current branch | `merges without prompt when --merge flag provided`, `auto-merges when config is true`, etc. |
| Implement `_wt_merge_branch()` helper for explicit target | `merges to explicit target branch with --merge-to`, `skips branch switch when already on target` |
| Implement flag conflict detection | All flag conflict tests |
| Implement exit code handling | All exit code tests |
| Integrate merge logic into wt-rm main | All integration tests |

After each task: `bats test/wt_rm_merge_protection.bats` should show fewer failures.

---

*Generated by /mdt:tests for WTA-003*
