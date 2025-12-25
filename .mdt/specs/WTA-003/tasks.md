# Tasks: WTA-003

**Source**: [WTA-003](./WTA-003.md)
**Tests**: `tests.md`
**Generated**: 2025-12-24

## Project Context

| Setting | Value |
|---------|-------|
| Source directory | `./` (root) |
| Test command | `bats test/wt_rm_merge_protection.bats` |
| Build command | N/A (bash source script) |
| File extension | `.sh` |

## Size Thresholds

| Module | Default | Hard Max | Action |
|--------|---------|----------|--------|
| `_wt_has_unmerged()` | 15 lines | 25 lines | Flag at 15+, STOP at 25+ |
| `_wt_prompt()` | 20 lines | 30 lines | Flag at 20+, STOP at 30+ |
| `_wt_parse_flags()` | 30 lines | 45 lines | Flag at 30+, STOP at 45+ |
| `_wt_merge_branch()` | 40 lines | 60 lines | Flag at 40+, STOP at 60+ |
| `wt-rm main logic` | 80 lines | 120 lines | Flag at 80+, STOP at 120+ |

*(From Architecture Design)*

## Shared Patterns

| Pattern | Extract To | Used By |
|---------|------------|---------|
| Prompt with `WT_TEST_RESPONSE` support | `_wt_prompt()` helper | Merge prompt, worktree removal prompt |
| Unmerged detection | `_wt_has_unmerged()` helper | Main wt-rm logic before deletion |
| Flag parsing | `_wt_parse_flags()` helper | Main wt-rm logic for all flag handling |
| Config reading with fallback | Inline in `_wt_parse_flags()` | `worktree.wt.autoMerge` config |

> Internal tasks extract shared patterns BEFORE adding main merge logic.

## Architecture Structure

```
install_aliases.sh
  └── wt-rm alias (lines 165-325)
      ├── _wt_resolve_worktree_path()     [existing, unchanged]
      ├── _wt_build_worktree_name()       [existing, unchanged]
      ├── _wt_has_unmerged()              [new, ~15 lines]
      ├── _wt_prompt()                    [new, ~20 lines]
      ├── _wt_parse_flags()               [new, ~30 lines]
      ├── _wt_merge_branch()              [new, ~40 lines]
      └── main logic                      [modified, ~80 lines]
          ├── Parse flags
          ├── Check unmerged
          ├── Decide action (merge/delete/fail)
          ├── Execute merge (if needed)
          └── Delete branch (with -d or -D)
```

## STOP Conditions

- File exceeds Hard Max → STOP, subdivide further
- Duplicating logic that exists in shared module → STOP, import/use shared function
- Structure path doesn't match Architecture Design → STOP, clarify
- Missing WT_TEST_RESPONSE support → STOP, must preserve testing capability

## Test Coverage (from tests.md)

