# Notes for `rdirichlet()`

- **Role**: Core Dirichlet random sampler used to generate Monte Carlo instances in `aldex.clr()`.
- **Dependencies**: Relies on base R random-number generation; called many times per analysis.
- **Test coverage**: Only indirectly exercised through CLR workflows; see `Test_Coverage_Report.md` for gaps.
- **Optimization priority**: Marked **HIGH** and a strong **GPU candidate** in `R_Code_Optimization_Summary.md`.
- **Translation note**: Julia implementation should focus on high-throughput sampling with good statistical properties, ideally via GPU kernels or efficient vectorized CPU code.


