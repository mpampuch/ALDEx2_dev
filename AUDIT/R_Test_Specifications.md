# R Test Specifications

**Date:** 2025-01-27  
**Package Version:** 1.8.1  
**Phase:** Phase 0, Week 1 - Test Specifications Extraction

## Executive Summary

This document extracts test cases from the ALDEx2 R package test suite, documenting expected outputs for deterministic functions, statistical validation criteria for probabilistic functions, edge cases, and reference values. These specifications will guide the Julia implementation and validation.

## Test Coverage Overview

**Total Test Files:** 3

- `test-aldex.ttest.R` - t-test and Wilcoxon tests
- `test-aldex.glm.R` - GLM and Kruskal-Wallis tests
- `test-stats.fast.R` - Fast statistical function validation

**Overall Coverage:** ~15-20% of functions (see `Test_Coverage_Report.md`)

## Test Data

### Primary Test Datasets

1. **selex dataset** (from ALDEx2 package)

   - Standard: 100 features × 14 samples
   - Extended: 100 features × 20 samples (with 6 fake columns)
   - Usage: Primary test dataset for most tests

## Test Specifications by Function

### 1. `aldex.ttest()` - Statistical Tests

**Test File:** `tests/testthat/test-aldex.ttest.R`

#### Test Case 1: Standard selex Dataset

**Input:**

```r
data(selex)
group <- c(rep("A", 7), rep("B", 7))
clr <- ALDEx2::aldex.clr(selex[1:100,], group, mc.samples = 128)
```

**Test:**

```r
test_that("new faster alex.ttest matches old function", {
  expect_equal(
    aldex.ttest.old(clr, group),
    aldex.ttest(clr, group)
  )
})
```

**Expected Output:**

- `data.frame` with columns: `we.ep`, `we.eBH`, `wi.ep`, `wi.eBH`
- Rows: 100 (one per feature)
- Row names: Feature names from `selex`
- Values: P-values and Benjamini-Hochberg adjusted p-values for Welch's t-test and Wilcoxon test

**Validation Criteria:**

- **Deterministic:** Exact equality (within floating-point tolerance) when using same `aldex.clr` object
- **Structure:** Same dimensions and column names as old implementation
- **Values:** P-values match old implementation exactly

**Notes:**

- Uses old implementation (`aldex.ttest.old`) as reference
- Tests both Welch's t-test (`we.*`) and Wilcoxon test (`wi.*`)
- Tests both unadjusted (`*.ep`) and BH-adjusted (`*.eBH`) p-values

---

#### Test Case 2: Extended selex Dataset

**Input:**

```r
data(selex)
dat <- selex
for(i in 1:6){
  fakecol <- data.frame(sample(selex[,1]))
  colnames(fakecol) <- paste0("fake", i)
  dat <- as.data.frame(cbind(dat, fakecol))
}
group <- c(rep("A", 10), rep("B", 10))
clr <- ALDEx2::aldex.clr(dat[1:100,], group, mc.samples = 128)
```

**Test:**

```r
test_that("new faster alex.ttest matches old function", {
  expect_equal(
    aldex.ttest.old(clr, group),
    aldex.ttest(clr, group)
  )
})
```

**Expected Output:**

- Same structure as Test Case 1
- 100 rows (features)
- 4 columns: `we.ep`, `we.eBH`, `wi.ep`, `wi.eBH`

**Validation Criteria:**

- Exact equality with old implementation
- Handles extended dataset with additional columns

**Notes:**

- Tests robustness with additional columns
- Validates that function handles varying sample counts

---

### 2. `aldex.glm()` - GLM and Kruskal-Wallis Tests

**Test File:** `tests/testthat/test-aldex.glm.R`

#### Test Case 1: Consistency with t-test

**Input:**

```r
set.seed(1)
data(selex)
group <- c(rep("A", 7), rep("B", 7))
tt <- aldex(selex[1:10,], group, test = "t", mc.samples = 128)
gm <- aldex(selex[1:10,], group, test = "glm", mc.samples = 128)
```

**Test:**

```r
test_that("aldex.glm function runs grossly intact", {
  expect_equal(
    tt$wi.eBH < .05,
    gm$kw.eBH < .05
  )

  expect_equal(
    rownames(tt),
    rownames(gm)
  )
})
```

**Expected Output:**

- `tt`: Results from `aldex()` with `test = "t"`
- `gm`: Results from `aldex()` with `test = "glm"`
- Both should have same row names
- Significance flags (`< .05`) should match between Wilcoxon (`wi.eBH`) and Kruskal-Wallis (`kw.eBH`)

**Validation Criteria:**

