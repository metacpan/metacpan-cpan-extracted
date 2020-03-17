#pragma once
#include "Stream.h"
#include <panda/unievent/Tty.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Tty*, TYPE> : Typemap<panda::unievent::Stream*, TYPE> {
    static panda::string package () { return "UniEvent::Tty"; }
};

}
