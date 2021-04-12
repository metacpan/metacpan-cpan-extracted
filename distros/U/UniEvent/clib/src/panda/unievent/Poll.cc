#include "Poll.h"
#include "util.h"

namespace panda { namespace unievent {

const HandleType Poll::TYPE("poll");

PollSP Poll::create (Socket sock, int events, const poll_fn& cb, const LoopSP& loop, Ownership ownership) {
    PollSP h = new Poll(sock, loop, ownership);
    h->start(events, cb);
    return h;
}

PollSP Poll::create (Fd fd, int events, const poll_fn& cb, const LoopSP& loop, Ownership ownership) {
    PollSP h = new Poll(fd, loop, ownership);
    h->start(events, cb);
    return h;
}

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

excepted<void, ErrorCode> Poll::start (int events, const poll_fn& callback) {
    if (callback) event.add(callback);
    return make_excepted(impl()->start(events));
}

excepted<void, panda::ErrorCode> Poll::stop() {
    return make_excepted(impl()->stop());
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

}}
