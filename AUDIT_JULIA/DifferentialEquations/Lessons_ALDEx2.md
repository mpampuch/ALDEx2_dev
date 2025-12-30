# DifferentialEquations.jl: Actionable Takeaways for ALDEx2.jl

## Summary

This document consolidates key lessons from the DifferentialEquations.jl ecosystem audit for implementing ALDEx2.jl, focusing on solver design, testing patterns, and validation strategies.

## Critical Implementation Patterns

### 1. Composable Architecture

**Pattern from DifferentialEquations.jl:**

- Modular design with specialized packages
- Re-export for unified interface
- Abstract types for algorithm variants
- Multiple dispatch for algorithm selection

**Implementation for ALDEx2.jl:**

```julia
# Abstract types for algorithms
abstract type AbstractALDExAlgorithm end
abstract type AbstractALDExCLRAlgorithm <: AbstractALDExAlgorithm end
abstract type AbstractALDExTestAlgorithm <: AbstractALDExAlgorithm end

# Concrete implementations
struct ALDExCLRStandard <: AbstractALDExCLRAlgorithm
    mc_samples::Int
    denominator::String
end

struct ALDExCLRGPU <: AbstractALDExCLRAlgorithm
    mc_samples::Int
    denominator::String
    backend::Backend
end

# Multiple dispatch for algorithm selection
function aldex_clr(reads, conditions, alg::AbstractALDExCLRAlgorithm)
    # Dispatch to appropriate implementation
end
```

### 2. Type Stability

**Pattern from DifferentialEquations.jl:**

- Type stability critical for performance
- Use type parameters for configuration
- Avoid dynamic dispatch in hot paths
- Use views instead of copies

**Implementation for ALDEx2.jl:**

```julia
# Type-stable function signature
function aldex_clr(reads::Matrix{T}, conditions::Vector{String},
                   mc_samples::Int, denominator::String) where T <: Real
    # Type-stable implementation
    clr_result = Matrix{T}(undef, size(reads, 1), size(reads, 2), mc_samples)
    # ... implementation ...
end

# Use views to avoid allocations
@views function compute_clr(reads, denominator_idx)
    # Use views for column operations
    denominator = reads[:, denominator_idx]
    clr = log.(reads ./ denominator)
end
```

### 3. Deterministic vs. Stochastic Handling

**Pattern from DifferentialEquations.jl:**

- Clear separation between deterministic and stochastic
- Different validation strategies
- RNG management for stochastic

**Implementation for ALDEx2.jl:**

```julia
# Deterministic function (exact matching)
function aitchison_mean(reads::Matrix{T}) where T
    # Deterministic computation
    mean_result = compute_mean(reads)
    return mean_result
end

# Probabilistic function (statistical validation)
function aldex_clr(reads::Matrix{T}, conditions::Vector{String},
                   mc_samples::Int) where T
    # Monte Carlo sampling (probabilistic)
    rng = Random.default_rng()
    clr_samples = [sample_dirichlet(rng, reads) for _ in 1:mc_samples]
    return ALDExCLR(reads, conditions, clr_samples, mc_samples)
end
```

### 4. Problem-Solution Pattern

**Pattern from DifferentialEquations.jl:**

- Problem definition encapsulates inputs
- Solution is immutable result
- Clear separation of concerns

**Implementation for ALDEx2.jl:**

```julia
# Problem definition
struct ALDExCLR
    reads::Matrix{Float64}
    conditions::Vector{String}
    clr::Array{Float64, 3}  # (features, samples, mc_samples)
    mc_samples::Int
    denominator::String
end

# Solution (immutable results)
struct ALDExResults
    we_ep::Vector{Float64}      # Welch's t-test expected p-value
    we_ebh::Vector{Float64}     # Welch's t-test expected Benjamini-Hochberg
    wi_ep::Vector{Float64}      # Wilcoxon expected p-value
    wi_ebh::Vector{Float64}     # Wilcoxon expected Benjamini-Hochberg
    effect::Vector{Float64}     # Effect size
    overlap::Vector{Float64}    # Overlap
end
```

## Testing Strategy

### 1. Regression Testing

**Pattern:**

- Compare against reference implementation (R ALDEx2)
- Use tolerance for deterministic functions
- Use statistical tests for probabilistic functions

**Implementation:**

```julia
@testset "aldex_clr regression" begin
    reads, conditions = load_test_data()

    # Julia implementation
    julia_result = aldex_clr(reads, conditions, mc_samples=128)

    # R reference (via R interface or stored reference)
    r_result = load_r_reference("aldex_clr")

    # Statistical validation (Monte Carlo is probabilistic)
    @test ks_test_equivalent(julia_result.clr, r_result.clr)
    @test correlation(julia_result.clr, r_result.clr) > 0.9
    @test size(julia_result.clr) == size(r_result.clr)
end
```

