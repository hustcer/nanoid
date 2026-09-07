## Unreleased

**Performance:**

- Reuse the fixed URL alphabet in `nanoid()` instead of validating and converting
  it on every call. For 21-character IDs, three-round release benchmarks on an
  Apple M1 measured 6.660 → 0.41528 µs on native (16.04×) and 8.010 → 1.370 µs on
  JS (5.85×). See [PERFORMANCE.md](PERFORMANCE.md) for methodology and raw round means.
- Use a local mutable map when validating custom alphabets. Generator setup with
  64 ASCII / 256 supplementary Unicode characters improved by 3.14× / 4.39× on
  native and 2.48× / 2.84× on JS in the same three-round benchmark methodology.
  Duplicate positions, error precedence, and Unicode behavior are preserved.

**Bug fixes:**

- Include Windows type definitions before `bcrypt.h` in the native entropy shim.
  A standalone C regression reproduces the previous Windows compilation failure
  (`LONG` / `ULONG` were undefined), and also checks zero-length, negative-length,
  and guarded-buffer requests.

- Give rejection sampling a minimum 128-byte retry budget. Previously, a
  one-character ID with a 129-character alphabet failed after only 16 rejected
  bytes, an event with probability about 1 in 74,000 for uniform random bytes.
  Deterministic regression tests cover recovery after that streak and bounded
  failure for a source that never yields an accepted byte.

## v0.6.0

**🐛 Bug Fixes:**

- **`NanoidError` is now `pub(all)`**: external callers can construct error variants. The `custom_random` signature `(Int) -> Result[Array[Int], NanoidError]` previously implied users could return `Err`, but the read-only `pub` enum made that impossible.

**✨ Improvements:**

- **OS-backed default RNG on native, JS, and LLVM**:
  - native/llvm: `getrandom`/`/dev/urandom` (Linux), `arc4random_buf` (BSD/macOS), or `BCryptGenRandom` (Windows) via a C stub
  - JS: Web Crypto (`crypto.getRandomValues`) with a Node `crypto.randomBytes` fallback, chunked at 32 KiB to stay under the 64 KiB spec cap
  - wasm/wasm-gc: unchanged — runtime-seeded ChaCha8 PRNG, kept self-contained so `moon test --target all` requires no host crypto import
- **JS extern surfaces underlying errors**: `RandomGenerationError` now carries the actual JS exception message instead of a generic string
- **Linux `SYS_getrandom` guarded by `#ifdef`**: toolchains without the macro fall through to `/dev/urandom` rather than failing to compile
- **Tests**: added user-error propagation through `custom_random`, generator-reuse uniqueness across calls, and full preset alphabet coverage
- **README**: per-target entropy story, `pub(all) NanoidError`, `custom_random` Err propagation example, `moon.pkg` import snippet using current syntax, `Tigls/mb-getrandom` acknowledgment for the C stub reference

## v0.5.1

**🐛 Bug Fixes:**

- **Custom random byte range validation**: each byte returned by a custom random function is now checked to be in `0..255`, with an error message including the offending index and value
- **Single-character alphabet skips random probe**: `custom_random` no longer calls the random function at all (including the setup probe) when the alphabet has exactly one character
- **`NanoidError` derives `Debug` instead of `Show`**: removes the deprecated-`Show` compiler warning

**✨ Improvements:**

- **README entropy note**: clarified that the MoonBit `@random` default constructor is not OS-backed; updated recommendation to use `custom_random` with an OS entropy source for security-sensitive IDs
- **CI**: added dedicated build and check steps

## v0.5.0

**⚠️ Breaking Changes:**

- **Switched to single-package public API at `hustcer/nanoid`**: removed the legacy `hustcer/nanoid/lib` package layout and consolidated implementation/test files under `src/nanoid.mbt` and `src/nanoid_test.mbt`

**🐛 Bug Fixes:**