| Test | Requirement | Task | Status |
|------|-------------|------|--------|
| `detects unmerged commits before deletion` | R1.1, R1.2 | Task 1.1 | 🔴 RED |
| `proceeds with deletion when no unmerged commits` | R1.3 | Task 1.1 | 🔴 RED |
| `merges when user responds yes to prompt` | R2.1, R2.2 | Task 2.2, Task 4 | 🔴 RED |
| `preserves branch when user responds no to prompt` | R2.1, R2.3 | Task 2.2, Task 4 | 🔴 RED |
| `respects WT_TEST_RESPONSE environment variable` | R2.4 | Task 2.1 | 🔴 RED |
| `accepts case-insensitive yes responses` | R2.2 | Task 2.1 | 🔴 RED |
| `merges without prompt when --merge flag provided` | R3.1, R3.2, R3.4 | Task 3, Task 4 | 🔴 RED |
| `preserves worktree on merge conflict with --merge flag` | R3.3, R9.1 | Task 3 | 🔴 RED |
| `exits with code 2 on merge failure` | R3.3, R10.3 | Task 3 | 🔴 RED |
| `merges to explicit target branch with --merge-to` | R4.1, R4.2, R4.5 | Task 3 | 🔴 RED |
| `skips branch switch when already on target` | R4.3 | Task 3 | 🔴 RED |
| `errors when target branch does not exist` | R4.4, R10.2 | Task 3 | 🔴 RED |
| `auto-merges when config is true` | R5.1, R5.2 | Task 3, Task 4 | 🔴 RED |
| `auto-merges when config is 'on'` | R5.1, R5.2 | Task 3, Task 4 | 🔴 RED |
| `auto-merges when config is 'yes'` | R5.1, R5.2 | Task 3, Task 4 | 🔴 RED |
| `auto-merges when config is '1'` | R5.1, R5.2 | Task 3, Task 4 | 🔴 RED |
| `prompts when autoMerge config is false` | R5.1, R5.3 | Task 3, Task 4 | 🔴 RED |
| `flags override autoMerge config` | R5.4 | Task 3 | 🔴 RED |
| `deletes unmerged branch with --delete-unmerged flag` | R6.1, R6.2 | Task 3, Task 4 | 🔴 RED |
| `skips merge prompts with --delete-unmerged flag` | R6.1, R6.3 | Task 4 | 🔴 RED |
| `auto-merges in quiet mode when config is true` | R7.1, R7.2, R7.4 | Task 3, Task 4 | 🔴 RED |
| `fails in quiet mode when autoMerge is false` | R7.1, R7.3, R7.4 | Task 4 | 🔴 RED |
| `skips all prompts in quiet mode` | R7.1, R7.4 | Task 2.1, Task 4 | 🔴 RED |
| `errors on --merge and --merge-to conflict` | R8.1, R10.4 | Task 3 | 🔴 RED |
| `errors on --merge and --delete-unmerged conflict` | R8.2, R10.4 | Task 3 | 🔴 RED |
| `errors on --merge-to and --delete-unmerged conflict` | R8.3, R10.4 | Task 3 | 🔴 RED |
| `errors when removing current worktree` | R9.2, R10.2 | Task 4 | 🔴 RED |
| `preserves worktree on merge conflict` | R9.1, R9.3 | Task 3 | 🔴 RED |
| `removes worktree when branch already deleted` | R9.5 | Task 4 | 🔴 RED |
| `exits with code 0 on successful removal` | R10.1 | Task 4 | 🔴 RED |
| `exits with code 1 on general error` | R10.2 | Task 3, Task 4 | 🔴 RED |
| `exits with code 3 on invalid flag combination` | R10.4 | Task 3 | 🔴 RED |
| `behaves identically to current implementation when no unmerged` | R11.1, R11.2, R11.3 | Task 4 | 🔴 RED |

**TDD Goal**: All tests RED before implementation, GREEN after respective task

---

## TDD Verification

Before starting implementation:
```bash
bats test/wt_rm_merge_protection.bats  # Should show 33 failures
```

After completing each task:
```bash
bats test/wt_rm_merge_protection.bats  # Related tests should pass
```

---

## Task 1.1: Implement _wt_has_unmerged() helper

**Structure**: `install_aliases.sh` → `_wt_has_unmerged()` function within `wt-rm` alias

**Implements**: R1.1, R1.2, R1.3

**Makes GREEN**:
- `detects unmerged commits before deletion` (R1.1, R1.2)
- `proceeds with deletion when no unmerged commits` (R1.3)

**Limits**:
- Default: 15 lines
- Hard Max: 25 lines
- If > 15: ⚠️ flag
- If > 25: ⛔ STOP

**Create**:
- Function that checks if worktree branch has unmerged commits
- Uses `git branch --merged` to check merge status
- Returns exit code: 0 if unmerged, 1 if fully merged
- Takes worktree name as parameter

**Exclude**:
- Merge execution logic (Task 3)
- User prompting logic (Task 2.2)
- Flag parsing (Task 3)

**Anti-duplication**:
- This IS the source detection function — main logic will call this

**Implementation sketch**:
```bash
_wt_has_unmerged() {
    local worktree="$1"
    local current_branch=$(git branch --show-current)

    # Check if worktree branch is in merged list
    if git branch --merged | grep -q "$worktree"; then
        return 1  # Fully merged
    else
        return 0  # Has unmerged commits
    fi
}
```

**Verify**:
```bash
# Count lines in wt-rm function after adding
sed -n '/^    wt-rm(){/,/^    }$/p' install_aliases.sh | wc -l  # Check total size
# Test function manually
git wt-rm  # Should call function, verify return codes
```

