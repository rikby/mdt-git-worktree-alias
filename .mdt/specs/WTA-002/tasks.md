# Tasks: WTA-002

**Source**: [WTA-002](../WTA-002-decouple-mdt-integration-from-core-worktree-alias-.md)
**Phase**: Non-phased - Generic Configuration Model
**Tests**: `tests.md`
**Generated**: 2025-12-23

## Project Context

| Setting | Value |
|---------|-------|
| Source directory | `./` (single-file script) |
| Test command | `bats test/` |
| Build command | `source install_aliases.sh` (validation) |
| File extension | `.sh` (Bash script) |
| Test filter | `bats test/wt_*.bats` |

## Size Thresholds

| Module | Default | Hard Max | Action |
|--------|---------|----------|--------|
| `_wt_build_worktree_name()` | 50 lines | 75 lines | Flag at 50+, STOP at 75+ |
| `_wt_resolve_worktree_path()` | 40 lines | 60 lines | Flag at 40+, STOP at 60+ |
| `git wt` (alias) | 70 lines | 105 lines | Flag at 70+, STOP at 105+ |
| `git wt-rm` (alias) | 80 lines | 120 lines | Flag at 80+, STOP at 120+ |

*(From Architecture Design)*

**Current totals**: wt (~126 lines), wt-rm (~115 lines)
**Target totals**: wt (~70 lines), wt-rm (~80 lines), shared (~90 lines)

## Shared Patterns

| Pattern | Occurrences | Extract To | Used By |
|---------|-------------|------------|---------|
| Worktree name building (MDT detection, prefix logic) | Lines 16-31 (wt), Lines 143-158 (wt-rm) | `_wt_build_worktree_name()` | `git wt`, `git wt-rm` |
| Path template resolution (placeholders, tilde expansion) | Lines 77-92 (wt), Lines 172-184 (wt-rm) | `_wt_resolve_worktree_path()` | `git wt`, `git wt-rm` |

> These shared functions are extracted FIRST (Tasks 1-2) before refactoring wt/wt-rm.

## Architecture Structure

```
install_aliases.sh
  ├── _wt_build_worktree_name()        → Input transformation (limit 50 lines)
  ├── _wt_resolve_worktree_path()      → Path resolution (limit 40 lines)
  ├── git wt (alias)                   → Worktree creation (limit 70 lines)
  └── git wt-rm (alias)                → Worktree removal (limit 80 lines)
```

## STOP Conditions

- File exceeds Hard Max → STOP, subdivide further
- Duplicating logic that exists in shared module → STOP, import instead
- Structure path doesn't match Architecture Design → STOP, clarify
- Breaking existing MDT behavior → STOP (backward compatibility required)

## Test Coverage (from tests.md)

| Test | Requirement | Task | Status |
|------|-------------|------|--------|
| `wt_generic_prefix.bats` | R1.1-R1.4, R4.2 (5 scenarios) | Task 2 | 🔴 RED |
| `wt_zero_padding.bats` | R2.1-R2.4, R4.1, R4.3 (7 scenarios) | Task 2 | 🔴 RED |
| `wt_input_detection.bats` | R3.1-R3.4 (7 scenarios) | Task 2 | 🔴 RED |
| `wt_config_namespace.bats` | R5.1-R5.3 (6 scenarios) | Tasks 2, 3 | 🔴 RED |
| `wt_consistent_behavior.bats` | R6.1-R6.3 (6 scenarios) | Tasks 2, 4 | 🔴 RED |
| `wt_project_code_resolution.bats` | R4.4 (existing test) | Task 2 | 🟢 GREEN (verify no regression) |
| Other existing tests | Backward compatibility | All tasks | 🟢 GREEN (verify no regression) |

**TDD Goal**: All new tests RED before implementation, GREEN after respective task

---

## TDD Verification

Before starting each task:
```bash
bats test/  # Should show ~31 new test failures, existing tests pass
```

After completing each task:
```bash
bats test/  # New tests should progressively pass, existing tests remain GREEN
```

---

## Tasks

### Task 1: Extract `_wt_resolve_worktree_path()` function

**Structure**: New function in `install_aliases.sh`

**Implements**: Path resolution foundation

**Makes GREEN**: (Foundation - no specific tests, but required for R5 tests)

