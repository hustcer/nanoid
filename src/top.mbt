// Demo of MoonBit nanoid implementation
// Compatible with Node.js nanoid API

///|
fn main {
  println("=== MoonBit Nanoid Library Demo ===")

  // Note: nanoid functions now use proper error handling instead of abort()
  // This improves reliability and allows graceful error recovery

  // Basic usage with error handling
  try {
    let id1 = @lib.nanoid()
    println("Generated ID: \{id1}")
  } catch {
    _ => println("Error generating default ID")
  }
  try {
    let id2 = @lib.nanoid(size=10)
    println("Custom length (10): \{id2}")
  } catch {
    _ => println("Error generating custom size ID")
  }

  // Custom alphabet with error handling
  try {
    let hex_nanoid = @lib.custom_alphabet("1234567890abcdef", size=10)
    let id3 = hex_nanoid()
    println("Custom alphabet (hex): \{id3}")
  } catch {
    _ => println("Error with custom alphabet (hex)")
  }
  try {
    let hex_nanoid_default = @lib.custom_alphabet("1234567890abcdef")
    let id5 = hex_nanoid_default()
    println("Custom alphabet with default size: \{id5}")
  } catch {
    _ => println("Error with custom alphabet (default size)")
  }

  // Display preset alphabets (these don't throw errors)
  println("URL Alphabet: \{@lib.url_alphabet}")
  println("Numbers only: \{@lib.numbers}")
  println("Hex alphabet: \{@lib.hex}")
  println("Hex upper: \{@lib.hex_upper}")
  println("Alphanumeric: \{@lib.alphanumeric}")

  // Demonstrate error handling with invalid input
  println("\n=== Error Handling Demo ===")
  try {
    let _bad_id = @lib.nanoid(size=-1)
    println("This shouldn't print")
  } catch {
    _ => println("✓ Successfully caught error for negative size")
  }
  try {
    let _bad_generator = @lib.custom_alphabet("")
    println("This shouldn't print either")
  } catch {
    _ => println("✓ Successfully caught error for empty alphabet")
  }
  println("\n=== Demo completed ===")
}
