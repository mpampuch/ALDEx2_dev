#!/usr/bin/env Rscript
# Test Coverage Analysis for ALDEx2 R Package
# Phase 0, Week 1, Task 2

# Load required packages
if (!require("covr", quietly = TRUE)) {
  if (!require("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("r-lib/covr")
}

if (!require("testthat", quietly = TRUE)) {
  install.packages("testthat")
}

library(covr)
library(testthat)

# Set working directory to ALDEx2 package root
# Get the script directory and navigate to package root
script_dir <- dirname(normalizePath(commandArgs(trailingOnly = FALSE)[4]))
project_root <- dirname(script_dir)
package_root <- file.path(project_root, "ALDEx2")

if (!dir.exists(package_root)) {
  stop("ALDEx2 package directory not found at: ", package_root)
}

setwd(package_root)

# Load the package
devtools::load_all(package_root)

# Run test coverage
cat("Running test coverage analysis...\n")
coverage <- package_coverage(
  path = package_root,
  type = "all",
  combine_types = TRUE
)

# Get coverage summary
coverage_summary <- covr::coverage_to_list(coverage)

# Print overall coverage
cat("\n=== Overall Test Coverage ===\n")
cat(sprintf("Total Coverage: %.2f%%\n", coverage_summary$totalcoverage))

# Get per-file coverage
file_coverage <- covr::file_coverage(coverage)
cat("\n=== Per-File Coverage ===\n")
print(file_coverage)

# Get per-function coverage
function_coverage <- covr::function_coverage(coverage)
cat("\n=== Per-Function Coverage ===\n")
print(function_coverage)

# Save detailed coverage report
cat("\nGenerating detailed coverage report...\n")
coverage_report <- covr::to_dataframe(coverage)

# Write coverage data to CSV
write.csv(coverage_report,
  file = file.path(dirname(package_root), "AUDIT", "test_coverage_detailed.csv"),
  row.names = FALSE
)

# Write summary to file
summary_file <- file.path(dirname(package_root), "AUDIT", "test_coverage_summary.txt")
sink(summary_file)
cat("ALDEx2 Test Coverage Analysis\n")
cat("=============================\n\n")
cat(sprintf("Date: %s\n", Sys.Date()))
cat(sprintf("Package Version: %s\n\n", packageVersion("ALDEx2")))

cat("=== Overall Coverage ===\n")
cat(sprintf("Total Coverage: %.2f%%\n\n", coverage_summary$totalcoverage))

cat("=== Per-File Coverage ===\n")
print(file_coverage)
cat("\n")

cat("=== Per-Function Coverage ===\n")
print(function_coverage)
cat("\n")

cat("=== Coverage Details ===\n")
print(coverage_report)
sink()

cat("\nCoverage analysis complete!\n")
cat(sprintf("Summary saved to: %s\n", summary_file))
cat(sprintf(
  "Detailed data saved to: %s\n",
  file.path(dirname(package_root), "AUDIT", "test_coverage_detailed.csv")
))
