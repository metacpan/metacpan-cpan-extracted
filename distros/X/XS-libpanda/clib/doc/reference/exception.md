# exception

Basic class for exceptions. Inherits std::exception and panda::Backtrace.

# Synopsis

```cpp
try {
    throw panda::exception("error");
} catch (panda::exception& e) {
    string what = e.whats(); // whats is the same as what but w/o allocation a char array
    string stack = e.get_backtrace_info()->to_string();
}
```

# Methods

Inherits [Backtrace](backtrace)

Ingerits [std::exception](https://en.cppreference.com/w/cpp/error/exception)

## whats()
```cpp
virtual string whats () const noexcept;
```

String representation of error. `panda::exceptions` stores a [panda::string](../string.md) so it is easier and faster to return it instead of allocating new char array.