# Profiling script for `aldex()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

# TODO: Replace with realistic inputs based on `selex` and typical condition vectors.

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)
example_conds <- rep(c("A", "B"), length.out = ncol(example_input))

profvis({
  result <- aldex(example_input, example_conds)
})

benchmark_results <- microbenchmark(
  "aldex" = {
    aldex(example_input, example_conds)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


