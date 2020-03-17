#pragma once
#include "Fs.h"
#include "error.h"
#include "Handle.h"
#include <panda/unievent/FsPoll.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::FsPoll*, TYPE> : Typemap<panda::unievent::Handle*, TYPE> {
    static panda::string package () { return "UniEvent::FsPoll"; }
};

}
