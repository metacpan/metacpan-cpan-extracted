#pragma once
#include <utility>
#include <cstdint>
#include <stdexcept>
#include <system_error>
#include "ssl/forward.h"
#include <panda/string.h>
#include <panda/excepted.h>

struct ssl_ctx_st;    typedef ssl_ctx_st SSL_CTX;

namespace panda { namespace unievent {

struct SslContext {
    static excepted<SslContext, std::error_code> create (string cert_file, string key_file, const SSL_METHOD* = nullptr);

    SslContext () noexcept                        : ctx(nullptr) {}
    SslContext (SSL_CTX*) noexcept;
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

}}
