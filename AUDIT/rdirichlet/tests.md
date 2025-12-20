# Tests for `rdirichlet()`

## Current R test coverage

- **Test files**: none.
- **Coverage level**: ⚠️ Indirect only (via Monte Carlo sampling inside `aldex.clr()`; see `Test_Coverage_Report.md`).
- **Test type**: Behaviour inferred indirectly; no direct statistical checks on samples.

## Required scenarios (not yet implemented)

- Shape and type checks for returned matrices for a range of alpha parameter vectors.
- Statistical property checks (e.g., sample means vs theoretical Dirichlet expectations, sum-to-one constraint per sample).
- Edge cases such as very small/large concentration parameters and high-dimensional parameter vectors.

## Action items

- Add unit tests that draw large numbers of samples and compare empirical moments to theoretical Dirichlet expectations within tolerance.
- Add error-handling tests for invalid alpha vectors (negative entries, zeros, mismatched lengths).


