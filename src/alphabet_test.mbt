///|
test "every_supported_alphabet_size_preserves_unicode_sampling" {
  // Exercise every mask boundary and batches that cross a 256-byte cycle.
  for length in 1..<=256 {
    let chars = Array::makei(length, i => (0x1F300 + i).unsafe_to_char())
    let alphabet = String::from_array(chars)
    let next : Ref[Int] = { val: 0, }
    let random = fn(size : Int) -> Result[Array[Int], @nanoid.NanoidError] {
      Ok(
        Array::makei(size, _ => {
          let byte = next.val & 255
          next.val += 1
          byte
        }),
      )
    }
    let generate = @nanoid.custom_random(alphabet, 257, random).unwrap()
    let id = generate().unwrap()
    let actual = id.to_array()
    assert_eq(actual.length(), 257)
    for i, char in actual {
      assert_eq(char, chars[i % length])
    }
  }
}

///|
test "unicode_validation_preserves_error_positions_and_precedence" {
  match @nanoid.custom_alphabet("A😀B😁😀", size=5) {
    Err(error) => assert_eq(error, @nanoid.DuplicateCharacter('😀', 1, 4))
    Ok(_) => fail("expected duplicate emoji")
  }
  let chars = Array::makei(257, i => (0x1F300 + i).unsafe_to_char())
  let oversized = String::from_array(chars)
  match @nanoid.custom_alphabet(oversized, size=1) {
    Err(error) => assert_eq(error, @nanoid.OversizedAlphabet(257))
    Ok(_) => fail("expected oversized alphabet")
  }
  // Existing behavior reports duplicates before alphabet or ID size errors.
  match @nanoid.custom_alphabet(oversized + chars[0].to_string(), size=0) {
    Err(error) => assert_eq(error, @nanoid.DuplicateCharacter(chars[0], 0, 257))
    Ok(_) => fail("expected duplicate before size errors")
  }
}
