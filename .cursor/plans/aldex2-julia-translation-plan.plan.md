---
name: ""
overview: ""
todos: []
---

# ALDEx2 Julia Translation Plan

## Overview

This plan outlines the translation of the ALDEx2 R package to Julia, creating a high-performance implementation with GPU support and an R interface, following the pattern established by the DifferentialEquations.jl ecosystem.

**Key Strategy:** The R interface is implemented first (Phase 1) to enable parallel testing of Julia functions alongside the original R package throughout development. This ensures continuous validation and equivalence checking as each function is implemented, rather than waiting until the end for validation.

## Package Structure

The project will consist of three main packages:

1. **ALDEx2.jl** - Core Julia package with CPU-optimized implementations
2. **ALDEx2GPU.jl** - GPU-accelerated version using KernelAbstractions.jl
3. **ALDEx2_jl_R** - R interface package using JuliaCall (similar to diffeqr)

## 1. ALDEx2.jl - Core Package

### 1.1 Package Structure

```
ALDEx2.jl/
├── Project.toml
├── README.md
├── LICENSE
├── src/
│   ├── ALDEx2.jl              # Main module file
│   ├── types.jl               # Core type definitions
│   ├── distributions.jl       # Dirichlet distribution functions
│   ├── clr.jl                 # CLR transformation
│   ├── feature_selection.jl   # IQLR and zero feature selection
│   ├── statistical_tests.jl   # t-test, Wilcoxon, GLM, Kruskal-Wallis
│   ├── effect_sizes.jl        # Effect size calculations
│   ├── correlation.jl         # Correlation analysis
│   └── utils.jl               # Utility functions
├── test/
│   ├── runtests.jl
│   ├── test_distributions.jl
│   ├── test_clr.jl
│   ├── test_statistical_tests.jl
│   ├── test_effect_sizes.jl
│   └── test_integration.jl
└── docs/
    ├── make.jl
    └── src/
        ├── index.md
        ├── api.md
        └── examples.md
```

### 1.2 Core Dependencies

```toml
[deps]
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
MultipleTesting = "f8716d33-7c4a-5097-896f-ce0ec3893b25"
GLM = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
```

### 1.3 Key Functions to Implement

**Core Functions:**

- `aldex_clr()` - CLR transformation with Monte Carlo sampling
- `aldex_ttest()` - Welch's t-test and Wilcoxon rank-sum tests
- `aldex_glm()` - GLM and Kruskal-Wallis tests
- `aldex_effect()` - Effect size calculations
- `aldex_corr()` - Correlation analysis
- `aldex()` - Main wrapper function

**Supporting Functions:**

- `rdirichlet()` - Dirichlet distribution sampling
- `aitchison_mean()` - Aitchison mean calculation
- `iqlr_features()` - Inter-quartile log-ratio feature selection
- `zero_features()` - Zero-inflated data handling

### 1.4 Performance Optimization Strategy

**Note:** Specific optimization strategies will be informed by Phase 0 audit findings. The following are general Julia performance principles:

Following Julia performance tips:

- Use type stability throughout
- Minimize allocations in hot paths
- Use views instead of copies
- Leverage SIMD operations
- Multi-threading for Monte Carlo sampling (based on Phase 0 parallelization analysis)
- Pre-allocate arrays where possible
- Use `@inbounds` and `@simd` where safe
- Focus optimization efforts on functions identified as computationally expensive in Phase 0
- Apply parallelization strategies identified in Phase 0 audit

The table below includes explicit recommendations for translating R performance patterns to Julia:

### Julia Performance Guidelines Based on R Audit Patterns

| R Pattern Observed                                                                                    | Recommended Julia Approach                                                                                                                 |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Avoiding method dispatch (e.g., `mean.default()`, `.Internal()` calls)                                | Rely on Julia’s **type-stable multiple dispatch**; remove any attempts to bypass dispatch.                                                 |
| Vectorization to avoid loops (`rowSums()`, `apply()` replacements)                                    | Write **clear, type-stable loops**; vectorize only when using BLAS/matrix operations or for readability, **not performance**.              |
| Rewriting base functions for speed (`quickdf()` replacing `as.data.frame()`)                          | Implement **specialized methods for specific types**, keeping base functions intact; rely on Julia compiler optimizations.                 |
| Avoiding object growth in loops (`c()`, `rbind()`, `paste()`)                                         | Use **mutable arrays with `push!` or `append!`**, or **preallocate arrays** to avoid unnecessary allocations.                              |
| Using C-backed or specialized helpers for performance (`rowSums()`, `vapply()`, `any(x==val)`)        | Use **loops or array operations in Julia**; helpers are only needed for clarity, not speed.                                                |
| Avoiding coercions/type conversions (`apply()` on data frames)                                        | Ensure **type stability and explicit conversions**; coercion avoidance is mostly unnecessary in Julia.                                     |
| Unsafe internal calls for micro-optimizations (`.Internal()` functions)                               | Rely on **compiler optimizations, preallocation, and type-stable code**; use unsafe operations only in exceptional, well-documented cases. |
| Repeated method dispatch in tight numeric loops                                                       | Rely on **compiled multiple dispatch**; ensure functions are **type-stable** so dispatch is resolved at compile time.                      |
| Vectorized subsetting/replacement to improve performance (`x[is.na(x)] <- 0`)                         | Use **loops or broadcasting (`.=`)** in Julia, which are efficient and clearer; vectorized assignment is unnecessary for speed.            |
| Simplifying computations via specialized arguments (`read.csv(colClasses=...)`, `factor(levels=...)`) | Use **type-stable constructors or explicit parsing functions**; most operations are already fast when types are clear.                     |

### Implementation Notes

- All core functions will be written **type-stable from the start**, avoiding ad-hoc workarounds common in R.
- Loops will **replace R-style vectorization** in hot paths unless BLAS or GPU-friendly operations are being leveraged.
- Preallocation and in-place operations will be **prioritized for arrays and matrices**, especially in Monte Carlo sampling (`aldex_clr`) and per-feature statistical tests.
- Multiple dispatch will be fully leveraged, replacing R’s `.default` and internal method bypasses.
- Unsafe operations and internal calls will only be used if performance profiling shows significant gains **and safety can be guaranteed**.
- All probabilistic functions will maintain reproducibility via **thread-safe RNGs**, avoiding R-style global RNG dependence.

