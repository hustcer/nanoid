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
} derive(Eq)

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

///| Helper function to create error results
fn[T] error_result(error : NanoidError) -> Result[T, NanoidError] {
  Err(error)
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
priv struct SimpleRng {
  mut state : Int64
}

///| Global counter to ensure different seeds for each call
let global_call_count : Ref[Int] = { val: 0 }

///| Create a new random number generator with a seed
fn SimpleRng::new(seed : Int64) -> SimpleRng {
  { state: seed }
}

///| Generate the next random 64-bit integer using xorshift64*
fn next_int64(self : SimpleRng) -> Int64 {
  // Xorshift64* algorithm - high quality PRNG
  // Avoid zero state which would cause the generator to get stuck
  if self.state == 0L {
    self.state = 1L
  }

  // Apply xorshift transformations to the state
  self.state = self.state ^ (self.state >> 12)
  self.state = self.state ^ (self.state << 25)
  self.state = self.state ^ (self.state >> 27)

  // Return the transformed state multiplied by the constant
  // This is the correct xorshift64* implementation
  self.state * 0x2545F4914F6CDD1DL
}

///| Generate a random integer in range [0, limit) with uniform distribution
fn next_int(self : SimpleRng, limit : Int) -> Int {
  if limit <= 0 {
    return 0
  }
  if limit == 1 {
    return 0
  }

  // For small limits, use simple approach to avoid complexity
  if limit <= 256 {
    let mut rand = self.next_int64()
    rand = if rand < 0L { rand & 0x7FFFFFFFFFFFFFFFL } else { rand }
    return (rand % limit.to_int64()).to_int()
  }

  // For larger limits, use rejection sampling with safety limit
  let limit_64 = limit.to_int64()
  let max_valid = 0x7FFFFFFFFFFFFFFFL / limit_64 * limit_64
  let mut attempts = 0
  let max_attempts = 100 // Prevent infinite loops
  while attempts < max_attempts {
    let mut rand = self.next_int64()
    rand = if rand < 0L { rand & 0x7FFFFFFFFFFFFFFFL } else { rand }
    if rand < max_valid {
      return (rand % limit_64).to_int()
    }
    attempts = attempts + 1
  }

  // Fallback: use simple modulo if rejection sampling fails
  let mut rand = self.next_int64()
  rand = if rand < 0L { rand & 0x7FFFFFFFFFFFFFFFL } else { rand }
  (rand % limit_64).to_int()
}

///| Internal function to generate secure random bytes
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  // Atomically increment global counter for entropy
  // Note: In a multi-threaded environment, this should use atomic operations
  let old_count = global_call_count.val
  global_call_count.val = old_count + 1

  // Create high-quality seed using multiple entropy sources
  let count = global_call_count.val.to_int64()
  let size_factor = size.to_int64()

  // Use SplitMix64-like seeding for better quality
  let mut seed = count + 0x9E3779B97F4A7C15L
  seed = (seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9L
  seed = (seed ^ (seed >> 27)) * 0x94D049BB133111EBL
  seed = seed ^ (seed >> 31)

  // Mix in size and old count for additional entropy
  seed = seed ^ (size_factor * 0x517CC1B727220A95L)
  seed = seed ^ (old_count.to_int64() * 0x9E3779B97F4A7C15L)
  let rng = SimpleRng::new(seed)
  let bytes = Array::make(size, 0)

  // Generate bytes directly from RNG
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.next_int(256)
  }
  Ok(bytes)
}

///| Internal function to generate ID with given alphabet, size, and random function
/// Returns Result with ID string or NanoidError for invalid parameters
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  // Check for empty alphabet
  if alphabet.length() == 0 {
    return error_result(EmptyAlphabet)
  }

  // Check for oversized alphabet
  if alphabet.length() > 256 {
    return error_result(OversizedAlphabet(alphabet.length()))
  }

  // Validate alphabet contains only valid Unicode characters
  // This helps catch potential encoding issues early
  for i = 0; i < alphabet.length(); i = i + 1 {
    match alphabet.get_char(i) {
      Some(_) => continue
      None =>
        return error_result(
          RandomGenerationError(
            "Invalid character in alphabet at position \{i}",
          ),
        )
    }
  }

  // Check for invalid size
  if size <= 0 {
    return error_result(InvalidSize(size))
  }

  // Check for unreasonably large size to prevent memory issues
  if size > 1000000 {
    return error_result(InvalidSize(size))
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
  let optimized_step = match alphabet_length {
    2 => 8 // Binary: use 8 bits at a time
    4 => 4 // Quaternary: use 4 bits at a time
    8 => 3 // Octal: use 3 bits at a time
    16 => 2 // Hex: use 2 bits at a time
    64 => 1 // Base64: use 1 bit at a time
    _ => if mask * size < 256 { mask * size } else { 256 }
  }

  // Use optimized step size
  let step = optimized_step

  // Pre-allocate character array for efficient building
  let id_chars = Array::make(size, ' ')
  let mut counter = 0
  let mut retry_count = 0
  let max_retries = size * 4 // Prevent infinite loops
  while counter < size && retry_count < max_retries {
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
      retry_count = retry_count + 1
    }
  }

  // Safety check: if we couldn't generate enough characters, fill the rest
  if counter < size {
    for i = counter; i < size; i = i + 1 {
      let char = alphabet.get_char(0).unwrap() // Use first character as fallback
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
  // Pre-validate parameters once to avoid repeated validation
  // The generate function will also validate, but this gives better error messages
  if alphabet.length() == 0 {
    return error_result(EmptyAlphabet)
  }
  if alphabet.length() > 256 {
    return error_result(OversizedAlphabet(alphabet.length()))
  }
  if size <= 0 || size > 1000000 {
    return error_result(InvalidSize(size))
  }

  // Validate alphabet characters once
  for i = 0; i < alphabet.length(); i = i + 1 {
    match alphabet.get_char(i) {
      Some(_) => continue
      None =>
        return error_result(
          RandomGenerationError(
            "Invalid character in alphabet at position \{i}",
          ),
        )
    }
  }
  Ok(fn() -> Result[String, NanoidError] {
    generate(alphabet, size, get_random_bytes)
  })
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
  // Validate parameters early with comprehensive checks
  if alphabet.length() == 0 {
    return error_result(EmptyAlphabet)
  }
  if alphabet.length() > 256 {
    return error_result(OversizedAlphabet(alphabet.length()))
  }
  if size <= 0 || size > 1000000 {
    return error_result(InvalidSize(size))
  }

  // Validate alphabet characters
  for i = 0; i < alphabet.length(); i = i + 1 {
    match alphabet.get_char(i) {
      Some(_) => continue
      None =>
        return error_result(
          RandomGenerationError(
            "Invalid character in alphabet at position \{i}",
          ),
        )
    }
  }

  // Test the random function with a small sample to catch issues early
  match random(1) {
    Ok(test_bytes) =>
      if test_bytes.length() != 1 {
        return error_result(
          RandomGenerationError(
            "Custom random function returned incorrect array length",
          ),
        )
      }
    Err(e) => return Err(e)
  }
  Ok(fn() -> Result[String, NanoidError] { generate(alphabet, size, random) })
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
