<!-- 8b669c62-b50e-4a14-a7ca-f2fd3f57b0bd 0f4ec7e9-a692-49b7-87dd-bd4100152910 -->
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

**Week 1: Package Structure and Test Coverage Analysis**

1. **Package Discovery and Inventory**

   - Locate the ALDEx2 R package repository
   - Map complete package structure (R/, man/, tests/, vignettes/, etc.)
   - Create comprehensive function inventory with signatures and dependencies
   - Document all exported and internal functions
   - Identify all dependencies and their versions

**Function Signature Documentation:**

   - For each function, document exact input specifications:
     - Parameter names and types (e.g., `matrix`, `data.frame`, `numeric`, `character`, `logical`)
     - Required vs. optional parameters
     - Default values for optional parameters
     - Parameter constraints and validation rules
     - Mathematical dimensions for array/matrix inputs:
       - Number of rows (samples) and columns (features) for count matrices
       - Vector lengths
       - Array dimensions (for multi-dimensional inputs)
     - Data structure requirements (e.g., row names, column names, metadata)

   - For each function, document exact output specifications:
     - Return type (e.g., `list`, `data.frame`, `matrix`, `numeric`, `ALDExObject`)
     - Output structure and organization
     - Mathematical dimensions of output arrays/matrices:
       - Number of rows and columns
       - Relationship between input and output dimensions
       - Dimension transformations (e.g., feature reduction, sample aggregation)
     - Field names and data types within complex return objects
     - Side effects (e.g., printed output, warnings, messages)

   - Create function signature documentation table with:
     - Function name
     - Input parameters (name, type, dimensions, constraints)
     - Output (type, dimensions, structure)
     - Example input/output pairs with actual dimensions
     - Dependencies on other functions

2. **Test Coverage Analysis**

   - Run test suite and measure coverage using `covr` or `testthat` coverage tools
   - Document test coverage percentage per function
   - Identify functions with no or minimal test coverage
   - Analyze test types (unit, integration, edge cases)
   - Review test quality and comprehensiveness
   - Create test coverage report with gaps identified

3. **Function Categorization**

   - **Probabilistic Functions:** Identify functions using random number generation
     - `aldex_clr()` - Monte Carlo sampling
     - `rdirichlet()` - Random sampling
     - Any functions with stochastic components
   - **Deterministic Functions:** Identify functions with fixed outputs for given inputs
     - `aitchison_mean()` - Mathematical operations
     - `iqlr_features()` - Feature selection logic
     - Statistical test calculations (given fixed inputs)
   - Document seed requirements and reproducibility constraints
   - Identify functions requiring statistical validation vs. exact matching

4. **Benchmarking Infrastructure Audit**

   - Check for existing benchmarking tools (microbenchmark, rbenchmark, etc.)
   - Identify if package has performance tests or benchmarks
   - Review vignettes for performance examples
   - Document current performance characteristics if available
   - Create benchmarking framework if missing

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

**Week 11-12: GPU Infrastructure**

- Set up ALDEx2GPU.jl package structure
- Implement KernelAbstractions kernels for operations identified in Phase 0 parallelization analysis
- Set up extension system for GPU backends
- Implement GPU-accelerated Dirichlet sampling (high priority from Phase 0)
- **Parallel Testing:** Validate GPU implementations against CPU versions (which are already validated against R)

**Week 13-14: GPU Algorithms**

- Implement GPU-accelerated CLR transformation (identified as high-value in Phase 0)
- Implement GPU statistical tests (feature-level parallelization from Phase 0)
- Implement GPU effect size calculations
- **Parallel Testing:** Validate GPU results against CPU Julia and R implementations
- Testing and validation on multiple GPU backends
- Performance validation against Phase 0 benchmarks
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
- Compare with Phase 0 performance profiles
- Use parallel testing framework to ensure performance gains don't compromise correctness

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

### To-dos

- [ ] Create comprehensive function inventory with signatures, dependencies, and exact input/output specifications (data types and mathematical dimensions)
- [ ] Run test coverage analysis using covr/testthat and document coverage per function
- [ ] Categorize all functions as probabilistic vs. deterministic
- [ ] Identify and document existing benchmarking tools in R package
- [ ] Profile all functions using profvis/Rprof/microbenchmark
- [ ] Create performance profile report ranking functions by computational cost
- [ ] Analyze parallelization opportunities (Monte Carlo, feature-level, sample-level)
- [ ] Identify GPU acceleration candidates and distributed computing opportunities
- [ ] Create R Package Audit Report with all findings
- [ ] Create Performance Analysis Report with hot paths and scaling behavior
- [ ] Create Parallelization Strategy Document with specific recommendations
- [ ] Extract test specifications from R package tests
- [ ] Create Implementation Priority Matrix based on audit findings
- [ ] Set up ALDEx2_jl_R package structure (enhance existing if present)
- [ ] Implement Julia setup function using JuliaCall with development mode support
- [ ] Implement data conversion utilities (R ↔ Julia)
- [ ] Implement parallel testing utilities (call R and Julia versions side-by-side)
- [ ] Implement validation utilities (output comparison, equivalence testing)
- [ ] Create validation scripts for dimension and data type checking
- [ ] Set up development workflow with hot-reload capability
- [ ] Document R interface usage for development and testing
- [ ] Create example scripts demonstrating parallel testing workflow
- [ ] Set up ALDEx2.jl package structure with PkgTemplates.jl, Project.toml, and basic module structure
- [ ] Implement core types (ALDExCLR, ALDExResults, ALDExEffect) in src/types.jl
- [ ] Create CI/CD pipeline
- [ ] Set up test data directory (test/data/)
- [ ] Step 1: Classify function as deterministic or probabilistic
- [ ] Step 2: Write R script to generate reference values from test data
- [ ] Step 3: Write Julia unit tests (test/test_[function_name].jl) - watch tests fail
- [ ] Step 4: Write R parallel tests (tests/testthat/test-[function_name].R) - watch tests fail
- [ ] Step 5: Implement first Julia version - make all tests pass
- [ ] Step 6: Run benchmarks (R, Julia via R interface, Julia direct)
- [ ] Step 7: Refactor and optimize Julia function - ensure tests still pass
- [ ] Step 8: Add documentation and examples
- [ ] Step 1: Classify function as deterministic or probabilistic
- [ ] Step 2: Write R script to generate reference values from test data
- [ ] Step 3: Write Julia unit tests (test/test_[function_name].jl) - watch tests fail
- [ ] Step 4: Write R parallel tests (tests/testthat/test-[function_name].R) - watch tests fail
- [ ] Step 5: Implement first Julia version - make all tests pass
- [ ] Step 6: Run benchmarks (R, Julia via R interface, Julia direct)
- [ ] Step 7: Refactor and optimize Julia function - ensure tests still pass
- [ ] Step 8: Add documentation and examples
- [ ] End-to-end validation of complete aldex() workflow
- [ ] Set up ALDEx2GPU.jl package structure with extension system for GPU backends
- [ ] Implement GPU kernels for CLR transformation and Dirichlet sampling using KernelAbstractions.jl
- [ ] Implement GPU-accelerated versions of core functions (aldex_clr, aldex_ttest, etc.)
- [ ] Validate GPU implementations against CPU versions (which are validated against R)
- [ ] Testing and validation on multiple GPU backends
- [ ] Update R interface to support GPU backend selection
- [ ] Create comprehensive test suite with unit tests, integration tests, and performance benchmarks
- [ ] All functions validated using parallel testing framework (R vs. Julia)
- [ ] End-to-end workflow validation with real datasets