- **Consistency:** Significance flags should match between t-test and GLM results
- **Structure:** Row names should be identical
- **Statistical:** Kruskal-Wallis p-values should be consistent with Wilcoxon p-values

**Notes:**

- Only tests consistency, not absolute correctness
- Uses subset of selex (10 features) for faster execution
- Tests `aldex()` wrapper, not `aldex.glm()` directly

**Gaps:**

- No direct comparison with reference implementation
- No tests for GLM coefficients
- No tests for different condition structures
- No tests for Kruskal-Wallis component explicitly

---

### 3. `t.fast()` - Fast t-test Implementation

**Test File:** `tests/testthat/test-stats.fast.R`

#### Test Case 1: Standard selex Dataset (Unpaired)

**Input:**

```r
data(selex)
group <- c(rep("A", 7), rep("B", 7))
clr <- ALDEx2::aldex.clr(selex, group, mc.samples = 128)
conditions <- group
conditions <- as.factor(conditions)
setA <- which(conditions == "A")
setB <- which(conditions == "B")
mc.all <- getMonteCarloInstances(clr)
t.input <- sapply(mc.all, function(y){y[, 1]})
```

**Test:**

```r
test_that("t.fast gives same result as t.test", {
  expect_equivalent(
    as.vector(apply(t.input, 1, function(i){
      t.test(x=i[setA],y=i[setB], paired = FALSE)$p.value})),
    ALDEx2:::t.fast(t.input, group, paired = FALSE)
  )
})
```

**Expected Output:**

- Vector of p-values (one per feature)
- Length: Number of features (100 for selex)
- Values: Should match `t.test()` p-values exactly

**Validation Criteria:**

- **Exact Equality:** P-values should match `t.test()` exactly (within floating-point tolerance)
- **Length:** Should match number of features

**Notes:**

- Tests unpaired t-test
- Uses first MC instance (`[, 1]`)
- Compares against base R `t.test()`

---

#### Test Case 2: Standard selex Dataset (Paired)

**Input:** Same as Test Case 1

**Test:**

```r
test_that("t.fast gives same result as t.test", {
  expect_equivalent(
    as.vector(apply(t.input, 1, function(i){
      t.test(x=i[setA],y=i[setB], paired = TRUE)$p.value})),
    ALDEx2:::t.fast(t.input, group, paired = TRUE)
  )
})
```

**Expected Output:**

- Vector of p-values for paired t-test
- Should match `t.test(paired = TRUE)` exactly

**Validation Criteria:**

- Exact equality with base R `t.test(paired = TRUE)`

---

#### Test Case 3: Extended selex Dataset (Unpaired and Paired)

**Input:**

```r
data(selex)
dat <- selex
for(i in 1:6){
  fakecol <- data.frame(sample(selex[,1]))
  colnames(fakecol) <- paste0("fake", i)
  dat <- as.data.frame(cbind(dat, fakecol))
}
group <- c(rep("A", 10), rep("B", 10))
clr <- ALDEx2::aldex.clr(dat, group, mc.samples = 128)
# ... setup similar to Test Case 1
```

**Test:**

- Same tests as Test Case 1 and 2, but with extended dataset

**Expected Output:**

- Same structure, but with more samples (20 total)

**Validation Criteria:**

- Exact equality with base R `t.test()`
- Handles different sample sizes

---

### 4. `wilcox.fast()` - Fast Wilcoxon Test Implementation

**Test File:** `tests/testthat/test-stats.fast.R`

#### Test Case 1: Standard selex Dataset (Exact, Unpaired)

**Input:** Same as `t.fast()` Test Case 1

**Test:**

```r
test_that("wilcox.fast gives same result as wilcox.test (exact)", {
  expect_equivalent(
    as.vector(apply(t.input, 1, function(i){
      wilcox.test(x=i[setA],y=i[setB], paired = FALSE, exact = TRUE)$p.value})),
    ALDEx2:::wilcox.fast(t.input, group, paired = FALSE)
  )
})
```

**Expected Output:**

- Vector of p-values (one per feature)
- Should match `wilcox.test(exact = TRUE)` exactly

**Validation Criteria:**

- Exact equality with base R `wilcox.test(exact = TRUE)`

**Notes:**

- Tests exact Wilcoxon test (no normal approximation)

---

#### Test Case 2: Standard selex Dataset (Exact, Paired)

**Input:** Same as Test Case 1

**Test:**

```r
test_that("wilcox.fast gives same result as wilcox.test (exact)", {
  expect_equivalent(
    apply(t.input, 1, function(i){
      wilcox.test(x=i[setA],y=i[setB], paired = TRUE, exact = TRUE)$p.value}),
    ALDEx2:::wilcox.fast(t.input, group, paired = TRUE)
  )
})
```

