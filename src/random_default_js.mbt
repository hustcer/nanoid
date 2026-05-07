///|
/// JavaScript runtime-backed random bytes.
extern "js" fn js_crypto_random(buf : Bytes, len : Int) -> Int =
  #| (buf, len) => {
  #|   const chunkSize = 32768;
  #|   globalThis.__moonbit_nanoid_random_error = "";
  #|   const errorMessage = (prefix, error) => {
  #|     const detail = error && error.message ? error.message : String(error);
  #|     return `${prefix}: ${detail}`;
  #|   };
  #|   try {
  #|     const view = new Uint8Array(buf.buffer, buf.byteOffset, len);
  #|     if (globalThis.crypto?.getRandomValues) {
  #|       for (let offset = 0; offset < len; offset += chunkSize) {
  #|         globalThis.crypto.getRandomValues(
  #|           view.subarray(offset, Math.min(offset + chunkSize, len)),
  #|         );
  #|       }
  #|       return 0;
  #|     }
  #|     if (typeof require !== "undefined") {
  #|       const crypto = require("crypto");
  #|       for (let offset = 0; offset < len; offset += chunkSize) {
  #|         const end = Math.min(offset + chunkSize, len);
  #|         view.set(crypto.randomBytes(end - offset), offset);
  #|       }
  #|       return 0;
  #|     }
  #|     globalThis.__moonbit_nanoid_random_error =
  #|       "No JavaScript crypto source available";
  #|     return -1;
  #|   } catch (error) {
  #|     globalThis.__moonbit_nanoid_random_error =
  #|       errorMessage("JavaScript crypto random generation failed", error);
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn js_crypto_random_error() -> String =
  #| () => globalThis.__moonbit_nanoid_random_error ||
  #|   "Failed to get random bytes from JavaScript runtime"

///|
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  if size <= 0 {
    return Ok([])
  }
  let random_bytes = Bytes::new(size)
  if js_crypto_random(random_bytes, size) == 0 {
    Ok(bytes_to_int_array(random_bytes, size))
  } else {
    Err(RandomGenerationError(js_crypto_random_error()))
  }
}
