# diffeqr: R ↔ Julia Interface Analysis

## Objective / Focus Area

Understand how `diffeqr` provides seamless R ↔ Julia interoperability for DifferentialEquations.jl and DiffEqGPU.jl, focusing on:

- JuliaCall integration patterns
- Type conversions between R and Julia
- Development-mode loading and hot-reloading
- Function wrapping and lazy initialization

## Implementation Patterns Observed

### 1. Setup and Initialization Pattern

**Key Function: `diffeq_setup()`**

```r
diffeq_setup <- function (pkg_check=TRUE,...){
  julia <- JuliaCall::julia_setup(installJulia=TRUE,...)
  if(pkg_check) JuliaCall::julia_install_package_if_needed("DifferentialEquations")
  JuliaCall::julia_library("DifferentialEquations")

  functions <- JuliaCall::julia_eval("filter(isascii, replace.(string.(propertynames(DifferentialEquations)),\"!\"=>\"_bang\"))")
  de <- julia_pkg_import("DifferentialEquations",functions)
  # ... autowrap solution types ...
  de
}
```

**Patterns Identified:**

- **Lazy initialization**: Uses `julia_pkg_import()` which creates an environment with lazy initialization
- **Automatic package installation**: Checks and installs Julia packages if needed
- **Function name filtering**: Filters non-ASCII characters and replaces `!` with `_bang` for R compatibility
- **Autowrap for complex types**: Uses `JuliaCall::autowrap()` to expose solution object fields (`t`, `u`) to R

### 2. Lazy Function Loading Pattern

**Key Functions: `julia_pkg_import()` and `julia_function()`**

```r
julia_pkg_import <- function(pkg_name, func_list){
  env <- new.env(parent = emptyenv())
  env$setup <- function(...){
    JuliaCall::julia_setup(...)
    JuliaCall::julia_library(pkg_name)
    env$initialized <- TRUE
  }
  for (fname in func_list) {
    julia_function(func_name = fname,
                   pkg_name = pkg_name,
                   env = env)
  }
  env
}

julia_function <- function(func_name, pkg_name = "Main", env = emptyenv()){
  fname <- paste0(pkg_name, ".", func_name)
  f <- function(..., need_return = c("R", "Julia", "None"), show_value = FALSE){
    if (!isTRUE(env$initialized)) {
      env$setup()
    }
    JuliaCall::julia_do.call(func_name = fname, list(...),
                             need_return = match.arg(need_return),
                             show_value = show_value)
  }
  env[[func_name]] <- f
}
```

**Patterns Identified:**

- **Lazy initialization**: Functions check `env$initialized` before first use
- **Environment-based state**: Uses R environments to store initialization state
- **Dynamic function creation**: Creates R wrapper functions dynamically for each Julia function
- **Return value control**: Allows specifying whether to return R object, Julia object, or nothing

### 3. Type Conversion Patterns

**Observed Conversions:**

- **R numeric vectors** → Julia `Array{Float64}` (automatic via JuliaCall)
- **R matrices** → Julia `Array{Float64, 2}` (automatic via JuliaCall)
- **R lists** → Julia tuples or NamedTuples (automatic via JuliaCall)
- **R data.frames** → Not directly used in diffeqr; uses matrices/vectors instead
- **Julia solution objects** → R lists with accessible fields via `autowrap()`

**Key Insight:** JuliaCall handles most basic type conversions automatically. Complex types require explicit wrapping via `autowrap()`.

### 4. GPU Backend Setup Pattern

**Key Function: `diffeqgpu_setup()`**

```r
diffeqgpu_setup <- function (backend){
  JuliaCall::julia_install_package_if_needed("DiffEqGPU")
  JuliaCall::julia_library("DiffEqGPU")
  functions <- JuliaCall::julia_eval("filter(isascii, replace.(string.(propertynames(DiffEqGPU)),\"!\"=>\"_bang\"))")
  degpu <- julia_pkg_import("DiffEqGPU",functions)

  if (backend == "CUDA") {
    JuliaCall::julia_install_package_if_needed("CUDA")
    JuliaCall::julia_library("CUDA")
    backend <- julia_pkg_import("CUDA",c("CUDABackend"))
    degpu$CUDABackend <- backend$CUDABackend
  }
  # ... similar for AMDGPU, Metal, oneAPI ...
  degpu
}
```

**Patterns Identified:**

