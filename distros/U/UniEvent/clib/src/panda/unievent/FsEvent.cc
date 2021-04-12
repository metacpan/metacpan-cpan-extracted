#include "FsEvent.h"

namespace panda { namespace unievent {

const HandleType FsEvent::TYPE("fs_event");

FsEventSP FsEvent::create (const string_view& path, int flags, const fs_event_fn& cb, const LoopSP& loop) {
    FsEventSP h = new FsEvent(loop);
    h->start(path, flags, cb);
    return h;
}

const HandleType& FsEvent::type () const {
    return TYPE;
}

excepted<void, panda::ErrorCode> FsEvent::start(const string_view& path, int flags, const fs_event_fn& callback) {
    if (callback) event.add(callback);
    _path = string(path);
    return make_excepted(impl()->start(path, flags));
}

excepted<void, panda::ErrorCode> FsEvent::stop() {
    return make_excepted(impl()->stop());
}

void FsEvent::reset () {
    impl()->stop();
}

void FsEvent::clear () {
    impl()->stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void FsEvent::handle_fs_event (const string_view& file, int events, const std::error_code& err) {
    FsEventSP self = this;
    event(self, file, events, err);
    if (_listener) _listener->on_fs_event(self, file, events, err);
}

}}
