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
        static const constexpr int PARTIAL   = 1;
        static const constexpr int IPV6ONLY  = 2;
        static const constexpr int REUSEADDR = 4;
    };

    enum class Membership {
        LEAVE_GROUP = 0,
        JOIN_GROUP
    };

    IUdpImplListener* listener;

    UdpImpl (LoopImpl* loop, IUdpImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual RequestImpl* new_send_request (IRequestListener*) = 0;

    string buf_alloc (size_t size) noexcept { return HandleImpl::buf_alloc(size, listener); }

    virtual void            open       (sock_t sock) = 0;
    virtual void            bind       (const net::SockAddr&, unsigned flags) = 0;
    virtual void            connect    (const net::SockAddr&) = 0;
    virtual void            recv_start () = 0;
    virtual void            recv_stop  () = 0;
    virtual std::error_code send       (const std::vector<string>& bufs, const net::SockAddr& addr, SendRequestImpl*) = 0;

    virtual net::SockAddr sockaddr () = 0;
    virtual net::SockAddr peeraddr () = 0;

    virtual optional<fh_t> fileno () const = 0;

    virtual int  recv_buffer_size () const    = 0;
    virtual void recv_buffer_size (int value) = 0;
    virtual int  send_buffer_size () const    = 0;
    virtual void send_buffer_size (int value) = 0;

    virtual void set_membership          (string_view multicast_addr, string_view interface_addr, Membership m) = 0;
    virtual void set_multicast_loop      (bool on) = 0;
    virtual void set_multicast_ttl       (int ttl) = 0;
    virtual void set_multicast_interface (string_view interface_addr) = 0;
    virtual void set_broadcast           (bool on) = 0;
    virtual void set_ttl                 (int ttl) = 0;

    void handle_receive (string& buf, const net::SockAddr& addr, unsigned flags, const std::error_code& err) {
        ltry([&]{ listener->handle_receive(buf, addr, flags, err); });
    }
};

}}}
