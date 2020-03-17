#include "Udp.h"
#include "util.h"
using namespace panda::unievent;

const HandleType Udp::TYPE("udp");

AddrInfoHints Udp::defhints = AddrInfoHints(AF_UNSPEC, SOCK_DGRAM, 0, AddrInfoHints::PASSIVE);

backend::HandleImpl* Udp::new_impl () {
    return loop()->impl()->new_udp(this, domain);
}

const HandleType& Udp::type () const {
    return TYPE;
}

panda::string Udp::buf_alloc (size_t cap) noexcept {
    try {
        return buf_alloc_callback ? buf_alloc_callback(cap) : string(cap);
    } catch (...) {
        return {};
    }
}

void Udp::open (sock_t sock, Ownership ownership) {
    if (ownership == Ownership::SHARE) sock = sock_dup(sock);
    impl()->open(sock);
}

void Udp::bind (const net::SockAddr& sa, unsigned flags) {
    impl()->bind(sa, flags);
}

void Udp::bind (string_view host, uint16_t port, const AddrInfoHints& hints, unsigned flags) {
    if (host == "*") return bind(broadcast_addr(port, hints), flags);
    auto ai = sync_resolve(loop()->backend(), host, port, hints);
    bind(ai.addr(), flags);
}

void Udp::connect (const net::SockAddr& addr) {
    impl()->connect(addr);
}

void Udp::connect (string_view host, uint16_t port, const AddrInfoHints& hints) {
    auto ai = sync_resolve(loop()->backend(), host, port, hints);
    connect(ai.addr());
}

void Udp::set_membership (string_view multicast_addr, string_view interface_addr, Membership membership) {
    impl()->set_membership(multicast_addr, interface_addr, membership);
}

void Udp::set_multicast_loop (bool on) {
    impl()->set_multicast_loop(on);
}

void Udp::set_multicast_ttl (int ttl) {
    impl()->set_multicast_ttl(ttl);
}

void Udp::set_multicast_interface (string_view interface_addr) {
    impl()->set_multicast_interface(interface_addr);
}

void Udp::set_broadcast (bool on) {
    impl()->set_broadcast(on);
}

void Udp::set_ttl (int ttl) {
    impl()->set_ttl(ttl);
}

void Udp::recv_start (receive_fn callback) {
    if (callback) receive_event.add(callback);
    impl()->recv_start();
}

void Udp::recv_stop () {
    impl()->recv_stop();
}

void Udp::send (const SendRequestSP& req) {
    req->set(this);
    queue.push(req);
}

void SendRequest::exec () {
    auto err = handle->impl()->send(bufs, addr, impl());
    if (err) delay([=]{ cancel(err); });
}

void SendRequest::notify (const ErrorCode& err) { handle->notify_on_send(err, this); }

void SendRequest::handle_event (const ErrorCode& err) {
    handle->queue.done(this, [=]{ handle->notify_on_send(err, this); });
}

void Udp::notify_on_send (const ErrorCode& err, const SendRequestSP& req) {
    UdpSP self = this;
    req->event(self, err, req);
    send_event(self, err, req);
    if (_listener) _listener->on_send(self, err, req);
}

void Udp::reset () {
    queue.cancel([&]{ BackendHandle::reset(); });
}

void Udp::clear () {
    queue.cancel([&]{
        BackendHandle::clear();
        domain = AF_UNSPEC;
        buf_alloc_callback = nullptr;
        _listener = nullptr;
        receive_event.remove_all();
        send_event.remove_all();
    });
}

void Udp::handle_receive (string& buf, const net::SockAddr& sa, unsigned flags, const std::error_code& err) {
    UdpSP self = this;
    receive_event(self, buf, sa, flags, err);
    if (_listener) _listener->on_receive(self, buf, sa, flags, err);
}
