# DiffEqGPU.jl: GPU Kernel Design Patterns

## Objective / Focus Area

Identify patterns for writing portable, performant GPU kernels in Julia, focusing on:

- KernelAbstractions.jl patterns
- Backend-agnostic kernel design
- Memory access patterns
- Grid-stride loops
- Input/output separation

## Implementation Patterns Observed

### 1. KernelAbstractions.jl Pattern

**Key Pattern:** Use `@kernel` macro from KernelAbstractions.jl for portable kernels.

**Example:**

```julia
@kernel function gpu_kernel(f, du, @Const(u), @Const(p), @Const(t))
    i = @index(Global, Linear)
    if eltype(p) <: Number
        @views @inbounds f(du[:, i], u[:, i], p[:, i], t)
    else
        @views @inbounds f(du[:, i], u[:, i], p[i], t)
    end
end
```

**Patterns Identified:**

- **`@kernel` macro**: Defines portable kernel that works across backends
- **`@index(Global, Linear)`**: Gets global linear index for current thread
- **`@Const` annotation**: Marks read-only parameters (enables optimizations)
- **`@views` and `@inbounds`**: Use views and disable bounds checking for performance
- **Backend-agnostic**: Same kernel works on CUDA, AMDGPU, Metal, oneAPI, OpenCL

### 2. Grid-Stride Loops

**Pattern:** Use grid-stride loops for variable input sizes.

**Example:**

```julia
@kernel function gpu_kernel(f, du, @Const(u), @Const(p), @Const(t))
    i = @index(Global, Linear)
    # Process element i
    # If input is larger than grid size, kernel will be called multiple times
    # with different i values
    @inbounds f(du[:, i], u[:, i], p[:, i], t)
end
```

**Patterns Identified:**

- **Linear indexing**: Use `@index(Global, Linear)` for simple linear access
- **Automatic handling**: KernelAbstractions handles grid-stride automatically
- **Variable sizes**: Works with inputs larger than number of threads

**Note:** DiffEqGPU.jl uses simple linear indexing. For more complex cases, explicit grid-stride loops may be needed:

```julia
@kernel function grid_stride_kernel(input, output)
    i = @index(Global, Linear)
    stride = @groupsize(Global, Linear) * @ngroups(Global, Linear)
    @inbounds for j in i:stride:length(input)
        output[j] = process(input[j])
    end
end
```

### 3. Input/Output Separation

**Pattern:** Write to pre-allocated output buffers, avoid in-place operations.

**Example:**

```julia
@kernel function gpu_kernel(f, du, @Const(u), @Const(p), @Const(t))
    i = @index(Global, Linear)
    # Write to output buffer du
    @views @inbounds f(du[:, i], u[:, i], p[:, i], t)
end
```

**Patterns Identified:**

