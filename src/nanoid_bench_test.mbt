///|
test "nanoid_size_21" (b : @bench.T) {
  b.bench(() => b.keep(@nanoid.nanoid().unwrap()))
}

///|
test "nanoid_size_1" (b : @bench.T) {
  b.bench(() => b.keep(@nanoid.nanoid(size=1).unwrap()))
}

///|
test "reused_url_generator_size_21" (b : @bench.T) {
  let generate = @nanoid.custom_alphabet(@nanoid.url_alphabet).unwrap()
  b.bench(() => b.keep(generate().unwrap()))
}

///|
test "custom_alphabet_setup_ascii_64" (b : @bench.T) {
  b.bench(() => b.keep(@nanoid.custom_alphabet(@nanoid.url_alphabet).unwrap()))
}

///|
test "custom_alphabet_setup_unicode_256" (b : @bench.T) {
  let alphabet = String::from_array(
    Array::makei(256, i => (0x1F300 + i).unsafe_to_char()),
  )
  b.bench(() => b.keep(@nanoid.custom_alphabet(alphabet).unwrap()))
}
