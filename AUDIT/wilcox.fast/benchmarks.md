# Benchmarks for `wilcox.fast()`

## Current benchmarking status

- Currently exercised indirectly through `aldex.ttest()` workflows.
- Marked as **HIGH** impact but with more complex GPU potential in `R_Code_Optimization_Summary.md`.

## Planned scenarios

- Standalone microbenchmarks on matrices with different tie structures and sample sizes.
- Comparisons to base R `wilcox.test()` focusing on speed-ups and numerical equivalence.

## Output and recording

- Benchmark CSVs to live under `AUDIT/wilcox.fast/` after `profile.R` is implemented.
- Notes should highlight where ranking and p-value calculation dominate runtime to inform Julia design.