- **Output buffers**: Always write to output buffers (kernels can't return values)
- **Pre-allocation**: Output buffers must be pre-allocated on host
- **Input/output separation**: Keep inputs and outputs separate to avoid race conditions
- **In-place operations**: Avoid in-place operations unless using atomics (which are slow)

### 4. Memory Access Patterns

**Pattern:** Use coalesced memory access patterns.

**Example:**

```julia
@kernel function gpu_kernel(f, du, @Const(u), @Const(p), @Const(t))
    i = @index(Global, Linear)
    # Consecutive threads access consecutive memory locations
    @views @inbounds f(du[:, i], u[:, i], p[:, i], t)
end
```

**Patterns Identified:**

- **Coalesced access**: Consecutive threads access consecutive memory locations
- **Column-major**: Access patterns favor column-major layout
- **Views for efficiency**: Use `@views` to avoid allocations
- **Strided access**: Avoid strided access patterns when possible

### 5. Type Handling in Kernels

**Pattern:** Handle different types explicitly in kernels.

**Example:**

```julia
@kernel function gpu_kernel(f, du, @Const(u), @Const(p), @Const(t))
    i = @index(Global, Linear)
    if eltype(p) <: Number
        # p is a matrix (one parameter set per trajectory)
        @views @inbounds f(du[:, i], u[:, i], p[:, i], t)
    else
        # p is a vector of parameter objects
        @views @inbounds f(du[:, i], u[:, i], p[i], t)
    end
end
```

**Patterns Identified:**

- **Type checks**: Use type checks to handle different input types
- **Branch divergence**: Minimize branch divergence (all threads in warp take same path)
- **Type stability**: Ensure kernel is type-stable for each branch

### 6. Workgroup Size Configuration

**Pattern:** Configure workgroup size based on backend.

**Example:**

```julia
function workgroupsize(backend, n)
    min(maxthreads(backend), n)
end

maxthreads(::CPU) = 1024

# Usage
wgs = workgroupsize(backend, size(u, 2))
kernel(backend)(f, du, u, p, t; ndrange = size(u, 2), workgroupsize = wgs)
```

**Patterns Identified:**

- **Backend-specific**: Different backends have different optimal workgroup sizes
- **Default values**: 128-512 threads per block, multiple of 32 (warp size)
- **Adaptive**: Adjust based on problem size
- **CPU fallback**: CPU backend has different limits (1024 threads)

### 7. Precision: Float32 vs Float64

**Pattern:** Use Float32 for better GPU performance.

**Example:**

```julia
u0 = Float32[1.0; 0.0; 0.0]
tspan = (0.0f0, 10.0f0)
p = (10.0f0, 28.0f0, 8 / 3.0f0)
```

**Patterns Identified:**

- **Float32 default**: Use Float32 for GPU computations (better performance)
- **Float64 when needed**: Use Float64 only when precision requires it
- **Backend support**: Not all backends support Float64 (e.g., Metal)
- **Type consistency**: Keep types consistent throughout (Float32 or Float64)

### 8. Kernel Launch Configuration

**Pattern:** Configure kernel launch with appropriate grid and block sizes.

**Example:**

```julia
version = get_backend(u)
wgs = workgroupsize(version, size(u, 2))
kernel(version)(f, du, u, p, t;
    ndrange = size(u, 2),      # Total number of threads
    workgroupsize = wgs)        # Threads per workgroup
```

**Patterns Identified:**

- **ndrange**: Total number of threads to launch
- **workgroupsize**: Threads per workgroup (block)
- **Backend detection**: Use `get_backend()` to detect backend
- **Automatic handling**: KernelAbstractions handles grid/block configuration

### 9. Shared Memory and Reductions

**Pattern:** Use shared memory for reductions when possible.

**Note:** DiffEqGPU.jl doesn't extensively use shared memory reductions, but the pattern is:

```julia
@kernel function reduction_kernel(input, output)
    i = @index(Global, Linear)
    tid = @index(Local, Linear)
    block_size = @groupsize(Global, Linear)

    # Load into shared memory (if available)
    # Perform reduction in shared memory
    # Write result with atomic operation (one per block)
end
```

**Patterns Identified:**

- **Shared memory**: Use for reductions to minimize atomics
- **One atomic per block**: Much faster than per-element atomics
- **Bank conflicts**: Be aware of shared memory bank conflicts
- **Not always available**: Shared memory not available on all backends

### 10. Random Number Generation

**Pattern:** Pre-allocate RNG per thread.

**Example (conceptual, not from DiffEqGPU.jl):**

```julia
@kernel function monte_carlo_kernel(rng_states, output, @Const(input))
    i = @index(Global, Linear)
    rng = rng_states[i]  # Each thread has its own RNG
    output[i] = sample(rng, input)
end
```

**Patterns Identified:**

- **Per-thread RNG**: Each thread must have its own RNG state
- **Pre-allocation**: Pre-allocate RNG states on host
- **Indexing**: Index RNG states by thread ID
- **Thread safety**: Never reuse RNG state across threads

## Direct Lessons for ALDEx2GPU.jl

### 1. Kernel Design

- **Use `@kernel` macro**: For portable, backend-agnostic kernels
- **Linear indexing**: Use `@index(Global, Linear)` for simple cases
- **Input/output separation**: Write to pre-allocated output buffers
- **`@Const` annotation**: Mark read-only parameters
- **Views and inbounds**: Use `@views` and `@inbounds` for performance

### 2. Memory Access

- **Coalesced access**: Ensure consecutive threads access consecutive memory
- **Column-major**: Favor column-major layout for better cache performance
- **Pre-allocation**: Pre-allocate all output buffers on host
- **Avoid strided access**: Minimize strided memory access patterns

### 3. Type Handling

- **Explicit type checks**: Handle different types explicitly in kernels
- **Minimize divergence**: Avoid branch divergence when possible
- **Type stability**: Ensure type stability for each branch
- **Float32 default**: Use Float32 for better GPU performance

### 4. Configuration

- **Workgroup size**: 128-512 threads, multiple of 32
- **Backend detection**: Use `get_backend()` to detect backend
- **Adaptive sizing**: Adjust workgroup size based on problem size
- **CPU fallback**: Support CPU backend with appropriate limits

### 5. Random Number Generation

- **Per-thread RNG**: Pre-allocate RNG state for each thread
- **Thread indexing**: Index RNG states by thread ID
- **Thread safety**: Never reuse RNG state across threads
- **Efficiency**: Avoid excessive RNG calls (can bottleneck registers)

### 6. Kernel Launch

- **ndrange**: Set to total number of elements to process
- **workgroupsize**: Set to optimal size for backend
- **Backend-specific**: Different backends may need different configurations

## Implementation Checklist for ALDEx2GPU.jl

- [ ] Design kernels using `@kernel` macro
- [ ] Use `@index(Global, Linear)` for simple indexing
- [ ] Mark read-only parameters with `@Const`
- [ ] Pre-allocate output buffers on host
- [ ] Use `@views` and `@inbounds` for performance
- [ ] Ensure coalesced memory access patterns
- [ ] Use Float32 for GPU computations
- [ ] Configure workgroup sizes appropriately
- [ ] Implement per-thread RNG for Monte Carlo
- [ ] Support multiple GPU backends (CUDA, AMDGPU, Metal, oneAPI, OpenCL)
- [ ] Provide CPU fallback
- [ ] Test kernels incrementally (small inputs first)

## Open Questions / Gaps

1. **Shared Memory**: When to use shared memory for ALDEx2 operations?

   - Solution: Consider for reductions (e.g., computing means, sums)

2. **Kernel Fusion**: Which operations can be fused into single kernels?

   - Solution: CLR transformation + statistical computation, if memory allows

3. **Memory Coalescing**: How to ensure optimal memory access for ALDEx2 data layout?

   - Solution: Consider data layout (row-major vs. column-major) for optimal access

4. **RNG Performance**: How to optimize RNG performance for large Monte Carlo ensembles?

   - Solution: Use efficient RNG (e.g., Philox), batch RNG generation

5. **Backend Support**: Which backends are most important for ALDEx2 users?
   - Solution: Start with CUDA (most common), add others based on demand