## 2. ALDEx2GPU.jl - GPU Package

### 2.1 Package Structure

```
ALDEx2GPU.jl/
├── Project.toml
├── README.md
├── src/
│   ├── ALDEx2GPU.jl           # Main module
│   ├── gpu_clr.jl             # GPU-accelerated CLR
│   ├── gpu_distributions.jl   # GPU Dirichlet sampling
│   ├── gpu_statistical_tests.jl
│   └── kernels/
│       ├── clr_kernels.jl
│       ├── dirichlet_kernels.jl
│       └── test_kernels.jl
├── ext/
│   ├── CUDAExt.jl
│   ├── AMDGPUExt.jl
│   ├── MetalExt.jl
│   ├── oneAPIExt.jl
│   └── OpenCLExt.jl
└── test/
    └── test_gpu.jl
```

### 2.2 Dependencies

```toml
[deps]
ALDEx2 = "..." # UUID of ALDEx2.jl
KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"

[weakdeps]
CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
oneAPI = "8f75cd03-7ff8-4ecb-9b8f-daf728133b1b"
OpenCL = "08131aa3-fb12-5dee-8b74-c09406e224a0"

[extensions]
CUDAExt = ["CUDA"]
AMDGPUExt = ["AMDGPU"]
MetalExt = ["Metal"]
oneAPIExt = ["oneAPI"]
OpenCLExt = ["OpenCL"]
```

### 2.3 GPU Optimization Strategy

**Note:** Final GPU acceleration targets will be determined by Phase 0 audit findings. The following are preliminary candidates:

**Key GPU-Accelerated Operations (to be validated in Phase 0):**

1. **Monte Carlo Sampling** - Parallel Dirichlet sampling across MC instances (high parallelization potential)
2. **CLR Transformations** - Matrix operations on GPU arrays (embarrassingly parallel)
3. **Statistical Tests** - Parallel computation across features (independent per feature)
4. **Effect Size Calculations** - Vectorized operations (SIMD-friendly)

**Implementation Pattern:**

- Use KernelAbstractions.jl for backend-agnostic kernels
- Support multiple GPU backends (CUDA, AMDGPU, Metal, oneAPI, OpenCL)
- Use extension system for optional GPU dependencies
- Provide fallback to CPU when GPU unavailable
- Prioritize functions identified as high-value GPU candidates in Phase 0 audit
- Validate GPU speedup against Phase 0 CPU benchmarks

### 2.4 GPU Implementation Guidelines

**Critical guidelines for implementing GPU kernels in ALDEx2GPU.jl:**

#### 1. Kernel Design & Correctness

- **Memory Access Safety:** Guard memory access with bounds checking to prevent out-of-bounds errors. Use comments to indicate where this is done, then determine if bounds checking can be optimized by disabling with `@inbounds` after validation.
- **Grid-Stride Loops:** Use grid-stride loops whenever the input may be larger than the number of launched threads. This ensures all elements are processed regardless of grid size.
- **Output Buffers:** Always write to output buffers because GPU kernels cannot return values. Design kernels to take input and output buffers as parameters.
- **Input/Output Separation:** Keep input/output separation (avoid in-place operations) unless using atomic operations or doing safe element-wise mapping. This prevents race conditions and makes kernels easier to reason about.

#### 2. Performance & Execution Configuration

- **Precision:** Use `Float32` values instead of `Float64` for better GPU performance and memory efficiency, unless numerical precision requirements demand `Float64`.
- **Block Size:** A good block size is 128–512 threads, always a multiple of 32 (warp size). Start with 256 threads per block as a default.
- **Grid Size:** Start grid size at 2×–4× number of SMs (usually 20–100 blocks for typical GPUs). Adjust based on workload characteristics.
- **Kernel Fusion:** When launching many small kernels, try to fuse operations into one kernel to reduce launch overhead. This is especially important for operations that can be combined (e.g., CLR transformation followed by statistical computation).
- **Memory Coalescing:** Access memory using coalesced patterns (thread i touches element i, i+stride, …). Ensure consecutive threads access consecutive memory locations when possible.
- **Shared Memory:** If using shared memory, keep an eye on bank conflicts. Structure shared memory access to minimize conflicts.

#### 3. Debugging & Development Tips

- **Debugging Tools:** Use compute-sanitizer and cuda-gdb to catch potential errors in GPU code. These tools help identify memory access violations, race conditions, and other GPU-specific issues.
- **Print Debugging:** Print debugging in GPU kernels works only with:
  - Literal strings
  - Scalars
  - Use these for basic debugging, but prefer proper debugging tools for complex issues.
- **Isolation Testing:** For tricky bugs: temporarily reduce block/grid size so you can isolate behavior. Start with 1 block, 1 thread to verify correctness before scaling up.

#### 4. Avoiding Race Conditions

- **Reduction Operations:** Any reduction-like operation (sum, histogram, etc.) requires atomic operations. Be aware that atomics can be performance bottlenecks.
- **Minimize Atomics:** Avoid atomics wherever possible because they slow down the code. Design algorithms to minimize the need for atomics.
- **Shared Memory Reduction:** If possible, use shared memory reduction, then one atomic write per block → huge performance boost. This pattern is much faster than per-element atomics.

#### 5. Managing Random Number Generation

- **RNG Per Thread:** Pre-allocate RNG for each thread. Each thread must use its own RNG state indexed by thread ID. Never reuse a state across threads.
- **RNG Efficiency:** Avoid excessive RNG per thread; thousands of draws per thread can bottleneck registers. Consider generating random numbers in batches or using alternative approaches when possible.

#### 6. Common Mistakes to Avoid

- **Type Casting:** Be explicit about type casting in kernels. Ensure division and other operations use the correct numeric types (Float32 vs Float64) as specified.
- **Memory Management:** Ensure all GPU memory allocations are properly freed. Use Julia's automatic memory management where possible, but be aware of memory pressure.

#### 7. Testing & Validation

- **Incremental Testing:** Always test kernels first with:
  - Small inputs
  - 1 block, 1 thread configuration
  - Gradually increase complexity
- **CPU Comparison:** Compare GPU results to a trusted CPU implementation. The CPU version (validated against R) serves as the ground truth.
- **Assert Checks:** Use assert sanity checks inside kernels when testing. Remove or conditionally compile these for production builds.

#### 8. Workflow & Productivity Tips

