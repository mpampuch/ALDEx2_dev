# Tests for `wilcox.fast()`

## Current R test coverage

- **Test file**: `tests/testthat/test-stats.fast.R`.
- **Coverage level**: ✅ 100% (see `Test_Coverage_Report.md`).
- **Test type**: Unit tests comparing `wilcox.fast()` directly against base R `wilcox.test()`.

### Scenarios covered

- Standard and extended `selex` datasets (paired and unpaired Wilcoxon tests).
- `iris`-based datasets, including normal-approximation paths.
- Tied-data scenarios explicitly exercising rank-handling logic.

## Gaps and follow-ups

- Stress tests for very large datasets and highly tied data distributions.
- Tests for NA handling, non-finite values, and invalid input shapes.
- Action item: add tests that explicitly verify p-value accuracy and continuity corrections under edge-case configurations.