### 2. Deterministic Function Testing

**Pattern:**

- Exact matching with tolerance
- Property validation
- Multiple test cases

**Implementation:**

```julia
@testset "aitchison_mean deterministic" begin
    reads = [1.0 2.0 3.0; 4.0 5.0 6.0]
    expected_mean = [2.0, 5.0]  # Reference value from R

    result = aitchison_mean(reads)

    @test result ≈ expected_mean atol=1e-10
    @test length(result) == size(reads, 1)
end
```

### 3. Probabilistic Function Testing

**Pattern:**

- Reproducibility test (same seed)
- Statistical equivalence test (different seeds)
- Ensemble statistics validation

**Implementation:**

```julia
@testset "aldex_clr probabilistic" begin
    reads, conditions = load_test_data()

    # Reproducibility test
    Random.seed!(12345)
    result1 = aldex_clr(reads, conditions, mc_samples=128)

    Random.seed!(12345)
    result2 = aldex_clr(reads, conditions, mc_samples=128)

    @test result1.clr ≈ result2.clr

    # Statistical equivalence test
    Random.seed!(67890)
    result3 = aldex_clr(reads, conditions, mc_samples=128)

    @test ks_test_equivalent(result1.clr, result3.clr)
    @test correlation(result1.clr, result3.clr) > 0.9

    # Ensemble statistics
    @test mean(result1.clr) ≈ mean(result3.clr) atol=0.1
    @test std(result1.clr) ≈ std(result3.clr) atol=0.1
end
```

## Performance Optimization

### 1. Type Stability

**Critical for performance:**

```julia
# Check type stability
@code_warntype aldex_clr(reads, conditions, 128)

# Fix type instabilities
# - Use type parameters
# - Avoid Any types
# - Use concrete types where possible
```

### 2. Pre-allocation

**Avoid allocations in hot paths:**

```julia
function aldex_clr(reads, conditions, mc_samples)
    # Pre-allocate output
    clr_result = Array{Float64, 3}(undef,
                                    size(reads, 1),
                                    size(reads, 2),
                                    mc_samples)

    # Pre-allocate temporary arrays
    dirichlet_sample = Vector{Float64}(undef, size(reads, 2))

    # Use pre-allocated arrays
    for i in 1:mc_samples
        sample_dirichlet!(dirichlet_sample, reads)
        clr_result[:, :, i] = compute_clr(reads, dirichlet_sample)
    end

    return clr_result
end
```

### 3. Views Instead of Copies

**Avoid unnecessary allocations:**

```julia
# Use views
@views function compute_clr(reads, denominator_idx)
    denominator = reads[:, denominator_idx]
    clr = log.(reads ./ denominator)
end

# Instead of copies
function compute_clr(reads, denominator_idx)
    denominator = copy(reads[:, denominator_idx])  # Unnecessary copy
    clr = log.(reads ./ denominator)
end
```

## Key Differences from DifferentialEquations.jl

### 1. Statistical Validation Required

**ALDEx2.jl needs:**

- Statistical equivalence tests for Monte Carlo functions
- Correlation tests for probabilistic outputs
- Ensemble statistics validation

**DifferentialEquations.jl:**

- Focuses on solution accuracy for deterministic problems
- Statistical validation less critical (solutions are deterministic given inputs)

### 2. R Reference Implementation

**ALDEx2.jl:**

- Must validate against R ALDEx2 implementation
- Parallel testing framework essential
- Reference values from R package

**DifferentialEquations.jl:**

- Validates against analytical solutions or high-precision reference
- No external reference implementation

### 3. Monte Carlo Focus

**ALDEx2.jl:**

- Monte Carlo sampling is core functionality
- Statistical validation critical
- Ensemble statistics important

**DifferentialEquations.jl:**

- Monte Carlo used for parameter sweeps, not core functionality
- Focus on individual solution accuracy

## Implementation Checklist

- [ ] Design composable architecture with abstract types
- [ ] Ensure type stability throughout
- [ ] Implement deterministic vs. stochastic handling
- [ ] Create problem-solution pattern
- [ ] Implement regression testing against R
- [ ] Add deterministic function tests (exact matching)
- [ ] Add probabilistic function tests (statistical validation)
- [ ] Create helper functions for statistical tests
- [ ] Store reference values for regression testing
- [ ] Optimize with pre-allocation and views
- [ ] Profile and fix type instabilities
- [ ] Document validation strategies



