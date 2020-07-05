#pragma once
#include "../pp.h"
#include "../string.h"
#include "../function.h"
//#include <iosfwd>
#include <time.h>
#include <string>
#include <memory>
#include <vector>
#include <ostream>

namespace panda { namespace log {

#define PANDA_LOG_CODE_POINT panda::log::CodePoint{__FILE__, __LINE__, __func__}

#define panda_should_log(...)       PANDA_PP_VFUNC(PANDA_SHOULD_LOG, __VA_ARGS__)
#define PANDA_SHOULD_LOG1(lvl)      PANDA_SHOULD_LOG2(lvl, panda_log_module)
#define PANDA_SHOULD_LOG2(lvl, mod) ((lvl) >= (mod).level && panda::log::details::logger)
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

#define panda_log_verbose_debug(...)    panda_log(panda::log::VERBOSE_DEBUG, __VA_ARGS__)
#define panda_log_debug(...)            panda_log(panda::log::DEBUG,        __VA_ARGS__)
#define panda_log_info(...)             panda_log(panda::log::INFO,         __VA_ARGS__)
#define panda_log_notice(...)           panda_log(panda::log::NOTICE,       __VA_ARGS__)
#define panda_log_warn(...)             panda_log(panda::log::WARNING,      __VA_ARGS__)
#define panda_log_warning(...)          panda_log(panda::log::WARNING,      __VA_ARGS__)
#define panda_log_error(...)            panda_log(panda::log::ERROR,        __VA_ARGS__)
#define panda_log_critical(...)         panda_log(panda::log::CRITICAL,     __VA_ARGS__)
#define panda_log_alert(...)            panda_log(panda::log::ALERT,        __VA_ARGS__)
#define panda_log_emergency(...)        panda_log(panda::log::EMERGENCY,    __VA_ARGS__)

#define panda_rlog(level, msg)          panda_log(level, ::panda_log_module, msg)
#define panda_rlog_verbose_debug(msg)   panda_rlog(panda::log::VERBOSE_DEBUG, msg)
#define panda_rlog_debug(msg)           panda_rlog(panda::log::DEBUG, msg)
#define panda_rlog_info(msg)            panda_rlog(panda::log::INFO, msg)
#define panda_rlog_notice(msg)          panda_rlog(panda::log::NOTICE, msg)
#define panda_rlog_warn(msg)            panda_rlog(panda::log::WARNING, msg)
#define panda_rlog_warning(msg)         panda_rlog(panda::log::WARNING, msg)
#define panda_rlog_error(msg)           panda_rlog(panda::log::ERROR, msg)
#define panda_rlog_critical(msg)        panda_rlog(panda::log::CRITICAL, msg)
#define panda_rlog_alert(msg)           panda_rlog(panda::log::ALERT, msg)
#define panda_rlog_emergency(msg)       panda_rlog(panda::log::EMERGENCY, msg)

#define panda_log_ctor(...)  PANDA_PP_VFUNC(PANDA_LOG_CTOR, __VA_ARGS__)
#define panda_log_dtor(...)  PANDA_PP_VFUNC(PANDA_LOG_DTOR, __VA_ARGS__)
#define PANDA_LOG_CTOR0()    PANDA_LOG_CTOR1(panda_log_module)
#define PANDA_LOG_CTOR1(mod) PANDA_LOG3(panda::log::VERBOSE_DEBUG, mod, __func__ << " [ctor]")
#define PANDA_LOG_DTOR0()    PANDA_LOG_DTOR1(panda_log_module)
#define PANDA_LOG_DTOR1(mod) PANDA_LOG3(panda::log::VERBOSE_DEBUG, mod, __func__ << " [dtor]")
#define panda_rlog_ctor()    panda_log_ctor(::panda_log_module)
#define panda_rlog_dtor()    panda_log_dtor(::panda_log_module)

#define panda_debug_v(var) panda_log_debug(#var << " = " << (var))

#define PANDA_ASSERT(var, msg) if(!(auto assert_value = var)) { panda_log_emergency("assert failed: " << #var << " is " << assert_value << msg) }

extern string_view default_message;

enum Level {
    VERBOSE_DEBUG = 0,
    DEBUG,
    INFO,
    NOTICE,
    WARNING,
    ERROR,
    CRITICAL,
    ALERT,
    EMERGENCY
};

struct Module {
    using Modules = std::vector<Module*>;

    Module* parent;
    Level   level;
    string  name;
    Modules children;

    Module (const string& name, Level level = WARNING);
    Module (const string& name, Module& parent, Level level = WARNING) : Module(name, &parent, level) {}
    Module (const string& name, Module* parent, Level level = WARNING);

    Module (const Module&) = delete;
    Module (Module&&)      = delete;

    Module& operator= (const Module&) = delete;

    void set_level (Level);

    virtual ~Module ();
};

struct CodePoint {
    string_view   file;
    uint32_t      line;
    string_view   func;
};

struct Info {
    Info () : level(), module(), line() {}
    Info (Level level, const Module* module, const string_view& file, uint32_t line, const string_view& func)
        : level(level), module(module), file(file), line(line), func(func) {}

    Level         level;
    const Module* module;
    string_view   file;
    uint32_t      line;
    string_view   func;
    timespec      time;
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

ILoggerSP    fn2logger    (const logger_format_fn&);
ILoggerSP    fn2logger    (const logger_fn&);
IFormatterSP fn2formatter (const format_fn&);

void set_level     (Level, string_view module = "");
void set_logger    (const ILoggerSP&);
void set_formatter (const IFormatterSP&);

inline void set_logger    (const logger_format_fn& f) { set_logger(fn2logger(f)); }
inline void set_logger    (const logger_fn& f)        { set_logger(fn2logger(f)); }
inline void set_logger    (std::nullptr_t)            { set_logger(ILoggerSP()); }
inline void set_formatter (const format_fn& f)        { set_formatter(fn2formatter(f)); }
inline void set_formatter (std::nullptr_t)            { set_formatter(IFormatterSP()); }

ILoggerSP    get_logger    ();
IFormatterSP get_formatter ();

struct escaped { string_view src; };

namespace details {
    extern ILoggerSP logger;

    std::ostream& get_os ();
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

std::ostream& operator<< (std::ostream&, const escaped&);

}}

extern panda::log::Module panda_log_module;
