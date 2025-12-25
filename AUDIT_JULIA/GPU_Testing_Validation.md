# GPU Testing & Performance Validation

## Objective / Focus Area

Extract strategies for robust multi-backend GPU testing and validation, focusing on:

- Incremental testing approach
- CPU comparison validation
- Multi-backend testing
- Performance benchmarking

## Testing & Validation Practices

### 1. Incremental Testing Strategy

**Pattern:** Start with minimal configuration, gradually increase complexity.

**Example from DiffEqGPU.jl:**

```julia
# Start with small input
reads = Float32[1.0 2.0; 3.0 4.0]

# Test with minimal configuration (1 block, 1 thread)
# (Note: KernelAbstractions handles this automatically, but concept applies)

# Gradually increase size
reads_medium = rand(Float32, 100, 50)
reads_large = rand(Float32, 1000, 500)
```

**Patterns Identified:**

- **Small inputs first**: Test with smallest possible inputs
- **Minimal configuration**: Start with minimal thread/block configuration
- **Gradual scaling**: Increase problem size incrementally
- **Isolation**: Isolate bugs by testing with minimal configuration

**Recommended Approach for ALDEx2GPU.jl:**

```julia
@testset "Incremental GPU testing" begin
    # 1. Smallest possible input
    reads = Float32[1.0 2.0; 3.0 4.0]
    conditions = ["A", "B"]

    # Test with minimal MC samples
    result = gpu_aldex_clr(reads, conditions, mc_samples=2, backend)
    @test size(result.clr) == (2, 2, 2)

    # 2. Medium input
    reads_medium = rand(Float32, 10, 5)
    result_medium = gpu_aldex_clr(reads_medium, conditions, mc_samples=10, backend)
    @test size(result_medium.clr) == (10, 5, 10)

    # 3. Large input
    reads_large = rand(Float32, 100, 50)
    result_large = gpu_aldex_clr(reads_large, conditions, mc_samples=128, backend)
    @test size(result_large.clr) == (100, 50, 128)
end
```

### 2. CPU Comparison Validation

**Pattern:** Always compare GPU results to CPU implementation (which is validated against R).

**Example from DiffEqGPU.jl:**

```julia
# GPU solution
sol_gpu = solve(monteprob, alg, EnsembleGPUKernel(backend), trajectories = 10)

# CPU reference solution
sol_cpu = solve(prob, Vern9(), adaptive = false, dt = 0.01f0)

# Compare
@test norm(sol_cpu.u[end] - sol_gpu.u[1].u[end]) < 5e-3
```

**Patterns Identified:**

- **CPU as ground truth**: CPU implementation (validated against R) serves as ground truth
- **Tolerance-based**: Use tolerance for floating-point comparison
- **Multiple properties**: Test multiple solution properties
- **Regression testing**: Compare against CPU to catch regressions

**Recommended Approach for ALDEx2GPU.jl:**

```julia
@testset "GPU vs CPU comparison" begin
    reads, conditions = load_test_data()

    # CPU (validated against R ALDEx2)
    cpu_result = aldex_clr(reads, conditions, mc_samples=128)

    # GPU
    gpu_result = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

    # Compare (Float32 tolerance: ~1e-3)
    @test gpu_result.clr ≈ cpu_result.clr atol=1e-3
    @test size(gpu_result.clr) == size(cpu_result.clr)

    # Compare statistical properties (for Monte Carlo)
    @test mean(gpu_result.clr) ≈ mean(cpu_result.clr) atol=0.1
    @test std(gpu_result.clr) ≈ std(cpu_result.clr) atol=0.1
end
```

### 3. Multi-Backend Testing

**Pattern:** Test on multiple GPU backends to ensure portability.

**Example from DiffEqGPU.jl:**

```julia
# Test conditionally based on backend availability
if CUDA.functional()
    backend = CUDABackend()
    sol = solve(prob, alg, EnsembleGPUKernel(backend), trajectories = 10)
    @test sol.converged == true
end
```

**Patterns Identified:**

