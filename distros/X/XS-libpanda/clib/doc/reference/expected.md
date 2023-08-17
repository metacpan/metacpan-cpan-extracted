# expected

Algebraic sum of type of result and type of error. See [Expect an Expected](../error.md#expect-the-expected) for a concept description.

# Synopsis

```cpp

    expected<long, string> parse(const char* c);


    auto i1 = parse("123");
    REQUIRE(i1.value() == 123); // using existing value, ok

    auto i2 = parse("99999999999999999999999999999999999999");
    int result = i2.value(); // ignoring error, exception is thrown

    auto i3 = parse("99999999999999999999999999999999999999");
    int result = i2.value_or(0); // 0 if error, no exceptions
    REQUIRE(result == 0);

    if (!i3) {
        REQUIRE(result.error() == "parsing failed");
    }

```
