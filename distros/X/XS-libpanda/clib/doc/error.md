# Error Handling


## What is error


There are different reasons why errors appear.
1. **An author's error**. The programmer who wrote a library module/class/function made an error. This is a bug. It should not happen. If it does there is no way to process the error and continue. State of the program is invalid and in case of continuation it can corrupt more data.
2. **An error made by a programmer that uses a library**. It means that a library is used incorrectly. It is a bug in the program but the library is correct. It is highly unlikely that the program can continue correctly because it contains a bug. It is better to fail fast and abort.
3. **Input error**. Any event that doesn’t depend on a programmer. It is not an error. Usually it is incorrect input data or events that shouldn’t happen in the common case. E.g. letters in number parsing, incorrect request, JSON syntax error. The program is correct and it should continue after processing of the case.
4. **Lack of resources, i.e memory**. C++ provides the bad_alloc exception and a way to catch it. The truth is that you cannot do anything useful when it happens. We just ignore such errors and let the program fail.


In the 1st case our policy is to abort the program. It can be implemented using `assert()` or `abort()`. This situation never happens in good code and if it does then the program wouldn’t corrupt any data.


In the 2nd case we use exceptions. A programmer-user receives an exception in the process of development and it won’t stay unnoticed. There is no need to catch such exceptions because there is no way to process it and continue. The program contains an error and should be stopped. It is much better than `abort()` because an exception object contains additional information about the reasons and ways to fix it.


The 3rd case is not an error at all. Users can do what they want. They can send any requests, type words instead of numbers, make syntax mistakes. If HTTP server receives an invalid request it is not exceptional, it is expected. And as soon as we do not call it exceptional we do not use exceptions in this case. It is not just a game of words. C++ exceptions are extremely slow and it is really bad to use them to process frequent situations.


As the result we got the rule **“Exception is a programmer’s error.”**  And the conclusion of the rule is **“No need to catch exceptions”**. Exceptions can be caught only to log the error and stop the program gracefully.


We don’t need any tools to process the 1st case. Standard functions such as `abort()` and `asert()` are enough. For the 2nd and the 3rd we have some useful tools in Panda-Lib.

The library doesn’t force a user to use the same error handling ideology but it uses it.


# Exceptions
We don’t use exceptions as part of business logic so we don’t need a big hierarchy of classes for this. The only thing we need from an exception object is the information about an error. It should be easy to read the message and it should be informative. But there is no need to process it.  The standard runtime_error is pretty much enough except for one detail. It doesn't contain the call stack. You cannot detect where an error happens after the exception is caught. It is very important when it is hard to reproduce the error.
Class [panda::Backtrace](reference/backtrace.md) provides a call stack and [panda::exception](reference/exception.md) is the base class containing the call stack. Collecting the callstach is relatively fast but making a text representation with symbols is really slow. That's why the panda::exception itself contains a vector of pointers to functions instead of storing a text. Symbolized stack is generated only if needed (`what()` call, e.g).


# Expect the Expected
Practically any interaction with a user or environment may fail. The main tools to store and process such failures are [panda::expected](reference/expected.md) and [panda::excepted](reference/excepted.md)


Expected is a new popular way of processing errors. Andrei Alexandrescu [explained it in 2018](https://youtu.be/CGwk3i1bGQI). `Expected` is an algebraic sum op types of result and error. It can contain either a valid result or an error description but not both. If you try to get result when there is an error exception is thrown. Here is the function that parses a number:
```cpp
    expected<long, string> parse(const char* c) {
    char* end;
    long result = strtol(c, &end, 10);
    if (errno) {
        return make_unexpected("parsing failed");
    }
    return result;


    }
```
Then if we use it:
```cpp


    auto i1 = parse("123");
    REQUIRE(i1.value() == 123); // using existing value, ok


    auto i2 = parse("99999999999999999999999999999999999999");
    int result = i2.value(); // ignoring error, exception is thrown


```


And if we do not want any exceptions:
```cpp
    auto i2 = parse("99999999999999999999999999999999999999");
    int result = i2.value_or(0); // 0 if error
    REQUIRE(result == 0);


```


This way of error handling combines all the strongest sides of exceptions and error codes. There is now `try ... catch` but users are forced to check for errors.


[panda::expected](reference/expected.md) is an implementation of a proposal to standard. It is pretty much the same as many other implementations.


But there is one problem in the concept of `expected`. It ignores the case of void functions. You cannot force the user to use the result value if it is not supposed to be one. In this case `expected` is the same thing as return code. This problem can be solved with one addition to `expected`. We can remember if the user checks the error or not and throw an exception in the destructor if there is an error. Yes, throwing in a destructor is very bad and it is an ugly hack. But it is also a very useful hack.


The implementation of this idea is called [panda::excepted](reference/excepted.md).

# ErrorCode

Both `expected` and `excpeted` are just containers. They can contain any type of error but doesn't represent the error itself. It should be a user type that contains an error to be used with `expected`. Usually it is just a number, an error code. It can be `int` but the standard contains a better approach - [std::error_code](https://en.cppreference.com/w/cpp/error/error_code). It contains an integer value and an error category. It is a really good wrapper for simple old integer error codes and the category can be used to distinguish different codes from different sources. `std::error_code` works really well with `expected` and it is highly recommended to use.

Panda-lib doesn't provide any replacement or custom implementation of std::error_code because there is no need. The thing than panda-lib do have is another container - ErrorCode. The name is the same but it is actually a linked list of [std::error_codes](https://en.cppreference.com/w/cpp/error/error_code). It is designed to be a trace of error from the source to high level description. E.g, you want to make a request to a server. It is a high level request that is based on http. And let's assume that connection failed. The high level user should receive an error. It can be just a "request error" but without an actual reason it is hard to debug. ErrorCode may contain something like

```
My awesome request error (1:my::application) -> HTTP connect error (3:unievent::http::Error) -> Connection refused (111:generic)
```

It is a list of errors that appears during the processing of the original connection error. One hand it is just a high level error about user request and on the other hand it contains all low level information. Some other languages provide a concept of chained exceptions for the same purpose.

ErrorCode is a highly optimized class. You can use it as the usual value type as std::error_code. It works well with `expected` and `excepted`. It uses [AllocatedObject](reference/memory.md#AllocatedObject) to allocate its storage. It is a pool for small objects and allocation is really fast.

More details about ErrorCode [here](reference/ErrorCode.md)












