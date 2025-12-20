# Benchmarks for `aldex.corr()`

## Current benchmarking status

- Not yet wired into `benchmarking_infrastructure.R`.
- Global optimization summary marks `aldex.corr()` as **HIGH priority** with many `apply()` calls and expensive correlation calculations.

## Planned scenarios

- Correlation analysis on CLR-transformed `selex` data with both Pearson and Spearman methods.
- Scaling study in number of features (rows) and covariates (`covar` dimension).
- Benchmarks contrasting serial vs threaded/parallel execution.

## Output and recording

- Microbenchmark and profiling outputs to be written under `AUDIT/aldex.corr/` once `profile.R` and/or infrastructure hooks are implemented.
- Summary of hot spots (e.g., correlation loops, p-value adjustments) to be documented here to guide Julia optimization.


