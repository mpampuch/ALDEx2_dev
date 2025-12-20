# Profiling script for `aitchison.mean()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)

profvis({
  result <- aitchison.mean(example_input)
})

benchmark_results <- microbenchmark(
  "aitchison.mean" = {
    aitchison.mean(example_input)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


