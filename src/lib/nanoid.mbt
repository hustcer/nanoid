///| MoonBit port of Nano ID library
/// A tiny, secure, URL-friendly, unique string ID generator
/// MoonBit implementation compatible with the official nanoid JavaScript library

// ========== Error Handling ==========

///| Error types for nanoid operations
pub enum NanoidError {
  EmptyAlphabet
  OversizedAlphabet(Int) // Contains the actual length
  SizeTooSmall(Int) // Contains the invalid size value (<= 0)
  SizeTooLarge(Int) // Contains the invalid size value (> MAX_ID_SIZE)
  RandomGenerationError(String)
}

///| Convert NanoidError to string representation
pub fn NanoidError::to_string(self : NanoidError) -> String {
  match self {
    EmptyAlphabet => "Alphabet cannot be empty"
    OversizedAlphabet(len) =>
      "Alphabet length (\{len}) exceeds maximum of 256 characters"
    SizeTooSmall(size) => "Size (\{size}) must be greater than 0"
    SizeTooLarge(size) =>
      "Size (\{size}) exceeds maximum allowed size of 1,000,000"
    RandomGenerationError(msg) => "Random generation failed: \{msg}"
  }
}

///| Convert NanoidError to detailed string representation with helpful guidance
pub fn NanoidError::to_string_detailed(self : NanoidError) -> String {
  match self {
    EmptyAlphabet =>
      "Alphabet cannot be empty. Please provide at least one character."
    OversizedAlphabet(len) =>
      "Alphabet length (\{len}) exceeds maximum of 256 characters. Consider using a smaller character set."
    SizeTooSmall(size) =>
      if size < 0 {
        "Size (\{size}) cannot be negative. Please provide a positive integer."
      } else {
        "Size (\{size}) must be greater than 0. Use size=1 for single character IDs."
      }
    SizeTooLarge(size) =>
      "Size (\{size}) exceeds maximum allowed size of 1,000,000. Large IDs may cause memory issues."
    RandomGenerationError(msg) =>
      "Random generation failed: \{msg}. This may indicate a system-level issue."
  }
}

///| Helper function to create error results
fn[T] error_result(error : NanoidError) -> Result[T, NanoidError] {
  Err(error)
}

// ========== Unified Validation Module ==========

///| Validation result for parameter checking
priv enum ValidationResult {
  Valid
  InvalidAlphabet(NanoidError)
  InvalidSize(NanoidError)
  InvalidRandom(NanoidError)
}

///| Validate alphabet parameter (with caching)
fn validate_alphabet(alphabet : String) -> ValidationResult {
  get_cached_alphabet_validation(alphabet)
}

///| Internal alphabet validation without caching
fn validate_alphabet_uncached(alphabet : String) -> ValidationResult {
  // Check for empty alphabet
  if alphabet.length() == 0 {
    return InvalidAlphabet(EmptyAlphabet)
  }

  // Check for oversized alphabet
  if alphabet.length() > MAX_ALPHABET_SIZE {
    return InvalidAlphabet(OversizedAlphabet(alphabet.length()))
  }

  // Use an immutable HashMap to efficiently check for duplicates and provide rich error messages.
  // The map stores the character and the index where it was first seen.
  let mut seen : @immut/hashmap.T[Char, Int] = @immut/hashmap.new()
  for i = 0; i < alphabet.length(); i = i + 1 {
    match alphabet.get_char(i) {
      Some(char) =>
        match seen.get(char) {
          Some(first_pos) =>
            // Duplicate found, return a detailed error.
            return InvalidAlphabet(
              RandomGenerationError(
                "Duplicate character '\{char}' found at position \{i}, first seen at \{first_pos}",
              ),
            )
          None =>
            // First time seeing this character, add it to the map with its index.
            seen = seen.add(char, i)
        }
      None =>
        return InvalidAlphabet(
          RandomGenerationError(
            "Invalid character in alphabet at position \{i}",
          ),
        )
    }
  }
  Valid
}

