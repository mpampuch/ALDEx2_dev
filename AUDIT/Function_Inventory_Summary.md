# ALDEx2 Function Inventory Summary

**Date:** 2024  
**Package Version:** 1.8.1

## Quick Reference: All Functions

### Exported Functions (User-Facing)

| Function           | File                | Category            | Input Type                                              | Output Type      |
| ------------------ | ------------------- | ------------------- | ------------------------------------------------------- | ---------------- |
| `aldex()`          | `R/aldex.r`         | Main wrapper        | `data.frame/matrix`, `conditions`                       | `data.frame`     |
| `aldex.clr()`      | `R/clr_function.r`  | Core transformation | `data.frame/matrix/RangedSummarizedExperiment`, `conds` | `aldex.clr` (S4) |
| `aldex.ttest()`    | `R/clr_ttest.r`     | Statistical testing | `aldex.clr`, `conditions`                               | `data.frame`     |
| `aldex.effect()`   | `R/clr_effect.r`    | Effect size         | `aldex.clr`, `conditions`                               | `data.frame`     |
| `aldex.glm()`      | `R/clr_glm.r`       | Statistical testing | `aldex.clr`, `conditions`                               | `data.frame`     |
| `aldex.corr()`     | `R/clr_corr.R`      | Correlation         | `aldex.clr`, `covar`                                    | `data.frame`     |
| `aldex.set.mode()` | `R/iqlr_features.r` | Feature selection   | `reads`, `conds`, `denom`                               | `list`           |
| `aldex.plot()`     | `R/plot.aldex.r`    | Visualization       | `aldex` results                                         | `NULL` (plot)    |

### Internal Functions (Not Exported)

| Function               | File                | Category                | Purpose                        |
| ---------------------- | ------------------- | ----------------------- | ------------------------------ |
| `aldex.clr.function()` | `R/clr_function.r`  | Core transformation     | Internal CLR implementation    |
| `rdirichlet()`         | `R/rdirichlet.r`    | Distribution sampling   | Dirichlet random sampling      |
| `aitchison.mean()`     | `R/rdirichlet.r`    | Statistical calculation | Aitchison mean calculation     |
| `iqlr.features()`      | `R/iqlr_features.r` | Feature selection       | IQLR feature selection         |
| `zero.features()`      | `R/iqlr_features.r` | Feature selection       | Zero-inflated feature handling |
| `all.features()`       | `R/iqlr_features.r` | Feature selection       | All features mode              |
| `custom.features()`    | `R/iqlr_features.r` | Feature selection       | Custom feature indices         |
| `t.fast()`             | `R/stats.fast.R`    | Statistical testing     | Fast t-test implementation     |
| `wilcox.fast()`        | `R/stats.fast.R`    | Statistical testing     | Fast Wilcoxon test             |
| `progress()`           | `R/progress.R`      | Utility                 | Progress bar display           |

### S4 Methods (Exported)

| Method                               | Object Type | Returns                |
| ------------------------------------ | ----------- | ---------------------- |
| `getMonteCarloInstances(.object)`    | `aldex.clr` | `list` of MC instances |
| `getSampleIDs(.object)`              | `aldex.clr` | `character` vector     |
| `getFeatures(.object)`               | `aldex.clr` | `numeric` vector       |
| `numFeatures(.object)`               | `aldex.clr` | `integer`              |
| `numMCInstances(.object)`            | `aldex.clr` | `integer`              |
| `getFeatureNames(.object)`           | `aldex.clr` | `character` vector     |
| `getReads(.object)`                  | `aldex.clr` | `data.frame`           |
| `numConditions(.object)`             | `aldex.clr` | `integer`              |
| `getMonteCarloReplicate(.object, i)` | `aldex.clr` | `matrix`               |

## Function Dependencies

```
aldex()
  ├── aldex.clr()
  │     ├── rdirichlet()
  │     ├── aldex.set.mode()
  │     │     ├── iqlr.features()
  │     │     ├── zero.features()
  │     │     ├── all.features()
  │     │     └── custom.features()
  │     └── BiocParallel (optional)
  ├── aldex.ttest()
  │     ├── t.fast()
  │     ├── wilcox.fast()
  │     └── progress()
  ├── aldex.glm()
  │     └── progress()
  └── aldex.effect()
        ├── aitchison.mean()
        └── BiocParallel (optional)
```

## Data Flow

1. **Input:** `reads` (count matrix) + `conditions` (group labels)
2. **CLR Transformation:** `aldex.clr()` → `aldex.clr` object
3. **Statistical Testing:**
   - `aldex.ttest()` → p-values
   - `aldex.glm()` → p-values
   - `aldex.corr()` → correlations
4. **Effect Size:** `aldex.effect()` → effect sizes, abundances
5. **Output:** `data.frame` with test results

## Key Data Structures

### Input: `reads`

- **Type:** `data.frame` or `matrix`
- **Format:** Features (rows) × Samples (columns)
- **Values:** Non-negative integers (counts)
- **Requirements:** Unique row/column names

### Intermediate: `aldex.clr` Object

- **Type:** S4 class
- **Key Slot:** `analysisData` (list of matrices)
- **Structure:** One matrix per sample, each with features × MC instances

### Output: Results `data.frame`

- **Type:** `data.frame`
- **Rows:** Features
- **Columns:** Test statistics (p-values, effect sizes, etc.)
- **Row names:** Feature names

## Monte Carlo Workflow

1. Generate `mc.samples` Dirichlet instances per sample
2. Transform each instance via CLR
3. Apply statistical tests to each MC instance
4. Average results across MC instances (expected values)

## Notes

- All functions operate on CLR-transformed data
- Monte Carlo sampling is central to methodology
- Supports parallel processing via BiocParallel
- Feature selection modes: "all", "iqlr", "zero", or custom
- Statistical tests: t-test, Wilcoxon, GLM, Kruskal-Wallis, correlations
