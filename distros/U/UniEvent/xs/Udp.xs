#include <xs/export.h>
#include <xs/unievent/Udp.h>
#include <xs/typemap/expected.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string;
using panda::string_view;
using panda::net::SockAddr;

static PERL_ITHREADS_LOCAL struct {
    Simple on_receive = Simple::shared("on_receive");
    Simple on_send    = Simple::shared("on_send");
} cbn;

struct XSUdpListener : IUdpListener, XSListener {
    void on_receive (const UdpSP& h, string& buf, const SockAddr& sa, unsigned flags, const ErrorCode& err) override {
        call(cbn.on_receive, xs::out(h), err ? Sv::undef : xs::out(buf), xs::out(&sa), Simple(flags), xs::out(err));
    }

    void on_send (const UdpSP& h, const ErrorCode& err, const SendRequestSP& req) override {
        call(cbn.on_send, xs::out(h), xs::out(err), xs::out(req));
    }
};


MODULE = UniEvent::Udp                PACKAGE = UniEvent::Udp
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Handle");
    s.add_const_sub("TYPE", Simple(Udp::TYPE.name));

    xs::exp::create_constants(s, {
        {"PARTIAL",     Udp::Flags::PARTIAL                   },
        {"IPV6ONLY",    Udp::Flags::IPV6ONLY                  },
        {"REUSEADDR",   Udp::Flags::REUSEADDR                 },
        {"MMSG_CHUNK",  Udp::Flags::MMSG_CHUNK                },
        {"MMSG_FREE",   Udp::Flags::MMSG_FREE                 },
        {"RECVMMSG",    Udp::Flags::RECVMMSG                  },
        {"LEAVE_GROUP", (unsigned)Udp::Membership::LEAVE_GROUP},
        {"JOIN_GROUP",  (unsigned)Udp::Membership::JOIN_GROUP }
    });

    xs::at_perl_destroy([]() {
        cbn.on_receive = nullptr;
        cbn.on_send    = nullptr;
    });
    unievent::register_perl_class(Udp::TYPE, s);
}

Udp* Udp::new (Loop* loop = Loop::default_loop(), int domain = AF_UNSPEC, int flags = 0) {
    RETVAL = make_backref<Udp>(loop, domain, flags);
}

void Udp::open (Sv sock) {
    XSRETURN_EXPECTED(THIS->open(sv2sock(sock), Ownership::SHARE));
}

void Udp::bind (string_view host, uint16_t port, AddrInfoHints hints = AddrInfoHints(), unsigned flags = 0) {
    XSRETURN_EXPECTED(THIS->bind(host, port, hints, flags));
}

void Udp::bind_addr (SockAddr addr, unsigned flags = 0) {
    XSRETURN_EXPECTED(THIS->bind(addr, flags));
}

#// connect($host, $port, [$hints])
#// connect($sockaddr)
void Udp::connect (Sv host_or_sockaddr, uint16_t port = 0, AddrInfoHints hints = AddrInfoHints()) {
    if (items < 3) XSRETURN_EXPECTED(THIS->connect(xs::in<SockAddr>(host_or_sockaddr)));
    else           XSRETURN_EXPECTED(THIS->connect(xs::in<string_view>(host_or_sockaddr), port, hints));
}

void Udp::recv_start (Udp::receive_fn cb = nullptr) {
    XSRETURN_EXPECTED(THIS->recv_start(cb));
}

void Udp::recv_stop () {
    XSRETURN_EXPECTED(THIS->recv_stop());
}

XSCallbackDispatcher* Udp::receive_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->receive_event);
}

void Udp::receive_callback (Udp::receive_fn cb) {
    THIS->receive_event.remove_all();
    if (cb) THIS->receive_event.add(cb);
}

XSCallbackDispatcher* Udp::send_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->send_event);
}

void Udp::send_callback (Udp::send_fn cb) {
    THIS->send_event.remove_all();
    if (cb) THIS->send_event.add(cb);
}

Ref Udp::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSUdpListener>(THIS, ST(0), lst, weak);
}

SendRequestSP Udp::send (Sv sv, SockAddr sa, Udp::send_fn cb = nullptr) {
    auto buf = sv2buf(sv);
    if (!buf) XSRETURN(0);

    SendRequestSP req = new SendRequest(buf);
    req->addr = sa;
    if (cb) req->event.add(cb);
    THIS->send(req);
    RETVAL = req;
}

void Udp::sockaddr () : ALIAS(peeraddr=1) {
    auto res = ix == 0 ? THIS->sockaddr() : THIS->peeraddr();
    XSRETURN_EXPECTED(res);
}

void Udp::set_membership (string_view multicast_addr, string_view interface_addr, int membership) {
    XSRETURN_EXPECTED(THIS->set_membership(multicast_addr, interface_addr, (Udp::Membership)membership));
}

void Udp::set_source_membership (string_view multicast_addr, string_view interface_addr, string_view source_addr, int membership) {
    XSRETURN_EXPECTED(THIS->set_source_membership(multicast_addr, interface_addr, source_addr, (Udp::Membership)membership));
}

void Udp::set_multicast_loop (bool on) {
    XSRETURN_EXPECTED(THIS->set_multicast_loop(on));
}

void Udp::set_multicast_ttl (int ttl) {
    XSRETURN_EXPECTED(THIS->set_multicast_ttl(ttl));
}

void Udp::set_multicast_interface (string_view interface_addr) {
    XSRETURN_EXPECTED(THIS->set_multicast_interface(interface_addr));
}

void Udp::set_broadcast (bool on) {
    XSRETURN_EXPECTED(THIS->set_broadcast(on));
}

void Udp::set_ttl (int ttl) {
    XSRETURN_EXPECTED(THIS->set_ttl(ttl));
}

size_t Udp::send_queue_size ()

void Udp::recv_buffer_size (Scalar newval = Scalar()) {
    if (newval) XSRETURN_EXPECTED(THIS->recv_buffer_size(newval.number()));
    else        XSRETURN_EXPECTED(THIS->recv_buffer_size());
}

void Udp::send_buffer_size (Scalar newval = Scalar()) {
    if (newval) XSRETURN_EXPECTED(THIS->send_buffer_size(newval.number()));
    else        XSRETURN_EXPECTED(THIS->send_buffer_size());
}

bool Udp::using_recvmmsg ()