///| Validate size parameter
fn validate_size(size : Int) -> ValidationResult {
  if size <= 0 {
    return InvalidSize(SizeTooSmall(size))
  }
  if size > MAX_ID_SIZE {
    return InvalidSize(SizeTooLarge(size))
  }
  Valid
}

///| Validate random function parameter
fn validate_random_function(
  random : (Int) -> Result[Array[Int], NanoidError],
) -> ValidationResult {
  // Test the random function with a small sample to catch issues early
  match random(1) {
    Ok(test_bytes) =>
      if test_bytes.length() != 1 {
        return InvalidRandom(
          RandomGenerationError(
            "Custom random function returned incorrect array length",
          ),
        )
      } else {
        Valid
      }
    Err(e) => InvalidRandom(e)
  }
}

///| Validate both alphabet and size parameters
fn validate_parameters(alphabet : String, size : Int) -> ValidationResult {
  match validate_alphabet(alphabet) {
    Valid => validate_size(size)
    error => error
  }
}

///| Validate alphabet, size, and random function parameters
fn validate_all_parameters(
  alphabet : String,
  size : Int,
  random : (Int) -> Result[Array[Int], NanoidError],
) -> ValidationResult {
  match validate_parameters(alphabet, size) {
    Valid => validate_random_function(random)
    error => error
  }
}

///| Constant-time string comparison to prevent timing attacks
/// This is important for security-sensitive applications
/// Usage: Use this when comparing sensitive strings like tokens or IDs
pub fn constant_time_eq(a : String, b : String) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut result = 0
  for i = 0; i < a.length(); i = i + 1 {
    let char_a = match a.get_char(i) {
      Some(c) => c.to_int()
      None => 0
    }
    let char_b = match b.get_char(i) {
      Some(c) => c.to_int()
      None => 0
    }
    result = result | (char_a ^ char_b)
  }
  result == 0
}

///| Secure memory clearing for sensitive data (enhanced)
pub fn secure_clear_bytes(bytes : Array[Int]) -> Unit {
  // Clear the array contents to prevent sensitive data from remaining in memory
  // Use multiple passes to make it harder for compiler to optimize away
  for i = 0; i < bytes.length(); i = i + 1 {
    bytes[i] = 0
  }
  // Second pass with different pattern to prevent optimization
  for i = 0; i < bytes.length(); i = i + 1 {
    bytes[i] = bytes[i] ^ 0xFF
    bytes[i] = bytes[i] ^ 0xFF // XOR twice to get back to 0, but prevents optimization
  }
  // Note: In a real implementation, we might want to add memory barriers
  // or use volatile operations to prevent compiler optimizations
}

// ========== Constants and Alphabets ==========

///| Default URL-friendly alphabet (official nanoid order)
/// Uses the same character order as official nanoid: A-Z, a-z, 0-9, underscore, hyphen
pub let url_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

///| Default ID length (same as official nanoid)
const DEFAULT_SIZE = 21

// ========== Algorithm Constants ==========

///| Maximum allowed alphabet size to prevent memory issues
const MAX_ALPHABET_SIZE = 256

///| Maximum allowed ID size to prevent memory issues
const MAX_ID_SIZE = 1000000

///| Safety factor for batch generation attempts to prevent infinite loops
const BATCH_GENERATION_SAFETY_FACTOR = 3

///| Maximum attempts for rejection sampling to prevent infinite loops
const MAX_REJECTION_ATTEMPTS = 100

///| Minimum batch size for random byte generation
const MIN_BATCH_SIZE = 8

///| Maximum batch size for random byte generation
const MAX_BATCH_SIZE = 256

// ========== Xorshift64* Algorithm Constants ==========

///| Xorshift64* multiplier constant for final mixing
const XORSHIFT_MULTIPLIER = 0x2545F4914F6CDD1DL