**Done when**:
- [ ] 2 tests GREEN (were RED)
- [ ] Function `_wt_has_unmerged()` exists in wt-rm alias
- [ ] Size ≤ 15 lines
- [ ] Returns correct exit codes for merged/unmerged branches

---

## Task 2.1: Implement _wt_prompt() helper with WT_TEST_RESPONSE support

**Structure**: `install_aliases.sh` → `_wt_prompt()` function within `wt-rm` alias

**Implements**: R2.2, R2.4, R7.4

**Makes GREEN**:
- `respects WT_TEST_RESPONSE environment variable` (R2.4)
- `accepts case-insensitive yes responses` (R2.2)
- `skips all prompts in quiet mode` (R7.4) - partially

**Limits**:
- Default: 20 lines
- Hard Max: 30 lines
- If > 20: ⚠️ flag
- If > 30: ⛔ STOP

**Create**:
- Function that prompts user with yes/no question
- Checks `WT_TEST_RESPONSE` environment variable first
- Supports case-insensitive yes/no responses (Y, YES, Yes, y, yes)
- Returns exit code: 0 for yes, 1 for no
- Takes prompt message as parameter
- Respects `--quiet` mode (return default=1/fail when quiet)

**Exclude**:
- Merge-specific logic (this is generic prompt helper)
- Flag state checking (caller handles quiet mode)

**Anti-duplication**:
- Existing wt-rm has prompts at lines 283-292, 310-320 — extract pattern
- This function will be used for ALL interactive prompts

**Implementation sketch**:
```bash
_wt_prompt() {
    local prompt_message="$1"
    local quiet_mode="$2"  # "true" or "false"

    # If quiet mode, return fail (no prompts)
    if [[ "$quiet_mode" == "true" ]]; then
        return 1
    fi

    # Check WT_TEST_RESPONSE first
    if [[ -n "${WT_TEST_RESPONSE:-}" ]]; then
        # Return from env var, consume first value if colon-separated
        local response="${WT_TEST_RESPONSE%%:*}"
        if [[ -z "$response" ]]; then
            response="${WT_TEST_RESPONSE}"
        fi
        # Update WT_TEST_RESPONSE for next prompt
        if [[ "$WT_TEST_RESPONSE" == *:* ]]; then
            export WT_TEST_RESPONSE="${WT_TEST_RESPONSE#*:}"
        else
            unset WT_TEST_RESPONSE
        fi
        [[ "$response" =~ ^[Yy] ]] && return 0 || return 1
    fi

    # Interactive prompt
    read -p "$prompt_message" response
    [[ "$response" =~ ^[Yy][Ee][Ss]*$ ]] && return 0 || return 1
}
```

**Verify**:
```bash
# Test with WT_TEST_RESPONSE
WT_TEST_RESPONSE="y" git wt-rm 123
# Test with quiet flag
git wt-rm --quiet 123
```

**Done when**:
- [ ] 3 tests GREEN (were RED)
- [ ] Function `_wt_prompt()` exists in wt-rm alias
- [ ] Size ≤ 20 lines
- [ ] WT_TEST_RESPONSE support works
- [ ] Case-insensitive responses accepted

---

## Task 2.2: Add interactive merge prompt to main logic

**Structure**: `install_aliases.sh` → `wt-rm` main logic (modified)

**Implements**: R2.1, R2.3

**Makes GREEN**:
- `merges when user responds yes to prompt` (R2.1, R2.2)
- `preserves branch when user responds no to prompt` (R2.1, R2.3)

**Limits**:
- Default: 80 lines (main logic total)
- Hard Max: 120 lines
- If > 80: ⚠️ flag
- If > 120: ⛔ STOP

**From**: existing `wt-rm` main logic
**To**: `wt-rm` main logic with merge prompt integration

**Modify**:
- After unmerged detection (Task 1.1), call `_wt_prompt()` for merge decision
- If yes: proceed to merge (Task 3 will implement)
- If no: exit with message, preserve branch
- Only prompt when: unmerged detected AND no merge flags AND autoMerge is false

**Exclude**:
- Flag parsing logic (Task 3)
- Merge execution (Task 3)
- Unmerged detection (Task 1.1)

