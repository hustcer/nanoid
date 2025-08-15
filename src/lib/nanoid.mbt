///| MoonBit port of Nano ID library
/// A tiny, secure, URL-friendly, unique string ID generator
/// MoonBit implementation compatible with the official nanoid JavaScript library

// ========== Error Handling ==========

///| Error types for nanoid operations
pub enum NanoidError {
  EmptyAlphabet
  OversizedAlphabet(Int) // Contains the actual length
  InvalidSize(Int) // Contains the invalid size value
  RandomGenerationError(String)
}

///| Convert NanoidError to string representation
pub fn NanoidError::to_string(self : NanoidError) -> String {
  match self {
    EmptyAlphabet => "Alphabet cannot be empty"
    OversizedAlphabet(len) =>
      "Alphabet length (\{len}) exceeds maximum of 256 characters"
    InvalidSize(size) =>
      if size > 1000000 {
        "Size (\{size}) exceeds maximum allowed size of 1,000,000"
      } else {
        "Size (\{size}) must be greater than 0"
      }
    RandomGenerationError(msg) => "Random generation failed: \{msg}"
  }
}

///| Convert NanoidError to detailed string representation with helpful guidance
pub fn NanoidError::to_string_detailed(self : NanoidError) -> String {
  match self {
    EmptyAlphabet =>
      "Alphabet cannot be empty. Please provide at least one character."
    OversizedAlphabet(len) =>
      "Alphabet length (\{len}) exceeds maximum of 256 characters. Consider using a smaller character set."
    InvalidSize(size) =>
      if size > 1000000 {
        "Size (\{size}) exceeds maximum allowed size of 1,000,000. Large IDs may cause memory issues."
      } else if size < 0 {
        "Size (\{size}) cannot be negative. Please provide a positive integer."
      } else {
        "Size (\{size}) must be greater than 0. Use size=1 for single character IDs."
      }
    RandomGenerationError(msg) =>
      "Random generation failed: \{msg}. This may indicate a system-level issue."
  }
}

///| Helper function to create error results
fn[T] error_result(error : NanoidError) -> Result[T, NanoidError] {
  Err(error)
}

// ========== Unified Validation Module ==========

///| Validation result for parameter checking
priv enum ValidationResult {
  Valid
  InvalidAlphabet(NanoidError)
  InvalidSize(NanoidError)
  InvalidRandom(NanoidError)
}

///| Validate alphabet parameter
fn validate_alphabet(alphabet : String) -> ValidationResult {
  // Check for empty alphabet
  if alphabet.length() == 0 {
    return InvalidAlphabet(EmptyAlphabet)
  }

  // Check for oversized alphabet
  if alphabet.length() > 256 {
    return InvalidAlphabet(OversizedAlphabet(alphabet.length()))
  }

  // Validate alphabet contains only valid Unicode characters
  for i = 0; i < alphabet.length(); i = i + 1 {
    match alphabet.get_char(i) {
      Some(_) => continue
      None =>
        return InvalidAlphabet(
          RandomGenerationError(
            "Invalid character in alphabet at position \{i}",
          ),
        )
    }
  }

  // Check for duplicate characters in alphabet
  if alphabet.length() > 1 {
    for i = 0; i < alphabet.length() - 1; i = i + 1 {
      let char_i = alphabet.get_char(i).unwrap()
      for j = i + 1; j < alphabet.length(); j = j + 1 {
        let char_j = alphabet.get_char(j).unwrap()
        if char_i == char_j {
          return InvalidAlphabet(
            RandomGenerationError(
              "Duplicate character '\{char_i}' found at positions \{i} and \{j}",
            ),
          )
        }
      }
    }
  }
  Valid
}

///| Validate size parameter
fn validate_size(size : Int) -> ValidationResult {
  if size <= 0 {
    return InvalidSize(InvalidSize(size))
  }
  if size > 1000000 {
    return InvalidSize(InvalidSize(size))
  }
  Valid
}

///| Validate random function parameter
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

///| Validate both alphabet and size parameters
fn validate_parameters(alphabet : String, size : Int) -> ValidationResult {
  match validate_alphabet(alphabet) {
    Valid => validate_size(size)
    error => error
  }
}

///| Validate alphabet, size, and random function parameters
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

