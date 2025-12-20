# Parallelization Strategy Document

**Date:** 2025-01-27  
**Package Version:** 1.8.1  
**Phase:** Phase 0, Week 2 - Parallelization and Distributed Computing Analysis

## Executive Summary

This document provides comprehensive parallelization opportunities and recommendations for ALDEx2 functions, identifying strategies for CPU threading, GPU acceleration, and distributed computing. The analysis identifies independent operations, communication overhead, memory requirements, and expected speedup estimates.

## Parallelization Analysis Framework

### Independence Criteria

For parallelization to be effective, operations must be:

1. **Independent** - No data dependencies between parallel tasks
2. **Sufficiently large** - Computation time >> communication/synchronization overhead
3. **Memory-efficient** - Parallel tasks fit in available memory
4. **Load-balanced** - Work distributed evenly across threads/processes

### Parallelization Levels

1. **Monte Carlo Level** - Parallelize across MC instances
2. **Feature Level** - Parallelize across features (rows)
3. **Sample Level** - Parallelize across samples (columns)
4. **Operation Level** - Parallelize within operations (matrix operations)

## Parallelization Opportunities by Function

### 1. `aldex.clr()` / `aldex.clr.function()` - CRITICAL

**Current R Implementation:** Uses `BiocParallel` (`bplapply()`) for optional parallelization

#### Monte Carlo Sampling Parallelization

**Opportunity:** ✅ **HIGH** - Embarrassingly parallel

**Analysis:**

- Each MC instance is generated independently
- `rdirichlet()` calls are independent across samples and MC instances
- Lines 105-112, 137-142: Current R code uses `bplapply()` vs `lapply()`

**Recommended Approach:**

- **CPU Threading:** Use `Threads.@threads` to parallelize MC instance generation
- **GPU Acceleration:** Highly suitable - each MC instance can be generated on GPU
- **Chunk Size:** Process MC instances in chunks to balance load

**Expected Speedup:**

- CPU threading: 2-4x (limited by number of cores)
- GPU: 10-50x for large datasets (depending on GPU)

**Memory Requirements:**

- Each thread/GPU thread needs memory for one MC instance
- Total memory: `samples × features × mc.samples × sizeof(Float64)`
- GPU memory: Same, but on GPU device

**Communication Overhead:**

- Low - Independent operations, minimal synchronization
- GPU: Memory transfer overhead (host ↔ device) but amortized over many operations

**Implementation Notes:**

- Use thread-safe RNG (one RNG per thread)
- Pre-allocate output arrays
- Use `@threads` for CPU or GPU kernels for device execution

---

#### CLR Transformation Parallelization

**Opportunity:** ✅ **MEDIUM-HIGH** - Matrix operations are parallelizable

**Analysis:**

- CLR transformation (Lines 139, 145, 157) involves matrix operations
- Element-wise operations can be parallelized
- Current R code uses `apply()` which is sequential

**Recommended Approach:**

- **GPU Acceleration:** Matrix operations are GPU-friendly
- **CPU Threading:** Less effective due to overhead, but possible for large matrices
- **Fusion:** Combine with Monte Carlo sampling in single GPU kernel

**Expected Speedup:**

- GPU: 5-20x for matrix operations
- CPU threading: 2-3x (limited by memory bandwidth)

**Memory Requirements:**

- Same as Monte Carlo sampling
- GPU: Coalesced memory access patterns important

---

#### Feature Selection Parallelization (IQLR/ZERO modes)

**Opportunity:** ⚠️ **LOW-MEDIUM** - Some operations are parallelizable

**Analysis:**

- Quantile calculations (Lines 83, 93, 94 in `iqlr.features()`) can be parallelized
- Feature subsetting is mostly sequential
- List operations are not easily parallelizable

**Recommended Approach:**

- **CPU Threading:** Parallelize quantile calculations across features
- **GPU:** Less suitable due to complex control flow

**Expected Speedup:**

- CPU threading: 1.5-2x (limited by sequential parts)

---

