// Demo of MoonBit nanoid implementation
// Now with proper error handling using Result types

///|
fn main {
  println("=== MoonBit Nanoid Library Demo ===")

  // Basic usage with proper error handling
  match @nanoid.nanoid() {
    Ok(id1) => println("Generated ID: \{id1}")
    Err(e) => println("Error generating ID: \{e.to_string()}")
  }

  match @nanoid.nanoid(size=10) {
    Ok(id2) => println("Custom length (10): \{id2}")
    Err(e) => println("Error generating custom length ID: \{e.to_string()}")
  }

  // Custom alphabet with proper error handling
  match @nanoid.custom_alphabet("1234567890abcdef", size=10) {
    Ok(hex_generator) => {
      match hex_generator() {
        Ok(id3) => println("Custom alphabet (hex): \{id3}")
        Err(e) => println("Error generating hex ID: \{e.to_string()}")
      }
    }
    Err(e) => println("Error creating hex generator: \{e.to_string()}")
  }

  match @nanoid.custom_alphabet("1234567890abcdef") {
    Ok(hex_generator_default) => {
      match hex_generator_default() {
        Ok(id5) => println("Custom alphabet with default size: \{id5}")
        Err(e) => println("Error generating default hex ID: \{e.to_string()}")
      }
    }
    Err(e) => println("Error creating default hex generator: \{e.to_string()}")
  }

  // Display preset alphabets
  println("\n=== Preset Alphabets ===")
  println("URL Alphabet: \{@nanoid.url_alphabet}")
  println("Numbers only: \{@nanoid.numbers}")
  println("Hex alphabet: \{@nanoid.hex}")
  println("Hex upper: \{@nanoid.hex_upper}")
  println("Alphanumeric: \{@nanoid.alphanumeric}")

  // Demonstrate proper error handling with invalid input
  println("\n=== Error Handling Demo ===")

  // Negative size returns error
  match @nanoid.nanoid(size=-1) {
    Ok(id) => println("Unexpected success: \{id}")
    Err(e) => println("Negative size (-1) → Error: \{e.to_string()}")
  }

  // Zero size returns error
  match @nanoid.nanoid(size=0) {
    Ok(id) => println("Unexpected success: \{id}")
    Err(e) => println("Zero size (0) → Error: \{e.to_string()}")
  }

  // Empty alphabet returns error
  match @nanoid.custom_alphabet("", size=8) {
    Ok(_) => println("Unexpected success with empty alphabet")
    Err(e) => println("Empty alphabet → Error: \{e.to_string()}")
  }

  // Multiple issues: empty alphabet + negative size
  match @nanoid.custom_alphabet("", size=-5) {
    Ok(_) => println("Unexpected success with multiple issues")
    Err(e) => println("Empty alphabet + negative size → Error: \{e.to_string()}")
  }

  // Demonstrate backward compatibility functions
  println("\n=== Backward Compatibility Demo ===")
  let compat_id = @nanoid.nanoid_or_empty()
  println("Backward compatible ID: \{compat_id}")

  let compat_empty = @nanoid.nanoid_or_empty(size=-1)
  println("Backward compatible with error (should be empty): '\{compat_empty}'")

  let compat_generator = @nanoid.custom_alphabet_or_empty("ABC", size=5)
  let compat_custom_id = compat_generator()
  println("Backward compatible custom ID: \{compat_custom_id}")

  println("\n=== Demo completed ===")
  println("✓ All operations handled errors properly")
}
