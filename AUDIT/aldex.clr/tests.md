# Tests for `aldex.clr()`

## Current R test coverage

- **Test files**: all existing testthat files (`test-aldex.ttest.R`, `test-aldex.glm.R`, `test-stats.fast.R`) call `aldex.clr()` indirectly.
- **Coverage level**: ⚠️ Indirect only (no direct unit tests; see `Test_Coverage_Report.md`).
- **Test type**: Integration tests via downstream functions.

### Scenarios covered (indirect)

- Typical `selex`-like count matrices with two conditions.
- Default denominator mode `denom = "all"` and default `mc.samples`.

## Gaps and follow-ups

- **Missing direct tests**:
  - Explicit checks on the structure of the returned `aldex.clr` object (slots, dimensions).
  - Tests for all denominator modes: "all", "iqlr", "zero", and custom features.
  - Tests for `useMC` and `verbose` flags.
  - Tests for alternative input types (matrix, `data.frame`, `RangedSummarizedExperiment`).
- **Action items**:
  - Add focused unit tests that construct small synthetic datasets and assert exact CLR outputs for simple cases.
  - Add S4-structure tests that validate object invariants and accessor methods.