### 2. `aldex.effect()` - CRITICAL

**Current R Implementation:** Uses `BiocParallel` (`bplapply()`) for optional parallelization

#### Median Calculation Parallelization

**Opportunity:** ✅ **HIGH** - Independent per feature

**Analysis:**

- Lines 52, 161-162, 165: `apply(..., 1, median)` - median per feature
- Each feature's median is independent
- Current R code uses `bplapply()` (Lines 67-68, 106-107)

**Recommended Approach:**

- **CPU Threading:** Use `Threads.@threads` to parallelize across features
- **GPU Acceleration:** Suitable - median calculations can be done on GPU
- **Chunk Size:** Process features in chunks

**Expected Speedup:**

- CPU threading: 2-4x
- GPU: 5-15x for large feature sets

**Memory Requirements:**

- Each thread needs memory for feature's data
- Total: `features × samples × mc.samples × sizeof(Float64)`
- GPU: Same, but on device

**Communication Overhead:**

- Low - Independent operations
- GPU: Memory transfer but amortized

---

#### Sampling Operation Parallelization

**Opportunity:** ✅ **MEDIUM** - Independent sampling

**Analysis:**

- Lines 90-94, 119-123: `apply()` + `sample()` pattern
- Each sampling operation is independent
- Can be parallelized across features or MC instances

**Recommended Approach:**

- **CPU Threading:** Parallelize sampling across features
- **GPU:** Suitable for independent sampling operations

**Expected Speedup:**

- CPU threading: 2-3x
- GPU: 3-10x

---

### 3. `rdirichlet()` - HIGH PRIORITY

**Opportunity:** ✅ **VERY HIGH** - Embarrassingly parallel

**Analysis:**

- Each sample's Dirichlet draw is independent
- Gamma variate generation is independent
- Normalization is element-wise (parallelizable)

**Recommended Approach:**

- **GPU Acceleration:** **PRIMARY TARGET** - Highly parallelizable
- **CPU Threading:** Also effective for CPU-only systems
- **Implementation:** Each thread/GPU thread generates independent samples

**Expected Speedup:**

- GPU: 20-100x for large sample counts
- CPU threading: 4-8x (limited by cores)

**Memory Requirements:**

- Output matrix: `n_samples × n_features × sizeof(Float64)`
- GPU: Same, but on device
- Per-thread RNG state: Minimal

**Communication Overhead:**

- Very low - Independent operations
- GPU: Single memory transfer for input/output

**Implementation Notes:**

- Pre-allocate RNG per thread/GPU thread
- Use grid-stride loops for variable input sizes
- Use `Float32` on GPU for better performance (unless precision requires `Float64`)

---

### 4. `aldex.ttest()` - HIGH PRIORITY

**Current R Implementation:** Sequential (no parallelization)

#### Feature-Level Parallelization

**Opportunity:** ✅ **HIGH** - Independent per feature

**Analysis:**

- Each feature's statistical test is independent
- Lines 40-43: Pre-allocated result matrices (good pattern)
- Line 53: `sapply()` for result extraction (sequential)

**Recommended Approach:**

- **CPU Threading:** Use `Threads.@threads` to parallelize across features
- **GPU Acceleration:** Suitable - feature-level parallelization
- **MC Instance Parallelization:** Also parallelize across MC instances

**Expected Speedup:**

- CPU threading: 2-4x
- GPU: 5-15x for large feature sets

**Memory Requirements:**

- Result matrices: `features × mc_instances × sizeof(Float64)`
- Each thread needs access to CLR data (read-only, can be shared)

**Communication Overhead:**

- Low - Independent operations
- GPU: Memory transfer for CLR data and results

**Implementation Notes:**

- Parallelize outer loop (features) and inner loop (MC instances)
- Use shared memory for CLR data (read-only)
- Pre-allocate result matrices

---

#### MC Instance Parallelization

**Opportunity:** ✅ **MEDIUM-HIGH** - Independent per MC instance

**Analysis:**

