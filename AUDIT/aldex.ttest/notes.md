# Notes for `aldex.ttest()`

- **Role**: Wraps differential testing on CLR-transformed data using `t.fast()`/`wilcox.fast()`.
- **Dependencies**: Relies on `aldex.clr()` for input objects and fast statistical kernels in `stats.fast.R`.
- **Test coverage**: Well tested (100% for the current implementation) via `test-aldex.ttest.R`; see `Test_Coverage_Report.md`.
- **Optimization priority**: Marked **HIGH** in `R_Code_Optimization_Summary.md` due to frequent calls across features and MC instances.
- **Translation note**: Keep interface compatible while mapping to highly optimized Julia kernels; parallelization over features/instances is an important design axis.


