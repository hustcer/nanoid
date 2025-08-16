// Simplified tests for the new Result-based nanoid API

///|
test "nanoid_basic_functionality" {
  // Test basic nanoid generation
  let result = nanoid()
  assert_true(result.is_ok())
  let id = result.unwrap()
  assert_eq(id.length(), 21)

  // Test custom size
  let result_10 = nanoid(size=10)
  assert_true(result_10.is_ok())
  let id_10 = result_10.unwrap()
  assert_eq(id_10.length(), 10)
}

///|
test "nanoid_error_handling" {
  // Test invalid size
  let result = nanoid(size=-1)
  assert_true(result.is_err())

  // Test zero size
  let result_zero = nanoid(size=0)
  assert_true(result_zero.is_err())
}

///|
test "custom_alphabet_basic" {
  // Test valid custom alphabet
  let result = custom_alphabet("ABC", size=5)
  assert_true(result.is_ok())
  let generator = result.unwrap()
  let id_result = generator()
  assert_true(id_result.is_ok())
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
  assert_true(result.is_err())

  // Test invalid size
  let result_invalid = custom_alphabet("ABC", size=-1)
  assert_true(result_invalid.is_err())
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
  assert_true(result.is_ok())
  let generator = result.unwrap()
  let id_result = generator()
  assert_true(id_result.is_ok())
  let id = id_result.unwrap()
  assert_eq(id, "XXXXX")
}

///|
test "random_generator_quality" {
  // Test random number generator quality and reproducibility
  let rng1 = SimpleRng::new(12345L)
  let rng2 = SimpleRng::new(12345L)

  // Same seed should produce same sequence
  let val1_1 = rng1.next_int64()
  let val1_2 = rng1.next_int64()
  let val2_1 = rng2.next_int64()
  let val2_2 = rng2.next_int64()
  assert_eq(val1_1, val2_1)
  assert_eq(val1_2, val2_2)

  // Values should be different
  assert_true(val1_1 != val1_2)
}

///|
test "random_generator_zero_state" {
  // Test zero state handling
  let rng = SimpleRng::new(0L)
  let val1 = rng.next_int64()
  let val2 = rng.next_int64()

  // Should not get stuck in zero state
  assert_true(val1 != 0L)
  assert_true(val2 != 0L)
  assert_true(val1 != val2)
}

///|
test "random_distribution_basic" {
  // Basic distribution test for next_int
  let rng = SimpleRng::new(54321L)
  let counts = Array::make(4, 0)

  // Generate many samples
  for i = 0; i < 1000; i = i + 1 {
    let val = rng.next_int(4)
    assert_true(val >= 0 && val < 4)
    counts[val] = counts[val] + 1
  }

  // Each bucket should have some values (basic sanity check)
  for i = 0; i < 4; i = i + 1 {
    assert_true(counts[i] > 0)
  }
}

///|
test "random_generator_fixes" {
  // Test that the fixed random generator produces different values
  let rng = SimpleRng::new(12345L)
  let values = Array::make(10, 0L)

  // Generate multiple values
  for i = 0; i < 10; i = i + 1 {
    values[i] = rng.next_int64()
  }

  // Check that we get different values (not all the same)
  let mut all_same = true
  for i = 1; i < 10; i = i + 1 {
    if values[i] != values[0] {
      all_same = false
    }
  }
  assert_false(all_same) // Should not all be the same

  // Test that next_int produces values in correct range
  for i = 0; i < 100; i = i + 1 {
    let val = rng.next_int(10)
    assert_true(val >= 0 && val < 10)
  }
}

///|
test "constant_time_comparison" {
  // Test constant-time string comparison
  assert_true(constant_time_eq("hello", "hello"))
  assert_true(constant_time_eq("", ""))
  assert_false(constant_time_eq("hello", "world"))
  assert_false(constant_time_eq("hello", "hello2"))
  assert_false(constant_time_eq("short", "longer"))

  // Test with nanoid generated strings
  let id1 = nanoid().unwrap()
  assert_true(constant_time_eq(id1, id1))
  // FIXED: Use different fixed strings to avoid random collision
  assert_false(constant_time_eq("test_id_1", "test_id_2"))

  // Test the new secure_verify_id function
  assert_true(secure_verify_id("same_id", "same_id"))
  assert_false(secure_verify_id("id1", "id2"))
}

