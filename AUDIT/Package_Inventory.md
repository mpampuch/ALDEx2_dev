# ALDEx2 R Package - Complete Inventory

**Date:** 2024  
**Package Version:** 1.8.1  
**Location:** `/Users/markpampuch/Dropbox/KAUST/PhD/ALDEx2_jl/ALDEx2_dev/ALDEx2/`

## Package Overview

**Package Name:** ALDEx2  
**Title:** Analysis Of Differential Abundance Taking Sample Variation Into Account  
**Version:** 1.8.1  
**Date:** 2017-03-27  
**Authors:** Greg Gloor, Ruth Grace Wong, Andrew Fernandes, Arianne Albert, Matt Links, Thomas Quinn, Jia Rong Wu  
**Maintainer:** Greg Gloor <ggloor@uwo.ca>

**Description:** A differential abundance analysis for the comparison of two or more conditions. Useful for analyzing data from standard RNA-seq or meta-RNA-seq assays as well as selected and unselected values from in-vitro sequence selections. Uses a Dirichlet-multinomial model to infer abundance from counts, optimized for three or more experimental replicates.

## Package Structure

```
ALDEx2/
├── DESCRIPTION          # Package metadata and dependencies
├── NAMESPACE           # Exported functions and imports
├── LICENSE             # License file
├── NEWS                # Package changelog
├── R/                  # Core R source files (13 files)
│   ├── aldex.r                    # Main wrapper function
│   ├── clr_function.r            # CLR transformation core
│   ├── clr_ttest.r               # t-test and Wilcoxon tests
│   ├── clr_effect.r              # Effect size calculations
│   ├── clr_glm.r                 # GLM and Kruskal-Wallis tests
│   ├── clr_corr.R                # Correlation analysis
│   ├── rdirichlet.r              # Dirichlet distribution sampling
│   ├── iqlr_features.r           # Feature selection (IQLR, zero, all)
│   ├── plot.aldex.r              # Plotting functions
│   ├── stats.fast.R              # Fast statistical test implementations
│   ├── AllClasses.R              # S4 class definitions
│   ├── AllGenerics.R             # S4 generic function definitions
│   └── progress.R                # Progress bar utility
├── man/                # Documentation (18 .Rd files)
├── tests/              # Test suite
│   └── testthat/
│       ├── test-aldex.glm.R
│       ├── test-aldex.ttest.R
│       └── test-stats.fast.R
├── vignettes/         # Usage examples
│   └── ALDEx2_vignette.Rnw
└── data/              # Example datasets
    └── selex.txt.gz
```

## Dependencies

### Depends

- `methods` (base R)
- `stats` (base R)

### Imports

- `BiocParallel` - Parallel processing support
- `GenomicRanges` - Genomic range operations
- `IRanges` - Interval range operations
- `S4Vectors` - S4 vector classes
- `SummarizedExperiment` - SummarizedExperiment class support
- `multtest` - Multiple testing procedures

### Suggests

- `testthat` - Testing framework

### Imported Functions from Base Packages

- `grDevices::rgb`
- `graphics::abline`, `graphics::hist`, `graphics::par`, `graphics::plot`, `graphics::points`
- `stats::cor.test`, `stats::drop1`, `stats::glm`, `stats::kruskal.test`, `stats::p.adjust`, `stats::rgamma`, `stats::t.test`, `stats::wilcox.test`, `stats::pnorm`, `stats::psignrank`, `stats::pt`, `stats::pwilcox`
- `utils::installed.packages`

## Exported Functions

### Main Functions (Exported via `export()` and `exportPattern()`)

1. **`aldex()`** - Main wrapper function

   - File: `R/aldex.r`
   - Wrapper that performs CLR transformation and statistical testing

2. **`aldex.clr()`** - CLR transformation

   - File: `R/clr_function.r`
   - Methods: `data.frame`, `matrix`, `RangedSummarizedExperiment`
   - Generates Monte Carlo samples and CLR transforms

