# Profiling script for `iqlr.features()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)

profvis({
  result <- iqlr.features(example_input)
})

benchmark_results <- microbenchmark(
  "iqlr.features" = {
    iqlr.features(example_input)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