**Limits**:
- Default: 40 lines
- Hard Max: 60 lines
- If > 40: ⚠️ flag warning
- If > 60: ⛔ STOP

**From**: Lines 77-92 (wt), Lines 172-184 (wt-rm)

**To**: New `_wt_resolve_worktree_path()` function (before git wt alias definition)

**Move/Create**:
- `worktree_name` parameter (worktree name to resolve path for)
- `{project_dir}` placeholder expansion logic
- `{worktree_name}` placeholder expansion logic
- Tilde (`~`) expansion to `$HOME`
- Relative vs absolute path detection
- Return value: Absolute worktree path via `echo`

**Exclude**:
- Keep `worktree.defaultPath` / `worktree.wt.defaultPath` config reading in wt/wt-rm (passed as parameter)
- Keep error handling for existing worktree/branch in wt/wt-rm
- Keep mkdir parent directory logic in wt/wt-rm

**Anti-duplication**:
- This IS the shared source — both wt and wt-rm will call this function

**Verify**:
```bash
wc -l install_aliases.sh  # Should increase by ~30-40 lines (new function)
source install_aliases.sh  # Should load without errors
```

**Done when**:
- [ ] `_wt_resolve_worktree_path()` function defined before git wt alias
- [ ] Function takes `worktree_name` as first parameter
- [ ] Function reads `worktree.wt.defaultPath` config (with fallback to `worktree.defaultPath`)
- [ ] Function expands `{project_dir}`, `{worktree_name}`, and `~` placeholders
- [ ] Function outputs absolute path via `echo`
- [ ] Size ≤ 40 lines (or flagged if ≤ 60)
- [ ] Existing tests still GREEN

---

### Task 2: Extract and enhance `_wt_build_worktree_name()` function

**Structure**: New function in `install_aliases.sh`

**Implements**: R1.1-R1.4, R2.1-R2.4, R3.1-R3.4, R4.1-R4.3, R6.3

**Makes GREEN**:
- `wt_generic_prefix.bats`: All 5 scenarios (R1.1-R1.4, R4.2)
- `wt_zero_padding.bats`: All 7 scenarios (R2.1-R2.4, R4.1, R4.3)
- `wt_input_detection.bats`: All 7 scenarios (R3.1-R3.4)
- `wt_consistent_behavior.bats`: R6.3 scenarios (identical logic)

**Limits**:
- Default: 50 lines
- Hard Max: 75 lines
- If > 50: ⚠️ flag warning
- If > 75: ⛔ STOP

**From**: Lines 16-31 (wt), Lines 143-158 (wt-rm)

**To**: New `_wt_build_worktree_name()` function (before git wt alias definition)

**Move/Create**:
- Input validation (remove strict 3-digit requirement - any input allowed)
- Input type detection:
  - Already prefixed: `PROJ-123`, `ABC-123` (regex: `^[A-Z]+-[0-9]+$`)
  - Pure numeric: `123`, `42` (regex: `^[0-9]+$`)
  - Text: `feature-login` (contains letters, no dash-number pattern)
- MDT auto-detection (reads `.mdt-config.toml` `code` field)
- Git config reading: `worktree.wt.prefix`, `worktree.wt.zeroPadDigits`
- Zero-padding logic (only for numeric input)
- Prefix application (only for numeric input)
- Return value: Final worktree name via `echo`

**Exclude**:
- Keep path resolution in `_wt_resolve_worktree_path()` (Task 1)
- Keep worktree creation git commands in wt
- Keep worktree removal logic in wt-rm

**Anti-duplication**:
- This IS the shared source — both wt and wt-rm will call this function
- Do NOT duplicate MDT detection logic
- Do NOT duplicate git config reading logic