- **Conditional testing**: Test backends conditionally based on availability
- **Consistent results**: Results should be consistent across backends (within tolerance)
- **Backend-specific limits**: Some backends have limitations (e.g., Metal doesn't support Float64)
- **Portability validation**: Ensure code works across all supported backends

**Recommended Approach for ALDEx2GPU.jl:**

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
    if Metal.functional()
        push!(backends, MetalBackend())
    end
    # ... other backends ...

    # CPU reference
    cpu_result = aldex_clr(reads, conditions, mc_samples=128)

    # Test each backend
    for backend in backends
        gpu_result = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

        # Compare to CPU
        @test gpu_result.clr ≈ cpu_result.clr atol=1e-3

        # Compare across backends (if multiple available)
        if length(backends) > 1
            for other_backend in backends
                if other_backend != backend
                    other_result = gpu_aldex_clr(reads, conditions, mc_samples=128, other_backend)
                    @test gpu_result.clr ≈ other_result.clr atol=1e-3
                end
            end
        end
    end
end
```

### 4. Debugging Tools

**Pattern:** Use backend-specific debugging tools for GPU code.

**Tools:**

- **CUDA**: `compute-sanitizer`, `cuda-gdb`
- **AMDGPU**: `rocgdb`
- **Metal**: Xcode Instruments
- **Print debugging**: Works with literals and scalars only

**Example:**

```julia
# Print debugging (works with literals and scalars)
@kernel function debug_kernel(input, output)
    i = @index(Global, Linear)
    @inbounds begin
        # Print literal string
        @cuprintf("Processing element %d\n", i)
        # Print scalar value
        @cuprintf("Value: %f\n", input[i])
        output[i] = input[i] * 2.0f0
    end
end
```

**Recommended Approach:**

- Use `compute-sanitizer` (CUDA) or equivalent for memory access validation
- Use `cuda-gdb` (CUDA) or equivalent for debugging
- Use print debugging for basic debugging (literals and scalars only)
- Remove or conditionally compile debug code for production

### 5. Assert Checks

**Pattern:** Use assert checks during development, remove for production.

**Example:**

```julia
@kernel function gpu_kernel(input, output)
    i = @index(Global, Linear)
    @inbounds begin
        # Assert check (remove for production)
        @assert i > 0 && i <= length(input) "Index out of bounds"
        output[i] = input[i] * 2.0f0
    end
end
```

**Recommended Approach:**

- Use assert checks during development
- Remove or conditionally compile for production
- Use `@assert` for bounds checking, type validation, etc.

### 6. Memory Validation

**Pattern:** Validate memory access patterns and prevent out-of-bounds errors.

**Example:**

```julia
@kernel function safe_kernel(input, output, @Const(n))
    i = @index(Global, Linear)
    @inbounds begin
        # Bounds checking (can be optimized with @inbounds after validation)
        if i <= n
            output[i] = input[i] * 2.0f0
        end
    end
end
```

**Recommended Approach:**

- Guard memory access with bounds checking initially
- Use `@inbounds` after validation (when safe)
- Use `compute-sanitizer` to catch memory errors
- Test with various input sizes to catch edge cases

### 7. RNG Validation

**Pattern:** Validate RNG per thread produces statistically equivalent results.

**Example:**

```julia
@testset "RNG validation" begin
    reads, conditions = load_test_data()

    # Same seed should produce identical results
    Random.seed!(12345)
    result1 = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

    Random.seed!(12345)
    result2 = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

    @test result1.clr ≈ result2.clr

    # Different seeds should produce statistically equivalent results
    Random.seed!(67890)
    result3 = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

    @test ks_test_equivalent(result1.clr, result3.clr)
    @test correlation(result1.clr, result3.clr) > 0.9
end
```

## Performance Benchmarking

### 1. Baseline Establishment

**Pattern:** Establish CPU baseline before GPU optimization.

```julia
@benchmark sol_cpu = aldex_clr(reads, conditions, mc_samples=128)
@benchmark sol_gpu = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)

speedup = time_cpu / time_gpu
@info "Speedup: $(speedup)x"
```

### 2. Scaling Analysis

**Pattern:** Test performance across different problem sizes.

```julia
mc_samples = [10, 100, 1000, 10_000]

for n in mc_samples
    @time sol = gpu_aldex_clr(reads, conditions, mc_samples=n, backend)
    # Record timing
end
```

### 3. Memory Profiling

**Pattern:** Monitor GPU memory usage.

```julia
# CUDA example
mem_before = CUDA.used_memory()
sol = gpu_aldex_clr(reads, conditions, mc_samples=128, backend)
mem_after = CUDA.used_memory()
memory_used = mem_after - mem_before
@info "Memory used: $(memory_used / 1024^2) MB"
```

## Direct Lessons for ALDEx2GPU.jl

### 1. Testing Strategy

- **Incremental testing**: Start with small inputs, gradually increase
- **CPU comparison**: Always compare GPU to CPU (validated against R)
- **Multi-backend**: Test on all supported backends
- **Debugging tools**: Use backend-specific debugging tools

### 2. Validation Approach

- **Tolerance-based**: Use tolerance for floating-point comparison
- **Statistical validation**: Use statistical tests for Monte Carlo
- **Memory validation**: Validate memory access patterns
- **RNG validation**: Test RNG reproducibility and equivalence

### 3. Performance Benchmarking

- **Baseline**: Establish CPU baseline first
- **Scaling**: Test across different problem sizes
- **Memory profiling**: Monitor GPU memory usage
- **Speedup measurement**: Track performance improvements

### 4. Debugging

- **Incremental**: Start with minimal configuration
- **Tools**: Use backend-specific debugging tools
- **Assert checks**: Use during development, remove for production
- **Print debugging**: Works with literals and scalars only

## Implementation Checklist

- [ ] Implement incremental testing (small inputs first)
- [ ] Compare GPU results to CPU (validated against R)
- [ ] Test on multiple GPU backends
- [ ] Use debugging tools (compute-sanitizer, etc.)
- [ ] Add assert checks during development
- [ ] Validate memory access patterns
- [ ] Test RNG reproducibility and equivalence
- [ ] Establish CPU baseline performance
- [ ] Measure GPU speedup
- [ ] Profile memory usage
- [ ] Test scaling with problem size
- [ ] Document testing and validation strategy

## Open Questions / Gaps

1. **Test Performance**: How to handle slow GPU tests in CI?

   - Solution: Mark slow tests, use smaller test datasets, test conditionally

2. **Backend Availability**: How to handle missing backends in CI?

   - Solution: Test conditionally, skip if backend not available

3. **Reproducibility**: How to ensure reproducible GPU results?

   - Solution: Set seeds, document RNG behavior, test reproducibility

4. **Performance Targets**: What performance targets should be set?

   - Solution: Target 10-50x speedup for large datasets (from plan)

5. **Memory Limits**: How to test with limited GPU memory?
   - Solution: Test with various problem sizes, handle memory errors gracefully


