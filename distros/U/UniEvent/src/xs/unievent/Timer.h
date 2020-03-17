#pragma once
#include "Handle.h"
#include <panda/unievent/Timer.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Timer*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {
    static panda::string package () { return "UniEvent::Timer"; }
};

}
