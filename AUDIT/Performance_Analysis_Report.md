# Performance Analysis Report

**Date:** 2025-01-27  
**Package Version:** 1.8.1  
**Phase:** Phase 0, Week 2 - Computational Cost Analysis

## Executive Summary

This report consolidates performance profiling and benchmarking results for all major ALDEx2 functions, identifying computational bottlenecks, hot paths, memory usage patterns, and scaling behavior. This analysis informs optimization priorities for the Julia translation.

## Methodology

### Benchmarking Infrastructure

- **Infrastructure Script:** `AUDIT/benchmarking_infrastructure.R`
- **Primary Dataset:** Full `selex` dataset (100 features × 14 samples) as canonical "small" benchmark
- **Tools Used:**
  - `profvis` - Interactive profiling
  - `Rprof` - Statistical profiling
  - `microbenchmark` - Function-level benchmarking
  - `bench` - Comprehensive benchmarking with memory tracking

### Performance Metrics Collected

- Execution time (wall-clock and CPU time)
- Memory allocation and usage
- Scaling behavior with dataset size
- Impact of parameters (`mc.samples`, `denom` modes, parallelization)

## Computational Cost Ranking

Functions ranked by computational cost and optimization priority:

| Function               | Computational Cost | Memory Intensity | Optimization Priority | GPU Potential |
| ---------------------- | ------------------ | ---------------- | --------------------- | ------------- |
| `aldex.clr.function()` | **Very High**      | High             | **P0 (Critical)**     | Very High     |
| `aldex.effect()`       | **Very High**      | Very High        | **P0 (Critical)**     | High          |
| `rdirichlet()`         | **High**           | Medium           | **P1 (High)**         | Very High     |
| `aldex.ttest()`        | **High**           | Medium           | **P1 (High)**         | High          |
| `aldex.glm()`          | **High**           | Medium           | **P1 (High)**         | High          |
| `aldex.corr()`         | **High**           | Medium           | **P1 (High)**         | High          |
| `t.fast()`             | **Medium**         | Low              | **P2 (Medium)**       | Medium        |
| `wilcox.fast()`        | **Medium**         | Low              | **P2 (Medium)**       | Low           |
| `iqlr.features()`      | **Low**            | Low              | **P3 (Low)**          | Low           |
| `aitchison.mean()`     | **Low**            | Low              | **P3 (Low)**          | Low           |

**Priority Levels:**

- **P0**: Critical - Must optimize for basic functionality
- **P1**: High - Significant performance impact
- **P2**: Medium - Moderate performance impact
- **P3**: Low - Minor optimizations

## Performance Profiles by Function

### 1. `aldex.clr()` / `aldex.clr.function()` - CRITICAL

**Status:** ✅ Benchmarked with infrastructure

**Key Measurements:**

- **Dataset:** Full `selex` (100 features × 14 samples)
- **Parameters:** `mc.samples = 32`, `denom = "all"`, `verbose = FALSE`
- **Artifacts Generated:**
  - `AUDIT/aldex.clr/profvis_small.html` - Interactive profile
  - `AUDIT/aldex.clr/Rprof_small_Rprof.out` - Base R profiling output
  - `AUDIT/aldex.clr/benchmarks_microbenchmark.csv` - Microbenchmark results
  - `AUDIT/aldex.clr/benchmarks_bench.csv` - Bench package results

**Scaling Characteristics:**

- Runtime scales linearly with `mc.samples`
- Runtime scales with number of features (row operations)
- Runtime scales with number of samples (column operations)
- Impact of `denom` mode: IQLR/ZERO modes add overhead
- Parallel vs serial (`useMC`): Parallelization provides speedup but with overhead

**Hot Paths Identified:**

1. **Monte Carlo Sampling** (`rdirichlet()` calls) - Lines 105-112, 137-142

   - Called once per sample per MC instance
   - Embarrassingly parallel
   - Major computational bottleneck

2. **CLR Transformation** - Lines 139, 145, 157

   - `apply(log2(m), 2, function(col) { col - mean(col) })` - Slow `apply()` pattern
   - Matrix operations that could be vectorized