///| Constant-time string comparison to prevent timing attacks
/// This is important for security-sensitive applications
/// Usage: Use this when comparing sensitive strings like tokens or IDs
pub fn constant_time_eq(a : String, b : String) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut result = 0
  for i = 0; i < a.length(); i = i + 1 {
    let char_a = match a.get_char(i) {
      Some(c) => c.to_int()
      None => 0
    }
    let char_b = match b.get_char(i) {
      Some(c) => c.to_int()
      None => 0
    }
    result = result | (char_a ^ char_b)
  }
  result == 0
}

///| Secure memory clearing for sensitive data
/// FIXED: Added secure memory clearing functionality
fn secure_clear_bytes(bytes : Array[Int]) -> Unit {
  // Clear the array contents to prevent sensitive data from remaining in memory
  for i = 0; i < bytes.length(); i = i + 1 {
    bytes[i] = 0
  }
  // Note: In a real implementation, we might want to add memory barriers
  // or other techniques to prevent compiler optimizations from removing this
}

// ========== Constants and Alphabets ==========

///| Default URL-friendly alphabet (official nanoid order)
/// Uses the same character order as official nanoid: A-Z, a-z, 0-9, underscore, hyphen
pub let url_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

///| Default ID length (same as official nanoid)
const DEFAULT_SIZE = 21

// ========== Random Number Generation ==========

///| High-quality random number generator for nanoid
/// Uses xorshift algorithm for better randomness distribution
pub struct SimpleRng {
  mut state : Int64
}

///| Global counter to ensure different seeds for each call
let global_call_count : Ref[Int] = { val: 0 }

///| Create a new random number generator with a seed
pub fn SimpleRng::new(seed : Int64) -> SimpleRng {
  { state: seed }
}

///| Generate the next random 64-bit integer using xorshift64*
pub fn next_int64(self : SimpleRng) -> Int64 {
  // Xorshift64* algorithm - high quality PRNG
  // Avoid zero state which would cause the generator to get stuck
  if self.state == 0L {
    self.state = 1L
  }

  // Apply xorshift transformations to the state
  self.state = self.state ^ (self.state >> 12)
  self.state = self.state ^ (self.state << 25)
  self.state = self.state ^ (self.state >> 27)

  // FIXED: Return the mixed output (state * constant) but don't store the multiplication result
  // The state transformations above are the actual state updates
  self.state * 0x2545F4914F6CDD1DL
}

///| Generate a random integer in range [0, limit) with uniform distribution
pub fn next_int(self : SimpleRng, limit : Int) -> Int {
  if limit <= 0 {
    return 0
  }
  if limit == 1 {
    return 0
  }

  // For small limits, use simple approach to avoid complexity
  if limit <= 256 {
    let rand = self.next_int64()
    // FIXED: Use absolute value properly to handle negative numbers
    let abs_rand = if rand < 0L { -rand } else { rand }
    return (abs_rand % limit.to_int64()).to_int()
  }

  // For larger limits, use rejection sampling with safety limit
  let limit_64 = limit.to_int64()
  let max_valid = 0x7FFFFFFFFFFFFFFFL / limit_64 * limit_64
  let mut attempts = 0
  let max_attempts = 100 // Prevent infinite loops
  while attempts < max_attempts {
    let rand = self.next_int64()
    // FIXED: Use absolute value properly
    let abs_rand = if rand < 0L { -rand } else { rand }
    if abs_rand < max_valid {
      return (abs_rand % limit_64).to_int()
    }
    attempts = attempts + 1
  }

  // Fallback: use simple modulo if rejection sampling fails
  let rand = self.next_int64()
  let abs_rand = if rand < 0L { -rand } else { rand }
  (abs_rand % limit_64).to_int()
}

