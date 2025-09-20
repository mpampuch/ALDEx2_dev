# ALDEx2.jl R Interface
# This file provides an R interface to the Julia ALDEx2.jl package
# Based on the diffeqr package pattern

#' Setup ALDEx2.jl for use in R
#'
#' This function initializes the Julia environment and loads the ALDEx2.jl package.
#' It follows the same pattern as diffeqr::diffeq_setup().
#'
#' @return A list containing Julia functions for ALDEx2 analysis
#' @export
aldex2jl_setup <- function() {
  # Check if JuliaCall is available
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    stop("JuliaCall package is required. Install with: install.packages('JuliaCall')")
  }

  # Initialize Julia
  julia <- JuliaCall::julia_setup()

  # Add the ALDEx2.jl package path
  package_path <- system.file("..", "ALDEx2_jl", package = "ALDEx2_jl", mustWork = FALSE)
  if (package_path == "" || !dir.exists(package_path)) {
    # Try to find the package in the current working directory
    package_path <- file.path(getwd(), "ALDEx2_jl")
    if (!dir.exists(package_path)) {
      stop("ALDEx2.jl package not found. Please ensure it's in the correct location.")
    }
  }

  # Activate the Julia environment
  JuliaCall::julia_command(paste0("using Pkg; Pkg.activate(\"", package_path, "\")"))

  # Load the ALDEx2.jl package
  JuliaCall::julia_library("ALDEx2_jl")

  # Create the interface object
  aldex2jl <- list()

  # CLR transformation function
  aldex2jl$aldex_clr <- function(reads, conditions, mc_samples = 128,
                                 denominator = "all", verbose = FALSE, use_mc = FALSE) {
    # Convert R data to Julia format
    if (is.data.frame(reads)) {
      reads_matrix <- as.matrix(reads)
    } else {
      reads_matrix <- reads
    }

    # Convert to Julia DataFrame
    JuliaCall::julia_assign("reads_df", reads_matrix)
    JuliaCall::julia_command("using DataFrames; reads_df = DataFrame(reads_df, :auto)")

    # Convert conditions to Julia vector
    JuliaCall::julia_assign("conditions_vec", conditions)
    JuliaCall::julia_command("conditions_vec = String.(conditions_vec)")

    # Call Julia function
    JuliaCall::julia_command(paste0(
      "clr_result = aldex_clr(reads_df, conditions_vec, ",
      "mc_samples = ", mc_samples, ", ",
      "denominator = \"", denominator, "\", ",
      "verbose = ", tolower(verbose), ", ",
      "use_mc = ", tolower(use_mc), ")"
    ))

    # Return the Julia object (you might want to extract specific fields)
    return(JuliaCall::julia_eval("clr_result"))
  }

  # T-test function
  aldex2jl$aldex_ttest <- function(clr_obj, verbose = FALSE) {
    JuliaCall::julia_assign("clr_input", clr_obj)
    JuliaCall::julia_command(paste0(
      "ttest_result = aldex_ttest(clr_input, verbose = ", tolower(verbose), ")"
    ))
    return(JuliaCall::julia_eval("ttest_result"))
  }

  # Effect size function
  aldex2jl$aldex_effect <- function(clr_obj, verbose = TRUE) {
    JuliaCall::julia_assign("clr_input", clr_obj)
    JuliaCall::julia_command(paste0(
      "effect_result = aldex_effect(clr_input, verbose = ", tolower(verbose), ")"
    ))
    return(JuliaCall::julia_eval("effect_result"))
  }

  # Main aldex function
  aldex2jl$aldex <- function(reads, conditions, mc_samples = 128,
                             test = "t", effect = TRUE, verbose = FALSE,
                             denominator = "all") {
    # Convert R data to Julia format
    if (is.data.frame(reads)) {
      reads_matrix <- as.matrix(reads)
    } else {
      reads_matrix <- reads
    }

    # Convert to Julia DataFrame
    JuliaCall::julia_assign("reads_df", reads_matrix)
    JuliaCall::julia_command("using DataFrames; reads_df = DataFrame(reads_df, :auto)")

    # Convert conditions to Julia vector
    JuliaCall::julia_assign("conditions_vec", conditions)
    JuliaCall::julia_command("conditions_vec = String.(conditions_vec)")

    # Call Julia function
    JuliaCall::julia_command(paste0(
      "aldex_result = aldex(reads_df, conditions_vec, ",
      "mc_samples = ", mc_samples, ", ",
      "test = \"", test, "\", ",
      "effect = ", tolower(effect), ", ",
      "verbose = ", tolower(verbose), ", ",
      "denominator = \"", denominator, "\")"
    ))

    return(JuliaCall::julia_eval("aldex_result"))
  }

  # Utility functions
  aldex2jl$validate_inputs <- function(reads, conditions) {
    if (is.data.frame(reads)) {
      reads_matrix <- as.matrix(reads)
    } else {
      reads_matrix <- reads
    }

    JuliaCall::julia_assign("reads_df", reads_matrix)
    JuliaCall::julia_command("using DataFrames; reads_df = DataFrame(reads_df, :auto)")
    JuliaCall::julia_assign("conditions_vec", conditions)
    JuliaCall::julia_command("conditions_vec = String.(conditions_vec)")

    JuliaCall::julia_command("validate_inputs(reads_df, conditions_vec)")
    return(JuliaCall::julia_eval("true"))
  }

  return(aldex2jl)
}

#' Example usage of ALDEx2.jl in R
#'
#' This function demonstrates how to use the ALDEx2.jl interface in R
#'
#' @export
aldex2jl_example <- function() {
  # Setup ALDEx2.jl
  aldex <- aldex2jl_setup()

  # Create example data
  set.seed(123)
  reads <- matrix(sample(0:100, 100 * 8, replace = TRUE), nrow = 100, ncol = 8)
  conditions <- c(rep("A", 4), rep("B", 4))

  print("Running ALDEx2.jl example...")

  # Perform CLR transformation
  clr_result <- aldex$aldex_clr(reads, conditions, verbose = TRUE)
  print("CLR transformation completed")

  # Perform t-test
  ttest_result <- aldex$aldex_ttest(clr_result, verbose = TRUE)
  print("T-test completed")

  # Calculate effect sizes
  effect_result <- aldex$aldex_effect(clr_result, verbose = TRUE)
  print("Effect size calculation completed")

  # Or use the main aldex function
  aldex_result <- aldex$aldex(reads, conditions, verbose = TRUE)
  print("Complete ALDEx2 analysis completed")

  return(list(
    clr = clr_result,
    ttest = ttest_result,
    effect = effect_result,
    aldex = aldex_result
  ))
}
