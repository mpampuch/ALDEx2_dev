# DifferentialEquations.jl: Testing and Validation Patterns

## Objective / Focus Area

Examine testing and validation patterns in the DifferentialEquations.jl ecosystem, focusing on:

- Deterministic solution validation
- Reproducibility checks for stochastic solvers
- Parameter sweeps / Monte Carlo simulations
- Regression testing strategies

## Testing & Validation Practices

### 1. Regression Testing Pattern

**Pattern:** Compare new implementation against trusted reference implementation.

**Example from DiffEqGPU.jl:**

```julia
# GPU solution
sol = solve(monteprob, alg, EnsembleGPUKernel(backend), trajectories = 10)

# CPU reference solution (trusted implementation)
bench_sol = solve(prob, Vern9(), adaptive = false, dt = 0.01f0)

# Compare results
@test norm(bench_sol.u[end] - sol.u[1].u[end]) < 5e-3
@test norm(bench_asol.u - asol.u[1].u) < 8e-4
```

**Patterns Identified:**

- **Reference implementation**: CPU version (or original R version) serves as ground truth
- **Tolerance-based comparison**: Use tolerance for floating-point comparison
- **Multiple properties**: Test multiple solution properties (endpoint, full trajectory, etc.)
- **Norm-based comparison**: Use vector norms for array comparison

**Key Insight:** The reference implementation (CPU or R) is the source of truth. New implementations (GPU, optimized) are validated against it.

### 2. Deterministic Solution Validation

**Pattern:** Exact matching with tolerance for deterministic problems.

**Example:**

```julia
# Compare solutions
@test norm(bench_sol.u - sol.u[1].u) < 2e-4

# Compare specific properties
@test length(sol.u[1].u) == length(saveat)
@test sol.converged == true
```

**Patterns Identified:**

- **Tolerance selection**: Choose tolerance based on numerical precision requirements
- **Property validation**: Test solution properties (length, convergence, structure)
- **Multiple test points**: Test at different time points, not just endpoints
- **Saveat validation**: Test that `saveat` points are correctly saved

**Tolerance Guidelines:**

- **Float32**: ~1e-3 to 1e-4 tolerance
- **Float64**: ~1e-10 to 1e-12 tolerance
- **Adaptive solvers**: May have slightly different tolerances

### 3. Stochastic Solution Validation

**Pattern:** Statistical validation for stochastic problems (SDEs, Monte Carlo).

**Note:** DiffEqGPU.jl doesn't explicitly test statistical equivalence in current tests, but this pattern is needed for ALDEx2.jl.

**Recommended Pattern for ALDEx2.jl:**

```julia
# Run Monte Carlo with same seed (reproducibility test)
sol1 = solve(prob, alg, EnsembleGPUKernel(backend), trajectories = 1000, seed=12345)
sol2 = solve(prob, alg, EnsembleGPUKernel(backend), trajectories = 1000, seed=12345)

# Should be identical with same seed
@test sol1.u ≈ sol2.u

# Run with different seeds (statistical equivalence test)
sol3 = solve(prob, alg, EnsembleGPUKernel(backend), trajectories = 1000, seed=67890)

# Use statistical tests
@test ks_test_equivalent(sol1, sol3)
@test correlation(sol1, sol3) > 0.95
```

**Patterns Identified:**

- **Reproducibility test**: Same seed should produce identical results
- **Statistical equivalence**: Different seeds should produce statistically equivalent results
- **Ensemble statistics**: Compare ensemble statistics, not individual trajectories
- **KS test**: Use Kolmogorov-Smirnov test for distribution equivalence
- **Correlation test**: Use correlation for relationship strength

### 4. Parameter Sweep Testing

**Pattern:** Test with different parameter values to ensure robustness.

**Example:**

```julia
# Test with different parameter sets
for p in parameter_sets
    prob = remake(prob, p=p)
    sol = solve(prob, alg)
    @test sol.retcode == ReturnCode.Success
    @test length(sol.u) > 0
end
```

**Patterns Identified:**

- **Multiple parameter sets**: Test with various parameter combinations
- **Edge cases**: Test boundary conditions, extreme values
- **Convergence**: Ensure solver converges for all parameter sets
- **Performance**: Monitor performance across parameter ranges

### 5. Monte Carlo Simulation Testing

**Pattern:** Test ensemble/Monte Carlo workflows.

**Example from DiffEqGPU.jl:**

```julia
# Create ensemble problem
prob_func = (prob, i, repeat) -> remake(prob, p = pre_p[i] .* p)
monteprob = EnsembleProblem(prob, prob_func = prob_func)

# Solve ensemble
sol = solve(monteprob, alg, EnsembleGPUKernel(backend), trajectories = 10_000)

# Validate ensemble properties
@test length(sol) == 10_000
@test all(s -> s.retcode == ReturnCode.Success, sol)
@test mean([s.u[end] for s in sol]) ≈ expected_mean atol=0.1
```

**Patterns Identified:**

- **Ensemble size**: Test with various ensemble sizes
- **Convergence**: Ensure all trajectories converge
- **Statistics**: Validate ensemble statistics (mean, variance, etc.)
- **Performance**: Monitor performance with large ensembles

### 6. Incremental Testing Strategy

**Pattern:** Start with simple cases, gradually increase complexity.

**Example from DiffEqGPU.jl tests:**

```julia
# Start with simple ODE
prob = ODEProblem(lorenz, u0, tspan, p)

# Test with fixed timestep
sol = solve(prob, alg, dt=0.01f0, adaptive=false)

# Test with adaptive timestep
sol = solve(prob, alg, dt=0.1f-1, adaptive=true, abstol=1e-7, reltol=1e-7)

# Test with saveat
sol = solve(prob, alg, saveat=[2.0f0, 4.0f0])

# Test with dense saveat
sol = solve(prob, alg, saveat=collect(0.0f0:0.1f0:10.0f0))
```

