# Function Signature: `aldex.clr()`

## Function Information

- **File:** `R/clr_function.r`
- **Type:** Exported S4 method
- **Category:** Core transformation function
- **Methods:** `data.frame`, `matrix`, `RangedSummarizedExperiment`

## Function Signature

```r
aldex.clr(reads, conds, mc.samples=128, denom="all",
          verbose=FALSE, useMC=FALSE)
```

## Input Parameters

### `reads`

- **Type:** `data.frame`, `matrix`, or `RangedSummarizedExperiment`
- **Required:** Yes
- **Constraints:**
  - Non-negative integers only
  - Unique row names (features)
  - Unique column names (samples)
  - Rows with sum = 0 are removed
- **Dimensions:**
  - Rows: Features (genes, OTUs, etc.)
  - Columns: Samples
- **Example:**
  ```
              T1a T1b  T2  T3  N1  N2
  Gene_00001   0   0   2   0   0   1
  Gene_00002  20   8  12   5  19  26
  ```

### `conds`

- **Type:** `vector` (character)
- **Required:** Yes
- **Constraints:**
  - Length must match number of columns in `reads`
  - Used for grouping samples
- **Dimensions:** Length = number of samples
- **Example:** `c(rep("A", 7), rep("B", 7))`

### `mc.samples`

- **Type:** `integer` (coerced from numeric)
- **Required:** No (default: 128)
- **Constraints:**
  - Must be positive integer
  - Warning if < 128
- **Default:** 128
- **Note:** Number of Monte Carlo Dirichlet samples per sample

### `denom`

- **Type:** `character` string or `numeric` vector
- **Required:** No (default: "all")
- **Valid values:**
  - `"all"` - All features (default)
  - `"iqlr"` - Inter-quartile log-ratio features
  - `"zero"` - Non-zero features per condition
  - `numeric` vector - Custom feature indices
- **Default:** `"all"`

### `verbose`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** Prints diagnostic information

### `useMC`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** Uses BiocParallel for parallel processing if available

## Output

### Return Type

- **Type:** `aldex.clr` (S4 object)
- **Class:** Defined in `R/AllClasses.R`

### Object Structure

#### Slots:

- `reads`: `data.frame` - Original read counts (with 0.5 prior added)
- `conds`: `data.frame` - Conditions (not actively used)
- `mc.samples`: `numeric` - Number of MC samples
- `denom`: `character` - Denominator mode used
- `verbose`: `logical` - Verbose flag
- `useMC`: `logical` - Multicore flag
- `analysisData`: `list` - CLR-transformed Monte Carlo instances

#### `analysisData` Structure:

- **Type:** `list` of `matrix` objects
- **Length:** Number of samples
- **Names:** Sample IDs (column names from input)
- **Each element:**
  - **Type:** `matrix`
  - **Dimensions:**
    - Rows: Features (after removing zero-sum rows)
    - Columns: Monte Carlo instances (`mc.samples`)
  - **Row names:** Feature names
  - **Values:** CLR-transformed log2 values

### Access Methods

- `getMonteCarloInstances(x)` - Returns `analysisData` list
- `getSampleIDs(x)` - Returns sample ID names
- `getFeatures(x)` - Returns feature vector (first column of first sample)
- `numFeatures(x)` - Returns number of features
- `numMCInstances(x)` - Returns number of MC instances
- `getFeatureNames(x)` - Returns feature names (row names)
- `getReads(x)` - Returns original reads data.frame
- `numConditions(x)` - Returns number of conditions (samples)
- `getMonteCarloReplicate(x, i)` - Returns MC instance `i` for sample `i`

## Processing Steps

1. **Data Validation:**

   - Checks for integer reads
   - Checks for non-negative values
   - Checks for finite values
   - Validates unique row/column names
   - Removes rows with sum = 0

2. **Prior Addition:**

   - Adds 0.5 prior to all reads (Count Zero Multiplicative approach)

3. **Feature Selection:**

   - Calls `aldex.set.mode()` to determine denominator features
   - Options: "all", "iqlr", "zero", or custom indices

4. **Dirichlet Sampling:**

   - For each sample, generates `mc.samples` Dirichlet instances
   - Uses `rdirichlet()` function
   - Parallel processing via BiocParallel if `useMC=TRUE`

5. **CLR Transformation:**
   - Computes log2 of Dirichlet proportions
   - Subtracts geometric mean (centered log-ratio)
   - Geometric mean computed using selected features

## Side Effects

- Prints messages if `verbose=TRUE`:
  - "data format is OK"
  - "dirichlet samples complete"
  - "clr transformation complete"
- Prints "operating in serial mode" or "multicore environment is OK" based on `useMC`

## Dependencies

- `rdirichlet()` - Dirichlet sampling
- `aldex.set.mode()` - Feature selection
- `BiocParallel::bplapply()` - Parallel processing (if `useMC=TRUE`)
- `base::lapply()` - Serial processing

## Example Usage

```r
data(selex)
selex <- selex[1201:1600,]
conds <- c(rep("NS", 7), rep("S", 7))
x <- aldex.clr(selex, conds, mc.samples=128,
               denom="all", verbose=FALSE)
```

## Notes

- Core function that generates Monte Carlo CLR instances
- All downstream functions operate on `aldex.clr` objects
- Supports parallel processing via BiocParallel
- Prior addition (0.5) handles zero counts
- Feature selection modes allow for different normalization strategies