**Expected Output:**

- Vector of p-values for paired Wilcoxon test
- Should match `wilcox.test(paired = TRUE, exact = TRUE)` exactly

---

#### Test Case 3: Extended selex Dataset (Exact, Unpaired and Paired)

**Input:** Same as `t.fast()` Test Case 3

**Test:**

- Same tests as Test Case 1 and 2, but with extended dataset

**Validation Criteria:**

- Exact equality with base R `wilcox.test(exact = TRUE)`

---

#### Test Case 4: Tied Data (Normal Approximation)

**Input:** Same as `t.fast()` Test Case 3 (extended selex dataset), but with tied values introduced:

```r
t.input[1:2, 1:3] <- t.input[1:2, 1]
t.input[1:2, 51:53] <- t.input[1:2, 51]
```

**Test:**

```r
test_that("wilcox.fast gives same result as wilcox.test (given ties)", {
  expect_equivalent(
    as.vector(apply(t.input, 1, function(i){
      wilcox.test(x=i[setA],y=i[setB], paired = FALSE, correct = FALSE)$p.value})),
    ALDEx2:::wilcox.fast(t.input, group, paired = FALSE)
  )

  expect_equivalent(
    apply(t.input, 1, function(i){
      wilcox.test(x=i[setA],y=i[setB], paired = TRUE, correct = FALSE)$p.value}),
    ALDEx2:::wilcox.fast(t.input, group, paired = TRUE)
  )
})
```

**Expected Output:**

- Vector of p-values handling tied data
- Should match `wilcox.test()` with ties exactly

**Validation Criteria:**

- Exact equality with base R `wilcox.test()` when ties are present
- Tests tie-handling logic

**Notes:**

- Important edge case: tied values in data
- Tests both unpaired and paired cases with ties

---

## Statistical Validation Criteria

### Deterministic Functions

For deterministic functions (given fixed inputs), use **exact equality** tests:

**Functions:**

- `t.fast()` - Exact p-value matching
- `wilcox.fast()` - Exact p-value matching
- `aitchison.mean()` - Exact numerical results
- Feature selection functions - Exact index sets
- Statistical tests on fixed CLR data - Exact p-values

**Tolerance:**

- Floating-point tolerance: `1e-10` for most operations
- May need tighter tolerance for some operations: `1e-15`

**Test Pattern:**

```julia
@test isapprox(julia_result, r_reference, rtol=1e-10)
```

---

### Probabilistic Functions

For probabilistic functions (using random number generation), use **statistical equivalence** tests:

**Functions:**

- `rdirichlet()` - Distributional equivalence
- `aldex.clr()` - Statistical equivalence of CLR values
- End-to-end `aldex()` - Distributional equivalence of summaries

**Validation Methods:**

1. **Kolmogorov-Smirnov Test:**

   - Compare distributions of outputs
   - Null hypothesis: Distributions are the same
   - Accept if p-value > 0.05

2. **Correlation Test:**

   - Compare correlation of outputs
   - High correlation (> 0.95) indicates equivalence

3. **Moment Comparison:**

   - Compare means and variances
   - Should match within tolerance

4. **Reproducibility:**
   - Use fixed seeds in each language
   - R seed ensures R reproducibility
   - Julia seed ensures Julia reproducibility
   - **Note:** R and Julia use different RNGs, so same seed values won't produce same sequences

**Test Pattern:**

```julia
# Generate multiple samples with fixed seed
rng_julia = MersenneTwister(seed_julia)
julia_samples = [rdirichlet(rng_julia, alpha) for _ in 1:n_samples]

# Compare distributions
ks_statistic = ks_test(julia_samples, r_reference_samples)
@test ks_statistic.p_value > 0.05
```

---

## Edge Cases Identified

### Missing from R Tests (Should be Added)

1. **Empty Datasets:**

   - Zero features
   - Zero samples
   - Empty matrices

2. **Single Sample Scenarios:**

   - Single sample per condition
   - Cannot perform two-sample tests

3. **All-Zero Datasets:**

   - All counts are zero
   - Division by zero issues

4. **Single Feature:**

   - Only one feature
   - Edge case for feature selection

5. **Very Sparse Data:**

   - Many zeros
   - Zero-inflated scenarios

6. **Invalid Inputs:**

   - Negative values
   - Non-integer counts
   - Missing values (NA)
   - Mismatched dimensions

7. **Boundary Conditions:**

   - Very small counts (1, 2)
   - Very large counts
   - Extreme ratios

8. **Unbalanced Conditions:**
   - Very different sample sizes
   - Single sample in one condition

---

## Reference Values

### Deterministic Functions - Expected Outputs

