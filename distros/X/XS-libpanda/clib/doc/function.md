# function
panda::function is a universal container for any callable value, i.e. lambda expression. Main feature of panda::function is overloaded operator==() which allows it to compare its objects. This is necessary for [CallbackDispatcher](CallbackDispatcher.md)

# Synopsis
```cpp
    int a = 13;
    function<int(int)> f = [&](int b){return a + b;};
    REQUIRE(f(42) == 55); // calling lambda 42 + 13 == 55

    struct Test {
        int operator()(int v) {return v;}
        bool operator == (const Test&) const { return true; }
    };

    f = Test(); // make function from callable object
    REQUIRE(f(42) == 42); // calling Test::operator()

    function<int(int)> f2 = Test();
    REQUIRE(f == f2); // if functors are equal so do panda::functions

    function<int(void)> l1 = [&](){return a;};
    auto l2 = l1;
    function<int(void)> l3 = [&](){return a;};

    REQUIRE(l1 == l2); // copies are equal
    REQUIRE(l1 != l3); // l3 made from different lambda

    // compatible types of arguments and return are allowed if implicitly convertible
    function<double (int)> cb = [](double) -> int {return 10;};
    REQUIRE(cb(3) == 10);
```

# Comparison
Function objects are comparable using operator==(). They are are equal if any of following is true
1. contains the same function pointers
    ```cpp
    void void_func();
    void void_func2();

    function<void(void)> f1_void = &void_func;
    function<void(void)> f2_void = &void_func;
    function<void(void)> f3_void = &void_func2;

    REQUIRE(f1_void == f2_void);
    REQUIRE(f1_void != f3_void);
    ```
2. contains functor objects that are equal (operator== on the left operand)
    ```cpp
    class Test : public panda::Refcnt {
    public:
        int value = 0;
        Test(int value) : value(value) {}

        int operator()(int v) {return v;}
        bool operator == (const Test& oth) const { return value == oth.value;}
    };
    function<int(int)> f1 = Test(1);
    function<int(int)> f2 = Test(2);
    function<int(int)> f11 = Test(1);
    REQUIRE(f1 != f2);
    REQUIRE(f1 == f11);
    ```

3. one is a copy of the other made with copy constructor or assignment
    ```cpp
    int a = 10;
    function<int(void)> l1 = [&](){return a;};
    function<int(void)> l2 = l1;
    function<int(void)> l3 = [&](){return a;};

    assert(l1 == l2);
    assert(l1 != l3);
    ```

First 2 cases use comparison of original values wrapped with the panda::function. The third differs. Lambdas in C++ does not provide operator== and you cannot compare them. The only thing that is comparable is a pointer to lambda. When the panda::function wraps a lambda it allocates and copies the value to internal storage. Copy of such a function does not provide a deep copy of stored lambda but copies the pointer. Thet why panda::function differs from std. In case of std::function copy is deep copy:
```cpp
    int a = 10;
    auto lambda = [=]() mutable {return ++a;};
    std::function<int(void)> f1 = lambda;
    std::function<int(void)> f2 = f1;

    REQUIRE(f1() == 11);
    REQUIRE(f2() == 11);
```
But for panda::function it is not:
```cpp
    int a = 10;
    auto lambda = [=]() mutable {return ++a;};
    panda::function<int(void)> f1 = lambda;
    panda::function<int(void)> f2 = f1;

    REQUIRE(f1() == 11);
    REQUIRE(f2() == 12);
```

In sum cases it is not so obvious
```cpp
    int a = 10;
    auto lambda = [&](){return a;};
    function<int(void)> l1 = lambda;
    auto l2 = l1;
    function<int(void)> l3 = lambda;

    REQUIRE(l1 == l2);
    REQUIRE(l1 != l3);
```
l3 makes a new copy of lambda and its pointer differs from l1.

# Covariance & Contravariance

There are some compatibility of function signatures. If the return value of the original function can be implicitly cast to panda::function declared return type then the panda::function object can hold this value. And in the opposite direction: if panda::function arguments can be implicitly cast to the function arguments then it works, too.

```cpp
    function<double (int)> cov= [](int a) -> int {
        return a;
    };
    REQUIRE(cov (3) == 3.0);

    function<double (int)> contr= [](double) -> int {
        return 10;
    };
    REQUIRE(contr (3) == 10);
```

# Self Reference

To make it easier to use with [CallbackDispatcher](CallbackDispatcher.md) panda::function can be created from a function with one additional argument. This should be the first argument of type  Ifunction<>&. This argument contains a reference to the function itself (internal storage of panda::function). It is comparable to panda::function objects and supposed to be passed to CallbackDispatcher::remove() if you want to remove the listener from its code.
```cpp
    Dispatcher d;
    static bool called;
    function<void(int)> l = [&](panda::Ifunction<void, int>& self, int) {
        d.remove(self);
        called = true;
    };

    d.add(l);
    CHECK(d(2).value_or(42) == 42);
    CHECK(called);
    called = false;
    CHECK(d(2).value_or(42) == 42);
    CHECK(!called);
```

# Method

panda::function can hold a pointer to a method and an object to call this method on. To do so call function `make_function`
```cpp
    class Test : public panda::Refcnt {
    public:
        int value = 0;
        int bar() {return value + 40;}
    };

    iptr<Test> t = new Test();
    t->value = 14;
    function<int()> m = make_function(&Test::bar, t);
    REQUIRE(m() == 54);
```
The object would be passed as a smart pointer [iptr](refcnt.md#iptr), so the class should be compatible with it.




