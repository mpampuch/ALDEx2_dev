# Function Signature: `aldex.effect()`

## Function Information

- **File:** `R/clr_effect.r`
- **Type:** Exported function
- **Category:** Effect size calculation

## Function Signature

```r
aldex.effect(clr, conditions, verbose=TRUE,
             include.sample.summary=FALSE, useMC=FALSE)
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
  - Each level must have at least 2 replicates
- **Dimensions:** Length = number of samples
- **Example:** `c(rep("A", 7), rep("B", 7))`

### `verbose`

- **Type:** `logical` (boolean)
- **Required:** No (default: TRUE)
- **Default:** TRUE
- **Note:** Prints progress messages

### `include.sample.summary`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** If TRUE, includes per-sample median CLR values

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
  - Columns: Variable (depends on `include.sample.summary`)
- **Row names:** Feature names from `clr` object

### Output Columns

#### Core Columns (Always Present):

1. **`rab.all`** - Median relative abundance (all samples)

   - Type: `numeric`
   - Description: Median CLR value across all samples and MC instances

2. **`rab.win.<condition1>`** - Median relative abundance for condition 1

   - Type: `numeric`
   - Description: Median CLR value for condition 1 samples

3. **`rab.win.<condition2>`** - Median relative abundance for condition 2

   - Type: `numeric`
   - Description: Median CLR value for condition 2 samples

4. **`diff.btw`** - Median between-condition difference

   - Type: `numeric`
   - Description: Median signed difference between conditions

5. **`diff.win`** - Median within-condition difference

   - Type: `numeric`
   - Description: Median absolute difference within conditions

6. **`effect`** - Effect size

   - Type: `numeric`
   - Description: `diff.btw / max(within-condition differences)`
   - Interpretation: Effect size relative to within-group variation

7. **`overlap`** - Proportion of effect overlapping zero
   - Type: `numeric`
   - Range: [0, 0.5]
   - Description: Minimum proportion of effect distribution on each side of zero
   - Calculated using `aitchison.mean()`

#### Optional Columns (if `include.sample.summary = TRUE`):

8. **`rab.sample.<sample_id>`** - Median CLR value per sample
   - Type: `numeric`
   - One column per sample
   - Description: Median CLR value for each individual sample

## Processing Steps

1. **Validate conditions:**

   - Check exactly 2 condition levels
   - Check at least 2 replicates per condition

2. **Calculate relative abundances (rab):**

   - `rab.all`: Median across all samples and MC instances
   - `rab.win`: Median per condition
   - `rab.spl`: Median per sample (if requested)

3. **Calculate differences:**

   - `diff.win`: Within-condition absolute differences (sampled, max 10000 comparisons)
   - `diff.btw`: Between-condition signed differences (sampled, max 10000 comparisons)

4. **Calculate effect size:**

   - For each feature: `effect = diff.btw / max(within-condition differences)`
   - Normalizes effect by within-group variation

5. **Calculate overlap:**
   - For each feature: proportion of effect distribution on each side of zero
   - Uses `aitchison.mean()` for calculation

## Side Effects

- Prints progress messages if `verbose=TRUE`:
  - "sanity check complete"
  - "rab.all complete"
  - "rab.win complete"
  - "rab of samples complete"
  - "within sample difference calculated"
  - "between group difference calculated"
  - "group summaries calculated"
  - "effect size calculated"
  - "summarizing output"
- Calls `gc()` for memory management

## Dependencies

- `aitchison.mean()` - Overlap calculation
- `BiocParallel::bplapply()` - Parallel processing (if `useMC=TRUE`)
- `base::lapply()` - Serial processing
- S4 accessor methods: `getMonteCarloInstances()`, `getMonteCarloReplicate()`, etc.

## Example Usage

```r
data(selex)
conds <- c(rep("NS", 7), rep("S", 7))
x.clr <- aldex.clr(selex, conds, mc.samples=128)
x.effect <- aldex.effect(x.clr, conds,
                         include.sample.summary=FALSE)
```

## Notes

- Only works with 2-condition comparisons
- Effect size is normalized by within-group variation
- Overlap metric indicates confidence in direction of effect
- Uses sampling (max 10000 comparisons) for computational efficiency
- Memory-intensive due to large intermediate matrices