**Logic flow**:
```bash
_wt_build_worktree_name() {
    local input="$1"

    # 1. Check if already prefixed (e.g., PROJ-123, ABC-123)
    if [[ "$input" =~ ^[A-Z]+-[0-9]+$ ]]; then
        echo "$input"
        return
    fi

    # 2. Check if pure numeric
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        # Read git config (check local, then global)
        local prefix=$(git config worktree.wt.prefix 2>/dev/null || git config --global worktree.wt.prefix 2>/dev/null)
        local pad_digits=$(git config worktree.wt.zeroPadDigits 2>/dev/null || git config --global worktree.wt.zeroPadDigits 2>/dev/null)

        # If not in git config, check MDT
        if [ -z "$prefix" ]; then
            local dot_config="$(git rev-parse --show-toplevel)/.mdt-config.toml"
            if [ -f "$dot_config" ]; then
                local project_code=$(grep "^code = " "$dot_config" | cut -d"=" -f2 | tr -d " \"")
                if [ -n "$project_code" ]; then
                    prefix="${project_code}-"
                    pad_digits="${pad_digits:-3}"  # Default to 3 for MDT
                fi
            fi
        fi

        # Apply zero-padding
        if [ -n "$pad_digits" ]; then
            input=$(printf "%0${pad_digits}d" "$input")
        fi

        # Apply prefix
        if [ -n "$prefix" ]; then
            input="${prefix}${input}"
        fi
    fi

    # 3. Text input (contains letters, no dash-number pattern) - pass through unchanged
    echo "$input"
}
```

**Verify**:
```bash
wc -l install_aliases.sh  # Function should be ≤ 50 lines
bats test/wt_generic_prefix.bats  # Should show 5 failures (not yet integrated)
bats test/wt_zero_padding.bats  # Should show 7 failures (not yet integrated)
bats test/wt_input_detection.bats  # Should show 7 failures (not yet integrated)
```

**Done when**:
- [ ] `_wt_build_worktree_name()` function defined
- [ ] Function accepts any input (no strict 3-digit validation)
- [ ] Already-prefixed input passes through unchanged
- [ ] Numeric input gets prefix + zero-padding (from git config or MDT)
- [ ] Text input passes through unchanged
- [ ] Git config takes precedence over MDT
- [ ] Size ≤ 50 lines (or flagged if ≤ 75)
- [ ] Existing MDT tests still GREEN (backward compatible)

---

### Task 3: Update `git wt` alias to use shared functions and new config namespace

**Structure**: `install_aliases.sh` - `git wt` alias definition

**Implements**: R5.1-R5.3 (configuration namespace)

**Makes GREEN**:
- `wt_config_namespace.bats`: All 6 scenarios (R5.1-R5.3)
- `wt_generic_prefix.bats`: All 5 scenarios (now using shared function)
- `wt_zero_padding.bats`: All 7 scenarios (now using shared function)
- `wt_input_detection.bats`: All 7 scenarios (now using shared function)

**Limits**:
- Default: 70 lines
- Hard Max: 105 lines
- If > 70: ⚠️ flag warning
- If > 105: ⛔ STOP

**From**: Lines 1-126 (current git wt alias)

**To**: Refactored `git wt` alias (reduced from ~126 to ~70 lines)

**Replace**:
- Remove: Lines 16-31 (worktree name building) → Call `_wt_build_worktree_name "$1"`
- Remove: Lines 77-92 (path resolution) → Call `_wt_resolve_worktree_path "$worktree"`
- Update: Config reading to use `worktree.wt.defaultPath` (with fallback to `worktree.defaultPath`)
- Remove: Strict 3-digit validation (handled in shared function)

**Exclude**:
- Keep usage message (lines 4-9)
- Keep default path interactive setup (lines 36-75)
- Keep worktree existence check (lines 105-109)
- Keep branch existence check (lines 111-115)
- Keep mkdir parent directory (lines 117-120)
- Keep git worktree add command (line 122)
- Keep output messages (lines 123-126)

**Anti-duplication**:
- Import `_wt_build_worktree_name` from shared function — do NOT duplicate logic
- Import `_wt_resolve_worktree_path` from shared function — do NOT duplicate logic

**New structure**:
```bash
git config --global alias.wt '!f() {
    worktree_input="$1"

    if [ -z "$worktree_input" ]; then
        # Usage message (unchanged)
    fi

    # Build worktree name using shared function
    worktree=$(_wt_build_worktree_name "$worktree_input")

    # Config reading with new namespace (worktree.wt.defaultPath)
    # Check new namespace first, fall back to old for migration
    default_path=$(git config worktree.wt.defaultPath 2>/dev/null || git config worktree.defaultPath 2>/dev/null || git config --global worktree.wt.defaultPath 2>/dev/null || git config --global worktree.defaultPath 2>/dev/null)

    if [ -z "$default_path" ]; then
        # Interactive setup (unchanged, but update to use worktree.wt.defaultPath)
        # ...
    fi

    # Resolve path using shared function
    worktree_path=$(_wt_resolve_worktree_path "$worktree" "$default_path")

    # Rest of logic (existence checks, git worktree add) unchanged
    # ...
}; f'
```

