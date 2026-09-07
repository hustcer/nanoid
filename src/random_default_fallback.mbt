///|
/// WASM fallback RNG state.
///
/// MoonBit's wasm test runner does not provide a standard crypto import yet.
/// Keep the previous runtime-seeded ChaCha8 path for wasm and wasm-gc so
/// `moon test --target all` remains self-contained.
let global_rng : @random.Rand = @random.Rand::chacha8(seed=build_runtime_seed())

///|
fn mix_seed_state(state : UInt64) -> UInt64 {
  let mut mixed = state
  mixed = mixed ^ (mixed << 13)
  mixed = mixed ^ (mixed >> 7)
  mixed = mixed ^ (mixed << 17)
  mixed
}

///|
fn absorb_seed_string(state : UInt64, value : String) -> UInt64 {
  let mut mixed = state
  for char in value {
    mixed = mix_seed_state(mixed + char.to_int().to_uint64())
  }
  mixed
}

///|
fn build_runtime_seed() -> Bytes {
  let mut state = @env.now()
  for arg in @env.args() {
    state = absorb_seed_string(state, arg)
  }
  match @env.current_dir() {
    Some(cwd) => state = absorb_seed_string(state, cwd)
    None => ()
  }
  if state == Default::default() {
    state = Int::to_uint64(1)
  }

  let seed_bytes : Array[Byte] = Array::make(32, 0)
  for i = 0; i < 32; i = i + 1 {
    state = mix_seed_state(state + Int::to_uint64(i + 1))
    seed_bytes[i] = state.to_byte()
  }
  Bytes::from_array(seed_bytes)
}

///|
fn get_random_bytes(size : Int) -> Result[Array[Int], NanoidError] {
  let bytes = Array::make(size, 0)
  for i = 0; i < size; i = i + 1 {
    bytes[i] = global_rng.int(limit=256)
  }
  Ok(bytes)
}
