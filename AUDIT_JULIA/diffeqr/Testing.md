# diffeqr: Testing and Validation Patterns

## Objective / Focus Area

Examine testing patterns in diffeqr for R ↔ Julia interface validation, focusing on:

- Test structure and organization
- Deterministic vs. stochastic function testing
- Validation approaches
- Test utilities and helpers

## Testing & Validation Practices

### Test Structure

**Location:** `tests/testthat/`

**Files:**

- `test_ode.R` - ODE solving tests
- `test_sde.R` - Stochastic differential equation tests
- `test_dae.R` - Differential-algebraic equation tests
- `test_dde.R` - Delay differential equation tests

**Framework:** Uses `testthat` (standard R testing framework)

### Test Patterns Observed

#### 1. Basic Test Structure

```r
context("ODEs")

test_that('1D works',{
  skip_on_cran()
  de <- diffeqr::diffeq_setup()
  f <- function(u,p,t) {
    return(1.01*u)
  }
  u0 <- 1/2
  tspan <- c(0., 1.)
  prob = de$ODEProblem(f, u0, tspan)
  sol = de$solve(prob)
  sol$.(0.2)
  expect_true(length(sol$t)<200)
})
```

**Patterns:**

- **Context grouping**: Uses `context()` to group related tests
- **Skip on CRAN**: All tests use `skip_on_cran()` to avoid requiring Julia in CRAN checks
- **Setup in each test**: Each test calls `diffeq_setup()` (could be optimized with `setup()` and `teardown()`)
- **Property validation**: Tests validate solution properties (length, convergence, etc.)

#### 2. Deterministic Function Testing

**Example: ODE System Test**

```r
test_that('ODE system works',{
  skip_on_cran()
  de <- diffeqr::diffeq_setup()
  f <- function(u,p,t) {
    du1 = p[1]*(u[2]-u[1])
    du2 = u[1]*(p[2]-u[3]) - u[2]
    du3 = u[1]*u[2] - p[3]*u[3]
    return(c(du1,du2,du3))
  }
  u0 <- c(1.0,0.0,0.0)
  tspan <- list(0.0,100.0)
  p <- c(10.0,28.0,8/3)
  prob <- de$ODEProblem(f, u0, tspan, p)
  sol <- de$solve(prob)
  mat <- sapply(sol$u,identity)
  udf <- as.data.frame(t(mat))

  abstol <- 1e-8
  reltol <- 1e-8
  saveat <- 0:10000/100
  sol <- de$solve(prob,abstol=abstol,reltol=reltol,saveat=saveat)
  udf <- as.data.frame(t(sapply(sol$u,identity)))
  expect_true(length(sol$t)>200)
})
```

**Patterns:**

- **Property-based validation**: Tests solution properties (length, structure) rather than exact values
- **Multiple solve calls**: Tests different solver configurations
- **Data extraction**: Extracts solution data to R data structures for validation

#### 3. Stochastic Function Testing

**Note:** diffeqr tests SDEs but doesn't explicitly test reproducibility or statistical equivalence. This is a gap that ALDEx2.jl should address.

**Potential Pattern for ALDEx2.jl:**

```r
test_that('Monte Carlo sampling is reproducible',{
  skip_on_cran()
  aldex2jl <- aldex2jl_setup()

  # Set seed in Julia
  JuliaCall::julia_command("using Random; Random.seed!(12345)")

  # Run Monte Carlo sampling
  result1 <- aldex2jl$aldex_clr(reads, conditions, mc_samples=128)

  # Reset seed and run again
  JuliaCall::julia_command("Random.seed!(12345)")
  result2 <- aldex2jl$aldex_clr(reads, conditions, mc_samples=128)

  # Should produce identical results with same seed
  expect_equal(result1, result2)
})

test_that('Monte Carlo sampling is statistically equivalent',{
  skip_on_cran()
  aldex2jl <- aldex2jl_setup()

  # Run with different seeds (should be statistically equivalent)
  JuliaCall::julia_command("Random.seed!(11111)")
  result1 <- aldex2jl$aldex_clr(reads, conditions, mc_samples=1000)

  JuliaCall::julia_command("Random.seed!(22222)")
  result2 <- aldex2jl$aldex_clr(reads, conditions, mc_samples=1000)

  # Use statistical tests to validate equivalence
  # (e.g., Kolmogorov-Smirnov test, correlation test)
  expect_true(ks_test_equivalent(result1, result2))
})
```

### Test Utilities

**Current State:** diffeqr doesn't provide explicit test utilities. Tests are self-contained.

**Recommended for ALDEx2.jl:**

- **Helper functions for parallel testing**: Functions to call both R and Julia versions
- **Comparison utilities**: Functions to compare outputs (exact for deterministic, statistical for probabilistic)
- **Visualization helpers**: Functions to visualize differences side-by-side

## Validation Approaches

### 1. Solution Property Validation

**Current Approach:**

- Validate solution length, structure, convergence
- Extract data to R for further analysis
- Use `expect_true()` for property checks

**Example:**

```r
expect_true(length(sol$t)>200)
expect_true(sol$retcode == "Success")
```

### 2. Exact Value Validation (for Deterministic Functions)

