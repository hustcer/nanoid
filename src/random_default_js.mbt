///|
/// JavaScript runtime-backed random bytes.
extern "js" fn js_crypto_random(buf : Bytes, len : Int) -> Int =
  #| (buf, len) => {
  #|   try {
  #|     const view = new Uint8Array(buf.buffer, buf.byteOffset, len);
  #|     if (globalThis.crypto?.getRandomValues) {
  #|       globalThis.crypto.getRandomValues(view);
  #|       return 0;
  #|     }
  #|     if (typeof require !== "undefined") {
  #|       const crypto = require("crypto");
  #|       view.set(crypto.randomBytes(len));
  #|       return 0;
  #|     }
  #|     return -1;
  #|   } catch (_) {
  #|     return -1;
  #|   }
  #| }

///|
fn bytes_to_int_array(random_bytes : Bytes, size : Int) -> Array[Int] {
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = random_bytes[i].to_int()
  }
  bytes
}

///|
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  if size <= 0 {
    return Ok([])
  }
  let random_bytes = Bytes::new(size)
  if js_crypto_random(random_bytes, size) == 0 {
    Ok(bytes_to_int_array(random_bytes, size))
  } else {
    Err(
      RandomGenerationError(
        "Failed to get random bytes from JavaScript runtime",
      ),
    )
  }
}
