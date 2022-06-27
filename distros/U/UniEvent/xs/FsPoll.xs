#include <xs/unievent/FsPoll.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string;
using panda::string_view;

static PERL_ITHREADS_LOCAL struct {
    Simple on_fs_start = Simple::shared("on_fs_start");
    Simple on_fs_poll  = Simple::shared("on_fs_poll");
} cbn;

struct XSFsPollListener : IFsPollListener, XSListener {
    void on_fs_poll (const FsPollSP& h, const opt<Fs::FStat>& prev, const opt<Fs::FStat>& cur, const std::error_code& err) override {
        call(cbn.on_fs_poll, xs::out(h), xs::out(prev), xs::out(cur), xs::out(err));
    }
    void on_fs_start (const FsPollSP& h, const opt<Fs::FStat>& stat, const std::error_code& err) override {
        call(cbn.on_fs_start, xs::out(h), xs::out(stat), xs::out(err));
    }
};

MODULE = UniEvent::FsPoll                PACKAGE = UniEvent::FsPoll
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.inherit("UniEvent::Handle");
    stash.add_const_sub("TYPE", Simple(FsPoll::TYPE.name));
    xs::at_perl_destroy([]() {
        cbn.on_fs_poll  = nullptr;
        cbn.on_fs_start = nullptr;
    });
    unievent::register_perl_class(FsPoll::TYPE, stash);
}

FsPollSP create (Sv proto, string_view path, double interval, FsPoll::fs_poll_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<FsPoll>(loop);
    RETVAL->start(path, interval*1000, cb);
}

FsPoll* FsPoll::new (DLoopSP loop = {}) {
    RETVAL = make_backref<FsPoll>(loop);
}

XSCallbackDispatcher* FsPoll::poll_event () : ALIAS(event=1) {
    (void)ix;
    RETVAL = XSCallbackDispatcher::create(THIS->poll_event);
}

void FsPoll::poll_callback (FsPoll::fs_poll_fn cb) : ALIAS(callback=1) {
    (void)ix;
    THIS->poll_event.remove_all();
    if (cb) THIS->poll_event.add(cb);
}

XSCallbackDispatcher* FsPoll::start_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->start_event);
}

void FsPoll::start_callback (FsPoll::fs_start_fn cb) {
    THIS->start_event.remove_all();
    if (cb) THIS->start_event.add(cb);
}

Ref FsPoll::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSFsPollListener>(THIS, ST(0), lst, weak);
}

void FsPoll::start (string_view path, double interval = 1, FsPoll::fs_poll_fn cb = {}) {
    THIS->start(path, interval*1000, cb);
}

void FsPoll::stop ()

string FsPoll::path ()


MODULE = UniEvent::FsPoll                PACKAGE = UniEvent
PROTOTYPES: DISABLE

FsPollSP fs_poll (string_view path, double interval, FsPoll::fs_poll_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<FsPoll>(loop);
    RETVAL->start(path, interval*1000, cb);
}
