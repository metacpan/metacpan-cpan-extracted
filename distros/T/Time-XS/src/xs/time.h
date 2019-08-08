#pragma once
#include <xs.h>
#include <panda/time.h>

namespace xs {
    template <> struct Typemap<const panda::time::Timezone*> : TypemapObject<const panda::time::Timezone*, const panda::time::Timezone*, ObjectTypeRefcntPtr, ObjectStorageMG> {
        static std::string package () { return "Time::XS::Timezone"; }
    };
}
