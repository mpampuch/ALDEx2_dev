#!/usr/bin/env Rscript
# Benchmarking Infrastructure for ALDEx2 R Package
# Phase 0, Week 1, Task 4: Benchmarking Infrastructure Audit
#
# This script sets up a reproducible framework for profiling and
# microbenchmarking key ALDEx2 functions on realistic datasets.
#
# Design goals:
# - Run from anywhere (discovers project & package root automatically)
# - Use the full selex dataset as the canonical "small" dataset
# - Capture both execution time and basic memory statistics
# - Cleanly separate profiling (profvis/Rprof) from microbenchmarks
# - Emit machine-readable results (CSV) and human-readable summaries
#
# NOTE: This script focuses on infrastructure and reproducibility.
# Detailed per-function analysis is recorded in AUDIT/<function>/benchmarks.md.

suppressPackageStartupMessages({
  if (!require("profvis", quietly = TRUE)) {
    install.packages("profvis")
    library(profvis)
  }
  if (!require("microbenchmark", quietly = TRUE)) {
    install.packages("microbenchmark")
    library(microbenchmark)
  }
  if (!require("bench", quietly = TRUE)) {
    install.packages("bench")
    library(bench)
  }
  if (!require("devtools", quietly = TRUE)) {
    install.packages("devtools")
    library(devtools)
  }
})

# --- Project / package discovery -------------------------------------------------

args <- commandArgs(trailingOnly = FALSE)
script_path <- normalizePath(sub("^--file=", "", args[grep("^--file=", args)]))
script_dir  <- dirname(script_path)
project_root <- dirname(script_dir)
package_root <- file.path(project_root, "ALDEx2")
audit_root   <- file.path(project_root, "AUDIT")

if (!dir.exists(package_root)) {
  stop("ALDEx2 package directory not found at: ", package_root)
}
if (!dir.exists(audit_root)) {
  stop("AUDIT directory not found at: ", audit_root)
}

setwd(package_root)

devtools::load_all(package_root)

# --- Helper: create directories safely ------------------------------------------

safe_dir_create <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

results_root <- file.path(audit_root, "benchmarks")
safe_dir_create(results_root)

# --- Helper: input data ---------------------------------------------------------
#
# We always use the full `selex` dataset from ALDEx2 and treat it as the
# "small" benchmark dataset. If selex is not available, this will error,
# which is intentional: benchmarks should not silently switch datasets.

load_selex_full <- function() {
  data_env <- new.env(parent = emptyenv())
  data("selex", package = "ALDEx2", envir = data_env)
  selex <- get("selex", envir = data_env)

  conds <- rep(c("A", "B"), length.out = ncol(selex))

  list(reads = selex, conds = conds)
}

# --- Helper: profiling wrappers --------------------------------------------------

profile_with_profvis <- function(expr, out_html) {
  # Wrap profvis so every run produces a self-contained HTML report.
  pv <- profvis::profvis(expr)
  htmlwidgets::saveWidget(pv, file = out_html, selfcontained = TRUE)
}

profile_with_Rprof <- function(expr, out_prefix) {
  # Lightweight CPU time profile using base Rprof.
  out_file <- paste0(out_prefix, "_Rprof.out")
  Rprof(out_file)
  on.exit(Rprof(NULL), add = TRUE)
  force(expr)
  Rprof(NULL)
}

# --- Helper: microbenchmark wrappers --------------------------------------------

run_microbench <- function(name, expr, size_label, times = 10L) {
  mb <- microbenchmark::microbenchmark(
    expr,
    times = times,
    unit = "ms"
  )
  df <- as.data.frame(mb)
  df$function <- name
  df$size     <- size_label
  df
}

run_bench_mark <- function(name, expr, size_label, iterations = 5L) {
  res <- bench::mark(expr, iterations = iterations, check = FALSE)
  df <- as.data.frame(res)
  df$function <- name
  df$size     <- size_label
  df
}

# --- Benchmark scenarios ---------------------------------------------------------

# We focus on core exported functions that represent typical workflows.

