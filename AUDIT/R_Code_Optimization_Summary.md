# R Code Optimization Analysis Summary

**Date:** 2024  
**Package Version:** 1.8.1  
**Phase:** Phase 0, Week 1

## Executive Summary

This document summarizes the R code optimization analysis performed on the ALDEx2 R package. The analysis identifies optimization patterns, translation recommendations, and prioritizes optimization efforts for the Julia translation.

## Key Findings

### Critical Optimization Patterns Identified

1. **Widespread use of `apply()` family functions** - These are slow in R and should be replaced with explicit loops or broadcasting in Julia
2. **Array growth with `cbind()` in loops** - Major memory bottleneck; must pre-allocate arrays in Julia
3. **List operations** - R lists are slow; should use arrays/vectors in Julia
4. **Data.frame construction overhead** - Should use NamedArrays or similar structures in Julia
5. **Good pre-allocation patterns** - Some functions already use pre-allocation; maintain these patterns

### High-Priority Functions for Optimization

| Function               | Priority     | Reason                                                    | GPU Candidate |
| ---------------------- | ------------ | --------------------------------------------------------- | ------------- |
| `aldex.clr.function()` | **CRITICAL** | Core function, many `apply()` calls, Monte Carlo sampling | ✅ Yes        |
| `aldex.effect()`       | **CRITICAL** | Memory-intensive, many `cbind()` operations               | ✅ Yes        |
| `rdirichlet()`         | **HIGH**     | Core Monte Carlo sampling, called frequently              | ✅ Yes        |
| `aldex.ttest()`        | **HIGH**     | Called for every analysis, many `sapply()` calls          | ✅ Yes        |
| `aldex.glm()`          | **HIGH**     | GLM fitting is expensive, many `apply()` calls            | ✅ Yes        |
| `aldex.corr()`         | **HIGH**     | Correlation tests are expensive, many `apply()` calls     | ✅ Yes        |
| `t.fast()`             | **HIGH**     | Called for every feature in every MC instance             | ✅ Yes        |
| `wilcox.fast()`        | **HIGH**     | Called for every feature in every MC instance             | ⚠️ Partial    |
| `iqlr.features()`      | **MEDIUM**   | Setup function, some `apply()` calls                      | ❌ No         |
| `aitchison.mean()`     | **MEDIUM**   | Called in effect calculations                             | ❌ No         |
| `aldex()`              | **LOW**      | Wrapper function, delegates to others                     | ❌ No         |

## Optimization Patterns by Category

### 1. Vectorized Operations (Replace with Loops/Broadcasting)

**Pattern:** Use of `apply()`, `sapply()`, `lapply()`, `vapply()`

**Functions Affected:**

- `aldex.clr.function()` - Lines 58, 139, 145, 157
- `aldex.ttest()` - Line 53
- `aldex.effect()` - Lines 52, 90-94, 119-123, 144, 161-162, 165
- `aldex.glm()` - Lines 77, 81-83, 91, 95-98
- `aldex.corr()` - Lines 48, 52-54, 57, 60, 63-65, 68, 71, 77-83
- `iqlr.features()` - Lines 83, 93, 94
- `t.fast()` - Lines 29-30
- `wilcox.fast()` - Lines 54-59, 71

**Translation Recommendation:**

- Replace `apply()` with explicit loops or broadcasting in Julia
- Julia loops are faster than R's `apply()` family
- Use broadcasting for element-wise operations: `x .+ y` instead of `apply(x, 1, function(z) z + y)`

### 2. Array Growth in Loops (Pre-allocate)

**Pattern:** Use of `cbind()`, `rbind()`, `c()` in loops

**Functions Affected:**

- `aldex.effect()` - Lines 51-54, 59-64, 82-99, 111-114 (CRITICAL)

**Translation Recommendation:**

- Pre-allocate all arrays before loops
- Use `Matrix{Float64}(undef, nrows, ncols)` for matrices
- Avoid growing arrays; this is a major performance bottleneck

### 3. Memory Management (Optimize)

**Pattern:** Use of `rm()` and `gc()` calls

**Functions Affected:**

- `aldex.effect()` - Lines 54, 63, 99, 129 (indicates memory pressure)

**Translation Recommendation:**

- Proper pre-allocation eliminates need for explicit memory management
- Julia's garbage collector is more efficient; explicit `gc()` calls not needed

### 4. Specialized C-backed Functions (Use Julia Equivalents)

**Pattern:** Use of optimized C-backed R functions

**Functions Affected:**

- `rowSums()`, `rowMeans()` - Used in multiple functions
- `multtest::mt.teststat()` - Used in `t.fast()`, `wilcox.fast()`
- `digamma()`, `pt()`, `pnorm()`, `pwilcox()`, `psignrank()` - Statistical functions
- `p.adjust()` - Multiple testing correction

**Translation Recommendation:**

- Use Julia equivalents: `StatsBase.jl`, `Distributions.jl`, `MultipleTesting.jl`
- Note: `rowMeans()` is C-backed in R, but Julia loops are actually faster for large arrays
- Ensure optimized implementations for critical functions like `mt.teststat()`

### 5. Pre-allocation (Maintain Good Patterns)

**Pattern:** Pre-allocated matrices/vectors

**Functions Affected:**

- `aldex.ttest()` - Lines 40-43
- `aldex.glm()` - Lines 64-67
- `aldex.corr()` - Lines 34-41
- `iqlr.features()` - Multiple locations

**Translation Recommendation:**

- Maintain these good patterns in Julia
- Use `Matrix{Float64}(undef, nrows, ncols)` for matrices
- Pre-allocate all result containers

