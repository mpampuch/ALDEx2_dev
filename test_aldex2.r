print("Hello, World!")
install.packages("/Users/markpampuch/Downloads/ALDEx2_1.41.0.gz", repos = NULL, type = "source")
print("installed ALDEx2")
library(ALDEx2)
print("loaded ALDEx2")
data(selex)
print("loaded selex data")

# Create conditions vector - selex has 14 samples (7 NS + 7 S)
conditions <- c(rep("NS", 7), rep("S", 7))
print("Conditions vector:")
print(conditions)

# Perform CLR transformation
clr <- aldex.clr(selex, conds = conditions, mc.samples = 1000, verbose = TRUE)
print("performed CLR")

# Perform t-test
ttest <- aldex.ttest(clr, verbose = TRUE)
print("performed t-test")

# Perform effect size calculation
effect <- aldex.effect(clr, verbose = TRUE)
print("performed effect size")

# Combine results for plotting
x.all <- data.frame(ttest, effect)
print("combined results for plotting")

# Create one MW plot (Effect plot)
print("Creating MW effect plot...")
aldex.plot(x.all, type = "MW", test = "welch", cutoff = 0.1)
title("MW Plot - Welch's t-test (q < 0.1)")

print("Effect plot completed!")
print("all done")
