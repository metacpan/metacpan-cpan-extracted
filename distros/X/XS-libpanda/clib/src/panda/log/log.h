#pragma once
#include "../pp.h"
#include "../string.h"
#include "../function.h"
#include <time.h>
#include <string>
#include <memory>
#include <vector>
#include <ostream>
#include <cstdlib>
#include <chrono>

namespace panda { namespace log {
struct Module;
}}

extern panda::log::Module panda_log_module;

namespace panda { namespace log {

#define PANDA_LOG_CODE_POINT panda::log::CodePoint{__FILE__, __LINE__, __func__}

#define panda_should_log(...)       PANDA_PP_VFUNC(PANDA_SHOULD_LOG, __VA_ARGS__)
#define PANDA_SHOULD_LOG1(lvl)      PANDA_SHOULD_LOG2(lvl, panda_log_module)
#define PANDA_SHOULD_LOG2(lvl, mod) ((lvl) >= (mod).level())
#define panda_should_rlog(lvl)      PANDA_SHOULD_LOG2(lvl, ::panda_log_module)

#define panda_log(...)            PANDA_LOG(__VA_ARGS__)                                      // proxy to expand args
#define PANDA_LOG(lvl, ...)       PANDA_PP_VFUNC(PANDA_LOG, PANDA_PP_VJOIN(lvl, __VA_ARGS__)) // separate first arg to detect empty args
#define PANDA_LOG1(lvl)           PANDA_LOG2(lvl, default_message)
#define PANDA_LOG2(lvl, msg)      PANDA_LOG3(lvl, panda_log_module, msg)
#define PANDA_LOG3(lvl, mod, msg) do {                                                                      \
    if (PANDA_SHOULD_LOG2(lvl, mod)) {                                                                      \
        std::ostream& log = panda::log::details::get_os();                                                  \
        panda::static_if<panda::log::details::IsEval<panda::log::details::getf(#msg)>::value>([&](auto) {   \
            (panda::log::details::LambdaStream&)log << msg;                                                 \
        })(panda::log::details::Unique1{});                                                                 \
        panda::static_if<!panda::log::details::IsEval<panda::log::details::getf(#msg)>::value>([&](auto) {  \
            log << msg;                                                                                     \
        })(panda::log::details::Unique2{});                                                                 \
        panda::log::details::do_log(log, lvl, &(mod), PANDA_LOG_CODE_POINT);                                \
    }                                                                                                       \
} while (0)

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

#define panda_rlog(level, msg)          panda_log(level, ::panda_log_module, msg)
#define panda_rlog_verbose_debug(msg)   panda_rlog(panda::log::Level::VerboseDebug, msg)
#define panda_rlog_debug(msg)           panda_rlog(panda::log::Level::Debug, msg)
#define panda_rlog_info(msg)            panda_rlog(panda::log::Level::Info, msg)
#define panda_rlog_notice(msg)          panda_rlog(panda::log::Level::Notice, msg)
#define panda_rlog_warn(msg)            panda_rlog(panda::log::Level::Warning, msg)
#define panda_rlog_warning(msg)         panda_rlog(panda::log::Level::Warning, msg)
#define panda_rlog_error(msg)           panda_rlog(panda::log::Level::Error, msg)
#define panda_rlog_critical(msg)        panda_rlog(panda::log::Level::Critical, msg)
#define panda_rlog_alert(msg)           panda_rlog(panda::log::Level::Alert, msg)
#define panda_rlog_emergency(msg)       panda_rlog(panda::log::Level::Emergency, msg)

#define panda_log_ctor(...)  PANDA_PP_VFUNC(PANDA_LOG_CTOR, __VA_ARGS__)
#define panda_log_dtor(...)  PANDA_PP_VFUNC(PANDA_LOG_DTOR, __VA_ARGS__)
#define PANDA_LOG_CTOR0()    PANDA_LOG_CTOR1(panda_log_module)
#define PANDA_LOG_CTOR1(mod) PANDA_LOG3(panda::log::Level::VerboseDebug, mod, __func__ << " [ctor]")
#define PANDA_LOG_DTOR0()    PANDA_LOG_DTOR1(panda_log_module)
#define PANDA_LOG_DTOR1(mod) PANDA_LOG3(panda::log::Level::VerboseDebug, mod, __func__ << " [dtor]")
#define panda_rlog_ctor()    panda_log_ctor(::panda_log_module)
#define panda_rlog_dtor()    panda_log_dtor(::panda_log_module)

#define panda_debug_v(var) panda_log_debug(#var << " = " << (var))

#define PANDA_ASSERT(var, msg) if(!(auto assert_value = var)) { panda_log_emergency("assert failed: " << #var << " is " << assert_value << msg) }

extern string_view default_message;

enum class Level {
    VerboseDebug = 0,
    Debug,
    Info,
    Notice,
    Warning,
    Error,
    Critical,
    Alert,
    Emergency
};

struct CodePoint {
    string_view   file;
    uint32_t      line;
    string_view   func;
};

struct Module;

