#pragma once
#include "Loop.h"
#include "error.h"
#include "AddrInfo.h"
#include <xs/net/sockaddr.h>
#include <panda/unievent/Resolver.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Resolver*, TYPE> : TypemapObject<panda::unievent::Resolver*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static std::string package () { return "UniEvent::Resolver"; }
};

template <class TYPE> struct Typemap<panda::unievent::Resolver::Request*, TYPE> : TypemapObject<panda::unievent::Resolver::Request*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static std::string package () { return "UniEvent::Resolver::Request"; }
};

}
