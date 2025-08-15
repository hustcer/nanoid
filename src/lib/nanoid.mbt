///| MoonBit port of Nano ID library
/// A tiny, secure, URL-friendly, unique string ID generator
/// MoonBit implementation compatible with the official nanoid JavaScript library

// ========== Error Handling ==========

///| Error types for nanoid operations
pub enum NanoidError {
  EmptyAlphabet
  OversizedAlphabet(Int)  // Contains the actual length
  InvalidSize(Int)        // Contains the invalid size value
  RandomGenerationError(String)
} derive(Eq)

///| Convert NanoidError to string representation
pub fn NanoidError::to_string(self : NanoidError) -> String {
  match self {
    EmptyAlphabet => "Alphabet cannot be empty"
    OversizedAlphabet(len) => "Alphabet length (\{len}) exceeds maximum of 256 characters"
    InvalidSize(size) => "Size (\{size}) must be greater than 0"
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

///| Internal function to generate secure random bytes
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  let rng = @random.Rand::new()
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.int(limit=256)
  }
  Ok(bytes)
}

///| Internal function to generate ID with given alphabet, size, and random function
/// Returns Result with ID string or NanoidError for invalid parameters
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError]
) -> Result[String, NanoidError] {
  // Check for empty alphabet
  if alphabet.length() == 0 {
    return error_result(EmptyAlphabet)
  }

  // Check for oversized alphabet
  if alphabet.length() > 256 {
    return error_result(OversizedAlphabet(alphabet.length()))
  }

  // Check for invalid size
  if size <= 0 {
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
  let mut mask = 1
  while mask < alphabet_length {
    mask = mask * 2
  }
  mask = mask - 1

  // Calculate step size to reduce random calls
  let step = if mask * size < 256 {
    mask * size
  } else {
    256
  }

  // Pre-allocate character array for efficient building
  let id_chars = Array::make(size, ' ')
  let mut counter = 0

  while counter < size {
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
  match nanoid(size=size) {
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
  size~ : Int = DEFAULT_SIZE
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  // Validate parameters early
  if alphabet.length() == 0 {
    return error_result(EmptyAlphabet)
  }
  if alphabet.length() > 256 {
    return error_result(OversizedAlphabet(alphabet.length()))
  }
  if size <= 0 {
    return error_result(InvalidSize(size))
  }

  Ok(fn() -> Result[String, NanoidError] { generate(alphabet, size, get_random_bytes) })
}

///| Convenience custom alphabet function that returns empty string on error
/// Usage: let gen = custom_alphabet_or_empty("abc123", size=8); let id = gen()
pub fn custom_alphabet_or_empty(
  alphabet : String,
  size~ : Int = DEFAULT_SIZE
) -> () -> String {
  match custom_alphabet(alphabet, size=size) {
    Ok(gen) => fn() -> String {
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
  random : (Int) -> Result[Array[Int], NanoidError]
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  // Validate parameters early
  if alphabet.length() == 0 {
    return error_result(EmptyAlphabet)
  }
  if alphabet.length() > 256 {
    return error_result(OversizedAlphabet(alphabet.length()))
  }
  if size <= 0 {
    return error_result(InvalidSize(size))
  }

  Ok(fn() -> Result[String, NanoidError] { generate(alphabet, size, random) })
}

///| Convenience custom random function that returns empty string on error
/// Usage: let gen = custom_random_or_empty(alphabet, size, random_fn); let id = gen()
pub fn custom_random_or_empty(
  alphabet : String,
  size : Int,
  random : (Int) -> Array[Int]
) -> () -> String {
  let safe_random = fn(size : Int) -> Result[Array[Int], NanoidError] {
    Ok(random(size))
  }

  match custom_random(alphabet, size, safe_random) {
    Ok(gen) => fn() -> String {
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
