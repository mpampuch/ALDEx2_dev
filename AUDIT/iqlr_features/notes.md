# Notes for `iqlr.features()`

- **Role**: Helper for IQLR feature selection, used by `aldex.set.mode()` when `denom = "iqlr"`.
- **Dependencies**: Works on CLR-style data to identify inter-quartile log-ratio features; see `Function_Inventory_Summary.md`.
- **Test coverage**: Currently 0%; called out explicitly in `Test_Coverage_Report.md` as part of the feature-selection gap.
- **Optimization priority**: Marked **MEDIUM** in `R_Code_Optimization_Summary.md` due to some `apply()` usage but modest overall cost.
- **Translation note**: Implement in Julia using explicit loops/broadcasting and boolean indexing; keep semantics tightly coupled to `aldex.set.mode()`.


