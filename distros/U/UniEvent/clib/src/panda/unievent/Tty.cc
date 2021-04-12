#include "Tty.h"
#include "uv.h"

namespace panda { namespace unievent {

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

excepted<void, panda::ErrorCode> Tty::set_mode(Mode mode) {
    return make_excepted(impl()->set_mode(mode));
}

excepted<Tty::WinSize, ErrorCode> Tty::get_winsize () {
    auto ret = impl()->get_winsize();
    if (ret.has_value()) {
        return ret.value();
    } else {
        return make_unexpected(ret.error());
    }
}

void Tty::on_reset () {
    read_stop();
    set_connect_result(true);
}

}}
