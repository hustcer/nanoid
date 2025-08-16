// Demo of MoonBit nanoid implementation
// Now with proper error handling using Result types

///|
fn main {
  println("=== MoonBit Nanoid Library Demo ===")

  // Basic usage with proper error handling - generate multiple IDs to test randomness
  match @nid.nanoid() {
    Ok(id1) => println("Generated ID 1: \{id1}")
    Err(e) => println("Error generating ID: \{e.to_string()}")
  }
  match @nid.nanoid() {
    Ok(id2) => println("Generated ID 2: \{id2}")
    Err(e) => println("Error generating ID: \{e.to_string()}")
  }
  match @nid.nanoid() {
    Ok(id3) => println("Generated ID 3: \{id3}")
    Err(e) => println("Error generating ID: \{e.to_string()}")
  }
  match @nid.nanoid(size=10) {
    Ok(id4) => println("Custom length (10): \{id4}")
    Err(e) => println("Error generating custom length ID: \{e.to_string()}")
  }

  // Custom alphabet with proper error handling
  match @nid.custom_alphabet("1234567890abcdef", size=10) {
    Ok(hex_generator) =>
      match hex_generator() {
        Ok(id3) => println("Custom alphabet (hex): \{id3}")
        Err(e) => println("Error generating hex ID: \{e.to_string()}")
      }
    Err(e) => println("Error creating hex generator: \{e.to_string()}")
  }
  match @nid.custom_alphabet("1234567890abcdef") {
    Ok(hex_generator_default) =>
      match hex_generator_default() {
        Ok(id5) => println("Custom alphabet with default size: \{id5}")
        Err(e) => println("Error generating default hex ID: \{e.to_string()}")
      }
    Err(e) => println("Error creating default hex generator: \{e.to_string()}")
  }

  // Display preset alphabets
  println("\n=== Preset Alphabets ===")
  println("URL Alphabet: \{@nid.url_alphabet}")
  println("Numbers only: \{@nid.numbers}")
  println("Hex alphabet: \{@nid.hex}")
  println("Hex upper: \{@nid.hex_upper}")
  println("Alphanumeric: \{@nid.alphanumeric}")

  // Demonstrate proper error handling with invalid input
  println("\n=== Error Handling Demo ===")

  // Negative size returns error
  match @nid.nanoid(size=-1) {
    Ok(id) => println("Unexpected success: \{id}")
    Err(e) => println("Negative size (-1) → Error: \{e.to_string()}")
  }

  // Zero size returns error
  match @nid.nanoid(size=0) {
    Ok(id) => println("Unexpected success: \{id}")
    Err(e) => println("Zero size (0) → Error: \{e.to_string()}")
  }

  // Test large size limit
  match @nid.nanoid(size=2000000) {
    Ok(id) => println("Unexpected success with large size: \{id.length()}")
    Err(e) => println("Large size (2,000,000) → Error: \{e.to_string()}")
  }

  // Empty alphabet returns error
  match @nid.custom_alphabet("", size=8) {
    Ok(_) => println("Unexpected success with empty alphabet")
    Err(e) => println("Empty alphabet → Error: \{e.to_string()}")
  }

  // Test oversized alphabet
  let mut long_alphabet = ""
  for i = 0; i < 300; i = i + 1 {
    long_alphabet = long_alphabet + "A"
  }
  match @nid.custom_alphabet(long_alphabet, size=5) {
    Ok(_) => println("Unexpected success with oversized alphabet")
    Err(e) =>
      println("Oversized alphabet (300 chars) → Error: \{e.to_string()}")
  }

  // Test duplicate characters in alphabet
  match @nid.custom_alphabet("ABCA", size=5) {
    Ok(_) => println("Unexpected success with duplicate characters")
    Err(e) => println("Duplicate characters → Error: \{e.to_string()}")
  }

  // Multiple issues: empty alphabet + negative size
  match @nid.custom_alphabet("", size=-5) {
    Ok(_) => println("Unexpected success with multiple issues")
    Err(e) =>
      println("Empty alphabet + negative size → Error: \{e.to_string()}")
  }

  // Demonstrate backward compatibility functions
  println("\n=== Backward Compatibility Demo ===")
  let compat_id = @nid.nanoid_or_empty()
  println("Backward compatible ID: \{compat_id}")
  let compat_empty = @nid.nanoid_or_empty(size=-1)
  println("Backward compatible with error (should be empty): '\{compat_empty}'")
  let compat_generator = @nid.custom_alphabet_or_empty("ABC", size=5)
  let compat_custom_id = compat_generator()
  println("Backward compatible custom ID: \{compat_custom_id}")
  println("\n=== Demo completed ===")
  println("✓ All operations handled errors properly")
}
