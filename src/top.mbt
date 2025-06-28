// Demo of MoonBit nanoid implementation
// Compatible with Node.js nanoid API

///|
fn main {
  println("=== MoonBit Nanoid Library Demo ===")

  // Note: nanoid library now uses graceful degradation instead of throwing errors
  // Invalid parameters are automatically corrected to sensible defaults

  // Basic usage - always works
  let id1 = @nanoid.nanoid()
  println("Generated ID: \{id1}")
  let id2 = @nanoid.nanoid(size=10)
  println("Custom length (10): \{id2}")

  // Custom alphabet - always works
  let hex_nanoid = @nanoid.custom_alphabet("1234567890abcdef", size=10)
  let id3 = hex_nanoid()
  println("Custom alphabet (hex): \{id3}")
  let hex_nanoid_default = @nanoid.custom_alphabet("1234567890abcdef")
  let id5 = hex_nanoid_default()
  println("Custom alphabet with default size: \{id5}")

  // Display preset alphabets
  println("URL Alphabet: \{@nanoid.url_alphabet}")
  println("Numbers only: \{@nanoid.numbers}")
  println("Hex alphabet: \{@nanoid.hex}")
  println("Hex upper: \{@nanoid.hex_upper}")
  println("Alphanumeric: \{@nanoid.alphanumeric}")

  // Demonstrate graceful degradation with invalid input
  println("\n=== Graceful Degradation Demo ===")

  // Negative size gets corrected to default (21)
  let id_negative_size = @nanoid.nanoid(size=-1)
  println(
    "Negative size (-1) → length \{id_negative_size.length()}: \{id_negative_size}",
  )

  // Zero size gets corrected to default (21)
  let id_zero_size = @nanoid.nanoid(size=0)
  println("Zero size (0) → length \{id_zero_size.length()}: \{id_zero_size}")

  // Empty alphabet gets corrected to default URL-safe alphabet
  let empty_alphabet_generator = @nanoid.custom_alphabet("", size=8)
  let id_empty_alphabet = empty_alphabet_generator()
  println(
    "Empty alphabet → uses default, length \{id_empty_alphabet.length()}: \{id_empty_alphabet}",
  )

  // Multiple issues: empty alphabet + negative size
  let multi_issue_generator = @nanoid.custom_alphabet("", size=-5)
  let id_multi_issue = multi_issue_generator()
  println(
    "Empty alphabet + negative size → length \{id_multi_issue.length()}: \{id_multi_issue}",
  )
  println("\n=== Demo completed ===")
  println("✓ All operations succeeded with graceful degradation")
}
