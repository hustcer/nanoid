// MoonBit port of Nano ID library
// A tiny, secure, URL-friendly, unique string ID generator
// API compatible with the official nanoid JavaScript library

// Custom error type for nanoid operations
///|
suberror NanoidError String

// Default URL-friendly alphabet (same order as official nanoid)

///|
pub let url_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

// Default ID length (same as official nanoid)

///|
const DEFAULT_SIZE = 21

// Global counter to add entropy across function calls

///|
let call_counter : Ref[Int] = { val: 0 }

// Internal function to generate random bytes

///|
fn get_random_bytes(size : Int) -> Array[Int] {
  // Increment call counter for additional entropy
  call_counter.val = call_counter.val + 1
  let rng = @random.Rand::new()
  let bytes = Array::make(size, 0)

  // Generate some entropy based on call counter and previous values
  let mut entropy_accumulator = call_counter.val
  for i = 0; i < size; i = i + 1 {
    // Get base random value
    let base_random = rng.int(limit=256)

    // Mix with entropy accumulator for better randomness
    entropy_accumulator = (entropy_accumulator * 1103515245 + 12345) %
      2147483647
    let entropy_byte = entropy_accumulator / 65536 % 256

    // Combine base random with entropy
    bytes[i] = (base_random + entropy_byte + i * 17) % 256
  }
  bytes
}

// Internal function to generate ID with given alphabet, size, and random function

///|
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Array[Int]
) -> String raise NanoidError {
  let alphabet_length = alphabet.length()
  if alphabet_length == 0 {
    raise NanoidError("Alphabet cannot be empty")
  }
  if alphabet_length > 256 {
    raise NanoidError("Alphabet must contain 256 symbols or less")
  }
  if size <= 0 {
    raise NanoidError("Size must be positive")
  }

  // Special case: single character alphabet - no randomness needed
  if alphabet_length == 1 {
    let single_char = alphabet.char_at(0).to_string()
    let mut id = ""
    for i = 0; i < size; i = i + 1 {
      id = id + single_char
    }
    return id
  }

  // Calculate mask for uniform distribution (avoid modulo bias)
  let mut mask = 1
  while mask < alphabet_length {
    mask = mask * 2
  }
  mask = mask - 1

  // Calculate step size to reduce random calls
  let step = if mask * size < 256 { mask * size } else { 256 }
  let mut id = ""
  let mut counter = 0
  while counter < size {
    let random_bytes = get_random(step)
    let mut byte_index = 0
    while byte_index < random_bytes.length() && counter < size {
      let byte = random_bytes[byte_index] & mask
      if byte < alphabet_length {
        let char = alphabet.char_at(byte)
        id = id + char.to_string()
        counter = counter + 1
      }
      byte_index = byte_index + 1
    }
  }
  id
}

// Main nanoid function - generates URL-friendly unique ID
// Default version: nanoid()

///|
pub fn nanoid(size~ : Int = DEFAULT_SIZE) -> String raise NanoidError {
  generate(url_alphabet, size, get_random_bytes)
}

// Custom alphabet function - returns a nanoid generator with custom alphabet
// Compatible with: custom_alphabet(alphabet, size)

///|
pub fn custom_alphabet(
  alphabet : String,
  size~ : Int = DEFAULT_SIZE
) -> (() -> String raise NanoidError) raise NanoidError {
  if alphabet.length() == 0 {
    raise NanoidError("Custom alphabet cannot be empty")
  }
  if alphabet.length() > 256 {
    raise NanoidError("Custom alphabet must contain 256 symbols or less")
  }
  fn() -> String raise NanoidError {
    generate(alphabet, size, get_random_bytes)
  }
}

// Custom random function - allows custom random generator
// Compatible with: custom_random(alphabet, size, random)

///|
pub fn custom_random(
  alphabet : String,
  size : Int,
  random : (Int) -> Array[Int]
) -> (() -> String raise NanoidError) raise NanoidError {
  if alphabet.length() == 0 {
    raise NanoidError("Custom alphabet cannot be empty")
  }
  if alphabet.length() > 256 {
    raise NanoidError("Custom alphabet must contain 256 symbols or less")
  }
  fn() -> String raise NanoidError { generate(alphabet, size, random) }
}

// Common alphabet presets for convenience (not part of official API)

///|
pub let numbers = "0123456789"

///|
pub let lowercase = "abcdefghijklmnopqrstuvwxyz"

///|
pub let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

///|
pub let alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

///|
pub let hex = "0123456789abcdef"

///|
pub let hex_upper = "0123456789ABCDEF"
