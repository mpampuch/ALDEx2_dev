# Profiling script for `wilcox.fast()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

set.seed(1)
example_input <- matrix(rnorm(1000), nrow = 10, ncol = 100)
conds <- rep(c(0, 1), length.out = ncol(example_input))

profvis({
  result <- wilcox.fast(example_input, conds)
})

benchmark_results <- microbenchmark(
  "wilcox.fast" = {
    wilcox.fast(example_input, conds)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


