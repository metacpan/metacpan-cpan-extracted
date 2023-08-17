# Macro Overloading

# Synopsys

```cpp
#define simple_sum_macro(...)  PANDA_PP_VFUNC(SIMPLE_MACRO, __VA_ARGS__)
#define SIMPLE_MACRO1(a)       (a)
#define SIMPLE_MACRO2(a, b)    (a + b)

// forcing at least one argument
#define MY_MACRO(first, ...)        PANDA_PP_VFUNC(MY_MACRO, PANDA_PP_VJOIN(first, __VA_ARGS__))
#define MY_MACRO1(first)            MY_MACRO2(first, default_message)
#define MY_MACRO2(first, msg)       MY_MACRO3(first, default_mod, msg)
#define MY_MACRO3(first, mod, msg)  std::cerr << first << mod  << msg << std::endl;
```