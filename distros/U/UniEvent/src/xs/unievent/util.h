#pragma once
#include <xs.h>
#include <panda/unievent/inc.h>

namespace xs { namespace unievent {

inline panda::unievent::fd_t sv2fd (const Sv& sv) {
    if (!sv) throw std::invalid_argument("fd must be defined");
    if (sv.is_ref() || sv.type() > SVt_PVMG) return Io(sv).fileno();
    if (!SvOK(sv)) throw std::invalid_argument("fd must be defined");
    return SvIV(sv);
}

inline panda::unievent::sock_t sv2sock (const Sv& sv) { return (panda::unievent::sock_t)sv2fd(sv); }

panda::string sv2buf (const Sv& sv);

}}
