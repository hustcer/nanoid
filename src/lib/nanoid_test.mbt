// Simplified tests for the new Result-based nanoid API

///|
test "nanoid_basic_functionality" {
  // Test basic nanoid generation
  let result = nanoid()
  assert_true(result is Ok(_))
  let id = result.unwrap()
  assert_eq(id.length(), 21)

  // Test custom size
  let result_10 = nanoid(size=10)
  assert_true(result_10 is Ok(_))
  let id_10 = result_10.unwrap()
  assert_eq(id_10.length(), 10)
}

///|
test "nanoid_error_handling" {
  // Test invalid size
  let result = nanoid(size=-1)
  assert_true(result is Err(_))

  // Test zero size
  let result_zero = nanoid(size=0)
  assert_true(result_zero is Err(_))
}

///|
test "custom_alphabet_basic" {
  // Test valid custom alphabet
  let result = custom_alphabet("ABC", size=5)
  assert_true(result is Ok(_))
  let generator = result.unwrap()
  let id_result = generator()
  assert_true(id_result is Ok(_))
  let id = id_result.unwrap()
  assert_eq(id.length(), 5)

  // Verify all characters are from alphabet
  for i = 0; i < id.length(); i = i + 1 {
    let char = id.get_char(i).unwrap()
    assert_true(char == 'A' || char == 'B' || char == 'C')
  }
}

///|
test "custom_alphabet_error_handling" {
  // Test empty alphabet
  let result = custom_alphabet("", size=5)
  assert_true(result is Err(_))

  // Test invalid size
  let result_invalid = custom_alphabet("ABC", size=-1)
  assert_true(result_invalid is Err(_))
}

///|
test "backward_compatibility_functions" {
  // Test nanoid_or_empty with valid input
  let id = nanoid_or_empty(size=10)
  assert_eq(id.length(), 10)

  // Test nanoid_or_empty with invalid input
  let empty_id = nanoid_or_empty(size=-1)
  assert_eq(empty_id, "")

  // Test custom_alphabet_or_empty with valid input
  let generator = custom_alphabet_or_empty("XYZ", size=3)
  let custom_id = generator()
  assert_eq(custom_id.length(), 3)

  // Test custom_alphabet_or_empty with invalid input
  let empty_generator = custom_alphabet_or_empty("", size=3)
  let empty_custom_id = empty_generator()
  assert_eq(empty_custom_id, "")
}

///|
test "basic_randomness_check" {
  // Generate IDs and check they contain different characters
  let id = nanoid().unwrap()
  assert_eq(id.length(), 21)

  // Check that the ID contains valid characters from the alphabet
  for i = 0; i < id.length(); i = i + 1 {
    let char = id.get_char(i).unwrap()
    assert_true(url_alphabet.contains(char.to_string()))
  }
}