#### `aitchison.mean()`

**Test Case 1: Simple Compositional Vector**

```r
# Input
n <- c(10, 20, 30, 40)

# Expected output (approximate)
# Aitchison mean using digamma transformation
# Should match R implementation exactly
```

**Test Case 2: Multi-feature Matrix**

```r
# Input: Matrix with known expected values
# Expected: Aitchison mean per feature
```

#### Feature Selection Functions

**Test Case: IQLR Feature Selection**

```r
# Input: selex dataset
# Expected: Feature indices within IQLR range
# Validation: Compare index sets (order may differ)
```

---

### Probabilistic Functions - Statistical Properties

#### `rdirichlet()`

**Statistical Properties:**

- Samples sum to 1 (simplex constraint)
- Each component > 0
- Mean of component i: `alpha[i] / sum(alpha)`
- Variance of component i: `alpha[i] * (sum(alpha) - alpha[i]) / (sum(alpha)^2 * (sum(alpha) + 1))`

**Validation:**

- Check simplex constraint: `sum(sample) ≈ 1.0`
- Compare empirical means to theoretical means
- Compare empirical variances to theoretical variances
- Use KS test for distributional equivalence

#### `aldex.clr()`

**Statistical Properties:**

- CLR values should be centered (mean ≈ 0)
- Distribution should match R implementation
- Correlation with R CLR values should be high (> 0.95)

**Validation:**

- Compare CLR value distributions using KS test
- Check correlation of CLR values
- Compare summary statistics (mean, variance)

---

## Test Data Specifications

### selex Dataset

**Source:** ALDEx2 package (`data(selex)`)

**Dimensions:**

- Standard: 100 features × 14 samples
- Extended: 100 features × 20 samples (with fake columns)

**Characteristics:**

- Count data (non-negative integers)
- Typical microbiome/metagenomics dataset
- Used as primary test dataset

**Usage:**

- Primary test dataset for most functions
- Subset to 10 features for faster GLM tests
- Extended with fake columns for robustness testing

---

## Test Gaps and Recommendations

### Critical Gaps

1. **`aldex()` wrapper function:**

   - Only 2 parameter combinations tested
   - Missing: `test="iterative"`, `effect=TRUE`, different `denom` values
   - **Action:** Create comprehensive test suite

2. **`aldex.effect()` function:**

   - No tests at all
   - **Action:** Create test suite with reference values

3. **`aldex.clr()` function:**

   - No direct tests
   - **Action:** Create direct unit tests

4. **`aldex.corr()` function:**

   - No tests at all
   - **Action:** Create test suite

5. **Feature selection functions:**
   - No tests for `iqlr.features()`, `zero.features()`, `custom.features()`
   - **Action:** Create test suite for all modes

### Edge Case Gaps

1. **Error handling:**

   - No tests for invalid inputs
   - **Action:** Add error handling tests

2. **Boundary conditions:**

   - No tests for extreme values
   - **Action:** Add boundary condition tests

3. **Empty/sparse data:**
   - No tests for edge cases
   - **Action:** Add edge case tests

---

## Implementation Recommendations for Julia

### Test Structure

1. **Unit Tests (Julia):**

   - Test each function independently
   - Use reference values from R
   - Test deterministic functions with exact equality
   - Test probabilistic functions with statistical equivalence

2. **Parallel Tests (R ↔ Julia):**

   - Call both R and Julia versions with same inputs
   - Compare outputs using appropriate criteria
   - Use helper functions from `helper-parallel_test.R` and `helper-validation.R`

3. **Integration Tests:**
   - Test complete workflows
   - Test with real datasets
   - Validate end-to-end results

### Reference Value Generation

1. **Deterministic Functions:**

   - Generate reference values using R
   - Save to `test/data/reference_values/`
   - Use in Julia tests for exact comparison

2. **Probabilistic Functions:**
   - Generate multiple samples with fixed seeds
   - Save summary statistics (mean, variance, distribution)
   - Use in Julia tests for statistical comparison

### Test Data Management

1. **Test Data Directory:**

   - Create `test/data/` directory
   - Store test datasets (selex, synthetic data)
   - Store reference values

2. **Synthetic Test Data:**
   - Generate edge case datasets
   - All zeros, single sample, single feature, etc.
   - Document characteristics

---

## References

- Test Coverage Report: `AUDIT/Test_Coverage_Report.md`
- Test Coverage Summary: `AUDIT/Test_Coverage_Summary.md`
- Function Categorization: `AUDIT/Function_Categorization.md`
- R Test Files: `ALDEx2/tests/testthat/test-*.R`
- Individual Function Tests: `AUDIT/<function_name>/tests.md`
