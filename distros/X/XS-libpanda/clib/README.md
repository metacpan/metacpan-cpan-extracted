# Panda-Lib

Panda-Lib is a C++ library with basic functionality. It contains implementation of string, function, pool allocator, error handling and a some others.
It is not yet another std implementation. Some classes are similar to std ones, i.e. panda::string is effective replacement of std::string.

# Build and Install

Panda-Lib is suppose to be built with CMake.
```
mkdir build
cd build
cmake ..
cmake --build .
cmake --build . --target install
```

# Dependencies

Lib itself does not depend on anything but it use [Catch2](https://github.com/catchorg/Catch2) for tests. By default tests are disabled. Set `PANDALIB_TESTS=ON` to build tests and make sure that [find_package](https://cmake.org/cmake/help/latest/command/find_package.html) can find Catch2.

# Documentation

All documentation is in [doc folder](doc).

## Main features

* [panda::string](doc/string.md) - optimized std compatible string with CoW and SSO
* [Error Handling](doc/error.md) - error types overview and usefull tools such as [expected](doc/reference/expected.md) and [backtrace](doc/reference/backtrace.md)
* [CallbackDispatcher](doc/CallbackDispatcher.md) - implementation of Event Listener pattern based on custom implementation of [function type](doc/function.md)
* [Logger](doc/log.md) - simple API for logs with lazy evaluation and flexible management
* [memory](doc/reference/memory.md) - fast allocators and helpers
* [iptr](doc/refcnt.md) - smart pointer based on intrusive reference counter

## Tools and helperes

* [dyn_cast](src/panda/cast.h) - Caching wrapper of `dynamic_cast`. It stores a static cache by types and `type_id` to make dynamic_cast faster
* [endian.h](src/panda/endian.h) - endian conversions for all integer types
* [hash.h](src/panda/hash.h) - hash algorithms (hash_murmur64a, hash_jenkins_one_at_a_time)
* [make_iterator_pair](src/panda/iterator.h) - make range from iterator pair
* [owning_list](src/panda/owning_list.h) - linked list that guaraties iterator validity in any case of deletion or insertion. Importatnt part of [CallbackDispatcher](doc/CallbackDispatcher.md) implementation
* [Macro Overload](doc/reference/PANDA_PP_VFUNC.md) - preprocessor macro overloading by number of arguments
* String Containers - [map](src/panda/string_map.h)/[set](src/panda/string_set.h), [unordered_map](src/panda/unordered_string_map.h)/[unordered_set](src/panda/unordered_string_set.h) by string that alowed look up with string_view without creation of a string object.
* [traits.h](src/panda/traits.h) - some type traits for meta programming.
* [VarIntStack](src/panda/varint.h) - stack of integerss stored as compact as possible using variadic int compression. Does not allocate untill container is less than 22 bytes (x64).

## Old C++ standard support

* [optional.h](src/panda/optional.h) - implementation of the latest C++20 optional API for C++14.
* [from_chars.h](src/panda/from_chars.h) - `from_chars` and `to_chars` functions for C++14.
* [string_view.h](src/panda/string_view.h) - `string_view` for C++14.

