///| MoonBit port of Nano ID library
/// A tiny, secure, URL-friendly, unique string ID generator
/// MoonBit implementation compatible with the official nanoid JavaScript library

// ========== Error Handling ==========

///|
/// Error types for nanoid operations
pub enum NanoidError {
  EmptyAlphabet
  OversizedAlphabet(Int) // Contains the actual length
  DuplicateCharacter(Char, Int, Int) // Contains (char, first_position, duplicate_position)
  SizeTooSmall(Int) // Contains the invalid size value (<= 0)
  SizeTooLarge(Int) // Contains the invalid size value (> MAX_ID_SIZE)
  RandomGenerationError(String)
}

///|
/// Convert NanoidError to string representation
pub fn NanoidError::to_string(self : NanoidError) -> String {
  match self {
    EmptyAlphabet => "Alphabet cannot be empty"
    OversizedAlphabet(len) =>
      "Alphabet length (\{len}) exceeds maximum of 256 characters"
    DuplicateCharacter(char, first_pos, dup_pos) =>
      "Duplicate character '\{char}' at position \{dup_pos}, first seen at \{first_pos}"
    SizeTooSmall(size) => "Size (\{size}) must be greater than 0"
    SizeTooLarge(size) =>
      "Size (\{size}) exceeds maximum allowed size of 1,000,000"
    RandomGenerationError(msg) => "Random generation failed: \{msg}"
  }
}

///|
/// Convert NanoidError to detailed string representation with helpful guidance
pub fn NanoidError::to_string_detailed(self : NanoidError) -> String {
  match self {
    EmptyAlphabet =>
      "Alphabet cannot be empty. Please provide at least one character."
    OversizedAlphabet(len) =>
      "Alphabet length (\{len}) exceeds maximum of 256 characters. Consider using a smaller character set."
    DuplicateCharacter(char, first_pos, dup_pos) =>
      "Duplicate character '\{char}' found at position \{dup_pos}, first seen at \{first_pos}. Each character in the alphabet must be unique."
    SizeTooSmall(size) =>
      if size < 0 {
        "Size (\{size}) cannot be negative. Please provide a positive integer."
      } else {
        "Size (\{size}) must be greater than 0. Use size=1 for single character IDs."
      }
    SizeTooLarge(size) =>
      "Size (\{size}) exceeds maximum allowed size of 1,000,000. Large IDs may cause memory issues."
    RandomGenerationError(msg) =>
      "Random generation failed: \{msg}. This may indicate a system-level issue."
  }
}

///|
/// Helper function to create error results
fn[T] error_result(error : NanoidError) -> Result[T, NanoidError] {
  Err(error)
}

// ========== Unified Validation Module ==========

///|
/// Validation result for parameter checking
priv enum ValidationResult {
  Valid
  InvalidAlphabet(NanoidError)
  InvalidSize(NanoidError)
  InvalidRandom(NanoidError)
}

///|
/// Validate alphabet parameter (with caching)
fn validate_alphabet(alphabet : String) -> ValidationResult {
  validate_alphabet_uncached(alphabet)
}

///|
/// Internal alphabet validation without caching
/// Optimized to perform validation in a single pass through the string
fn validate_alphabet_uncached(alphabet : String) -> ValidationResult {
  // Use an immutable HashMap to efficiently check for duplicates and provide rich error messages.
  // The map stores the character and the index where it was first seen.
  let mut seen : @immut/hashmap.HashMap[Char, Int] = @immut/hashmap.new()
  let mut char_count = 0

  // Single pass: count characters and check for duplicates simultaneously
  // Use for-in loop to correctly iterate over Unicode characters (including emoji, etc.)
  for char in alphabet {
    match seen.get(char) {
      Some(first_pos) =>
        // Duplicate found, return a detailed error with proper error type.
        return InvalidAlphabet(DuplicateCharacter(char, first_pos, char_count))
      None =>
        // First time seeing this character, add it to the map with its index.
        seen = seen.add(char, char_count)
    }
    char_count = char_count + 1
  }

  // Check for empty alphabet (after loop to maintain single pass)
  if char_count == 0 {
    return InvalidAlphabet(EmptyAlphabet)
  }

  // Check for oversized alphabet
  if char_count > MAX_ALPHABET_SIZE {
    return InvalidAlphabet(OversizedAlphabet(char_count))
  }
  Valid
}

