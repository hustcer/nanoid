// MoonBit port of Nano ID library
// A tiny, secure, URL-friendly, unique string ID generator
// API compatible with the official nanoid JavaScript library

// Default URL-friendly alphabet (same order as official nanoid)
///|
pub let url_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

// Default ID length (same as official nanoid)

///|
const DEFAULT_SIZE = 21

// Internal function to generate random bytes

///|
fn get_random_bytes(size : Int) -> Array[Int] {
  let rng = @random.Rand::new()
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.int(limit=256)
  }
  bytes
}

// Internal function to generate ID with given alphabet, size, and random function

///|
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Array[Int]
) -> String {
  let alphabet_length = alphabet.length()
  if alphabet_length == 0 {
    abort("Alphabet cannot be empty")
  }
  if alphabet_length > 256 {
    abort("Alphabet must contain 256 symbols or less")
  }
  if size <= 0 {
    abort("Size must be positive")
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
pub fn nanoid(size? : Int) -> String {
  let actual_size = match size {
    Some(s) => s
    None => DEFAULT_SIZE
  }
  generate(url_alphabet, actual_size, get_random_bytes)
}

// Custom alphabet function - returns a nanoid generator with custom alphabet
// Compatible with: custom_alphabet(alphabet, default_size)

///|
pub fn custom_alphabet(alphabet : String, length : Int) -> (Int) -> String {
  if alphabet.length() == 0 {
    abort("Custom alphabet cannot be empty")
  }
  if alphabet.length() > 256 {
    abort("Custom alphabet must contain 256 symbols or less")
  }
  fn(size : Int) -> String {
    let actual_size = if size <= 0 { length } else { size }
    generate(alphabet, actual_size, get_random_bytes)
  }
}

// Custom random function - allows custom random generator
// Compatible with: custom_random(alphabet, size, random)

///|
pub fn custom_random(
  alphabet : String,
  size : Int,
  random : (Int) -> Array[Int]
) -> () -> String {
  if alphabet.length() == 0 {
    abort("Custom alphabet cannot be empty")
  }
  if alphabet.length() > 256 {
    abort("Custom alphabet must contain 256 symbols or less")
  }
  fn() -> String { generate(alphabet, size, random) }
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
