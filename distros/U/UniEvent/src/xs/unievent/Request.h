#pragma once
#include <xs.h>
#include <panda/unievent/Request.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Request*, TYPE> : TypemapObject<panda::unievent::Request*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {};

}
