#pragma once
#include <xs.h>
#include <panda/unievent/error.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Error*, TYPE*> : TypemapObject<panda::unievent::Error*, TYPE*, ObjectTypePtr, ObjectStorageMG> {
    static panda::string_view package () { return "UniEvent::Error"; }
};

}
