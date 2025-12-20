# Notes for `aldex()`

- **Role**: Main user-facing wrapper that orchestrates CLR transformation, statistical testing, and effect-size calculation (see `Package_Inventory.md`).
- **Dependencies**: Delegates to `aldex.clr()`, `aldex.ttest()`, `aldex.glm()`, and `aldex.effect()` as summarized in `Function_Inventory_Summary.md`.
- **Test coverage**: Minimally tested (~5% of parameter space); see `Test_Coverage_Report.md` for gaps and recommended test matrix.
- **Optimization priority**: Marked **LOW** in `R_Code_Optimization_Summary.md` (most cost is in callees), but correctness is critical.
- **Translation note**: In Julia, keep this wrapper thin and declarative; focus optimization effort on lower-level functions while ensuring end-to-end behaviour remains identical.


