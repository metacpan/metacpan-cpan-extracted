#include <xs/unievent/Check.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static PERL_THREAD_LOCAL struct {
    Simple on_check = Simple::shared("on_check");
} cbn;

struct XSCheckListener : ICheckListener, XSListener {
    void on_check (const CheckSP& h) override {
        call(cbn.on_check, xs::out(h));
    }
};

MODULE = UniEvent::Check                PACKAGE = UniEvent::Check
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.inherit("UniEvent::Handle");
    stash.add_const_sub("TYPE", Simple(Check::TYPE.name));
    xs::at_perl_destroy([]() { cbn.on_check = nullptr; });
    unievent::register_perl_class(Check::TYPE, stash);
}

CheckSP create (Sv proto, Check::check_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Check>(loop);
    RETVAL->start(cb);
}

Check* Check::new (DLoopSP loop = {}) {
    RETVAL = make_backref<Check>(loop);
}
    
XSCallbackDispatcher* Check::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void Check::callback (Check::check_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref Check::event_listener (Sv lst = {}, bool weak = false) {
    RETVAL = event_listener<XSCheckListener>(THIS, ST(0), lst, weak);
}

void Check::start (Check::check_fn cb = {})

void Check::stop ()

void Check::call_now ()


MODULE = UniEvent::Check                PACKAGE = UniEvent
PROTOTYPES: DISABLE

CheckSP check (Check::check_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Check>(loop);
    RETVAL->start(cb);
}