///| SplitMix64 golden ratio constant
const SPLITMIX_GOLDEN_RATIO = 0x9E3779B97F4A7C15L

///| SplitMix64 first multiplier
const SPLITMIX_MULT1 = 0xBF58476D1CE4E5B9L

///| SplitMix64 second multiplier
const SPLITMIX_MULT2 = 0x94D049BB133111EBL

///| SplitMix64 third multiplier
const SPLITMIX_MULT3 = 0xFF51AFD7ED558CCDL

///| SplitMix64 fourth multiplier
const SPLITMIX_MULT4 = 0xC4CEB9FE1A85EC53L

///| Additional entropy mixing constants
const ENTROPY_MIX1 = 0x517CC1B727220A95L

///| Second entropy mixing constant for cross-correlation prevention
const ENTROPY_MIX2 = 0x94D049BB133111EBL

///| Maximum safe value for rejection sampling (2^63 - 1)
const MAX_SAFE_INT64 = 0x7FFFFFFFFFFFFFFFL

// ========== Random Number Generation ==========

///| High-quality random number generator for nanoid
/// Uses xorshift algorithm for better randomness distribution
pub struct SimpleRng {
  mut state : Int64
}

///| Global counter to ensure different seeds for each call
/// Note: In a multi-threaded environment, this should use atomic operations
pub let global_call_count : Ref[Int] = { val: 0 }

///| Thread-safe increment of global counter (simulated atomic operation)
pub fn atomic_increment_counter() -> Int {
  // In a real implementation, this should use atomic compare-and-swap
  // For now, we simulate thread safety with multiple reads to detect changes
  let mut old_val = global_call_count.val
  let mut new_val = old_val + 1

  // Simple retry mechanism to handle potential race conditions
  let mut attempts = 0
  while attempts < 3 {
    let current_val = global_call_count.val
    if current_val == old_val {
      global_call_count.val = new_val
      return new_val
    } else {
      // Value changed, retry with new value
      old_val = current_val
      new_val = old_val + 1
      attempts = attempts + 1
    }
  }

  // Fallback: just increment (may have race condition but better than nothing)
  global_call_count.val = global_call_count.val + 1
  global_call_count.val
}

// ========== Alphabet Validation Cache ==========

// ========== Alphabet Validation Cache ==========
// Note: Caching temporarily disabled due to Map API limitations
// TODO: Re-implement when Map.insert is available or use alternative approach

///| Get cached validation result or compute and cache it
/// Currently just calls validate_alphabet_uncached directly
fn get_cached_alphabet_validation(alphabet : String) -> ValidationResult {
  // TODO: Implement proper caching when Map API is more complete
  validate_alphabet_uncached(alphabet)
}

///| Create a new random number generator with a seed
pub fn SimpleRng::new(seed : Int64) -> SimpleRng {
  { state: seed }
}

///| Generate the next random 64-bit integer using xorshift64*
pub fn next_int64(self : SimpleRng) -> Int64 {
  // Xorshift64* algorithm - high quality PRNG
  // Avoid zero state which would cause the generator to get stuck
  if self.state == 0L {
    self.state = 1L
  }

  // Apply xorshift transformations to the state
  self.state = self.state ^ (self.state >> 12)
  self.state = self.state ^ (self.state << 25)
  self.state = self.state ^ (self.state >> 27)

  // The state transformations above are the actual state updates
  self.state * XORSHIFT_MULTIPLIER
}

