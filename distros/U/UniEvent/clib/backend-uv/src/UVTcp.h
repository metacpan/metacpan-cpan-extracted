#pragma once
#include "UVStream.h"
#include <panda/unievent/backend/TcpImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVTcp : UVStream<TcpImpl, uv_tcp_t> {
    UVTcp (UVLoop* loop, IStreamImplListener* lst, int domain) : UVStream<TcpImpl, uv_tcp_t>(loop, lst) {
        if (domain == AF_UNSPEC) uvx_strict(uv_tcp_init(loop->uvloop, &uvh));
        else                     uvx_strict(uv_tcp_init_ex(loop->uvloop, &uvh, domain));
    }

    std::error_code open (sock_t sock) override {
        auto ret = uv_tcp_open(&uvh, sock);
        return uvx_ce(ret);
    }

    std::error_code bind (const net::SockAddr& addr, unsigned flags) override {
        unsigned uv_flags = 0;
        if (flags & Flags::IPV6ONLY) uv_flags |= UV_TCP_IPV6ONLY;
        return uvx_ce(uv_tcp_bind(&uvh, addr.get(), uv_flags));
    }

    std::error_code connect (const net::SockAddr& addr, ConnectRequestImpl* _req) override {
        auto req = static_cast<UVConnectRequest*>(_req);
        auto err = uv_tcp_connect(&req->uvr, &uvh, addr.get(), on_connect);
        if (!err) req->active = true;
        return uvx_ce(err);
    }

    expected<net::SockAddr, std::error_code> sockaddr () const override {
        return uvx_sockaddr(&uvh, &uv_tcp_getsockname);
    }

    expected<net::SockAddr, std::error_code> peeraddr () const override {
        return uvx_sockaddr(&uvh, &uv_tcp_getpeername);
    }

    std::error_code set_nodelay (bool enable) override {
        return uvx_ce(uv_tcp_nodelay(&uvh, enable));
    }

    std::error_code set_keepalive (bool enable, unsigned delay) override {
        return uvx_ce(uv_tcp_keepalive(&uvh, enable, delay));
    }

    std::error_code set_simultaneous_accepts (bool enable) override {
        return uvx_ce(uv_tcp_simultaneous_accepts(&uvh, enable));
    }
};

}}}}
