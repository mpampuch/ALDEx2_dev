# Tests for `aldex.set.mode()`

## Current R test coverage

- **Test files**: none.
- **Coverage level**: ❌ 0% (critical gap; see `Test_Coverage_Report.md`).
- **Test type**: No dedicated tests for feature-selection logic.

## Required scenarios (not yet implemented)

- `denom = "all"` mode: verifies that all features are selected as denominators.
- `denom = "iqlr"` mode: verifies that inter-quartile log-ratio selection matches `iqlr.features()`.
- `denom = "zero"` mode: verifies behaviour on zero-inflated data.
- `denom = custom_indices` mode: verifies correct handling of user-specified feature indices.

## Action items

- Implement unit tests that call `aldex.set.mode()` on small synthetic matrices and assert exact denominator index sets.
- Add tests that mirror the gaps listed in `Test_Coverage_Report.md` for feature-selection helpers (`iqlr.features()`, `zero.features()`, `custom.features()`).


