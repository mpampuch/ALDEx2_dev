# Profiling script for `aldex.effect()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)
example_conds <- rep(c("A", "B"), length.out = ncol(example_input))

clr <- aldex.clr(example_input, example_conds)

profvis({
  result <- aldex.effect(clr)
})

benchmark_results <- microbenchmark(
  "aldex.effect" = {
    aldex.effect(clr)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