- **Backend selection**: User specifies backend at setup time
- **Conditional package loading**: Only loads the selected GPU backend package
- **Backend object attachment**: Attaches backend object to the main environment
- **Extension pattern**: Follows Julia's extension system pattern (optional dependencies)

### 5. Development Mode Loading

**Not Explicitly Implemented in diffeqr:**

- No explicit development mode support in current diffeqr code
- Would require: `Pkg.develop()` or `Pkg.activate()` to load local package
- Could be added via `JuliaCall::julia_command("using Pkg; Pkg.develop(path=\"...\")")`

## Testing & Validation Practices

### Test Structure (from `tests/testthat/`)

**Pattern:**

- Uses `testthat` framework
- Tests skip on CRAN (`skip_on_cran()`) to avoid requiring Julia in CRAN checks
- Tests cover:
  - Basic ODE solving
  - System of ODEs
  - JIT optimization
  - SDE solving
  - DAE solving
  - DDE solving

**Example Test:**

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
  expect_true(length(sol$t)>200)
})
```

**Key Observations:**

- Tests are straightforward: setup, create problem, solve, validate
- No explicit side-by-side R vs. Julia testing (R package is the interface)
- Validation focuses on solution properties (length, convergence, etc.)

## Performance / Benchmarking Notes

- **First-time setup is slow**: Includes Julia precompilation
- **Lazy initialization**: Functions only initialize Julia when first called
- **Type conversion overhead**: Automatic conversions may have overhead for large arrays
- **No explicit benchmarking**: diffeqr focuses on correctness, not performance comparison

## Direct Lessons for ALDEx2.jl

### 1. Setup Function Pattern

- **Use lazy initialization**: Create environment with `initialized` flag
- **Auto-install packages**: Check and install Julia packages if needed
- **Filter function names**: Handle non-ASCII and special characters (`!` → `_bang`)
- **Autowrap complex types**: Use `autowrap()` for ALDEx2 result objects

### 2. Function Wrapping Pattern

- **Dynamic function creation**: Create R wrappers for each Julia function
- **Lazy Julia initialization**: Check initialization state before calling Julia
- **Return value control**: Allow specifying return format (R object, Julia object, or None)

### 3. Type Conversion Strategy

- **Leverage automatic conversions**: JuliaCall handles basic types automatically
- **Explicit wrapping for complex types**: Use `autowrap()` for ALDEx2 result types
- **Document expected types**: Clearly document what R types map to what Julia types

### 4. Development Mode Support (Enhancement)

- **Add development mode**: Support loading local ALDEx2.jl package during development
- **Hot-reloading**: Enable reloading Julia package without restarting R session
- **Path-based activation**: Allow specifying path to local package

### 5. GPU Backend Support

- **Backend selection at setup**: Allow user to specify GPU backend
- **Conditional loading**: Only load selected backend package
- **Backend object attachment**: Attach backend to main environment for easy access

### 6. Testing Strategy

- **Use testthat framework**: Follow R package testing conventions
- **Skip on CRAN**: Use `skip_on_cran()` to avoid requiring Julia in CRAN checks
- **Test solution properties**: Validate outputs (dimensions, convergence, statistical properties)
- **Add parallel testing**: Compare R ALDEx2 vs. Julia ALDEx2 outputs side-by-side

## Open Questions / Gaps

1. **Development Mode**: How to best support loading local Julia package during development?

   - Solution: Add `aldex2jl_setup(dev_path = NULL)` parameter
   - Use `Pkg.develop()` or `Pkg.activate()` if path provided

2. **Hot-reloading**: How to reload Julia package without restarting R session?

   - Solution: Use `Revise.jl` or `Pkg.precompile()` + reload

3. **Type Safety**: How to validate type conversions and catch errors early?

   - Solution: Add validation functions that check types before calling Julia

4. **Error Handling**: How to provide meaningful error messages when Julia calls fail?

   - Solution: Wrap Julia calls in try-catch, extract and format Julia error messages

5. **Parallel Testing Framework**: How to structure side-by-side R vs. Julia testing?

   - Solution: Create helper functions in `helper-parallel_test.R` and `helper-validation.R`
   - Functions to call both versions, compare outputs, visualize differences

6. **Statistical Validation**: How to validate probabilistic functions (Monte Carlo sampling)?
   - Solution: Use statistical tests (Kolmogorov-Smirnov, correlation) rather than exact matching
   - Set seeds independently in R and Julia for reproducibility (not for matching)


