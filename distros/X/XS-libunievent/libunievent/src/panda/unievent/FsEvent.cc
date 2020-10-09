#include "FsEvent.h"
using namespace panda::unievent;

const HandleType FsEvent::TYPE("fs_event");

const HandleType& FsEvent::type () const {
    return TYPE;
}

void FsEvent::start (const string_view& path, int flags, fs_event_fn callback) {
    if (callback) event.add(callback);
    _path = string(path);
    impl()->start(path, flags);
}

void FsEvent::stop () {
    impl()->stop();
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
