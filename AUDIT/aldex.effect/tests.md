# Tests for `aldex.effect()`

## Current R test coverage

- **Test files**: none.
- **Coverage level**: ❌ 0% (see `Test_Coverage_Report.md`).
- **Test type**: No direct or indirect tests specifically targeting effect-size calculations.

## Required scenarios (not yet implemented)

- Effect size calculations under simple two-group scenarios with known expected values.
- Overlap and relative abundance calculations.
- Behaviour when `include.sample.summary = TRUE` vs `FALSE`.
- Sensitivity to `mc.samples`, `denom` modes, and parallel vs serial execution.

## Action items

- Design a minimal synthetic dataset where effect sizes and overlaps can be computed by hand and use it for golden-reference tests.
- Add tests that stress memory usage patterns (many features, larger MC samples) to guard against regressions during optimization/translation.
- Incorporate edge-case tests (all-zero features, single-feature inputs, unbalanced conditions) as recommended in the global `Test_Coverage_Report.md`.


