// MoonBit nanoid library tests
// Tests for all public functions and edge cases

// Test basic nanoid generation with default parameters
test "nanoid_default_generation" {
  let id = nanoid()
  assert_eq(id.length(), 21) // Default size should be 21

  // Check that generated ID contains only URL-safe characters
  for i = 0; i < id.length(); i = i + 1 {
    let char = id.char_at(i)
    assert_true(url_alphabet.contains(char.to_string()))
  }
}

// Test nanoid generation with custom size
test "nanoid_custom_size" {
  let id_10 = nanoid(size=10)
  assert_eq(id_10.length(), 10)

  let id_50 = nanoid(size=50)
  assert_eq(id_50.length(), 50)

  let id_1 = nanoid(size=1)
  assert_eq(id_1.length(), 1)
}

// Test that generated IDs are unique (probabilistically)
test "nanoid_uniqueness" {
  let id1 = nanoid()
  let id2 = nanoid()
  let id3 = nanoid()

  assert_not_eq(id1, id2)
  assert_not_eq(id2, id3)
  assert_not_eq(id1, id3)
}

// Test custom alphabet functionality
test "custom_alphabet_basic" {
  let simple_alphabet = "ABC"
  let generator = custom_alphabet(simple_alphabet, size=10)
  let id = generator()

  assert_eq(id.length(), 10)

  // Check that all characters are from the custom alphabet
  for i = 0; i < id.length(); i = i + 1 {
    let char = id.char_at(i)
    assert_true(simple_alphabet.contains(char.to_string()))
  }
}

// Test custom alphabet with default size
test "custom_alphabet_default_size" {
  let binary_alphabet = "01"
  let generator = custom_alphabet(binary_alphabet)
  let id = generator()

  assert_eq(id.length(), 21) // Should use DEFAULT_SIZE

  // Check binary characters only
  for i = 0; i < id.length(); i = i + 1 {
    let char = id.char_at(i)
    assert_true(char == '0' || char == '1')
  }
}

// Test custom alphabet with numbers preset
test "custom_alphabet_numbers" {
  let generator = custom_alphabet(numbers, size=15)
  let id = generator()

  assert_eq(id.length(), 15)

  for i = 0; i < id.length(); i = i + 1 {
    let char = id.char_at(i)
    assert_true(numbers.contains(char.to_string()))
  }
}

// Test custom random function
test "custom_random_deterministic" {
  let test_alphabet = "ABC"

  // Create a deterministic random function that always returns the same pattern
  fn deterministic_random(size : Int) -> Array[Int] {
    let bytes = Array::make(size, 0)
    for i = 0; i < size; i = i + 1 {
      bytes[i] = i % 3  // Will cycle through 0, 1, 2
    }
    bytes
  }

  let generator = custom_random(test_alphabet, 6, deterministic_random)
  let id1 = generator()
  let id2 = generator()

  assert_eq(id1.length(), 6)
  assert_eq(id2.length(), 6)
  assert_eq(id1, id2) // Should be identical with deterministic random
}

// Test alphabet presets
test "alphabet_presets" {
  assert_eq(numbers, "0123456789")
  assert_eq(lowercase, "abcdefghijklmnopqrstuvwxyz")
  assert_eq(uppercase, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  assert_eq(alphanumeric, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
  assert_eq(hex, "0123456789abcdef")
  assert_eq(hex_upper, "0123456789ABCDEF")
  assert_eq(url_alphabet, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-")
}

// Test using preset alphabets
test "preset_alphabets_usage" {
  let hex_generator = custom_alphabet(hex, size=8)
  let hex_id = hex_generator()

  assert_eq(hex_id.length(), 8)

  for i = 0; i < hex_id.length(); i = i + 1 {
    let char = hex_id.char_at(i)
    assert_true(hex.contains(char.to_string()))
  }
}

// Test edge case: single character alphabet
test "single_character_alphabet" {
  let single_char_generator = custom_alphabet("X", size=5)
  let id = single_char_generator()

  assert_eq(id, "XXXXX")
}

// Test edge case: size of 1
test "size_one" {
  let id = nanoid(size=1)
  assert_eq(id.length(), 1)
  assert_true(url_alphabet.contains(id))
}

// Test large size
test "large_size" {
  let large_id = nanoid(size=1000)
  assert_eq(large_id.length(), 1000)

  // Verify all characters are valid
  for i = 0; i < large_id.length(); i = i + 1 {
    let char = large_id.char_at(i)
    assert_true(url_alphabet.contains(char.to_string()))
  }
}

// Test very long alphabet (close to 256 limit)
test "long_alphabet" {
  let mut long_alphabet = ""
  for i = 0; i < 200; i = i + 1 {
    long_alphabet = long_alphabet + i.to_string()
  }

  let generator = custom_alphabet(long_alphabet, size=10)
  let id = generator()
  assert_eq(id.length(), 10)
}

// Test distribution is reasonable (not perfect randomness test, but basic check)
test "basic_distribution_check" {
  let binary_generator = custom_alphabet("01", size=1000)
  let id = binary_generator()

  let mut zero_count = 0
  let mut one_count = 0

  for i = 0; i < id.length(); i = i + 1 {
    if id.char_at(i) == '0' {
      zero_count = zero_count + 1
    } else {
      one_count = one_count + 1
    }
  }

  // For 1000 characters, both should be reasonably represented
  // Allow for some variance in random distribution
  assert_true(zero_count > 300)
  assert_true(one_count > 300)
  assert_eq(zero_count + one_count, 1000)
}
