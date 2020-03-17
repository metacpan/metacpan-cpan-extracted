#pragma once
#include "Stream.h"
#include "AddrInfo.h"
#include <xs/net/sockaddr.h>
#include <panda/unievent/Tcp.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Tcp*, TYPE> : Typemap<panda::unievent::Stream*, TYPE> {
    static panda::string package () { return "UniEvent::Tcp"; }
};

}
