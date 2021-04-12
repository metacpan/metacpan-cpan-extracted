#include <xs/export.h>
#include <xs/unievent/Signal.h>
#include <xs/typemap/expected.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>
#include <xs/unievent/error.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string;

static PERL_THREAD_LOCAL struct {
    Simple on_signal = Simple::shared("on_signal");
} cbn;

struct XSSignalListener : ISignalListener, XSListener {
    void on_signal (const SignalSP& h, int signum) override {
        call(cbn.on_signal, xs::out(h), Simple(signum));
    }
};

MODULE = UniEvent::Signal                PACKAGE = UniEvent::Signal
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.inherit("UniEvent::Handle");
    stash.add_const_sub("TYPE", Simple(Signal::TYPE.name));
    
    for (int i = 0; i < NSIG; ++i) {
        auto name = Signal::signame(i);
        if (name) xs::exp::create_constant(stash, name, i);
    }
    xs::exp::autoexport(stash);
    
    xs::at_perl_destroy([]() { cbn.on_signal = nullptr; });
    unievent::register_perl_class(Signal::TYPE, stash);
}

SignalSP create (SV* proto, int signum, Signal::signal_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Signal>(loop);
    RETVAL->start(signum, cb);
}

SignalSP create_once (SV* proto, int signum, Signal::signal_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Signal>(loop);
    RETVAL->once(signum, cb);
}

Signal* Signal::new (DLoopSP loop = {}) {
    RETVAL = make_backref<Signal>(loop);
}

XSCallbackDispatcher* Signal::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void Signal::callback (Signal::signal_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref Signal::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSSignalListener>(THIS, ST(0), lst, weak);
}

int Signal::signum ()

string signame (Sv obj_or_class_or_signum, SV* signum_sv = NULL) {
    if (obj_or_class_or_signum.is_object_ref()) // $handle->signame()
        RETVAL = xs::in<Signal*>(obj_or_class_or_signum)->signame();
    else // $signal_class->signame($signum) or UniEvent::Signal::signame($signum)
        RETVAL = Signal::signame(signum_sv ? SvIV(signum_sv) : SvIV(obj_or_class_or_signum));
}

void Signal::start (int signum, Signal::signal_fn cb = {}) {
    XSRETURN_EXPECTED(THIS->start(signum, cb));
}

void Signal::once (int signum, Signal::signal_fn cb = {}) {
    XSRETURN_EXPECTED(THIS->once(signum, cb));
}

void Signal::stop () {
    XSRETURN_EXPECTED(THIS->stop());
}

void Signal::call_now (int signum)

SignalSP watch (SV* CLASS, int signum, Signal::signal_fn cb, LoopSP loop = {}) {
    PROTO = CLASS;
    if (!loop) loop = Loop::default_loop();
    RETVAL = make_backref<Signal>(loop);
    RETVAL->start(signum, cb);
}

MODULE = UniEvent::Signal                PACKAGE = UniEvent
PROTOTYPES: DISABLE

SignalSP signal (int signum, Signal::signal_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Signal>(loop);
    RETVAL->start(signum, cb);
}

SignalSP signal_once (int signum, Signal::signal_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Signal>(loop);
    RETVAL->once(signum, cb);
}
