# Benchmarks for `aldex.clr()`

## Current benchmarking status

- **Infrastructure script**: `AUDIT/benchmarking_infrastructure.R` implements `benchmark_aldex_clr()`.
- **Datasets**: Full `selex` dataset used as the canonical "small" benchmark.
- **Artifacts generated** (see script comments):
  - `AUDIT/aldex.clr/profvis_small.html` – interactive profile.
  - `AUDIT/aldex.clr/Rprof_small_Rprof.out` – base `Rprof` output.
  - `AUDIT/aldex.clr/benchmarks_microbenchmark.csv` – microbenchmark results.
  - `AUDIT/aldex.clr/benchmarks_bench.csv` – `bench` package results.

## Key measurements to track

- Time per full CLR transform (wall-clock, CPU via `Rprof`).
- Scaling of runtime with `mc.samples`, number of features, and sample count.
- Impact of `denom` mode and parallel vs serial (`useMC`) execution.

## Next steps

- Extend benchmarks to larger synthetic datasets for scaling analysis.
- Mirror these scenarios when porting to Julia to compare absolute and relative performance.


