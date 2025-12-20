# Tests for `aldex.corr()`

## Current R test coverage

- **Test files**: none.
- **Coverage level**: ❌ 0% (critical gap; see `Test_Coverage_Report.md`).
- **Test type**: No direct or indirect tests specific to correlation behaviour.

## Required scenarios (not yet implemented)

- Pearson and Spearman correlations on small synthetic datasets with analytically known results.
- Behaviour of p-values and BH-adjusted p-values under null and alternative hypotheses.
- Handling of missing values, constant covariates, and highly collinear predictors.

## Action items

- Create unit tests that compare `aldex.corr()` outputs to base R `cor.test()` on simple matrices.
- Add tests for multiple-testing correction correctness (BH vs alternative methods).
- Add edge-case tests aligned with global recommendations: all-zero features, single-feature inputs, and varying numbers of samples.