- Each MC instance's statistical tests are independent
- Can parallelize the loop over MC instances (Lines 34-47 in old implementation)

**Recommended Approach:**

- **CPU Threading:** Parallelize across MC instances
- **GPU:** Process multiple MC instances in parallel

**Expected Speedup:**

- CPU threading: 2-4x (limited by MC instance count)
- GPU: 5-10x

---

### 5. `aldex.glm()` - HIGH PRIORITY

**Current R Implementation:** Uses `BiocParallel` (`bplapply()`) for optional parallelization

#### Feature-Level Parallelization

**Opportunity:** ✅ **HIGH** - Independent per feature

**Analysis:**

- Each feature's GLM/Kruskal-Wallis test is independent
- Lines 64-67: Pre-allocated result matrices (good pattern)
- Lines 81-83, 95-98: `apply()` for GLM/Kruskal-Wallis (sequential)

**Recommended Approach:**

- **CPU Threading:** Use `Threads.@threads` to parallelize across features
- **GPU Acceleration:** Suitable for feature-level parallelization
- **MC Instance Parallelization:** Also parallelize across MC instances

**Expected Speedup:**

- CPU threading: 2-4x
- GPU: 5-15x (GLM fitting may be complex on GPU)

**Memory Requirements:**

- Result matrices: `features × mc_instances × sizeof(Float64)`
- GLM fitting requires intermediate storage per feature

**Communication Overhead:**

- Low - Independent operations
- GPU: Memory transfer for CLR data and results

**Implementation Notes:**

- Parallelize across features (outer loop)
- GLM fitting may need CPU fallback if GPU implementation is complex
- Use `GLM.jl` which may have GPU support

---

#### MC Instance Parallelization

**Opportunity:** ✅ **MEDIUM-HIGH** - Independent per MC instance

**Analysis:**

- Each MC instance's GLM tests are independent
- Lines 72-101: Loop over MC instances can be parallelized

**Recommended Approach:**

- **CPU Threading:** Parallelize across MC instances
- **GPU:** Process multiple MC instances in parallel

**Expected Speedup:**

- CPU threading: 2-4x
- GPU: 5-10x

---

### 6. `aldex.corr()` - HIGH PRIORITY

**Current R Implementation:** Sequential (no parallelization)

#### Feature-Level Parallelization

**Opportunity:** ✅ **HIGH** - Independent per feature

**Analysis:**

- Each feature's correlation tests are independent
- Lines 34-41: Pre-allocated result matrices (good pattern)
- Lines 48, 52-54, 57, 60, 63-65, 68, 71: `apply()` for correlations (sequential)

**Recommended Approach:**

- **CPU Threading:** Use `Threads.@threads` to parallelize across features
- **GPU Acceleration:** Suitable - correlation calculations are GPU-friendly
- **Covariate Parallelization:** Also parallelize across covariates if many

**Expected Speedup:**

- CPU threading: 2-4x
- GPU: 5-15x for large feature sets

**Memory Requirements:**

- Result matrices: `features × covariates × mc_instances × sizeof(Float64)`
- Each thread needs access to CLR data and covariates

**Communication Overhead:**

- Low - Independent operations
- GPU: Memory transfer for CLR data, covariates, and results

**Implementation Notes:**

- Parallelize across features (primary)
- If many covariates, also parallelize across covariates
- Use `StatsBase.jl` for correlations (may have GPU support)

---

### 7. `t.fast()` - MEDIUM PRIORITY

**Opportunity:** ⚠️ **LOW** - Already optimized, called frequently

**Analysis:**

- Called for every feature in every MC instance
- Already optimized implementation
- Per-call overhead is small

**Recommended Approach:**

- **Parallelization:** Handled at higher level (`aldex.ttest()`)
- **GPU:** Can be part of feature-level GPU kernel

**Expected Speedup:**

- Indirect (through `aldex.ttest()` parallelization)

---

### 8. `wilcox.fast()` - MEDIUM PRIORITY

**Opportunity:** ⚠️ **LOW** - Complex ranking operations

**Analysis:**

