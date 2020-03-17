#pragma once
#include "Handle.h"
#include <panda/unievent/Idle.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Idle*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {
    static panda::string package () { return "UniEvent::Idle"; }
};

}
