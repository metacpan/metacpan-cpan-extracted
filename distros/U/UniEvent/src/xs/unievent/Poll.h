#pragma once
#include "error.h"
#include "Handle.h"
#include <panda/unievent/Poll.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Poll*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {
    static panda::string package () { return "UniEvent::Poll"; }
};

}