///|
/// Validate size parameter
fn validate_size(size : Int) -> ValidationResult {
  if size <= 0 {
    return InvalidSize(SizeTooSmall(size))
  }
  if size > MAX_ID_SIZE {
    return InvalidSize(SizeTooLarge(size))
  }
  Valid
}

///|
/// Validate random function parameter
fn validate_random_function(
  random : (Int) -> Result[Array[Int], NanoidError],
) -> ValidationResult {
  // Test the random function with a small sample to catch issues early
  match random(1) {
    Ok(test_bytes) =>
      if test_bytes.length() != 1 {
        return InvalidRandom(
          RandomGenerationError(
            "Custom random function returned incorrect array length",
          ),
        )
      } else {
        Valid
      }
    Err(e) => InvalidRandom(e)
  }
}

///|
/// Validate both alphabet and size parameters
fn validate_parameters(alphabet : String, size : Int) -> ValidationResult {
  match validate_alphabet(alphabet) {
    Valid => validate_size(size)
    error => error
  }
}

///|
/// Validate alphabet, size, and random function parameters
fn validate_all_parameters(
  alphabet : String,
  size : Int,
  random : (Int) -> Result[Array[Int], NanoidError],
) -> ValidationResult {
  match validate_parameters(alphabet, size) {
    Valid => validate_random_function(random)
    error => error
  }
}

///|
/// Helper function to convert string to character array using safe iteration
fn string_to_chars(s : String) -> Array[Char] {
  let mut count = 0
  for _char in s {
    count = count + 1
  }
  let chars = Array::make(count, ' ')
  let mut i = 0
  for char in s {
    chars[i] = char
    i = i + 1
  }
  chars
}

// ========== Constants and Alphabets ==========

///|
/// Default URL-friendly alphabet (official nanoid order)
/// Uses the same character order as official nanoid: A-Z, a-z, 0-9, underscore, hyphen
pub let url_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

///|
/// Default ID length (same as official nanoid)
const DEFAULT_SIZE = 21

// ========== Algorithm Constants ==========

///|
/// Maximum allowed alphabet size to prevent memory issues
const MAX_ALPHABET_SIZE = 256

///|
/// Maximum allowed ID size to prevent memory issues
const MAX_ID_SIZE = 1000000

///|
/// Safety factor for batch generation attempts to prevent infinite loops
const BATCH_GENERATION_SAFETY_FACTOR = 3

///|
/// Minimum batch size for random byte generation
const MIN_BATCH_SIZE = 8

///|
/// Maximum batch size for random byte generation
const MAX_BATCH_SIZE = 256

// ========== Random Number Generation ==========

///|
/// Global counter to provide entropy for seed generation.
/// Each call to nanoid increments this counter, ensuring different seeds
/// even when called rapidly in sequence.
///
/// WARNING: This counter is NOT thread-safe. In multi-threaded environments,
/// external synchronization is required.
let global_call_count : Ref[Int] = { val: 0 }

///|
/// Increment global counter (non-atomic, not thread-safe)
///
/// Returns: (old_value, new_value) tuple for use in seed generation
fn increment_counter() -> (Int, Int) {
  let old_val = global_call_count.val
  global_call_count.val = old_val + 1
  (old_val, old_val + 1)
}

