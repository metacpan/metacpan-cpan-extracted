#include <xs/export.h>
#include <xs/unievent/FsEvent.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string_view;

static PERL_THREAD_LOCAL struct {
    Simple on_fs_event = Simple::shared("on_fs_event");
} cbn;

struct XSFsEventListener : IFsEventListener, XSListener {
    void on_fs_event (const FsEventSP& h, const string_view& file, int events, const std::error_code& err) {
        call(cbn.on_fs_event, xs::out(h), Simple(file), Simple(events), xs::out(err));
    }
};

MODULE = UniEvent::FsEvent                PACKAGE = UniEvent::FsEvent
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Handle");
    s.add_const_sub("TYPE", Simple(FsEvent::TYPE.name));
    
    xs::exp::create_constants(s, {
        {"RECURSIVE",   FsEvent::Flags::RECURSIVE},
        {"RENAME",      FsEvent::Event::RENAME   },
        {"CHANGE",      FsEvent::Event::CHANGE   }
    });
    xs::exp::autoexport(s);
    
    xs::at_perl_destroy([]() { cbn.on_fs_event = nullptr; });
    unievent::register_perl_class(FsEvent::TYPE, s);
}

FsEvent* FsEvent::new (LoopSP loop = Loop::default_loop()) {
    RETVAL = make_backref<FsEvent>(loop);
}

XSCallbackDispatcher* FsEvent::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void FsEvent::callback (FsEvent::fs_event_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref FsEvent::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSFsEventListener>(THIS, ST(0), lst, weak);
}

string_view FsEvent::path ()

void FsEvent::start (string_view path, int flags = 0, FsEvent::fs_event_fn cb = nullptr)

void FsEvent::stop ()
