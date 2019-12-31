#pragma once
#include "object.h"
#include <system_error>
#include <panda/exception.h>
#include <panda/error.h>

// hack to get private access to panda::ErrorCode
namespace panda {
    namespace private_tags {
        struct ErrorCodeXsIn {};
        struct ErrorCodeXsOut {};
    }

    template<> private_tags::ErrorCodeXsIn ErrorCode::private_access<private_tags::ErrorCodeXsIn, const xs::Sv&>(const xs::Sv& arg);
    template<> xs::Sv ErrorCode::private_access<xs::Sv, private_tags::ErrorCodeXsOut>(private_tags::ErrorCodeXsOut) const;
}

namespace xs {

template <> struct Typemap<const std::error_category*> : TypemapObject<const std::error_category*, const std::error_category*, ObjectTypeForeignPtr, ObjectStorageMG> {
    static panda::string_view package () { return "XS::STL::ErrorCategory"; }
};

template <> struct Typemap<std::error_code> : TypemapBase<std::error_code> {
    static std::error_code in (const Sv& arg) {
        if (!arg.defined()) return {};
        SV* sv = SvROK(arg) ? SvRV(arg) : arg.get();
        if (!SvOBJECT(sv)) throw panda::exception("invalid std::error_code");
        if (!SvPOK(sv) || SvCUR(sv) < sizeof(std::error_code)) throw panda::exception("invalid std::error_code");
        return *((std::error_code*)SvPVX(sv));
    }

    static Sv out (const std::error_code& var, const Sv& = {}) {
        if (!var) return Sv::undef;
        thread_local Stash stash("XS::STL::ErrorCode");
        auto base = Simple(panda::string_view(reinterpret_cast<const char*>(&var), sizeof(var)));
        return stash.bless(base).ref();
    }
};

template <> struct Typemap<panda::ErrorCode> : TypemapBase<panda::ErrorCode> {
    static panda::ErrorCode in (const Sv& arg) {
        if (!arg.defined()) return {};
        if (!arg.is_object_ref()) throw panda::exception("invalid panda::ErrorCode ref");

        panda::ErrorCode ret;
        ret.private_access<panda::private_tags::ErrorCodeXsIn, const Sv&>(SvRV(arg));
        return ret;
    }

    static Sv out (const panda::ErrorCode& var, const Sv& = {}) {
        if (!var) return Sv::undef;

        Sv ret = var.private_access<Sv>(panda::private_tags::ErrorCodeXsOut{});

        thread_local Stash stash("XS::ErrorCode");
        return stash.bless(ret).ref();
    }
};

}

namespace panda {

template<> inline private_tags::ErrorCodeXsIn ErrorCode::private_access<private_tags::ErrorCodeXsIn, const xs::Sv&>(const xs::Sv& sv) {
    static const size_t CAT_SIZE = sizeof(const error::NestedCategory*);
    static const size_t CODES_SIZE = 1;
    if (!SvPOK(sv) || SvCUR(sv) < CAT_SIZE + CODES_SIZE) throw panda::exception("invalid panda::ErrorCode");

    char* data = SvPVX(sv);

    cat = *reinterpret_cast<const error::NestedCategory**>(data);
    codes.storage = string(data + CAT_SIZE, SvCUR(sv) - CAT_SIZE);
    return {};
}

template<> inline xs::Sv ErrorCode::private_access<xs::Sv, private_tags::ErrorCodeXsOut>(private_tags::ErrorCodeXsOut) const {
    static const size_t CAT_SIZE = sizeof(const error::NestedCategory*);
    size_t size = CAT_SIZE + codes.storage.size();
    xs::Simple base = xs::Simple::create(size);

    char* data = SvPVX(base);

    memcpy(data, &cat, CAT_SIZE);
    memcpy(data + CAT_SIZE, codes.storage.data(), codes.storage.size());
    SvCUR_set(base, size);
    return base;
}

}
