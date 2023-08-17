# ErrorCode
A list of [std::error_codes](https://en.cppreference.com/w/cpp/error/error_code). See paragraph [ErrorCode](../error.md#errorcode) of [Eroor Handling](../error.md)

# Synopsis

```cpp
    enum MyErr { Err1 = 1, Err2 };
    // assume that MyError is is_error_code_enum for std::error_code and MyCategory exists

    ErrorCode nested_code(Err1);
    ErrorCode code(Err2, nested_code);
    auto n = code.next(); // code.next() is Err1

    string text = code.what(); //"MyErr2 (2:MyCategory) -> MyErr1 (1:MyCategory)";

    code.contains(Err1); // true
    code.contains(Err2); // true
```


# Methods

