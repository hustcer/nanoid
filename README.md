# MoonBit Nanoid

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A tiny, secure, URL-friendly, unique string ID generator for [MoonBit](https://moonbitlang.com/).

This is a MoonBit port of the popular [Nano ID](https://github.com/ai/nanoid) JavaScript library, maintaining API compatibility while providing excellent error handling through MoonBit's robust type system.

## Features

- **Small & Fast**: Minimal overhead, optimized for performance
- **URL-Safe**: Generated IDs are safe for use in URLs, filenames, and databases
- **Customizable**: Support for custom alphabets and ID sizes
- **Unicode Support**: Full support for Unicode alphabets including emoji and CJK characters
- **Error Safe**: Proper error handling with `Result` types instead of runtime panics
- **Type Safe**: Full MoonBit type system support with `derive(Show, Eq)` on error types
- **Zero Dependencies**: No external dependencies beyond MoonBit core

> **Note**: MoonBit currently lacks a system entropy API, so the ChaCha8 RNG uses a deterministic seed. All ID sequences are reproducible across program runs. This will be resolved when MoonBit adds system entropy support.

## Quick Start

1. Add this module as a dependency to your MoonBit project.

   ```bash
   moon update
   moon add hustcer/nanoid
   ```

2. Import `hustcer/nanoid` package where you need it.

   ```json
   {
     "import": [
        { "path": "hustcer/nanoid/lib", "alias": "nanoid" }
      ]
   }
   ```

### Basic Usage

```moonbit
// Generate a URL-safe ID with default length (21 characters)
let id_result = @nanoid.nanoid()
match id_result {
  Ok(id) => println(id) // => "rMf19KHCD5GQw0wzQnEKd"
  Err(e) => println("Error: \{e.to_string()}")
}

// Generate an ID with custom length
let short_id_result = @nanoid.nanoid(size=10)
match short_id_result {
  Ok(short_id) => println(short_id) // => "yue8fl8f9X"
  Err(e) => println("Error: \{e.to_string()}")
}

// For convenience, use the backward-compatible functions
let id = @nanoid.nanoid_or_empty()
println(id) // => "rMf19KHCD5GQw0wzQnEKd" or "" on error
```

### Custom Alphabets

```moonbit
// Create a generator with custom alphabet
let hex_generator_result = @nanoid.custom_alphabet(@nanoid.hex, size=8)
match hex_generator_result {
  Ok(hex_generator) => {
    match hex_generator() {
      Ok(hex_id) => println(hex_id) // => "a1b2c3d4"
      Err(e) => println("Generation error: \{e.to_string()}")
    }
  }
  Err(e) => println("Setup error: \{e.to_string()}")
}

// For convenience, use the backward-compatible functions
let safe_generator = @nanoid.custom_alphabet_or_empty(@nanoid.nolookalikes, size=12)
let safe_id = safe_generator()
println(safe_id) // => "6B9CMnpqrt7w" or "" on error

// Unicode alphabets are fully supported
let emoji_gen = @nanoid.custom_alphabet("😀😁😂🤣😃😄", size=5)
```

## API Reference

### Core Functions

#### `nanoid(size? : Int = 21) -> Result[String, NanoidError]`

Generates a URL-safe unique ID using the default alphabet.

- `size`: Length of the generated ID (default: 21)
- Returns: `Ok(String)` with the generated ID, or `Err(NanoidError)` for invalid parameters

```moonbit
let id1 = @nanoid.nanoid()          // Ok("...") with 21 characters
let id2 = @nanoid.nanoid(size=10)   // Ok("...") with 10 characters
let id3 = @nanoid.nanoid(size=0)    // Err(SizeTooSmall(0))
```

#### `nanoid_or_empty(size? : Int = 21) -> String`

Convenience function that returns empty string on error (for backward compatibility).

- `size`: Length of the generated ID (default: 21)
- Returns: A random string ID, or empty string if invalid

```moonbit
let id1 = @nanoid.nanoid_or_empty()          // 21 characters or ""
let id2 = @nanoid.nanoid_or_empty(size=10)   // 10 characters or ""
let id3 = @nanoid.nanoid_or_empty(size=0)    // ""
```

#### `custom_alphabet(alphabet : String, size? : Int = 21) -> Result[() -> Result[String, NanoidError], NanoidError]`

Creates a generator function with a custom alphabet.

- `alphabet`: String containing unique characters to use (1-256 characters, no duplicates)
- `size`: Default length for generated IDs (must be positive)
- Returns: `Ok(generator)` or `Err(NanoidError)` for invalid parameters

```moonbit
let generator_result = @nanoid.custom_alphabet("0123456789", size=8)
match generator_result {
  Ok(generator) => {
    match generator() {
      Ok(numeric_id) => println(numeric_id)  // => "12345678"
      Err(e) => println("Generation error: \{e.to_string()}")
    }
  }
  Err(e) => println("Setup error: \{e.to_string()}")
}

let bad_result = @nanoid.custom_alphabet("", size=8)
// Returns Err(EmptyAlphabet)
```

#### `custom_alphabet_or_empty(alphabet : String, size? : Int = 21) -> () -> String`

Convenience function that returns empty string on error (for backward compatibility).

- `alphabet`: String containing unique characters to use
- `size`: Default length for generated IDs
- Returns: A generator function that returns string or empty string on error

#### `custom_random(alphabet : String, size : Int, random : (Int) -> Result[Array[Int], NanoidError]) -> Result[() -> Result[String, NanoidError], NanoidError]`

Creates a generator with custom alphabet and random function.

- `alphabet`: String containing unique characters to use (1-256 characters, no duplicates)
- `size`: Length for generated IDs (must be positive)
- `random`: Custom random byte generator function that returns Result
- Returns: `Ok(generator)` or `Err(NanoidError)` for invalid parameters

## Error Handling

The library uses MoonBit's Result type for proper error handling:

```moonbit
pub enum NanoidError {
  EmptyAlphabet                    // Alphabet cannot be empty
  OversizedAlphabet(Int)           // Alphabet exceeds 256 characters
  DuplicateCharacter(Char, Int, Int) // Duplicate character found at positions
  SizeTooSmall(Int)                // Size must be greater than 0
  SizeTooLarge(Int)                // Size exceeds maximum allowed (1,000,000)
  RandomGenerationError(String)    // Random number generation failed
} derive(Show, Eq)
```

### Error Handling Examples

```moonbit
// Handle errors explicitly
match @nanoid.nanoid(size=-1) {
  Ok(id) => println("Generated: \{id}")
  Err(SizeTooSmall(size)) => println("Invalid size: \{size}")
  Err(e) => println("Other error: \{e.to_string()}")
}

// Detect duplicate characters in alphabet
match @nanoid.custom_alphabet("ABCA", size=5) {
  Err(DuplicateCharacter(char, first, dup)) =>
    println("'\{char}' duplicated at \{dup}, first at \{first}")
  _ => ()
}

// Use convenience functions for backward compatibility
let id = @nanoid.nanoid_or_empty(size=-1)  // Returns "" on error
```

## Predefined Alphabets

Based on [nanoid-dictionary](https://github.com/CyberAP/nanoid-dictionary), we provide several predefined character sets:

### Basic Sets

| Alphabet       | Characters                   | Description         |
| -------------- | ---------------------------- | ------------------- |
| `numbers`      | `0123456789`                 | Numbers only        |
| `lowercase`    | `abcdefghijklmnopqrstuvwxyz` | Lowercase letters   |
| `uppercase`    | `ABCDEFGHIJKLMNOPQRSTUVWXYZ` | Uppercase letters   |
| `alphanumeric` | `A-Za-z0-9` (62 chars)       | Letters and numbers |

### Hexadecimal

| Alphabet    | Characters         | Description           |
| ----------- | ------------------ | --------------------- |
| `hex`       | `0123456789abcdef` | Lowercase hexadecimal |
| `hex_upper` | `0123456789ABCDEF` | Uppercase hexadecimal |

### Special Purpose

| Alphabet            | Characters                       | Description                                                 |
| ------------------- | -------------------------------- | ----------------------------------------------------------- |
| `url_alphabet`      | `A-Za-z0-9_-` (64 chars)         | Default URL-safe alphabet                                   |
| `nolookalikes`      | `346789ABCD...xyz` (49 chars)    | No confusing characters (removes 1,l,I,0,O,o,u,v,5,S,s,2,Z) |
| `nolookalikes_safe` | `6789BCDF...twz` (35 chars)      | No lookalikes + no vowels (safer for public IDs)            |
| `base58`            | `123456789ABCD...xyz` (58 chars) | Bitcoin-style (excludes 0,O,I,l)                            |
| `base62`            | `0-9A-Za-z` (62 chars)           | Standard base62 encoding                                    |
| `url_safe`          | `A-Za-z0-9_-` (64 chars)         | Alias of `url_alphabet`                                     |
| `filename_safe`     | `A-Za-z0-9_-` (64 chars)         | Alias of `url_alphabet`, for filename contexts              |

### Usage Examples

```moonbit
// Use different alphabets for different purposes
let uuid_like = @nanoid.custom_alphabet(@nanoid.hex, size=32)
let readable = @nanoid.custom_alphabet(@nanoid.nolookalikes, size=8)
let safe_public = @nanoid.custom_alphabet(@nanoid.nolookalikes_safe, size=6)
let crypto_style = @nanoid.custom_alphabet(@nanoid.base58, size=16)
```

## Testing

Run the comprehensive test suite:

```bash
moon test --target all
```

The test suite includes:

- Basic functionality and custom alphabet tests
- Error handling and edge case tests (boundaries, Unicode, duplicate detection)
- ChaCha8 RNG quality, reproducibility, distribution, and range tests
- Unicode emoji and CJK character support tests

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original [Nano ID](https://github.com/ai/nanoid) by Andrey Sitnik
- [nanoid-dictionary](https://github.com/CyberAP/nanoid-dictionary) for alphabet definitions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## See Also

- [Official Nano ID](https://github.com/ai/nanoid) - The original JavaScript implementation
- [nanoid-dictionary](https://github.com/CyberAP/nanoid-dictionary) - Predefined character sets
- [MoonBit Documentation](https://moonbitlang.com/docs/) - Learn more about MoonBit
