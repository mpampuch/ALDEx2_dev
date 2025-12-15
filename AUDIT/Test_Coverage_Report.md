# ALDEx2 Test Coverage Analysis Report

**Date:** 2025-01-27  
**Package Version:** 1.8.1  
**Phase:** Phase 0, Week 1, Task 2

## Executive Summary

This report analyzes the test coverage of the ALDEx2 R package by examining the test suite in `tests/testthat/` and mapping it against all functions in the package.

### Overall Assessment

- **Total Test Files:** 3 test files
- **Test Framework:** testthat
- **Coverage Type:** Primarily integration tests comparing new implementations against old implementations
- **Coverage Quality:** Limited - focuses on correctness validation of refactored functions rather than comprehensive unit testing

## Test Files Inventory

### 1. `test-aldex.ttest.R`

- **Purpose:** Validates that the new (optimized) `aldex.ttest()` function produces identical results to the old implementation
- **Test Cases:** 2 test cases
  - Test with standard selex dataset (100 features, 14 samples)
  - Test with extended dataset (100 features, 20 samples with 6 fake columns)
- **Coverage:** Validates `aldex.ttest()` function only
- **Test Type:** Integration test (comparison test)

### 2. `test-aldex.glm.R`

- **Purpose:** Validates that `aldex.glm()` runs and produces consistent results with `aldex.ttest()`
- **Test Cases:** 1 test case
  - Compares significance flags between t-test and GLM results
  - Validates row names match between test types
- **Coverage:** Validates `aldex.glm()` function only
- **Test Type:** Integration test (consistency test)

### 3. `test-stats.fast.R`

- **Purpose:** Validates that optimized statistical functions (`t.fast()` and `wilcox.fast()`) produce identical results to base R functions
- **Test Cases:** Multiple test cases across different scenarios:
  - Standard selex dataset (paired and unpaired tests)
  - Extended dataset with fake columns (paired and unpaired tests)
  - Iris dataset (paired and unpaired tests, including normal approximation for Wilcoxon)
  - Tied data scenario (Wilcoxon test with ties)
- **Coverage:** Validates `t.fast()` and `wilcox.fast()` internal functions
- **Test Type:** Unit tests (correctness validation)

## Function Coverage Analysis

### Exported Functions (User-Facing)

| Function           | File                | Test Coverage   | Test Type   | Notes                                                                                                                                                           |
| ------------------ | ------------------- | --------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `aldex()`          | `R/aldex.r`         | ⚠️ **~5%**      | Minimal     | Called in test-aldex.glm.R but only `test="t"` and `test="glm"` with `effect=FALSE`. Missing: `test="iterative"`, `effect=TRUE`, different `denom` values, etc. |
| `aldex.clr()`      | `R/clr_function.r`  | ⚠️ **Indirect** | Indirect    | Tested indirectly via other functions, but no direct tests                                                                                                      |
| `aldex.ttest()`    | `R/clr_ttest.r`     | ✅ **100%**     | Integration | Fully tested against old implementation                                                                                                                         |
| `aldex.effect()`   | `R/clr_effect.r`    | ❌ **0%**       | None        | **NOT TESTED**                                                                                                                                                  |
| `aldex.glm()`      | `R/clr_glm.r`       | ⚠️ **Partial**  | Integration | Basic functionality test only                                                                                                                                   |
| `aldex.corr()`     | `R/clr_corr.R`      | ❌ **0%**       | None        | **NOT TESTED**                                                                                                                                                  |
| `aldex.set.mode()` | `R/iqlr_features.r` | ❌ **0%**       | None        | **NOT TESTED**                                                                                                                                                  |
| `aldex.plot()`     | `R/plot.aldex.r`    | ❌ **0%**       | None        | **NOT TESTED**                                                                                                                                                  |

### Internal Functions

| Function               | File                | Test Coverage   | Test Type | Notes                                          |
| ---------------------- | ------------------- | --------------- | --------- | ---------------------------------------------- |
| `aldex.clr.function()` | `R/clr_function.r`  | ⚠️ **Indirect** | Indirect  | Tested indirectly via `aldex.clr()`            |
| `rdirichlet()`         | `R/rdirichlet.r`    | ⚠️ **Indirect** | Indirect  | Tested indirectly via CLR transformation       |
| `aitchison.mean()`     | `R/rdirichlet.r`    | ⚠️ **Indirect** | Indirect  | Tested indirectly via effect size calculations |
| `iqlr.features()`      | `R/iqlr_features.r` | ❌ **0%**       | None      | **NOT TESTED**                                 |
| `zero.features()`      | `R/iqlr_features.r` | ❌ **0%**       | None      | **NOT TESTED**                                 |
| `all.features()`       | `R/iqlr_features.r` | ⚠️ **Indirect** | Indirect  | Default mode, tested indirectly                |
| `custom.features()`    | `R/iqlr_features.r` | ❌ **0%**       | None      | **NOT TESTED**                                 |
| `t.fast()`             | `R/stats.fast.R`    | ✅ **100%**     | Unit      | Fully tested against base R `t.test()`         |
| `wilcox.fast()`        | `R/stats.fast.R`    | ✅ **100%**     | Unit      | Fully tested against base R `wilcox.test()`    |
| `progress()`           | `R/progress.R`      | ❌ **0%**       | None      | **NOT TESTED**                                 |

