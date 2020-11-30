#pragma once
#include "util.h"
#include "error.h"
#include "Handle.h"
#include "Request.h"
#include "Ssl.h"
#include <panda/unievent/Stream.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Stream*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {};

template <class TYPE> struct Typemap<panda::unievent::ConnectRequest*, TYPE> : TypemapObject<panda::unievent::Request*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Request::Connect"; }
};

template <class TYPE> struct Typemap<panda::unievent::WriteRequest*, TYPE> : TypemapObject<panda::unievent::Request*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Request::Write"; }
};

template <class TYPE> struct Typemap<panda::unievent::ShutdownRequest*, TYPE> : TypemapObject<panda::unievent::Request*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Request::Shutdown"; }
};

}
