#include "Async.h"
using namespace panda::unievent;

const HandleType Async::TYPE("async");

const HandleType& Async::type () const {
    return TYPE;
}

void Async::send () {
    impl()->send();
}

void Async::clear () {
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Async::handle_async () {
    AsyncSP self = this;
    event(self);
    if (_listener) _listener->on_async(self);
}
