# Benchmarks for `aldex.effect()`

## Current benchmarking status

- No dedicated benchmark function in `benchmarking_infrastructure.R` yet.
- Global optimization analysis (`R_Code_Optimization_Summary.md`) flags `aldex.effect()` as **CRITICAL** for performance (heavy use of `apply()` and `cbind()` in loops).

## Planned scenarios

- End-to-end effect-size computation on full `selex` data for typical `mc.samples` values.
- Stress tests with increased feature counts and MC samples to characterize memory usage and allocation hotspots.
- Comparison of serial vs parallel execution (when integrated with BiocParallel).

## Output and recording

- Microbenchmark CSVs and profiling outputs (profvis/Rprof) to be saved under `AUDIT/aldex.effect/`.
- Summary tables and observations to be added here once the corresponding `profile.R` is run.


