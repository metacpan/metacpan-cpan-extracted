#pragma once
#include <xs.h>
#include <panda/unievent/SslContext.h>

extern "C" {
    int SSL_CTX_up_ref(SSL_CTX *ctx);
    void SSL_CTX_free(SSL_CTX *ctx);
}

namespace xs {

template<>
struct Typemap<SSL_CTX*>: TypemapBase<SSL_CTX*> {
    static SSL_CTX* in(SV* arg) {
        if (!SvOK(arg)) return nullptr;
        return reinterpret_cast<SSL_CTX*>(SvIV(arg));
    }
    static Sv out (const SSL_CTX* ctx, const Sv&) {
        if (!ctx) return Simple::undef;
        return Simple(reinterpret_cast<ptrdiff_t>(ctx));
    }
};

template <>
struct Typemap<panda::unievent::SslContext> : TypemapBase<panda::unievent::SslContext> {
    using SslContext = panda::unievent::SslContext;
    using RawTypeMap = Typemap<SSL_CTX*>;

    static SslContext in(SV* arg) {
        return RawTypeMap::in(arg);
    }

    static Sv out (SslContext& context, const Sv& sv = Sv()) {
        return RawTypeMap::out(context, sv);
    }
};

}