- Ranking operations are more complex than t-test
- Less suitable for GPU due to complex control flow
- Per-call overhead is moderate

**Recommended Approach:**

- **CPU Threading:** Handled at higher level (`aldex.ttest()`)
- **GPU:** Less suitable due to ranking complexity

**Expected Speedup:**

- Indirect (through `aldex.ttest()` parallelization)
- GPU: Limited by ranking operations

---

## Parallelization Strategy Summary

### CPU Threading Strategy

**Primary Targets:**

1. Monte Carlo sampling in `aldex.clr()` - **P0**
2. Feature-level parallelization in statistical tests - **P0**
3. Median calculations in `aldex.effect()` - **P0**

**Implementation:**

- Use `Threads.@threads` for parallel loops
- Pre-allocate arrays to avoid race conditions
- Use thread-safe RNG (one RNG per thread)
- Balance load by chunking work

**Expected Overall Speedup:**

- 2-4x for typical multi-core systems (4-8 cores)
- Limited by Amdahl's law (sequential parts)

---

### GPU Acceleration Strategy

**Primary Targets (High Priority):**

1. **Monte Carlo Sampling (`rdirichlet()`)** - **P0**

   - Expected speedup: 20-100x
   - Embarrassingly parallel

2. **CLR Transformations** - **P0**

   - Expected speedup: 5-20x
   - Matrix operations

3. **Statistical Tests (Feature-level)** - **P1**

   - Expected speedup: 5-15x
   - Independent per feature

4. **Effect Size Calculations** - **P1**
   - Expected speedup: 3-10x
   - Median and sampling operations

**Implementation:**

- Use `KernelAbstractions.jl` for backend-agnostic kernels
- Support multiple GPU backends (CUDA, AMDGPU, Metal, oneAPI, OpenCL)
- Pre-allocate GPU buffers
- Use `Float32` for better performance (unless precision requires `Float64`)
- Handle RNG per thread properly
- Use grid-stride loops for variable input sizes
- Minimize atomics; prefer shared memory reductions

**Expected Overall Speedup:**

- 10-50x for large datasets (depending on GPU)
- Best for: Large feature counts, many MC instances

---

### Distributed Computing Strategy

**Opportunity:** ⚠️ **LOW-MEDIUM** - Limited applicability

**Analysis:**

- Most operations are memory-intensive (CLR data)
- Communication overhead would be high
- Better suited for GPU acceleration

**Potential Use Cases:**

1. **Very Large Datasets:** If dataset doesn't fit in single node memory
2. **Parameter Sweeps:** Multiple independent analyses with different parameters
3. **Batch Processing:** Multiple independent datasets

**Recommended Approach:**

- Use distributed computing only if:
  - Dataset is too large for single node
  - Multiple independent analyses needed
  - GPU acceleration is not available

**Expected Speedup:**

- Limited by communication overhead
- Better to use GPU if available

---

## Memory Requirements and Communication Overhead

### Memory Requirements by Parallelization Strategy

| Strategy         | Memory per Thread/Process | Total Memory Scaling                | Notes                               |
| ---------------- | ------------------------- | ----------------------------------- | ----------------------------------- |
| CPU Threading    | CLR data (shared)         | `features × samples × mc_instances` | Shared memory, low overhead         |
| GPU Acceleration | CLR data (device)         | `features × samples × mc_instances` | Device memory, transfer overhead    |
| Distributed      | Full dataset per node     | `nodes × dataset_size`              | High memory, communication overhead |

### Communication Overhead Analysis

| Strategy         | Communication Type      | Overhead Level | Mitigation                           |
| ---------------- | ----------------------- | -------------- | ------------------------------------ |
| CPU Threading    | Cache coherency         | Low            | Shared memory, cache-friendly access |
| GPU Acceleration | Host ↔ Device transfer | Medium         | Batch transfers, keep data on device |
| Distributed      | Network communication   | High           | Minimize transfers, batch operations |

---

## Expected Speedup Estimates

### Overall Expected Speedups

