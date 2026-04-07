///| MoonBit port of Nano ID library
/// A tiny, URL-friendly, unique string ID generator
/// MoonBit implementation compatible with the official nanoid JavaScript library

// ========== Error Handling ==========

///|
/// Error types for nanoid operations
pub enum NanoidError {
  EmptyAlphabet
  OversizedAlphabet(Int)
  DuplicateCharacter(Char, Int, Int)
  SizeTooSmall(Int)
  SizeTooLarge(Int)
  RandomGenerationError(String)
} derive(Debug, Eq)

///|
/// Convert NanoidError to a human-readable string with helpful guidance
pub fn NanoidError::to_string(self : NanoidError) -> String {
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

// ========== Unified Validation Module ==========

///|
/// Validation result for parameter checking
priv enum ValidationResult {
  Valid
  InvalidAlphabet(NanoidError)
  InvalidSize(NanoidError)
}

///|
/// Internal alphabet validation
/// Performs validation in a single pass through the string
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
/// Validate random byte count and return a detailed error when mismatch happens
fn validate_random_output_size(
  bytes : Array[Int],
  expected_size : Int,
) -> Result[Array[Int], NanoidError] {
  if bytes.length() != expected_size {
    return Err(
      RandomGenerationError(
        "Custom random function returned incorrect array length: expected \{expected_size}, got \{bytes.length()}",
      ),
    )
  }
  Ok(bytes)
}

///|
/// Validate both alphabet and size parameters
fn validate_parameters(alphabet : String, size : Int) -> ValidationResult {
  match validate_alphabet_uncached(alphabet) {
    Valid => validate_size(size)
    error => error
  }
}

///|
/// Helper function to convert string to character array using safe iteration
fn string_to_chars(s : String) -> Array[Char] {
  let chars : Array[Char] = []
  for char in s {
    chars.push(char)
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
/// Safety factor for random-byte budget before failing generation.
/// A higher multiplier dramatically reduces false failures for small sizes while
/// still providing a finite upper bound for pathological custom random functions.
const BATCH_GENERATION_SAFETY_FACTOR = 8

///|
/// Minimum batch size for random byte generation
const MIN_BATCH_SIZE = 8

///|
/// Maximum batch size for random byte generation
const MAX_BATCH_SIZE = 256

// ========== Random Number Generation ==========

///|
/// Global persistent ChaCha8 RNG instance.
/// Using a single instance avoids per-call initialization overhead and lets
/// the internal state advance naturally, producing a longer non-repeating sequence.
///
/// Seed is derived at runtime from process context (time/args/cwd), so
/// sequences are no longer fixed across process runs.
/// Note: this is still not a cryptographic entropy source.
/// WARNING: This RNG is NOT thread-safe.
let global_rng : @random.Rand = @random.Rand::chacha8(seed=build_runtime_seed())

///|
/// Mix a UInt64 value (xorshift-style) for seed derivation.
fn mix_seed_state(state : UInt64) -> UInt64 {
  let mut mixed = state
  mixed = mixed ^ (mixed << 13)
  mixed = mixed ^ (mixed >> 7)
  mixed = mixed ^ (mixed << 17)
  mixed
}

///|
/// Fold a string into seed state to add process-specific variability.
fn absorb_seed_string(state : UInt64, value : String) -> UInt64 {
  let mut mixed = state
  for char in value {
    mixed = mix_seed_state(mixed + char.to_int().to_uint64())
  }
  mixed
}

///|
/// Build a 32-byte seed from runtime process context.
fn build_runtime_seed() -> Bytes {
  let mut state = @env.now()
  for arg in @env.args() {
    state = absorb_seed_string(state, arg)
  }
  match @env.current_dir() {
    Some(cwd) => state = absorb_seed_string(state, cwd)
    None => ()
  }
  if state == UInt64::default() {
    state = Int::to_uint64(1)
  }

  let seed_bytes : Array[Byte] = Array::make(32, 0)
  for i = 0; i < 32; i = i + 1 {
    state = mix_seed_state(state + Int::to_uint64(i + 1))
    seed_bytes[i] = state.to_byte()
  }
  Bytes::from_array(seed_bytes)
}

///|
/// Calculate mask for uniform distribution (power of 2 - 1)
fn calculate_mask(alphabet_length : Int) -> Int {
  let mut mask = 1
  while mask < alphabet_length {
    mask = mask << 1
  }
  mask - 1
}

///|
/// Generate ID characters using batch processing with rejection sampling
fn generate_id_characters(
  alphabet_chars : Array[Char],
  alphabet_length : Int,
  size : Int,
  step : Int,
  mask : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  let id_chars = Array::make(size, ' ')
  let mut counter = 0
  let mut batch_count = 0
  let max_batches = calculate_max_batches(alphabet_length, size, step, mask)

  // Main generation loop with batch processing
  while counter < size && batch_count < max_batches {
    let random_bytes = match get_random(step) {
      Ok(bytes) =>
        match validate_random_output_size(bytes, step) {
          Ok(valid_bytes) => valid_bytes
          Err(e) => return Err(e)
        }
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
    return Err(
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
/// Compute a finite batch budget based on expected random bytes needed.
/// expected_bytes = ceil(size * (mask + 1) / alphabet_length)
/// max_bytes = expected_bytes * safety_factor
fn calculate_max_batches(
  alphabet_length : Int,
  target_size : Int,
  step : Int,
  mask : Int,
) -> Int {
  let expected_bytes = (target_size * (mask + 1) + alphabet_length - 1) /
    alphabet_length
  let max_bytes = expected_bytes * BATCH_GENERATION_SAFETY_FACTOR
  let max_batches = (max_bytes + step - 1) / step
  if max_batches < 1 {
    1
  } else {
    max_batches
  }
}

///|
/// Generate random bytes from the global ChaCha8 RNG
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = global_rng.int(limit=256)
  }
  Ok(bytes)
}

///|
/// Request exact number of bytes from a custom random function.
fn request_random_exact(
  random : (Int) -> Result[Array[Int], NanoidError],
  size : Int,
) -> Result[Array[Int], NanoidError] {
  match random(size) {
    Ok(bytes) => validate_random_output_size(bytes, size)
    Err(e) => Err(e)
  }
}

///|
/// Prepend a probe byte to the remaining random bytes.
fn prepend_probe_byte(first_byte : Int, rest_bytes : Array[Int]) -> Array[Int] {
  let merged_bytes = Array::make(rest_bytes.length() + 1, 0)
  merged_bytes[0] = first_byte
  for i = 0; i < rest_bytes.length(); i = i + 1 {
    merged_bytes[i + 1] = rest_bytes[i]
  }
  merged_bytes
}

///|
/// Try to build random bytes from the cached probe byte.
fn generate_with_probe_byte(
  random : (Int) -> Result[Array[Int], NanoidError],
  probe_byte : Ref[Int?],
  first_byte : Int,
  request_size : Int,
) -> Result[Array[Int], NanoidError] {
  if request_size == 1 {
    probe_byte.val = None
    return Ok([first_byte])
  }
  match request_random_exact(random, request_size - 1) {
    Ok(valid_rest_bytes) => {
      probe_byte.val = None
      Ok(prepend_probe_byte(first_byte, valid_rest_bytes))
    }
    Err(e) => Err(e)
  }
}

///|
/// Generate random bytes, consuming probe byte first when available.
fn generate_replay_random_bytes(
  random : (Int) -> Result[Array[Int], NanoidError],
  probe_byte : Ref[Int?],
  request_size : Int,
) -> Result[Array[Int], NanoidError] {
  if request_size <= 0 {
    return Ok([])
  }
  match probe_byte.val {
    Some(first_byte) =>
      generate_with_probe_byte(random, probe_byte, first_byte, request_size)
    None => request_random_exact(random, request_size)
  }
}

///|
/// Wrap a custom random function and replay the probe byte so validation does not
/// consume random state from the first generated ID.
fn create_replay_random(
  random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[(Int) -> Result[Array[Int], NanoidError], NanoidError] {
  match request_random_exact(random, 1) {
    Ok(valid_test_bytes) => {
      let probe_byte : Ref[Int?] = { val: Some(valid_test_bytes[0]) }
      Ok(fn(request_size : Int) -> Result[Array[Int], NanoidError] {
        generate_replay_random_bytes(random, probe_byte, request_size)
      })
    }
    Err(e) => Err(e)
  }
}

///|
/// Internal generation without validation using precomputed alphabet characters
fn generate_unchecked_with_alphabet_chars(
  alphabet_chars : Array[Char],
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  let alphabet_length = alphabet_chars.length()

  // Special case: single character alphabet - no randomness needed
  if alphabet_length == 1 {
    return Ok(String::from_array(Array::make(size, alphabet_chars[0])))
  }

  let mask = calculate_mask(alphabet_length)
  let step = calculate_optimal_batch_size(alphabet_length, size, mask)
  generate_id_characters(
    alphabet_chars, alphabet_length, size, step, mask, get_random,
  )
}

///|
/// Internal generation without validation (caller must validate first)
fn generate_unchecked(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  generate_unchecked_with_alphabet_chars(
    string_to_chars(alphabet),
    size,
    get_random,
  )
}

///|
/// Generate ID with validation
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  match validate_parameters(alphabet, size) {
    Valid => generate_unchecked(alphabet, size, get_random)
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
  }
}

///|
/// Main nanoid function - generates URL-friendly unique ID
/// Generates random IDs using the default URL-safe alphabet
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
  match validate_parameters(alphabet, size) {
    Valid => {
      let alphabet_chars = string_to_chars(alphabet)
      Ok(fn() -> Result[String, NanoidError] {
        generate_unchecked_with_alphabet_chars(
          alphabet_chars, size, get_random_bytes,
        )
      })
    }
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
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
  match validate_parameters(alphabet, size) {
    Valid => {
      let alphabet_chars = string_to_chars(alphabet)
      match create_replay_random(random) {
        Ok(replay_random) =>
          Ok(fn() -> Result[String, NanoidError] {
            generate_unchecked_with_alphabet_chars(
              alphabet_chars, size, replay_random,
            )
          })
        Err(e) => Err(e)
      }
    }
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
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