**Verify**:
```bash
wc -l install_aliases.sh | grep -A1 "git wt"  # wt alias should be ≤ 70 lines
source install_aliases.sh  # Should load without errors
bats test/wt_config_namespace.bats  # Should show 6 passing (or fewer failures)
bats test/wt_generic_prefix.bats  # Should show fewer failures
bats test/wt_zero_padding.bats  # Should show fewer failures
bats test/wt_input_detection.bats  # Should show fewer failures
bats test/wt_project_code_resolution.bats  # Should still be GREEN
```

**Done when**:
- [ ] `git wt` uses `_wt_build_worktree_name()` for name building
- [ ] `git wt` uses `_wt_resolve_worktree_path()` for path resolution
- [ ] `git wt` reads `worktree.wt.defaultPath` (with fallback)
- [ ] Strict 3-digit validation removed
- [ ] Size ≤ 70 lines (or flagged if ≤ 105)
- [ ] `wt_config_namespace.bats` tests GREEN
- [ ] `wt_generic_prefix.bats` tests GREEN
- [ ] `wt_zero_padding.bats` tests GREEN
- [ ] `wt_input_detection.bats` tests GREEN
- [ ] Existing MDT tests still GREEN

---

### Task 4: Update `git wt-rm` alias to use shared functions

**Structure**: `install_aliases.sh` - `git wt-rm` alias definition

**Implements**: R6.1-R6.3 (consistent behavior)

**Makes GREEN**:
- `wt_consistent_behavior.bats`: All 6 scenarios (R6.1-R6.3)

**Limits**:
- Default: 80 lines
- Hard Max: 120 lines
- If > 80: ⚠️ flag warning
- If > 120: ⛔ STOP

**From**: Lines 128-253 (current git wt-rm alias)

**To**: Refactored `git wt-rm` alias (reduced from ~115 to ~80 lines)

**Replace**:
- Remove: Lines 143-158 (worktree name building) → Call `_wt_build_worktree_name "$1"`
- Remove: Lines 172-184 (path resolution) → Call `_wt_resolve_worktree_path "$worktree"`
- Update: Config reading to use `worktree.wt.defaultPath` (with fallback to `worktree.defaultPath`)
- Remove: Strict 3-digit validation (handled in shared function)

**Exclude**:
- Keep usage message (lines 131-136)
- Keep default path fallback message (lines 163-167)
- Keep worktree existence check (lines 198-204)
- Keep removal confirmation (lines 206-220)
- Keep git worktree remove command (lines 222-231)
- Keep branch deletion logic (lines 233-250)
- Keep success messages (lines 252-253)

**Anti-duplication**:
- Import `_wt_build_worktree_name` from shared function — do NOT duplicate logic
- Import `_wt_resolve_worktree_path` from shared function — do NOT duplicate logic
- Use identical logic to `git wt` for consistency (R6.3)

**New structure**:
```bash
git config --global alias.wt-rm '!f() {
    worktree_input="$1"

    if [ -z "$worktree_input" ]; then
        # Usage message (unchanged)
    fi

    # Build worktree name using shared function (same as wt)
    worktree=$(_wt_build_worktree_name "$worktree_input")

    # Config reading with new namespace
    default_path=$(git config worktree.wt.defaultPath 2>/dev/null || git config worktree.defaultPath 2>/dev/null || git config --global worktree.wt.defaultPath 2>/dev/null || git config --global worktree.defaultPath 2>/dev/null)

    if [ -z "$default_path" ]; then
        default_path=".gitWT/{worktree_name}"
    fi

    # Resolve path using shared function (same as wt)
    worktree_path=$(_wt_resolve_worktree_path "$worktree" "$default_path")

    # Rest of logic (existence check, confirmation, removal) unchanged
    # ...
}; f'
```

**Verify**:
```bash
wc -l install_aliases.sh | grep -A1 "git wt-rm"  # wt-rm alias should be ≤ 80 lines
source install_aliases.sh  # Should load without errors
bats test/wt_consistent_behavior.bats  # Should show 6 passing
bats test/wt_rm_removal.bats  # Should still be GREEN (existing tests)
```