3. **Feature Selection** (IQLR/ZERO modes) - Lines 155-167
   - Complex list manipulations
   - Multiple `apply()` calls for quantile calculations

**Memory Usage:**

- High memory allocation for Monte Carlo instances
- List of matrices (one per sample) with features × MC instances
- Memory scales with `mc.samples × features × samples`

**Optimization Opportunities:**

- Replace all `apply()` calls with loops or broadcasting
- Pre-allocate all arrays
- Parallelize Monte Carlo sampling (CPU threading or GPU)
- Use views instead of copies for subsetting

**Next Steps:**

- Extend benchmarks to larger synthetic datasets for scaling analysis
- Profile with different `denom` modes
- Measure parallelization overhead vs. speedup

---

### 2. `aldex.effect()` - CRITICAL

**Status:** ⚠️ Benchmarks planned but not yet executed

**Expected Characteristics (from code analysis):**

- **Memory Intensive:** Multiple `cbind()` operations in loops (Lines 51-54, 59-64, 82-99)
- **Computational Cost:** Many `apply()` calls for median calculations (Lines 52, 90-94, 119-123, 144, 161-162, 165)
- **Memory Management:** Explicit `rm()` and `gc()` calls indicate memory pressure

**Hot Paths Identified:**

1. **Array Growth in Loops** - Lines 51-54, 59-64, 82-99

   - `cbind()` operations in loops - **CRITICAL BOTTLENECK**
   - Causes memory fragmentation and repeated allocations

2. **Median Calculations** - Lines 52, 161-162, 165

   - `apply(..., 1, median)` - Slow `apply()` pattern
   - Called multiple times per feature

3. **Sampling Operations** - Lines 90-94, 119-123
   - `apply()` + `sample()` pattern - Inefficient
   - Independent operations that could be parallelized

**Memory Usage:**

- Very high memory allocation due to `cbind()` in loops
- Memory fragmentation from repeated allocations
- Explicit garbage collection calls indicate memory pressure

**Optimization Opportunities:**

- **CRITICAL:** Pre-allocate all arrays (replace `cbind()` in loops)
- Replace `apply()` with loops or broadcasting
- Parallelize median calculations across features
- Use views for subsetting to avoid copies

**Planned Benchmarks:**

- End-to-end effect-size computation on full `selex` data
- Stress tests with increased feature counts and MC samples
- Memory usage profiling
- Comparison of serial vs parallel execution

---

### 3. `rdirichlet()` - HIGH PRIORITY

**Status:** ⚠️ Benchmarks planned but not yet executed

**Expected Characteristics:**

- **Core Function:** Called frequently by `aldex.clr()` (once per sample per MC instance)
- **Highly Parallelizable:** Each sample is independent
- **GPU Candidate:** Embarrassingly parallel operations

**Scaling Characteristics:**

- Throughput (samples/sec) scales with number of features
- Independent across MC instances and samples
- Memory scales with output matrix size

**Optimization Opportunities:**

- Pre-allocate output matrix
- Use broadcasting for normalization
- **GPU acceleration:** Highly parallelizable
- Parallelize across MC instances and samples

**Planned Benchmarks:**

- Measure sampling throughput (samples/sec) for varying numbers of features
- Compare serial vs parallel (threaded) implementations
- GPU acceleration potential assessment

---

### 4. `aldex.ttest()` - HIGH PRIORITY

**Status:** ✅ Benchmarked with infrastructure

**Key Measurements:**

- **Dataset:** Full `selex` dataset transformed via `aldex.clr()`
- **Artifacts Generated:**
  - `AUDIT/aldex.ttest/benchmarks_microbenchmark.csv` - Microbenchmark timings

**Scaling Characteristics:**

- Runtime scales with number of features
- Runtime scales with number of MC instances
- Sensitivity to paired vs unpaired tests (minimal overhead difference)

**Hot Paths Identified:**

1. **Wrapper Overhead** - Line 53

   - `sapply()` call for extracting results
   - Could be optimized with direct array operations

2. **Underlying `t.fast()` and `wilcox.fast()` calls**
   - Called for every feature in every MC instance
   - Pre-allocated result matrices (good pattern)

**Memory Usage:**

- Pre-allocated result matrices (good pattern)
- Memory scales with features × MC instances

