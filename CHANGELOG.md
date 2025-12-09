## v0.2.2

**🐛 Bug Fixes:**

- **Fixed array bounds bug**: Corrected `generate()` and `generate_id_characters()` to use actual character count instead of byte length
- **Prevented potential crashes**: Using `alphabet.length()` for Unicode alphabets (emoji, Chinese, etc.) could cause index out-of-bounds errors
- **Made `string_to_chars` public**: Exposed as a utility function for safe Unicode string-to-array conversion
- **Fixed Unicode String Iteration**: Corrected `validate_alphabet_uncached` to use proper character iteration instead of UTF-16 code unit indexing
- **Fixed Constant-Time Comparison**: Resolved security vulnerability in `constant_time_eq` where non-BMP characters could cause incorrect comparisons
- **Fixed Potential Panic**: Removed unsafe `unwrap()` call in `alphabet_to_chars` that could panic on strings with surrogate pairs
- **Added Helper Function**: New `string_to_chars` function for safe Unicode string-to-array conversion

**✨ Improvements:**

- **Added comprehensive Unicode tests**: New test suite covering single emoji, mixed emoji, Chinese characters, and mixed ASCII+Unicode alphabets
- **Improved Unicode support**: Full support for emoji and multi-byte character alphabets
- **Optimized alphabet validation**: Merged dual string traversals into single pass in `validate_alphabet_uncached` (~50% performance improvement)

## 🚀 **Recent Optimizations (v0.2.0)**

This version includes significant optimizations and improvements:

- **Fixed Random Number Generator**: Corrected xorshift64* algorithm implementation for better randomness quality
- **Enhanced Security**: Improved seed generation with multiple entropy sources and secure memory clearing
- **Performance Optimizations**: Specialized algorithms for common alphabet sizes and reduced memory allocations
- **Unified Validation**: Consolidated parameter validation logic for better maintainability
- **Extended Testing**: Comprehensive test suite including edge cases, performance, and security tests
- **Better Error Handling**: Detailed error messages with helpful guidance
- **Fail-fast Security**: Removed deterministic fallback to prevent predictable ID generation
