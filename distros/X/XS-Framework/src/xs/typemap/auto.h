#pragma once
#include "base.h"
#include <panda/refcnt.h>

namespace xs {

// automatic default typemap for <const TYPE*> if typemap for <TYPE*> defined
template <class TYPEMAP, class TYPE> struct Typemap<const TYPEMAP*, TYPE> : Typemap<TYPEMAP*, TYPE> {};

// automatic default reference resolving
template <class TYPE, bool = has_typemap<std::remove_reference_t<TYPE>*>::value> struct TypemapResolveReference {};
template <class TYPE> struct TypemapResolveReference<TYPE&, true> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static TYPE& in (SV* arg) {
        auto ret = Super::in(arg);
        if (!ret) throw "invalid value: undef not allowed";
        return *ret;
    }
    static Sv out (TYPE& var, const Sv& = {}) = delete;
};
template <class TYPE> struct TypemapResolveReference<TYPE&, false> : Typemap<std::remove_const_t<TYPE>> {};
template <class TYPEMAP, class TYPE> struct Typemap<TYPEMAP&, TYPE> : TypemapResolveReference<TYPE> {};

// automatic default typemap for <iptr<TYPE>> if typemap for <TYPE> defined
template <class TYPEMAP, class TYPE> struct Typemap<panda::iptr<TYPEMAP>, panda::iptr<TYPE>> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static panda::iptr<TYPE> in (SV* arg) { return Super::in(arg); }

    static Sv out (const panda::iptr<TYPE>& var, const Sv& proto = {}) {
        return Super::out(var.get(), proto);
    }
};

}