///|
/// Get precomputed mask for common alphabet sizes
fn get_precomputed_mask(alphabet_length : Int) -> Int? {
  match alphabet_length {
    2 => Some(1) // 2^1 - 1
    4 => Some(3) // 2^2 - 1
    8 => Some(7) // 2^3 - 1
    16 => Some(15) // 2^4 - 1
    32 => Some(31) // 2^5 - 1
    64 => Some(63) // 2^6 - 1
    128 => Some(127) // 2^7 - 1
    256 => Some(255) // 2^8 - 1
    _ => None
  }
}

///|
/// Calculate mask for uniform distribution (power of 2 - 1)
/// Uses precomputed values for common sizes, falls back to calculation for others
fn calculate_mask(alphabet_length : Int) -> Int {
  match get_precomputed_mask(alphabet_length) {
    Some(mask) => mask
    None => {
      // Fallback to calculation for uncommon sizes
      let mut mask = 1
      while mask < alphabet_length {
        mask = mask << 1
      }
      mask - 1
    }
  }
}

///|
/// Generate ID characters using batch processing with rejection sampling (optimized)
fn generate_id_characters(
  alphabet : String,
  size : Int,
  step : Int,
  mask : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  // Convert alphabet to character array once and get actual character count
  // Critical for Unicode: alphabet.length() returns byte/code-unit count, not character count
  let alphabet_chars = get_cached_alphabet_chars(alphabet)
  let alphabet_length = alphabet_chars.length()
  let id_chars = Array::make(size, ' ')
  let mut counter = 0
  let mut batch_count = 0
  let max_batches = (size / step + 1) * BATCH_GENERATION_SAFETY_FACTOR // Allow reasonable number of batches

  // Main generation loop with batch processing
  while counter < size && batch_count < max_batches {
    let random_bytes = match get_random(step) {
      Ok(bytes) => bytes
      Err(e) => return Err(e)
    }

    // Process each byte in the batch using optimized version
    counter = process_random_batch_optimized(
      random_bytes, alphabet_chars, id_chars, counter, size, mask, alphabet_length,
    )
    batch_count = batch_count + 1
  }

  // Handle insufficient randomness case by returning an error
  if counter < size {
    return error_result(
      RandomGenerationError(
        "Failed to generate sufficient random characters after \{batch_count} batches. This may indicate an issue with the random number generator.",
      ),
    )
  }
  Ok(String::from_array(id_chars))
}

///|
/// Process a batch of random bytes and fill ID characters (optimized version)
fn process_random_batch_optimized(
  random_bytes : Array[Int],
  alphabet_chars : Array[Char],
  id_chars : Array[Char],
  start_counter : Int,
  target_size : Int,
  mask : Int,
  alphabet_length : Int,
) -> Int {
  let mut counter = start_counter
  let mut byte_index = 0
  while byte_index < random_bytes.length() && counter < target_size {
    let byte = random_bytes[byte_index] & mask
    if byte < alphabet_length {
      // Direct array access is faster than string.get_char()
      id_chars[counter] = alphabet_chars[byte]
      counter = counter + 1
    }
    byte_index = byte_index + 1
  }
  counter
}

// Legacy function removed - now using optimized version directly

///|
/// Heuristic fast-path for optimal batch size when rejection probability is zero.
/// Returns Some(step) only when (mask + 1) == alphabet_length (i.e. power-of-two alphabet)
/// so every generated random byte can map to a character without rejection.
///
/// Strategy:
///   - Use target_size directly (1 batch ideal) to minimize RNG + loop overhead.
///   - Clamp to [MIN_BATCH_SIZE, MAX_BATCH_SIZE] to avoid pathological tiny/huge requests.
///   - Otherwise return None and let the analytical path compute a value.
///
/// Rationale:
///   Previous implementation hard-coded opaque magic numbers (e.g. 64->10) which caused
///   unnecessary multiple batches, increasing RNG calls and memory clearing. This version
///   keeps semantics minimal while enabling single-batch generation for common alphabets
///   like 64 (URL/base64) and 32 (base32) when size is within limits.
fn get_precomputed_batch_size(
  alphabet_length : Int,
  target_size : Int,
  mask : Int,
) -> Int? {
  if mask + 1 == alphabet_length { // perfect power-of-two span => zero rejection
    // Clamp desired step to reasonable bounds
    let mut step = target_size
    if step < MIN_BATCH_SIZE {
      step = MIN_BATCH_SIZE
    }
    if step > MAX_BATCH_SIZE {
      step = MAX_BATCH_SIZE
    }
    return Some(step)
  }
  None
}

