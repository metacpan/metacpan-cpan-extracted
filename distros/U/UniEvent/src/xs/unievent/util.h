#pragma once
#include <xs.h>
#include <panda/unievent/inc.h>
#include <panda/unievent/util.h>

namespace xs { namespace unievent {

struct IoInfo {
    bool is_sock;
    union {
        panda::unievent::sock_t sock;
        panda::unievent::fd_t   fd;
    };
};

IoInfo sv_io_info (const Sv&);

inline panda::unievent::fd_t sv2fd (const Sv& sv) {
    if (!sv) throw std::invalid_argument("fd must be defined");
    if (sv.is_ref() || sv.type() > SVt_PVMG) return Io(sv).fileno();
    if (!SvOK(sv)) throw std::invalid_argument("fd must be defined");
    return SvIV(sv);
}

inline panda::unievent::sock_t sv2sock (const Sv& sv) {
    return panda::unievent::fd2sock(sv2fd(sv));
}

panda::string sv2buf (const Sv& sv);

}}

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::RandomRequest*, TYPE> : Typemap<panda::unievent::Work*, TYPE> {
    static panda::string package () { return "UniEvent::Request::Random"; }
};

}
