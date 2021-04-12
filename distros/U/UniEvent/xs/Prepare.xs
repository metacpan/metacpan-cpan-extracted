#include <xs/unievent/Prepare.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static PERL_THREAD_LOCAL struct {
    Simple on_prepare = Simple::shared("on_prepare");
} cbn;

struct XSPrepareListener : IPrepareListener, XSListener {
    void on_prepare (const PrepareSP& h) override {
        call(cbn.on_prepare, xs::out(h));
    }
};

MODULE = UniEvent::Prepare                PACKAGE = UniEvent::Prepare
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.inherit("UniEvent::Handle");
    stash.add_const_sub("TYPE", Simple(Prepare::TYPE.name));
    xs::at_perl_destroy([]() { cbn.on_prepare = nullptr; });
    unievent::register_perl_class(Prepare::TYPE, stash);
}

PrepareSP create (SV* proto, Prepare::prepare_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Prepare>(loop);
    RETVAL->start(cb);
}

Prepare* Prepare::new (DLoopSP loop = {}) {
    RETVAL = make_backref<Prepare>(loop);
}

XSCallbackDispatcher* Prepare::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void Prepare::callback (Prepare::prepare_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref Prepare::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSPrepareListener>(THIS, ST(0), lst, weak);
}

void Prepare::start (Prepare::prepare_fn cb = nullptr)

void Prepare::stop ()

void Prepare::call_now ()

MODULE = UniEvent::Prepare                PACKAGE = UniEvent
PROTOTYPES: DISABLE

PrepareSP prepare (Prepare::prepare_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Prepare>(loop);
    RETVAL->start(cb);
}
