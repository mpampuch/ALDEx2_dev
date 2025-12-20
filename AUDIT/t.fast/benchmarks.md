# Benchmarks for `t.fast()`

## Current benchmarking status

- Currently exercised indirectly through `aldex.ttest()` benchmarks.
- Identified as **HIGH** priority in `R_Code_Optimization_Summary.md` due to frequent per-feature, per-MC-instance calls.

## Planned scenarios

- Standalone microbenchmarks on synthetic matrices to isolate `t.fast()` from wrapper overhead.
- Comparisons to base R `t.test()` in terms of throughput and scaling with number of features and MC instances.

## Output and recording

- Benchmark CSVs to be stored under `AUDIT/t.fast/` once dedicated benchmarking scripts are added.
- Use results to validate Julia `t.fast` equivalents and to decide whether further low-level optimization is needed.


