#pragma once
#include "util.h"
#include "error.h"
#include "Handle.h"
#include "Request.h"
#include "AddrInfo.h"
#include <xs/net/sockaddr.h>
#include <panda/unievent/Udp.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Udp*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {
    static panda::string package () { return "UniEvent::Udp"; }
};

template <class TYPE> struct Typemap<panda::unievent::SendRequest*, TYPE> : Typemap<panda::unievent::Request*, TYPE> {
    static panda::string package () { return "UniEvent::Request::Send"; }
};

}
