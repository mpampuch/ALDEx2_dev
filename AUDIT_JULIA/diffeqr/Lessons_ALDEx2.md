# diffeqr: Actionable Takeaways for ALDEx2.jl

## Summary

This document consolidates key lessons from the diffeqr audit for implementing ALDEx2_jl_R, the R interface package for ALDEx2.jl.

## Critical Implementation Patterns

### 1. Setup Function with Lazy Initialization

**Pattern from diffeqr:**

- Create environment with `initialized` flag
- Lazy initialization: check flag before first Julia call
- Auto-install packages if needed
- Filter function names for R compatibility

**Implementation for ALDEx2.jl:**

```r
aldex2jl_setup <- function(dev_path = NULL, pkg_check = TRUE, ...) {
  julia <- JuliaCall::julia_setup(installJulia = TRUE, ...)

  # Support development mode
  if (!is.null(dev_path)) {
    JuliaCall::julia_command(paste0("using Pkg; Pkg.develop(path=\"", dev_path, "\")"))
  }

  if (pkg_check) {
    JuliaCall::julia_install_package_if_needed("ALDEx2_jl")
  }
  JuliaCall::julia_library("ALDEx2_jl")

  # Get function names and create wrappers
  functions <- JuliaCall::julia_eval("filter(isascii, replace.(string.(propertynames(ALDEx2_jl)),\"!\"=>\"_bang\"))")
  aldex2jl <- julia_pkg_import("ALDEx2_jl", functions)

  # Autowrap result types
  JuliaCall::autowrap("ALDEx2_jl.ALDExCLR", fields = c("reads", "conditions", "clr", "mc_samples"))
  JuliaCall::autowrap("ALDEx2_jl.ALDExResults", fields = c("we.ep", "we.eBH", "wi.ep", "wi.eBH", "effect", "overlap"))

  aldex2jl
}
```

### 2. Function Wrapping with Lazy Initialization

**Pattern from diffeqr:**

- Dynamic function creation for each Julia function
- Environment-based state management
- Lazy Julia initialization

**Implementation for ALDEx2.jl:**

```r
julia_pkg_import <- function(pkg_name, func_list) {
  env <- new.env(parent = emptyenv())
  env$setup <- function(...) {
    JuliaCall::julia_setup(...)
    JuliaCall::julia_library(pkg_name)
    env$initialized <- TRUE
  }
  for (fname in func_list) {
    julia_function(func_name = fname, pkg_name = pkg_name, env = env)
  }
  env
}

julia_function <- function(func_name, pkg_name = "Main", env = emptyenv()) {
  fname <- paste0(pkg_name, ".", func_name)
  force(fname)
  f <- function(..., need_return = c("R", "Julia", "None"), show_value = FALSE) {
    if (!isTRUE(env$initialized)) {
      env$setup()
    }
    JuliaCall::julia_do.call(func_name = fname, list(...),
                             need_return = match.arg(need_return),
                             show_value = show_value)
  }
  force(f)
  env[[func_name]] <- f
}
```

### 3. Type Conversion Strategy

**Key Insights:**

- JuliaCall handles basic types automatically (numeric vectors, matrices)
- Complex types require explicit wrapping via `autowrap()`
- Document expected type mappings clearly

**Implementation for ALDEx2.jl:**

```r
# Automatic conversions (handled by JuliaCall):
# - R numeric vector → Julia Array{Float64}
# - R matrix → Julia Array{Float64, 2}
# - R list → Julia tuple or NamedTuple

# Explicit conversions needed:
# - R data.frame → Julia DataFrame (convert manually)
# - ALDEx2 result objects → R lists (via autowrap)

convert_to_julia_dataframe <- function(r_df) {
  # Convert R data.frame to Julia DataFrame
  JuliaCall::julia_assign("r_data", as.matrix(r_df))
  JuliaCall::julia_command("using DataFrames; df = DataFrame(r_data, :auto)")
  JuliaCall::julia_eval("df")
}
```

### 4. GPU Backend Support

**Pattern from diffeqr:**

- Backend selection at setup time
- Conditional package loading
- Backend object attachment

**Implementation for ALDEx2.jl:**

```r
aldex2jl_gpu_setup <- function(backend = "CUDA") {
  JuliaCall::julia_install_package_if_needed("ALDEx2GPU")
  JuliaCall::julia_library("ALDEx2GPU")
  functions <- JuliaCall::julia_eval("filter(isascii, replace.(string.(propertynames(ALDEx2GPU)),\"!\"=>\"_bang\"))")
  aldex2gpu <- julia_pkg_import("ALDEx2GPU", functions)

  if (backend == "CUDA") {
    JuliaCall::julia_install_package_if_needed("CUDA")
    JuliaCall::julia_library("CUDA")
    backend_obj <- julia_pkg_import("CUDA", c("CUDABackend"))
    aldex2gpu$CUDABackend <- backend_obj$CUDABackend
  }
  # ... similar for other backends ...

  aldex2gpu
}
```

## Testing Strategy