///|
/// Calculate optimal batch size for random byte generation
/// Uses entropy efficiency analysis to determine the best batch size
fn calculate_optimal_batch_size(
  alphabet_length : Int,
  target_size : Int,
  mask : Int,
) -> Int {
  // Fast path: perfect power-of-two span uses single batch (clamped) to reduce overhead.
  let optimized_step = match
    get_precomputed_batch_size(alphabet_length, target_size, mask) {
    Some(precomputed) => precomputed
    None => {
      // Analytical estimation: bytes_needed ≈ target_size * waste_factor * safety_margin
      // waste_factor = 1 / efficiency, efficiency = alphabet_length / (mask+1)
      let efficiency = alphabet_length.to_double() / (mask + 1).to_double()
      let waste_factor = 1.0 / efficiency
      let safety_margin = 1.2 // modest extra to reduce probability of a second batch
      let raw = (target_size.to_double() * waste_factor * safety_margin).to_int()
      // Clamp to global bounds
      let mut est = raw
      if est < MIN_BATCH_SIZE {
        est = MIN_BATCH_SIZE
      }
      if est > MAX_BATCH_SIZE {
        est = MAX_BATCH_SIZE
      }
      est
    }
  }

  // Avoid generating wildly more bytes than needed for very small target sizes.
  let max_reasonable = target_size * 2
  if optimized_step > max_reasonable {
    max_reasonable
  } else {
    optimized_step
  }
}

///|
/// SplitMix64 output function: produces a well-distributed 64-bit value
/// from the given state, advancing the state for the next call.
/// Returns (next_state, output_value).
fn splitmix64_next(state : Int64) -> (Int64, Int64) {
  let s = state + 0x9E3779B97F4A7C15L // golden ratio
  let mut z = s
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9L
  z = (z ^ (z >> 27)) * 0x94D049BB133111EBL
  z = z ^ (z >> 31)
  (s, z)
}

///|
/// Create a 32-byte seed for ChaCha8 from global counter and size hint.
/// Uses SplitMix64 to expand the counter into 32 bytes with good avalanche
/// properties, ensuring all seed bytes carry meaningful entropy.
///
/// Note: MoonBit currently lacks a system entropy API, so the actual entropy
/// comes only from the counter (~32 bits). The mixing ensures this entropy
/// is well-distributed across all 32 bytes, but the seed space remains limited.
fn create_seed_bytes(size_hint : Int) -> Bytes {
  let (_old_count, new_count) = increment_counter()
  // Combine counter and size_hint into a single 64-bit state
  let mut state = new_count.to_int64() ^ (size_hint.to_int64() << 32)
  // Generate 4 well-mixed 64-bit values (4 * 8 = 32 bytes)
  let values = Array::make(4, 0L)
  for i = 0; i < 4; i = i + 1 {
    let (next_state, output) = splitmix64_next(state)
    state = next_state
    values[i] = output
  }
  // Extract bytes from the 4 Int64 values in little-endian order
  Bytes::makei(32, fn(i) { (values[i / 8] >> (i % 8 * 8)).to_byte() })
}

///|
/// Maximum number of alphabets to store in the cache.
const MAX_ALPHABET_CACHE_SIZE = 16

///|
/// Simple alphabet cache to avoid repeated conversions
/// Note: This is a basic implementation. In production, consider using a proper LRU cache
let alphabet_char_cache : Ref[@immut/hashmap.HashMap[String, Array[Char]]] = {
  val: @immut/hashmap.new(),
}

