# Tests: WTA-002

**Mode**: Feature
**Source**: requirements.md
**Generated**: 2025-12-23
**Scope**: All requirements

## Test Configuration

| Setting | Value |
|---------|-------|
| Framework | Bats (Bash Automated Testing System) |
| Test Directory | `test/` |
| Test File Pattern | `*.bats` |
| Test Command | `bats test/` |
| Status | 🟢 GREEN (implementation complete) |
| Last Updated | 2025-12-23 |
| Total Tests | 75 (31 new + 44 existing) |
| Passing | 75 |
| Failing | 0 |

## Requirement → Test Mapping

| Req ID | Description | Test File | Scenarios | Status |
|--------|-------------|-----------|-----------|--------|
| R1.1 | Prefix added to numeric input | `wt_generic_prefix.bats` | 5 | 🟢 GREEN |
| R1.2 | Hash prefix support | `wt_generic_prefix.bats` | 1 | 🟢 GREEN |
| R1.3 | Prefix ignored for text input | `wt_generic_prefix.bats` | 1 | 🟢 GREEN |
| R1.4 | No prefix when not configured | `wt_generic_prefix.bats` | 1 | 🟢 GREEN |
| R2.1 | Zero-padding with prefix (3 digits) | `wt_zero_padding.bats` | 2 | 🟢 GREEN |
| R2.2 | Zero-padding with prefix (4 digits) | `wt_zero_padding.bats` | 1 | 🟢 GREEN |
| R2.3 | Zero-padding without prefix | `wt_zero_padding.bats` | 1 | 🟢 GREEN |
| R2.4 | No padding when not configured | `wt_zero_padding.bats` | 1 | 🟢 GREEN |
| R3.1 | Already-prefixed input pass-through | `wt_input_detection.bats` | 4 | 🟢 GREEN |
| R3.2 | Numeric input gets prefix/padding | `wt_input_detection.bats` | 1 | 🟢 GREEN |
| R3.3 | Text input unchanged | `wt_input_detection.bats` | 1 | 🟢 GREEN |
| R3.4 | wt-rm uses same detection logic | `wt_input_detection.bats` | 2 | 🟢 GREEN |
| R4.1 | MDT auto-detection (prefix + padding) | `wt_zero_padding.bats` | 1 | 🟢 GREEN |
| R4.2 | Git config overrides MDT prefix | `wt_generic_prefix.bats` | 1 | 🟢 GREEN |
| R4.3 | Git config overrides MDT padding | `wt_zero_padding.bats` | 1 | 🟢 GREEN |
| R4.4 | Empty MDT code falls back gracefully | Existing: `wt_project_code_resolution.bats` | 1 | 🟢 GREEN |
| R5.1 | worktree.wt.defaultPath namespace | `wt_config_namespace.bats` | 6 | 🟢 GREEN |
| R5.2 | worktree.wt.prefix namespace | `wt_generic_prefix.bats` | 5 | 🟢 GREEN |
| R5.3 | worktree.wt.zeroPadDigits namespace | `wt_zero_padding.bats` | 7 | 🟢 GREEN |
| R6.1 | wt-rm locates prefixed worktree | `wt_consistent_behavior.bats` | 4 | 🟢 GREEN |
| R6.2 | wt-rm accepts full worktree name | `wt_consistent_behavior.bats` | 2 | 🟢 GREEN |
| R6.3 | Identical logic across commands | `wt_consistent_behavior.bats` | 6 | 🟢 GREEN |

**Total Requirements**: 6 main requirements (R1-R6)
**Total Test Scenarios**: 31 new scenarios (all GREEN) + 44 existing tests (all GREEN)
**All Tests**: 75/75 passing ✅

## Test Specifications

### Feature: Generic Ticket Prefix Configuration (R1)

**File**: `test/wt_generic_prefix.bats`
**Covers**: R1.1-R1.4

#### Scenario: prefix_adds_to_numeric (R1.1)

```gherkin
Given worktree.wt.prefix is set to "ABC-"
And worktree.wt.defaultPath is configured
When user executes git wt 101
Then worktree name should be ABC-101
And worktree directory exists at .gitWT/ABC-101
```

**Test**: `@test "prefix: adds configured prefix to numeric input"`

#### Scenario: prefix_hash_style (R1.2)

```gherkin
Given worktree.wt.prefix is set to "#"
When user executes git wt 42
Then worktree name should be #42
```

**Test**: `@test "prefix: adds hash prefix to numeric input"`

#### Scenario: prefix_ignored_for_text (R1.3)

