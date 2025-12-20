# Benchmarks for `aldex()`

## Current benchmarking status

- **Infrastructure**: `benchmarking_infrastructure.R` focuses on lower-level building blocks (`aldex.clr()`, `aldex.ttest()`, `aldex.glm()`).
- **Direct benchmarks**: None yet specific to the `aldex()` wrapper.

## Planned scenarios

- End-to-end runs on the full `selex` dataset for each `test` mode ("t", "glm", "iterative") with default parameters.
- Sensitivity benchmarks varying `mc.samples`, `denom` modes, and `include.sample.summary`.
- Comparative runs in serial vs parallel (`useMC`) to understand orchestrator overhead.

## Output and recording

- Microbenchmark summaries (median/quantile runtimes) written to CSV under `AUDIT/aldex/`.
- High-level wall-clock timings and memory notes summarized here after running per-function `profile.R`.


