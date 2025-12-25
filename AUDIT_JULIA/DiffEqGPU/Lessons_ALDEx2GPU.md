# DiffEqGPU.jl: Actionable Takeaways for ALDEx2GPU.jl

## Summary

This document consolidates key lessons from the DiffEqGPU.jl audit for implementing ALDEx2GPU.jl, focusing on GPU kernel design, performance optimization, and multi-backend support.

## Critical Implementation Patterns

### 1. Kernel Design with KernelAbstractions.jl

**Pattern from DiffEqGPU.jl:**

- Use `@kernel` macro for portable kernels
- Use `@index(Global, Linear)` for simple indexing
- Mark read-only parameters with `@Const`
- Write to pre-allocated output buffers

**Implementation for ALDEx2GPU.jl:**

```julia
using KernelAbstractions

# GPU-accelerated CLR transformation
@kernel function gpu_clr_kernel(reads, clr_output, @Const(denominator_idx))
    i = @index(Global, Linear)  # Feature index
    j = @index(Group, Linear)   # Sample index

    # Compute CLR for feature i, sample j
    @inbounds begin
        denominator = reads[denominator_idx, j]
        clr_output[i, j] = log(reads[i, j] / denominator)
    end
end

# GPU-accelerated Dirichlet sampling
@kernel function gpu_dirichlet_kernel(rng_states, output, @Const(alpha))
    i = @index(Global, Linear)  # Sample index

    rng = rng_states[i]  # Per-thread RNG
    n_features = size(alpha, 1)

    @inbounds begin
        # Sample from Dirichlet
        sum_gamma = 0.0f0
        for j in 1:n_features
            gamma_val = rand(rng, Gamma(alpha[j], 1.0f0))
            output[j, i] = gamma_val
            sum_gamma += gamma_val
        end

        # Normalize to simplex
        for j in 1:n_features
            output[j, i] /= sum_gamma
        end
    end
end
```

### 2. Backend-Agnostic Design

**Pattern:**

- Use KernelAbstractions for backend abstraction
- Support multiple backends (CUDA, AMDGPU, Metal, oneAPI, OpenCL)
- Provide CPU fallback

**Implementation:**

```julia
using KernelAbstractions
using CUDA, AMDGPU, Metal, oneAPI, OpenCL

# Get backend from input array
function get_backend(x)
    if x isa CuArray
        return CUDABackend()
    elseif x isa ROCArray
        return AMDGPUBackend()
    elseif x isa MtlArray
        return MetalBackend()
    elseif x isa oneArray
        return oneAPIBackend()
    elseif x isa CLArray
        return OpenCLBackend()
    else
        return CPU()
    end
end

# Launch kernel with appropriate backend
function gpu_clr(reads, denominator_idx, backend = get_backend(reads))
    clr_output = similar(reads)
    wgs = workgroupsize(backend, size(reads, 2))

    kernel = gpu_clr_kernel(backend)
    kernel(clr_output, reads, denominator_idx;
           ndrange = size(reads, 1) * size(reads, 2),
           workgroupsize = wgs)

    return clr_output
end
```

### 3. Per-Thread RNG for Monte Carlo

**Pattern:**

- Pre-allocate RNG state for each thread
- Index RNG states by thread ID
- Never reuse RNG state across threads

**Implementation:**

```julia
using Random

# Pre-allocate RNG states
function allocate_rng_states(backend, n_threads, seed)
    rng_states = [MersenneTwister(seed + i) for i in 1:n_threads]
    return adapt(backend, rng_states)
end

# Use in kernel
@kernel function gpu_dirichlet_kernel(rng_states, output, @Const(alpha))
    i = @index(Global, Linear)
    rng = rng_states[i]  # Each thread has its own RNG
    # ... sampling code ...
end
```

### 4. Memory Access Optimization

**Pattern:**

- Ensure coalesced memory access
- Use column-major layout when possible
- Pre-allocate output buffers
- Use views to avoid allocations