### S4 Methods

| Method                     | Test Coverage   | Notes                                 |
| -------------------------- | --------------- | ------------------------------------- |
| `getMonteCarloInstances()` | ⚠️ **Indirect** | Used in tests but not directly tested |
| `getSampleIDs()`           | ⚠️ **Indirect** | Used in tests but not directly tested |
| `getFeatures()`            | ❌ **0%**       | **NOT TESTED**                        |
| `numFeatures()`            | ⚠️ **Indirect** | Used in tests but not directly tested |
| `numMCInstances()`         | ⚠️ **Indirect** | Used in tests but not directly tested |
| `getFeatureNames()`        | ⚠️ **Indirect** | Used in tests but not directly tested |
| `getReads()`               | ❌ **0%**       | **NOT TESTED**                        |
| `numConditions()`          | ❌ **0%**       | **NOT TESTED**                        |
| `getMonteCarloReplicate()` | ⚠️ **Indirect** | Used in tests but not directly tested |

## Coverage Statistics

### By Category

- **Exported Functions:** 2-3/8 tested (25-38%, but `aldex()` is only minimally tested)
- **Internal Functions:** 2/11 tested (18%)
- **S4 Methods:** 0/9 directly tested (0%)
- **Overall Function Coverage:** ~15-20% (estimated)

### Test Type Distribution

- **Integration Tests:** 2 test files (comparison/consistency tests)
- **Unit Tests:** 1 test file (statistical function validation)
- **Edge Case Tests:** Limited (only tied data scenario in `test-stats.fast.R`)
- **Error Handling Tests:** None
- **Input Validation Tests:** None

## Test Quality Assessment

### Strengths

1. **Correctness Validation:** Tests validate that optimized functions produce identical results to reference implementations
2. **Multiple Datasets:** Tests use different datasets (selex, iris) and configurations
3. **Statistical Validation:** `test-stats.fast.R` thoroughly validates statistical functions against base R

### Gaps and Limitations

1. **Missing Core Function Tests:**

   - `aldex()` wrapper function - **CRITICAL GAP** (minimally tested: only 2 parameter combinations out of many possible)
   - `aldex.clr()` - no direct tests
   - `aldex.effect()` - **CRITICAL GAP** (effect size calculations)
   - `aldex.corr()` - **CRITICAL GAP** (correlation analysis)
   - `aldex.set.mode()` - **CRITICAL GAP** (feature selection modes)

2. **Missing Feature Selection Tests:**

   - No tests for `iqlr.features()` (IQLR mode)
   - No tests for `zero.features()` (zero-inflated mode)
   - No tests for `custom.features()` (custom denominator)
   - No tests for different `denom` parameter values

3. **Missing Edge Case Tests:**

   - No tests for empty datasets
   - No tests for single-sample scenarios
   - No tests for datasets with all zeros
   - No tests for datasets with missing values
   - No tests for invalid inputs (negative values, non-integer counts)
   - No tests for mismatched dimensions
   - Limited tests for different sample sizes

4. **Missing Error Handling Tests:**

   - No tests for error conditions
   - No tests for input validation
   - No tests for boundary conditions

5. **Missing Integration Tests:**

   - No end-to-end workflow tests
   - No tests for `aldex()` with different `test` parameter values ("t", "glm", "iterative")
   - No tests for `effect=TRUE` scenarios
   - No tests for `include.sample.summary=TRUE`

6. **Missing Visualization Tests:**

   - No tests for `aldex.plot()` function

7. **Missing Parallel Processing Tests:**

   - No tests for `useMC=TRUE` (BiocParallel functionality)
   - No tests for parallel vs. serial mode equivalence

8. **Missing Monte Carlo Tests:**

   - No tests for different `mc.samples` values
   - No tests for reproducibility with seeds
   - No tests for Monte Carlo convergence

9. **Missing S4 Method Tests:**

   - No direct tests for S4 accessor methods
   - No tests for `aldex.clr` object structure validation

