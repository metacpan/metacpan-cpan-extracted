#pragma once
#include "util.h"
#include "Stream.h"
#include "AddrInfo.h"
#include "Resolver.h"
#include "backend/TcpImpl.h"
#include <iosfwd>

namespace panda { namespace unievent {

struct ITcpListener     : IStreamListener     {};
struct ITcpSelfListener : IStreamSelfListener {};

struct Tcp : virtual Stream, AllocatedObject<Tcp> {
    using TcpImpl = backend::TcpImpl;
    using Flags   = TcpImpl::Flags;

    static const HandleType TYPE;
    static const AddrInfoHints defhints;

    Tcp (const LoopSP& loop = Loop::default_loop(), int domain = AF_UNSPEC);

    ~Tcp () { panda_log_dtor(); }

    const HandleType& type () const override;

    virtual excepted<void, ErrorCode> open (sock_t socket, Ownership = Ownership::TRANSFER);
    virtual excepted<void, ErrorCode> bind (const net::SockAddr&, unsigned flags = 0);
    virtual excepted<void, ErrorCode> bind (string_view host, uint16_t port, const AddrInfoHints& hints = defhints, unsigned flags = 0);

    TcpConnectRequestSP connect ();
    TcpConnectRequestSP connect (const net::SockAddr& sa, uint64_t timeout = 0);
    TcpConnectRequestSP connect (const string& host, uint16_t port, uint64_t timeout = 0, const AddrInfoHints& hints = defhints);

    virtual void connect (const TcpConnectRequestSP&);

    excepted<net::SockAddr, ErrorCode> sockaddr () const { return handle_fd_excepted(impl()->sockaddr()); }
    excepted<net::SockAddr, ErrorCode> peeraddr () const { return handle_fd_excepted(impl()->peeraddr()); }

    excepted<void, ErrorCode> set_nodelay              (bool enable)                     { return make_excepted(impl()->set_nodelay(enable)); }
    excepted<void, ErrorCode> set_keepalive            (bool enable, unsigned int delay) { return make_excepted(impl()->set_keepalive(enable, delay)); }
    excepted<void, ErrorCode> set_simultaneous_accepts (bool enable)                     { return make_excepted(impl()->set_simultaneous_accepts(enable)); }

    excepted<sock_t, ErrorCode> socket () const;

    void setsockopt (int level, int optname, const void* optval, int optlen) { unievent::setsockopt(socket().value(), level, optname, optval, optlen); }

    static excepted<std::pair<TcpSP, TcpSP>, ErrorCode>
    pair (const LoopSP& = Loop::default_loop(), int type = SOCK_STREAM, int proto = PF_UNSPEC);

    static excepted<std::pair<TcpSP, TcpSP>, ErrorCode>
    pair (const TcpSP&, const TcpSP&, int type = SOCK_STREAM, int proto = PF_UNSPEC);

protected:
    StreamSP create_connection () override;

private:
    friend TcpConnectRequest;

    int domain;

    backend::TcpImpl* impl () const { return static_cast<backend::TcpImpl*>(BackendHandle::impl()); }

    HandleImpl* new_impl () override;
};

struct TcpConnectRequest : ConnectRequest, AllocatedObject<TcpConnectRequest> {
    net::SockAddr addr;
    string        host;
    uint16_t      port;
    bool          cached;
    AddrInfoHints hints;

    TcpConnectRequest (Tcp* h = nullptr) : port(), cached(true), handle(h) {}

    TcpConnectRequestSP to (const string& host, uint16_t port, const AddrInfoHints& hints = Tcp::defhints) {
        this->host  = host;
        this->port  = port;
        this->hints = hints;
        return this;
    }

    TcpConnectRequestSP to         (const net::SockAddr& val)      { addr = val; return this; }
    TcpConnectRequestSP timeout    (uint64_t val)                  { this->ConnectRequest::timeout = val; return this; }
    TcpConnectRequestSP on_connect (const Stream::connect_fn& val) { event.add(val); return this; }
    TcpConnectRequestSP use_cache  (bool val)                      { cached = val; return this; }
    TcpConnectRequestSP set_hints  (const AddrInfoHints& val)      { hints = val; return this; }
    TcpConnectRequestSP run        ()                              { handle->connect(this); return this; }

private:
    friend Tcp; friend StreamFilter;
    Tcp*                handle;
    Resolver::RequestSP resolve_request;

    void set (Tcp* h) {
        handle = h;
        ConnectRequest::set(h);
    }

    void exec             () override;
    void finalize_connect ();
    void handle_event     (const ErrorCode&) override;
};

inline TcpConnectRequestSP Tcp::connect () {
    return new TcpConnectRequest(this);
}

inline TcpConnectRequestSP Tcp::connect (const net::SockAddr& addr, uint64_t timeout) {
    return connect()->to(addr)->timeout(timeout)->run();
}

inline TcpConnectRequestSP Tcp::connect (const string& host, uint16_t port, uint64_t timeout, const AddrInfoHints& hints) {
    return connect()->to(host, port, hints)->timeout(timeout)->run();
}

std::ostream& operator<< (std::ostream&, const Tcp&);
std::ostream& operator<< (std::ostream&, const TcpConnectRequest&);

}}