**Implementation:**

```julia
# Coalesced access pattern
@kernel function gpu_clr_kernel(reads, clr_output, @Const(denominator_idx))
    i = @index(Global, Linear)
    # Consecutive threads access consecutive memory
    @inbounds clr_output[i] = log(reads[i] / reads[denominator_idx])
end

# Pre-allocate output
function gpu_aldex_clr(reads, conditions, mc_samples, backend)
    # Pre-allocate all output buffers
    clr_output = Array{Float32, 3}(undef, size(reads, 1), size(reads, 2), mc_samples)
    dirichlet_samples = Array{Float32, 2}(undef, size(reads, 2), mc_samples)

    # ... computation ...

    return clr_output
end
```

### 5. Workgroup Size Configuration

**Pattern:**

- Configure workgroup size based on backend
- Default: 128-512 threads, multiple of 32
- Adjust based on problem size

**Implementation:**

```julia
function workgroupsize(backend, n)
    min(maxthreads(backend), n)
end

maxthreads(::CUDABackend) = 512
maxthreads(::AMDGPUBackend) = 256
maxthreads(::MetalBackend) = 256
maxthreads(::CPU) = 1024

# Usage
wgs = workgroupsize(backend, size(reads, 2))
kernel(backend)(...; workgroupsize = wgs)
```

### 6. Precision Strategy

**Pattern:**

- Use Float32 for GPU (better performance)
- Use Float64 when precision requires
- Adjust tolerances based on precision

**Implementation:**

```julia
# Float32 for GPU
function gpu_aldex_clr(reads::Matrix{Float32}, conditions, mc_samples, backend)
    # ... Float32 computation ...
end

# Float64 when needed
function gpu_aldex_clr(reads::Matrix{Float64}, conditions, mc_samples, backend)
    # ... Float64 computation ...
    # Note: May not be supported on all backends (e.g., Metal)
end
```

## Testing Strategy

### 1. Incremental Testing

**Pattern:**

- Start with small inputs
- Test with 1 block, 1 thread first
- Gradually increase complexity

**Implementation:**

```julia
@testset "GPU CLR kernel" begin
    # Small input first
    reads = Float32[1.0 2.0; 3.0 4.0]
    denominator_idx = 1

    # Test with minimal configuration
    clr_result = gpu_clr(reads, denominator_idx, backend)

    # Compare to CPU
    cpu_result = cpu_clr(reads, denominator_idx)
    @test clr_result ≈ cpu_result atol=1e-3

    # Gradually increase size
    reads_large = rand(Float32, 1000, 100)
    clr_large = gpu_clr(reads_large, 1, backend)
    cpu_large = cpu_clr(reads_large, 1)
    @test clr_large ≈ cpu_large atol=1e-3
end
```

### 2. CPU Comparison

**Pattern:**

- Always compare GPU results to CPU implementation
- CPU implementation is validated against R (ground truth)
- Use tolerance for floating-point comparison

**Implementation:**

```julia
@testset "GPU vs CPU comparison" begin
    reads, conditions = load_test_data()

    # CPU (validated against R)
    cpu_result = aldex_clr(reads, conditions, mc_samples=128)

    # GPU
    gpu_result = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

    # Compare (Float32 tolerance)
    @test gpu_result.clr ≈ cpu_result.clr atol=1e-3
    @test size(gpu_result.clr) == size(cpu_result.clr)
end
```

### 3. Multi-Backend Testing

**Pattern:**

- Test on multiple GPU backends
- Ensure consistent results across backends
- Test conditionally based on availability

**Implementation:**

```julia
@testset "Multi-backend testing" begin
    reads, conditions = load_test_data()

    backends = []
    if CUDA.functional()
        push!(backends, CUDABackend())
    end
    if AMDGPU.functional()
        push!(backends, AMDGPUBackend())
    end
    # ... other backends ...

    cpu_result = aldex_clr(reads, conditions, mc_samples=128)

    for backend in backends
        gpu_result = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)
        @test gpu_result.clr ≈ cpu_result.clr atol=1e-3
    end
end
```

