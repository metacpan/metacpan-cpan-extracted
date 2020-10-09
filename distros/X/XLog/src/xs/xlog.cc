#include "xlog.h"

using namespace xs;
using namespace panda;
using namespace panda::log;

struct PerlSubLogger : ILogger {
    Sub f;
    PerlSubLogger (const Sub& f) : f(f) {}
    void log (const string& msg, const Info& info) override {
        if (!is_perl_thread()) throw std::logic_error("can't call pure-perl logging callback: log() called from perl-foreign thread");
        f.call(xs::out(msg), xs::out(info.level));
    }
};

struct PerlSubFormatter : IFormatter {
    Sub f;
    PerlSubFormatter (const Sub& f) : f(f) {}
    string format (std::string& msg, const Info& info) const override {
        if (!is_perl_thread()) throw std::logic_error("can't call pure-perl formatting callback: log() called from perl-foreign thread");
        auto ret = f.call(xs::out(msg), xs::out(info.level), xs::out(info.module->name), xs::out(info.file), xs::out(info.line), xs::out(info.func));
        return xs::in<string>(ret);
    }
};

static bool _init () {
    xs::at_perl_destroy([]{
        if (dyn_cast<PerlSubLogger*>(get_logger().get())) set_logger(nullptr);
        if (dyn_cast<PerlSubFormatter*>(get_formatter().get())) set_formatter(nullptr);
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
    return xs::in<IFormatter*>(sv);
}

}