- **Keep Kernels Minimal:** Keep GPU code minimal—move setup, preprocessing, or complex logic to the host (CPU). Kernels should focus on the parallel computation itself.
- **Host-Device Separation:** Clearly separate host code (setup, data preparation, result collection) from device code (kernels). This improves maintainability and performance.

## 3. ALDEx2_jl_R - R Interface Package

**Note:** This interface is implemented in Phase 1 (immediately after audit) to enable parallel testing during development.

### 3.1 Package Structure

```
ALDEx2_jl_R/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── aldex2jl_setup.R       # Setup function (already exists)
│   ├── aldex2jl_clr.R
│   ├── aldex2jl_ttest.R
│   ├── aldex2jl_glm.R
│   ├── aldex2jl_effect.R
│   └── aldex2jl.R             # Main wrapper
├── man/
│   └── *.Rd files
└── tests/
    └── testthat/
        ├── helper-parallel_test.R    # Parallel testing utilities (auto-sourced by testthat)
        └── helper-validation.R      # Output comparison utilities (auto-sourced by testthat)
```

### 3.2 Implementation Pattern

Follow the `diffeqr` pattern with enhancements for parallel testing:

- Use JuliaCall for R-Julia interface
- Provide setup function that initializes Julia and loads packages
  - Support development mode loading (load Julia package from local path)
  - Enable hot-reloading during development
- Convert R data structures to Julia equivalents
- Return results in R-friendly formats
- Support both CPU and GPU backends
- **Parallel Testing Features:**
  - Utilities to call both R and Julia versions with same inputs
  - Comparison functions for validating equivalent outputs
  - Side-by-side result visualization
  - Automated validation workflows

## 4. Implementation Phases (Test-Driven Development)

**Detailed TDD Workflow for Each Function:**

This workflow ensures comprehensive testing and validation at each step, with continuous comparison against the R implementation.

### Step-by-Step TDD Process

**Step 1: Function Classification**

- Determine if function is **deterministic** or **probabilistic** (from Phase 0 audit)
- Document expected behavior and validation approach

**Step 2: Generate Reference Values**

- Write a small R script using the original ALDEx2 package
- Generate reference values from test data
- Save reference outputs for deterministic functions
- Document expected statistical properties for probabilistic functions
- Commit: "Add reference values for [function_name]"

**Step 3: Write Julia Unit Tests**

- Write Julia tests in `test/test_[function_name].jl`
- For **deterministic functions**: Use strict equality tests (exact matching)
- For **probabilistic functions**: Use statistical equivalence tests (e.g., Kolmogorov-Smirnov, correlation tests)
- Reference the saved reference values from Step 2
- **Watch tests fail** (verify test framework works correctly)
- Commit: "Add Julia unit tests for [function_name] (RED phase)"

**Step 4: Write R Parallel Tests**

- Write R tests in `tests/testthat/test-[function_name].R`
- Test both original R package function and Julia function (via R interface)
- Use helper functions from `helper-parallel_test.R` and `helper-validation.R`
- For **deterministic functions**: Compare outputs exactly
- For **probabilistic functions**: Use statistical equivalence tests with same seeds
  - Set seeds independently in R and Julia (for reproducibility within each language)
  - R seed ensures R function produces reproducible results across test runs
  - Julia seed ensures Julia function produces reproducible results across test runs
  - **Note:** R and Julia use different RNGs, so same seed values won't produce same sequences; seeds are for reproducibility, not matching
  - Compare results using statistical tests (e.g., Kolmogorov-Smirnov, correlation tests) to verify equivalent distributions