```gherkin
Given worktree.wt.prefix is set to "ABC-"
When user executes git wt feature-login
Then worktree name should be feature-login (prefix NOT applied)
```

**Test**: `@test "prefix: ignores prefix for text input"`

#### Scenario: prefix_none_configured (R1.4)

```gherkin
Given worktree.wt.prefix is NOT configured
When user executes git wt 101
Then worktree name should be 101 (no prefix)
```

**Test**: `@test "prefix: uses input as-is when no prefix configured"`

#### Scenario: prefix_git_config_overrides_mdt (R4.2)

```gherkin
Given .mdt-config.toml exists with code "TEST"
And worktree.wt.prefix is set to "OVERRIDE-"
When user executes git wt 123
Then worktree name should be OVERRIDE-123 (git config wins)
```

**Test**: `@test "prefix: git config takes precedence over MDT config"`

---

### Feature: Zero-Padding Configuration (R2)

**File**: `test/wt_zero_padding.bats`
**Covers**: R2.1-R2.4, R4.1, R4.3

#### Scenario: padding_3_digits_with_prefix (R2.1)

```gherkin
Given worktree.wt.zeroPadDigits is set to 3
And worktree.wt.prefix is set to "WTA-"
When user executes git wt 7
Then worktree name should be WTA-007
```

**Test**: `@test "padding: zero-pads to 3 digits with prefix"`

#### Scenario: padding_4_digits_with_prefix (R2.2)

```gherkin
Given worktree.wt.zeroPadDigits is set to 4
And worktree.wt.prefix is set to "PROJ-"
When user executes git wt 12
Then worktree name should be PROJ-0012
```

**Test**: `@test "padding: zero-pads to 4 digits with prefix"`

#### Scenario: padding_without_prefix (R2.3)

```gherkin
Given worktree.wt.zeroPadDigits is set to 3
And no prefix is configured
When user executes git wt 5
Then worktree name should be 005
```

**Test**: `@test "padding: zero-pads without prefix"`

#### Scenario: padding_none_configured (R2.4)

```gherkin
Given worktree.wt.zeroPadDigits is NOT configured
And worktree.wt.prefix is set to "PROJ-"
When user executes git wt 42
Then worktree name should be PROJ-42 (no padding)
```

**Test**: `@test "padding: uses number as-is when no padding configured"`

#### Scenario: padding_no_truncation (R2.4 - edge case)

```gherkin
Given worktree.wt.zeroPadDigits is set to 3
When user executes git wt 1234 (larger than 3 digits)
Then worktree name should use 1234 as-is (not truncated)
```

**Test**: `@test "padding: does not truncate numbers larger than digit count"`

#### Scenario: mdt_auto_padding (R4.1)

```gherkin
Given .mdt-config.toml exists with code "WTA"
And worktree.wt.zeroPadDigits is NOT configured
When user executes git wt 12
Then worktree name should be WTA-012 (auto 3-digit padding)
```

**Test**: `@test "padding: MDT auto zero-padding (default 3 digits)"`

#### Scenario: git_config_overrides_mdt_padding (R4.3)

```gherkin
Given .mdt-config.toml exists with code "WTA"
And worktree.wt.zeroPadDigits is set to 4
When user executes git wt 7
Then worktree name should be WTA-0007 (git config 4, not MDT 3)
```

**Test**: `@test "padding: git config overrides MDT default zero-padding"`

---

### Feature: Input Type Detection and Handling (R3)

**File**: `test/wt_input_detection.bats`
**Covers**: R3.1-R3.4

#### Scenario: input_already_prefixed (R3.1)

```gherkin
Given worktree.wt.prefix is set to "ABC-"
When user executes git wt PROJ-123 (already prefixed)
Then worktree name should be PROJ-123 (unchanged, not ABC-PROJ-123)
```

**Test**: `@test "input: passes through already-prefixed input unchanged"`

#### Scenario: input_pure_numeric (R3.2)

```gherkin
Given worktree.wt.prefix is configured
And worktree.wt.zeroPadDigits is configured
When user executes git wt 101 (pure numeric)
Then prefix and zero-padding should be applied
```

**Test**: `@test "input: applies prefix to pure numeric input"`

#### Scenario: input_text_with_letters (R3.3)

```gherkin
Given worktree.wt.prefix is configured
When user executes git wt feature-auth (contains letters)
Then worktree name should be feature-auth (prefix ignored)
```

**Test**: `@test "input: passes through text input unchanged"`

