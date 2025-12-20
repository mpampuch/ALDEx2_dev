# Benchmarks for `aitchison.mean()`

## Current benchmarking status

- No dedicated benchmarks yet; function is marked **MEDIUM** priority in `R_Code_Optimization_Summary.md`.

## Planned scenarios

- Benchmark on effect-size-style workloads where `aitchison.mean()` is called repeatedly across many features.
- Compare naive implementations vs optimized vectorized/loop-based versions in R (for reference) and Julia.

## Output and recording

- Once a `profile.R` script is implemented, record microbenchmark results and any noticeable numerical-stability issues here.


