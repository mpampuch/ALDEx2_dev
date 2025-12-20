# Tests for `aldex.glm()`

## Current R test coverage

- **Test file**: `tests/testthat/test-aldex.glm.R`.
- **Coverage level**: ⚠️ Partial (~20%; see `Test_Coverage_Report.md`).
- **Test type**: Integration/consistency test comparing GLM results to `aldex.ttest()`.

### Scenarios covered

- Single dataset with two conditions, using `selex`-like counts.
- Basic significance-flag consistency and row-name equality between GLM and t-test outputs.

## Gaps and follow-ups

- **Statistical coverage**:
  - No explicit tests for the Kruskal–Wallis component.
  - No tests across different condition structures (multi-class, unbalanced designs).
- **Parameter coverage**:
  - No tests for alternative model formulas or contrasts.
  - No tests for `mc.samples`, `denom`, or `useMC` variations.
- **Action items**:
  - Add unit tests that validate GLM coefficients and p-values against known reference fits (e.g., via base R `glm`).
  - Add scenarios with >2 conditions and unbalanced group sizes, as recommended in `Test_Coverage_Report.md`.


