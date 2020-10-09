#include "Poll.h"
#include "util.h"
using namespace panda::unievent;

const HandleType Poll::TYPE("poll");

Poll::Poll (Socket sock, const LoopSP& loop, Ownership ownership) : _listener() {
    if (ownership == Ownership::SHARE) sock.val = sock_dup(sock.val);
    _init(loop, loop->impl()->new_poll_sock(this, sock.val));
}

Poll::Poll (Fd fd, const LoopSP& loop, Ownership ownership) : _listener() {
    if (ownership == Ownership::SHARE) fd.val = file_dup(fd.val);
    _init(loop, loop->impl()->new_poll_fd(this, fd.val));
}

const HandleType& Poll::type () const {
    return TYPE;
}

void Poll::start (int events, poll_fn callback) {
    if (callback) event.add(callback);
    impl()->start(events);
}

void Poll::stop () {
    impl()->stop();
}

void Poll::reset () {
    stop();
}

void Poll::clear () {
    stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Poll::handle_poll (int events, const std::error_code& err) {
    PollSP self = this;
    event(self, events, err);
    if (_listener) _listener->on_poll(self, events, err);
}
