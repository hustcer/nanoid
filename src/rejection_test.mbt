///|
test "short_id_survives_sixteen_rejected_bytes" {
  // With 129 characters, every byte in 129..255 must be rejected.
  // Sixteen consecutive rejections occur about once per 74,000 IDs with
  // uniform random bytes, so this is not evidence of a broken random source.
  let alphabet = String::from_array(
    Array::makei(129, i => (0x400 + i).unsafe_to_char()),
  )
  let consumed : Ref[Int] = { val: 0, }
  let random = fn(size : Int) -> Result[Array[Int], @nanoid.NanoidError] {
    Ok(
      Array::makei(size, _ => {
        let byte = if consumed.val < 16 { 255 } else { 5 }
        consumed.val += 1
        byte
      }),
    )
  }
  let generator = @nanoid.custom_random(alphabet, 1, random).unwrap()
  assert_eq(generator(), Ok("Ѕ"))
}

///|
test "short_id_rejection_retries_remain_bounded" {
  let consumed : Ref[Int] = { val: 0, }
  let random = fn(size : Int) -> Result[Array[Int], @nanoid.NanoidError] {
    consumed.val += size
    if consumed.val > 256 {
      return Err(@nanoid.RandomGenerationError("test safety guard reached"))
    }
    Ok(Array::make(size, 3))
  }
  let generator = @nanoid.custom_random("abc", 1, random).unwrap()
  match generator() {
    Err(@nanoid.RandomGenerationError(message)) =>
      assert_true(
        message.contains("Failed to generate sufficient random characters"),
      )
    _ => fail("expected bounded rejection failure")
  }
  assert_true(consumed.val <= 256)
}