struct Info {
    Info () : level(), module(), line() {}
    Info (Level level, const Module* module, const string_view& file, uint32_t line, const string_view& func, const string_view& program_name)
        : level(level), module(module), file(file), line(line), func(func), program_name{program_name} {}

    using time_point = std::chrono::system_clock::time_point;

    Level         level;
    const Module* module;
    string_view   file;
    uint32_t      line;
    string_view   func;
    time_point    time;
    string_view   program_name;
};

struct IFormatter : AtomicRefcnt {
    virtual string format (std::string&, const Info&) const = 0;
    virtual ~IFormatter () {}
};
using IFormatterSP = iptr<IFormatter>;

struct ILogger : AtomicRefcnt {
    virtual void log_format (std::string&, const Info&, const IFormatter&);
    virtual void log        (const string&, const Info&);
    virtual ~ILogger () = 0;
};
using ILoggerSP = iptr<ILogger>;

using format_fn        = function<string(std::string&, const Info&)>;
using logger_format_fn = function<void(std::string&, const Info&, const IFormatter&)>;
using logger_fn        = function<void(const string&, const Info&)>;

inline ILoggerSP make_logger (std::nullptr_t) { return {}; }
inline ILoggerSP make_logger (ILoggerSP l) { return l; }
       ILoggerSP make_logger (const logger_fn& f);
       ILoggerSP make_logger (const logger_format_fn& f);

inline IFormatterSP make_formatter (std::nullptr_t) { return {}; }
inline IFormatterSP make_formatter (const IFormatterSP& f) { return f; }
       IFormatterSP make_formatter (const format_fn& f);
       IFormatterSP make_formatter (string_view pattern);

struct ILoggerFromAny {
    ILoggerSP value;
    ILoggerFromAny () {}
    template <class T> ILoggerFromAny (T&& l) : value(make_logger(std::forward<T>(l))) {}
};

struct IFormatterFromAny {
    IFormatterSP value;
    IFormatterFromAny () {}
    template <class T> IFormatterFromAny (T&& f) : value(make_formatter(std::forward<T>(f))) {}
};
struct Module {
    using Modules = std::vector<Module*>;

    Module (const string& name, Level level = Level::Warning);                 // module with root parent
    Module (const string& name, Module& parent, Level level = Level::Warning); // module with parent
    Module (const string& name, Module* parent, Level level = Level::Warning);
    Module (const string& name, std::nullptr_t, Level level = Level::Warning); // root module

    Module (const Module&) = delete;
    Module (Module&&)      = delete;

    Module& operator= (const Module&) = delete;

    const string&  name        () const;
    const Module*  parent      () const;
    Level          level       () const;
    const Modules& children    () const;
    bool           passthrough () const;

    void set_level     (Level);
    void set_logger    (ILoggerFromAny, bool passthrough = false);
    void set_formatter (IFormatterFromAny);

    ILoggerSP    get_logger    ();
    IFormatterSP get_formatter ();

    virtual ~Module ();
    void init();

private:
    Module* _parent;
    Level   _level;
    Modules _children;
    string  _name;
    bool    _passthrough = false;

    void _set_effective_logger    (const ILoggerSP&);
    void _set_effective_formatter (const IFormatterSP&);
};

void set_level       (Level, string_view module = "");
void set_logger      (ILoggerFromAny l);
void set_formatter   (IFormatterFromAny f);
void set_program_name(const string& value) noexcept;

ILoggerSP    get_logger    ();
IFormatterSP get_formatter ();

Module*              get_module  (string_view);
std::vector<Module*> get_modules ();

namespace details {
    std::ostream& get_os ();
    std::ostream& get_os_tmp ();
    bool          do_log (std::ostream&, Level, const Module*, const CodePoint&);

    template <char T> struct IsEval      : std::false_type {};
    template <>       struct IsEval<'['> : std::true_type  {};

    static constexpr inline char getf (const char* s) { return *s; }

    struct LambdaStream : std::ostream {};
    struct Unique1 {};
    struct Unique2 {};

    template <class T>
    std::enable_if_t<panda::has_call_operator<T>::value, LambdaStream&> operator<< (LambdaStream& os, T&& f) {
        f();
        return os;
    }
}

struct escaped { string_view src; };

struct prettify_json {
    string_view src;
    std::string str;
    size_t unfold_limit;

    explicit prettify_json (const string_view& sv, size_t unfold_limit = 1) : src(sv), unfold_limit(unfold_limit) {}

    template <typename T, typename = std::enable_if_t<!std::is_same<std::decay_t<T>, string>::value && !std::is_same<std::decay_t<T>, string_view>::value, T>>
    explicit prettify_json (T&& v, size_t unfold_limit = 1) : unfold_limit(unfold_limit) {
        auto& os = details::get_os_tmp();
        os << v;
        set_from_os(os);
    }

private:
    void set_from_os(std::ostream&);
};

std::ostream& operator<< (std::ostream&, const escaped&);
std::ostream& operator<< (std::ostream&, const prettify_json&);

}}

extern panda::log::Module panda_log_module;

