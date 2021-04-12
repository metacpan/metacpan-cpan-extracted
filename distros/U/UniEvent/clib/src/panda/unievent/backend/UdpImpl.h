#pragma once
#include "HandleImpl.h"
#include <panda/net/sockaddr.h>

#undef fileno

namespace panda { namespace unievent { namespace backend {

struct IUdpImplListener {
    virtual string buf_alloc      (size_t cap) = 0;
    virtual void   handle_receive (string& buf, const net::SockAddr& addr, unsigned flags, const std::error_code& err) = 0;
};

struct SendRequestImpl : RequestImpl { using RequestImpl::RequestImpl; };

struct UdpImpl : HandleImpl {
    struct Flags {
        static constexpr int PARTIAL    = 1;
        static constexpr int IPV6ONLY   = 2;
        static constexpr int REUSEADDR  = 4;
        static constexpr int MMSG_CHUNK = 8;
        static constexpr int MMSG_FREE  = 16;
        static constexpr int RECVMMSG   = 256;
    };

    enum class Membership {
        LEAVE_GROUP = 0,
        JOIN_GROUP
    };

    IUdpImplListener* listener;

    UdpImpl (LoopImpl* loop, IUdpImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual RequestImpl* new_send_request (IRequestListener*) = 0;

    string buf_alloc (size_t size) noexcept { return HandleImpl::buf_alloc(size, listener); }

    virtual std::error_code open       (sock_t sock) = 0;
    virtual std::error_code bind       (const net::SockAddr&, unsigned flags) = 0;
    virtual std::error_code connect    (const net::SockAddr&) = 0;
    virtual std::error_code recv_start () = 0;
    virtual std::error_code recv_stop  () = 0;
    virtual std::error_code send       (const std::vector<string>& bufs, const net::SockAddr& addr, SendRequestImpl*) = 0;

    virtual expected<net::SockAddr, std::error_code> sockaddr () = 0;
    virtual expected<net::SockAddr, std::error_code> peeraddr () = 0;

    virtual expected<fh_t, std::error_code> fileno () const = 0;

    virtual expected<int, std::error_code> recv_buffer_size () const = 0;
    virtual expected<int, std::error_code> send_buffer_size () const = 0;
    virtual std::error_code recv_buffer_size (int value) = 0;
    virtual std::error_code send_buffer_size (int value) = 0;

    virtual std::error_code set_membership          (string_view multicast_addr, string_view interface_addr, Membership m) = 0;
    virtual std::error_code set_source_membership   (string_view multicast_addr, string_view interface_addr, string_view source_addr, Membership m) = 0;
    virtual std::error_code set_multicast_loop      (bool on) = 0;
    virtual std::error_code set_multicast_ttl       (int ttl) = 0;
    virtual std::error_code set_multicast_interface (string_view interface_addr) = 0;
    virtual std::error_code set_broadcast           (bool on) = 0;
    virtual std::error_code set_ttl                 (int ttl) = 0;

    virtual size_t send_queue_size () const noexcept = 0;

    void handle_receive (string& buf, const net::SockAddr& addr, unsigned flags, const std::error_code& err) {
        ltry([&]{ listener->handle_receive(buf, addr, flags, err); });
    }
};

}}}