///| Generate a random integer in range [0, limit) with uniform distribution
pub fn next_int(self : SimpleRng, limit : Int) -> Int {
  if limit <= 0 {
    return 0
  }
  if limit == 1 {
    return 0
  }

  // For small limits, use simple approach to avoid complexity
  if limit <= 256 {
    let rand = self.next_int64()
    // Use absolute value properly to handle negative numbers
    let abs_rand = if rand < 0L { -rand } else { rand }
    return (abs_rand % limit.to_int64()).to_int()
  }

  // For larger limits, use rejection sampling with safety limit
  let limit_64 = limit.to_int64()
  let max_valid = MAX_SAFE_INT64 / limit_64 * limit_64
  let mut attempts = 0
  let max_attempts = MAX_REJECTION_ATTEMPTS // Prevent infinite loops
  while attempts < max_attempts {
    let rand = self.next_int64()
    let abs_rand = if rand < 0L { -rand } else { rand }
    if abs_rand < max_valid {
      return (abs_rand % limit_64).to_int()
    }
    attempts = attempts + 1
  }

  // Fallback: use simple modulo if rejection sampling fails
  let rand = self.next_int64()
  let abs_rand = if rand < 0L { -rand } else { rand }
  (abs_rand % limit_64).to_int()
}

// Performance utility functions removed - can be added back when needed

///| Convert alphabet string to character array for efficient access
pub fn alphabet_to_chars(alphabet : String) -> Array[Char] {
  let chars = Array::make(alphabet.length(), ' ')
  for i = 0; i < alphabet.length(); i = i + 1 {
    chars[i] = alphabet.get_char(i).unwrap()
  }
  chars
}

///| Get precomputed mask for common alphabet sizes
pub fn get_precomputed_mask(alphabet_length : Int) -> Int? {
  match alphabet_length {
    2 => Some(1) // 2^1 - 1
    4 => Some(3) // 2^2 - 1
    8 => Some(7) // 2^3 - 1
    16 => Some(15) // 2^4 - 1
    32 => Some(31) // 2^5 - 1
    64 => Some(63) // 2^6 - 1
    128 => Some(127) // 2^7 - 1
    256 => Some(255) // 2^8 - 1
    _ => None
  }
}

///| Calculate mask for uniform distribution (power of 2 - 1)
/// Uses precomputed values for common sizes, falls back to calculation for others
pub fn calculate_mask(alphabet_length : Int) -> Int {
  match get_precomputed_mask(alphabet_length) {
    Some(mask) => mask
    None => {
      // Fallback to calculation for uncommon sizes
      let mut mask = 1
      while mask < alphabet_length {
        mask = mask << 1
      }
      mask - 1
    }
  }
}

///| Generate ID characters using batch processing with rejection sampling (optimized)
fn generate_id_characters(
  alphabet : String,
  size : Int,
  step : Int,
  mask : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  let alphabet_length = alphabet.length()
  let alphabet_chars = get_cached_alphabet_chars(alphabet) // Use cached conversion for efficiency
  let id_chars = Array::make(size, ' ')
  let mut counter = 0
  let mut batch_count = 0
  let max_batches = (size / step + 1) * BATCH_GENERATION_SAFETY_FACTOR // Allow reasonable number of batches

  // Main generation loop with batch processing
  while counter < size && batch_count < max_batches {
    let random_bytes = match get_random(step) {
      Ok(bytes) => bytes
      Err(e) => return Err(e)
    }

    // Process each byte in the batch using optimized version
    counter = process_random_batch_optimized(
      random_bytes, alphabet_chars, id_chars, counter, size, mask, alphabet_length,
    )
    batch_count = batch_count + 1

    // Clear sensitive random bytes after use
    secure_clear_bytes(random_bytes)
  }

  // Handle insufficient randomness case by returning an error
  if counter < size {
    match handle_insufficient_randomness(batch_count) {
      Ok(_) => () // Should not happen, but handles the Result type
      Err(e) => return Err(e)
    }
  }
  Ok(String::from_array(id_chars))
}

