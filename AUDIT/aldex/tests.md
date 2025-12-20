# Tests for `aldex()`

## Current R test coverage

- **Test files**: `tests/testthat/test-aldex.glm.R` (indirectly exercises `aldex()`)
- **Coverage level**: ⚠️ ~5% of parameter space (see `Test_Coverage_Report.md`)
- **Test type**: Integration-style consistency check between `test="t"` and `test="glm"`.

### Scenarios covered

- `reads = selex`-like data, two conditions.
- `test = "t"` and `test = "glm"`.
- `effect = FALSE`, `denom = "all"`.

## Gaps and follow-ups

- **Missing workflows**: `test = "iterative"`, combinations of `effect = TRUE/FALSE`, alternative `denom` values ("iqlr", "zero", custom indices).
- **Missing options**: `include.sample.summary`, `mc.samples` variations, `useMC`, `verbose`.
- **Missing robustness tests**: invalid inputs, edge-case datasets (all zeros, single sample/feature, NAs, negative counts).
- **Action items**:
  - Add end-to-end tests that call `aldex()` for each supported `test` mode and verify high-level invariants.
  - Add error-handling and input-validation tests as recommended in `Test_Coverage_Report.md`.