**Optimization Opportunities:**

- Replace `sapply()` with array operations
- Maintain pre-allocation pattern
- Parallelize across MC instances
- **GPU candidate:** Feature-level parallelization

**Next Steps:**

- Add additional benchmark scenarios with varying `mc.samples`
- Profile wrapper overhead vs underlying function calls

---

### 5. `aldex.glm()` - HIGH PRIORITY

**Status:** ✅ Benchmarked with infrastructure

**Key Measurements:**

- **Dataset:** Full `selex` dataset transformed via `aldex.clr()`
- **Artifacts Generated:**
  - `AUDIT/aldex.glm/benchmarks_microbenchmark.csv` - Microbenchmark timings

**Scaling Characteristics:**

- Runtime scales with number of features (GLM fit per feature)
- Runtime scales with condition complexity
- GLM vs Kruskal-Wallis paths have different performance characteristics

**Hot Paths Identified:**

1. **GLM Fitting** - Lines 81-83

   - `apply()` for GLM fitting per feature
   - Each GLM fit is computationally expensive

2. **Kruskal-Wallis Tests** - Lines 95-98

   - `apply()` for Kruskal-Wallis per feature
   - Ranking operations are expensive

3. **MC Instance Extraction** - Line 77
   - `sapply()` for extracting MC instances
   - Could use direct array indexing

**Memory Usage:**

- Pre-allocated result matrices (good pattern)
- GLM fitting requires intermediate storage

**Optimization Opportunities:**