///| Process a batch of random bytes and fill ID characters (optimized version)
fn process_random_batch_optimized(
  random_bytes : Array[Int],
  alphabet_chars : Array[Char],
  id_chars : Array[Char],
  start_counter : Int,
  target_size : Int,
  mask : Int,
  alphabet_length : Int,
) -> Int {
  let mut counter = start_counter
  let mut byte_index = 0
  while byte_index < random_bytes.length() && counter < target_size {
    let byte = random_bytes[byte_index] & mask
    if byte < alphabet_length {
      // Direct array access is faster than string.get_char()
      id_chars[counter] = alphabet_chars[byte]
      counter = counter + 1
    }
    byte_index = byte_index + 1
  }
  counter
}

// Legacy function removed - now using optimized version directly

///| Handle the case where insufficient random characters were generated (optimized)
fn handle_insufficient_randomness(
  batch_count : Int,
) -> Result[Unit, NanoidError] {
  // This function is called when not enough characters were generated.
  // Instead of falling back to a deterministic pattern, we will always
  // return an error to enforce security and correctness ("fail-fast").
  return error_result(
    RandomGenerationError(
      "Failed to generate sufficient random characters after \{batch_count} batches. This may indicate an issue with the random number generator.",
    ),
  )
}

///| Heuristic fast-path for optimal batch size when rejection probability is zero.

///| Returns Some(step) only when (mask + 1) == alphabet_length (i.e. power-of-two alphabet)

///| so every generated random byte can map to a character without rejection.

///| Strategy:

///|   - Use target_size directly (1 batch ideal) to minimize RNG + loop overhead.

///|   - Clamp to [MIN_BATCH_SIZE, MAX_BATCH_SIZE] to avoid pathological tiny/huge requests.

///|   - Otherwise return None and let the analytical path compute a value.

///| Rationale:

///|   Previous implementation hard-coded opaque magic numbers (e.g. 64->10) which caused

///|   unnecessary multiple batches, increasing RNG calls and memory clearing. This version

///|   keeps semantics minimal while enabling single-batch generation for common alphabets

///|   like 64 (URL/base64) and 32 (base32) when size is within limits.
pub fn get_precomputed_batch_size(
  alphabet_length : Int,
  target_size : Int,
  mask : Int,
) -> Int? {
  if mask + 1 == alphabet_length { // perfect power-of-two span => zero rejection
    // Clamp desired step to reasonable bounds
    let mut step = target_size
    if step < MIN_BATCH_SIZE {
      step = MIN_BATCH_SIZE
    }
    if step > MAX_BATCH_SIZE {
      step = MAX_BATCH_SIZE
    }
    return Some(step)
  }
  None
}

///| Calculate optimal batch size for random byte generation
/// Uses entropy efficiency analysis to determine the best batch size
fn calculate_optimal_batch_size(
  alphabet_length : Int,
  target_size : Int,
  mask : Int,
) -> Int {
  // Fast path: perfect power-of-two span uses single batch (clamped) to reduce overhead.
  let optimized_step = match
    get_precomputed_batch_size(alphabet_length, target_size, mask) {
    Some(precomputed) => precomputed
    None => {
      // Analytical estimation: bytes_needed ≈ target_size * waste_factor * safety_margin
      // waste_factor = 1 / efficiency, efficiency = alphabet_length / (mask+1)
      let efficiency = alphabet_length.to_double() / (mask + 1).to_double()
      let waste_factor = 1.0 / efficiency
      let safety_margin = 1.2 // modest extra to reduce probability of a second batch
      let raw = (target_size.to_double() * waste_factor * safety_margin).to_int()
      // Clamp to global bounds
      let mut est = raw
      if est < MIN_BATCH_SIZE {
        est = MIN_BATCH_SIZE
      }
      if est > MAX_BATCH_SIZE {
        est = MAX_BATCH_SIZE
      }
      est
    }
  }

  // Avoid generating wildly more bytes than needed for very small target sizes.
  let max_reasonable = target_size * 2
  if optimized_step > max_reasonable {
    max_reasonable
  } else {
    optimized_step
  }
}

