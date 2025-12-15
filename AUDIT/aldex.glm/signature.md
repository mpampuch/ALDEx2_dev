# Function Signature: `aldex.glm()`

## Function Information

- **File:** `R/clr_glm.r`
- **Type:** Exported function
- **Category:** Statistical testing (multi-sample)

## Function Signature

```r
aldex.glm(clr, conditions, useMC=FALSE)
```

## Input Parameters

### `clr`

- **Type:** `aldex.clr` (S4 object)
- **Required:** Yes
- **Constraints:**
  - Must be output from `aldex.clr()`
  - Can handle 2+ condition levels
- **Note:** CLR-transformed Monte Carlo instances

### `conditions`

- **Type:** `vector` (character or factor)
- **Required:** Yes
- **Constraints:**
  - Length must match `numConditions(clr)`
  - Can have 2+ unique levels
  - Converted to factor internally
- **Dimensions:** Length = number of samples
- **Example:** `c(rep("A", 5), rep("B", 5), rep("C", 5))`

### `useMC`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** Uses BiocParallel for parallel processing if available

## Output

### Return Type

- **Type:** `data.frame`
- **Dimensions:**
  - Rows: Number of features
  - Columns: 4
- **Row names:** Feature names from `clr` object

### Output Columns

1. **`kw.ep`** - Expected Kruskal-Wallis p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean p-value across all Monte Carlo instances

2. **`kw.eBH`** - Expected Kruskal-Wallis BH-adjusted p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean Benjamini-Hochberg adjusted p-value

3. **`glm.ep`** - Expected GLM p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean p-value from GLM likelihood ratio test

4. **`glm.eBH`** - Expected GLM BH-adjusted p-value
   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean Benjamini-Hochberg adjusted p-value

## Processing Steps

1. **Extract dimensions:**

   - Number of features, MC instances, sample IDs, feature names

2. **Validate conditions:**

   - Check length matches number of samples
   - Convert to factor

3. **For each Monte Carlo instance:**

   - Extract MC instance matrix (features × samples)
   - For each feature:
     - Fit GLM: `glm(value ~ factor(conditions))`
     - Perform likelihood ratio test: `drop1(glm, test="Chis")`
     - Extract p-value
   - Perform Kruskal-Wallis test per feature
   - Apply BH correction to both tests
   - Store results in matrices

4. **Compute expected values:**
   - Mean across MC instances for each test
   - Return as data.frame

## Statistical Tests

### GLM Test

- **Model:** `glm(value ~ factor(conditions))`
- **Test:** Likelihood ratio test via `drop1()`
- **Null hypothesis:** No difference between conditions
- **Alternative:** At least one condition differs

### Kruskal-Wallis Test

- **Type:** Non-parametric rank-based test
- **Null hypothesis:** Distributions are identical across conditions
- **Alternative:** At least one condition differs
- **Implementation:** `stats::kruskal.test()`

## Side Effects

- Prints "running tests for each MC instance:"
- Displays progress bar during MC iterations
- Prints "multicore environment is OK" or "operating in serial mode" based on `useMC`

## Dependencies

- `stats::glm()` - Generalized linear model fitting
- `stats::drop1()` - Likelihood ratio test
- `stats::kruskal.test()` - Kruskal-Wallis test
- `stats::p.adjust()` - Benjamini-Hochberg correction
- `BiocParallel::bplapply()` - Parallel processing (if `useMC=TRUE`)
- `progress()` - Progress bar utility
- S4 accessor methods

## Example Usage

```r
data(selex)
conds <- c(rep("A", 5), rep("B", 5), rep("C", 4))
x.clr <- aldex.clr(selex, conds, mc.samples=128)
x.glm <- aldex.glm(x.clr, conds, useMC=FALSE)
```

## Notes

- Supports multi-sample comparisons (2+ conditions)
- GLM uses Gaussian family (default)
- Kruskal-Wallis is non-parametric alternative
- Both tests are applied per feature across all MC instances
- Expected p-values are means across MC instances
- BH correction applied per MC instance, then averaged
