///|
/// Native OS-backed random bytes.
#borrow(buf)
extern "C" fn os_random(buf : Bytes, len : Int) -> Int = "nanoid_os_random"

///|
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  if size <= 0 {
    return Ok([])
  }
  let random_bytes = Bytes::new(size)
  if os_random(random_bytes, size) == 0 {
    Ok(bytes_to_int_array(random_bytes, size))
  } else {
    Err(RandomGenerationError("Failed to get random bytes from OS"))
  }
}
