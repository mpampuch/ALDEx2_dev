# Profiling script for `rdirichlet()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

alpha <- rep(1, 100)

profvis({
  result <- rdirichlet(1000, alpha)
})

benchmark_results <- microbenchmark(
  "rdirichlet" = {
    rdirichlet(1000, alpha)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


