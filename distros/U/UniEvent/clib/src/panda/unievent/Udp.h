#pragma once
#include "Queue.h"
#include "Request.h"
#include "AddrInfo.h"
#include "BackendHandle.h"
#include "backend/UdpImpl.h"

namespace panda { namespace unievent {

struct IUdpListener {
    virtual void on_receive (const UdpSP&, string&, const net::SockAddr&, unsigned/*flags*/, const ErrorCode&) {}
    virtual void on_send    (const UdpSP&, const ErrorCode&, const SendRequestSP&)                             {}
};

struct IUdpSelfListener : IUdpListener {
    virtual void on_receive (string&, const net::SockAddr&, unsigned/*flags*/, const ErrorCode&) {}
    virtual void on_send    (const ErrorCode&, const SendRequestSP&)                             {}

    void on_receive (const UdpSP&, string& buf, const net::SockAddr& addr, unsigned flags, const ErrorCode& err) override { on_receive(buf, addr, flags, err); }
    void on_send    (const UdpSP&, const ErrorCode& err, const SendRequestSP& req)                               override { on_send(err, req); }
};

struct Udp : virtual BackendHandle, AllocatedObject<Udp>, private backend::IUdpImplListener {
    using receive_fptr = void(const UdpSP& handle, string& buf, const net::SockAddr& addr, unsigned flags, const ErrorCode& err);
    using receive_fn   = function<receive_fptr>;
    using send_fptr    = void(const UdpSP& handle, const ErrorCode& err, const SendRequestSP& req);
    using send_fn      = function<send_fptr>;
    using UdpImpl      = backend::UdpImpl;
    using Flags        = UdpImpl::Flags;
    using Membership   = UdpImpl::Membership;

    buf_alloc_fn                     buf_alloc_callback;
    CallbackDispatcher<receive_fptr> receive_event;
    CallbackDispatcher<send_fptr>    send_event;

    Udp (const LoopSP& loop = Loop::default_loop(), int domain = AF_UNSPEC, int flags = 0) : domain(domain), flags(flags) {
        panda_log_ctor();
        _init(loop, loop->impl()->new_udp(this, domain, flags));
    }

    const HandleType& type () const override;

    IUdpListener* event_listener () const          { return _listener; }
    void          event_listener (IUdpListener* l) { _listener = l; }

    string buf_alloc (size_t cap) noexcept override;

    virtual void reset () override;
    virtual void clear () override;

    virtual excepted<void, ErrorCode> open       (sock_t socket, Ownership = Ownership::TRANSFER);
    virtual excepted<void, ErrorCode> bind       (const net::SockAddr&, unsigned flags = 0);
    virtual excepted<void, ErrorCode> bind       (string_view host, uint16_t port, const AddrInfoHints& hints = defhints, unsigned flags = 0);
    virtual excepted<void, ErrorCode> connect    (const net::SockAddr&);
    virtual excepted<void, ErrorCode> connect    (string_view host, uint16_t port, const AddrInfoHints& hints = defhints);
    virtual excepted<void, ErrorCode> recv_start (receive_fn callback = nullptr);
    virtual excepted<void, ErrorCode> recv_stop  ();
    virtual void send       (const SendRequestSP& req);
    /*INL*/ void send       (const string& data, const net::SockAddr& sa = {}, send_fn callback = {});
    template <class It>
    /*INL*/ void send       (It begin, It end, const net::SockAddr& sa = {}, send_fn callback = {});

    excepted<fh_t, ErrorCode> fileno () const { return _impl ? handle_fd_excepted(impl()->fileno()) : fh_t(); }

    excepted<net::SockAddr, ErrorCode> sockaddr () const { return handle_fd_excepted(impl()->sockaddr()); }
    excepted<net::SockAddr, ErrorCode> peeraddr () const { return handle_fd_excepted(impl()->peeraddr()); }

    excepted<int,  ErrorCode> recv_buffer_size () const { return make_excepted(impl()->recv_buffer_size()); }
    excepted<int,  ErrorCode> send_buffer_size () const { return make_excepted(impl()->send_buffer_size()); }
    excepted<void, ErrorCode> recv_buffer_size (int value) { return make_excepted(impl()->recv_buffer_size(value)); }
    excepted<void, ErrorCode> send_buffer_size (int value) { return make_excepted(impl()->send_buffer_size(value)); }

    excepted<void, ErrorCode> set_membership          (string_view multicast_addr, string_view interface_addr, Membership membership);
    excepted<void, ErrorCode> set_source_membership   (string_view multicast_addr, string_view interface_addr, string_view source_addr, Membership membership);
    excepted<void, ErrorCode> set_multicast_loop      (bool on);
    excepted<void, ErrorCode> set_multicast_ttl       (int ttl);
    excepted<void, ErrorCode> set_multicast_interface (string_view interface_addr);
    excepted<void, ErrorCode> set_broadcast           (bool on);
    excepted<void, ErrorCode> set_ttl                 (int ttl);

    bool   using_recvmmsg  () const { return flags & Flags::RECVMMSG; }
    size_t send_queue_size () const { return _sq_size + impl()->send_queue_size(); }

    static const HandleType TYPE;

private:
    friend SendRequest;
    static AddrInfoHints defhints;

    int           domain;
    int           flags;
    Queue         queue;
    IUdpListener* _listener = nullptr;
    size_t        _sq_size  = 0;

    UdpImpl* impl () const { return static_cast<UdpImpl*>(BackendHandle::impl()); }

    HandleImpl* new_impl () override;

    void handle_receive (string& buf, const net::SockAddr& sa, unsigned flags, const std::error_code& err) override;
    void notify_on_send (const ErrorCode&, const SendRequestSP&);
};


struct SendRequest : Request, AllocatedObject<SendRequest> {
    CallbackDispatcher<Udp::send_fptr> event;
    net::SockAddr                      addr;
    std::vector<string>                bufs;

    SendRequest () {}

    explicit SendRequest (const string& data) {
        bufs.push_back(data);
    }

    template <class It>
    SendRequest (It begin, It end) {
        bufs.reserve(end - begin);
        for (; begin != end; ++begin) bufs.push_back(*begin);
    }

private:
    friend Udp;
    Udp* handle;

    void set (Udp* h) {
        handle = h;
        Request::set(h);
    }

    backend::SendRequestImpl* impl () {
        if (!_impl) _impl = handle->impl()->new_send_request(this);
        return static_cast<backend::SendRequestImpl*>(_impl);
    }

    void exec         () override;
    void handle_event (const ErrorCode&) override;
    void notify       (const ErrorCode&) override;
};


inline void Udp::send (const string& data, const net::SockAddr& sa, send_fn callback) {
    auto rp = new SendRequest(data);
    rp->addr = sa;
    if (callback) rp->event.add(callback);
    send(rp);
}

template <class It>
inline void Udp::send (It begin, It end, const net::SockAddr& sa, send_fn callback) {
    auto rp = new SendRequest(begin, end);
    rp->addr = sa;
    if (callback) rp->event.add(callback);
    send(rp);
}

}}
