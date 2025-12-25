# DifferentialEquations.jl: Solver Design Patterns

## Objective / Focus Area

Extract design and testing patterns for high-performance differential equation solvers in Julia, focusing on:

- Composable solver architecture
- Type stability patterns
- Deterministic vs. stochastic workflow handling
- API design principles

## Implementation Patterns Observed

### 1. Package Structure: Re-export Pattern

**Key Observation:** DifferentialEquations.jl is primarily a **re-export package** that aggregates functionality from specialized packages.

```julia
module DifferentialEquations

using Reexport

@reexport using SciMLBase
@reexport using OrdinaryDiffEq

end # module
```

**Patterns Identified:**

- **Modular design**: Core functionality split into specialized packages (OrdinaryDiffEq, StochasticDiffEq, etc.)
- **Unified interface**: Re-export provides single import point for users
- **Composability**: Packages can be used independently or together
- **Type system**: Leverages Julia's type system for algorithm selection

**Lesson for ALDEx2.jl:**

- Consider modular structure if package grows large
- Use re-export for convenience while maintaining modularity
- Keep core types and interfaces in main package

### 2. Composable Solver Architecture

**Pattern:** Solvers are composable through multiple dispatch and type parameters.

**Example from DiffEqGPU.jl:**

```julia
abstract type GPUODEAlgorithm <: DiffEqBase.AbstractODEAlgorithm end
abstract type GPUSDEAlgorithm <: DiffEqBase.AbstractSDEAlgorithm end

struct GPUTsit5 <: GPUODEAlgorithm end
struct GPUEM <: GPUSDEAlgorithm end
```

**Patterns Identified:**

- **Abstract type hierarchy**: Algorithms inherit from abstract types
- **Multiple dispatch**: Algorithm selection via dispatch on algorithm type
- **Type parameters**: Algorithms can have type parameters for configuration
- **Composability**: Algorithms can be combined with other components (callbacks, etc.)

**Lesson for ALDEx2.jl:**

- Use abstract types for algorithm variants (e.g., `AbstractALDExAlgorithm`)
- Leverage multiple dispatch for algorithm selection
- Design composable components (feature selection, statistical tests, etc.)

### 3. Type Stability Patterns

**Key Pattern:** Functions are type-stable, with types resolved at compile time.

**Example from GPU kernel:**

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

- **Type annotations**: Use `@Const` for read-only parameters in kernels
- **Type stability**: Avoid type instability in hot paths
- **Compile-time resolution**: Use type parameters to resolve dispatch at compile time
- **Views for efficiency**: Use `@views` to avoid allocations

**Lesson for ALDEx2.jl:**

- Ensure type stability throughout (critical for performance)
- Use type parameters for configuration (e.g., `ALDExCLR{T}` where `T` is element type)
- Use views instead of copies where possible
- Annotate function parameters clearly

### 4. Deterministic vs. Stochastic Workflow Handling

**Pattern:** Separate handling for deterministic (ODE) and stochastic (SDE) problems.

**Deterministic (ODE):**

- Fixed solution for given inputs
- Reproducible with same initial conditions
- Validation via exact matching or tolerance

**Stochastic (SDE):**

- Random solution paths
- Reproducible with same RNG seed
- Validation via statistical properties or ensemble statistics

**Example from DiffEqGPU.jl:**

```julia
# Deterministic ODE solver
sol = solve(prob, GPUTsit5(), EnsembleGPUKernel(backend), trajectories = 10)

# Stochastic SDE solver
sol = solve(sdeprob, GPUEM(), EnsembleGPUArray(backend), trajectories = 10_000)
```

**Patterns Identified:**

- **Separate algorithm types**: `GPUODEAlgorithm` vs. `GPUSDEAlgorithm`
- **Ensemble handling**: Stochastic problems use ensembles for Monte Carlo
- **RNG management**: Stochastic solvers manage RNG state per trajectory
- **Validation strategy**: Deterministic uses exact matching, stochastic uses statistical tests

**Lesson for ALDEx2.jl:**

