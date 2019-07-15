#pragma once
#include <xs/Sub.h>
#include <functional>

namespace xs {

using CatchHandlerSimple = std::function<Sv()>;
using CatchHandler       = std::function<Sv(const Sub&)>;

void add_catch_handler (CatchHandlerSimple f);
void add_catch_handler (CatchHandler       f);

Sv _exc2sv (pTHX_ const Sub&);

template <typename F> static inline auto throw_guard (pTHX_ CV* context, F&& f) -> decltype(f()) {
    SV* exc;
    try { return f(); }
    catch (...) {
        auto tmp = xs::_exc2sv(aTHX_ context);
        if (tmp) exc = tmp.detach();
        else exc = newSVpvs("<empty exception>");
    }
    croak_sv(sv_2mortal(exc));
}

}
