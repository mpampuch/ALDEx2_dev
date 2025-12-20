# Notes for `aitchison.mean()`

- **Role**: Computes Aitchison means used in effect-size calculations within `aldex.effect()`.
- **Dependencies**: Operates on CLR-like compositions, as summarized in `Package_Inventory.md`.
- **Test coverage**: Indirect only; no dedicated tests.
- **Optimization priority**: Marked **MEDIUM** in `R_Code_Optimization_Summary.md` (important but not the dominant cost centre).
- **Translation note**: Emphasize numerical stability and type-stable implementations in Julia, potentially using `SpecialFunctions.jl` for `digamma` and related operations.


