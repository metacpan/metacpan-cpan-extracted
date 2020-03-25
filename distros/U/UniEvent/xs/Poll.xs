#include <xs/export.h>
#include <xs/unievent/util.h>
#include <xs/unievent/Poll.h>
#include <panda/unievent/Fs.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static PERL_THREAD_LOCAL struct {
    Simple on_poll = Simple::shared("on_poll");
} cbn;

struct XSPollListener : IPollListener, XSListener {
    void on_poll (const PollSP& h, int events, const std::error_code& err) override {
        call(cbn.on_poll, xs::out(h), Simple(events), xs::out(err));
    }
};

MODULE = UniEvent::Poll                PACKAGE = UniEvent::Poll
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Handle");
    s.add_const_sub("TYPE", Simple(Poll::TYPE.name));
    
    xs::exp::create_constants(s, {
        {"READABLE", Poll::READABLE},
        {"WRITABLE", Poll::WRITABLE}
    });
    xs::exp::autoexport(s);
    
    xs::at_perl_destroy([]() { cbn.on_poll = nullptr; });
}

Poll* Poll::new (Sv fd, LoopSP loop = {}) {
    if (!loop) loop = Loop::default_loop();
    auto info = sv_io_info(fd);
    if (info.is_sock) RETVAL = make_backref<Poll>(Poll::Socket{info.sock}, loop);
    else              RETVAL = make_backref<Poll>(Poll::Fd    {info.fd  }, loop);
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

void Poll::start (int events, Poll::poll_fn cb = nullptr)

void Poll::stop ()

void Poll::call_now (int events, Sv sverr = {}) {
    if (sverr) THIS->call_now(events, xs::in<const std::error_code&>(sverr));
    else       THIS->call_now(events);
}
