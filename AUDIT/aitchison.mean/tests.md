# Tests for `aitchison.mean()`

## Current R test coverage

- **Test files**: none.
- **Coverage level**: ⚠️ Indirect only (used inside `aldex.effect()`; see `Test_Coverage_Report.md`).
- **Test type**: No function-specific tests.

## Required scenarios (not yet implemented)

- Simple compositional vectors where the Aitchison mean can be computed analytically.
- Multi-feature matrices with known expected values, including balanced and highly skewed compositions.
- Edge cases such as zeros, very small/large counts, and single-feature inputs.

## Action items

- Create small synthetic examples with closed-form Aitchison means and use them as golden references.
- Add tests that compare numerical stability across different scales (raw counts vs normalized counts).
