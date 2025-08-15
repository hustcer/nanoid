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
test "constant_time_comparison" {
  // Test constant-time string comparison
  assert_true(constant_time_eq("hello", "hello"))
  assert_true(constant_time_eq("", ""))
  assert_false(constant_time_eq("hello", "world"))
  assert_false(constant_time_eq("hello", "hello2"))
  assert_false(constant_time_eq("short", "longer"))

  // Test with nanoid generated strings
  let id1 = nanoid().unwrap()
  let id2 = nanoid().unwrap()
  assert_true(constant_time_eq(id1, id1))
  assert_false(constant_time_eq(id1, id2))
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