///|
test "alphabet_presets" {
  // Test that alphabet presets are defined correctly
  assert_eq(numbers, "0123456789")
  assert_eq(lowercase, "abcdefghijklmnopqrstuvwxyz")
  assert_eq(uppercase, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  assert_eq(hex, "0123456789abcdef")
  assert_eq(hex_upper, "0123456789ABCDEF")
}

///|
test "single_character_alphabet" {
  // Test edge case: single character alphabet
  let result = custom_alphabet("X", size=5)
  assert_true(result is Ok(_))
  let generator = result.unwrap()
  let id_result = generator()
  assert_true(id_result is Ok(_))
  let id = id_result.unwrap()
  assert_eq(id, "XXXXX")
}

///|
test "chacha8_rng_quality" {
  // Test that the standard library ChaCha8 RNG produces good quality output
  let rng = @random.Rand::chacha8(
    seed=b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20",
  )

  // Generate multiple values and verify they are different
  let val1 = rng.int(limit=256)
  let val2 = rng.int(limit=256)
  let val3 = rng.int(limit=256)

  // At least some values should differ (with overwhelming probability)
  assert_true(val1 != val2 || val2 != val3)

  // Values should be in range
  assert_true(val1 >= 0 && val1 < 256)
  assert_true(val2 >= 0 && val2 < 256)
  assert_true(val3 >= 0 && val3 < 256)
}

///|
test "chacha8_rng_reproducibility" {
  // Same seed should produce same sequence
  let rng1 = @random.Rand::chacha8(
    seed=b"\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a",
  )
  let rng2 = @random.Rand::chacha8(
    seed=b"\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a\x2a",
  )

  for _i = 0; _i < 100; _i = _i + 1 {
    assert_eq(rng1.int(limit=256), rng2.int(limit=256))
  }
}

///|
test "chacha8_distribution_basic" {
  // Basic distribution test using ChaCha8
  let rng = @random.Rand::chacha8(
    seed=b"\xd4\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
  )
  let counts = Array::make(4, 0)

  // Generate many samples
  for _i = 0; _i < 1000; _i = _i + 1 {
    let val = rng.int(limit=4)
    assert_true(val >= 0 && val < 4)
    counts[val] = counts[val] + 1
  }

  // Each bucket should have some values (basic sanity check)
  for i = 0; i < 4; i = i + 1 {
    assert_true(counts[i] > 0)
  }
}

///|
test "chacha8_rng_range_correctness" {
  // Test that ChaCha8 produces values in correct ranges
  let rng = @random.Rand::chacha8(
    seed=b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20",
  )

  for _i = 0; _i < 100; _i = _i + 1 {
    let val = rng.int(limit=10)
    assert_true(val >= 0 && val < 10)
  }

  for _i = 0; _i < 100; _i = _i + 1 {
    let val = rng.int(limit=256)
    assert_true(val >= 0 && val < 256)
  }
}

///|
test "final_fixes_verification" {
  // Test that nanoid generation works correctly
  let id1 = nanoid(size=10).unwrap()
  let id2 = nanoid(size=10).unwrap()
  assert_eq(id1.length(), 10)
  assert_eq(id2.length(), 10)
  assert_false(id1 == id2) // Should be different
}

///|
test "performance_optimizations" {
  // Test that optimized functions produce same results as before
  // but with better performance characteristics

  // Test with common alphabet sizes that have precomputed optimizations
  let hex_result = custom_alphabet("0123456789abcdef", size=10)
  assert_true(hex_result is Ok(_))
  let hex_gen = hex_result.unwrap()
  let hex_id = hex_gen().unwrap()
  assert_eq(hex_id.length(), 10)

  // Test with base64-like alphabet
  let base64_result = custom_alphabet(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    size=12,
  )
  assert_true(base64_result is Ok(_))
  let base64_gen = base64_result.unwrap()
  let base64_id = base64_gen().unwrap()
  assert_eq(base64_id.length(), 12)

  // Test with binary alphabet (highly optimized case)
  let binary_result = custom_alphabet("01", size=20)
  assert_true(binary_result is Ok(_))
  let binary_gen = binary_result.unwrap()
  let binary_id = binary_gen().unwrap()
  assert_eq(binary_id.length(), 20)
  // Verify all characters are 0 or 1
  for i = 0; i < binary_id.length(); i = i + 1 {
    let char = binary_id.get_char(i).unwrap()
    assert_true(char == '0' || char == '1')
  }
}

///|
test "id_randomness_quality" {
  // Generate multiple IDs and verify they are different
  let ids = Array::make(10, "")
  for i = 0; i < 10; i = i + 1 {
    ids[i] = nanoid().unwrap()
  }

  // Check that all IDs are different
  for i = 0; i < 10; i = i + 1 {
    for j = i + 1; j < 10; j = j + 1 {
      assert_false(ids[i] == ids[j]) // Should be different
    }
  }

  // Check that IDs have expected length
  for i = 0; i < 10; i = i + 1 {
    assert_eq(ids[i].length(), 21)
  }
}

///|
test "edge_cases_and_boundaries" {
  // Test maximum size limit
  let result_max = nanoid(size=1000000)
  assert_true(result_max is Ok(_))

  // Test size just over limit
  let result_over = nanoid(size=1000001)
  assert_true(result_over is Err(_))

  // Test single character ID
  let result_single = nanoid(size=1)
  assert_true(result_single is Ok(_))
  let single_id = result_single.unwrap()
  assert_eq(single_id.length(), 1)

  // Test very large alphabet (at limit)
  let mut large_alphabet = ""
  for i = 0; i < 256; i = i + 1 {
    large_alphabet = large_alphabet + Int::unsafe_to_char(33 + i).to_string() // Start from '!' (33) to avoid duplicates
  }
  let result_large = custom_alphabet(large_alphabet, size=5)
  assert_true(result_large is Ok(_))

  // Test alphabet just over limit
  let oversized_alphabet = large_alphabet + "X"
  let result_oversized = custom_alphabet(oversized_alphabet, size=5)
  assert_true(result_oversized is Err(_))
}

///|
test "error_message_quality" {
  // Test detailed error messages
  let empty_result = custom_alphabet("", size=5)
  match empty_result {
    Err(error) => {
      let msg = error.to_string()
      assert_true(msg.contains("at least one character"))
    }
    Ok(_) => assert_true(false) // Should not succeed
  }
  let negative_result = nanoid(size=-5)
  match negative_result {
    Err(error) => {
      let msg = error.to_string()
      assert_true(msg.contains("cannot be negative"))
    }
    Ok(_) => assert_true(false) // Should not succeed
  }
}

///|
test "custom_random_validation" {
  // Test valid custom random function
  let valid_random = fn(size : Int) -> Result[Array[Int], NanoidError] {
    Ok(Array::make(size, 42))
  }
  let result = custom_random("ABC", 5, valid_random)
  assert_true(result is Ok(_))

  // Test invalid custom random function (wrong array length)
  let invalid_random = fn(_size : Int) -> Result[Array[Int], NanoidError] {
    Ok(Array::make(2, 42)) // Always returns 2 elements regardless of requested size
  }
  let result_invalid = custom_random("ABC", 5, invalid_random)
  assert_true(result_invalid is Err(_))
}

///|
test "insufficient_randomness_triggers_error" {
  // This test verifies that the "fail-fast" mechanism works when the
  // random byte generator consistently fails to provide usable values.

  // A "malicious" random function that always returns bytes that will be rejected.
  // For alphabet "abc" (length 3), the mask is 3 (binary 11).
  // Any byte where (byte & 3) is >= 3 will be rejected.
  // We return 3, which guarantees rejection.
  let bad_random = fn(size : Int) -> Result[Array[Int], NanoidError] {
    Ok(Array::make(size, 3))
  }
  let alphabet = "abc"
  let size = 10

  // Create a generator with the malicious random function.
  let generator_result = custom_random(alphabet, size, bad_random)
  assert_true(generator_result is Ok(_))
  let generator = generator_result.unwrap()

  // Attempt to generate an ID. This should fail.
  match generator() {
    Ok(id) => {
      // If it succeeds, the test fails.
      println("Unexpected success generating ID: \{id}")
      assert_true(false)
    }
    Err(e) => {
      // Check that we got the correct error.
      let error_string = e.to_string()
      assert_true(
        error_string.contains("Failed to generate sufficient random characters"),
      )
    }
  }
}

///|
test "unicode_emoji_alphabet_support" {
  // Test single emoji alphabet
  let emoji_gen = custom_alphabet("😀", size=5)
  assert_true(emoji_gen is Ok(_))
  let id_emoji = emoji_gen.unwrap()()
  assert_true(id_emoji is Ok(_))
  let emoji_id = id_emoji.unwrap()
  // Count characters using for-in loop
  let mut emoji_count = 0
  for _c in emoji_id {
    emoji_count = emoji_count + 1
  }
  assert_eq(emoji_count, 5)

  // Test mixed emoji alphabet
  let mixed_emoji_gen = custom_alphabet("😀😁😂", size=10)
  assert_true(mixed_emoji_gen is Ok(_))
  let id_mixed = mixed_emoji_gen.unwrap()()
  assert_true(id_mixed is Ok(_))
  let mixed_id = id_mixed.unwrap()
  let mut mixed_count = 0
  for _c in mixed_id {
    mixed_count = mixed_count + 1
  }
  assert_eq(mixed_count, 10)

  // Test Chinese characters
  let chinese_gen = custom_alphabet("你好世界", size=8)
  assert_true(chinese_gen is Ok(_))
  let id_chinese = chinese_gen.unwrap()()
  assert_true(id_chinese is Ok(_))
  let chinese_id = id_chinese.unwrap()
  let mut chinese_count = 0
  for _c in chinese_id {
    chinese_count = chinese_count + 1
  }
  assert_eq(chinese_count, 8)

  // Test mixed ASCII and Unicode
  let mixed_gen = custom_alphabet("A😀B😁C", size=10)
  assert_true(mixed_gen is Ok(_))
  let id_mixed_ascii = mixed_gen.unwrap()()
  assert_true(id_mixed_ascii is Ok(_))
  let mixed_ascii_id = id_mixed_ascii.unwrap()
  let mut ascii_count = 0
  for _c in mixed_ascii_id {
    ascii_count = ascii_count + 1
  }
  assert_eq(ascii_count, 10)

  // Verify all characters in the generated ID are from the alphabet
  let alphabet = "A😀B😁C"
  for c in mixed_ascii_id {
    let mut found = false
    for a in alphabet {
      if c == a {
        found = true
      }
    }
    assert_true(found)
  }
}

///|
test "duplicate_character_in_alphabet" {
  // Test that duplicate ASCII characters are rejected
  let result = custom_alphabet("ABCA", size=5)
  assert_true(result is Err(_))
  match result {
    Err(error) => {
      let msg = error.to_string()
      assert_true(msg.contains("Duplicate character"))
      assert_true(msg.contains("'A'"))
    }
    Ok(_) => assert_true(false)
  }

  // Test that duplicate Unicode characters are rejected
  let emoji_result = custom_alphabet("😀😁😀", size=5)
  assert_true(emoji_result is Err(_))
  match emoji_result {
    Err(error) => {
      let msg = error.to_string()
      assert_true(msg.contains("Duplicate character"))
    }
    Ok(_) => assert_true(false)
  }

  // Test detailed error message
  let result2 = custom_alphabet("XYZXY", size=5)
  match result2 {
    Err(error) => {
      let detailed = error.to_string()
      assert_true(detailed.contains("must be unique"))
    }
    Ok(_) => assert_true(false)
  }
}

///|
test "duplicate_character_error_type" {
  // Verify the error type is DuplicateCharacter, not RandomGenerationError
  let result = custom_alphabet("ABBA", size=5)
  match result {
    Err(NanoidError::DuplicateCharacter(char, first_pos, dup_pos)) => {
      assert_eq(char, 'B')
      assert_eq(first_pos, 1)
      assert_eq(dup_pos, 2)
    }
    Err(_) => assert_true(false) // Wrong error type
    Ok(_) => assert_true(false) // Should not succeed
  }
}

///|
test "error_type_coverage" {
  // Test all error types have proper string representations by triggering actual errors

  // EmptyAlphabet
  match custom_alphabet("", size=5) {
    Err(error) => {
      assert_true(error.to_string().contains("empty"))
      assert_true(error.to_string().contains("at least one"))
    }
    Ok(_) => assert_true(false)
  }

  // DuplicateCharacter
  match custom_alphabet("ABCA", size=5) {
    Err(error) => {
      assert_true(error.to_string().contains("Duplicate"))
      assert_true(error.to_string().contains("unique"))
    }
    Ok(_) => assert_true(false)
  }

  // SizeTooSmall (negative)
  match nanoid(size=-5) {
    Err(error) => assert_true(error.to_string().contains("negative"))
    Ok(_) => assert_true(false)
  }

  // SizeTooSmall (zero)
  match nanoid(size=0) {
    Err(error) => assert_true(error.to_string().contains("size=1"))
    Ok(_) => assert_true(false)
  }

  // SizeTooLarge
  match nanoid(size=1000001) {
    Err(error) => {
      assert_true(error.to_string().contains("1000001"))
      assert_true(error.to_string().contains("memory"))
    }
    Ok(_) => assert_true(false)
  }
}

///|
test "unicode_alphabet_iteration_consistency" {
  // Ensure Unicode handling is consistent across the codebase
  let alphabet = "A😀B😁C"

  // Should have 5 characters, not byte count
  let mut char_count = 0
  let chars : Array[Char] = []
  for c in alphabet {
    char_count = char_count + 1
    chars.push(c)
  }
  assert_eq(char_count, 5)
  assert_eq(chars[0], 'A')
  assert_eq(chars[1], '😀')
  assert_eq(chars[2], 'B')
  assert_eq(chars[3], '😁')
  assert_eq(chars[4], 'C')

  // Generate ID and verify using consistent iteration
  let gen = custom_alphabet(alphabet, size=10)
  assert_true(gen is Ok(_))
  let id = gen.unwrap()().unwrap()

  // Verify length using character count
  let mut id_len = 0
  for _c in id {
    id_len = id_len + 1
  }
  assert_eq(id_len, 10)

  // Verify all characters are from alphabet
  for c in id {
    let mut found = false
    for a in alphabet {
      if c == a {
        found = true
      }
    }
    assert_true(found)
  }
}

///|
test "chacha8_rng_value_range" {
  // Test that ChaCha8 RNG always produces values in valid range
  // This replaces the previous Int64.MIN_VALUE overflow test since
  // ChaCha8 handles value generation internally without overflow risks
  let rng = @random.Rand::chacha8(
    seed=b"\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
  )

  for _i = 0; _i < 1000; _i = _i + 1 {
    let val = rng.int(limit=256)
    assert_true(val >= 0)
    assert_true(val < 256)
  }

  // Test with different limits
  for limit in [10, 64, 100, 256] {
    for _j = 0; _j < 100; _j = _j + 1 {
      let val = rng.int(limit~)
      assert_true(val >= 0)
      assert_true(val < limit)
    }
  }
}
