# Function Signature: `t.fast()`

## Function Information

- **File:** `R/stats.fast.R`
- **Type:** Internal function (not exported)
- **Category:** Statistical testing (optimized implementation)

## Function Signature

```r
t.fast(data, group, paired)
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
- **Note:** Whether to perform paired t-test

## Output

### Return Type

- **Type:** `numeric` vector
- **Dimensions:** Length = number of features (rows in `data`)
- **Values:**
  - Two-tailed p-values
  - Range: [0, 1]

## Algorithm

### Unpaired Test (Welch's t-test):

1. Split data by group
2. Calculate test statistic using `multtest::mt.teststat()`
3. Calculate degrees of freedom (Welch's approximation)
4. Compute two-tailed p-value using `pt()`

### Paired Test:

1. Order pairs for `multtest::mt.teststat()`
2. Calculate paired t-statistic
3. Degrees of freedom = n - 1 (where n = number of pairs)
4. Compute two-tailed p-value

## Implementation Details

- Uses `multtest::mt.teststat()` for fast computation
- Assumes unequal variance (Welch's t-test)
- Uses `stats::pt()` for p-value calculation
- Optimized for speed over base `t.test()`

## Dependencies

- `multtest::mt.teststat()` - Fast test statistic calculation
- `stats::pt()` - t-distribution p-value
- `base::apply()` - Standard deviation calculation

## Example Usage

```r
# CLR-transformed data (features × samples)
data <- matrix(rnorm(100 * 14), nrow=100, ncol=14)

# Binary grouping
group <- c(rep(0, 7), rep(1, 7))

# Unpaired test
pvals <- t.fast(data, group, paired=FALSE)

# Paired test (requires equal group sizes)
pvals <- t.fast(data, group, paired=TRUE)
```

## Notes

- Faster than base `t.test()` due to vectorized computation
- Used internally by `aldex.ttest()`
- Assumes unequal variance (Welch's approximation)
- Returns two-tailed p-values
- Critical for performance in Monte Carlo iterations
