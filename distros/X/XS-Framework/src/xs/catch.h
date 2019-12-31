#pragma once
#include <xs/Sub.h>
#include <functional>
#include <panda/exception.h>

namespace xs {

using CatchHandlerSimple = std::function<Sv()>;
using CatchHandler       = std::function<Sv(const Sub&)>;

using ExceptionProcessor       = std::function<Sv(Sv& ex, const Sub&)>;
using ExceptionProcessorSimple = std::function<Sv(Sv& ex)>;

void add_catch_handler (CatchHandlerSimple f);
void add_catch_handler (CatchHandler       f);

void add_exception_processor(ExceptionProcessor       f);
void add_exception_processor(ExceptionProcessorSimple f);

Sv _exc2sv (const Sub&);

template <typename F> static inline auto throw_guard (CV* context, F&& f) -> decltype(f()) {
    SV* exc;
    try { return f(); }
    catch (...) {
        auto tmp = xs::_exc2sv(context);
        if (tmp) exc = tmp.detach();
        else exc = newSVpvs("<empty exception>");
    }
    croak_sv(sv_2mortal(exc));
}

}