## Performance Optimization

### 1. Kernel Fusion

**Pattern:**

- Fuse small kernels to reduce launch overhead
- Combine operations when memory allows

**Example:**

```julia
# Fused kernel: Dirichlet sampling + CLR transformation
@kernel function gpu_dirichlet_clr_kernel(rng_states, clr_output,
                                         @Const(reads), @Const(alpha))
    i = @index(Global, Linear)  # MC instance index
    rng = rng_states[i]

    # Sample Dirichlet
    dirichlet_sample = sample_dirichlet(rng, alpha)

    # Compute CLR
    for j in 1:size(reads, 2)
        clr_output[j, i] = log(dirichlet_sample[j] / sum(dirichlet_sample))
    end
end
```

### 2. Memory Coalescing

**Pattern:**

- Ensure consecutive threads access consecutive memory
- Use column-major layout when possible
- Avoid strided access patterns

### 3. Shared Memory (when applicable)

**Pattern:**

- Use shared memory for reductions
- Minimize atomics (use shared memory reduction + one atomic per block)

**Example (conceptual):**

```julia
@kernel function gpu_mean_kernel(input, output)
    i = @index(Global, Linear)
    tid = @index(Local, Linear)
    block_size = @groupsize(Global, Linear)

    # Load into shared memory
    shared = @localmem Float32 (block_size,)
    shared[tid] = input[i]
    synchronize()

    # Reduction in shared memory
    # ... reduction code ...

    # Write result (one per block)
    if tid == 1
        output[block_id] = reduced_value
    end
end
```

## Key Differences from DiffEqGPU.jl

### 1. Monte Carlo Focus

**ALDEx2GPU.jl:**

- Monte Carlo sampling is core functionality
- Per-thread RNG critical
- Statistical validation required

**DiffEqGPU.jl:**

- Monte Carlo used for parameter sweeps
- RNG less critical (used for SDE noise)
- Focus on solution accuracy

### 2. Data Layout

**ALDEx2GPU.jl:**

- Features × Samples × MC instances
- May need different access patterns
- Consider row-major vs. column-major

**DiffEqGPU.jl:**

- Trajectories × Time × State
- Column-major layout standard
- Well-established patterns

### 3. Statistical Validation

**ALDEx2GPU.jl:**

- Must validate statistical equivalence
- Compare ensemble statistics
- Use KS test, correlation tests

**DiffEqGPU.jl:**

- Focus on solution accuracy
- Compare individual trajectories
- Less emphasis on statistical validation

## Implementation Checklist

- [ ] Design kernels using `@kernel` macro
- [ ] Implement backend-agnostic design
- [ ] Pre-allocate per-thread RNG states
- [ ] Optimize memory access patterns
- [ ] Configure workgroup sizes appropriately
- [ ] Use Float32 for GPU computations
- [ ] Implement CPU fallback
- [ ] Test incrementally (small inputs first)
- [ ] Compare GPU results to CPU (validated against R)
- [ ] Test on multiple GPU backends
- [ ] Profile kernel execution times
- [ ] Optimize hot paths
- [ ] Document performance characteristics

## Open Questions / Gaps

1. **Kernel Fusion**: Which ALDEx2 operations can be fused?

   - Solution: Profile to identify fusion opportunities (e.g., Dirichlet + CLR)

2. **Data Layout**: What data layout is optimal for ALDEx2 GPU operations?

   - Solution: Profile different layouts, choose based on access patterns

3. **RNG Performance**: How to optimize RNG for large Monte Carlo ensembles?

   - Solution: Use efficient RNG (Philox), batch RNG generation

4. **Memory Management**: How to handle very large problems?

   - Solution: Streaming/chunked processing, or CPU fallback

5. **Backend Priority**: Which backends should be prioritized?
   - Solution: Start with CUDA, add others based on demand


