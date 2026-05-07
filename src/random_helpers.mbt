///|
/// Convert random bytes to the Int byte-array representation used by the
/// existing nanoid generation pipeline.
fn bytes_to_int_array(random_bytes : Bytes, size : Int) -> Array[Int] {
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = random_bytes[i].to_int()
  }
  bytes
}
