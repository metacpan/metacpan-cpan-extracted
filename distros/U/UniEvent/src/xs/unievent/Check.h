#pragma once
#include "Handle.h"
#include <panda/unievent/Check.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Check*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {
    static panda::string package () { return "UniEvent::Check"; }
};

}