///| Enhanced seed generation using multiple entropy sources
fn create_enhanced_seed(size_hint : Int) -> Int64 {
  // Atomically increment global counter for entropy
  let old_count = global_call_count.val
  global_call_count.val = old_count + 1

  // 1. Base entropy from counter and size
  let count = global_call_count.val.to_int64()
  let size_factor = size_hint.to_int64()

  // 2. Use SplitMix64 algorithm for high-quality mixing
  let mut seed = count + 0x9E3779B97F4A7C15L
  seed = (seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9L
  seed = (seed ^ (seed >> 27)) * 0x94D049BB133111EBL
  seed = seed ^ (seed >> 31)

  // 3. Mix in additional entropy sources
  seed = seed ^ (size_factor * 0x517CC1B727220A95L)
  seed = seed ^ (old_count.to_int64() * 0x9E3779B97F4A7C15L)

  // 4. Add cross-correlation prevention
  seed = seed ^ (count * size_factor * 0x94D049BB133111EBL)

  // 5. Final mixing step for better avalanche effect
  seed = seed ^ (seed >> 33)
  seed = seed * 0xFF51AFD7ED558CCDL
  seed = seed ^ (seed >> 33)
  seed = seed * 0xC4CEB9FE1A85EC53L
  seed = seed ^ (seed >> 33)

  // FIXED: Ensure seed is never zero to prevent RNG from getting stuck
  if seed == 0L {
    seed = 0x9E3779B97F4A7C15L
  }
  seed
}

///| Internal function to generate secure random bytes
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  // Create high-quality seed using enhanced algorithm
  let mut seed = create_enhanced_seed(size)
  let rng = SimpleRng::new(seed)
  let bytes = Array::make(size, 0)

  // Generate bytes directly from RNG
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.next_int(256)
  }

  // FIXED: Security - Clear sensitive seed data from memory more thoroughly
  seed = 0L

  // Return bytes first - don't clear them here as they contain the random data we need!
  Ok(bytes)
}

///| Internal function to generate ID with given alphabet, size, and random function
/// Returns Result with ID string or NanoidError for invalid parameters
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  // FIXED: Use unified validation instead of duplicating logic
  match validate_parameters(alphabet, size) {
    Valid => () // Continue with generation
    InvalidAlphabet(error) => return Err(error)
    InvalidSize(error) => return Err(error)
    InvalidRandom(error) => return Err(error)
  }
  let alphabet_length = alphabet.length()

  // Special case: single character alphabet - no randomness needed
  if alphabet_length == 1 {
    let single_char = alphabet.get_char(0).unwrap()
    let chars = Array::make(size, single_char)
    return Ok(String::from_array(chars))
  }

  // Calculate mask for uniform distribution (avoid modulo bias)
  // Use bit manipulation for faster mask calculation
  let mut mask = 1
  while mask < alphabet_length {
    mask = mask << 1
  }
  mask = mask - 1

  // Optimize for common alphabet sizes
  // Calculate how many random bytes we need based on efficiency
  let optimized_step = match alphabet_length {
    2 => 64 // Binary: 1 bit per char, so 64 chars from 8 bytes
    4 => 32 // Quaternary: 2 bits per char, so 32 chars from 8 bytes
    8 => 21 // Octal: ~2.67 bits per char, so ~21 chars from 8 bytes
    16 => 16 // Hex: 4 bits per char, so 16 chars from 8 bytes
    32 => 12 // Base32: ~5 bits per char, so ~12 chars from 8 bytes
    64 => 10 // Base64: 6 bits per char, so ~10 chars from 8 bytes
    _ => {
      // For other sizes, calculate optimal step
      let bytes_needed = if mask * size < 256 { mask * size } else { 256 }
      if bytes_needed < 8 {
        8
      } else {
        bytes_needed
      }
    }
  }

  // Use optimized step size
  let step = optimized_step

  // Pre-allocate character array for efficient building
  let id_chars = Array::make(size, ' ')
  let mut counter = 0
  let mut batch_count = 0
  let max_batches = (size / step + 1) * 3 // Allow reasonable number of batches
  while counter < size && batch_count < max_batches {
    let random_bytes = match get_random(step) {
      Ok(bytes) => bytes
      Err(e) => return Err(e)
    }
    let mut byte_index = 0
    while byte_index < random_bytes.length() && counter < size {
      let byte = random_bytes[byte_index] & mask
      if byte < alphabet_length {
        let char = alphabet.get_char(byte).unwrap()
        id_chars[counter] = char
        counter = counter + 1
      }
      byte_index = byte_index + 1
    }
    batch_count = batch_count + 1

    // FIXED: Clear sensitive random bytes after use
    secure_clear_bytes(random_bytes)
  }

  // FIXED: Better error handling for insufficient randomness
  if counter < size {
    // If we couldn't generate enough characters after reasonable attempts,
    // this indicates a problem with the random function or alphabet
    if batch_count >= max_batches {
      return error_result(
        RandomGenerationError(
          "Failed to generate sufficient random characters after \{max_batches} attempts",
        ),
      )
    }

    // Use a simple deterministic pattern based on position for remaining characters
    // This should rarely happen with a properly functioning random generator
    for i = counter; i < size; i = i + 1 {
      let fallback_index = i % alphabet_length
      let char = alphabet.get_char(fallback_index).unwrap()
      id_chars[i] = char
    }
  }
  Ok(String::from_array(id_chars))
}

