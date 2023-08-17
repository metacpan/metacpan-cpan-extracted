# Log Modules

Log Module is a separate space of logging with its own logging settings such as level.


```cpp
namespace network {
static panda::log::Module panda_log_module("network");
//...
panda_log_debug("data received:" << raw_data);
}

namespace logic {
static panda::log::Module panda_log_module("logic");
//...
panda_log_debug("buisness logic debug message");
}

// somewhere
panda::log::set_level(panda::log::Level::Debug);
// or
network::panda_log_module.set_level(panda::log::Level::Debug);
// ...
set_logger([](const string& msg, const Info&) {
    std::cout << msg << std::endl;
});
```


Log modules are used to separate logs of one part of the application from another. For example image you have network layer in your application and
logic layer.
```cpp
// network layer
panda_log_debug("data received:" << raw_data);

// logic layer
panda_log_debug("buisness logic debug message");

// somewhere
panda::log::set_level(panda::log::Level::Debug);
```

You want to debug your network layer and enable debug logs but you don't want to enable debug logs everywhere across your app.
In this case you can create 2 log modules, use it when logging and enable debug log only for certain log module.

```cpp
namespace network {
static panda::log::Module network_log_module("network");
//...
panda_log_debug(network_log_module, "data received:" << raw_data);
}

namespace logic {
static panda::log::Module logic_log_module("logic");
//...
panda_log_debug(logic_log_module, "buisness logic debug message");
}

network::panda_log_module.set_level(panda::log::Level::Debug);
```

Now min level `Debug` is only set for `network` log module while `logic` still have `Warning` as min level (default).

Module parameter to log functions can be omitted if variable's name holding log module is `panda_log_module` and it is discoverable from logging point. All loggin macros uses name `panda_log_module`. By default name lookup founds a root module defined in Panda-Lib. But if you define a local variable or global that preceeds the root one in name lookup then this variable will be used as a module

```cpp
namespace network {
static panda::log::Module panda_log_module("network");
//...
panda_log_debug("data received:" << raw_data); // goes to network
}

namespace logic {
static panda::log::Module panda_log_module("logic");
//...
panda_log_debug("buisness logic debug message"); // goes to logic
}

panda_log_debug("some other place"); // goes to root module
```

Modules can be organised in hierarchies (parent-child).
```cpp
    Module mod("mod", Level::Warning);
    Module submod("submod", mod, Level::Warning);
```

In this case `submod` is a child of module `mod`. Setting log level for `mod` also sets level for `submod` but not vice-versa.
Child modules partially inherits names from their parents, so in this case the name of `submod` module will be `aaa::bbb`.

Also modules support setting custom `logger` and `formatter`. By default, if none is set to any module, all modules will use logger/formatter from the root module (set via `log::set_logger/set_formatter`).

If you set logger or formatter explicitly for some module
```cpp
    module.set_logger(my_logger);
    module.set_formatter(my_formatter);
```

then `module` and all of its children will use logger/formatter provided.

To revert to default behaviour (inherit logger/formatter from parent) set them to `nullptr`

# Methods

## ctor
```cpp
Module (const string& name, Level level = Level::Warning);                 // module with root parent
Module (const string& name, Module& parent, Level level = Level::Warning); // module with parent
Module (const string& name, Module* parent, Level level = Level::Warning);
Module (const string& name, std::nullptr_t, Level level = Level::Warning); // root module

Module (const Module&) = delete;
Module (Module&&)      = delete;
```

Creates a new module. If no parent passed then root module is a parent. If `nullptr` passed then new Module is a root module itself and does not inherit any settings from default root. Such module and its children will not react to `log::set_level/set_logger/etc`, but only to direct configuring.
`level` is minimal logging level for all logs written with this module. The default is `Warning`.

## name
```cpp
const string&  name        () const;
```
Returns full module name


## level
```cpp
Level          level       () const;
```
Returns minimal log level for this module


## set_level
```cpp
void set_level     (Level);
```
Sets minimal log level for this module and all of its children

## set_logger
```cpp
void set_logger    (ILoggerFromAny, bool passthrough = false);
```
Sets logger backend for this module. Logging that is done with this module or any of its children will use this logger unless some child has its own
logger configured explicitly.

See [log::set_logger](../reference/log.md#set_logger) for details on what arguments can be.

To revert to using parent's logger, just set it to `nullptr`.
```cpp
    module.set_logger(nullptr);
```

Setting `nullptr` as logger for root module (module with no parent) disables logging for such module and its children except for child modules that has its own logger configured explicitly.

If `passthrough` is set, after logging to this logger, will log also to parent's logger is if this logger wasn't present

## set_formatter
```cpp
void set_formatter (IFormatterFromAny);
```

Sets formatter for this module. Logging that is done with this module or any of its children will use this formatter unless some child has its own
formatter configured explicitly.

See [log::set_fromatter](../reference/log.md#set_formatter) for details on what arguments can be.

To revert to using parent's formatter, just set it to `nullptr`.

```cpp
    module.set_formatter(nullptr);
```

Setting `nullptr` as formatter for root module (module with no parent) reverts to using default formatter.


## passthrough
```cpp
bool           passthrough () const;
```
Returns true if `passthrough` was set on last `set_logger` call to this module.
