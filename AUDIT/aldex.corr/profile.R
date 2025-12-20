# Profiling script for `aldex.corr()`
# Generated from `AUDIT/audit_template.r`; customize inputs before use.

library(microbenchmark)
library(profvis)

example_input <- matrix(rpois(1000, lambda = 5), nrow = 10, ncol = 100)
example_conds <- rep(c("A", "B"), length.out = ncol(example_input))

clr <- aldex.clr(example_input, example_conds)

# Example covariate: simple numeric vector
covar <- rnorm(ncol(example_input))

profvis({
  result <- aldex.corr(clr, covar)
})

benchmark_results <- microbenchmark(
  "aldex.corr" = {
    aldex.corr(clr, covar)
  },
  times = 10L
)
print(benchmark_results)

write.csv(as.data.frame(benchmark_results), "benchmark_results.csv")