**Anti-duplication**:
- Use `_wt_prompt()` from Task 2.1 — do NOT duplicate prompt logic
- Use `_wt_has_unmerged()` from Task 1.1 — do NOT duplicate detection

**Verify**:
```bash
# Create worktree with unmerged commits
git wt 123
cd ../WTA-123
echo "test" > file.txt
git add . && git commit -m "test"
cd -
# Test prompt
git wt-rm 123  # Should prompt, preserve on 'n'
```

**Done when**:
- [ ] 2 tests GREEN (were RED)
- [ ] Main logic calls `_wt_prompt()` after unmerged detection
- [ ] Branch preserved on 'no' response
- [ ] Size ≤ 80 lines (main logic)

---

## Task 3: Implement _wt_parse_flags() and _wt_merge_branch() helpers

**Structure**: `install_aliases.sh` → Two new functions within `wt-rm` alias

**Implements**: R3.1-R3.4, R4.1-R4.5, R5.1-R5.4, R6.1-R6.3, R7.1-R7.4, R8.1-R8.3

**Makes GREEN**:
- `merges without prompt when --merge flag provided` (R3.1, R3.2, R3.4)
- `preserves worktree on merge conflict with --merge flag` (R3.3, R9.1)
- `exits with code 2 on merge failure` (R3.3, R10.3)
- `merges to explicit target branch with --merge-to` (R4.1, R4.2, R4.5)
- `skips branch switch when already on target` (R4.3)
- `errors when target branch does not exist` (R4.4, R10.2)
- All autoMerge config tests (R5.1-R5.4)
- `deletes unmerged branch with --delete-unmerged flag` (R6.1, R6.2)
- `skips merge prompts with --delete-unmerged flag` (R6.1, R6.3)
- `auto-merges in quiet mode when config is true` (R7.1, R7.2, R7.4)
- `fails in quiet mode when autoMerge is false` (R7.1, R7.3, R7.4)
- All flag conflict tests (R8.1-R8.3)
- `exits with code 1 on general error` (R10.2) - partially
- `exits with code 3 on invalid flag combination` (R10.4)

**Limits**:

| Function | Default | Hard Max |
|----------|---------|----------|
| `_wt_parse_flags()` | 30 lines | 45 lines |
| `_wt_merge_branch()` | 40 lines | 60 lines |

If > Default: ⚠️ flag
If > Hard Max: ⛔ STOP

**Create in _wt_parse_flags()**:
- Parse `--merge`, `--merge-to TARGET`, `--delete-unmerged`, `--quiet` flags
- Read `worktree.wt.autoMerge` config (accept: true, on, yes, 1)
- Set global/parent variables: `quiet`, `delete_unmerged`, `merge_mode`, `merge_target`, `auto_merge`
- Detect flag conflicts and exit with code 3

**Create in _wt_merge_branch()**:
- Handle `--merge` mode: merge into current branch
- Handle `--merge-to TARGET` mode: checkout target, merge, checkout back
- Skip checkout if already on target branch
- Check target branch existence before checkout
- Execute `git merge` and capture exit code
- Return exit code: 0 success, 1 general error, 2 merge conflict
- Preserve worktree/branch on merge failure

**Exclude**:
- Main orchestration logic (Task 4)
- Unmerged detection (Task 1.1)
- User prompting (Task 2.1, Task 2.2)

**Anti-duplication**:
- Use `_wt_prompt()` from Task 2.1 if needed
- Do NOT duplicate flag parsing logic
- Do NOT duplicate merge workflow logic

