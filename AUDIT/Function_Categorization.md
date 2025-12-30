# Function Categorization: Deterministic vs Probabilistic

**Context:** Phase 0 · Week 1 · Section 3 (Function Categorization) from `aldex2-julia-translation-plan.plan.md`.

## Summary

- **Probabilistic core**: Monte Carlo sampling is confined to `rdirichlet()` and the Monte Carlo workflow inside `aldex.clr.function()` (exposed as `aldex.clr()`).
- **Deterministic layer**: All downstream statistical tests (`aldex.ttest()`, `aldex.glm()`, `aldex.corr()`, `t.fast()`, `wilcox.fast()`), effect size calculations (`aldex.effect()`, `aitchison.mean()`), feature selection helpers (`iqlr.features()`, `zero.features()`, `all.features()`, `custom.features()`), and the main wrapper `aldex()` are **deterministic** given fixed inputs and fixed CLR Monte Carlo instances.

This matches the Phase 0 plan expectation:

- **Probabilistic functions**: `aldex_clr()` (via `aldex.clr.function()`) and `rdirichlet()`.
- **Deterministic functions**: `aitchison_mean()`, IQLR/zero feature selection, statistical tests, and all S4 accessors/utilities.

## 1. Probabilistic Functions

### 1.1 `rdirichlet()`

- **Location**: `ALDEx2/R/rdirichlet.r`
- **Role**: Low-level Dirichlet sampler used by `aldex.clr.function()` to generate Monte Carlo instances.
- **Randomness source**: Uses `rgamma()` internally to draw Gamma variates and normalizes rows to the simplex.
- **Determinism properties**:
  - **Within R**: For fixed `alpha`, `n`, and global RNG state, results are reproducible given a fixed `set.seed()` _before_ calling higher-level functions.
  - **Cross-language**: Julia’s RNG will differ, so equivalence must be assessed via **distributional/statistical tests** (e.g., comparing empirical moments or via KS tests), not exact draws.

**Reproducibility requirements for Julia translation:**

- Implement `rdirichlet` as a **pure function of RNG state + parameters**.
- Ensure the Julia variant:
  - Draws from the same parameterization as R (Gamma(shape = alpha_i), then normalize).
  - Can be seeded via a **thread-safe RNG** (no reliance on a global RNG).
- For tests, treat `rdirichlet` as **probabilistic** and validate:
  - Means and variances per component match R within tolerance.
  - Samples lie on the simplex and respect positivity.

### 1.2 `aldex.clr()` / `aldex.clr.function()`

- **Location**: `ALDEx2/R/clr_function.r`
- **Role**: Core Monte Carlo CLR transformation.
- **Randomness source**:
  - Calls `rdirichlet(mc.samples, col)` for each sample (column) to create Monte Carlo instances.
  - Applies log-ratio transformation and centering on each Monte Carlo instance.
- **Outputs**:
  - S4 `aldex.clr` object with slots `reads`, `mc.samples`, `verbose`, `useMC`, and `analysisData` (list of CLR matrices per sample).

**Probabilistic classification:**

- For fixed `reads`, `conds`, `mc.samples`, and global RNG state, `aldex.clr()` is **probabilistic** because the Monte Carlo instances differ between runs unless the RNG state is reset.
- However, downstream summaries (e.g., averages across MC instances used in effect sizes and tests) are _approximately_ stable for sufficiently large `mc.samples`.

**Reproducibility requirements for Julia translation:**

- Treat `aldex_clr` as a **probabilistic function** in tests:
  - Use **statistical equivalence** criteria against R outputs (e.g., correlation of CLR values, distributional checks across features), not element-wise equality.
- Ensure Julia implementation:
  - Uses a **per-thread or per-task RNG** to support parallel Monte Carlo sampling.
  - Matches R’s Dirichlet parameterization (alpha = counts + prior, with prior=0.5 in current R code).
  - Preserves the same structural layout of `analysisData` (features × MC instances per sample) to keep downstream deterministic functions compatible.

## 2. Deterministic Functions

### 2.1 `aitchison.mean()`

- **Location**: `ALDEx2/R/rdirichlet.r`
- **Role**: Computes expected composition or log-composition given counts.
- **Implementation**: Pure transformation using `digamma` and exponentiation; no RNG calls.
- **Classification**: **Deterministic** – same input vector `n` always yields the same output.
- **Testing requirement**: Use **exact equality** (within numeric tolerance) vs. R reference values in Julia.

### 2.2 Feature Selection Helpers

- **Functions**: `aldex.set.mode()`, `iqlr.features()`, `zero.features()`, `all.features()`, `custom.features()`
- **Location**: `ALDEx2/R/iqlr_features.r`
- **Role**: Determine feature indices used as denominators for CLR/IQLR centering.
- **RNG usage**: None – all logic is based on deterministic transformations (sums, variances, quantiles, condition-wise subsets).
- **Classification**: **Deterministic**.
- **Testing requirement**:
  - Compare **exact index sets** (after harmonizing any trivial ordering differences) between R and Julia.
  - Pay special attention to IQLR quantile boundaries; test with realistic and edge-case datasets.

