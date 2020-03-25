#pragma once
#include "UVHandle.h"
#include "UVRequest.h"
#include <panda/unievent/backend/UdpImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVSendRequest : UVRequest<SendRequestImpl, uv_udp_send_t>, AllocatedObject<UVSendRequest> {
    using UVRequest<SendRequestImpl, uv_udp_send_t>::UVRequest;
};

struct UVUdp : UVHandle<UdpImpl, uv_udp_t> {
    UVUdp (UVLoop* loop, IUdpImplListener* lst, int domain) : UVHandle<UdpImpl, uv_udp_t>(loop, lst) {
        uvx_strict(domain == AF_UNSPEC ? uv_udp_init(loop->uvloop, &uvh) : uv_udp_init_ex(loop->uvloop, &uvh, domain));
    }

    void open (sock_t sock) override {
        uvx_strict(uv_udp_open(&uvh, sock));
    }

    void bind (const net::SockAddr& addr, unsigned flags) override {
        unsigned uv_flags = 0;
        if (flags & Flags::IPV6ONLY)  uv_flags |= UV_UDP_IPV6ONLY;
        if (flags & Flags::REUSEADDR) uv_flags |= UV_UDP_REUSEADDR;
        uvx_strict(uv_udp_bind(&uvh, addr.get(), uv_flags));
    }

    void connect (const net::SockAddr& addr) override {
        uvx_strict(uv_udp_connect(&uvh, addr ? addr.get() : nullptr));
    }

    void recv_start () override {
        uvx_strict(uv_udp_recv_start(&uvh, _buf_alloc, on_receive));
    }

    void recv_stop  () override {
        uvx_strict(uv_udp_recv_stop(&uvh));
    }

    std::error_code send (const std::vector<string>& bufs, const net::SockAddr& addr, SendRequestImpl* _req) override {
        auto req = static_cast<UVSendRequest*>(_req);
        UVX_FILL_BUFS(bufs, uvbufs);
        auto err = uv_udp_send(&req->uvr, &uvh, uvbufs, bufs.size(), addr.get(), on_send);
        if (err) return uvx_error(err);
        req->active = true;
        // &uvh.write_queue == uvh.write_queue[0]
        if (!uvh.send_queue_size) { // not working! never = 0 even if written synchronously
            req->handle_event({}); // written synchronously
        }
        return {};
    }

    net::SockAddr sockaddr () override {
        return uvx_sockaddr(&uvh, &uv_udp_getsockname);
    }

    net::SockAddr peeraddr () override {
        return uvx_sockaddr(&uvh, &uv_udp_getpeername);
    }

    optional<fh_t> fileno () const override { return uvx_fileno(uvhp()); }

    int  recv_buffer_size ()    const override { return uvx_recv_buffer_size(uvhp()); }
    void recv_buffer_size (int value) override { uvx_recv_buffer_size(uvhp(), value); }
    int  send_buffer_size ()    const override { return uvx_send_buffer_size(uvhp()); }
    void send_buffer_size (int value) override { uvx_send_buffer_size(uvhp(), value); }

    void set_membership (string_view multicast_addr, string_view interface_addr, Membership membership) override {
        uv_membership uvmemb = uv_membership();
        switch (membership) {
            case Membership::LEAVE_GROUP : uvmemb = UV_LEAVE_GROUP; break;
            case Membership::JOIN_GROUP  : uvmemb = UV_JOIN_GROUP;  break;
        }
        UE_NULL_TERMINATE(multicast_addr, multicast_addr_cstr);
        UE_NULL_TERMINATE(interface_addr, interface_addr_cstr);
        uvx_strict(uv_udp_set_membership(&uvh, multicast_addr_cstr, interface_addr_cstr, uvmemb));
    }

    void set_multicast_loop (bool on) override {
        uvx_strict(uv_udp_set_multicast_loop(&uvh, on));
    }

    void set_multicast_ttl (int ttl) override {
        uvx_strict(uv_udp_set_multicast_ttl(&uvh, ttl));
    }

    void set_multicast_interface (string_view interface_addr) override {
        UE_NULL_TERMINATE(interface_addr, interface_addr_cstr);
        uvx_strict(uv_udp_set_multicast_interface(&uvh, interface_addr_cstr));
    }

    void set_broadcast (bool on) override {
        uvx_strict(uv_udp_set_broadcast(&uvh, on));
    }

    void set_ttl (int ttl) override {
        uvx_strict(uv_udp_set_ttl(&uvh, ttl));
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

        h->handle_receive(buf, addr, flags, uvx_ce(err));
    }
};

}}}}
