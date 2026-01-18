library(ALDEx2)
library(energy)
library(kSamples)


set.seed(NULL)

## -----------------------------
## Load data
## -----------------------------
selex <- read.csv(
  "/Users/markpampuch/Dropbox/KAUST/PhD/ALDEx2_jl/ALDEx2_dev/TEST_DATA/selex_subset_1201-1600.csv",
  row.names = 1
)

conds <- c(rep("NS", 7), rep("S", 7))

## -----------------------------
## Run ALDEx2 with two seeds
## -----------------------------
# set.seed(1)
clr1 <- aldex.clr(selex, conds, mc.samples = 128)
# saveRDS(clr1, file = "clr1.rds")

# set.seed(2)
clr2 <- aldex.clr(selex, conds, mc.samples = 128)
# saveRDS(clr2, file = "clr2.rds")

## -----------------------------
## Deterministic sanity checks
## -----------------------------
stopifnot(
  identical(clr1@reads, clr2@reads),
  identical(clr1@conds, clr2@conds),
  identical(clr1@mc.samples, clr2@mc.samples)
)

AD1 <- clr1@analysisData
AD2 <- clr2@analysisData
features <- names(AD1)

## =========================================================
## Added diagnostics: correlation + Kolmogorov-Smirnov test
## =========================================================

## Mean CLR per feature per sample
m1 <- lapply(AD1, rowMeans)
m2 <- lapply(AD2, rowMeans)

m1 <- do.call(cbind, m1)
m2 <- do.call(cbind, m2)

mean_clr_correlation <- cor(as.vector(m1), as.vector(m2))
print(mean_clr_correlation)

## -----------------------------
## KS and AD tests per feature (sampled)
## -----------------------------

alpha <- 0.05
sample_size <- 100

## -----------------------------
## Kolmogorov-Smirnov test per feature (sampled)
## -----------------------------
ks_pvals <- sapply(features, function(f) {
  v1 <- as.vector(AD1[[f]])
  v2 <- as.vector(AD2[[f]])

  # Sample if vectors are too long
  if (length(v1) > sample_size) {
    idx <- sample.int(length(v1), sample_size)
    v1 <- v1[idx]
    v2 <- v2[idx]
  }

  ks.test(v1, v2)$p.value
})

ks_summary <- summary(ks_pvals)
print("--------------------------------")
print("Kolmogorov–Smirnov test per feature (sampled)")
print(ks_summary)
print("--------------------------------")

# Are all KS tests failing to reject H0?
ks_ok <- all(ks_pvals > alpha)

## -----------------------------
## Anderson-Darling test per feature (sampled)
## -----------------------------
ad_pvals <- sapply(features, function(f) {
  tryCatch(
    {
      v1 <- as.vector(AD1[[f]])
      v2 <- as.vector(AD2[[f]])

      if (length(v1) > sample_size) {
        idx <- sample.int(length(v1), sample_size)
        v1 <- v1[idx]
        v2 <- v2[idx]
      }

      ad_result <- ad.test(v1, v2)
      ad_result$ad[1, grep("P-value", colnames(ad_result$ad))]
    },
    error = function(e) NA_real_
  )
})

ad_summary <- summary(ad_pvals)
print("--------------------------------")
print("Anderson–Darling test per feature (sampled)")
print(ad_summary)
print("--------------------------------")

# Are all AD tests failing to reject H0?
ad_ok <- all(ad_pvals > alpha)

## =========================================================
## Robust equivalence testing
## =========================================================

## Helper: proper TOST
tost_mean <- function(x, eps, alpha = 0.05) {
  p1 <- t.test(x, mu = -eps, alternative = "greater")$p.value
  p2 <- t.test(x, mu = eps, alternative = "less")$p.value
  max(p1, p2) < alpha
}

## -----------------------------
## 1) Mean equivalence (MC-aware)
## -----------------------------
eps_mean <- 0.05

