#include "xlog.h"
#include <xs/function.h>

using namespace xs;
using namespace panda;
using namespace panda::log;

struct PerlSubLogger : ILogger {
    using fn_t = function<void(const string&, Level)>;
    fn_t fn;

    PerlSubLogger (const Sub& sub) : fn(xs::in<fn_t>(sub)) {}

    void log (const string& msg, const Info& info) override {
        if (!is_perl_thread()) throw std::logic_error("can't call pure-perl logging callback: log() called from perl-foreign thread");
        fn(msg, info.level);
    }
};

struct PerlSubFormatter : IFormatter {
    using fn_t = function<string(const std::string&, Level, const string&, string_view, uint32_t, string_view)>;
    fn_t fn;

    PerlSubFormatter (const Sub& sub) : fn(xs::in<fn_t>(sub)) {}

    string format (std::string& msg, const Info& info) const override {
        if (!is_perl_thread()) throw std::logic_error("can't call pure-perl formatting callback: log() called from perl-foreign thread");
        return fn(msg, info.level, info.module->name(), info.file, info.line, info.func);
    }
};

static bool _init () {
    xs::at_perl_destroy([]{
        // remove all perl loggers and formatters from C++ modules as they are no longer available
        auto modules = get_modules();
        for (auto module : modules) {
            if (dyn_cast<PerlSubLogger*>(module->get_logger().get())) module->set_logger(nullptr);
            if (dyn_cast<PerlSubFormatter*>(module->get_formatter().get())) module->set_formatter(nullptr);
        }
    });
    return true;
}
static bool __init = _init();

namespace xs {

ILoggerSP Typemap<ILoggerSP>::in (Sv sv) {
    if (sv.is_sub_ref()) return new PerlSubLogger(sv);
    return xs::in<ILogger*>(sv);
}

IFormatterSP Typemap<IFormatterSP>::in (Sv sv) {
    if (sv.is_sub_ref()) return new PerlSubFormatter(sv);
    if (sv.is_string()) return new PatternFormatter(xs::in<string_view>(sv));
    return xs::in<IFormatter*>(sv);
}

}