- **Watch tests fail** (Julia function doesn't exist yet or returns wrong results)
- Commit: "Add R parallel tests for [function_name] (RED phase)"\

**Step 5: Implement First Julia Version**

- Write initial Julia implementation in `src/[module].jl`
- Translate from R code, focusing on correctness over performance
- Ensure function signature matches Phase 0 audit specifications
- Make it pass both Julia unit tests and R parallel tests
- Verify outputs match reference values (deterministic) or are statistically equivalent (probabilistic)
- Commit: "Implement [function_name] - passes tests (GREEN phase)"

**Step 6: Benchmarking**

- Run benchmarks comparing:
  - Original R implementation
  - Julia implementation (via R interface)
  - Julia implementation (direct Julia call)
- Use Phase 0 audit benchmarks as baseline
- Document performance characteristics
- Commit: "Add benchmarks for [function_name]"

**Step 7: Refactor and Optimize**

- Optimize Julia implementation based on:
  - Phase 0 performance analysis
  - Benchmark results
  - Julia performance best practices
- Improve type stability
- Reduce allocations
- Add SIMD operations where applicable
- Ensure all tests still pass after optimization
- Re-run benchmarks to verify improvements
- Commit: "Optimize [function_name] (REFACTOR phase)"

**Step 8: Documentation**

- Add docstrings with examples
- Document any deviations from R implementation
- Update package documentation
- Commit: "Document [function_name]"

### TDD Principles

- **Always write tests first** - Tests define expected behavior
- **Watch tests fail** - Verifies test framework and expected behavior
- **Small commits** - Each step is a separate commit for clear history
- **Continuous validation** - Both Julia tests and R parallel tests must pass
- **Benchmark early** - Understand performance characteristics before optimization
- **Refactor safely** - All tests must pass after each optimization

### Test Data Management

- Create `test/data/` directory for test datasets
- Use standard ALDEx2 test datasets (e.g., selex dataset)
- Generate synthetic test data for edge cases
- Document test data sources and characteristics

See `TDD_Implementation_Phases.md` for detailed test specifications and implementation steps.

### Phase 0: R Package Deep Audit and Inspection (Weeks 1-2)

**Objective:** Conduct a comprehensive analysis of the original ALDEx2 R package to inform implementation strategy, identify optimization opportunities, and ensure complete feature parity.

# Week 1: ALDEx2 Package Structure and Test Coverage Analysis

## 1. Package Discovery and Inventory

**Objective:** Understand ALDEx2’s structure, dependencies, and functions.

### Tasks

- Locate the ALDEx2 R package repository (CRAN/GitHub)
- Map complete package structure:
  - `R/` – core R functions
  - `man/` – documentation
  - `tests/` – unit and integration tests
  - `vignettes/` – usage examples
  - `data/` – example datasets
  - `DESCRIPTION` & `NAMESPACE` – dependencies and exports
- Create a **function inventory**:
  - List all exported and internal functions
  - Document function signatures and dependencies
  - Record package dependencies with exact versions

### Function Signature Documentation

For each function:

- **Inputs:**
  - Parameter names and types (`matrix`, `data.frame`, `numeric`, `character`, `logical`)
  - Required vs. optional parameters
  - Default values
  - Constraints and validation rules
  - Dimensions for matrices/arrays:
    - Count matrices: rows = samples, columns = features
    - Vectors and arrays: lengths and dimensions
  - Data structure requirements (row/column names, metadata)
- **Outputs:**
  - Return type (`list`, `data.frame`, `matrix`, `ALDExObject`)
  - Output structure and organization
  - Dimensions and transformations
  - Field names and types for complex objects
  - Side effects (printed output, warnings, messages)
- **Documentation Table Columns:**
  - Function name
  - Input parameters (name, type, dimensions, constraints)
  - Output type, dimensions, structure
  - Example input/output with dimensions
  - Dependencies on other functions

### R Code Optimization Analysis

**Objective:** Identify sections of the ALDEx2 R package that are already optimized or use advanced techniques. This informs whether direct translation is sufficient or if Julia-specific refactoring is needed.

## Optimization Patterns to Look For

During the audit, flag code that shows signs of R-level optimization:

| Pattern                                             | Description                                                                                                  | Audit Action                                                                                                      |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| **Vectorized operations**                           | Use of `rowSums()`, `colSums()`, `apply()`, `vapply()` or matrix operations to avoid explicit loops          | Note potential Julia translation: loops may be faster than R-style vectorization; mark for performance validation |
| **Pre-allocation of vectors/matrices**              | Code that initializes vectors/matrices with fixed length before filling                                      | Flag as already optimized; Julia should also pre-allocate                                                         |
| **Use of specialized helpers / internal functions** | Calls to `.Internal()` functions or other optimized base R functions                                         | Document exact purpose; consider whether Julia equivalent exists or if a new Julia implementation is required     |
| **Avoidance of coercion**                           | Explicit type handling (`as.numeric()`, `as.matrix()`, `factor(levels=...)`) to prevent repeated conversions | Note for Julia translation: ensure type-stable constructors                                                       |
| **C-backed or compiled helpers**                    | Use of functions like `rowSums()`, `any(x==val)` which are backed by optimized C code                        | Document these hotspots; Julia may achieve similar or better performance via type-stable loops or SIMD            |
| **Efficient subsetting/replacement**                | Patterns like `x[is.na(x)] <- 0` implemented carefully to avoid unnecessary copies                           | Identify and note equivalent Julia broadcasting patterns                                                          |
| **Loop optimization**                               | Explicit loops that avoid object growth (`for (i in 1:n)`) or use `*apply()` alternatives efficiently        | Check if type-stable Julia loops can replace or improve upon these                                                |
| **Monte Carlo / random sampling optimizations**     | Use of vectorized Dirichlet or normal sampling (`rdirichlet()`, `rmvnorm()`)                                 | Document reproducibility, vectorization, and allocation patterns for translation to Julia/GPU                     |
| **Memory-efficient data handling**                  | Use of `data.table`, `matrix`, or other memory-light structures instead of `data.frame` where possible       | Note for Julia: ensure efficient array representation and consider `DataFrame` only if necessary                  |

## Audit Tasks

For each function:

1. Scan code for optimization patterns listed above.
2. Document each pattern found:
   - File and line numbers
   - Purpose of optimization
   - Whether it is essential for performance in Julia
3. Classify sections as:
   - **High priority for Julia optimization** – computationally expensive, not trivially translated
   - **Direct translation likely sufficient** – already efficient in R, likely good performance in Julia loops
   - **Candidate for GPU acceleration** – Monte Carlo sampling or feature-wise parallel computations
4. Note potential pitfalls for Julia translation:
   - R vectorization may translate into unnecessary allocations in Julia if not replaced with loops or views
   - Internal `.Internal()` calls may require custom Julia implementation

## Deliverables

\*\*Add these `AUDIT/<function_name>/optimizations.md` in the following format:

Example:

| Function      | File & Line                 | R Optimization Pattern                       | Purpose                   | Translation Recommendation                  | Notes                          |
| ------------- | --------------------------- | -------------------------------------------- | ------------------------- | ------------------------------------------- | ------------------------------ |
| iqlr_features | R/feature_selection.R:12-35 | Pre-allocated matrices, efficient subsetting | Reduce memory allocations | Translate directly, maintain pre-allocation | Ensure type stability in Julia |

- Include notes for Julia translation decisions, highlighting which R optimizations are already efficient and which require re-implementation or further optimization.

---

## 2. Test Coverage Analysis

**Objective:** Assess test completeness and identify gaps.

### Tasks

- Run the test suite and measure coverage using `covr` or `testthat`
- Document:
  - Coverage percentage per function
  - Functions with minimal/no coverage
  - Test types (unit, integration, edge cases)
  - Test quality and comprehensiveness
- Produce a **test coverage report** highlighting gaps

---

## 3. Function Categorization

**Objective:** Identify deterministic vs. probabilistic functions and reproducibility requirements.

### Probabilistic Functions

- Functions using random number generation:
  - `aldex_clr()` – Monte Carlo sampling
  - `rdirichlet()` – Random sampling
- Document:
  - Seed requirements
  - Variability and reproducibility constraints

### Deterministic Functions

- Functions producing fixed output for given input:
  - `aitchison_mean()` – mathematical operations
  - `iqlr_features()` – feature selection
  - Statistical tests on fixed inputs
- Note functions requiring statistical validation vs. exact matching

---

## 4. Benchmarking Infrastructure Audit

**Objective:** Identify performance bottlenecks and create a reproducible benchmarking framework.

### Profiling Existing Code

- Use `Rprof()` and `profvis` to locate slow code
- Visualize execution time and memory usage
- Highlight stochastic functions with variable runtimes

### Microbenchmarking

- Use `microbenchmark` or `bench` packages
- Test realistic input sizes (samples × features, metadata)
- Collect median, mean, min/max, and interquartile runtime

### Performance Metrics

- Execution time (seconds per function call)
- Memory allocation (bytes)
- Scalability with number of samples/features
- Reproducibility for stochastic functions

### Best Practices (from Advanced R)

- Optimize bottlenecks, not trivial code
- Benchmark realistic input sizes
- Compare alternative implementations
- Repeat benchmarks multiple times
- Consider trade-offs: speed vs. readability/maintainability

### Documentation and Reporting

- Record profiling and benchmarking results for each function
- Highlight deterministic vs. stochastic functions
- Provide optimization recommendations:
  - Vectorization
  - Pre-allocation
  - Efficient data structures
  - Parallelization (e.g., Monte Carlo sampling)

---

## 5. AUDIT Folder Structure for Function-Level Analysis

**Objective:** Organize audit information for each R function in a dedicated folder with reproducible profiling.

### Tasks

- Create an `AUDIT/` folder in the project root
- For each function in ALDEx2:
  - Create a subfolder: `AUDIT/<function_name>/`
  - Store audit documents:
    - `signature.md` – input/output specifications
    - `tests.md` – test coverage analysis
    - `benchmarks.md` – profiling and microbenchmark results
    - `notes.md` – observations, reproducibility, optimization suggestions
    - `profile.R` – **profiling and benchmarking code**, example template:
    - `optimizations.md` - Notes on potential optimizations found in R source code

**Week 2: Computational Analysis and Parallelization Opportunities**

1. **Computational Cost Analysis**

   - Profile each function using `profvis`, `Rprof`, or `microbenchmark`
   - Measure execution time for typical datasets (small, medium, large)
   - Identify hot paths and bottlenecks
   - Measure memory usage and allocations
   - Create performance profile report ranking functions by computational cost
   - Document scaling behavior (time complexity analysis)

2. **Parallelization and Distributed Computing Analysis**

   - **Monte Carlo Sampling Analysis:**

     - Analyze `aldex_clr()` Monte Carlo iterations
     - Determine if iterations are independent (embarrassingly parallel)
     - Measure overhead vs. computation ratio
     - Identify optimal chunk sizes for parallelization

   - **Feature-Level Parallelization:**

     - Identify functions that operate independently on features
     - Statistical tests (t-test, Wilcoxon) per feature
     - Effect size calculations per feature
     - Correlation analysis per feature pair

   - **Sample-Level Parallelization:**

     - Identify operations that can parallelize across samples
     - CLR transformations
     - Data preprocessing steps

   - **Distributed Computing Opportunities:**
     - Functions suitable for multi-core CPU parallelization
     - Functions suitable for GPU acceleration
     - Functions suitable for distributed computing (multi-node)
     - Memory requirements for each parallelization strategy
     - Communication overhead analysis

3. **Data Flow and Dependency Analysis**

   - Map data flow through main workflows
   - Identify data transformation steps
   - Document intermediate data structures and sizes
   - Identify opportunities for in-place operations
   - Analyze memory access patterns

4. **Algorithm Complexity Analysis**

   - Document time complexity (Big-O) for each function
   - Document space complexity
   - Identify algorithms that could be optimized
   - Compare with alternative algorithms where applicable

**Deliverables from Phase 0:**

1. **R Package Audit Report** (`R_Package_Audit_Report.md`)

   - Complete function inventory with detailed signatures
   - Exact input/output specifications for each function:
     - Data types for all parameters and return values
     - Mathematical dimensions (rows, columns, array shapes) for all array/matrix inputs and outputs
     - Parameter constraints and validation rules
     - Example input/output pairs with actual dimensions
   - Test coverage report with gaps
   - Function categorization (probabilistic vs. deterministic)
   - Benchmarking results and framework

2. **Performance Analysis Report** (`Performance_Analysis_Report.md`)

   - Computational cost ranking
   - Hot path identification
   - Memory usage profiles
   - Scaling behavior documentation

3. **Parallelization Strategy Document** (`Parallelization_Strategy.md`)

   - Parallelization opportunities by function
   - Recommended parallelization approach per function
   - GPU acceleration candidates
   - Distributed computing candidates
   - Expected speedup estimates

4. **Test Specification Document** (`R_Test_Specifications.md`)

   - Test cases extracted from R package
   - Expected outputs for deterministic functions
   - Statistical validation criteria for probabilistic functions
   - Edge cases identified from R tests

5. **Implementation Priority Matrix**

   - Functions ranked by: computational cost, test coverage, parallelization potential
   - Recommended implementation order
   - Risk assessment for each function

**Tools and Methods:**

- **R Package Analysis:**

  - `devtools::load_all()` - Load package for inspection
  - `ls("package:ALDEx2")` - List all exported functions
  - `getNamespaceExports("ALDEx2")` - Get all exports
  - `codetools::findGlobals()` - Find dependencies
  - `args(function_name)` - Get function signature
  - `formals(function_name)` - Get formal arguments and defaults
  - `body(function_name)` - Inspect function body
  - `help(function_name)` or `?function_name` - Access documentation
  - Manual inspection of `.Rd` files in `man/` directory for complete documentation

- **Function Signature and Dimension Extraction:**

  - Create test scripts that call each function with known inputs
  - Use `str()` to inspect object structure and dimensions
  - Use `dim()`, `nrow()`, `ncol()`, `length()` to document dimensions
  - Use `class()`, `typeof()`, `is.matrix()`, `is.data.frame()` to document types
  - Use `attributes()` to inspect metadata (row names, column names, etc.)
  - Run example code from vignettes and documentation to capture real input/output pairs
  - Use `trace()` or `browser()` to inspect intermediate values
  - Document dimension transformations by comparing input and output dimensions

- **Test Coverage:**

  - `covr::package_coverage()` - Measure test coverage
  - `testthat::test_dir()` - Run test suite
  - Manual review of `tests/testthat/` directory

- **Profiling:**

  - `profvis::profvis()` - Interactive profiling
  - `Rprof()` - Statistical profiling
  - `microbenchmark::microbenchmark()` - Function benchmarking
  - `bench::mark()` - Comprehensive benchmarking

- **Parallelization Analysis:**
  - `parallel::detectCores()` - System capabilities
  - Manual code review for independence
  - Dependency graph analysis

**Success Criteria for Phase 0:**

- [ ] Complete function inventory with 100% coverage, including exact input/output specifications with data types and mathematical dimensions
- [ ] Test coverage report showing coverage percentage per function
- [ ] All functions categorized as probabilistic or deterministic
- [ ] Performance profiles for all major functions
- [ ] Parallelization strategy document with specific recommendations
- [ ] Test specifications extracted from R package
- [ ] Implementation priority matrix created
- [ ] All deliverables documented and reviewed

## Phase 0.5: DifferentialEquations.jl / GPU / R Interface Audit

### 10.1 diffeqr: R ↔ Julia Interface

**Objective:** Understand how `diffeqr` provides seamless R ↔ Julia interoperability for DifferentialEquations.jl and DiffEqGPU.jl.

#### Tasks

- Review `diffeqr` source code:

  - How `JuliaCall` enables R ↔ Julia function calls
  - Development-mode loading and hot-reloading patterns
  - Type conversions:

    - R `data.frame` → Julia `Array` or `DataFrame`
    - R numeric vectors → `Array{Float64}`
    - R lists → Julia tuples or NamedTuples

- Examine utilities for side-by-side testing of R vs. Julia outputs
- Identify support for deterministic vs. stochastic DEs
- Document lessons for ALDEx2.jl:

  - Development-mode loading & hot-reloading patterns
  - Type-safe conversions and dimension checks
  - Parallel testing framework for deterministic/stochastic functions
  - Statistical validation approaches for Monte Carlo/stochastic workflows

---

### 10.2 DifferentialEquations.jl: Core Julia DEs

**Objective:** Extract design and testing patterns for high-performance differential equation solvers in Julia.

#### Tasks

- Review solver API patterns, type stability, and composable integrators
- Examine deterministic and stochastic DE workflows
- Identify testing & benchmarking strategies:

  - Deterministic solution validation
  - Reproducibility checks for stochastic solvers
  - Parameter sweeps / Monte Carlo simulations

- Document lessons for ALDEx2.jl:

  - Composable function & solver architecture
  - Deterministic vs. stochastic workflow handling
  - Efficient validation strategies

---

### 10.3 DiffEqGPU.jl / GPUArrays.jl: GPU Acceleration

**Objective:** Identify patterns for writing portable, performant GPU kernels in Julia.

#### Tasks

- Review `DiffEqGPU.jl` and dependencies (`KernelAbstractions.jl`, `GPUArrays.jl`):

  - Backend-agnostic support: CUDA, AMDGPU, Metal, oneAPI, OpenCL
  - Portable kernel design patterns
  - Pre-allocation of buffers and per-thread RNGs

- Identify kernel-level best practices:

  - Grid-stride loops for variable input sizes
  - Input/output separation: write to pre-allocated buffers
  - Use `@inbounds` and `@simd` for safe performance optimization
  - Shared memory reductions, minimal atomics

- Document lessons for ALDEx2GPU.jl:

  - Portable kernels via `KernelAbstractions.jl`
  - Fuse small kernels to reduce launch overhead
  - Validation against CPU Julia implementation
  - CPU fallback support

---

### 10.4 GPU Testing & Performance Validation

**Objective:** Extract strategies for robust multi-backend GPU testing.

#### Tasks

- Examine test patterns:

  - Start with single block / single thread for correctness
  - Incrementally scale to full dataset and multi-threaded execution
  - Compare GPU vs. CPU results
  - Multi-backend GPU testing (CUDA, AMD, etc.)

- Document recommended testing & benchmarking strategy:

  - GPU kernel correctness validation
  - Reproducible stochastic GPU computations
  - Incremental scaling approach

---

### 10.5 AUDIT Folder Structure for Julia Package Analysis

**Objective:** Organize audit artifacts by package and kernel.

```graphql
AUDIT_JULIA/
├─ diffeqr/
│  ├─ R_Interface.md          # JuliaCall integration, type conversions
│  ├─ Testing.md              # R ↔ Julia testing, stochastic validation
│  └─ Lessons_ALDEx2.md       # Actionable takeaways for ALDEx2.jl
│
├─ DifferentialEquations/
│  ├─ Solver_Design.md        # Composable DE solvers, deterministic/stochastic patterns
│  ├─ Testing.md              # Validation & reproducibility patterns
│  └─ Lessons_ALDEx2.md       # Actionable takeaways for ALDEx2.jl
│
├─ DiffEqGPU/
│  ├─ Kernel_Design.md        # Portable kernel patterns, buffer management
│  ├─ Performance.md          # Benchmarking & multi-backend testing
│  └─ Lessons_ALDEx2GPU.md    # Actionable takeaways for ALDEx2GPU.jl
```

#### Documentation Template per Package

- **Objective / Focus Area**
- **Implementation Patterns Observed**
- **Testing & Validation Practices**
- **Performance / Benchmarking Notes**
- **Direct Lessons for ALDEx2.jl / ALDEx2GPU.jl**
- **Open Questions / Gaps**

### Phase 1: R Interface for Parallel Testing (Weeks 3-4)

**Objective:** Implement the R interface infrastructure to enable loading and testing Julia functions alongside the original R ALDEx2 package, allowing for parallel validation during development.

**Week 3: R Interface Infrastructure**

- Set up ALDEx2_jl_R package structure (enhance existing if present)
- Implement Julia setup function using JuliaCall (similar to `diffeqr` pattern)
  - Initialize Julia environment
  - Load ALDEx2.jl package (even if functions are incomplete)
  - Set up Julia package development mode loading
- Implement data conversion utilities:
  - R matrix/data.frame → Julia Array/DataFrame
  - Julia results → R-friendly formats (data.frame, list, etc.)
  - Handle dimension preservation and metadata
- Implement basic error handling and validation
- Create test infrastructure for parallel R/Julia function calls

**Week 4: Testing Framework and Validation Tools**

- Implement parallel testing utilities:
  - Function to call both R and Julia versions with same inputs
  - Comparison utilities for outputs (exact matching for deterministic, statistical for probabilistic)
  - Side-by-side result visualization/validation
- Create validation scripts for:
  - Input/output dimension checking
  - Data type validation
  - Result equivalence testing
- Set up development workflow:
  - Load Julia package in development mode from R
  - Hot-reload Julia functions during development
  - Run R and Julia functions in same session for comparison
- Document R interface usage for development and testing
- Create example scripts demonstrating parallel testing workflow

**Key Deliverables:**

- Functional R interface allowing Julia package loading in development mode
- Parallel testing framework for R vs. Julia function comparison
- Validation utilities for ensuring equivalent outputs
- Documentation for using R interface during development

**Success Criteria:**

- [ ] Can load ALDEx2.jl package in development mode from R session
- [ ] Can call Julia functions (even if stubs) from R
- [ ] Data conversion utilities handle all required data types and dimensions
- [ ] Parallel testing framework functional
- [ ] Can run R and Julia versions side-by-side with same inputs

### Phase 2: Core ALDEx2.jl Package Foundation (Weeks 5-8)

**Implementation Approach:** Each function follows the detailed TDD workflow (Section 4) with all 8 steps.

**Week 5-6: Foundation**

- Set up ALDEx2.jl package structure with PkgTemplates.jl
- Implement core types (`ALDExCLR`, `ALDExResults`, etc.) based on audit findings
- Create CI/CD pipeline
- Set up test data directory (`test/data/`)

**For each function (`rdirichlet`, `aitchison_mean`, etc.), follow TDD workflow:**

1. **Function Classification:** Determine deterministic vs. probabilistic (from Phase 0)
2. **Generate Reference Values:** Write R script to generate reference outputs from test data
3. **Write Julia Tests:** Create `test/test_[function_name].jl` with appropriate test type
4. **Write R Parallel Tests:** Create `tests/testthat/test-[function_name].R` comparing R vs. Julia
5. **Implement First Version:** Translate to Julia, make tests pass
6. **Benchmark:** Compare R, Julia (via R interface), and Julia (direct) performance
7. **Refactor & Optimize:** Improve performance while maintaining correctness
8. **Document:** Add docstrings and examples

**Functions to implement:**

- `rdirichlet()` - Probabilistic (use statistical equivalence tests)
- `aitchison_mean()` - Deterministic (use strict equality tests)

**Week 7-8: Core Algorithms**

**For each function (`aldex_clr`, IQLR feature selection, zero handling, `aldex_ttest`), follow TDD workflow:**

- Follow all 8 TDD steps for each function
- `aldex_clr()` - Probabilistic (Monte Carlo sampling, use statistical equivalence)
- Feature selection functions - Deterministic (use strict equality)
- `aldex_ttest()` - Deterministic (statistical test results, use strict equality for p-values)

**Key Activities:**

- Implement with Monte Carlo sampling (using parallelization strategy from Phase 0)
- Continuously validate using R parallel tests from Phase 1
- Benchmark after initial implementation
- Optimize based on Phase 0 profiling results and benchmark results
- Ensure all tests pass after each optimization

### Phase 3: Advanced Features (Weeks 9-10)

**Implementation Approach:** Each function follows the detailed TDD workflow (Section 4) with all 8 steps.

**Week 9:**

**For each function (`aldex_glm`, `aldex_effect`, `aldex_corr`), follow TDD workflow:**

- Follow all 8 TDD steps for each function
- `aldex_glm()` - Deterministic (GLM results, use strict equality for coefficients and p-values)
- `aldex_effect()` - Deterministic (effect size calculations, use strict equality)
- `aldex_corr()` - Deterministic (correlation coefficients, use strict equality)

**Key Activities:**

- Generate reference values for each function
- Write Julia tests (strict equality for all)
- Write R parallel tests comparing R vs. Julia
- Implement first version, make all tests pass
- Benchmark all implementations
- Refactor and optimize

**Week 10:**

**For `aldex()` wrapper function, follow TDD workflow:**

- Follow all 8 TDD steps
- `aldex()` - Deterministic wrapper (orchestrates other functions)
- **End-to-end validation:** Test complete workflow
  - Generate reference values for full pipeline
  - Write Julia integration tests
  - Write R parallel tests for complete workflow
  - Validate all intermediate steps
  - Compare complete outputs
- Comprehensive testing and validation
- Documentation and examples
- Performance profiling and optimization
- Validate against Phase 0 performance targets

### Phase 4: GPU Package (Weeks 11-14)

**Implementation Guidelines:** Follow all GPU implementation guidelines from Section 2.4 during kernel development. Key principles:

- Start with small inputs and 1 block/1 thread for initial testing
- Use Float32 for performance unless precision requires Float64
- Guard memory access, then optimize with @inbounds after validation
- Use grid-stride loops for variable-sized inputs
- Minimize atomics; prefer shared memory reductions
- Pre-allocate RNG per thread with proper indexing
- Keep kernels minimal; move complex logic to host
- Always compare GPU results to CPU implementation (validated against R)

**Week 11-12: GPU Infrastructure**

- Set up ALDEx2GPU.jl package structure
- Implement KernelAbstractions kernels for operations identified in Phase 0 parallelization analysis
  - Follow kernel design guidelines (Section 2.4.1): bounds checking, grid-stride loops, output buffers
  - Use appropriate block sizes (128-512 threads, multiple of 32)
  - Configure grid sizes (2×-4× number of SMs)
- Set up extension system for GPU backends
- Implement GPU-accelerated Dirichlet sampling (high priority from Phase 0)
  - Pre-allocate RNG per thread with proper state indexing
  - Use Float32 for performance
  - Test with small inputs first (1 block, 1 thread)
- **Parallel Testing:** Validate GPU implementations against CPU versions (which are already validated against R)
  - Use compute-sanitizer and cuda-gdb for debugging
  - Compare results using CPU implementation as ground truth

**Week 13-14: GPU Algorithms**

- Implement GPU-accelerated CLR transformation (identified as high-value in Phase 0)
  - Use coalesced memory access patterns
  - Consider fusing with subsequent operations to reduce kernel launch overhead
  - Optimize shared memory usage if applicable
- Implement GPU statistical tests (feature-level parallelization from Phase 0)
  - Parallel computation across features (independent per feature)
  - Use appropriate reduction patterns (shared memory + atomic per block)
- Implement GPU effect size calculations
  - Vectorized operations with proper memory coalescing
- **Parallel Testing:** Validate GPU results against CPU Julia and R implementations
  - Test with small inputs, then scale up
  - Use assert checks during development
  - Remove/conditionally compile asserts for production
- Testing and validation on multiple GPU backends
  - CUDA, AMDGPU, Metal, oneAPI, OpenCL
  - Validate consistent results across backends
- Performance validation against Phase 0 benchmarks
  - Measure speedup vs. CPU implementation
  - Profile memory usage and kernel execution times
- Update R interface to support GPU backend selection

## 5. Performance Targets

### CPU Performance

- Target: 2-5x faster than R implementation for typical datasets
- Memory: Similar or lower memory usage
- Scalability: Handle datasets with 10,000+ features efficiently

### GPU Performance

- Target: 10-50x speedup for large datasets (depending on GPU)
- Memory: Efficient GPU memory usage
- Scalability: Handle datasets with 100,000+ features

## 6. Testing Strategy

**Note:** Test specifications will be extracted from R package during Phase 0 audit. The R interface (Phase 1) enables parallel testing throughout development. All functions follow the detailed TDD workflow (Section 4) with 8 steps including both Julia unit tests and R parallel tests.

### TDD Workflow Integration

Each function follows the 8-step TDD process:

1. Function classification (deterministic vs. probabilistic)
2. Generate reference values (R script)
3. Write Julia unit tests (watch them fail)
4. Write R parallel tests (watch them fail)
5. Implement Julia function (make all tests pass)
6. Benchmark (R, Julia via R interface, Julia direct)
7. Refactor and optimize
8. Document

### Parallel Testing (Primary Validation Method)

- **Real-time Validation:** Use R interface from Phase 1 to test Julia functions alongside R implementation during development
- **Same Input Testing:** Run R and Julia versions with identical inputs in the same R session
- **Output Comparison:**
  - Exact matching for deterministic functions
  - Statistical validation for probabilistic functions (using Phase 0 criteria)
- **Continuous Integration:** Validate each function as it's implemented (Step 5 of TDD workflow)
- **Workflow Validation:** Test complete workflows end-to-end in parallel

### Unit Tests

- **Julia Unit Tests:** Written in Step 3 of TDD workflow (`test/test_[function_name].jl`)
  - Strict equality for deterministic functions
  - Statistical equivalence for probabilistic functions
- **R Parallel Tests:** Written in Step 4 of TDD workflow (`tests/testthat/test-[function_name].R`)
  - Compare original R package vs. Julia package (via R interface)
  - Use helper functions from `helper-parallel_test.R` and `helper-validation.R`
- Use test cases extracted from R package in Phase 0
- Test edge cases identified in Phase 0 (zero counts, single samples, etc.)
- Ensure test coverage matches or exceeds R package coverage (from Phase 0 report)

### Integration Tests

- End-to-end workflows tested in parallel (R vs. Julia)
- Real dataset validation (selex dataset) with side-by-side comparison
- Cross-platform testing
- Validate against R package test suite results from Phase 0
- Use Phase 1 R interface for automated parallel testing

### Performance Tests

- Benchmark against R implementation using Phase 0 benchmarks
- Validate performance targets from Phase 0 analysis
- Memory profiling
- GPU performance validation
  - Follow GPU testing guidelines (Section 2.4.7): start with small inputs, 1 block/1 thread
  - Compare GPU results to CPU implementation (validated against R)
  - Use compute-sanitizer and cuda-gdb for debugging
  - Profile kernel execution times and memory usage
- Compare with Phase 0 performance profiles
- Use parallel testing framework to ensure performance gains don't compromise correctness

### GPU Kernel Tests

- **Incremental Testing:** Test kernels with small inputs and minimal configuration (1 block, 1 thread) before scaling up
- **CPU Comparison:** Always compare GPU kernel results to CPU implementation (which is validated against R)
- **Debugging Tools:** Use compute-sanitizer and cuda-gdb to catch GPU-specific errors
- **Assert Checks:** Include assert sanity checks during development; remove or conditionally compile for production
- **Multi-Backend Validation:** Test on multiple GPU backends (CUDA, AMDGPU, Metal, oneAPI, OpenCL) to ensure portability
- **Memory Validation:** Verify proper memory access patterns (coalesced access, no out-of-bounds)
- **RNG Validation:** For probabilistic functions, ensure RNG per thread produces statistically equivalent results

## 7. Documentation

- Comprehensive API documentation
- Performance benchmarks and comparisons
- Migration guide from R
- GPU setup and usage guide
- Examples and tutorials

## 8. Key Files to Create/Modify

### ALDEx2.jl

- `src/ALDEx2.jl` - Main module
- `src/types.jl` - Type definitions
- `src/distributions.jl` - Dirichlet functions
- `src/clr.jl` - CLR transformation
- `src/statistical_tests.jl` - Statistical tests
- `test/test_*.jl` - Julia unit tests (Step 3 of TDD workflow)
- `test/data/` - Test datasets and reference values (Step 2 of TDD workflow)
- `Project.toml` - Dependencies

### ALDEx2GPU.jl

- `src/ALDEx2GPU.jl` - Main module
- `src/gpu_clr.jl` - GPU CLR
- `src/kernels/clr_kernels.jl` - GPU kernels
- `ext/CUDAExt.jl` - CUDA extension
- `Project.toml` - Dependencies with extensions

### ALDEx2_jl_R

- `R/aldex2jl_setup.R` - Enhance existing with development mode support
- `R/aldex2jl.R` - Main wrapper functions
- `tests/testthat/helper-parallel_test.R` - Parallel testing utilities (call R and Julia versions side-by-side, auto-sourced by testthat)
- `tests/testthat/helper-validation.R` - Output comparison and validation utilities (auto-sourced by testthat)
- `tests/testthat/test-*.R` - R parallel tests (Step 4 of TDD workflow)
- `tests/reference_values/` - R scripts to generate reference values (Step 2 of TDD workflow)
- `DESCRIPTION` - Package metadata

## 9. Success Criteria

- [ ] Phase 0 audit completed with all deliverables (R Package Audit Report, Performance Analysis Report, Parallelization Strategy Document, Test Specification Document, Implementation Priority Matrix)
- [ ] Phase 1 R interface functional and enabling parallel testing (can load Julia package in development mode, call functions from R, compare outputs)
- [ ] All core ALDEx2 functions implemented based on Phase 0 function inventory
- [ ] All functions validated using parallel testing framework (R vs. Julia) during development
- [ ] Test coverage > 90% (validated against Phase 0 test coverage report)
- [ ] CPU performance faster than R (validated against Phase 0 benchmarks)
- [ ] GPU package functional on at least 2 GPU backends (targeting functions identified in Phase 0 parallelization analysis)
- [ ] R interface fully functional with complete function wrappers
- [ ] Documentation complete
- [ ] Validated against R implementation with real data using parallel testing
- [ ] Performance targets met for computationally expensive functions identified in Phase 0
- [ ] Parallelization strategies implemented as recommended in Phase 0 audit
- [ ] All probabilistic functions validated using statistical criteria from Phase 0 (via parallel testing)
- [ ] All deterministic functions match R outputs exactly (validated using Phase 0 test specifications and parallel testing)