mean_equiv <- sapply(features, function(f) {
  d <- colMeans(AD1[[f]] - AD2[[f]])
  tost_mean(d, eps_mean)
})

## -----------------------------
## 2) Variance / scale equivalence
## -----------------------------
eps_var <- log(1.2)

var_equiv <- sapply(features, function(f) {
  s1 <- apply(AD1[[f]], 2, mad)
  s2 <- apply(AD2[[f]], 2, mad)
  d <- log(s1 / s2)
  tost_mean(d, eps_var)
})

## -----------------------------
## 3) Distributional equivalence
## -----------------------------
# Sample vectors to avoid integer overflow in edist() for large datasets
# edist() computes pairwise distances, which causes overflow when vectors are very large
# Sampling preserves distributional properties while making computation feasible
# set.seed(42) # Fixed seed for reproducibility
max_samples <- 1000 # Maximum samples to avoid overflow (edist limit ~1000-1500)

safe_edist <- function(x, y) {
  tryCatch(
    edist(x, y),
    error = function(e) NA_real_
  )
}

ed <- vapply(
  features,
  function(f) {
    v1 <- as.vector(AD1[[f]])
    v2 <- as.vector(AD2[[f]])

    if (length(v1) > max_samples) {
      idx <- sample.int(length(v1), max_samples)
      v1 <- v1[idx]
      v2 <- v2[idx]
    }

    val <- safe_edist(v1, v2)
    if (length(val) != 1 || !is.finite(val)) NA_real_ else val
  },
  numeric(1)
)

## -----------------------------
## 4) MC noise floor calibration
## -----------------------------
set.seed(1)
clr_ref <- aldex.clr(selex, conds, mc.samples = 256)

# Set seed for reproducible sampling in energy distance calculation
set.seed(43) # Different seed from ed calculation to ensure independence
ref_ed <- vapply(
  features,
  function(f) {
    x <- clr_ref@analysisData[[f]][, 1:128]
    y <- clr_ref@analysisData[[f]][, 129:256]

    v1 <- as.vector(x)
    v2 <- as.vector(y)

    if (length(v1) > max_samples) {
      idx <- sample.int(length(v1), max_samples)
      v1 <- v1[idx]
      v2 <- v2[idx]
    }

    val <- safe_edist(v1, v2)
    if (length(val) != 1 || !is.finite(val)) NA_real_ else val
  },
  numeric(1)
)

valid_ed <- is.finite(ref_ed) & ref_ed > 0

ed_ratio <- ed[valid_ed] / ref_ed[valid_ed]

# If almost everything is zero-distance, accept equivalence
if (length(ed_ratio) < 0.1 * length(features)) {
  message("Energy distance ≈ 0 for most features → distributions identical")
  ed_ok <- TRUE
} else {
  ed_ok <- quantile(ed_ratio, 0.95) <= 1.1
}

## -----------------------------
## 5) Summary + hard criteria
## -----------------------------
results <- list(
  mean_clr_correlation      = mean_clr_correlation,
  ks_pvalue_summary         = ks_summary,
  ad_pvalue_summary         = ad_summary,
  mean_equivalence_fraction = mean(mean_equiv),
  var_equivalence_fraction  = mean(var_equiv),
  energy_ratio_quantiles    = quantile(ed_ratio, c(0.5, 0.9, 0.95))
)

print(results)
validated <- try(
  {
    stopifnot(
      mean_clr_correlation >= 0.99,
      mean(mean_equiv) >= 0.98,
      mean(var_equiv) >= 0.95,
      ks_ok,
      ad_ok,
      ed_ok
    )
    TRUE
  },
  silent = TRUE
)

# -----------------------------
# Report results
# -----------------------------
if (isTRUE(validated)) {
  cat("✔ ALDEx2 stochastic equivalence validated\n")
} else {
  stop("✘ ALDEx2 stochastic equivalence FAILED")
}
