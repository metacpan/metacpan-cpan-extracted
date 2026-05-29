Build the shared library:
    make

Equivalent direct gcc command:
    gcc -O2 -Wall -Wextra -Wpedantic -fPIC -Iinclude -shared -o libgreet.so src/greet.c

Notes:
- Returned strings are heap-allocated by the C library.
- Always free them with greet_free from the same library.
- greet_free_count() and greet_reset_free_count() expose a small test-only
  counter so runtimes can prove they called greet_free for owned returns.
- greet_person(NULL) and greet_person("") both return "Hello, world!".

Phase-0 std/clib contract symbols:
- greet() -> heap char*, NUL-terminated, free with greet_free.
- greet_person(const char *name) -> heap char*, NUL-terminated, free
  with greet_free. NULL and empty strings use "world".
- greet_free_count(void) -> int64_t number of greet_free calls.
- greet_reset_free_count(void) -> void.
- greet_add_i64(int64_t left, int64_t right) -> int64_t.
- greet_add_f64(double left, double right) -> double.
- greet_not(bool value) -> bool.
- greet_noop(void) -> void.
- greet_return_null(void) -> NULL char*.
- greet_copy_bytes(const char *bytes, int64_t len) -> heap bytes, free
  with greet_free. The returned byte length is exactly len.
- greet_count_bytes(const char *bytes, int64_t len) -> int64_t length,
  or -1 for invalid input.

The TAP-style ZuzuScript contract is in t/ztests/std/clib.zzs. It imports
std/clib directly, builds this fixture with gcc when needed, and exercises
all phase-0 fixture symbols.
