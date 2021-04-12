#include "SslContext.h"
#include "error.h"
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

excepted<SslContext, std::error_code> SslContext::create (string cert_file, string key_file, const SSL_METHOD* method) {
    auto ctx = SSL_CTX_new(method ? method : SSLv23_server_method());
    auto ret = SslContext::attach(ctx);

    int ok;

    ok = SSL_CTX_use_certificate_file(ctx, cert_file.c_str(), SSL_FILETYPE_PEM);
    if (!ok) return make_unexpected(make_ssl_error_code(SSL_ERROR_SSL));

    ok = SSL_CTX_use_PrivateKey_file(ctx, key_file.c_str(), SSL_FILETYPE_PEM);
    if (!ok) return make_unexpected(make_ssl_error_code(SSL_ERROR_SSL));

    ok = SSL_CTX_check_private_key(ctx);
    if (!ok) return make_unexpected(make_ssl_error_code(SSL_ERROR_SSL));

    return ret;
}

}}