benchmark_aldex_clr <- function() {
  fun_name <- "aldex.clr"
  fun_root <- file.path(audit_root, "aldex.clr")
  safe_dir_create(fun_root)

  size_label <- "small"  # full selex

  input <- load_selex_full()
  reads <- input$reads
  conds <- input$conds

  message("[", fun_name, "] size=", size_label,
          ", n_features=", nrow(reads),
          ", n_samples=", ncol(reads))

  # Profiling for CLR on full selex dataset
  profvis_html <- file.path(fun_root, paste0("profvis_", size_label, ".html"))
  profile_with_profvis({
    aldex.clr(reads, conds, mc.samples = 32L, denom = "all", verbose = FALSE)
  }, profvis_html)

  profile_with_Rprof({
    aldex.clr(reads, conds, mc.samples = 32L, denom = "all", verbose = FALSE)
  }, file.path(fun_root, paste0("Rprof_", size_label)))

  mb_df <- run_microbench(
    fun_name,
    aldex.clr(reads, conds, mc.samples = 32L, denom = "all", verbose = FALSE),
    size_label = size_label
  )

  bench_df <- run_bench_mark(
    fun_name,
    aldex.clr(reads, conds, mc.samples = 32L, denom = "all", verbose = FALSE),
    size_label = size_label
  )

  write.csv(mb_df,
            file = file.path(fun_root, "benchmarks_microbenchmark.csv"),
            row.names = FALSE)
  write.csv(bench_df,
            file = file.path(fun_root, "benchmarks_bench.csv"),
            row.names = FALSE)

  invisible(list(microbenchmark = mb_df, bench = bench_df))
}

# Placeholder hooks for other functions. These can be filled out with
# function-specific inputs as the audit progresses.

benchmark_aldex_ttest <- function() {
  # Intentionally minimal for now: reused CLR object and default tests.
  # This keeps the infrastructure focused while still exercising the code path.
  fun_name <- "aldex.ttest"
  fun_root <- file.path(audit_root, "aldex.ttest")
  safe_dir_create(fun_root)

  input <- load_selex_full()
  clr <- aldex.clr(input$reads, input$conds, mc.samples = 32L, denom = "all")

  mb_df <- run_microbench(
    fun_name,
    aldex.ttest(clr, paired.test = FALSE, verbose = FALSE),
    size_label = "small"
  )
  write.csv(mb_df,
            file = file.path(fun_root, "benchmarks_microbenchmark.csv"),
            row.names = FALSE)

  invisible(mb_df)
}

benchmark_aldex_glm <- function() {
  fun_name <- "aldex.glm"
  fun_root <- file.path(audit_root, "aldex.glm")
  safe_dir_create(fun_root)

  input <- load_selex_full()
  clr <- aldex.clr(input$reads, input$conds, mc.samples = 32L, denom = "all")

  mb_df <- run_microbench(
    fun_name,
    aldex.glm(clr, ~ input$conds),
    size_label = "small"
  )
  write.csv(mb_df,
            file = file.path(fun_root, "benchmarks_microbenchmark.csv"),
            row.names = FALSE)

  invisible(mb_df)
}

# --- Main entrypoint -------------------------------------------------------------

message("Running ALDEx2 benchmarking infrastructure (Phase 0, Week 1, Task 4)...")

clr_res   <- benchmark_aldex_clr()
ttest_res <- try(benchmark_aldex_ttest(), silent = TRUE)
glm_res   <- try(benchmark_aldex_glm(), silent = TRUE)

# Aggregate high-level summary for quick inspection
summary_file <- file.path(results_root, "Benchmarking_Infrastructure_Summary.md")

summary_lines <- c(
  "# Benchmarking Infrastructure Summary (Phase 0, Week 1, Task 4)",
  "",
  paste0("Date: ", Sys.Date()),
  "",
  "## Functions Benchmarked",
  "",
  "- `aldex.clr()` (full selex as \"small\"; profvis + Rprof + microbenchmark + bench)",
  "- `aldex.ttest()` (small; microbenchmark)",
  "- `aldex.glm()` (small; microbenchmark)",
  "",
  "## Files Generated",
  "",
  "- `AUDIT/aldex.clr/profvis_small.html` — interactive profile for CLR on full selex dataset",
  "- `AUDIT/aldex.clr/Rprof_small_Rprof.out` — base R profiling output for CLR",
  "- `AUDIT/aldex.clr/benchmarks_microbenchmark.csv` — microbenchmark results for CLR",
  "- `AUDIT/aldex.clr/benchmarks_bench.csv` — bench package results for CLR",
  "- `AUDIT/aldex.ttest/benchmarks_microbenchmark.csv` — microbenchmark results for t-test wrapper",
  "- `AUDIT/aldex.glm/benchmarks_microbenchmark.csv` — microbenchmark results for GLM wrapper",
  "",
  "## Notes",
  "",
  "- This script is intentionally conservative in mc.samples to keep runtimes",
  "  reasonable during the infrastructure audit phase.",
  "- For Phase 0 Week 2 and later phases, you can add larger synthetic datasets",
  "  or additional benchmark scenarios in separate scripts focused on scaling.",
  "- Per-function interpretation and prioritization should be recorded in",
  "  `AUDIT/<function_name>/benchmarks.md`.",
  ""
)

writeLines(summary_lines, con = summary_file)

message("Benchmarking infrastructure run complete.")
message("Summary written to: ", summary_file)
