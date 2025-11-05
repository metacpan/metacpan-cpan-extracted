# uinteger

A module for unsigned integer math.

```
use integer;
print ~0; # print -1
print +(-1) >> 1; # print -1
use uinteger;
print ~0; # print a large number
print -1; # print a large number
print +(-1) >> 1; # print a large number
```

This module makes the add, subtract, multiply and unary minus
operators work with their arguments and results as unsigned integers.

Since perl normally uses unsigned integer math for many other bit-type
operators (left and right shift, bitwise boolean operators) this
allows you to easily re-implement functions from C that work with
unsigned integer math.

Note that `use integer;` largely also works for the add, subtract,
multiply and unary minus operators, but produces signed integers.
Through the properties of two's complement match you can then convert
these results to unsigned values by performing a bit-wise operator
such as ` $x | 0` on the result.

Unfortunately you need to do that outside of `use integer;` since that
makes most of the bit-type operators also work with signed integers,
producing negative numbers if the high bit is set, and propagating the
sign bit for right shifts.

`use uinteger` lets you avoid this mixed processing.

You may or may not get faster code - if you want speed for this type
of processing you should use XS or `Inline::C`
