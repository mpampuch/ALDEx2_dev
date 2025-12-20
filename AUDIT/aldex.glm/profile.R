# Profiling script for `aldex.glm()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)
example_conds <- factor(rep(c("A", "B"), length.out = ncol(example_input)))

clr <- aldex.clr(example_input, example_conds)

profvis({
  result <- aldex.glm(clr, ~example_conds)
})

benchmark_results <- microbenchmark(
  "aldex.glm" = {
    aldex.glm(clr, ~example_conds)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


