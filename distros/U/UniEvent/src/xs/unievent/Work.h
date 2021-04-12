#pragma once
#include <xs.h>
#include <panda/unievent/Work.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Work*, TYPE> : TypemapObject<panda::unievent::Work*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Work"; }
};

}
