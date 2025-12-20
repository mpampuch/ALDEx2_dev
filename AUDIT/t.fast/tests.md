# Tests for `t.fast()`

## Current R test coverage

- **Test file**: `tests/testthat/test-stats.fast.R`.
- **Coverage level**: ✅ 100% (see `Test_Coverage_Report.md`).
- **Test type**: Unit tests comparing `t.fast()` directly against base R `t.test()`.

### Scenarios covered

- Standard `selex` dataset for both paired and unpaired designs.
- Extended datasets with additional columns and varied condition assignments.
- `iris`-based synthetic datasets with different configurations.

## Gaps and follow-ups

- Explicit tests for numerical stability at extreme parameter values (very small/large variances, near-singular cases).
- Tests for behaviour with NAs, non-finite values, and non-numeric inputs.
- Action item: design additional tests that exercise error/warning paths and confirm informative messaging, in line with global recommendations.


