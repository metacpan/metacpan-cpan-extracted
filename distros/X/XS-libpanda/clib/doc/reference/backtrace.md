# Backtrace

Class that collects call stack and look for symbols for it.

# Synopsis

```cpp
Backtrace stack; // default constructor collects stack
//text representation with all symbol resolved:
string str = stack.get_backtrace_info()->to_string();

// the same without creating an object
string quick_dump = Backtrace::dump_trace();
```

# Methods