- **Clear separation**: Distinguish probabilistic (`aldex_clr` with Monte Carlo) from deterministic functions
- **RNG management**: Use thread-safe RNGs for Monte Carlo sampling
- **Validation**: Use exact matching for deterministic, statistical tests for probabilistic
- **Ensemble support**: Consider ensemble-style API for Monte Carlo workflows

### 5. Problem-Integrator-Solution Pattern

**Pattern:** Three-stage workflow: Problem → Integrator → Solution

```julia
# 1. Define problem
prob = ODEProblem(f, u0, tspan, p)

# 2. Create integrator (optional, for more control)
integrator = init(prob, alg, dt=0.01)

# 3. Solve (creates solution)
sol = solve(prob, alg)
```

**Patterns Identified:**

- **Problem definition**: Encapsulates function, initial conditions, parameters
- **Integrator**: Low-level control over solving process
- **Solution**: Immutable result with interpolation capabilities
- **Separation of concerns**: Each stage has clear responsibility

**Lesson for ALDEx2.jl:**

- **Problem definition**: `ALDExCLR` could be the "problem" (encapsulates data + parameters)
- **Solution**: `ALDExResults` is the "solution" (immutable results)
- **Intermediate steps**: Consider exposing intermediate steps (CLR transformation) as separate objects

### 6. Callback System

**Pattern:** Callbacks allow custom behavior during solving process.

**Example:**

```julia
condition(u, t, integrator) = u[1] > 1.0
affect!(integrator) = integrator.u[1] = 0.0
cb = DiscreteCallback(condition, affect!)
sol = solve(prob, alg, callback=cb)
```

**Patterns Identified:**

- **Composable callbacks**: Multiple callbacks can be combined
- **Type-safe**: Callbacks are type-stable
- **Flexible**: Support discrete and continuous callbacks

**Lesson for ALDEx2.jl:**

- **Progress callbacks**: Consider callback system for progress reporting
- **Custom processing**: Allow custom processing at intermediate steps
- **Composability**: Design callbacks to be composable

## Testing & Validation Practices

### 1. Regression Testing

**Pattern:** Compare GPU results to trusted CPU implementation.

**Example from DiffEqGPU.jl tests:**

```julia
# GPU solution
sol = solve(monteprob, alg, EnsembleGPUKernel(backend), trajectories = 10)

# CPU reference solution
bench_sol = solve(prob, Vern9(), adaptive = false, dt = 0.01f0)

# Compare
@test norm(bench_sol.u[end] - sol.u[1].u[end]) < 5e-3
```

**Patterns Identified:**

- **Reference implementation**: CPU version serves as ground truth
- **Tolerance-based comparison**: Use tolerance for floating-point comparison
- **Property validation**: Compare solution properties, not exact values

**Lesson for ALDEx2.jl:**

- **R as reference**: R ALDEx2 implementation serves as ground truth
- **Tolerance for deterministic**: Use tolerance for deterministic functions
- **Statistical for probabilistic**: Use statistical tests for Monte Carlo functions

### 2. Deterministic Solution Validation

**Pattern:** Exact matching with tolerance for deterministic problems.

```julia
@test norm(bench_sol.u - sol.u[1].u) < 2e-4
```

**Patterns Identified:**

- **Norm-based comparison**: Use vector norms for array comparison
- **Tolerance selection**: Choose tolerance based on numerical precision
- **Multiple properties**: Test multiple solution properties

**Lesson for ALDEx2.jl:**

- **Exact matching**: Use `isapprox()` with tolerance for deterministic functions
- **Multiple checks**: Validate dimensions, structure, and values
- **Tolerance selection**: Choose tolerance based on expected numerical precision

### 3. Stochastic Solution Validation

**Pattern:** Statistical validation for stochastic problems.

**Note:** DiffEqGPU.jl doesn't explicitly test statistical equivalence, but this is needed for ALDEx2.jl.

**Recommended Pattern for ALDEx2.jl:**

