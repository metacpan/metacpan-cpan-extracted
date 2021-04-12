#pragma once
#include "UVHandle.h"
#include "UVRequest.h"
#include <panda/unievent/backend/UdpImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVSendRequest : UVRequest<SendRequestImpl, uv_udp_send_t>, AllocatedObject<UVSendRequest> {
    using UVRequest<SendRequestImpl, uv_udp_send_t>::UVRequest;
};

struct UVUdp : UVHandle<UdpImpl, uv_udp_t> {
    UVUdp (UVLoop* loop, IUdpImplListener* lst, int domain, int flags) : UVHandle<UdpImpl, uv_udp_t>(loop, lst) {
        int uv_flags = domain;
        if (flags & Flags::RECVMMSG) uv_flags |= UV_UDP_RECVMMSG;

        int ret;
        if (uv_flags == AF_UNSPEC) {
            ret = uv_udp_init(loop->uvloop, &uvh);
        } else {
            ret = uv_udp_init_ex(loop->uvloop, &uvh, uv_flags);
        }

        uvx_strict(ret);
    }

    std::error_code open (sock_t sock) override {
        return uvx_ce(uv_udp_open(&uvh, sock));
    }

    std::error_code bind (const net::SockAddr& addr, unsigned flags) override {
        unsigned uv_flags = 0;
        if (flags & Flags::IPV6ONLY)  uv_flags |= UV_UDP_IPV6ONLY;
        if (flags & Flags::REUSEADDR) uv_flags |= UV_UDP_REUSEADDR;
        return uvx_ce(uv_udp_bind(&uvh, addr.get(), uv_flags));
    }

    std::error_code connect (const net::SockAddr& addr) override {
        return uvx_ce(uv_udp_connect(&uvh, addr ? addr.get() : nullptr));
    }

    std::error_code recv_start () override {
        return uvx_ce(uv_udp_recv_start(&uvh, _buf_alloc, on_receive));
    }

    std::error_code recv_stop  () override {
        return uvx_ce(uv_udp_recv_stop(&uvh));
    }

    std::error_code send (const std::vector<string>& bufs, const net::SockAddr& addr, SendRequestImpl* _req) override {
        auto req = static_cast<UVSendRequest*>(_req);
        UVX_FILL_BUFS(bufs, uvbufs);
        auto err = uv_udp_send(&req->uvr, &uvh, uvbufs, bufs.size(), addr.family() == AF_UNSPEC ? nullptr : addr.get(), on_send);
        if (err) return uvx_error(err);
        req->active = true;
        // &uvh.write_queue == uvh.write_queue[0]
        if (!uvh.send_queue_size) { // not working! never = 0 even if written synchronously
            req->handle_event({}); // written synchronously
        }
        return {};
    }

    expected<net::SockAddr, std::error_code> sockaddr () override {
        return uvx_sockaddr(&uvh, &uv_udp_getsockname);
    }

    expected<net::SockAddr, std::error_code> peeraddr () override {
        return uvx_sockaddr(&uvh, &uv_udp_getpeername);
    }

    expected<fh_t, std::error_code> fileno () const override { return uvx_fileno(uvhp()); }

    expected<int, std::error_code> recv_buffer_size () const override { return uvx_recv_buffer_size(uvhp()); }
    expected<int, std::error_code> send_buffer_size () const override { return uvx_send_buffer_size(uvhp()); }
    std::error_code recv_buffer_size (int value) override { return uvx_recv_buffer_size(uvhp(), value); }
    std::error_code send_buffer_size (int value) override { return uvx_send_buffer_size(uvhp(), value); }

    std::error_code set_membership (string_view multicast_addr, string_view interface_addr, Membership membership) override {
        uv_membership uvmemb = uv_membership();
        switch (membership) {
            case Membership::LEAVE_GROUP : uvmemb = UV_LEAVE_GROUP; break;
            case Membership::JOIN_GROUP  : uvmemb = UV_JOIN_GROUP;  break;
        }
        UE_NULL_TERMINATE(multicast_addr, multicast_addr_cstr);
        UE_NULL_TERMINATE(interface_addr, interface_addr_cstr);
        return uvx_ce(uv_udp_set_membership(&uvh, multicast_addr_cstr, interface_addr_cstr, uvmemb));
    }

    std::error_code set_source_membership (string_view multicast_addr, string_view interface_addr, string_view source_addr, Membership membership) override {
        uv_membership uvmemb = uv_membership();
        switch (membership) {
            case Membership::LEAVE_GROUP : uvmemb = UV_LEAVE_GROUP; break;
            case Membership::JOIN_GROUP  : uvmemb = UV_JOIN_GROUP;  break;
        }
        UE_NULL_TERMINATE(multicast_addr, multicast_addr_cstr);
        UE_NULL_TERMINATE(interface_addr, interface_addr_cstr);
        UE_NULL_TERMINATE(source_addr, source_addr_cstr);
        return uvx_ce(uv_udp_set_source_membership(&uvh, multicast_addr_cstr, interface_addr_cstr, source_addr_cstr, uvmemb));
    }

    std::error_code set_multicast_loop (bool on) override {
        return uvx_ce(uv_udp_set_multicast_loop(&uvh, on));
    }

    std::error_code set_multicast_ttl (int ttl) override {
        return uvx_ce(uv_udp_set_multicast_ttl(&uvh, ttl));
    }

    std::error_code set_multicast_interface (string_view interface_addr) override {
        UE_NULL_TERMINATE(interface_addr, interface_addr_cstr);
        return uvx_ce(uv_udp_set_multicast_interface(&uvh, interface_addr_cstr));
    }

    std::error_code set_broadcast (bool on) override {
        return uvx_ce(uv_udp_set_broadcast(&uvh, on));
    }

    std::error_code set_ttl (int ttl) override {
        return uvx_ce(uv_udp_set_ttl(&uvh, ttl));
    }

    size_t send_queue_size () const noexcept override {
        return uvh.send_queue_size;
    }

    SendRequestImpl* new_send_request (IRequestListener* l) override { return new UVSendRequest(this, l); }

private:
    static void on_send (uv_udp_send_t* p, int status) {
        auto req = get_request<UVSendRequest*>(p);
        req->active = false;
        req->handle_event(uvx_ce(status));
    }

    static void _buf_alloc (uv_handle_t* p, size_t size, uv_buf_t* uvbuf) {
        auto buf = get_handle<UVUdp*>(p)->buf_alloc(size);
        uvx_buf_alloc(buf, uvbuf);
    }

    static void on_receive (uv_udp_t* p, ssize_t nread, const uv_buf_t* uvbuf, const struct sockaddr* addr, unsigned flags) {
        auto h   = get_handle<UVUdp*>(p);
        auto buf = uvx_detach_buf(uvbuf);

        if (!nread && !addr) return; // nothing to read

        ssize_t err = 0;
        if (nread < 0) std::swap(err, nread);
        buf.length(nread); // set real buf len

        h->handle_receive(buf, net::SockAddr(addr, sizeof(*addr)), flags, uvx_ce(err));
    }
};

}}}}
