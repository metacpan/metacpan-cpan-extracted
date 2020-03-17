#pragma once
#include <xs.h>
#include <panda/unievent/backend/Backend.h>

namespace xs {

template <> struct Typemap<panda::unievent::backend::Backend*> : TypemapObject<panda::unievent::backend::Backend*, panda::unievent::backend::Backend*, ObjectTypeForeignPtr, ObjectStorageMG> {
    static panda::string package () { return "UniEvent::Backend"; }
};

}