///|
/// Get cached character array for alphabet, or convert and cache it
fn get_cached_alphabet_chars(alphabet : String) -> Array[Char] {
  let cache = alphabet_char_cache.val

  // Check if alphabet is already cached using the map
  match cache.get(alphabet) {
    Some(cached_chars) =>
      // Cache hit
      return cached_chars
    None => {
      // Cache miss: convert and then cache
      let chars = string_to_chars(alphabet)

      // Only cache if the cache size is within the limit to prevent memory bloat
      if cache.length() < MAX_ALPHABET_CACHE_SIZE {
        let new_cache = cache.add(alphabet, chars)
        alphabet_char_cache.val = new_cache
      }
      return chars
    }
  }
}

///|
/// Internal function to generate random bytes using ChaCha8 PRNG
/// Uses MoonBit's standard library @random (ChaCha8-based) for
/// better randomness quality compared to simple xorshift algorithms.
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  let seed = create_seed_bytes(size)
  let rng = @random.Rand::chacha8(seed~)
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.int(limit=256)
  }
  Ok(bytes)
}

///|
/// Internal function to generate ID with given alphabet, size, and random function
/// Returns Result with ID string or NanoidError for invalid parameters
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  match validate_parameters(alphabet, size) {
    Valid => () // Continue with generation
    InvalidAlphabet(error) => return Err(error)
    InvalidSize(error) => return Err(error)
    InvalidRandom(error) => return Err(error)
  }

  // Convert alphabet to character array and get actual character count
  // This is critical for Unicode handling - alphabet.length() returns byte/code-unit count
  let alphabet_chars = get_cached_alphabet_chars(alphabet)
  let alphabet_length = alphabet_chars.length()

  // Special case: single character alphabet - no randomness needed
  if alphabet_length == 1 {
    let single_char = alphabet_chars[0]
    let chars = Array::make(size, single_char)
    return Ok(String::from_array(chars))
  }

  // Calculate mask for uniform distribution (avoid modulo bias)
  let mask = calculate_mask(alphabet_length)

  // Calculate optimal batch size for random byte generation
  let step = calculate_optimal_batch_size(alphabet_length, size, mask)

  // Generate ID characters using optimized batch processing
  generate_id_characters(alphabet, size, step, mask, get_random)
}

///|
/// Main nanoid function - generates URL-friendly unique ID
/// Generates secure random IDs using the default URL-safe alphabet
/// Returns Result with ID string or NanoidError for invalid parameters
/// Usage: nanoid() generates 21-character ID, nanoid(size=10) generates 10-character ID
pub fn nanoid(size? : Int = DEFAULT_SIZE) -> Result[String, NanoidError] {
  generate(url_alphabet, size, get_random_bytes)
}

///|
/// Convenience function that returns empty string on error (for backward compatibility)
/// Usage: nanoid_or_empty() generates 21-character ID or empty string on error
pub fn nanoid_or_empty(size? : Int = DEFAULT_SIZE) -> String {
  match nanoid(size~) {
    Ok(id) => id
    Err(_) => ""
  }
}

///|
/// Custom alphabet function - returns a nanoid generator with custom alphabet
/// Creates a generator function that uses the specified alphabet and size
/// Returns Result with generator function or NanoidError for invalid parameters
/// Usage: let gen = custom_alphabet("abc123", size=8)?; let id = gen()?
pub fn custom_alphabet(
  alphabet : String,
  size? : Int = DEFAULT_SIZE,
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  // Use unified validation
  match validate_parameters(alphabet, size) {
    Valid =>
      Ok(fn() -> Result[String, NanoidError] {
        generate(alphabet, size, get_random_bytes)
      })
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
    InvalidRandom(error) => Err(error)
  }
}