### 6. Parallel Processing (Enhance)

**Pattern:** Use of `BiocParallel` (`bplapply()`)

**Functions Affected:**

- `aldex.clr.function()` - Lines 105-112, 137-142
- `aldex.effect()` - Lines 67-68, 106-107
- `aldex.glm()` - Lines 86-90

**Translation Recommendation:**

- Use Julia's `Threads.@threads` for CPU parallelization
- Consider GPU acceleration for Monte Carlo sampling
- Julia's threading is more efficient than R's BiocParallel

## Translation Recommendations by Function

### Core Functions

#### `rdirichlet()`

- ✅ Pre-allocate output matrix
- ✅ Use broadcasting for normalization
- ✅ Type stability via multiple dispatch
- ✅ **GPU candidate** - Highly parallelizable

#### `aldex.clr.function()`

- 🔴 **CRITICAL**: Replace all `apply()` calls with loops/broadcasting
- 🔴 **CRITICAL**: Pre-allocate all arrays
- ✅ Use views instead of copies
- ✅ Parallelize Monte Carlo sampling
- ✅ **GPU candidate** - Monte Carlo and CLR transformations

#### `aldex.ttest()`

- 🔴 Replace `sapply()` with array operations
- ✅ Maintain pre-allocation pattern
- ✅ Parallelize across MC instances
- ✅ **GPU candidate** - Feature-level parallelization

#### `aldex.effect()`

- 🔴 **CRITICAL**: Pre-allocate all arrays (replace `cbind()` in loops)
- 🔴 **CRITICAL**: Replace all `apply()` calls
- ✅ Use views for subsetting
- ✅ Parallelize median calculations
- ✅ **GPU candidate** - Median and sampling operations

#### `aldex.glm()`

- 🔴 Replace `apply()` with loops
- ✅ Parallelize across features
- ✅ Use `GLM.jl` for GLM fitting
- ✅ **GPU candidate** - Feature-level parallelization

#### `aldex.corr()`

- 🔴 Replace `apply()` with loops
- ✅ Parallelize across features
- ✅ Use `StatsBase.jl` for correlations
- ✅ **GPU candidate** - Feature-level parallelization

### Supporting Functions

#### `t.fast()` / `wilcox.fast()`

- 🔴 Replace `apply()` with loops
- ✅ Use optimized Julia statistical functions
- ✅ Maintain fast test statistic calculation
- ⚠️ GPU: `wilcox.fast()` is complex due to ranking

#### `iqlr.features()`

- 🔴 Replace `apply()` with broadcasting
- ✅ Use boolean indexing
- ✅ Type stability

#### `aitchison.mean()`

- ✅ Maintain numerical stability pattern
- ✅ Use `SpecialFunctions.jl` for `digamma()`
- ✅ Type stability

## Common Pitfalls to Avoid

1. **Don't translate `apply()` directly** - Use loops or broadcasting
2. **Don't grow arrays in loops** - Always pre-allocate
3. **Don't use data.frames unnecessarily** - Use arrays or NamedArrays
4. **Don't replicate R's list operations** - Use arrays/vectors in Julia
5. **Don't ignore type stability** - Ensure all functions are type-stable
6. **Don't use `rowMeans()` for large arrays** - Julia loops are faster

## GPU Acceleration Strategy

### High-Priority GPU Candidates

1. **Monte Carlo Sampling (`rdirichlet()`)** - Embarrassingly parallel
2. **CLR Transformations** - Matrix operations are GPU-friendly
3. **Statistical Tests** - Feature-level parallelization
4. **Effect Size Calculations** - Median and sampling operations

### GPU Implementation Considerations

- Use `KernelAbstractions.jl` for backend-agnostic kernels
- Pre-allocate GPU buffers
- Use `Float32` for better GPU performance (unless precision requires `Float64`)
- Handle RNG per thread properly
- Validate GPU results against CPU implementation

## Performance Optimization Priority Matrix

| Function               | Computational Cost | Optimization Impact | GPU Potential | Priority |
| ---------------------- | ------------------ | ------------------- | ------------- | -------- |
| `aldex.clr.function()` | Very High          | Very High           | Very High     | **P0**   |
| `aldex.effect()`       | Very High          | Very High           | High          | **P0**   |
| `rdirichlet()`         | High               | High                | Very High     | **P1**   |
| `aldex.ttest()`        | High               | High                | High          | **P1**   |
| `aldex.glm()`          | High               | High                | High          | **P1**   |
| `aldex.corr()`         | High               | High                | High          | **P1**   |
| `t.fast()`             | Medium             | High                | Medium        | **P2**   |
| `wilcox.fast()`        | Medium             | High                | Low           | **P2**   |
| `iqlr.features()`      | Low                | Medium              | Low           | **P3**   |
| `aitchison.mean()`     | Low                | Low                 | Low           | **P3**   |

**Priority Levels:**

- **P0**: Critical - Must optimize for basic functionality
- **P1**: High - Significant performance impact
- **P2**: Medium - Moderate performance impact
- **P3**: Low - Minor optimizations

## Next Steps

1. **Week 2**: Computational cost analysis and profiling
2. **Week 2**: Parallelization opportunities analysis
3. **Implementation**: Follow optimization recommendations during translation
4. **Validation**: Benchmark Julia implementations against R

## References

- Individual function optimization analyses in `AUDIT/<function_name>/optimizations.md`
- Function signatures in `AUDIT/<function_name>/signature.md`
- Package inventory in `AUDIT/Package_Inventory.md`
