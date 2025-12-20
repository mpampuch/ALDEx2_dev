# Notes for `aldex.set.mode()`

- **Role**: Central feature-selection wrapper that chooses denominator features based on modes ("all", "iqlr", "zero", custom indices).
- **Dependencies**: Delegates to helper functions `iqlr.features()`, `zero.features()`, `all.features()`, and `custom.features()`; see `Function_Inventory_Summary.md`.
- **Test coverage**: 0%; flagged as a critical gap in `Test_Coverage_Report.md` together with its helpers.
- **Optimization priority**: Marked **HIGH** in `R_Code_Optimization_Summary.md` mainly for its importance to workflows rather than raw cost.
- **Translation note**: Ensure that the Julia version enforces consistent, well-documented semantics for each mode and shares logic with the helper functions to avoid divergence.


