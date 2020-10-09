#pragma once
#include "UVStream.h"
#include <panda/unievent/backend/TcpImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVTcp : UVStream<TcpImpl, uv_tcp_t> {
    UVTcp (UVLoop* loop, IStreamImplListener* lst, int domain) : UVStream<TcpImpl, uv_tcp_t>(loop, lst) {
        if (domain == AF_UNSPEC) uvx_strict(uv_tcp_init(loop->uvloop, &uvh));
        else                     uvx_strict(uv_tcp_init_ex(loop->uvloop, &uvh, domain));
    }

    void open (sock_t sock) override {
        auto ret = uv_tcp_open(&uvh, sock);
        uvx_strict(ret);
    }

    std::error_code bind (const net::SockAddr& addr, unsigned flags) override {
        unsigned uv_flags = 0;
        if (flags & Flags::IPV6ONLY) uv_flags |= UV_TCP_IPV6ONLY;
        return uvx_ce(uv_tcp_bind(&uvh, addr.get(), uv_flags));
    }

    virtual std::error_code connect (const net::SockAddr& addr, ConnectRequestImpl* _req) override {
        auto req = static_cast<UVConnectRequest*>(_req);
        auto err = uv_tcp_connect(&req->uvr, &uvh, addr.get(), on_connect);
        if (!err) req->active = true;
        return uvx_ce(err);
    }

    net::SockAddr sockaddr () const override {
        return uvx_sockaddr(&uvh, &uv_tcp_getsockname);
    }

    net::SockAddr peeraddr () const override {
        return uvx_sockaddr(&uvh, &uv_tcp_getpeername);
    }

    void set_nodelay (bool enable) override {
        uvx_strict(uv_tcp_nodelay(&uvh, enable));
    }

    void set_keepalive (bool enable, unsigned delay) override {
        uvx_strict(uv_tcp_keepalive(&uvh, enable, delay));
    }

    void set_simultaneous_accepts (bool enable) override {
        uvx_strict(uv_tcp_simultaneous_accepts(&uvh, enable));
    }
};

}}}}
