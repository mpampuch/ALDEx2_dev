# Function Signature: `rdirichlet()`

## Function Information

- **File:** `R/rdirichlet.r`
- **Type:** Internal function (not exported)
- **Category:** Distribution sampling
- **License:** Copied from mc2d R package (GPL>=2, compatible with AGPL3)

## Function Signature

```r
rdirichlet(n, alpha)
```

## Input Parameters

### `n`

- **Type:** `integer` or `numeric` (coerced to integer)
- **Required:** Yes
- **Constraints:**
  - Must be non-negative
  - If vector, uses `length(n)`
  - If length 0, returns `numeric(0)`
- **Note:** Number of Dirichlet samples to generate

### `alpha`

- **Type:** `vector` or `matrix`
- **Required:** Yes
- **Constraints:**
  - Must be positive (Dirichlet parameters)
  - If vector, converted to row matrix via `t(alpha)`
- **Dimensions:**
  - If vector: length = number of categories
  - If matrix: columns = categories, rows = different parameter sets
- **Note:** Dirichlet distribution parameters (concentration parameters)

## Output

### Return Type

- **Type:** `matrix`
- **Dimensions:**
  - Rows: `n` (number of samples)
  - Columns: `length(alpha)` or `ncol(alpha)` (number of categories)
- **Values:**
  - Each row sums to 1.0 (probability vector)
  - Non-negative values
  - Represents proportions/probabilities

## Algorithm

1. Generate `n * length(alpha)` gamma random variates
2. Reshape into `n × length(alpha)` matrix
3. Normalize each row to sum to 1.0

## Implementation Details

```r
# Simplified version of algorithm:
x <- matrix(rgamma(l * n, t(alpha)), ncol = l, byrow=TRUE)
return(x / rowSums(x))
```

Where:

- `l` = number of categories (length or ncol of alpha)
- `n` = number of samples
- Each element is gamma-distributed with shape = alpha parameter
- Rows are normalized to form probability vectors

## Example Usage

```r
# Generate 10 samples from Dirichlet with 3 categories
# Parameters: alpha = c(1, 1, 1) (uniform)
samples <- rdirichlet(10, c(1, 1, 1))
# Result: 10 × 3 matrix, each row sums to 1.0

# Generate samples with different parameters
samples <- rdirichlet(5, c(2, 2, 2))
```

## Dependencies

- `stats::rgamma()` - Gamma random number generation
- `base::rowSums()` - Row sum calculation

## Notes

- Used internally by `aldex.clr()` for Monte Carlo sampling
- Each sample column in ALDEx2 gets `mc.samples` Dirichlet instances
- Parameters (alpha) are the read counts + 0.5 prior for each feature
- Returns probability vectors consistent with observed proportions
- Critical for modeling technical variation in sequencing data
