# Panda-Lib

Panda-Lib is a C++ library with basic functionality. It contains implementation of string, function, pool allocator, error handling and a some others.
It is not yet another std implementation. Some classes are similar to std ones, i.e. panda::string is effective replacement of std::string.

# Build and Install

Panda-Lib is suppose to be built with CMake.
```
mkdir build
cd build
cmake ..
cmake --build ..
cmake --build .. --target install
```

# Dependencies

Lib itself does not depend on anything but it use [Catch2](https://github.com/catchorg/Catch2) for tests. Make sure that [find_package](https://cmake.org/cmake/help/latest/command/find_package.html) can find it.

# Documentation

In progress. You can find som in folder [doc](doc).
