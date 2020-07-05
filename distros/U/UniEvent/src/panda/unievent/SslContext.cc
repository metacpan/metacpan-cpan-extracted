#include "SslContext.h"
#include <openssl/ssl.h>

namespace panda { namespace unievent {

SslContext::SslContext(SSL_CTX* value) noexcept: ctx{value} {
    retain();
}

SslContext::~SslContext() {
    release();
}

SslContext& SslContext::operator=(const SslContext& other) noexcept {
    release();
    ctx = other.ctx;
    retain();
    return *this;
}

SslContext SslContext::attach(SSL_CTX* value) noexcept {
    SslContext r(value);
    r.release();
    return r;
}

void SslContext::retain  () const noexcept {
    if (ctx) SSL_CTX_up_ref(ctx);
}

void SslContext::release () const noexcept {
    if (ctx) SSL_CTX_free(ctx);
}

void SslContext::reset () noexcept {
    release();
    ctx = nullptr;
}



}}