| Scenario                  | CPU Threading | GPU Acceleration | Notes                                 |
| ------------------------- | ------------- | ---------------- | ------------------------------------- |
| Small dataset (100×14)    | 1.5-2x        | 5-10x            | Overhead dominates for small datasets |
| Medium dataset (1000×50)  | 2-3x          | 10-30x           | Good parallelization efficiency       |
| Large dataset (10000×200) | 3-4x          | 20-50x           | Best parallelization efficiency       |
| Very large (100000×500)   | 3-4x          | 30-100x          | GPU excels for large datasets         |

**Assumptions:**

- CPU: 4-8 cores
- GPU: Modern GPU (e.g., NVIDIA V100, A100, or equivalent)
- Memory: Sufficient for dataset size
- Overhead: Minimal communication/synchronization

---

## Implementation Recommendations

### Phase 1: CPU Threading (Immediate)

1. **Monte Carlo Sampling in `aldex.clr()`**

   - Use `Threads.@threads` for MC instance generation
   - Thread-safe RNG per thread
   - Expected speedup: 2-4x

2. **Feature-Level Parallelization in Statistical Tests**

   - Parallelize `aldex.ttest()`, `aldex.glm()`, `aldex.corr()` across features
   - Expected speedup: 2-4x

3. **Median Calculations in `aldex.effect()`**
   - Parallelize median calculations across features
   - Expected speedup: 2-3x

### Phase 2: GPU Acceleration (High Priority)

1. **Monte Carlo Sampling (`rdirichlet()`)** - **P0**

   - GPU kernel for Dirichlet sampling
   - Expected speedup: 20-100x

2. **CLR Transformations** - **P0**

   - GPU kernel for CLR matrix operations
   - Expected speedup: 5-20x

3. **Statistical Tests** - **P1**
   - Feature-level GPU kernels
   - Expected speedup: 5-15x

### Phase 3: Optimization and Tuning

1. **Kernel Fusion**

   - Combine Monte Carlo sampling + CLR transformation
   - Reduce kernel launch overhead

2. **Memory Optimization**

   - Minimize host ↔ device transfers
   - Use in-place operations where possible

3. **Load Balancing**
   - Dynamic work distribution
   - Chunking strategies

---

## Risk Assessment

### High-Risk Areas

1. **RNG Reproducibility**

   - Risk: Different RNG sequences in parallel execution
   - Mitigation: Thread-safe RNG with proper seeding

2. **Memory Pressure**

   - Risk: Out-of-memory errors with large datasets
   - Mitigation: Chunking, memory-efficient algorithms

3. **GPU Memory Limits**
   - Risk: Dataset too large for GPU memory
   - Mitigation: CPU fallback, chunking strategies

### Low-Risk Areas

1. **Feature-Level Parallelization**

   - Low risk: Independent operations, well-understood pattern

2. **Monte Carlo Parallelization**
   - Low risk: Embarrassingly parallel, minimal dependencies

---

## Validation Strategy

### Correctness Validation

1. **Reproducibility Tests**

   - Compare parallel vs sequential results
   - Use same seeds for RNG

2. **Statistical Equivalence**

   - For probabilistic functions, use statistical tests
   - Compare distributions, not exact values

3. **Numerical Precision**
   - Validate floating-point precision maintained
   - Check for accumulation errors

### Performance Validation

1. **Speedup Measurements**

   - Compare parallel vs sequential execution times
   - Measure scaling with dataset size

2. **Memory Profiling**

   - Monitor memory usage
   - Check for memory leaks

3. **GPU Utilization**
   - Monitor GPU utilization
   - Check for kernel efficiency

---

## References

- Performance Analysis: `AUDIT/Performance_Analysis_Report.md`
- Optimization Summary: `AUDIT/R_Code_Optimization_Summary.md`
- Function Optimizations: `AUDIT/<function_name>/optimizations.md`
- GPU Implementation Guidelines: `.cursor/plans/aldex2-julia-translation-plan.plan.md` (Section 2.4)
