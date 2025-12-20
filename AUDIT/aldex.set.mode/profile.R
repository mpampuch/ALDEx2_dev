# Profiling script for `aldex.set.mode()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)
example_conds <- rep(c("A", "B"), length.out = ncol(example_input))

profvis({
  result <- aldex.set.mode(example_input, example_conds, denom = "iqlr")
})

benchmark_results <- microbenchmark(
  "aldex.set.mode" = {
    aldex.set.mode(example_input, example_conds, denom = "iqlr")
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")
