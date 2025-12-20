# Notes for `aldex.glm()`

- **Role**: Provides GLM and Kruskal–Wallis based multi-group differential abundance tests on CLR data.
- **Dependencies**: Uses `aldex.clr` outputs and base R GLM/Kruskal–Wallis tooling; see `Package_Inventory.md`.
- **Test coverage**: Partially covered by `test-aldex.glm.R` with a single consistency check vs `aldex.ttest()`; gaps are listed in `Test_Coverage_Report.md`.
- **Optimization priority**: Marked **HIGH** in `R_Code_Optimization_Summary.md`, with emphasis on replacing `apply()` and parallelizing over features.
- **Translation note**: Julia implementation should lean on `GLM.jl` or similar packages and be structured for per-feature parallelism.


