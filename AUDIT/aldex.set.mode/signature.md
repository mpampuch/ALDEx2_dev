# Function Signature: `aldex.set.mode()`

## Function Information

- **File:** `R/iqlr_features.r`
- **Type:** Exported function
- **Category:** Feature selection

## Function Signature

```r
aldex.set.mode(reads, conds, denom="all")
```

## Input Parameters

### `reads`

- **Type:** `data.frame` or `matrix`
- **Required:** Yes
- **Constraints:**
  - Non-negative integers
  - Unique row/column names
- **Dimensions:**
  - Rows: Features
  - Columns: Samples
- **Note:** Read count matrix (before prior addition)

### `conds`

- **Type:** `vector` (character)
- **Required:** Yes
- **Constraints:**
  - Length matches number of columns in `reads`
- **Dimensions:** Length = number of samples
- **Example:** `c(rep("A", 7), rep("B", 7))`

### `denom`

- **Type:** `character` string or `numeric` vector
- **Required:** No (default: "all")
- **Valid values:**
  - `"all"` - Use all features (default)
  - `"iqlr"` - Inter-quartile log-ratio features
  - `"zero"` - Non-zero features per condition
  - `numeric` vector - Custom feature indices
- **Default:** `"all"`

## Output

### Return Type

- **Type:** `list` of `numeric` vectors
- **Length:** Number of unique conditions
- **Names:** Condition names (if applicable)
- **Each element:**
  - **Type:** `numeric` vector
  - **Values:** Feature indices (1-based)
  - **Note:** Indices refer to rows in `reads` (after removing zero-sum rows)

### Output Structure by Mode

#### `denom = "all"`:

- Returns list with one vector per condition
- Each vector contains all feature indices: `1:nrow(reads)`

#### `denom = "iqlr"`:

- Returns list with one vector per condition
- Each vector contains indices of features with variance between 1st and 3rd quartile
- Same indices for all conditions

#### `denom = "zero"`:

- Returns list with one vector per condition
- Each vector contains indices of non-zero features for that condition
- Different indices per condition (condition-specific)

#### `denom = numeric` vector:

- Returns list with one vector per condition
- Each vector contains the custom indices provided
- Same indices for all conditions

## Processing Steps

1. **Validate input:**

   - Check `denom` type (character or numeric)
   - If character, validate against known modes

2. **Route to appropriate function:**

   - `"all"` → `all.features()`
   - `"iqlr"` → `iqlr.features()`
   - `"zero"` → `zero.features()`
   - `numeric` → `custom.features()`

3. **Return feature indices:**
   - List format expected by `aldex.clr.function()`

## Side Effects

- Prints mode selection message:
  - "computing zero removal"
  - "computing iqlr centering"
  - "computing center with all features"
  - Or warning if unrecognized mode

## Dependencies

- `all.features()` - All features mode
- `iqlr.features()` - IQLR feature selection
- `zero.features()` - Zero-inflated feature handling
- `custom.features()` - Custom feature indices

## Example Usage

```r
data(selex)
conds <- c(rep("NS", 7), rep("S", 7))

# All features
features <- aldex.set.mode(selex, conds, denom="all")

# IQLR features
features <- aldex.set.mode(selex, conds, denom="iqlr")

# Zero-inflated handling
features <- aldex.set.mode(selex, conds, denom="zero")

# Custom features
features <- aldex.set.mode(selex, conds, denom=c(1, 5, 10, 20))
```

## Notes

- Determines which features are used for geometric mean calculation in CLR
- IQLR mode selects features with intermediate variance (robust to systematic variation)
- Zero mode handles cases with many zeros in one condition but not another
- Custom mode allows user-specified invariant features (e.g., housekeeping genes)