**Implementation sketch for _wt_parse_flags()**:
```bash
_wt_parse_flags() {
    # Initialize variables
    quiet=false
    delete_unmerged=false
    merge_mode=""  # "current" or "explicit"
    merge_target=""
    auto_merge=$(git config worktree.wt.autoMerge 2>/dev/null || echo "false")

    # Normalize auto_merge
    if [[ "$auto_merge" == "true" ]] || [[ "$auto_merge" == "1" ]] || \
       [[ "$auto_merge" == "yes" ]] || [[ "$auto_merge" == "on" ]]; then
        auto_merge=true
    else
        auto_merge=false
    fi

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --merge)
                merge_mode="current"
                shift
                ;;
            --merge-to)
                merge_mode="explicit"
                merge_target="$2"
                shift 2
                ;;
            --delete-unmerged)
                delete_unmerged=true
                shift
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Detect conflicts
    if [[ "$merge_mode" == "current" ]] && [[ -n "$merge_target" ]]; then
        echo "Error: Conflicting flags --merge and --merge-to" >&2
        exit 3
    fi
    if [[ "$merge_mode" == "current" ]] && [[ "$delete_unmerged" == "true" ]]; then
        echo "Error: Conflicting flags --merge and --delete-unmerged" >&2
        exit 3
    fi
    if [[ -n "$merge_target" ]] && [[ "$delete_unmerged" == "true" ]]; then
        echo "Error: Conflicting flags --merge-to and --delete-unmerged" >&2
        exit 3
    fi
}
```

**Implementation sketch for _wt_merge_branch()**:
```bash
_wt_merge_branch() {
    local worktree="$1"
    local mode="$2"  # "current" or "explicit"
    local target="${3:-}"

    if [[ "$mode" == "current" ]]; then
        # Merge into current branch
        git merge "$worktree"
        return $?
    elif [[ "$mode" == "explicit" ]]; then
        # Check target exists
        if ! git rev-parse --verify "$target" >/dev/null 2>&1; then
            echo "Error: Target branch '$target' not found" >&2
            return 1
        fi

        local current_branch=$(git branch --show-current)

        # Skip checkout if already on target
        if [[ "$current_branch" != "$target" ]]; then
            git checkout "$target" || return 1
            git merge "$worktree"
            local merge_result=$?
            git checkout "$current_branch"
            return $merge_result
        else
            git merge "$worktree"
            return $?
        fi
    fi
}
```

**Verify**:
```bash
# Test each flag
git wt-rm --merge 123
git wt-rm --merge-to main 123
git wt-rm --delete-unmerged 123
git wt-rm --quiet 123
# Test conflicts
git wt-rm --merge --merge-to main 123  # Should exit 3
git wt-rm --merge --delete-unmerged 123  # Should exit 3
```

**Done when**:
- [ ] All flag-related tests GREEN (at least 20 tests)
- [ ] `_wt_parse_flags()` ≤ 30 lines
- [ ] `_wt_merge_branch()` ≤ 40 lines
- [ ] All 4 flags parsed correctly
- [ ] autoMerge config read and normalized
- [ ] Flag conflicts detected with exit code 3
- [ ] Merge workflows execute correctly

---

## Task 4: Integrate merge logic into wt-rm main orchestration

**Structure**: `install_aliases.sh` → `wt-rm` main logic (modified)

**Implements**: R9.1-R9.5, R10.1, R11.1-R11.3 (integration)

**Makes GREEN**:
- `errors when removing current worktree` (R9.2, R10.2)
- `removes worktree when branch already deleted` (R9.5)
- `exits with code 0 on successful removal` (R10.1)
- `behaves identically to current implementation when no unmerged` (R11.1, R11.2, R11.3)
- All integration tests from previous tasks

**Limits**:
- Default: 80 lines (main logic total)
- Hard Max: 120 lines
- If > 80: ⚠️ flag
- If > 120: ⛔ STOP

**From**: existing `wt-rm` main logic with partial integration from Tasks 1-3
**To**: Complete `wt-rm` main logic with full merge orchestration

**Modify**:
1. Call `_wt_parse_flags()` at start to process flags
2. Check for current worktree detection (compare `$GIT_DIR`)
3. Call `_wt_has_unmerged()` to check merge status
4. Decision tree:
   - No unmerged → proceed to deletion (use `git branch -d`)
   - Has unmerged AND `--delete-unmerged` → use `git branch -D`
   - Has unmerged AND merge mode → call `_wt_merge_branch()`
     - Success (exit 0) → proceed to deletion with `git branch -d`
     - Failure (exit 1 or 2) → preserve, exit with code
   - Has unmerged AND no merge mode → call `_wt_prompt()` (Task 2.2)
     - Yes → call `_wt_merge_branch()` with current mode
     - No → exit, preserve branch
5. Handle branch already deleted case (remove worktree only)

