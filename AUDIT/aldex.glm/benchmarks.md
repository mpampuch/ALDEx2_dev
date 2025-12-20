# Benchmarks for `aldex.glm()`

## Current benchmarking status

- **Infrastructure script**: `AUDIT/benchmarking_infrastructure.R` implements `benchmark_aldex_glm()`.
- **Dataset**: Full `selex` dataset transformed via `aldex.clr()`.
- **Artifacts generated**:
  - `AUDIT/aldex.glm/benchmarks_microbenchmark.csv` – microbenchmark timings for GLM-based testing.

## Key measurements to track

- Runtime per call as a function of features, samples, and condition complexity.
- Overhead compared to `aldex.ttest()` for similar designs.
- Impact of GLM vs Kruskal–Wallis paths on performance.

## Next steps

- Add profiling (profvis/Rprof) hooks similar to `aldex.clr()`.
- Extend benchmarks to multi-class and unbalanced designs that are representative of real use-cases.


