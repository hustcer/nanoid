// Demo of MoonBit nanoid implementation
// Compatible with Node.js nanoid API

///|
fn main {
  // Basic usage - same as JavaScript: nanoid()
  let id1 = @lib.nanoid()
  println("Default nanoid: \{id1}")

  // Custom length - same as JavaScript: nanoid(10)
  let id2 = @lib.nanoid(size=10)
  println("Custom length (10): \{id2}")

  // Custom alphabet - same as JavaScript: custom_alphabet("1234567890abcdef", 10)
  let hex_nanoid = @lib.custom_alphabet("1234567890abcdef", 10)
  let id3 = hex_nanoid(10)
  println("Custom alphabet (hex): \{id3}")

  // Custom alphabet with default size (using custom_alphabet)
  let hex_nanoid_8 = @lib.custom_alphabet("1234567890abcdef", 8)
  let id5 = hex_nanoid_8(8)
  println("Custom alphabet with default size: \{id5}")

  // Custom alphabet with different size
  let id6 = hex_nanoid(5)
  println("Custom alphabet with size override: \{id6}")

  // Using url_alphabet directly
  println("URL Alphabet: \{@lib.url_alphabet}")

  // Using preset alphabets
  println("Numbers only: \{@lib.numbers}")
  println("Hex alphabet: \{@lib.hex}")
  println("Hex upper: \{@lib.hex_upper}")
  println("Alphanumeric: \{@lib.alphanumeric}")
}