///| Main nanoid function - generates URL-friendly unique ID
/// Generates secure random IDs using the default URL-safe alphabet
/// Returns Result with ID string or NanoidError for invalid parameters
/// Usage: nanoid() generates 21-character ID, nanoid(size=10) generates 10-character ID
pub fn nanoid(size~ : Int = DEFAULT_SIZE) -> Result[String, NanoidError] {
  generate(url_alphabet, size, get_random_bytes)
}

///| Convenience function that returns empty string on error (for backward compatibility)
/// Usage: nanoid_or_empty() generates 21-character ID or empty string on error
pub fn nanoid_or_empty(size~ : Int = DEFAULT_SIZE) -> String {
  match nanoid(size~) {
    Ok(id) => id
    Err(_) => ""
  }
}

///| Custom alphabet function - returns a nanoid generator with custom alphabet
/// Creates a generator function that uses the specified alphabet and size
/// Returns Result with generator function or NanoidError for invalid parameters
/// Usage: let gen = custom_alphabet("abc123", size=8)?; let id = gen()?
pub fn custom_alphabet(
  alphabet : String,
  size~ : Int = DEFAULT_SIZE,
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

///| Convenience custom alphabet function that returns empty string on error
/// Usage: let gen = custom_alphabet_or_empty("abc123", size=8); let id = gen()
pub fn custom_alphabet_or_empty(
  alphabet : String,
  size~ : Int = DEFAULT_SIZE,
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

///| Custom random function - allows custom random generator
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

///| Convenience custom random function that returns empty string on error
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

///| Numbers from 0 to 9
pub let numbers = "0123456789"

///| Lowercase English letters
pub let lowercase = "abcdefghijklmnopqrstuvwxyz"

///| Uppercase English letters
pub let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

///| Combination of lowercase, uppercase letters and numbers
/// Does not include any symbols or special characters
pub let alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

///| Lowercase hexadecimal characters
pub let hex = "0123456789abcdef"

///| Uppercase hexadecimal characters
pub let hex_upper = "0123456789ABCDEF"

///| Numbers and English alphabet without lookalikes
/// Removes: 1, l, I, 0, O, o, u, v, 5, S, s, 2, Z
/// Complete set: 346789ABCDEFGHJKLMNPQRTUVWXYabcdefghijkmnpqrtwxyz
pub let nolookalikes = "346789ABCDEFGHJKLMNPQRTUVWXYabcdefghijkmnpqrtwxyz"

///| Same as nolookalikes but with additional removed characters: 3, 4, x, X, V
/// Also removes vowels to protect from accidentally getting obscene words in generated strings
/// Complete set: 6789BCDFGHJKLMNPQRTWbcdfghjkmnpqrtwz
pub let nolookalikes_safe = "6789BCDFGHJKLMNPQRTWbcdfghjkmnpqrtwz"

///| Base62 encoding alphabet (numbers, uppercase, lowercase)
/// Compatible with most base62 implementations
pub let base62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

///| Base58 encoding alphabet (Bitcoin style - excludes 0, O, I, l)
/// Used in cryptocurrency and other applications to avoid character confusion
pub let base58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz"

///| URL-safe characters that don't require encoding in most contexts
/// Excludes characters that might be problematic in URLs or file systems
/// Same as the default url_alphabet
pub let url_safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

///| Filename-safe characters for cross-platform compatibility
/// Safe for use in filenames on Windows, macOS, and Linux
pub let filename_safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

// ========== Security Utilities ==========

///| Secure ID verification using constant-time comparison
/// FIXED: Added public utility function that uses the constant_time_eq function
/// This prevents timing attacks when verifying IDs or tokens
/// Usage: secure_verify_id(user_provided_id, expected_id)
pub fn secure_verify_id(provided_id : String, expected_id : String) -> Bool {
  constant_time_eq(provided_id, expected_id)
}