### Parallel Testing Framework

**Create helper files:**

**`tests/testthat/helper-parallel_test.R`:**

```r
# Call both R and Julia versions with same inputs
call_both_versions <- function(func_name, ...) {
  # Call R ALDEx2 version
  r_func <- get(paste0("aldex.", func_name), envir = asNamespace("ALDEx2"))
  r_result <- do.call(r_func, list(...))

  # Call Julia ALDEx2 version
  aldex2jl <- aldex2jl_setup()
  julia_func <- aldex2jl[[func_name]]
  julia_result <- do.call(julia_func, list(...))

  list(r = r_result, julia = julia_result)
}
```

**`tests/testthat/helper-validation.R`:**

```r
# Statistical equivalence for probabilistic functions
ks_test_equivalent <- function(x, y, alpha = 0.05) {
  ks_result <- ks.test(x, y)
  ks_result$p.value > alpha
}

# Exact matching for deterministic functions
expect_equal_with_tolerance <- function(actual, expected, tolerance = 1e-10) {
  expect_true(all(abs(actual - expected) < tolerance))
}
```

### Test Example

```r
test_that('aldex_clr produces statistically equivalent results', {
  skip_on_cran()

  # Set seeds independently (for reproducibility, not matching)
  set.seed(12345)
  JuliaCall::julia_command("using Random; Random.seed!(67890)")

  # Call both versions
  results <- call_both_versions("clr", reads, conditions, mc_samples = 128)

  # Statistical validation (Monte Carlo is probabilistic)
  expect_true(ks_test_equivalent(results$r$clr, results$julia$clr))
  expect_true(cor(results$r$clr, results$julia$clr) > 0.9)

  # Dimension validation
  expect_equal(dim(results$r$clr), dim(results$julia$clr))
})
```

## Development Workflow

### Development Mode Loading

**Enhancement over diffeqr:**

```r
aldex2jl_setup <- function(dev_path = NULL, ...) {
  # ... standard setup ...

  # Support development mode
  if (!is.null(dev_path)) {
    # Load local package in development mode
    JuliaCall::julia_command(paste0("using Pkg; Pkg.develop(path=\"", dev_path, "\")"))
    JuliaCall::julia_command("using Revise")  # Enable hot-reloading
    JuliaCall::julia_library("ALDEx2_jl")
  } else {
    # Standard package loading
    JuliaCall::julia_install_package_if_needed("ALDEx2_jl")
    JuliaCall::julia_library("ALDEx2_jl")
  }

  # ... rest of setup ...
}
```

### Hot-Reloading Support

**Use Revise.jl for hot-reloading during development:**

```r
# In setup function
if (!is.null(dev_path)) {
  JuliaCall::julia_command("using Revise")
  JuliaCall::julia_command(paste0("Revise.track(\"", dev_path, "\")"))
}
```

## Error Handling

### Meaningful Error Messages

**Pattern:**

- Wrap Julia calls in try-catch
- Extract and format Julia error messages
- Provide context about what operation failed

**Implementation:**

```r
safe_julia_call <- function(expr, error_context = "") {
  tryCatch({
    JuliaCall::julia_eval(expr)
  }, error = function(e) {
    stop(paste0("Error in ", error_context, ": ", e$message))
  })
}
```

## Key Differences from diffeqr

### 1. Statistical Validation Required

**ALDEx2.jl needs:**

- Statistical equivalence tests for Monte Carlo functions
- Correlation tests for probabilistic outputs
- Seed management (independent seeds for R and Julia)

**diffeqr doesn't need this** because:

- DE solutions are deterministic (given same inputs)
- SDE tests focus on solution properties, not statistical equivalence

### 2. Parallel Testing Critical

**ALDEx2.jl needs:**

- Side-by-side R vs. Julia testing throughout development
- Comparison utilities for deterministic and probabilistic functions
- Reference value storage for regression testing

**diffeqr doesn't need this** because:

- R package is the interface (no separate R implementation to compare against)

### 3. Development Mode Essential

**ALDEx2.jl needs:**

- Development mode loading for local package
- Hot-reloading support for iterative development
- Path-based activation

**diffeqr has minimal development mode support**, but ALDEx2.jl needs it more because:

- Parallel testing requires frequent iteration
- Need to test Julia functions as they're implemented

## Implementation Checklist

- [ ] Implement `aldex2jl_setup()` with lazy initialization
- [ ] Implement `julia_pkg_import()` and `julia_function()` helpers
- [ ] Add development mode support (`dev_path` parameter)
- [ ] Implement type conversion utilities (data.frame → DataFrame)
- [ ] Add `autowrap()` for ALDEx2 result types
- [ ] Create `helper-parallel_test.R` with `call_both_versions()`
- [ ] Create `helper-validation.R` with comparison utilities
- [ ] Implement GPU backend setup function
- [ ] Add error handling with meaningful messages
- [ ] Write test examples using parallel testing framework
- [ ] Document type conversion mappings
- [ ] Set up hot-reloading with Revise.jl