#### Scenario: input_wt_rm_same_detection (R3.4)

```gherkin
Given user created worktree with git wt 101 (resulting in PROJ-101)
When user executes git wt-rm 101
Then system should locate and remove PROJ-101
```

**Test**: `@test "input: wt-rm applies same detection logic as wt"`

#### Scenario: input_alphanumeric_ticket (R3.1 - edge case)

```gherkin
Given user executes git wt ABC-123
When worktree name is constructed
Then worktree name should be ABC-123 (treated as already prefixed)
```

**Test**: `@test "input: handles mixed alphanumeric input (e.g., ABC-123)"`

#### Scenario: input_feature_with_numbers (R3.3 - edge case)

```gherkin
Given user executes git wt feature-123
When worktree name is constructed
Then worktree name should be feature-123 (not treated as numeric)
```

**Test**: `@test "input: handles feature branch with numbers (e.g., feature-123)"`

---

### Feature: Configuration Namespace (R5)

**File**: `test/wt_config_namespace.bats`
**Covers**: R5.1-R5.3

#### Scenario: namespace_default_path (R5.1)

```gherkin
Given worktree.wt.defaultPath is set to ".worktrees/{worktree_name}"
When user creates a worktree
Then worktree should be created at .worktrees/{worktree_name}
```

**Test**: `@test "namespace: uses worktree.wt.defaultPath for path template"`

#### Scenario: namespace_migration (R5.1 - backward compatibility)

```gherkin
Given user has old worktree.defaultPath configured
And worktree.wt.defaultPath is also set
When user creates a worktree
Then worktree.wt.defaultPath should take precedence
```

**Test**: `@test "namespace: migrates from old worktree.defaultPath to worktree.wt.defaultPath"`

#### Scenario: namespace_placeholder_worktree_name (R5.1)

```gherkin
Given worktree.wt.defaultPath contains {worktree_name}
When user creates worktree for PROJ-123
Then placeholder should be replaced with PROJ-123
```

**Test**: `@test "namespace: supports {worktree_name} placeholder"`

#### Scenario: namespace_placeholder_project_dir (R5.1)

```gherkin
Given worktree.wt.defaultPath contains {project_dir}
When user creates a worktree
Then placeholder should be replaced with repository basename
```

**Test**: `@test "namespace: supports {project_dir} placeholder"`

#### Scenario: namespace_tilde_expansion (R5.1)

```gherkin
Given worktree.wt.defaultPath contains tilde (~)
When user creates a worktree
Then tilde should expand to home directory
```

**Test**: `@test "namespace: supports tilde expansion in path"`

#### Scenario: namespace_all_settings (R5.1-R5.3)

```gherkin
Given all worktree.wt.* settings are configured
When user creates worktree with git wt
Then all settings should be applied correctly
```

**Test**: `@test "namespace: reads all worktree.wt.* config consistently"`

---

### Feature: Consistent Behavior Across Commands (R6)

**File**: `test/wt_consistent_behavior.bats`
**Covers**: R6.1-R6.3

#### Scenario: consistent_wt_rm_short_input (R6.1)

```gherkin
Given user created worktree with git wt 101 (resulting in PROJ-101)
When user executes git wt-rm 101
Then system should locate PROJ-101 worktree
```

**Test**: `@test "consistent: wt-rm locates worktree created with prefix config"`

#### Scenario: consistent_wt_rm_full_name (R6.2)

```gherkin
Given user created worktree with git wt 101 (resulting in PROJ-101)
When user executes git wt-rm PROJ-101
Then system should locate the worktree
```

**Test**: `@test "consistent: wt-rm accepts full worktree name"`

#### Scenario: consistent_identical_prefix (R6.3)

```gherkin
Given worktree.wt.prefix is set to "JIRA-"
When user creates with git wt 42 and removes with git wt-rm 42
Then both should use JIRA-42
```

**Test**: `@test "consistent: wt and wt-rm apply identical prefix logic"`

#### Scenario: consistent_identical_padding (R6.3)

```gherkin
Given worktree.wt.zeroPadDigits is set to 4
And worktree.wt.prefix is set to "ABC-"
When user creates with git wt 7 and removes with git wt-rm 7
Then both should use ABC-0007
```

**Test**: `@test "consistent: wt and wt-rm apply identical zero-padding logic"`

#### Scenario: consistent_text_input (R6.3)

```gherkin
Given user created worktree with git wt feature-login
When user executes git wt-rm feature-login
Then system should locate feature-login worktree
```