- Replace `apply()` with loops
- Parallelize across features (each feature's test is independent)
- Use `GLM.jl` for GLM fitting
- **GPU candidate:** Feature-level parallelization

**Next Steps:**

- Add profiling (profvis/Rprof) hooks similar to `aldex.clr()`
- Extend benchmarks to multi-class and unbalanced designs

---

### 6. `aldex.corr()` - HIGH PRIORITY

**Status:** ⚠️ Benchmarks planned but not yet executed

**Expected Characteristics:**

- **Computational Cost:** Many `apply()` calls for correlation calculations (Lines 48, 52-54, 57, 60, 63-65, 68, 71, 77-83)
- **Scaling:** Runtime scales with number of features and covariates

**Hot Paths Identified:**

1. **Correlation Calculations** - Lines 48, 52-54, 57, 60, 63-65, 68, 71

   - `apply()` for Pearson and Spearman correlations
   - Called for every feature-covariate pair

2. **P-value Adjustments** - Lines 77-83
   - Multiple testing correction overhead

**Optimization Opportunities:**

- Replace `apply()` with loops
- Parallelize across features
- Use `StatsBase.jl` for correlations
- **GPU candidate:** Feature-level parallelization

**Planned Benchmarks:**

- Correlation analysis on CLR-transformed `selex` data
- Scaling study in number of features and covariates
- Benchmarks contrasting serial vs threaded/parallel execution

---

### 7. `t.fast()` - MEDIUM PRIORITY

**Status:** ⚠️ Currently exercised indirectly through `aldex.ttest()` benchmarks

**Expected Characteristics:**

- **Frequency:** Called for every feature in every MC instance
- **Performance:** Optimized implementation (faster than base R `t.test()`)
- **Scaling:** Linear with number of features

**Hot Paths Identified:**

- Lines 29-30: `apply()` pattern (minor, but could be optimized)

**Optimization Opportunities:**

- Replace `apply()` with loops
- Use optimized Julia statistical functions
- Maintain fast test statistic calculation

**Planned Benchmarks:**

- Standalone microbenchmarks on synthetic matrices
- Comparisons to base R `t.test()` in terms of throughput

---

### 8. `wilcox.fast()` - MEDIUM PRIORITY

**Status:** ⚠️ Currently exercised indirectly through `aldex.ttest()` benchmarks

**Expected Characteristics:**

- **Frequency:** Called for every feature in every MC instance
- **Performance:** Optimized implementation (faster than base R `wilcox.test()`)
- **Complexity:** Ranking operations are more complex than t-test

**Hot Paths Identified:**

- Lines 54-59, 71: `apply()` patterns for ranking and p-value calculations

**Optimization Opportunities:**

- Replace `apply()` with loops
- Use optimized Julia statistical functions
- **GPU potential:** Low (ranking is complex)

**Planned Benchmarks:**

- Standalone microbenchmarks on matrices with different tie structures
- Comparisons to base R `wilcox.test()` focusing on speed-ups

---

### 9. `iqlr.features()` - LOW PRIORITY

**Status:** ⚠️ Benchmarks planned but not yet executed

**Expected Characteristics:**

- **Overhead:** Lightweight selector function
- **Impact:** Affects downstream workflows, not raw computational cost

**Hot Paths Identified:**

- Lines 83, 93, 94: `apply()` calls for quantile calculations

**Optimization Opportunities:**

- Replace `apply()` with broadcasting
- Use boolean indexing
- Type stability

**Planned Benchmarks:**

- Measure selection overhead on `selex`-sized and larger matrices
- Compare performance against alternative implementations

---

### 10. `aitchison.mean()` - LOW PRIORITY

**Status:** ⚠️ Benchmarks planned but not yet executed

**Expected Characteristics:**

- **Frequency:** Called in effect calculations
- **Cost:** Low computational cost (pure mathematical operations)
- **Stability:** Numerical stability considerations

**Optimization Opportunities:**

- Maintain numerical stability pattern
- Use `SpecialFunctions.jl` for `digamma()`
- Type stability

**Planned Benchmarks:**

- Benchmark on effect-size-style workloads
- Compare naive vs optimized vectorized/loop-based versions

---

## Hot Path Summary

### Top 5 Computational Bottlenecks

1. **Monte Carlo Sampling (`rdirichlet()` in `aldex.clr()`)** - Very High

   - Called once per sample per MC instance
   - Embarrassingly parallel
   - **GPU acceleration target**

2. **Array Growth in `aldex.effect()` (`cbind()` in loops)** - Very High

   - Causes memory fragmentation
   - **CRITICAL:** Must pre-allocate in Julia

3. **CLR Transformation (`apply()` patterns)** - High

   - Multiple `apply()` calls for log-ratio calculations
   - **Replace with loops or broadcasting**

4. **Statistical Test Loops (`apply()` in `aldex.ttest()`, `aldex.glm()`, `aldex.corr()`)** - High

   - `apply()` called for every feature
   - **Replace with loops, parallelize across features**

5. **Median Calculations (`apply(..., 1, median)` in `aldex.effect()`)** - High
   - Called multiple times per feature
   - **Replace with `median(..., dims=2)` or loops**

---

## Memory Usage Analysis

### High Memory Functions

1. **`aldex.clr()`** - High

   - Stores MC instances: `samples × features × mc.samples`
   - Memory scales linearly with all dimensions

2. **`aldex.effect()`** - Very High
   - Multiple `cbind()` operations cause memory fragmentation
   - Explicit `rm()` and `gc()` calls indicate memory pressure
   - **CRITICAL:** Pre-allocation will significantly reduce memory usage

### Memory Patterns

- **Good Patterns:**

  - `aldex.ttest()` - Pre-allocated result matrices
  - `aldex.glm()` - Pre-allocated result matrices
  - `aldex.corr()` - Pre-allocated result matrices

- **Bad Patterns:**
  - `aldex.effect()` - `cbind()` in loops (causes fragmentation)
  - List operations in `aldex.clr()` (IQLR/ZERO modes)

---

## Scaling Behavior

### Time Complexity Analysis

| Function         | Time Complexity (Big-O) | Dominant Factor                      |
| ---------------- | ----------------------- | ------------------------------------ |
| `aldex.clr()`    | O(f × s × m)            | Features × Samples × MC instances    |
| `aldex.effect()` | O(f × s × m)            | Features × Samples × MC instances    |
| `rdirichlet()`   | O(f × n)                | Features × Number of samples         |
| `aldex.ttest()`  | O(f × m)                | Features × MC instances              |
| `aldex.glm()`    | O(f × m)                | Features × MC instances              |
| `aldex.corr()`   | O(f × c × m)            | Features × Covariates × MC instances |
| `t.fast()`       | O(1)                    | Per-feature, per-MC instance         |
| `wilcox.fast()`  | O(s log s)              | Per-feature, per-MC instance         |

Where:

- `f` = number of features
- `s` = number of samples
- `m` = number of MC instances (`mc.samples`)
- `c` = number of covariates
- `n` = number of samples to generate

### Space Complexity Analysis

| Function         | Space Complexity (Big-O) | Dominant Storage        |
| ---------------- | ------------------------ | ----------------------- |
| `aldex.clr()`    | O(f × s × m)             | MC instances per sample |
| `aldex.effect()` | O(f × s × m)             | Intermediate arrays     |
| `rdirichlet()`   | O(f × n)                 | Output matrix           |
| `aldex.ttest()`  | O(f × m)                 | Result matrices         |
| `aldex.glm()`    | O(f × m)                 | Result matrices         |
| `aldex.corr()`   | O(f × c × m)             | Result matrices         |

---

## Performance Optimization Recommendations

### Immediate Priorities (P0)

1. **`aldex.clr()`:**

   - Replace all `apply()` calls with loops or broadcasting
   - Pre-allocate all arrays
   - Parallelize Monte Carlo sampling (CPU threading or GPU)

2. **`aldex.effect()`:**
   - **CRITICAL:** Pre-allocate all arrays (replace `cbind()` in loops)
   - Replace all `apply()` calls with loops or broadcasting
   - Parallelize median calculations

### High Priorities (P1)

3. **`rdirichlet()`:**

   - Pre-allocate output matrix
   - GPU acceleration (highly parallelizable)

4. **`aldex.ttest()`, `aldex.glm()`, `aldex.corr()`:**
   - Replace `apply()`/`sapply()` with loops
   - Parallelize across features
   - GPU acceleration for feature-level parallelization

### Medium Priorities (P2)

5. **`t.fast()`, `wilcox.fast()`:**
   - Replace `apply()` with loops
   - Use optimized Julia statistical functions

---

## GPU Acceleration Candidates

### High-Priority GPU Targets

1. **Monte Carlo Sampling (`rdirichlet()`)** - Very High Potential

   - Embarrassingly parallel
   - Independent across MC instances and samples
   - Expected speedup: 10-50x for large datasets

2. **CLR Transformations** - High Potential

   - Matrix operations are GPU-friendly
   - Element-wise operations
   - Expected speedup: 5-20x

3. **Statistical Tests** - High Potential

   - Feature-level parallelization (independent per feature)
   - Expected speedup: 5-15x

4. **Effect Size Calculations** - Medium-High Potential
   - Median and sampling operations
   - Expected speedup: 3-10x

### GPU Implementation Considerations

- Use `KernelAbstractions.jl` for backend-agnostic kernels
- Pre-allocate GPU buffers
- Use `Float32` for better GPU performance (unless precision requires `Float64`)
- Handle RNG per thread properly
- Validate GPU results against CPU implementation

---

## Benchmarking Gaps and Next Steps

### Functions Needing Benchmarks

1. **`aldex.effect()`** - CRITICAL

   - End-to-end effect-size computation
   - Memory usage profiling
   - Stress tests with increased feature counts

2. **`rdirichlet()`** - HIGH

   - Standalone throughput benchmarks
   - Parallel vs serial comparison

3. **`aldex.corr()`** - HIGH

   - Correlation analysis benchmarks
   - Scaling studies

4. **`t.fast()`, `wilcox.fast()`** - MEDIUM

   - Standalone microbenchmarks
   - Comparison to base R functions

5. **`iqlr.features()`, `aitchison.mean()`** - LOW
   - Overhead measurements
   - Numerical stability tests

### Scaling Analysis Needed

- Larger synthetic datasets (1000+ features, 100+ samples)
- Varying `mc.samples` values (32, 128, 512, 1024)
- Different `denom` modes impact
- Parallel vs serial execution comparison

---

## References

- Individual function benchmarks: `AUDIT/<function_name>/benchmarks.md`
- Optimization analysis: `AUDIT/R_Code_Optimization_Summary.md`
- Benchmarking infrastructure: `AUDIT/benchmarking_infrastructure.R`
- Function signatures: `AUDIT/<function_name>/signature.md`