**Done when**:
- [ ] `git wt-rm` uses `_wt_build_worktree_name()` for name building
- [ ] `git wt-rm` uses `_wt_resolve_worktree_path()` for path resolution
- [ ] `git wt-rm` reads `worktree.wt.defaultPath` (with fallback)
- [ ] Strict 3-digit validation removed
- [ ] Size ≤ 80 lines (or flagged if ≤ 120)
- [ ] `wt_consistent_behavior.bats` tests GREEN
- [ ] `wt-rm` can remove worktrees created with `wt` (R6.1)
- [ ] `wt-rm` accepts full worktree names (R6.2)
- [ ] `wt-rm` uses identical logic to `wt` (R6.3)
- [ ] Existing removal tests still GREEN

---

## Post-Implementation

### Task 5: Verify no duplication

```bash
# Check for duplicated MDT detection logic
grep -n "\.mdt-config.toml" install_aliases.sh | wc -l
# Should be: 1 (only in _wt_build_worktree_name)

# Check for duplicated path resolution logic
grep -n "{worktree_name}" install_aliases.sh | wc -l
# Should be: 1 (only in _wt_resolve_worktree_path)

# Check for duplicated placeholder expansion
grep -n "sed.*{project_dir}" install_aliases.sh | wc -l
# Should be: 1 (only in _wt_resolve_worktree_path)
```

**Done when**:
- [ ] Each pattern exists in ONE location only
- [ ] No duplicated logic between wt and wt-rm

### Task 6: Verify size compliance

```bash
# Check function sizes
awk '/^_wt_build_worktree_name\(\)/,/^}/ {if (/^}/) exit; count++} END {print "_wt_build_worktree_name:", count+1, "lines"}' install_aliases.sh

awk '/^_wt_resolve_worktree_path\(\)/,/^}/ {if (/^}/) exit; count++} END {print "_wt_resolve_worktree_path:", count+1, "lines"}' install_aliases.sh

# Expected output:
# _wt_build_worktree_name: ~50 lines (≤ 50 default, ≤ 75 hard max)
# _wt_resolve_worktree_path: ~40 lines (≤ 40 default, ≤ 60 hard max)
```

**Done when**:
- [ ] `_wt_build_worktree_name` ≤ 50 lines (or flagged if ≤ 75)
- [ ] `_wt_resolve_worktree_path` ≤ 40 lines (or flagged if ≤ 60)
- [ ] `git wt` alias ≤ 70 lines (or flagged if ≤ 105)
- [ ] `git wt-rm` alias ≤ 80 lines (or flagged if ≤ 120)

### Task 7: Run full test suite

```bash
bats test/
```

**Done when**:
- [ ] All WTA-002 new tests GREEN (31 scenarios)
- [ ] All existing tests GREEN (backward compatible)
- [ ] No regressions

### Task 8: Update documentation

**Files to update**:
- `README.md` - Add new configuration options
- `git-wt-manual.md` - Update with new namespace and features
- `old-config-migration.md` - Already exists, reference in README

**Add to README**:
- New `worktree.wt.prefix` setting with examples
- New `worktree.wt.zeroPadDigits` setting with examples
- New `worktree.wt.defaultPath` namespace (migration from `worktree.defaultPath`)
- Generic mode examples (non-MDT projects)

**Add to manual**:
- Input type detection rules
- Configuration precedence (git config > MDT > default)
- Migration guide for `worktree.defaultPath`

**Done when**:
- [ ] README updated with new configuration options
- [ ] Manual updated with detailed usage
- [ ] Migration guide referenced
- [ ] Examples for GitHub-style, JIRA-style, and MDT projects

---

## Migration Note

**Breaking change**: `worktree.defaultPath` → `worktree.wt.defaultPath`

The implementation should support a migration period where both namespaces work, but `worktree.wt.defaultPath` takes precedence. Users with existing `worktree.defaultPath` configurations should see a deprecation warning encouraging migration.

**Migration command** (to document):
```bash
# For each repo/worktree:
old_path=$(git config worktree.defaultPath)
git config worktree.wt.defaultPath "$old_path"
git config --unset worktree.defaultPath

# Global migration:
old_path=$(git config --global worktree.defaultPath)
git config --global worktree.wt.defaultPath "$old_path"
git config --global --unset worktree.defaultPath
```

---

*Generated by /mdt:tasks*
