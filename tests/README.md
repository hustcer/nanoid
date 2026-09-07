# Native entropy regression

`native_entropy_test.c` includes the actual C shim first, so unrelated includes
cannot hide missing prerequisites. It verifies that negative and zero lengths
do not write to the buffer and that a successful request preserves guard bytes.

Compile and run on macOS or Linux, using your MoonBit include directory:

```sh
cc -Wall -Wextra -Werror -I "$HOME/.moon/include" tests/native_entropy_test.c -o /tmp/nanoid-native-entropy-test
/tmp/nanoid-native-entropy-test
```

Cross-compile on a machine with Zig to check Windows headers and BCrypt linkage:

```sh
zig cc -target x86_64-windows-gnu -I "$HOME/.moon/include" tests/native_entropy_test.c -lbcrypt -o /tmp/nanoid-native-entropy-test.exe
```

Before the Windows include-order fix, this test fails to compile in `bcrypt.h`
with undefined `LONG`, `ULONG`, and other Windows types. After the fix it compiles
and links. Cross-compilation does not execute the Windows binary; the existing
Windows CI job separately builds and runs the MoonBit tests with the native shim.
