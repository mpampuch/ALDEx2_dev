# Notes for `aldex.effect()`

- **Role**: Computes effect sizes, overlaps, and relative abundances from CLR-transformed Monte Carlo instances.
- **Dependencies**: Uses `aitchison.mean()` and interacts closely with `aldex.clr` object structures.
- **Test coverage**: Currently untested (0%); see `Test_Coverage_Report.md` where this is flagged as a **critical gap**.
- **Optimization priority**: Marked **CRITICAL (P0)** in `R_Code_Optimization_Summary.md` due to `apply()` and `cbind()` patterns causing heavy allocation and memory pressure.
- **Translation note**: Prioritize pre-allocation and careful memory layout in Julia; ensure numerical stability and reproducibility for effect-size calculations.


