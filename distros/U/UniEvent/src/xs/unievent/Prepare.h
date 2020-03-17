#pragma once
#include "Handle.h"
#include <panda/unievent/Prepare.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Prepare*, TYPE> : Typemap<panda::unievent::BackendHandle*, TYPE> {
    static panda::string package () { return "UniEvent::Prepare"; }
};

}
