#pragma once
#include <utility>
#include <cstdint>
#include <stdexcept>
#include <panda/refcnt.h>

struct ssl_ctx_st;    typedef ssl_ctx_st SSL_CTX;

namespace panda { namespace unievent {

struct SslContext {
    SslContext (SSL_CTX*) noexcept;
    SslContext () noexcept                        : ctx(nullptr) {}
    SslContext (const SslContext& other) noexcept : SslContext(other.ctx) {}
    SslContext (SslContext&& other) noexcept      : ctx(nullptr) { std::swap(ctx, other.ctx); }

    ~SslContext ();

    inline operator SSL_CTX* () const noexcept { return ctx; }
    inline operator bool     () const noexcept { return ctx; }

    bool operator==(const SslContext& other) const noexcept { return ctx == other.ctx; }
    SslContext& operator=(const SslContext& other) noexcept;
    SslContext& operator=(SslContext&& other) noexcept { std::swap(ctx, other.ctx); return *this; }

    static SslContext attach(SSL_CTX* value) noexcept;

    void retain  () const noexcept;
    void release () const noexcept;
    void reset   () noexcept;

    SSL_CTX* ctx = nullptr;
};


inline void refcnt_inc(SslContext* ptr) { ptr->retain(); }
inline void refcnt_dec(SslContext* ptr) { ptr->release(); }
inline std::uint32_t refcnt_get(SslContext*) { throw std::runtime_error("unsupported operation"); }

}}
