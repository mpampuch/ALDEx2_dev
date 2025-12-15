# Function Signature: `aitchison.mean()`

## Function Information

- **File:** `R/rdirichlet.r`
- **Type:** Internal function (not exported)
- **Category:** Statistical calculation
- **Purpose:** Calculate Aitchison mean (expected frequencies from counts)

## Function Signature

```r
aitchison.mean(n, log=FALSE)
```

## Input Parameters

### `n`

- **Type:** `vector` of `numeric` (coerced and rounded)
- **Required:** Yes
- **Constraints:**
  - Must be non-negative integers (counts)
  - Rounded to nearest integer
- **Dimensions:** Length = number of categories/features
- **Note:** Input count vector

### `log`

- **Type:** `logical` (boolean)
- **Required:** No (default: FALSE)
- **Default:** FALSE
- **Note:** If TRUE, returns log-frequencies with uninformative subspace removed

## Output

### Return Type

- **Type:** `vector` of `numeric`
- **Dimensions:** Same length as input `n`
- **Values:**
  - If `log=FALSE`: Probability vector (sums to 1.0)
  - If `log=TRUE`: Log-probabilities (mean-centered, sums to 0)

## Algorithm

1. Add 0.5 prior to counts: `a = n + 0.5`
2. Calculate log-probabilities using digamma:
   - `log.p = digamma(a) - digamma(sum(a))`
3. Center log-probabilities: `log.p = log.p - mean(log.p)`
4. If `log=TRUE`: Return centered log-probabilities
5. If `log=FALSE`:
   - Exponentiate: `p = exp(log.p - max(log.p))`
   - Normalize: `p = p / sum(p)`
   - Return probability vector

## Mathematical Background

The Aitchison mean uses the digamma function to compute expected log-frequencies from count data. The digamma function is the derivative of the log-gamma function and is used in Dirichlet distribution calculations.

## Example Usage

```r
# Count vector
counts <- c(10, 20, 30, 40)

# Get probability vector
probs <- aitchison.mean(counts, log=FALSE)
# Result: c(0.15, 0.25, 0.30, 0.30) approximately (sums to 1.0)

# Get log-probabilities
log_probs <- aitchison.mean(counts, log=TRUE)
# Result: Mean-centered log-probabilities (sums to 0)
```

## Dependencies

- `base::digamma()` - Digamma function
- `base::exp()` - Exponential function
- `base::mean()` - Mean calculation
- `base::sum()` - Sum calculation

## Usage in ALDEx2

- Used in `aldex.effect()` for calculating overlap proportions
- Specifically: `aitchison.mean(c(sum(row < 0), sum(row > 0)) + 0.5)`
- Used to compute the proportion of effect size distribution overlapping zero

## Notes

- Implements Aitchison's approach to compositional data analysis
- Uses 0.5 prior (same as main ALDEx2 workflow)
- Log-space calculations avoid numerical underflow
- Mean-centering removes uninformative subspace in log-space
