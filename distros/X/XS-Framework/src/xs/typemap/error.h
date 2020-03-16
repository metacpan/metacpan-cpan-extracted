#pragma once
#include "object.h"
#include "../Object.h"
#include <system_error>
#include <panda/exception.h>
#include <panda/error.h>

namespace xs {
    
template <> struct Typemap<const std::error_category*> : TypemapObject<const std::error_category*, const std::error_category*, ObjectTypeForeignPtr, ObjectStorageMG> {
    static panda::string_view package () { return "XS::STL::ErrorCategory"; }
};

template <> struct Typemap<std::error_code> : TypemapBase<std::error_code> {
    static PERL_THREAD_LOCAL HV* stash;

    static std::error_code in (const Sv& arg) {
        if (!arg.defined()) return {};
        SV* sv = SvROK(arg) ? SvRV(arg) : arg.get();
        if (!SvOBJECT(sv)) throw panda::exception("invalid std::error_code");
        if (!SvPOK(sv) || SvCUR(sv) < sizeof(std::error_code)) throw panda::exception("invalid std::error_code");
        return *((std::error_code*)SvPVX(sv));
    }

    static Sv out (const std::error_code& var, const Sv& = {}) {
        if (!var) return Sv::undef;
        auto base = Simple(panda::string_view(reinterpret_cast<const char*>(&var), sizeof(var)));
        return Stash(stash).bless(base).ref();
    }
};

template <> struct Typemap<panda::ErrorCode*> : TypemapObject<panda::ErrorCode*, panda::ErrorCode*, ObjectTypePtr, ObjectStorageMG> {
    static panda::string_view package () { return "XS::ErrorCode"; }
};

template <> struct Typemap<panda::ErrorCode> : Typemap<panda::ErrorCode*> {
    using Super = Typemap<panda::ErrorCode*>;

    static panda::ErrorCode in (const Sv& arg) {
        if (!arg.defined()) return {};
        if (!arg.is_object_ref()) throw panda::exception("invalid XS::ErrorCode object");
        if (Object(arg).stash() == Typemap<std::error_code>::stash) return xs::in<std::error_code>(arg);
        return *Super::in(arg);
    }

    static Sv out (const panda::ErrorCode& var, const Sv& proto = {}) {
        if (!var) return Sv::undef;
        return Super::out(new panda::ErrorCode(var), proto);
    }
};

}
