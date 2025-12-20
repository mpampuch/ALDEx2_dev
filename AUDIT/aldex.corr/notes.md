# Notes for `aldex.corr()`

- **Role**: Computes feature-wise correlations (Pearson/Spearman) on CLR-transformed data.
- **Dependencies**: Uses base R correlation and multiple-testing utilities (`cor.test`, `p.adjust`, etc.); see `Package_Inventory.md`.
- **Test coverage**: No dedicated tests; highlighted as a critical coverage gap in `Test_Coverage_Report.md`.
- **Optimization priority**: Classified as **HIGH** in `R_Code_Optimization_Summary.md` due to many `apply()` calls and expensive correlation computations.
- **Translation note**: In Julia, design for batched correlation computations with pre-allocation and potential threading/GPU support.


