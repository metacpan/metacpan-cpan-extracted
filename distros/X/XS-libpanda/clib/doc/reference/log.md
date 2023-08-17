# Log

Log library description is [here](../log.md).

## set_level
```cpp
void set_level       (Level, string_view module = "");
```

## set_logger
```cpp
void set_logger      (ILoggerFromAny l);
```

Set backend globally (for root module). `ILoggerFromAny` is a proxy type to resolve all overloads. Anything that can be passed to [make_logger](#make_logger) works for `set_logger`.

Usually `l` is an instance of `ConsoleLogger`, `MultiLogger` or any other implementation of `ILogger`.
Also, you can pass a function.
All the possibilities are described in [make_logger](#make_logger).

## set_formatter
```cpp
void set_formatter   (IFormatterFromAny f);
```
Set log message formatter globally (for root module). May be a function, formatter object or pattern string. `IFormatterFromAny` is a proxy type to resolve all overloads. See details in [make_formatter](#make_formatter).

## set_program_name
```cpp
void set_program_name(const string& value) noexcept;
```
Sets a program name that is used as `program_name` in the `Info` structure in logging calbacks. Also available as `%P` in format pattern.

# make_logger
```cpp
ILoggerSP make_logger (std::nullptr_t) { return {}; } // 1
ILoggerSP make_logger (ILoggerSP l) { return l; } // 2
ILoggerSP make_logger (const function<void(const string&, const Info&)>& f); // 3
ILoggerSP make_logger (const function<void(std::string&, const Info&, const IFormatter&)>& f); // 4
```

Creates or forwards an object implementing `ILogger` interface from any possible argument.

It forwards `nullptr` and `ILoggerSP` values as is.

It creates an object from a function that implements logging.

`3` expects a simple function that receives a message as a string and additional `Info` structure containg log level, module, time, source code point and etc.

`4` is an extended version that also receives a formatter.

# make_formatter

```cpp
IFormatterSP make_formatter (std::nullptr_t) { return {}; } // 1
IFormatterSP make_formatter (const IFormatterSP& f) { return f; } // 2
IFormatterSP make_formatter (const function<string(std::string&, const Info&)>& f); // 3
IFormatterSP make_formatter (string_view pattern); // 4
```

Creates or forwards an object implementing `IFormatterSP` interface from any possible argument.

It forwards `nullptr` and `IFormatterSP` values as is.

`3` creates an object that uses `f` as a format method.

`4` creates an instance of [PatternFormatter](../log/formatter.md#pattern-formater) whith `pattern` as constructor argument.

See also [Formatter](../log/formatter)