**Not extensively used in diffeqr**, but could be used for ALDEx2.jl deterministic functions:

```r
# For deterministic functions (e.g., aitchison_mean)
expect_equal(result$mean, expected_mean, tolerance=1e-10)
```

### 3. Statistical Validation (for Probabilistic Functions)

**Not implemented in diffeqr**, but **critical for ALDEx2.jl**:

```r
# For probabilistic functions (e.g., aldex_clr with Monte Carlo)
# Use statistical tests rather than exact matching
expect_true(ks_test_equivalent(result1, result2))
expect_true(cor(result1$clr, result2$clr) > 0.95)
```

## Parallel Testing Framework (Recommended for ALDEx2.jl)

### Concept

Test both R ALDEx2 and Julia ALDEx2 implementations side-by-side with the same inputs, comparing outputs.

### Helper Functions Structure

**File: `tests/testthat/helper-parallel_test.R`**

```r
# Call both R and Julia versions with same inputs
call_both_versions <- function(func_name, ...) {
  # Call R version
  r_result <- do.call(paste0("aldex.", func_name), list(...))

  # Call Julia version
  aldex2jl <- aldex2jl_setup()
  julia_result <- do.call(aldex2jl[[func_name]], list(...))

  list(r = r_result, julia = julia_result)
}

# Compare outputs
compare_outputs <- function(r_result, julia_result,
                           tolerance = 1e-10,
                           use_statistical = FALSE) {
  if (use_statistical) {
    # Use statistical tests for probabilistic functions
    ks_test_equivalent(r_result, julia_result)
  } else {
    # Use exact matching for deterministic functions
    all.equal(r_result, julia_result, tolerance = tolerance)
  }
}
```

**File: `tests/testthat/helper-validation.R`**

```r
# Statistical equivalence tests
ks_test_equivalent <- function(x, y, alpha = 0.05) {
  # Kolmogorov-Smirnov test
  ks_result <- ks.test(x, y)
  ks_result$p.value > alpha
}

correlation_test <- function(x, y, threshold = 0.95) {
  cor(x, y) > threshold
}

# Dimension checking
check_dimensions <- function(r_result, julia_result) {
  # Extract dimensions from both results
  r_dims <- get_dimensions(r_result)
  julia_dims <- get_dimensions(julia_result)
  identical(r_dims, julia_dims)
}
```

### Test Example Using Parallel Testing

```r
test_that('aldex_clr produces equivalent results',{
  skip_on_cran()

  # Call both versions
  results <- call_both_versions("clr", reads, conditions, mc_samples=128)

  # For Monte Carlo (probabilistic), use statistical validation
  # Note: R and Julia use different RNGs, so same seed won't produce same sequence
  # Instead, validate statistical properties
  expect_true(ks_test_equivalent(results$r$clr, results$julia$clr))
  expect_true(correlation_test(results$r$clr, results$julia$clr, 0.9))

  # Check dimensions match
  expect_true(check_dimensions(results$r, results$julia))
})
```

## Direct Lessons for ALDEx2.jl

### 1. Test Structure

- **Use testthat framework**: Follow R package testing conventions
- **Skip on CRAN**: Use `skip_on_cran()` to avoid requiring Julia in CRAN checks
- **Group related tests**: Use `context()` to organize tests
- **Setup optimization**: Consider `setup()` and `teardown()` for shared initialization

### 2. Validation Strategy

- **Deterministic functions**: Use exact matching with tolerance (`expect_equal()`)
- **Probabilistic functions**: Use statistical tests (KS test, correlation) rather than exact matching
- **Property validation**: Validate solution properties (dimensions, structure, convergence)

### 3. Parallel Testing Framework

- **Create helper functions**: `helper-parallel_test.R` and `helper-validation.R`
- **Call both versions**: Test R and Julia implementations side-by-side
- **Statistical validation**: Use appropriate tests for probabilistic functions
- **Dimension checking**: Validate that outputs have matching dimensions

### 4. Seed Management

- **Independent seeds**: R and Julia use different RNGs, so same seed won't produce same sequence
- **Reproducibility**: Set seeds independently in R and Julia for reproducibility within each language
- **Statistical equivalence**: Use statistical tests to validate equivalent distributions, not exact matching

### 5. Error Handling

- **Meaningful errors**: Provide clear error messages when tests fail
- **Type validation**: Validate input types before calling functions
- **Dimension validation**: Check dimensions match expected values

## Open Questions / Gaps

1. **Test Performance**: How to handle slow tests (Julia initialization, large datasets)?

   - Solution: Use `skip_on_cran()`, mark slow tests, use smaller test datasets

2. **Continuous Integration**: How to set up CI for R package that requires Julia?

   - Solution: Use GitHub Actions with Julia setup, or skip tests on CRAN

3. **Test Coverage**: How to measure test coverage for R ↔ Julia interface?

   - Solution: Use `covr` for R code, Julia code coverage separately

4. **Regression Testing**: How to store and compare reference outputs?

   - Solution: Store reference outputs in `tests/reference_values/`, compare against them

5. **Statistical Test Selection**: Which statistical tests are appropriate for validating Monte Carlo results?
   - Solution: Kolmogorov-Smirnov for distribution equivalence, correlation for relationship strength
