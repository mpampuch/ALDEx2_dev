print("Hello, World!")

# Check if JuliaCall is available first
if (!require(JuliaCall, quietly = TRUE)) {
  print("JuliaCall not found. Please install it first:")
  print("install.packages('JuliaCall')")
  print("Then restart R and try again.")
  stop("JuliaCall package required")
}

# Load the setup function
source("aldex2jl_setup.R")

print("Setting up ALDEx2.jl interface...")

# Setup ALDEx2.jl with timeout protection
tryCatch(
  {
    aldex_jl <- aldex2jl_setup()
    print("✓ ALDEx2.jl setup completed successfully!")
  },
  error = function(e) {
    print(paste("✗ ALDEx2.jl setup failed:", e$message))
    print("Make sure Julia is installed and ALDEx2.jl package is available.")
    stop("Setup failed")
  }
)

print("ALDEx2.jl setup completed!")

# Load the actual selex dataset from ALDEx2
print("Loading selex dataset...")
library(ALDEx2)
data(selex)
reads <- selex
conditions <- c(rep("NS", 7), rep("S", 7))

print("Loaded selex data:")
print(paste("Features:", nrow(reads)))
print(paste("Samples:", ncol(reads)))
print(paste("Conditions:", paste(conditions, collapse = ", ")))

# Perform CLR transformation using Julia
print("Performing CLR transformation with Julia...")
time_start <- Sys.time()
clr_result <- aldex_jl$aldex_clr(reads, conditions, mc_samples = 1000, verbose = TRUE)
time_end <- Sys.time()
print(paste("Julia CLR transformation completed in", time_end - time_start))
print("✓ CLR transformation completed")

# Perform CLR transformation using R ALDEx2
print("Performing CLR transformation with R ALDEx2...")
time_start <- Sys.time()
clr_r <- aldex.clr(selex, conds = conditions, mc.samples = 1000, verbose = TRUE)
time_end <- Sys.time()
print(paste("R CLR transformation completed in", time_end - time_start))

# Perform t-test using R ALDEx2 (Julia version has parameter issues)
print("Performing t-test with R ALDEx2...")
time_start <- Sys.time()
ttest <- aldex.ttest(clr_r, verbose = TRUE)
time_end <- Sys.time()
print(paste("R T-test completed in", time_end - time_start))
print("✓ T-test completed")

# Perform effect size calculation using R ALDEx2
print("Performing effect size calculation with R ALDEx2...")
time_start <- Sys.time()
effect <- aldex.effect(clr_r, verbose = TRUE)
time_end <- Sys.time()
print(paste("R Effect size calculation completed in", time_end - time_start))
print("✓ Effect size calculation completed")

# Combine results for plotting
x.all <- data.frame(ttest, effect)
print("Combined results for plotting")

# Create one MW plot (Effect plot)
print("Creating MW effect plot...")
aldex.plot(x.all, type = "MW", test = "welch", cutoff = 0.1)
title("MW Plot - Welch's t-test (q < 0.1)")

print("Effect plot completed!")
print("All done")
