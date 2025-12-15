# Function Signature: `aldex.ttest()`

## Function Information

- **File:** `R/clr_ttest.r`
- **Type:** Exported function
- **Category:** Statistical testing

## Function Signature

```r
aldex.ttest(clr, conditions, paired.test=FALSE, hist.plot=FALSE)
```

## Input Parameters

### `clr`

- **Type:** `aldex.clr` (S4 object)
- **Required:** Yes
- **Constraints:**
  - Must be output from `aldex.clr()`
  - Must have exactly 2 condition levels
- **Note:** CLR-transformed Monte Carlo instances

### `conditions`

- **Type:** `vector` (character or factor)
- **Required:** Yes
- **Constraints:**
  - Length must match `numConditions(clr)`
  - Must have exactly 2 unique levels
  - Converted to factor internally
- **Dimensions:** Length = number of samples
- **Example:** `c(rep("A", 7), rep("B", 7))`

### `paired.test`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** If TRUE, performs paired t-test and Wilcoxon test

### `hist.plot`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** If TRUE, plots histograms of p-values and BH values

## Output

### Return Type

- **Type:** `data.frame`
- **Dimensions:**
  - Rows: Number of features
  - Columns: 4
- **Row names:** Feature names from `clr` object

### Output Columns

1. **`we.ep`** - Expected Welch's t-test p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean p-value across all Monte Carlo instances

2. **`we.eBH`** - Expected Welch's t-test BH-adjusted p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean Benjamini-Hochberg adjusted p-value

3. **`wi.ep`** - Expected Wilcoxon rank-sum p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean p-value across all Monte Carlo instances

4. **`wi.eBH`** - Expected Wilcoxon BH-adjusted p-value
   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean Benjamini-Hochberg adjusted p-value

## Processing Steps

1. **Extract dimensions:**

   - Number of features, MC instances, sample IDs, feature names

2. **Validate conditions:**

   - Check length matches number of samples
   - Check exactly 2 condition levels
   - Create binary grouping vector

3. **For each Monte Carlo instance:**

   - Extract MC instance matrix (features × samples)
   - Run `t.fast()` for Welch's t-test
   - Run `wilcox.fast()` for Wilcoxon test
   - Apply BH correction to both
   - Store results in matrices

4. **Compute expected values:**
   - Mean across MC instances for each test
   - Return as data.frame

## Side Effects

- Prints "running tests for each MC instance:"
- Displays progress bar during MC iterations
- If `hist.plot=TRUE`, creates 4-panel histogram plot

## Dependencies

- `t.fast()` - Fast Welch's t-test implementation
- `wilcox.fast()` - Fast Wilcoxon test implementation
- `stats::p.adjust()` - Benjamini-Hochberg correction
- `progress()` - Progress bar utility
- S4 accessor methods: `getMonteCarloInstances()`, `getFeatureNames()`, etc.

## Example Usage

```r
data(selex)
conds <- c(rep("NS", 7), rep("S", 7))
x.clr <- aldex.clr(selex, conds, mc.samples=128)
x.tt <- aldex.ttest(x.clr, conds, paired.test=FALSE)
```

## Notes

- Operates on CLR-transformed Monte Carlo instances
- Computes expected p-values by averaging across MC instances
- Uses optimized fast implementations (`t.fast`, `wilcox.fast`)
- Supports both paired and unpaired tests
- BH correction applied per MC instance, then averaged
