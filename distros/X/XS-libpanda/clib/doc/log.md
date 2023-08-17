# Log

An efficient API for logging.

# Synopsis

```cpp
set_logger([](const string& msg, const Info&) {
    std::cout << msg << std::endl;
});
set_formatter("%1t %c[%L/%1M]%C %f:%l,%F(): %m");
set_level(Level::Info);

panda_log_info("info message");
panda_log_warning("hello");
panda_log(Level::Error, "Achtung!");
panda_log_debug("here"); // will not be logged, because min level is INFO, and message will NOT be evaluated

Module my_log_module("CustomName");
panda_log_error(my_log_module, "custom only"); // use certain log module for logging

int data[] = {1,42,5};
//callback will not be called if log level is insufficient
panda_log_notice([&] {
    for (auto v : data) {
        log << (v + 1);
    }
});

// macro uses name panda_log_module as logging module
// first found by C++ name lookup is used
// you may want to define panda_log_module in your application namespace
{
    Module panda_log_module("my_module", Level::Error); // local variables have the highest priority

    panda_log_error("anything"); // logged with module "my_module"
    panda_log_warning("warn"); // will not be logged / evaluated
}

// choose a backend for logging
set_logger(new ConsoleLogger());

// or log to multiple backends
set_logger(new MultiLogger({
    MultiLogger::Channel(new ConsoleLogger()),
    MultiLogger::Channel([](const string& msg, const Info&) {
        // custom logging function
    })
}));
```

All logging library can be divided in 4 parts:
1. API for logging from user code,
2. routing: some logs should be written, some should not,
3. formatting,
4. actual writing to file, network, console or anywhere else.

# 1. Logging API

First part is presented with set of macro functions that can be called to log something. It is preprocessor macro because it is the only way to make lazy evaluation of arguments. E.g.

```cpp
panda_log_debug(heavy_function());
```
transforms to something like

```cpp
if (panda::log::should_log(panda::log::DEBUG)) {
    panda::log::do_log(heavy_function());
}
```

If current setting allow debug logs to be shown than `heavy_function()` is called. In the other case it is just one `if` with comparision of global variable and constant. You should not care about performance impact of logs if it won't be written in production mode. No need of `#ifdef` and rebuild to get detailed logs.

## Types

Logger calls `operator<<(std::ostream&, Type)` for any value you pass to it. If the type of value overloads the `operator<<` than value can be logged.

## Levels

There are 9 levels of logs: VerboseDebug, Debug, Info, Notice, Warning, Error, Critical, Alert,Emergency. You can set what level whould be visible (see ["Routing and Modules" section](#routing-and-modules) for details). If you set the level you receive all logs with the same level and higher. E.g. if you set Warning then wou receive Warning, Error, Critical, Alert and Emergency logs. Level is just a digit and higher means more valuable.

There is a macro for each level:
```cpp
#define panda_log_verbose_debug(...)    panda_log(panda::log::Level::VerboseDebug, __VA_ARGS__)
#define panda_log_debug(...)            panda_log(panda::log::Level::Debug,        __VA_ARGS__)
#define panda_log_info(...)             panda_log(panda::log::Level::Info,         __VA_ARGS__)
#define panda_log_notice(...)           panda_log(panda::log::Level::Notice,       __VA_ARGS__)
#define panda_log_warn(...)             panda_log(panda::log::Level::Warning,      __VA_ARGS__)
#define panda_log_warning(...)          panda_log(panda::log::Level::Warning,      __VA_ARGS__)
#define panda_log_error(...)            panda_log(panda::log::Level::Error,        __VA_ARGS__)
#define panda_log_critical(...)         panda_log(panda::log::Level::Critical,     __VA_ARGS__)
#define panda_log_alert(...)            panda_log(panda::log::Level::Alert,        __VA_ARGS__)
#define panda_log_emergency(...)        panda_log(panda::log::Level::Emergency,    __VA_ARGS__)
```

As you see `panda_log_<level>(smth)` is the same as `panda_log(<Level>, smth). You can use the style you like more. The only small detail about this is `panda_log_warn`. It is just a short form of `panda_log_warning`.

## Lazy Functions

Sometimes calculation of log is something more complicated than one expression. In this case you can pass a lambda function as an argument.

```cpp
panda_log_warning([&]{
    auto ret = heavy_function();
    //some long processing, stringigication and formating
    for (auto& e : ret.some_vector) {
        log << e << ",";
    }
    log << to_string(ret);
});
```

Lambda should capture everything by reference to make the local variable `log` available. 'log' is a local variable defined by macro. Pass all the data you want to stream operator `<<` on this object. You can also call `<<` many times, e.g. to log all elements of an array.

# 2. Routing and Modules

Panda-log supports logging modules. Modules are used to separate log levels in one part of the application from another so that you can enable for example debug logs only for part of your application, not for the whole app. Also modules allow to log various parts of application to different destinations.

More detailed info on modules [here](log/modules.md).

# 3. Formating

See [Formatter](log/formatter.md)

# 4. Output

To set downstream for logs call `set_logger`. The argument van be eigther a callback `void (const string& msg, const Info&)` or a pointer to `ILogger`. You can make an successor by overriding methods
```cpp
virtual void log_format (std::string&, const Info&, const IFormatter&);
virtual void log        (const string&, const Info&);
```

or just use ready implementations such as [ConsoleLogger](../src/panda/log/console.h).