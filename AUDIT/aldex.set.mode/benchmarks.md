# Benchmarks for `aldex.set.mode()`

## Current benchmarking status

- No dedicated benchmarks yet; function is primarily a lightweight selector.
- Optimization summary classifies it as **HIGH** priority mainly because of its impact on downstream workflows, not raw cost.

## Planned scenarios

- Measure overhead of feature selection for different modes ("all", "iqlr", "zero", custom indices) on `selex`-sized matrices.
- Evaluate cost relative to `aldex.clr()` and downstream statistical tests.

## Output and recording

- If selection overhead is confirmed negligible, note that here and deprioritize detailed benchmarking.
- Otherwise, record microbenchmark results and any surprising hot spots (e.g., `apply()` use) to inform Julia translation.


