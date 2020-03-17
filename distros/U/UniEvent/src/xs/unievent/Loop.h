#pragma once
#include "Backend.h"
#include <panda/unievent/Loop.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Loop*, TYPE> : TypemapObject<panda::unievent::Loop*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast> {
    static panda::string package () { return "UniEvent::Loop"; }
};

}