///|
/// Convenience custom alphabet function that returns empty string on error
/// Usage: let gen = custom_alphabet_or_empty("abc123", size=8); let id = gen()
pub fn custom_alphabet_or_empty(
  alphabet : String,
  size? : Int = DEFAULT_SIZE,
) -> () -> String {
  match custom_alphabet(alphabet, size~) {
    Ok(gen) =>
      fn() -> String {
        match gen() {
          Ok(id) => id
          Err(_) => ""
        }
      }
    Err(_) => fn() -> String { "" }
  }
}

///|
/// Custom random function - allows custom random generator
/// Creates a generator with custom alphabet, size, and random function
/// Returns Result with generator function or NanoidError for invalid parameters
/// Usage: let gen = custom_random(alphabet, size, random_fn)?; let id = gen()?
pub fn custom_random(
  alphabet : String,
  size : Int,
  random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  // Use unified validation for all parameters
  match validate_all_parameters(alphabet, size, random) {
    Valid =>
      Ok(fn() -> Result[String, NanoidError] {
        generate(alphabet, size, random)
      })
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
    InvalidRandom(error) => Err(error)
  }
}

///|
/// Convenience custom random function that returns empty string on error
/// Usage: let gen = custom_random_or_empty(alphabet, size, random_fn); let id = gen()
pub fn custom_random_or_empty(
  alphabet : String,
  size : Int,
  random : (Int) -> Array[Int],
) -> () -> String {
  let safe_random = fn(size : Int) -> Result[Array[Int], NanoidError] {
    Ok(random(size))
  }
  match custom_random(alphabet, size, safe_random) {
    Ok(gen) =>
      fn() -> String {
        match gen() {
          Ok(id) => id
          Err(_) => ""
        }
      }
    Err(_) => fn() -> String { "" }
  }
}

// ========== Character Sets & Alphabet Presets ==========
// Based on nanoid-dictionary (https://github.com/CyberAP/nanoid-dictionary)

///|
/// Numbers from 0 to 9
pub let numbers = "0123456789"

///|
/// Lowercase English letters
pub let lowercase = "abcdefghijklmnopqrstuvwxyz"

///|
/// Uppercase English letters
pub let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

///|
/// Combination of lowercase, uppercase letters and numbers
/// Does not include any symbols or special characters
pub let alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

///|
/// Lowercase hexadecimal characters
pub let hex = "0123456789abcdef"

///|
/// Uppercase hexadecimal characters
pub let hex_upper = "0123456789ABCDEF"

///|
/// Numbers and English alphabet without lookalikes
/// Removes: 1, l, I, 0, O, o, u, v, 5, S, s, 2, Z
/// Complete set: 346789ABCDEFGHJKLMNPQRTUVWXYabcdefghijkmnpqrtwxyz
pub let nolookalikes = "346789ABCDEFGHJKLMNPQRTUVWXYabcdefghijkmnpqrtwxyz"

///|
/// Same as nolookalikes but with additional removed characters: 3, 4, x, X, V
/// Also removes vowels to protect from accidentally getting obscene words in generated strings
/// Complete set: 6789BCDFGHJKLMNPQRTWbcdfghjkmnpqrtwz
pub let nolookalikes_safe = "6789BCDFGHJKLMNPQRTWbcdfghjkmnpqrtwz"

///|
/// Base62 encoding alphabet (numbers, uppercase, lowercase)
/// Compatible with most base62 implementations
pub let base62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

///|
/// Base58 encoding alphabet (Bitcoin style - excludes 0, O, I, l)
/// Used in cryptocurrency and other applications to avoid character confusion
pub let base58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz"

///|
/// URL-safe characters that don't require encoding in most contexts
/// Excludes characters that might be problematic in URLs or file systems
/// Same as the default url_alphabet
pub let url_safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

///|
/// Filename-safe characters for cross-platform compatibility
/// Safe for use in filenames on Windows, macOS, and Linux
pub let filename_safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
