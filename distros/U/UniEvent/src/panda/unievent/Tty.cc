#include "Tty.h"
#include "uv.h"
using namespace panda::unievent;

const HandleType Tty::TYPE("tty");

void Tty::reset_mode () {
    uv_tty_reset_mode();
}

Tty::Tty (fd_t fd, const LoopSP& loop) : _fd(fd) {
    _init(loop, loop->impl()->new_tty(this, fd));
    read_stop(); // dont read automatically, fd may not support it
    set_connect_result(true);
}

const HandleType& Tty::type () const {
    return TYPE;
}

backend::HandleImpl* Tty::new_impl () {
    return loop()->impl()->new_tty(this, _fd);
}

StreamSP Tty::create_connection () {
    return new Tty(_fd, loop());
}

void Tty::set_mode (Mode mode) {
    impl()->set_mode(mode);
}

Tty::WinSize Tty::get_winsize () {
    return impl()->get_winsize();
}

void Tty::on_reset () {
    read_stop();
    set_connect_result(true);
}
