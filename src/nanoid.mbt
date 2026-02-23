///| Public facade package for hustcer/nanoid.
/// Re-exports the library API from hustcer/nanoid/lib so users can import
/// hustcer/nanoid directly.

///|
pub type NanoidError = @nid.NanoidError

///|
pub let url_alphabet : String = @nid.url_alphabet

///|
pub let numbers : String = @nid.numbers

///|
pub let lowercase : String = @nid.lowercase

///|
pub let uppercase : String = @nid.uppercase

///|
pub let alphanumeric : String = @nid.alphanumeric

///|
pub let hex : String = @nid.hex

///|
pub let hex_upper : String = @nid.hex_upper

///|
pub let nolookalikes : String = @nid.nolookalikes

///|
pub let nolookalikes_safe : String = @nid.nolookalikes_safe

///|
pub let base62 : String = @nid.base62

///|
pub let base58 : String = @nid.base58

///|
pub let url_safe : String = @nid.url_safe

///|
pub let filename_safe : String = @nid.filename_safe

///|
pub fn nanoid(size? : Int = 21) -> Result[String, NanoidError] {
  @nid.nanoid(size~)
}

///|
pub fn nanoid_or_empty(size? : Int = 21) -> String {
  @nid.nanoid_or_empty(size~)
}

///|
pub fn custom_alphabet(
  alphabet : String,
  size? : Int = 21,
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  @nid.custom_alphabet(alphabet, size~)
}

///|
pub fn custom_alphabet_or_empty(
  alphabet : String,
  size? : Int = 21,
) -> () -> String {
  @nid.custom_alphabet_or_empty(alphabet, size~)
}

///|
pub fn custom_random(
  alphabet : String,
  size : Int,
  random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  @nid.custom_random(alphabet, size, random)
}

///|
pub fn custom_random_or_empty(
  alphabet : String,
  size : Int,
  random : (Int) -> Array[Int],
) -> () -> String {
  @nid.custom_random_or_empty(alphabet, size, random)
}
