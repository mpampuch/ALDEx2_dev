# Tests for `aldex.ttest()`

## Current R test coverage

- **Test file**: `tests/testthat/test-aldex.ttest.R`.
- **Coverage level**: ✅ 100% of the current R implementation (see `Test_Coverage_Report.md`).
- **Test type**: Integration tests comparing against the previous implementation.

### Scenarios covered

- Standard `selex` dataset (≈100 features × 14 samples).
- Extended dataset with additional "fake" columns (≈100 features × 20 samples).
- Both paired and unpaired t-tests through the wrapper.

## Gaps and follow-ups

- **Missing edge cases**: extreme sample size imbalances, all-zero rows, single-feature datasets, NAs or non-integer counts.
- **Missing validation tests**: explicit checks of p-value distributions and multiple-testing adjustments under known null/alternative scenarios.
- **Action items**:
  - Add focused unit tests on small synthetic matrices where expected t-statistics and p-values can be computed analytically.
  - Add error-handling tests for invalid inputs and mismatched condition vectors.


