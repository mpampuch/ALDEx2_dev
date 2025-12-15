# Function Signature: `aldex()`

## Function Information

- **File:** `R/aldex.r`
- **Type:** Exported function (main wrapper)
- **Category:** Main wrapper function

## Function Signature

```r
aldex(reads, conditions, mc.samples=128, test="t",
      effect=TRUE, include.sample.summary=FALSE,
      verbose=FALSE, denom="all")
```

## Input Parameters

### `reads`

- **Type:** `data.frame` or `matrix`
- **Required:** Yes
- **Constraints:**
  - Non-negative integers only
  - Unique row names (features/genes)
  - Unique column names (samples)
  - Rows with 0 reads in all samples are deleted
- **Dimensions:**
  - Rows: Features (genes, OTUs, etc.)
  - Columns: Samples
- **Example:**
  ```
              T1a T1b  T2  T3  N1  N2  Nx
  Gene_00001   0   0   2   0   0   1   0
  Gene_00002  20   8  12   5  19  26  14
  ```

### `conditions`

- **Type:** `character` vector
- **Required:** Yes
- **Constraints:**
  - Length must match number of columns in `reads`
  - Typically group labels (e.g., `c("A", "A", "B", "B")`)
- **Dimensions:** Length = number of samples (columns in `reads`)
- **Example:** `c(rep("NS", 7), rep("S", 7))`

### `mc.samples`

- **Type:** `integer` (coerced from numeric)
- **Required:** No (default: 128)
- **Constraints:**
  - Must be positive integer
  - Warning if < 128 (values unreliable)
- **Default:** 128
- **Note:** Number of Monte Carlo Dirichlet samples

### `test`

- **Type:** `character` string
- **Required:** No (default: "t")
- **Valid values:**
  - `"t"` - Welch's t-test and Wilcoxon tests
  - `"glm"` - GLM and Kruskal-Wallis tests
  - `"iterative"` - Two-pass t-test with non-DE feature seeding
- **Default:** `"t"`

### `effect`

- **Type:** `logical` (boolean)
- **Required:** No (default: TRUE)
- **Constraints:**
  - Only applies when `test = "t"` or `test = "iterative"`
- **Default:** TRUE
- **Note:** Toggles effect size calculation

### `include.sample.summary`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Constraints:**
  - Only applies when `effect = TRUE`
- **Default:** FALSE
- **Note:** Includes median CLR values per sample

### `verbose`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** Prints diagnostic information

### `denom`

- **Type:** `character` string or `numeric` vector
- **Required:** No (default: "all")
- **Valid values:**
  - `"all"` - Use all features (default)
  - `"iqlr"` - Inter-quartile log-ratio features
  - `"zero"` - Non-zero features per group
  - `numeric` vector - Custom feature indices
- **Default:** `"all"`

## Output

### Return Type

- **Type:** `data.frame`
- **Structure:** Depends on `test` and `effect` parameters

### Output Structure by Test Type

#### When `test = "t"` and `effect = TRUE`:

- **Columns:**
  - `we.ep` - Expected Welch's t-test p-value
  - `we.eBH` - Expected Welch's t-test BH-adjusted p-value
  - `wi.ep` - Expected Wilcoxon p-value
  - `wi.eBH` - Expected Wilcoxon BH-adjusted p-value
  - `rab.all` - Median relative abundance (all samples)
  - `rab.win.<condition>` - Median relative abundance per condition
  - `rab.sample.<sample_id>` - Median relative abundance per sample (if `include.sample.summary = TRUE`)
  - `diff.btw` - Median between-condition difference
  - `diff.win` - Median within-condition difference
  - `effect` - Effect size
  - `overlap` - Proportion of effect overlapping zero
- **Rows:** One row per feature (after removing zero-sum rows)
- **Row names:** Feature names from input

#### When `test = "t"` and `effect = FALSE`:

- **Columns:**
  - `we.ep`, `we.eBH`, `wi.ep`, `wi.eBH` (as above)
- **Rows:** One row per feature
- **Row names:** Feature names

#### When `test = "glm"`:

- **Columns:**
  - `kw.ep` - Expected Kruskal-Wallis p-value
  - `kw.eBH` - Expected Kruskal-Wallis BH-adjusted p-value
  - `glm.ep` - Expected GLM p-value
  - `glm.eBH` - Expected GLM BH-adjusted p-value
- **Rows:** One row per feature
- **Row names:** Feature names

#### When `test = "iterative"`:

- Same as `test = "t"` with `effect = TRUE`
- Uses non-DE features from first pass as denominator for second pass

## Side Effects

- Prints progress messages:
  - "aldex.clr: generating Monte-Carlo instances and clr values"
  - "aldex.ttest: doing t-test" (or similar)
  - "aldex.effect: calculating effect sizes" (if applicable)

## Dependencies

- Calls `aldex.clr()` for CLR transformation
- Calls `aldex.ttest()` for t-tests
- Calls `aldex.glm()` for GLM tests
- Calls `aldex.effect()` for effect sizes

## Example Usage

```r
data(selex)
selex <- selex[1201:1600,] # subset for efficiency
conds <- c(rep("NS", 7), rep("S", 7))
x <- aldex(selex, conds, mc.samples=128, denom="all",
           test="t", effect=TRUE)
```

## Notes

- Main wrapper function that orchestrates the entire ALDEx2 workflow
- Removes rows with zero reads in all samples before processing
- For `test = "iterative"`, requires at least some non-DE features to be found