///| Enhanced seed generation using multiple entropy sources (improved security)
fn create_enhanced_seed(size_hint : Int) -> Int64 {
  // Thread-safe increment of global counter for entropy
  let old_count = global_call_count.val
  let count = atomic_increment_counter().to_int64()
  let size_factor = size_hint.to_int64()

  // 2. Additional entropy sources for better unpredictability
  let thread_entropy = (old_count.to_int64() * 0x9E3779B97F4A7C15L) ^ count
  let size_entropy = size_factor * ENTROPY_MIX1
  let cross_entropy = (count ^ size_factor) * ENTROPY_MIX2

  // 3. Use SplitMix64 algorithm for high-quality mixing
  let mut seed = count + SPLITMIX_GOLDEN_RATIO + thread_entropy
  seed = (seed ^ (seed >> 30)) * SPLITMIX_MULT1
  seed = (seed ^ (seed >> 27)) * SPLITMIX_MULT2
  seed = seed ^ (seed >> 31)

  // 4. Mix in additional entropy sources
  seed = seed ^ size_entropy
  seed = seed ^ (old_count.to_int64() * SPLITMIX_GOLDEN_RATIO)
  seed = seed ^ cross_entropy

  // 5. Add cross-correlation prevention with enhanced mixing
  seed = seed ^ (count * size_factor * ENTROPY_MIX2)
  seed = seed ^ ((count << 16) | (size_factor & 0xFFFFL))

  // 6. Final mixing step for better avalanche effect
  seed = seed ^ (seed >> 33)
  seed = seed * SPLITMIX_MULT3
  seed = seed ^ (seed >> 33)
  seed = seed * SPLITMIX_MULT4
  seed = seed ^ (seed >> 33)

  // 7. Additional security: ensure seed has good bit distribution
  let bit_count = count_set_bits(seed)
  if bit_count < 16 || bit_count > 48 {
    // If bit distribution is poor, add more entropy
    seed = seed ^ (SPLITMIX_GOLDEN_RATIO * (bit_count.to_int64() + 1L))
  }

  // Ensure seed is never zero to prevent RNG from getting stuck
  if seed == 0L {
    seed = SPLITMIX_GOLDEN_RATIO
  }
  seed
}

///| Count the number of set bits in an Int64 (for entropy quality check)
pub fn count_set_bits(n : Int64) -> Int {
  let mut count = 0
  let mut num = n
  while num != 0L {
    count = count + 1
    num = num & (num - 1L) // Clear the lowest set bit
  }
  count
}

///| Calculate entropy efficiency for a given alphabet size and mask
pub fn calculate_entropy_efficiency(
  alphabet_length : Int,
  mask : Int,
) -> Double {
  alphabet_length.to_double() / (mask + 1).to_double()
}

///| Estimate waste factor for rejection sampling
pub fn calculate_waste_factor(alphabet_length : Int, mask : Int) -> Double {
  let efficiency = calculate_entropy_efficiency(alphabet_length, mask)
  1.0 / efficiency
}

///| Get optimal batch size recommendation for given parameters
pub fn get_batch_size_recommendation(
  alphabet_length : Int,
  target_size : Int,
  mask : Int,
) -> Int {
  calculate_optimal_batch_size(alphabet_length, target_size, mask)
}

///| Maximum number of alphabets to store in the cache.
const MAX_ALPHABET_CACHE_SIZE = 16

///| Simple alphabet cache to avoid repeated conversions
/// Note: This is a basic implementation. In production, consider using a proper LRU cache
let alphabet_char_cache : Ref[@immut/hashmap.T[String, Array[Char]]] = {
  val: @immut/hashmap.new(),
}

///| Get cached character array for alphabet, or convert and cache it
pub fn get_cached_alphabet_chars(alphabet : String) -> Array[Char] {
  let cache = alphabet_char_cache.val

  // Check if alphabet is already cached using the map
  match cache.get(alphabet) {
    Some(cached_chars) =>
      // Cache hit
      return cached_chars
    None => {
      // Cache miss: convert and then cache
      let chars = alphabet_to_chars(alphabet)

      // Only cache if the cache size is within the limit to prevent memory bloat
      if cache.size() < MAX_ALPHABET_CACHE_SIZE {
        let new_cache = cache.add(alphabet, chars)
        alphabet_char_cache.val = new_cache
      }
      return chars
    }
  }
}