- **Hardened `custom_random` runtime validation**: now validates custom random byte array length on every request (not just setup), with detailed `expected X, got Y` error messages
- **Fixed `custom_random` probe side effects**: validation probe byte is replayed into first generation call so setup checks no longer consume user-provided random state
- **Fixed false generation failures for small non-power-of-two alphabets**: replaced simplistic batch cap with expected-byte based batch budgeting to avoid premature `Failed to generate sufficient random characters` errors
- **Runtime-seeded default RNG**: default ChaCha8 seed now derives from runtime process context (`time/args/cwd`) to avoid identical startup sequences across processes

**✨ Improvements:**

- **Root package import is now first-class**: API is exposed directly from `hustcer/nanoid`, simplifying integration and matching README examples
- **Demo moved to dedicated subpackage**: executable demo relocated to `src/demo/top.mbt` with its own package metadata for cleaner library/demo separation
- **Refactored replay-random pipeline**: split `create_replay_random` flow into smaller helpers for easier maintenance while preserving behavior
- **Documentation updated for new package path and RNG model**: README now reflects root import usage, thread-safety note, and non-cryptographic entropy caveat

**🧹 Maintenance:**

- **Repository housekeeping**: updated and then removed agent instruction files (`AGENTS.md`) with no runtime/API impact on the nanoid library

## v0.3.0

**⚠️ Breaking Changes:**

- **Replaced custom xorshift64\* PRNG with MoonBit stdlib ChaCha8**: `@random.Rand::chacha8()` provides a well-tested, cryptographic-strength RNG from the standard library, replacing the hand-rolled xorshift64\* implementation

**🚀 Performance:**

- **Persistent global RNG**: Single `@random.Rand::chacha8()` instance reused across calls, eliminating per-call ChaCha8 initialization overhead
- **Eliminated double validation**: `custom_alphabet`/`custom_random` closures call `generate_unchecked` directly, avoiding redundant parameter validation on each invocation
- **Eliminated double alphabet lookup**: `generate_id_characters` now accepts `Array[Char]` + `Int` directly instead of re-looking up the alphabet from cache
- **Simplified `calculate_mask`**: Removed `get_precomputed_mask` lookup table in favor of a simple bit-shift loop (at most 8 iterations for ≤256 alphabets)
- **Single-pass `string_to_chars`**: Replaced two-pass count-then-fill with dynamic array `push`

**✨ Improvements:**

- **`derive(Show, Eq)` for `NanoidError`**: Enables direct comparison and debug printing of error values
- **Cache safety**: `get_cached_alphabet_chars` now returns a copy to prevent callers from mutating cached data
- **Unified error messages**: `to_string` now includes contextual guidance (e.g., "Please provide at least one character", "Use size=1 for single character IDs")

## v0.2.3

**🐛 Bug Fixes:**

- **Fixed Int64 Overflow**: Resolved a potential `Int64.MIN_VALUE` overflow issue in `SimpleRng::next_int` to ensure safe absolute value conversion
- **Fixed Dependencies**: Removed invalid dependencies to ensure a clean build environment
- **Fixed Import Warnings**: Resolved compiler warnings related to imports

**✨ Improvements:**

- **Enhanced Seed Generation**: Simplified `increment_counter` and improved seed generation by mixing multiple entropy sources (old and new counter values, cross-correlation)
- **Improved Validation**: Added specific `DuplicateCharacter` error type for better debugging of invalid alphabets
- **Refactored Counter Logic**: Simplified global counter increment logic to be more transparent about threading assumptions
- **Enhanced Constant-Time Comparison**: Further improvements to the security of `constant_time_eq`

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

- **Fixed Random Number Generator**: Corrected xorshift64\* algorithm implementation for better randomness quality
- **Enhanced Security**: Improved seed generation with multiple entropy sources and secure memory clearing
- **Performance Optimizations**: Specialized algorithms for common alphabet sizes and reduced memory allocations
- **Unified Validation**: Consolidated parameter validation logic for better maintainability
- **Extended Testing**: Comprehensive test suite including edge cases, performance, and security tests
- **Better Error Handling**: Detailed error messages with helpful guidance
- **Fail-fast Security**: Removed deterministic fallback to prevent predictable ID generation