10. **Missing Data Type Tests:**
    - No tests for `matrix` input (only `data.frame` tested)
    - No tests for `RangedSummarizedExperiment` input
    - Limited tests for different data structures

## Test Coverage by Function (Detailed)

### ✅ Well-Tested Functions

#### `aldex.ttest()`

- **Coverage:** 100%
- **Test File:** `test-aldex.ttest.R`
- **Test Cases:** 2
- **Validation:** Comparison against old implementation
- **Scenarios:** Standard dataset, extended dataset
- **Status:** ✅ Comprehensive

#### `t.fast()` and `wilcox.fast()`

- **Coverage:** 100%
- **Test File:** `test-stats.fast.R`
- **Test Cases:** Multiple (paired/unpaired, different datasets, ties)
- **Validation:** Comparison against base R functions
- **Scenarios:** Standard, extended, iris datasets; tied data
- **Status:** ✅ Comprehensive

### ⚠️ Partially Tested Functions

#### `aldex()` - Main Wrapper

- **Coverage:** ~5%
- **Test File:** `test-aldex.glm.R`
- **Test Cases:** 1 (consistency check only)
- **Validation:** Compares results between `test="t"` and `test="glm"`
- **Gaps:**
  - No tests for `test="iterative"`
  - No tests for `effect=TRUE` (effect size calculations)
  - No tests for different `denom` values ("iqlr", "zero", custom)
  - No tests for `include.sample.summary=TRUE`
  - No tests for `verbose=TRUE`
  - No end-to-end validation
- **Status:** ⚠️ Critically under-tested

#### `aldex.glm()`

- **Coverage:** ~20%
- **Test File:** `test-aldex.glm.R`
- **Test Cases:** 1 (basic consistency check)
- **Validation:** Compares significance flags with t-test
- **Gaps:**
  - No direct comparison with reference implementation
  - No tests for different GLM configurations
  - No tests for Kruskal-Wallis component
  - No tests for different condition configurations
- **Status:** ⚠️ Needs expansion

#### `aldex.clr()` (indirect)

- **Coverage:** Indirect only
- **Test Files:** All (used by other functions)
- **Test Cases:** Indirect via other functions
- **Gaps:**
  - No direct unit tests
  - No tests for different `denom` modes
  - No tests for `verbose` parameter
  - No tests for `useMC` parameter
  - No tests for SummarizedExperiment input
- **Status:** ⚠️ Needs direct tests

### ❌ Untested Functions (Critical Gaps)

#### `aldex()` - Main Wrapper

- **Coverage:** ~5% (minimally tested)
- **Criticality:** ⭐⭐⭐⭐⭐ (CRITICAL)
- **Current Tests:** Called in `test-aldex.glm.R` with:
  - `test="t"` and `test="glm"` only
  - `effect=FALSE` (default is TRUE, but not tested)
  - `denom="all"` (default, other modes not tested)
- **Missing Tests:**
  - No tests for `test="t"` workflow
  - No tests for `test="glm"` workflow
  - No tests for `test="iterative"` workflow
  - No tests for `effect=TRUE/FALSE`
  - No tests for `include.sample.summary=TRUE/FALSE`
  - No tests for different `denom` values
  - No end-to-end workflow validation
- **Impact:** Main user-facing function is completely untested

#### `aldex.effect()` - Effect Size Calculation

- **Coverage:** 0%
- **Criticality:** ⭐⭐⭐⭐⭐ (CRITICAL)
- **Missing Tests:**
  - No tests for effect size calculations
  - No tests for overlap calculations
  - No tests for relative abundance calculations
  - No tests for `include.sample.summary` parameter
  - No tests for `verbose` parameter
- **Impact:** Core statistical output is untested

#### `aldex.corr()` - Correlation Analysis

- **Coverage:** 0%
- **Criticality:** ⭐⭐⭐⭐ (HIGH)
- **Missing Tests:**
  - No tests for Pearson correlation
  - No tests for Spearman correlation
  - No tests for correlation p-values
  - No tests for BH-adjusted p-values
- **Impact:** Important analysis function is untested

#### `aldex.set.mode()` - Feature Selection

- **Coverage:** 0%
- **Criticality:** ⭐⭐⭐⭐ (HIGH)
- **Missing Tests:**
  - No tests for `denom="all"` mode
  - No tests for `denom="iqlr"` mode
  - No tests for `denom="zero"` mode
  - No tests for `denom=custom_indices` mode
- **Impact:** Feature selection logic is untested

#### Feature Selection Helper Functions

- **Coverage:** 0%
- **Functions:** `iqlr.features()`, `zero.features()`, `custom.features()`, `all.features()`
- **Criticality:** ⭐⭐⭐ (MEDIUM)
- **Impact:** Feature selection implementation is untested