**Test**: `@test "consistent: wt-rm passes through text input unchanged"`

#### Scenario: consistent_already_prefixed (R6.3)

```gherkin
Given user created worktree with git wt EXISTING-123
When user executes git wt-rm EXISTING-123
Then system should locate the worktree
```

**Test**: `@test "consistent: wt-rm handles already-prefixed input"`

---

## Edge Cases

| Scenario | Expected Behavior | Test | Req |
|----------|-------------------|------|-----|
| Already prefixed input (PROJ-123) | Pass through unchanged | `wt_input_detection.bats` | R3.1 |
| Text input (feature-login) | No prefix applied | `wt_generic_prefix.bats` | R1.3 |
| Empty MDT code | Fall back to git config/default | Existing: `wt_project_code_resolution.bats` | R4.4 |
| Number larger than zeroPadDigits | Use as-is, no truncation | `wt_zero_padding.bats` | R2.4 |
| Feature branch with numbers (feature-123) | Treat as text, no prefix | `wt_input_detection.bats` | R3.3 |
| Both old and new path config | New namespace takes precedence | `wt_config_namespace.bats` | R5.1 |

## Generated Test Files

| File | Scenarios | Lines | Status |
|------|-----------|-------|--------|
| `test/wt_generic_prefix.bats` | 5 | ~160 | 🟢 GREEN |
| `test/wt_zero_padding.bats` | 7 | ~220 | 🟢 GREEN |
| `test/wt_input_detection.bats` | 7 | ~240 | 🟢 GREEN |
| `test/wt_config_namespace.bats` | 6 | ~180 | 🟢 GREEN |
| `test/wt_consistent_behavior.bats` | 6 | ~180 | 🟢 GREEN |

**Total New Tests**: 31 scenarios across 5 files (~980 lines) - All GREEN ✅

## Verification

Run all WTA-002 tests:
```bash
# Run new tests only
bats test/wt_generic_prefix.bats test/wt_zero_padding.bats test/wt_input_detection.bats test/wt_config_namespace.bats test/wt_consistent_behavior.bats

# Or run all tests
bats test/
```

Result: **All 75 tests passing** ✅

Sample output:
```
1..75
ok 1 uses worktree.wt.defaultPath for path template
ok 2 worktree.wt.defaultPath takes precedence over old worktree.defaultPath
ok 3 replaces {worktree_name} placeholder in path template
...
```

## Coverage Checklist

- [x] All R1 (Generic Prefix) requirements have tests
- [x] All R2 (Zero-Padding) requirements have tests
- [x] All R3 (Input Detection) requirements have tests
- [x] All R4 (MDT Auto-Detection) requirements have tests
- [x] All R5 (Configuration Namespace) requirements have tests
- [x] All R6 (Consistent Behavior) requirements have tests
- [x] Error scenarios covered
- [x] Edge cases documented
- [x] All tests are GREEN (verified: 75/75 passing ✅)

---

## Implementation Summary

All tasks completed:

| Task | Makes GREEN | Status |
|------|-------------|--------|
| Extract `_wt_resolve_worktree_path()` function | Foundation for R5 tests | ✅ Complete |
| Extract `_wt_build_worktree_name()` function | Foundation for R1-R4, R6 tests | ✅ Complete |
| Update `git wt` to use shared functions | R5.1-R5.3 + integration | ✅ Complete |
| Update `git wt-rm` to use shared functions | R6.1-R6.3 | ✅ Complete |
| Fix test infrastructure (helper functions) | All tests | ✅ Complete |
| Update legacy tests for new namespace | Backward compatibility | ✅ Complete |
| Remove obsolete validation tests | Clean up old behavior | ✅ Complete |

**Result**: All 75 tests passing ✅

---

## Existing Tests (Updated - Stay GREEN)

The following existing tests were updated for WTA-002 and continue passing:

- `test/wt_project_code_resolution.bats` - MDT integration (backward compatible)
- `test/wt_path_resolution.bats` - Path placeholder expansion
- `test/wt_integration.bats` - End-to-end workflows
- `test/wt_error_handling.bats` - Error scenarios (updated namespace, removed obsolete test)
- `test/wt_ticket_validation.bats` - Input validation (removed 2 obsolete tests)
- `test/wt_rm_removal.bats` - Worktree removal
- `test/wt_interactive_setup.bats` - Interactive configuration (updated namespace)

These tests verify backward compatibility with existing MDT behavior while supporting new WTA-002 features.

---

*Generated by /mdt:tests*
*Last updated: 2025-12-23*
