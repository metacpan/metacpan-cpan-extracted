#include "test.h"
#include <memory>
#include <openssl/err.h>
#include <openssl/dh.h>
#include <openssl/ssl.h>
#include <openssl/conf.h>
#include <openssl/engine.h>

Variation variation;

SSL_CTX* get_ssl_ctx() {
    static SSL_CTX* ctx = nullptr;
    if (ctx) {
        return ctx;
    }
    ctx = SSL_CTX_new(SSLv23_server_method());
    SSL_CTX_use_certificate_file(ctx, "t/cert/ca.pem", SSL_FILETYPE_PEM);
    SSL_CTX_use_PrivateKey_file(ctx, "t/cert/ca.key", SSL_FILETYPE_PEM);
    SSL_CTX_check_private_key(ctx);
    return ctx;
}

TcpSP make_basic_server (const LoopSP& loop, const SockAddr& sa) {
    TcpSP server = new Tcp(loop);
    server->bind(sa);
    server->listen(1);
    return server;
}

TcpSP make_ssl_server (const LoopSP& loop, const SockAddr& sa) {
    auto server = make_basic_server(loop, sa);
    server->use_ssl(get_ssl_ctx());
    return server;
}

TcpSP make_server (const LoopSP& loop, const SockAddr& sa) {
    TcpSP server = new Tcp(loop);
    server->bind(sa);
    if (variation.ssl) server->use_ssl(get_ssl_ctx());
    server->listen(10000);
    return server;
}

TcpSP make_client (const LoopSP& loop) {
    TcpSP client = new Tcp(loop, AF_INET);

    if (variation.ssl) client->use_ssl();

    if (variation.buf) {
        client->recv_buffer_size(1);
        client->send_buffer_size(1);
    }

    return client;
}

TcpP2P make_tcp_pair (const LoopSP& loop, const SockAddr& sa) {
    TcpP2P ret;
    ret.server = make_server(loop, sa);
    ret.client = make_client(loop);
    ret.client->connect(ret.server->sockaddr());
    return ret;
}

TcpP2P make_p2p (const LoopSP& loop, const SockAddr& sa) {
    TcpP2P ret = make_tcp_pair(loop, sa);
    ret.server->connection_event.add([&](auto, auto sconn, auto& err) {
        if (err) throw err;
        ret.sconn = panda::dynamic_pointer_cast<Tcp>(sconn);
        loop->stop();
    });
    loop->run();
    assert(ret.sconn);
    return ret;
}

