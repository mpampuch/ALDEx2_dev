# ALDEx2 R Package Audit - Phase 0, Week 1

This directory contains the complete audit documentation for the ALDEx2 R package, performed as part of Phase 0, Week 1: Package Discovery and Inventory.

## Structure

```
AUDIT/
├── README.md                          # This file
├── Package_Inventory.md               # Complete package overview
├── Function_Inventory_Summary.md      # Quick reference for all functions
│
├── aldex/                             # Main wrapper function
│   └── signature.md
├── aldex.clr/                         # CLR transformation
│   └── signature.md
├── aldex.ttest/                       # t-test and Wilcoxon
│   └── signature.md
├── aldex.effect/                      # Effect size calculation
│   └── signature.md
├── aldex.glm/                         # GLM and Kruskal-Wallis
│   └── signature.md
├── aldex.corr/                        # Correlation analysis
│   └── signature.md
├── aldex.set.mode/                    # Feature selection
│   └── signature.md
├── rdirichlet/                        # Dirichlet sampling
│   └── signature.md
├── aitchison.mean/                    # Aitchison mean
│   └── signature.md
├── t.fast/                            # Fast t-test
│   └── signature.md
├── wilcox.fast/                       # Fast Wilcoxon test
│   └── signature.md
│
└── [Additional function folders...]
```

## Documents

### Main Documents

1. **Package_Inventory.md** - Complete package overview including:

   - Package metadata and structure
   - Complete dependency list
   - All exported and internal functions
   - S4 classes and methods
   - Test coverage information

2. **Function_Inventory_Summary.md** - Quick reference table with:
   - All functions (exported and internal)
   - Function categories
   - Input/output types
   - Dependency graph
   - Data flow diagram

### Function Signature Documents

Each function has a dedicated folder with `signature.md` containing:

- Function information (file, type, category)
- Complete function signature
- Detailed input parameter specifications:
  - Type, constraints, dimensions, examples
- Output specifications:
  - Return type, structure, dimensions
- Processing steps
- Dependencies
- Example usage
- Notes and implementation details

## Completed Functions

### Exported Functions

- ✅ `aldex()` - Main wrapper
- ✅ `aldex.clr()` - CLR transformation
- ✅ `aldex.ttest()` - Statistical tests
- ✅ `aldex.effect()` - Effect sizes
- ✅ `aldex.glm()` - GLM tests
- ✅ `aldex.corr()` - Correlations
- ✅ `aldex.set.mode()` - Feature selection

### Internal Functions

- ✅ `rdirichlet()` - Dirichlet sampling
- ✅ `aitchison.mean()` - Aitchison mean
- ✅ `t.fast()` - Fast t-test
- ✅ `wilcox.fast()` - Fast Wilcoxon

## Next Steps (Week 1 Remaining Tasks)

1. Complete signature documentation for remaining functions:

   - `aldex.plot()`
   - `iqlr.features()`
   - `zero.features()`
   - `all.features()`
   - `custom.features()`
   - `progress()`

2. Create additional audit documents:

   - `tests.md` - Test coverage analysis (Week 1, Task 2)
   - `benchmarks.md` - Benchmarking infrastructure (Week 1, Task 4)
   - `notes.md` - General observations (Week 1, Task 3)

3. Function categorization:
   - Deterministic vs. probabilistic functions
   - Reproducibility requirements

## Usage

To find information about a specific function:

1. Check `Function_Inventory_Summary.md` for quick reference
2. Navigate to the function's folder (e.g., `aldex/`)
3. Read `signature.md` for detailed specifications

To understand the overall package:

1. Start with `Package_Inventory.md`
2. Review `Function_Inventory_Summary.md` for structure
3. Consult individual function signatures as needed

## Notes

- All function signatures include exact input/output specifications
- Dimensions are documented for all array/matrix inputs and outputs
- Dependencies are tracked for each function
- Examples are provided where applicable
