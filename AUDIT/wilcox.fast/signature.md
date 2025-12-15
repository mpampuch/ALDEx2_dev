# Function Signature: `wilcox.fast()`

## Function Information

- **File:** `R/stats.fast.R`
- **Type:** Internal function (not exported)
- **Category:** Statistical testing (optimized implementation)

## Function Signature

```r
wilcox.fast(data, group, paired)
```

## Input Parameters

### `data`

- **Type:** `matrix` or `data.frame`
- **Required:** Yes
- **Constraints:**
  - Rows: Features
  - Columns: Samples
- **Dimensions:**
  - Rows: Number of features
  - Columns: Number of samples
- **Note:** CLR-transformed values (one MC instance)

### `group`

- **Type:** `numeric` or `logical` vector
- **Required:** Yes
- **Constraints:**
  - Length must match number of columns in `data`
  - Must have exactly 2 unique values
- **Dimensions:** Length = number of samples
- **Note:** Binary grouping vector (0/1 or FALSE/TRUE)

### `paired`

- **Type:** `logical` (boolean)
- **Required:** Yes
- **Constraints:**
  - If TRUE, groups must have equal sizes
- **Note:** Whether to perform paired Wilcoxon test

## Output

### Return Type

- **Type:** `numeric` vector
- **Dimensions:** Length = number of features (rows in `data`)
- **Values:**
  - Two-tailed p-values
  - Range: [0, 1]

## Algorithm

### Unpaired Test (Wilcoxon rank-sum):

1. Check for ties in data
2. If ties detected: Use slower `wilcox.test()` per feature
3. If no ties:
   - Calculate test statistic using `multtest::mt.teststat()`
   - For small samples (< 50): Use exact distribution (`pwilcox()`)
   - For large samples: Use normal approximation (`pnorm()`)

### Paired Test (Wilcoxon signed-rank):

1. Calculate differences between pairs
2. Calculate signed-rank statistic
3. For small samples (< 50): Use exact distribution (`psignrank()`)
4. For large samples: Use normal approximation

## Implementation Details

- Uses `multtest::mt.teststat()` when possible (faster)
- Falls back to `wilcox.test()` if ties are detected
- Uses exact distributions for small samples
- Uses normal approximation for large samples
- Equivalent to `wilcox.test(..., correct=FALSE)`

## Dependencies

- `multtest::mt.teststat()` - Fast test statistic calculation
- `stats::wilcox.test()` - Fallback for tied data
- `stats::pwilcox()` - Exact Wilcoxon p-value
- `stats::psignrank()` - Exact signed-rank p-value
- `stats::pnorm()` - Normal approximation
- `base::rank()` - Ranking for paired test

## Example Usage

```r
# CLR-transformed data (features × samples)
data <- matrix(rnorm(100 * 14), nrow=100, ncol=14)

# Binary grouping
group <- c(rep(0, 7), rep(1, 7))

# Unpaired test
pvals <- wilcox.fast(data, group, paired=FALSE)

# Paired test (requires equal group sizes)
pvals <- wilcox.fast(data, group, paired=TRUE)
```

## Notes

- Faster than base `wilcox.test()` for large datasets
- Handles ties by falling back to standard implementation
- Uses exact distributions when sample sizes are small
- Used internally by `aldex.ttest()`
- Critical for performance in Monte Carlo iterations