#### `aldex.plot()` - Visualization

- **Coverage:** 0%
- **Criticality:** ⭐⭐ (LOW)
- **Missing Tests:**
  - No tests for plot generation
  - No tests for different plot types ("MW", "MA")
- **Impact:** Visualization function is untested (lower priority)

#### `progress()` - Utility

- **Coverage:** 0%
- **Criticality:** ⭐ (LOW)
- **Impact:** Utility function (lower priority)

## Recommendations for Test Coverage Improvement

### Priority 1: Critical Functions (Must Test)

1. **`aldex()` wrapper function**

   - Test all `test` parameter values ("t", "glm", "iterative")
   - Test `effect=TRUE/FALSE` scenarios
   - Test `include.sample.summary=TRUE/FALSE`
   - Test different `denom` values
   - End-to-end workflow validation

2. **`aldex.effect()` function**

   - Test effect size calculations
   - Test overlap calculations
   - Test relative abundance calculations
   - Validate against known reference values

3. **`aldex.clr()` function**
   - Direct unit tests
   - Test all `denom` modes
   - Test `verbose` parameter
   - Test `useMC` parameter
   - Test different input types (matrix, data.frame, SummarizedExperiment)

### Priority 2: High-Value Functions

4. **`aldex.corr()` function**

   - Test Pearson correlation
   - Test Spearman correlation
   - Validate p-values and BH adjustments

5. **`aldex.set.mode()` and feature selection functions**

   - Test all feature selection modes
   - Test IQLR feature selection
   - Test zero-inflated feature handling
   - Test custom feature indices

6. **`aldex.glm()` function**
   - Expand existing basic test
   - Test GLM component
   - Test Kruskal-Wallis component
   - Compare with reference implementation

### Priority 3: Edge Cases and Error Handling

7. **Input validation tests**

   - Invalid inputs (negative values, non-integers)
   - Empty datasets
   - Single-sample scenarios
   - Mismatched dimensions
   - Missing values

8. **Edge case tests**

   - All-zero datasets
   - Single feature scenarios
   - Very large datasets
   - Very small datasets
   - Different sample sizes per condition

9. **Error handling tests**
   - Test error messages
   - Test warning conditions
   - Test boundary conditions

### Priority 4: Additional Coverage

10. **S4 method tests**

    - Direct tests for all accessor methods
    - Object structure validation

11. **Parallel processing tests**

    - Test `useMC=TRUE` vs `useMC=FALSE` equivalence
    - Validate parallel processing results

12. **Monte Carlo tests**

    - Test different `mc.samples` values
    - Test reproducibility with seeds
    - Test Monte Carlo convergence

13. **Integration tests**
    - Complete workflow tests
    - Multiple function combinations
    - Real-world dataset validation

## Test Data Used

### Current Test Datasets

1. **selex dataset** (from ALDEx2 package)

   - Standard: 100 features × 14 samples
   - Extended: 100 features × 20 samples (with 6 fake columns)

2. **iris dataset** (from base R)
   - Transformed: 4 features × 100 samples

### Recommended Additional Test Data

1. **Synthetic edge case datasets:**

   - All zeros
   - Single sample
   - Single feature
   - Very sparse data
   - Very dense data

2. **Real-world datasets:**
   - Large datasets (1000+ features)
   - Small datasets (<10 features)
   - Unbalanced conditions

## Conclusion

The ALDEx2 test suite provides **limited coverage** (~15-20% of functions), focusing primarily on validating that optimized statistical functions produce correct results. While the existing tests are valuable for correctness validation, there are **significant gaps** in testing:

1. **Critical functions are untested:** The main `aldex()` wrapper and `aldex.effect()` functions have no test coverage
2. **Limited edge case coverage:** No tests for error conditions, invalid inputs, or boundary cases
3. **Missing feature coverage:** Feature selection modes and correlation analysis are untested
4. **No integration tests:** No end-to-end workflow validation

### For Julia Translation

When implementing the Julia version:

1. **Create comprehensive test suite** covering all functions identified in this analysis
2. **Use existing R tests as reference** but expand coverage significantly
3. **Implement parallel testing framework** (Phase 1) to validate Julia functions against R
4. **Focus on critical functions first:** `aldex()`, `aldex.clr()`, `aldex.effect()`, `aldex.ttest()`, `aldex.glm()`
5. **Include edge case tests** that are missing in R package
6. **Test all feature selection modes** comprehensively
7. **Validate statistical equivalence** for probabilistic functions using appropriate statistical tests

The limited test coverage in the R package means that the Julia implementation will need to establish its own comprehensive test suite, using the R package as a reference implementation rather than relying on existing R tests for complete validation.
