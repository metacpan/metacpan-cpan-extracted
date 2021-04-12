#include "Udp.h"
#include "util.h"

namespace panda { namespace unievent {

const HandleType Udp::TYPE("udp");

AddrInfoHints Udp::defhints = AddrInfoHints(AF_UNSPEC, SOCK_DGRAM, 0, 0);

backend::HandleImpl* Udp::new_impl () {
    return loop()->impl()->new_udp(this, domain, flags);
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

excepted<void, panda::ErrorCode> Udp::open(sock_t sock, Ownership ownership) {
    if (ownership == Ownership::SHARE) sock = sock_dup(sock);
    return make_excepted(impl()->open(sock));
}

excepted<void, panda::ErrorCode> Udp::bind (const net::SockAddr& sa, unsigned flags) {
    return make_excepted(impl()->bind(sa, flags));
}

excepted<void, panda::ErrorCode> Udp::bind (string_view host, uint16_t port, const AddrInfoHints& hints, unsigned flags) {
    if (host == "*") return bind(broadcast_addr(port, hints), flags);
    auto res = sync_resolve(loop()->backend(), host, port, hints);
    if (!res) return make_unexpected<ErrorCode>(res.error());
    return bind(res.value().addr(), flags);
}

excepted<void, panda::ErrorCode> Udp::connect (const net::SockAddr& addr) {
    return make_excepted(impl()->connect(addr));
}

excepted<void, panda::ErrorCode> Udp::connect (string_view host, uint16_t port, const AddrInfoHints& hints) {
    auto res = sync_resolve(loop()->backend(), host, port, hints);
    if (!res) return make_unexpected<ErrorCode>(res.error());
    return connect(res.value().addr());
}

excepted<void, panda::ErrorCode> Udp::set_membership (string_view multicast_addr, string_view interface_addr, Membership membership) {
    return make_excepted(impl()->set_membership(multicast_addr, interface_addr, membership));
}

excepted<void, panda::ErrorCode> Udp::set_source_membership (string_view multicast_addr, string_view interface_addr, string_view source_addr, Membership membership) {
    return make_excepted(impl()->set_source_membership(multicast_addr, interface_addr, source_addr, membership));
}

excepted<void, panda::ErrorCode> Udp::set_multicast_loop (bool on) {
    return make_excepted(impl()->set_multicast_loop(on));
}

excepted<void, panda::ErrorCode> Udp::set_multicast_ttl (int ttl) {
    return make_excepted(impl()->set_multicast_ttl(ttl));
}

excepted<void, panda::ErrorCode> Udp::set_multicast_interface (string_view interface_addr) {
    return make_excepted(impl()->set_multicast_interface(interface_addr));
}

excepted<void, panda::ErrorCode> Udp::set_broadcast (bool on) {
    return make_excepted(impl()->set_broadcast(on));
}

excepted<void, panda::ErrorCode> Udp::set_ttl (int ttl) {
    return make_excepted(impl()->set_ttl(ttl));
}

excepted<void, panda::ErrorCode> Udp::recv_start (receive_fn callback) {
    if (callback) receive_event.add(callback);
    return make_excepted(impl()->recv_start());
}

excepted<void, panda::ErrorCode> Udp::recv_stop () {
    return make_excepted(impl()->recv_stop());
}

void Udp::send (const SendRequestSP& req) {
    for (const auto& buf : req->bufs) _sq_size += buf.length();
    req->set(this);
    queue.push(req);
}

void SendRequest::exec () {
    for (const auto& buf : bufs) handle->_sq_size -= buf.length();
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

}}