### 2.3 Statistical Test Helpers

- **Functions**: `t.fast()`, `wilcox.fast()`
- **Location**: `ALDEx2/R/stats.fast.R`
- **Role**: Optimized t-test and Wilcoxon implementations on CLR-transformed Monte Carlo summaries.
- **RNG usage**: None – tests operate on already generated CLR summaries.
- **Classification**: **Deterministic**.
- **Testing requirement**:
  - Use **strict equality** (within numerical tolerance) for test statistics and p-values.
  - Use fixed example inputs from R tests and vignettes.

### 2.4 High-Level Statistical Functions

- **Functions**: `aldex.ttest()`, `aldex.glm()`, `aldex.corr()`
- **Location**:
  - `ALDEx2/R/clr_ttest.r`
  - `ALDEx2/R/clr_glm.r`
  - `ALDEx2/R/clr_corr.R`
- **Role**: Per-feature hypothesis tests and correlation analysis using the `aldex.clr` object.
- **RNG usage**: None – all randomness is encapsulated in the `aldex.clr` object; these functions only perform deterministic operations on its contents.
- **Classification**: **Deterministic given a fixed `aldex.clr` object**.
- **Testing requirement**:
  - Use **exact equality** vs. R outputs for p-values, test statistics, and adjusted p-values when given the same `aldex.clr` object (i.e., using a fixed MC realization).
  - When comparing full pipelines (where `aldex.clr` itself is probabilistic), treat combined workflows as **probabilistic** and validate statistically.

### 2.5 Effect Size Function

- **Function**: `aldex.effect()`
- **Location**: `ALDEx2/R/clr_effect.r`
- **Role**: Compute per-feature effect sizes and abundance summaries from CLR Monte Carlo instances.
- **RNG usage**: None – uses precomputed Monte Carlo instances.
- **Classification**: **Deterministic given a fixed `aldex.clr` object**.
- **Testing requirement**:
  - For a fixed `aldex.clr` object, use **exact equality** (within tolerance) vs. R for effect sizes and summary statistics.
  - For end-to-end pipelines, treat as part of a **probabilistic workflow** and use statistical equivalence.

### 2.6 Main Wrapper

- **Function**: `aldex()`
- **Location**: `ALDEx2/R/aldex.r`
- **Role**: User-facing pipeline wrapper that composes:
  - `aldex.clr()` (probabilistic)
  - `aldex.ttest()` / `aldex.glm()` (deterministic)
  - `aldex.effect()` (deterministic)
- **Classification**:
  - **End-to-end**: `aldex()` is **probabilistic** because it depends on `aldex.clr()`’s Monte Carlo sampling.
  - **Conditioned on `aldex.clr` input**: the remaining part (`aldex.ttest`, `aldex.glm`, `aldex.effect`) is **deterministic**.
- **Testing requirement**:
  - For **unit-level** Julia tests, decouple: test downstream deterministic pieces using a fixed `aldex.clr` object.
  - For **integration tests** (R vs Julia `aldex()`), rely on **distributional/summary metrics** rather than exact equality, unless a fixed saved `aldex.clr` object is shared.

### 2.7 S4 Accessors and Utilities

- **Methods**: `getMonteCarloInstances`, `getSampleIDs`, `getFeatures`, `numFeatures`, `numMCInstances`, `getFeatureNames`, `getReads`, `numConditions`, `getMonteCarloReplicate`.
- **Location**: `ALDEx2/R/clr_function.r` (S4 methods section).
- **Role**: Pure accessors over `aldex.clr` slots.
- **RNG usage**: None.
- **Classification**: **Deterministic**.
- **Testing requirement**: Exact structural equality of returned types and dimensions vs. R.

## 3. TDD and Reproducibility Implications

Based on the above categorization, the TDD workflow from the plan should adopt the following rules:

- **Probabilistic functions (`rdirichlet`, `aldex_clr`, end-to-end `aldex`)**:
  - Use **statistical equivalence** tests (e.g., KS tests, correlation of summaries, comparison of empirical means/variances) rather than element-wise equality.
  - Manage RNG via **per-test seeding** in each language (R and Julia) for reproducibility _within_ language, but do **not** expect identical sequences across languages.
- **Deterministic functions (`aitchison_mean`, feature selectors, statistical tests, effect sizes, accessors)**:
  - Use **strict equality** (within floating-point tolerance) against R reference outputs.
  - Generate and store reference values in Phase 0/Phase 1 scripts for reuse in Julia tests.

This document completes Phase 0 · Week 1 · Section 3 (“Function Categorization”) by explicitly labeling all ALDEx2 core functions as **probabilistic** or **deterministic** and stating their reproducibility and testing requirements for the Julia translation.





