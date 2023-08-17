# Formatter

```cpp
struct Formatter : IFormatter {
    string format (std::string& msg, const Info& info) const override {
        std::stringstream ss;
        ss << info.file <<  ":" << to_string(info.line) << "\t" << msg << std::endl;
        auto ret = ss.str();
        return string(ret.data(), ret.size());
    }
};
set_formatter(new Formatter());
```

Formatter is an object that produce a string from all the information provided by logging library and user.

To customize format implement `IFormatter` an overload `string format (std::string& msg, const Info& info) const` method.
`msg` is a message passed to log macro(i.e. `panda_log_debug`) and `info` is additional information:

* `Level level` - log level: debug, info, error, etc...
* `const Module* module` - pointer to module object. See [Modules](modules.md)
* `string_view   file` - name of source file containing the logging call
* `uint32_t      line` -  line in a source file
* `string_view   func`-  short name of a function containing the logging call
* `time_point    time` - curent time
* `string_view   program_name` - a name of program. Process name by default, can be changed by [set_program_name](../reference/log.md#set_program_name)


## Pattern Formater

A formatter based on a pattern string. It is printf-like string.
Tokens can look like `%X` or `%xX` or `%.yX` or `%x.yX`. `x` and `y` are tokent's digital arguments like precision for doubles in printf.
I.e. `%2.3t` is a time HH:MM:SS and 3 digits of milliseconds.

`%L` - level

`%M` - module.
     if module has no name (root), removes x chars on the left and y chars on the right.

`%F` - function

`%f` - file
* x=0: only file name
* x=1: full path as it appeared during compilation

`%l` - line

`%m` - message
* x=0: default multiline message behaviour
* x=1: decorate each line of multiline message

`%t` - current time
* x=0: YYYY-MM-DD HH:MM:SS
* x=1: YY-MM-DD HH:MM:SS
* x=2: HH:MM:SS
* x=3: UNIX TIMESTAMP
* x=4: YYYY/MM/DD HH:MM:SS
* y>0: high resolution time, adds fractional part after seconds with "y" digits precision

`%T` - current thread id

`%p` - current process id

`%P` - current process title

`%c` - start color

`%C` - end color
