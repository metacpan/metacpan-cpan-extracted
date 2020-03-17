#pragma once
#include "error.h"
#include "Handle.h"
#include <panda/unievent/FsEvent.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::FsEvent*, TYPE> : Typemap<panda::unievent::Handle*, TYPE> {
    static panda::string package () { return "UniEvent::FsEvent"; }
};

}
