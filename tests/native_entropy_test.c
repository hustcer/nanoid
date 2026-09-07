// Compile the real entropy shim as a standalone translation unit. In particular,
// no preceding windows.h include may hide an include-order error in the shim.
#include "../src/random_stub.c"

#include <assert.h>
#include <string.h>

int main(void) {
  uint8_t bytes[64];
  memset(bytes, 0xA5, sizeof(bytes));

  assert(nanoid_os_random(bytes, -1) == -1);
  assert(nanoid_os_random(bytes, 0) == 0);
  for (size_t i = 0; i < sizeof(bytes); i++) {
    assert(bytes[i] == 0xA5);
  }

  // Guard bytes verify that the shim only writes the requested range.
  assert(nanoid_os_random(bytes + 1, (int)sizeof(bytes) - 2) == 0);
  assert(bytes[0] == 0xA5);
  assert(bytes[sizeof(bytes) - 1] == 0xA5);
  return 0;
}
