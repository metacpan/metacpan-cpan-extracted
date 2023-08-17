# panda::string
Optimized replacement for std::string with the same API. It uses such optimisations as [CoW](#copy-on-write-cow) and [SSO](#small-string-optimization-sso) that affects [thread safety](#thread-safety).
There are different classes for different types of symbols as in std: `string` for `char`, `wstring` for `wchar_t`, `u16string` for `char16_t`, `u32string` for `char32_t`.


# Synopsis
```cpp
using panda::string;
string a = "hello, ";
string b("world!!!", 6);
string c = a + b;
REQUIRE(c == "hello, world!");


//CoW, no copy on assignment or substr
string copy = a;
REQUIRE(copy.data() == a.data());


string sub = a.substr(0, 4);
REQUIRE(sub.data() == a.data());
```


# Copy on Write (CoW)
[Copy on write](https://en.wikipedia.org/wiki/Copy-on-write) is the main feature and difference with std::string. The main idea is to evade data copying if possible. The simplest case is object copy constructor:
```cpp
using panda::string;
string a = "hello";
string b(a);
```
In this case panda::string doesn't allocate a new chunk of memory, it just puts a pointer to data of 'a' in 'b'. Behavior of objects is the same as if they are copies and changing data in any of it does not affect another. So panda::string follows the same value semantics as std::string.
```cpp
string a = "hello, ";
string copy = a;
REQUIRE(copy.data() == a.data());
copy[1] = 'a';
REQUIRE(a == "hello, ");
REQUIRE(copy == "hallo, ");
```
This optimization works also for `substr` method and everywhere where it is logically possible.
All memory management is panda::string responsibility and it is implemented via reference counting. By default panda::strings copies any data it is constructed from. Exceptions are another panda::string(CoW in this case), [string literals](#literals) (no need to copy immutable data) and manually managed [external buffers](#external-buffer).


# Small String Optimization (SSO)
SSO is another useful optimization. If a string is really short it can be stored right inside of the string object itself instead of allocating a buffer in heap. To do this some private fields are used. So the maximum size of such a string is the sum of sizes of these private fields. For 64-bit platforms it is 23 bytes (size of pointer to beginning of string + size of pointer to original string + size of length field - 1 byte for flag that it is SSO mode). It means that if you create/copy a string shorter than 23 bytes no allocation happens.


# Literals
If panda::string is constructed from a string literal then no allocation or copy happens. String literals are immutable and immortal so it is safe to keep the pointer. It cannot be freed or changed from outside. If the content of such a panda::string object should be changed, by operator[] e.g, full copy to heap happens. Since usually objects constructed from literals don't change they never actually allocate.


# Thread Safety
The panda::string class doesn't provide any strong thread safety garanties. Its objects can be created, used and deleted from any threads but one object can be used only from one thread at a time. Use external mutex or any other tool to provide concurrent access.
CoW makes it unsafe to use different copies of the same object from different threads. If you want to pass a copy of a panda::string instance to another thread then call the `buf()` method on the copy. That call will make a force copy and ensure that this object is the only owner of the data.


# External Buffer
The panda::string can be used as some kind of smart pointer to external data. Idea is the same as the custom destructor for std::shared_ptr.
You can pass the ownership of some chunk of data to panda::string. To do so pass the pointer to data, size and destruction function to the constructor;
```cpp
basic_string (CharT* str, size_type len, size_type capacity, dtor_fn dtor);
```
CharT is a type of char. It is `char` for `string`, `wchar_t` for `wstring`, etc.


`dtor_fn` is a pointer to function `void (*)(CharT*, size_t)`. This function will be called by panda::string when no reference to the data left in any instances of panda::string. Typically it can be regular memory free or delete[] or empty callback if the actual ownership is not supposed to be passed.



