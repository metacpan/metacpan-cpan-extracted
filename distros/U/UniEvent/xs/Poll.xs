#include <xs/export.h>
#include <xs/unievent/util.h>
#include <xs/unievent/Poll.h>
#include <panda/unievent/Fs.h>
#include <xs/typemap/expected.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static PERL_ITHREADS_LOCAL struct {
    Simple on_poll = Simple::shared("on_poll");
} cbn;

struct XSPollListener : IPollListener, XSListener {
    void on_poll (const PollSP& h, int events, const std::error_code& err) override {
        call(cbn.on_poll, xs::out(h), Simple(events), xs::out(err));
    }
};

static Poll* create_poll (Sv fd, LoopSP loop) {
    if (!loop) loop = Loop::default_loop();
    auto info = sv_io_info(fd);
    if (info.is_sock) return make_backref<Poll>(Poll::Socket{info.sock}, loop, Ownership::SHARE);
    else              return make_backref<Poll>(Poll::Fd    {info.fd  }, loop, Ownership::SHARE);
}

MODULE = UniEvent::Poll                PACKAGE = UniEvent::Poll
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Handle");
    s.add_const_sub("TYPE", Simple(Poll::TYPE.name));
    
    xs::exp::create_constants(s, {
        {"READABLE",    Poll::READABLE},
        {"WRITABLE",    Poll::WRITABLE},
        {"PRIORITIZED", Poll::PRIORITIZED},
        {"DISCONNECT",  Poll::DISCONNECT},
    });
    xs::exp::autoexport(s);
    
    xs::at_perl_destroy([]() { cbn.on_poll = nullptr; });
    unievent::register_perl_class(Poll::TYPE, s);
}

PollSP create (Sv proto, Sv fd, int events, Poll::poll_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = create_poll(fd, loop);
    RETVAL->start(events, cb);
}

Poll* Poll::new (Sv fd, DLoopSP loop = {}) {
    RETVAL = create_poll(fd, loop);
}

XSCallbackDispatcher* Poll::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void Poll::callback (Poll::poll_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref Poll::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSPollListener>(THIS, ST(0), lst, weak);
}

void Poll::start (int events, Poll::poll_fn cb = {}) {
    XSRETURN_EXPECTED(THIS->start(events, cb));
}

void Poll::stop () {
    XSRETURN_EXPECTED(THIS->stop());
}

void Poll::call_now (int events, Sv sverr = {}) {
    if (sverr) THIS->call_now(events, xs::in<const std::error_code&>(sverr));
    else       THIS->call_now(events);
}

MODULE = UniEvent::Poll                PACKAGE = UniEvent
PROTOTYPES: DISABLE

PollSP poll (Sv fd, int events, Poll::poll_fn cb, DLoopSP loop = {}) {
    RETVAL = create_poll(fd, loop);
    RETVAL->start(events, cb);
}
