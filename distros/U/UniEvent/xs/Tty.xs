#include <xs/export.h>
#include <xs/unievent/Tty.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static inline TtySP create_tty (fd_t fd, const LoopSP& loop) {
    TtySP ret = make_backref<Tty>(fd, loop);
    ret->connection_factory = [](const StreamSP& h) {
        auto srv = panda::dyn_cast<Tty*>(h.get());
        TtySP client = make_backref<Tty>(srv->fd(), srv->loop());
        xs::out(client); // fill backref
        return client;
    };
    return ret;
}

MODULE = UniEvent::Tty                PACKAGE = UniEvent::Tty
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Stream");
    s.add_const_sub("TYPE", Simple(Tty::TYPE.name));
    
    xs::exp::create_constants(s, {
        {"MODE_STD", (int)Tty::Mode::STD},
        {"MODE_RAW", (int)Tty::Mode::RAW},
        {"MODE_IO",  (int)Tty::Mode::IO }
    });
    unievent::register_perl_class(Tty::TYPE, s);
}

TtySP Tty::new (Sv fd, LoopSP loop = {}) {
    if (!loop) loop = Loop::default_loop();
    RETVAL = create_tty(sv2fd(fd), loop);
}

void Tty::set_mode (int mode) {
    if (mode < (int)Tty::Mode::STD || mode > (int)Tty::Mode::IO) throw "invalid mode";
    THIS->set_mode((Tty::Mode)mode);
}

void Tty::get_winsize () {
    auto wsz = THIS->get_winsize();
    EXTEND(SP, 2);
    mPUSHu(wsz.width);
    mPUSHu(wsz.height);
    XSRETURN(2);
}

void reset_mode () {
    Tty::reset_mode();
}
