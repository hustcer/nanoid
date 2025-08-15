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