3. **`aldex.ttest()`** - Welch's t-test and Wilcoxon tests

   - File: `R/clr_ttest.r`
   - Two-sample tests on CLR-transformed data

4. **`aldex.effect()`** - Effect size calculations

   - File: `R/clr_effect.r`
   - Calculates effect sizes and relative abundances

5. **`aldex.glm()`** - GLM and Kruskal-Wallis tests

   - File: `R/clr_glm.r`
   - Multi-sample tests

6. **`aldex.corr()`** - Correlation analysis

   - File: `R/clr_corr.R`
   - Pearson and Spearman correlations

7. **`aldex.set.mode()`** - Feature selection mode

   - File: `R/iqlr_features.r`
   - Determines denominator features for CLR

8. **`aldex.plot()`** - Plotting function
   - File: `R/plot.aldex.r`
   - Visualization of results

### S4 Methods (Exported via `exportMethods()`)

All methods operate on `aldex.clr` objects:

- `getMonteCarloInstances(.object)` - Get MC instances
- `getSampleIDs(.object)` - Get sample IDs
- `getFeatures(.object)` - Get features
- `numFeatures(.object)` - Number of features
- `numMCInstances(.object)` - Number of MC instances
- `getFeatureNames(.object)` - Get feature names
- `getReads(.object)` - Get read counts
- `numConditions(.object)` - Number of conditions
- `getMonteCarloReplicate(.object, i)` - Get specific MC replicate

## Internal Functions (Not Exported)

1. **`aldex.clr.function()`** - Internal CLR implementation

   - File: `R/clr_function.r`
   - Core CLR transformation logic

2. **`rdirichlet()`** - Dirichlet distribution sampling

   - File: `R/rdirichlet.r`
   - Generates random Dirichlet samples

3. **`aitchison.mean()`** - Aitchison mean calculation

   - File: `R/rdirichlet.r`
   - Calculates expected frequencies

4. **`iqlr.features()`** - IQLR feature selection

   - File: `R/iqlr_features.r`
   - Selects inter-quartile log-ratio features

5. **`zero.features()`** - Zero-inflated feature handling

   - File: `R/iqlr_features.r`
   - Handles zero-inflated data

6. **`all.features()`** - All features mode

   - File: `R/iqlr_features.r`
   - Uses all features

7. **`custom.features()`** - Custom feature selection

   - File: `R/iqlr_features.r`
   - User-specified features

8. **`t.fast()`** - Fast t-test implementation

   - File: `R/stats.fast.R`
   - Optimized t-test using multtest

9. **`wilcox.fast()`** - Fast Wilcoxon test implementation

   - File: `R/stats.fast.R`
   - Optimized Wilcoxon test using multtest

10. **`progress()`** - Progress bar utility
    - File: `R/progress.R`
    - Displays progress during MC iterations

## S4 Classes

### `aldex.clr` Class

- **File:** `R/AllClasses.R`
- **Slots:**
  - `reads`: `data.frame` - Original read counts
  - `conds`: `data.frame` - Conditions (not used in current implementation)
  - `mc.samples`: `numeric` - Number of MC samples
  - `denom`: `character` - Denominator mode
  - `verbose`: `logical` - Verbose flag
  - `useMC`: `logical` - Multicore flag
  - `analysisData`: `list` - CLR-transformed MC instances

## Test Coverage

### Test Files

- `tests/testthat/test-aldex.glm.R` - GLM tests
- `tests/testthat/test-aldex.ttest.R` - t-test tests
- `tests/testthat/test-stats.fast.R` - Fast stats tests

## Example Datasets

- **`selex`** - Example dataset (loaded from `data/selex.txt.gz`)
  - 1600 features × 14 samples
  - Used in vignettes and examples

## Vignettes

- **`ALDEx2_vignette.Rnw`** - Main package vignette with usage examples

## Notes

- Package uses S4 classes and methods for object-oriented design
- Supports parallel processing via BiocParallel (optional)
- Monte Carlo sampling is central to the methodology
- All statistical tests operate on CLR-transformed Monte Carlo instances
- Package is optimized for datasets with 3+ replicates per condition
