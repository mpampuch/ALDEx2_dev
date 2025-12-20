# Notes for `aldex.clr()`

- **Role**: Core CLR transformation producing `aldex.clr` S4 objects; central to all downstream analyses.
- **Dependencies**: Uses `rdirichlet()`, `aldex.set.mode()` (and its helpers), and optionally BiocParallel (`bplapply()`), as shown in the dependency diagram in `Function_Inventory_Summary.md`.
- **Test coverage**: Only indirectly tested via other functions; see `Test_Coverage_Report.md` for missing direct unit tests and S4 accessor checks.
- **Optimization priority**: `R_Code_Optimization_Summary.md` marks `aldex.clr.function()` as **CRITICAL (P0)** because of heavy `apply()` usage and Monte Carlo sampling.
- **Translation note**: In Julia, focus on pre-allocation, replacing `apply()` with loops/broadcasting, and exploiting threading/GPU for Monte Carlo instances.