**Exclude**:
- Helper functions (Tasks 1.1, 2.1, 3) — these are imported
- Flag parsing logic (Task 3) — this is imported
- Merge execution (Task 3) — this is imported

**Anti-duplication**:
- Import `_wt_has_unmerged()` from Task 1.1
- Import `_wt_prompt()` from Task 2.1
- Import `_wt_parse_flags()` and `_wt_merge_branch()` from Task 3
- Do NOT duplicate any logic from helper functions

**Verify**:
```bash
# Test full workflow
git wt 123
cd ../WTA-123
echo "test" > file.txt && git add . && git commit -m "test"
cd -
git wt-rm 123  # Should detect and prompt
git wt-rm --merge 123  # Should merge and delete
git wt-rm --delete-unmerged 123  # Should delete without merge
# Test backward compatibility
git wt 456
cd ../WTA-456
git checkout main  # Fully merged branch
cd -
git wt-rm 456  # Should proceed without prompts
```

**Done when**:
- [ ] All remaining tests GREEN
- [ ] Main logic ≤ 80 lines (excluding helper functions)
- [ ] All flag combinations work correctly
- [ ] Backward compatibility preserved
- [ ] Exit codes correct (0, 1, 2, 3)

---

## Post-Implementation

### Task 5.1: Verify no duplication

```bash
# Check for duplicated prompt logic
grep -n "read -p" install_aliases.sh | grep -v "_wt_prompt"

# Check for duplicated unmerged detection
grep -n "branch --merged" install_aliases.sh | grep -v "_wt_has_unmerged"

# Check for duplicated flag parsing
grep -n "case.*--merge" install_aliases.sh | grep -v "_wt_parse_flags"
```

**Done when**: [ ] Each pattern exists in ONE location only

### Task 5.2: Verify size compliance

```bash
# Check helper function sizes
sed -n '/_wt_has_unmerged()/,/^    }$/p' install_aliases.sh | wc -l  # ≤ 15
sed -n '/_wt_prompt()/,/^    }$/p' install_aliases.sh | wc -l  # ≤ 20
sed -n '/_wt_parse_flags()/,/^    }$/p' install_aliases.sh | wc -l  # ≤ 30
sed -n '/_wt_merge_branch()/,/^    }$/p' install_aliases.sh | wc -l  # ≤ 40

# Check main logic size (exclude helpers)
sed -n '/^    wt-rm(){/,/^    }$/p' install_aliases.sh | wc -l  # ≤ 185 total
```

**Done when**: [ ] No functions exceed hard max limits

### Task 5.3: Run all tests

```bash
cd /Users/kirby/home/worktree-alias
bats test/wt_rm_merge_protection.bats
```

**Done when**: [ ] All 33 tests GREEN

### Task 5.4: Verify backward compatibility

```bash
# Test that existing behavior is unchanged for merged branches
git wt 999
cd ../WTA-999
git checkout main  # Branch is fully merged
cd -
git wt-rm 999  # Should work exactly as before
```

**Done when**: [ ] Existing workflow unchanged for merged branches

---

## Implementation Order

1. **Task 1.1**: `_wt_has_unmerged()` — Foundation for all merge detection
2. **Task 2.1**: `_wt_prompt()` — Generic prompt helper with WT_TEST_RESPONSE
3. **Task 2.2**: Add merge prompt to main logic — Basic interactive flow
4. **Task 3**: Flag parsing + merge execution — All flags and merge modes
5. **Task 4**: Main orchestration integration — Complete workflow
6. **Task 5.1-5.4**: Verification and cleanup — Quality checks

---

## Dependencies

```
Task 1.1 (unmerged detection)
  ↓
Task 2.1 (prompt helper)
  ↓
Task 2.2 (merge prompt integration)
  ↓
Task 3 (flag parsing + merge execution)
  ↓
Task 4 (main orchestration)
  ↓
Task 5.1-5.4 (verification)
```

---

## Exit Codes Reference

| Code | Meaning | Set By |
|------|---------|--------|
| 0 | Success | Task 4 |
| 1 | General error | Task 3, Task 4 |
| 2 | Merge conflict | Task 3 |
| 3 | Invalid flags | Task 3 |

---

*Generated by /mdt:tasks for WTA-003*
