# Nano ID for MoonBit

A MoonBit port of the [Nano ID](https://github.com/ai/nanoid) library - a tiny, secure, URL-friendly, unique string ID generator.

## Features

- **Small**: Simple implementation with minimal code
- **Safe**: Uses MoonBit's random number generation
- **URL-friendly**: Uses URL-safe characters (`A-Za-z0-9_-`)
- **Customizable**: Supports custom alphabets and lengths
- **Fast**: Efficient ID generation algorithm optimized with uniform distribution
- **API Compatible**: Similar API to Node.js nanoid

## Installation

This is a MoonBit project that builds with the MoonBit toolchain.

## Dependencies

- `moonbitlang/core`: Official MoonBit core library for random number generation

## API

### Basic Usage

```moonbit
// Generate default length (21) nano ID
let id = @lib.nanoid() // => "V1StGXR8_Z5jdHi6B-myT"

// Generate nano ID with specified length
let short_id = @lib.nanoid(size=10) // => "IRFa-VaY2b"
```

### Custom Alphabet

```moonbit
// Create a custom alphabet generator with default size (21)
let hex_generator = @lib.custom_alphabet("0123456789ABCDEF")
let hex_id = hex_generator() // => "2A4F7E1B9C3D4F5E6A7B"

// Create a custom alphabet generator with specified size
let hex_generator_8 = @lib.custom_alphabet("0123456789ABCDEF", size=8)
let hex_id_8 = hex_generator_8() // => "2A4F7E1B"
```

### Custom Random Generator

```moonbit
// Define custom random function
fn my_random(size : Int) -> Array[Int] {
  // Your custom random implementation
  // Note: get_random_bytes is internal, use a proper random implementation
  let rng = @random.Rand::new()
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.int(limit=256)
  }
  bytes
}

// Create generator with custom random
let custom_gen = @lib.custom_random("abc123", 10, my_random)
let custom_id = custom_gen() // => uses your random function
```

### Predefined Alphabets

```moonbit
// Available alphabet constants
@lib.url_alphabet     // "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
@lib.numbers          // "0123456789"
@lib.lowercase        // "abcdefghijklmnopqrstuvwxyz"
@lib.uppercase        // "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
@lib.alphanumeric     // "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
@lib.hex              // "0123456789abcdef"
@lib.hex_upper        // "0123456789ABCDEF"
```

## API Reference

### Functions

| Function | Description | Example |
|----------|-------------|---------|
| `nanoid()` | Generate ID with default length (21) | `nanoid()` |
| `nanoid(size=n)` | Generate ID with specified length | `nanoid(size=10)` |
| `custom_alphabet(alphabet, size=21)` | Create custom alphabet generator | `custom_alphabet("abc123", size=8)` |
| `custom_random(alphabet, size, random_fn)` | Create generator with custom random function | `custom_random("abc", 10, my_random)` |

### Function Signatures

```moonbit
// Main nanoid function
pub fn nanoid(size~ : Int = 21) -> String

// Custom alphabet generator
pub fn custom_alphabet(alphabet : String, size~ : Int = 21) -> () -> String

// Custom random generator
pub fn custom_random(alphabet : String, size : Int, random : (Int) -> Array[Int]) -> () -> String
```

### Constants

| Constant | Value | Use Case |
|----------|-------|----------|
| `url_alphabet` | A-Za-z0-9_- (64 chars) | Default web-safe IDs |
| `numbers` | 0-9 (10 chars) | Numeric codes |
| `lowercase` | a-z (26 chars) | Lowercase identifiers |
| `uppercase` | A-Z (26 chars) | Uppercase codes |
| `alphanumeric` | A-Za-z0-9 (62 chars) | Alphanumeric IDs |
| `hex` | 0-9a-f (16 chars) | Hex lowercase |
| `hex_upper` | 0-9A-F (16 chars) | Hex uppercase |

## Security

This implementation:

- Uses MoonBit's random number generation from `moonbitlang/core`
- Implements uniform distribution to avoid modulo bias
- Uses bit masking for efficient random selection
- Provides cryptographically secure randomness (depends on platform)

## Entropy Analysis

The default configuration (64 characters, 21 length) provides:
- **~130 bits of entropy** (log2(64^21))
- **Excellent collision resistance** for practical applications
- **URL-safe character set** for web applications

### Collision Probability

For 1 million IDs with default settings, the collision probability is negligible (< 1 in 10^15).

## Comparison with UUID

| Feature | Nano ID | UUID v4 |
|---------|---------|---------|
| Size | 21 chars | 36 chars |
| Alphabet | 64 (URL-safe) | 16 (hex) + dashes |
| Entropy | ~130 bits | 122 bits |
| Readability | High | Low |
| URL-safe | Yes | No (needs encoding) |

## Usage Examples

```moonbit
fn main {
  // Basic usage
  let id = @lib.nanoid()
  println("Generated: \{id}")

  // Custom size
  let short = @lib.nanoid(size=8)
  println("Short ID: \{short}")

  // Custom alphabet for hex IDs with default size
  let hex_gen = @lib.custom_alphabet(@lib.hex)
  let hex_id = hex_gen()
  println("Hex ID (default): \{hex_id}")

  // Custom alphabet for hex IDs with specific size
  let hex_gen_8 = @lib.custom_alphabet(@lib.hex, size=8)
  let hex_id_8 = hex_gen_8()
  println("Hex ID (8 chars): \{hex_id_8}")

  // Numeric codes
  let num_gen = @lib.custom_alphabet(@lib.numbers, size=6)
  let code = num_gen()
  println("Numeric code: \{code}")

  // Using preset alphabets
  println("URL Alphabet: \{@lib.url_alphabet}")
  println("Numbers: \{@lib.numbers}")
  println("Hex: \{@lib.hex}")
}
```

## Building and Running

```bash
# Check for errors
moon check

# Run the example
moon run src

# Build the project
moon build
```

## Algorithm Details

The implementation uses an optimized algorithm that:

1. **Calculates bit mask** for uniform distribution
2. **Batches random byte generation** for efficiency
3. **Avoids modulo bias** using rejection sampling
4. **Minimizes random calls** through step calculation

This ensures both security and performance while maintaining compatibility with the original nanoid design.

## License

MIT License - feel free to use in your projects!

## References

- [Original Nano ID (JavaScript)](https://github.com/ai/nanoid)
- [MoonBit Language](https://www.moonbitlang.com/)
- [ID collision probability calculator](https://zelark.github.io/nano-id-cc/)
