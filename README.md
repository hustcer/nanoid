# MoonBit Nanoid

**WARN**: Due to [this issue](https://github.com/moonbitlang/core/issues/1616) the library may not work as expected, **DO NOT** use it.

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
let id = @nanoid.nanoid()
println(id) // => "rMf19KHCD5GQw0wzQnEKd"

// Generate an ID with custom length
let short_id = @nanoid.nanoid(size=10)
println(short_id) // => "yue8fl8f9X"
```

### Custom Alphabets

```moonbit
// Create a generator with custom alphabet
let hex_generator = @nanoid.custom_alphabet(@nanoid.hex, size=8)
let hex_id = hex_generator()
println(hex_id) // => "a1b2c3d4"

// Use predefined alphabet sets
let safe_generator = @nanoid.custom_alphabet(@nanoid.nolookalikes, size=12)
let safe_id = safe_generator()
println(safe_id) // => "6B9CMnpqrt7w"
```

## API Reference

### Core Functions

#### `nanoid(size~ : Int = 21) -> String`

Generates a URL-safe unique ID using the default alphabet.

- `size`: Length of the generated ID (default: 21, non-positive values return empty string with warning)
- Returns: A random string ID, or empty string if size is invalid

```moonbit
let id1 = @nanoid.nanoid()          // 21 characters
let id2 = @nanoid.nanoid(size=10)   // 10 characters
let id3 = @nanoid.nanoid(size=0)    // "" with warning
```

#### `custom_alphabet(alphabet : String, size~ : Int = 21) -> (() -> String)`

Creates a generator function with a custom alphabet.

- `alphabet`: String containing characters to use (empty string or >256 chars returns empty string with warning)
- `size`: Default length for generated IDs (non-positive values return empty string with warning)
- Returns: A generator function

```moonbit
let generator = @nanoid.custom_alphabet("0123456789", size=8)
let numeric_id = generator()  // => "12345678"
let bad_gen = @nanoid.custom_alphabet("", size=8)
let empty_id = bad_gen()      // "" with warning
```

#### `custom_random(alphabet : String, size : Int, random : (Int) -> Array[Int]) -> (() -> String)`

Creates a generator with custom alphabet and random function.

- `alphabet`: String containing characters to use (empty string or >256 chars returns empty string with warning)
- `size`: Length for generated IDs (non-positive values return empty string with warning)
- `random`: Custom random byte generator function
- Returns: A generator function

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
| `url_safe`          | `A-Za-z0-9_-` (64 chars)         | URL-safe characters                                         |
| `filename_safe`     | `A-Za-z0-9_-` (64 chars)         | Cross-platform filename safe                                |

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

- Basic functionality tests
- Custom alphabet tests
- Error handling tests
- Edge case tests
- Distribution quality tests
- All predefined alphabet tests

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