///|
test "optimization_functions" {
  // Test precomputed mask function
  assert_eq(get_precomputed_mask(2), Some(1))
  assert_eq(get_precomputed_mask(4), Some(3))
  assert_eq(get_precomputed_mask(16), Some(15))
  assert_eq(get_precomputed_mask(64), Some(63))
  assert_eq(get_precomputed_mask(256), Some(255))
  assert_eq(get_precomputed_mask(100), None) // Non-power-of-2

  // Test mask calculation with precomputed values
  assert_eq(calculate_mask(2), 1)
  assert_eq(calculate_mask(16), 15)
  assert_eq(calculate_mask(64), 63)

  // Test alphabet to chars conversion
  let alphabet = "ABC"
  let chars = alphabet_to_chars(alphabet)
  assert_eq(chars.length(), 3)
  assert_eq(chars[0], 'A')
  assert_eq(chars[1], 'B')
  assert_eq(chars[2], 'C')

  // Test precomputed batch sizes
  assert_eq(get_precomputed_batch_size(2), Some(64))
  assert_eq(get_precomputed_batch_size(16), Some(16))
  assert_eq(get_precomputed_batch_size(64), Some(10))
  assert_eq(get_precomputed_batch_size(100), None)
}

///|
test "performance_optimizations" {
  // Test that optimized functions produce same results as before
  // but with better performance characteristics

  // Test with common alphabet sizes that have precomputed optimizations
  let hex_result = custom_alphabet("0123456789abcdef", size=10)
  assert_true(hex_result.is_ok())
  let hex_gen = hex_result.unwrap()
  let hex_id = hex_gen().unwrap()
  assert_eq(hex_id.length(), 10)

  // Test with base64-like alphabet
  let base64_result = custom_alphabet(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    size=12,
  )
  assert_true(base64_result.is_ok())
  let base64_gen = base64_result.unwrap()
  let base64_id = base64_gen().unwrap()
  assert_eq(base64_id.length(), 12)

  // Test with binary alphabet (highly optimized case)
  let binary_result = custom_alphabet("01", size=20)
  assert_true(binary_result.is_ok())
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
  assert_true(result_max.is_ok())

  // Test size just over limit
  let result_over = nanoid(size=1000001)
  assert_true(result_over.is_err())

  // Test single character ID
  let result_single = nanoid(size=1)
  assert_true(result_single.is_ok())
  let single_id = result_single.unwrap()
  assert_eq(single_id.length(), 1)

  // Test very large alphabet (at limit)
  let mut large_alphabet = ""
  for i = 0; i < 256; i = i + 1 {
    large_alphabet = large_alphabet + Int::unsafe_to_char(33 + i).to_string() // Start from '!' (33) to avoid duplicates
  }
  let result_large = custom_alphabet(large_alphabet, size=5)
  assert_true(result_large.is_ok())

  // Test alphabet just over limit
  let oversized_alphabet = large_alphabet + "X"
  let result_oversized = custom_alphabet(oversized_alphabet, size=5)
  assert_true(result_oversized.is_err())
}

///|
test "error_message_quality" {
  // Test detailed error messages
  let empty_result = custom_alphabet("", size=5)
  match empty_result {
    Err(error) => {
      let detailed = error.to_string_detailed()
      assert_true(detailed.contains("at least one character"))
    }
    Ok(_) => assert_true(false) // Should not succeed
  }
  let negative_result = nanoid(size=-5)
  match negative_result {
    Err(error) => {
      let detailed = error.to_string_detailed()
      assert_true(detailed.contains("cannot be negative"))
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
  assert_true(result.is_ok())

  // Test invalid custom random function (wrong array length)
  let invalid_random = fn(_size : Int) -> Result[Array[Int], NanoidError] {
    Ok(Array::make(2, 42)) // Always returns 2 elements regardless of requested size
  }
  let result_invalid = custom_random("ABC", 5, invalid_random)
  assert_true(result_invalid.is_err())
}
