# Benchmarks for `aldex.ttest()`

## Current benchmarking status

- **Infrastructure script**: `AUDIT/benchmarking_infrastructure.R` implements `benchmark_aldex_ttest()`.
- **Dataset**: Full `selex` dataset transformed once via `aldex.clr()`.
- **Artifacts generated**:
  - `AUDIT/aldex.ttest/benchmarks_microbenchmark.csv` – microbenchmark timings for the wrapper.

## Key measurements to track

- Runtime per call as a function of number of features and Monte Carlo samples.
- Sensitivity to paired vs unpaired tests.
- Overhead of the wrapper vs underlying `t.fast()` calls.

## Next steps

- Add additional benchmark scenarios with varying `mc.samples` and condition structures.
- Reuse these benchmarks to validate Julia `aldex.ttest()` performance against the R baseline.