**Patterns Identified:**

- **Simple first**: Start with simplest case
- **Gradual complexity**: Add complexity incrementally
- **Multiple configurations**: Test various solver configurations
- **Edge cases**: Test edge cases (empty saveat, single point, etc.)

## Validation Approaches

### 1. Solution Property Validation

**Properties to Validate:**

- **Convergence**: `sol.retcode == ReturnCode.Success`
- **Length**: `length(sol.u) == expected_length`
- **Time span**: `sol.t[1] ≈ tspan[1]` and `sol.t[end] ≈ tspan[2]`
- **Saveat points**: All `saveat` points are present in solution
- **Interpolation**: Solution can be interpolated at arbitrary time points

### 2. Numerical Accuracy Validation

**Approaches:**

- **Reference solution**: Compare against high-precision reference solution
- **Analytical solution**: Compare against known analytical solution (when available)
- **Convergence order**: Test that error decreases with expected order
- **Tolerance satisfaction**: Ensure solution satisfies specified tolerances

### 3. Statistical Validation (for Monte Carlo)

**Approaches:**

- **Reproducibility**: Same seed produces identical results
- **Distribution equivalence**: KS test for distribution equivalence
- **Correlation**: Correlation test for relationship strength
- **Ensemble statistics**: Compare ensemble mean, variance, etc. to expected values
- **Convergence**: Ensemble statistics converge with more samples

## Direct Lessons for ALDEx2.jl

### 1. Regression Testing

- **R as reference**: Use R ALDEx2 implementation as ground truth
- **Tolerance-based**: Use tolerance for deterministic functions
- **Multiple properties**: Test dimensions, structure, and values
- **Norm-based comparison**: Use vector norms for array comparison

### 2. Deterministic Function Testing

- **Exact matching**: Use `isapprox()` with tolerance for deterministic functions
- **Property validation**: Test dimensions, structure, convergence
- **Multiple test cases**: Test with various input configurations
- **Edge cases**: Test boundary conditions, empty inputs, etc.

### 3. Probabilistic Function Testing

- **Reproducibility**: Test that same seed produces identical results
- **Statistical equivalence**: Use KS test, correlation test for different seeds
- **Ensemble statistics**: Compare ensemble statistics to expected values
- **Convergence**: Test that statistics converge with more samples

### 4. Monte Carlo Testing

- **Ensemble size**: Test with various ensemble sizes (small to large)
- **Convergence**: Ensure all Monte Carlo instances complete successfully
- **Statistics**: Validate Monte Carlo statistics (mean, variance, etc.)
- **Performance**: Monitor performance with large ensembles

### 5. Incremental Testing

- **Simple first**: Start with simplest test cases
- **Gradual complexity**: Add complexity incrementally
- **Multiple configurations**: Test various parameter configurations
- **Edge cases**: Test boundary conditions and edge cases

### 6. Test Organization

- **Group by function**: Organize tests by function/module
- **Helper functions**: Create helper functions for common test patterns
- **Reference values**: Store reference values for regression testing
- **Test data**: Use standard test datasets (e.g., selex dataset)

## Test Structure Recommendations for ALDEx2.jl

### Test File Organization

```
test/
├── runtests.jl
├── test_distributions.jl      # rdirichlet tests
├── test_clr.jl                # aldex_clr tests
├── test_statistical_tests.jl  # t-test, Wilcoxon tests
├── test_effect_sizes.jl       # effect size tests
├── test_correlation.jl        # correlation tests
├── test_integration.jl        # end-to-end tests
└── data/
    ├── selex.jl               # Test dataset
    └── reference_values.jl    # Reference outputs
```

### Test Pattern Example

```julia
@testset "aldex_clr" begin
    # Load test data
    reads, conditions = load_test_data()

    # Test reproducibility
    Random.seed!(12345)
    result1 = aldex_clr(reads, conditions, mc_samples=128)

    Random.seed!(12345)
    result2 = aldex_clr(reads, conditions, mc_samples=128)

    @test result1.clr ≈ result2.clr

    # Test statistical equivalence (different seeds)
    Random.seed!(67890)
    result3 = aldex_clr(reads, conditions, mc_samples=128)

    # Use statistical tests
    @test ks_test_equivalent(result1.clr, result3.clr)
    @test correlation(result1.clr, result3.clr) > 0.9

    # Test dimensions
    @test size(result1.clr) == (n_features, n_samples, mc_samples)

    # Test against R reference (if available)
    if has_r_reference()
        r_result = load_r_reference()
        @test statistical_equivalent(result1, r_result)
    end
end
```

## Open Questions / Gaps

1. **Reference Value Storage**: How to store and manage reference values for regression testing?

   - Solution: Store in `test/data/reference_values.jl` or separate data files

2. **Statistical Test Selection**: Which statistical tests are most appropriate for Monte Carlo validation?

   - Solution: KS test for distribution, correlation for relationship, ensemble statistics for convergence

3. **Tolerance Selection**: How to choose appropriate tolerances for different functions?

   - Solution: Based on numerical precision, test with various tolerances, document choices

4. **Performance Testing**: How to test performance without slowing down test suite?

   - Solution: Separate performance tests, use `@test_broken` for performance regressions

5. **Cross-Platform Testing**: How to ensure tests pass on different platforms?
   - Solution: Use CI with multiple platforms, test on different Julia versions
