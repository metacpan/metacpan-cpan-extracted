#pragma once
#include <xs/typemap/object.h>
#include <panda/uri/Router.h>

namespace xs { namespace uri {

using SvRouter = panda::uri::Router<Scalar>;

}}

namespace xs {

template <> struct Typemap<xs::uri::SvRouter*> : TypemapObject<xs::uri::SvRouter*, xs::uri::SvRouter*, ObjectTypePtr, ObjectStorageMG> {
    static panda::string_view package () { return "URI::Router"; }
};

}
