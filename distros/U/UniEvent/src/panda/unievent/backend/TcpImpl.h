#pragma once
#include "StreamImpl.h"

namespace panda { namespace unievent { namespace backend {

struct TcpImpl : StreamImpl {
    struct Flags {
        static const constexpr int IPV6ONLY = 1;
    };

    TcpImpl (LoopImpl* loop, IStreamImplListener* lst) : StreamImpl(loop, lst) {}

    virtual void open (sock_t) = 0;

    virtual std::error_code bind (const net::SockAddr&, unsigned flags) = 0;
    virtual std::error_code connect (const net::SockAddr&, ConnectRequestImpl*) = 0;

    virtual net::SockAddr sockaddr () const = 0;
    virtual net::SockAddr peeraddr () const = 0;

    virtual void set_nodelay              (bool enable) = 0;
    virtual void set_keepalive            (bool enable, unsigned delay) = 0;
    virtual void set_simultaneous_accepts (bool enable) = 0;
};

}}}
