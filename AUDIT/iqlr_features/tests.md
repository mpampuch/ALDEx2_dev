# Tests for `iqlr.features()`

## Current R test coverage

- **Test files**: none.
- **Coverage level**: ❌ 0% (see `Test_Coverage_Report.md`, feature-selection helpers).
- **Test type**: No direct tests for IQLR feature selection.

## Required scenarios (not yet implemented)

- Synthetic count matrices where the inter-quartile log-ratio features can be identified by hand.
- Datasets with varying sparsity and zero-inflation to test robustness of feature selection.
- Comparisons between `iqlr.features()` output and simpler selection rules on toy examples.

## Action items

- Implement unit tests that assert exact feature index sets for small matrices.
- Add tests that are coordinated with `aldex.set.mode()` tests so that the two layers remain consistent.


