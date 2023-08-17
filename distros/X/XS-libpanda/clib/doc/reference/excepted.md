# excepted

Algebraic sum of type of result and type of error. Same as [expected](expected.md) but with different processing of `void`. See [Expect an Expected](../error.md#expect-the-expected) for a concept description.

# Synopsis

```cpp
    process("bad"); // exception thrown, you shoud assign and check the result

    auto ret = process("bad");
    if (!ret) {
        INFO(ret.error());
    } // no problem, ret was checked and processed

    process("good"); // no error, no problem

```