# Function Signature: `aldex.corr()`

## Function Information

- **File:** `R/clr_corr.R`
- **Type:** Exported function
- **Category:** Correlation analysis

## Function Signature

```r
aldex.corr(clr, covar)
```

## Input Parameters

### `clr`

- **Type:** `aldex.clr` (S4 object)
- **Required:** Yes
- **Constraints:**
  - Must be output from `aldex.clr()`
- **Note:** CLR-transformed Monte Carlo instances

### `covar`

- **Type:** `vector` of `numeric`
- **Required:** Yes
- **Constraints:**
  - Must be numeric
  - Length must match number of samples
- **Dimensions:** Length = number of samples
- **Note:** Continuous variable to correlate with relative abundances
- **Example:** `c(1.2, 1.5, 2.1, 1.8, ...)` (e.g., age, pH, temperature)

## Output

### Return Type

- **Type:** `data.frame`
- **Dimensions:**
  - Rows: Number of features
  - Columns: 6
- **Row names:** Feature names from `clr` object

### Output Columns

1. **`pearson.ecor`** - Expected Pearson correlation coefficient

   - Type: `numeric`
   - Range: [-1, 1]
   - Description: Mean correlation coefficient across all Monte Carlo instances

2. **`pearson.ep`** - Expected Pearson p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean p-value across all Monte Carlo instances

3. **`pearson.eBH`** - Expected Pearson BH-adjusted p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean Benjamini-Hochberg adjusted p-value

4. **`spearman.erho`** - Expected Spearman rank correlation coefficient

   - Type: `numeric`
   - Range: [-1, 1]
   - Description: Mean rank correlation coefficient across all MC instances

5. **`spearman.ep`** - Expected Spearman p-value

   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean p-value across all Monte Carlo instances

6. **`spearman.eBH`** - Expected Spearman BH-adjusted p-value
   - Type: `numeric`
   - Range: [0, 1]
   - Description: Mean Benjamini-Hochberg adjusted p-value

## Processing Steps

1. **Extract dimensions:**

   - Number of features, MC instances, sample IDs, feature names

2. **Validate covariate:**

   - Check length matches number of samples
   - Check is numeric

3. **For each Monte Carlo instance:**

   - Extract MC instance matrix (features × samples)
   - For each feature:
     - Pearson correlation: `cor.test(value, covar)`
     - Spearman correlation: `cor.test(value, covar, method="spearman")`
     - Extract correlation coefficient and p-value
   - Apply BH correction to both tests
   - Store results in matrices

4. **Compute expected values:**
   - Mean correlation coefficients across MC instances
   - Mean p-values across MC instances
   - Return as data.frame

## Statistical Tests

### Pearson Correlation

- **Type:** Parametric product-moment correlation
- **Assumptions:** Linear relationship, normality
- **Implementation:** `stats::cor.test()` with default method

### Spearman Correlation

- **Type:** Non-parametric rank-based correlation
- **Assumptions:** Monotonic relationship
- **Implementation:** `stats::cor.test()` with `method="spearman"`

## Side Effects

- None (no printed output)

## Dependencies

- `stats::cor.test()` - Correlation testing
- `stats::p.adjust()` - Benjamini-Hochberg correction
- S4 accessor methods: `getMonteCarloInstances()`, `getFeatureNames()`, etc.

## Example Usage

```r
data(selex)
conds <- c(rep("NS", 7), rep("S", 7))
x.clr <- aldex.clr(selex, conds, mc.samples=128)

# Continuous covariate (e.g., pH values)
pH_values <- c(6.5, 6.8, 7.0, 6.9, 7.1, 6.7, 6.6,
               7.2, 7.3, 7.1, 7.0, 7.4, 7.2, 7.1)

x.corr <- aldex.corr(x.clr, pH_values)
```

## Notes

- Correlates each feature's CLR values with a continuous covariate
- Computes both parametric (Pearson) and non-parametric (Spearman) correlations
- Expected values are means across all Monte Carlo instances
- BH correction applied per MC instance, then averaged
- Useful for identifying features associated with continuous variables (e.g., pH, temperature, age)