```julia
# Run Monte Carlo with different seeds
sol1 = solve(prob, alg, EnsembleGPUKernel(backend), trajectories = 1000, seed=1)
sol2 = solve(prob, alg, EnsembleGPUKernel(backend), trajectories = 1000, seed=2)

# Statistical validation
@test ks_test_equivalent(sol1, sol2)
@test correlation(sol1, sol2) > 0.95
```

**Lesson for ALDEx2.jl:**

- **Statistical tests**: Use KS test, correlation tests for Monte Carlo validation
- **Ensemble statistics**: Compare ensemble statistics, not individual trajectories
- **Seed management**: Test reproducibility with same seed, equivalence with different seeds

## Performance / Benchmarking Notes

### 1. Type Stability Critical

**Observation:** Type instability kills performance in Julia.

**Pattern:**

- Ensure all hot paths are type-stable
- Use type parameters for configuration
- Avoid dynamic dispatch in loops

**Lesson for ALDEx2.jl:**

- **Type stability first**: Ensure type stability from the start
- **Profile early**: Use `@code_warntype` to check type stability
- **Type parameters**: Use type parameters for element types, array types

### 2. Pre-allocation

**Pattern:** Pre-allocate arrays to avoid allocations in hot paths.

**Example:**

```julia
# Pre-allocate output arrays
du = similar(u)
```

**Lesson for ALDEx2.jl:**

- **Pre-allocate**: Pre-allocate arrays for Monte Carlo sampling
- **In-place operations**: Use in-place operations where possible
- **Memory efficiency**: Minimize allocations in hot paths

### 3. Views vs. Copies

**Pattern:** Use views instead of copies to avoid allocations.

**Example:**

```julia
@views @inbounds f(du[:, i], u[:, i], p[:, i], t)
```

**Lesson for ALDEx2.jl:**

- **Use views**: Use `@views` macro to avoid allocations
- **Safe indexing**: Use `@inbounds` where safe (after validation)
- **Column-major**: Consider column-major layout for better cache performance

## Direct Lessons for ALDEx2.jl

### 1. Architecture

- **Modular design**: Consider splitting into modules if package grows
- **Re-export pattern**: Use re-export for convenience while maintaining modularity
- **Abstract types**: Use abstract types for algorithm variants
- **Multiple dispatch**: Leverage multiple dispatch for algorithm selection

### 2. Type Stability

- **Type stability first**: Ensure type stability from the start
- **Type parameters**: Use type parameters for configuration
- **Views over copies**: Use views to avoid allocations
- **Profile early**: Check type stability with `@code_warntype`

### 3. Deterministic vs. Stochastic

- **Clear separation**: Distinguish probabilistic from deterministic functions
- **RNG management**: Use thread-safe RNGs for Monte Carlo
- **Validation strategy**: Exact matching for deterministic, statistical for probabilistic
- **Ensemble support**: Consider ensemble-style API for Monte Carlo

### 4. Testing

- **Reference implementation**: Use R ALDEx2 as ground truth
- **Tolerance-based**: Use tolerance for deterministic functions
- **Statistical tests**: Use statistical tests for Monte Carlo functions
- **Regression tests**: Compare against reference implementation

### 5. Performance

- **Pre-allocation**: Pre-allocate arrays to avoid allocations
- **In-place operations**: Use in-place operations where possible
- **Views**: Use views instead of copies
- **Type stability**: Critical for performance

## Open Questions / Gaps

1. **Ensemble API**: How to design ensemble-style API for ALDEx2 Monte Carlo?

   - Solution: Consider `EnsembleProblem`-like pattern for Monte Carlo sampling

2. **Progress Reporting**: How to report progress during long Monte Carlo runs?

   - Solution: Use callback system or progress bars (ProgressMeter.jl)

3. **Memory Management**: How to handle large Monte Carlo ensembles efficiently?

   - Solution: Use streaming/chunked processing, or GPU acceleration

4. **Reproducibility**: How to ensure reproducibility across Julia versions?

   - Solution: Document RNG behavior, use fixed seeds in tests

5. **Validation Strategy**: How to validate Monte Carlo results statistically?
   - Solution: Use KS test, correlation tests, ensemble statistics


