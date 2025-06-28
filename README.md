# MoonBit Nanoid

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A tiny, secure, URL-friendly, unique string ID generator for [MoonBit](https://moonbitlang.com/).

This is a MoonBit port of the popular [Nano ID](https://github.com/ai/nanoid) JavaScript library, maintaining API compatibility while providing excellent error handling through MoonBit's robust type system.

## Features

- **Small & Fast**: Minimal overhead, optimized for performance
- **Secure**: Uses cryptographically strong random number generation
- **URL-Safe**: Generated IDs are safe for use in URLs, filenames, and databases
- **Customizable**: Support for custom alphabets and ID sizes
- **Error Safe**: Proper error handling instead of runtime panics
- **Type Safe**: Full MoonBit type system support
- **Zero Dependencies**: No external dependencies beyond MoonBit core

## Quick Start

### Basic Usage

```moonbit
import @lib

// Generate a URL-safe ID with default length (21 characters)
let id = @lib.nanoid()
// => "rMf19KHCD5GQw0wzQnEKd"

// Generate an ID with custom length
let short_id = @lib.nanoid(size=10)
// => "yue8fl8f9X"
```

### Custom Alphabets

```moonbit
import @lib

// Create a generator with custom alphabet
let hex_generator = @lib.custom_alphabet(@lib.hex, size=8)
let hex_id = hex_generator()
// => "a1b2c3d4"

// Use predefined alphabet sets
let safe_generator = @lib.custom_alphabet(@lib.nolookalikes, size=12)
let safe_id = safe_generator()
// => "6B9CMnpqrt7w"
```

### Error Handling

```moonbit
import @lib

// Handle potential errors gracefully
try {
  let id = @lib.nanoid(size=10)
  println("Generated: \{id}")
} catch {
  @lib.NanoidError(msg) => println("Error: \{msg}")
}
```

## API Reference

### Core Functions

#### `nanoid(size~ : Int = 21) -> String raise NanoidError`

Generates a URL-safe unique ID using the default alphabet.

- `size`: Length of the generated ID (default: 21)
- Returns: A random string ID
- Raises: `NanoidError` if size is invalid

```moonbit
let id1 = @lib.nanoid()          // 21 characters
let id2 = @lib.nanoid(size=10)   // 10 characters
```

#### `custom_alphabet(alphabet : String, size~ : Int = 21) -> (() -> String raise NanoidError) raise NanoidError`

Creates a generator function with a custom alphabet.

- `alphabet`: String containing characters to use
- `size`: Default length for generated IDs
- Returns: A generator function
- Raises: `NanoidError` if alphabet is invalid

```moonbit
let generator = @lib.custom_alphabet("0123456789", size=8)
let numeric_id = generator()  // => "12345678"
```

#### `custom_random(alphabet : String, size : Int, random : (Int) -> Array[Int]) -> (() -> String raise NanoidError) raise NanoidError`

Creates a generator with custom alphabet and random function.

- `alphabet`: String containing characters to use
- `size`: Length for generated IDs
- `random`: Custom random byte generator function
- Returns: A generator function
- Raises: `NanoidError` if parameters are invalid

## Predefined Alphabets

Based on [nanoid-dictionary](https://github.com/CyberAP/nanoid-dictionary), we provide several predefined character sets:

### Basic Sets

| Alphabet | Characters | Description |
|----------|------------|-------------|
| `numbers` | `0123456789` | Numbers only |
| `lowercase` | `abcdefghijklmnopqrstuvwxyz` | Lowercase letters |
| `uppercase` | `ABCDEFGHIJKLMNOPQRSTUVWXYZ` | Uppercase letters |
| `alphanumeric` | `A-Za-z0-9` (62 chars) | Letters and numbers |

### Hexadecimal

| Alphabet | Characters | Description |
|----------|------------|-------------|
| `hex` | `0123456789abcdef` | Lowercase hexadecimal |
| `hex_upper` | `0123456789ABCDEF` | Uppercase hexadecimal |

### Special Purpose

| Alphabet | Characters | Description |
|----------|------------|-------------|
| `url_alphabet` | `A-Za-z0-9_-` (64 chars) | Default URL-safe alphabet |
| `nolookalikes` | `346789ABCD...xyz` (49 chars) | No confusing characters (removes 1,l,I,0,O,o,u,v,5,S,s,2,Z) |
| `nolookalikes_safe` | `6789BCDF...twz` (35 chars) | No lookalikes + no vowels (safer for public IDs) |
| `base58` | `123456789ABCD...xyz` (58 chars) | Bitcoin-style (excludes 0,O,I,l) |
| `base62` | `0-9A-Za-z` (62 chars) | Standard base62 encoding |
| `url_safe` | `A-Za-z0-9_-` (64 chars) | URL-safe characters |
| `filename_safe` | `A-Za-z0-9_-` (64 chars) | Cross-platform filename safe |

### Usage Examples

```moonbit
import @lib

// Use different alphabets for different purposes
let uuid_like = @lib.custom_alphabet(@lib.hex, size=32)
let readable = @lib.custom_alphabet(@lib.nolookalikes, size=8)
let safe_public = @lib.custom_alphabet(@lib.nolookalikes_safe, size=6)
let crypto_style = @lib.custom_alphabet(@lib.base58, size=16)
```

## Installation

Add this package to your MoonBit project:

```json
{
  "deps": {
    "nanoid": "path/to/nanoid"
  }
}
```

## Error Handling

All functions that can fail return `NanoidError` instead of panicking:

```moonbit
// Invalid size
try {
  let bad_id = @lib.nanoid(size=-1)
} catch {
  @lib.NanoidError(msg) => println("Caught: \{msg}")
}

// Empty alphabet
try {
  let bad_generator = @lib.custom_alphabet("")
} catch {
  @lib.NanoidError(msg) => println("Caught: \{msg}")
}

// Alphabet too long (>256 chars)
try {
  let huge_alphabet = "..." // 300+ characters
  let bad_generator = @lib.custom_alphabet(huge_alphabet)
} catch {
  @lib.NanoidError(msg) => println("Caught: \{msg}")
}
```

## Security

- Uses cryptographically secure random number generation
- Implements uniform distribution to avoid modulo bias
- All algorithms are well-documented and tested
- No predictable patterns in generated IDs

## Performance

Nanoid is designed for high performance:

- Minimal memory allocations
- Efficient bit masking for uniform distribution
- Optimized loop structures
- No external dependencies

## Testing

Run the comprehensive test suite:

```bash
moon test --target all
```

The test suite includes:
- Basic functionality tests
- Custom alphabet tests
- Error handling tests
- Edge case tests
- Distribution quality tests
- All predefined alphabet tests

## Comparison with UUID

| Aspect | Nanoid | UUID v4 |
|--------|--------|---------|
| Size | 21 chars | 36 chars |
| Alphabet | 64 chars (`A-Za-z0-9_-`) | 16 chars (`0-9a-f`) |
| Random bits | 126 | 122 |
| URL-safe | ✅ | ❌ (needs encoding) |
| Collision probability | ~1 in billion for 103 trillion IDs | Similar |

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original [Nano ID](https://github.com/ai/nanoid) by Andrey Sitnik
- [nanoid-dictionary](https://github.com/CyberAP/nanoid-dictionary) for alphabet definitions
- MoonBit team for the excellent language and toolchain

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## See Also

- [Official Nano ID](https://github.com/ai/nanoid) - The original JavaScript implementation
- [nanoid-dictionary](https://github.com/CyberAP/nanoid-dictionary) - Predefined character sets
- [MoonBit Documentation](https://moonbitlang.com/docs/) - Learn more about MoonBit