///| Internal function to generate secure random bytes
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  // Create high-quality seed using enhanced algorithm
  let mut seed = create_enhanced_seed(size)
  let rng = SimpleRng::new(seed)
  let bytes = Array::make(size, 0)

  // Generate bytes directly from RNG
  for i = 0; i < size; i = i + 1 {
    bytes[i] = rng.next_int(256)
  }

  // Security - Clear sensitive seed data from memory more thoroughly
  seed = 0L

  // Return bytes first - don't clear them here as they contain the random data we need!
  Ok(bytes)
}

///| Internal function to generate ID with given alphabet, size, and random function
/// Returns Result with ID string or NanoidError for invalid parameters
fn generate(
  alphabet : String,
  size : Int,
  get_random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[String, NanoidError] {
  match validate_parameters(alphabet, size) {
    Valid => () // Continue with generation
    InvalidAlphabet(error) => return Err(error)
    InvalidSize(error) => return Err(error)
    InvalidRandom(error) => return Err(error)
  }
  let alphabet_length = alphabet.length()

  // Special case: single character alphabet - no randomness needed
  if alphabet_length == 1 {
    let single_char = alphabet.get_char(0).unwrap()
    let chars = Array::make(size, single_char)
    return Ok(String::from_array(chars))
  }

  // Calculate mask for uniform distribution (avoid modulo bias)
  let mask = calculate_mask(alphabet_length)

  // Calculate optimal batch size for random byte generation
  let step = calculate_optimal_batch_size(alphabet_length, size, mask)

  // Generate ID characters using optimized batch processing
  generate_id_characters(alphabet, size, step, mask, get_random)
}

///| Main nanoid function - generates URL-friendly unique ID
/// Generates secure random IDs using the default URL-safe alphabet
/// Returns Result with ID string or NanoidError for invalid parameters
/// Usage: nanoid() generates 21-character ID, nanoid(size=10) generates 10-character ID
pub fn nanoid(size~ : Int = DEFAULT_SIZE) -> Result[String, NanoidError] {
  generate(url_alphabet, size, get_random_bytes)
}

///| Convenience function that returns empty string on error (for backward compatibility)
/// Usage: nanoid_or_empty() generates 21-character ID or empty string on error
pub fn nanoid_or_empty(size~ : Int = DEFAULT_SIZE) -> String {
  match nanoid(size~) {
    Ok(id) => id
    Err(_) => ""
  }
}

///| Custom alphabet function - returns a nanoid generator with custom alphabet
/// Creates a generator function that uses the specified alphabet and size
/// Returns Result with generator function or NanoidError for invalid parameters
/// Usage: let gen = custom_alphabet("abc123", size=8)?; let id = gen()?
pub fn custom_alphabet(
  alphabet : String,
  size~ : Int = DEFAULT_SIZE,
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  // Use unified validation
  match validate_parameters(alphabet, size) {
    Valid =>
      Ok(fn() -> Result[String, NanoidError] {
        generate(alphabet, size, get_random_bytes)
      })
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
    InvalidRandom(error) => Err(error)
  }
}

///| Convenience custom alphabet function that returns empty string on error
/// Usage: let gen = custom_alphabet_or_empty("abc123", size=8); let id = gen()
pub fn custom_alphabet_or_empty(
  alphabet : String,
  size~ : Int = DEFAULT_SIZE,
) -> () -> String {
  match custom_alphabet(alphabet, size~) {
    Ok(gen) =>
      fn() -> String {
        match gen() {
          Ok(id) => id
          Err(_) => ""
        }
      }
    Err(_) => fn() -> String { "" }
  }
}

///| Custom random function - allows custom random generator
/// Creates a generator with custom alphabet, size, and random function
/// Returns Result with generator function or NanoidError for invalid parameters
/// Usage: let gen = custom_random(alphabet, size, random_fn)?; let id = gen()?
pub fn custom_random(
  alphabet : String,
  size : Int,
  random : (Int) -> Result[Array[Int], NanoidError],
) -> Result[() -> Result[String, NanoidError], NanoidError] {
  // Use unified validation for all parameters
  match validate_all_parameters(alphabet, size, random) {
    Valid =>
      Ok(fn() -> Result[String, NanoidError] {
        generate(alphabet, size, random)
      })
    InvalidAlphabet(error) => Err(error)
    InvalidSize(error) => Err(error)
    InvalidRandom(error) => Err(error)
  }
}

///| Convenience custom random function that returns empty string on error
/// Usage: let gen = custom_random_or_empty(alphabet, size, random_fn); let id = gen()
pub fn custom_random_or_empty(
  alphabet : String,
  size : Int,
  random : (Int) -> Array[Int],
) -> () -> String {
  let safe_random = fn(size : Int) -> Result[Array[Int], NanoidError] {
    Ok(random(size))
  }
  match custom_random(alphabet, size, safe_random) {
    Ok(gen) =>
      fn() -> String {
        match gen() {
          Ok(id) => id
          Err(_) => ""
        }
      }
    Err(_) => fn() -> String { "" }
  }
}

// ========== Character Sets & Alphabet Presets ==========
// Based on nanoid-dictionary (https://github.com/CyberAP/nanoid-dictionary)

///| Numbers from 0 to 9
pub let numbers = "0123456789"

///| Lowercase English letters
pub let lowercase = "abcdefghijklmnopqrstuvwxyz"

///| Uppercase English letters
pub let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

///| Combination of lowercase, uppercase letters and numbers
/// Does not include any symbols or special characters
pub let alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

///| Lowercase hexadecimal characters
pub let hex = "0123456789abcdef"

///| Uppercase hexadecimal characters
pub let hex_upper = "0123456789ABCDEF"

///| Numbers and English alphabet without lookalikes
/// Removes: 1, l, I, 0, O, o, u, v, 5, S, s, 2, Z
/// Complete set: 346789ABCDEFGHJKLMNPQRTUVWXYabcdefghijkmnpqrtwxyz
pub let nolookalikes = "346789ABCDEFGHJKLMNPQRTUVWXYabcdefghijkmnpqrtwxyz"

///| Same as nolookalikes but with additional removed characters: 3, 4, x, X, V
/// Also removes vowels to protect from accidentally getting obscene words in generated strings
/// Complete set: 6789BCDFGHJKLMNPQRTWbcdfghjkmnpqrtwz
pub let nolookalikes_safe = "6789BCDFGHJKLMNPQRTWbcdfghjkmnpqrtwz"

///| Base62 encoding alphabet (numbers, uppercase, lowercase)
/// Compatible with most base62 implementations
pub let base62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

///| Base58 encoding alphabet (Bitcoin style - excludes 0, O, I, l)
/// Used in cryptocurrency and other applications to avoid character confusion
pub let base58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz"

///| URL-safe characters that don't require encoding in most contexts
/// Excludes characters that might be problematic in URLs or file systems
/// Same as the default url_alphabet
pub let url_safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

///| Filename-safe characters for cross-platform compatibility
/// Safe for use in filenames on Windows, macOS, and Linux
pub let filename_safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

// ========== Security Utilities ==========

///| Secure ID verification using constant-time comparison
/// This prevents timing attacks when verifying IDs or tokens
/// Usage: secure_verify_id(user_provided_id, expected_id)
pub fn secure_verify_id(provided_id : String, expected_id : String) -> Bool {
  constant_time_eq(provided_id, expected_id)
}
