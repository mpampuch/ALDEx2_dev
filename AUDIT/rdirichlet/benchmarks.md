# Benchmarks for `rdirichlet()`

## Current benchmarking status

- Not yet integrated into `benchmarking_infrastructure.R` as a standalone target.
- Identified as **HIGH** priority and a strong GPU candidate in `R_Code_Optimization_Summary.md`.

## Planned scenarios

- Measure sampling throughput (samples/sec) for varying numbers of features and MC samples on `selex`-scale alpha vectors.
- Compare serial vs parallel (threaded) implementations.

## Output and recording

- Microbenchmark CSVs to be written under `AUDIT/rdirichlet/` from dedicated profiling scripts.
- Notes here should capture scaling trends and any numerical-stability observations for extreme alpha values.


