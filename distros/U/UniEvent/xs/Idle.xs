#include <xs/unievent/Idle.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static PERL_THREAD_LOCAL struct {
    Simple on_idle = Simple::shared("on_idle");
} cbn;

struct XSIdleListener : IIdleListener, XSListener {
    void on_idle (const IdleSP& h) override {
        call(cbn.on_idle, xs::out(h));
    }
};

MODULE = UniEvent::Idle                PACKAGE = UniEvent::Idle
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.inherit("UniEvent::Handle");
    stash.add_const_sub("TYPE", Simple(Idle::TYPE.name));
    xs::at_perl_destroy([]() { cbn.on_idle = nullptr; });
    unievent::register_perl_class(Idle::TYPE, stash);
}

IdleSP create (Sv proto, Idle::idle_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Idle>(loop);
    RETVAL->start(cb);
}

Idle* Idle::new (DLoopSP loop = {}) {
    RETVAL = make_backref<Idle>(loop);
}
    
XSCallbackDispatcher* Idle::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void Idle::callback (Idle::idle_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref Idle::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSIdleListener>(THIS, ST(0), lst, weak);
}

void Idle::start (Idle::idle_fn cb = nullptr)

void Idle::stop ()

void Idle::call_now ()

MODULE = UniEvent::Idle                PACKAGE = UniEvent
PROTOTYPES: DISABLE

IdleSP idle (Idle::idle_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Idle>(loop);
    RETVAL->start(cb);
}
