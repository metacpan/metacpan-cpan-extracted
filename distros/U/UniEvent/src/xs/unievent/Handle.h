#pragma once
#include "Loop.h"
#include <panda/unievent/BackendHandle.h>

namespace xs {

namespace unievent {
    Sv handle_perl_class(const panda::unievent::HandleType&);
    void register_perl_class(const panda::unievent::HandleType&, const Stash&);
}

template <class TYPE> struct Typemap<panda::unievent::Handle*, TYPE> : TypemapObject<panda::unievent::Handle*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast> {
    using Super = TypemapObject<panda::unievent::Handle*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast>;
    static Sv create (const TYPE& var, Sv proto = Sv()) {
        if (!var) return &PL_sv_undef;
        if (!proto) {
            proto = unievent::handle_perl_class(var->type());
        }
        return Super::create(var, proto);
    }
};

template <class TYPE> struct Typemap<panda::unievent::BackendHandle*, TYPE> : Typemap<panda::unievent::Handle*, TYPE> {};

}
