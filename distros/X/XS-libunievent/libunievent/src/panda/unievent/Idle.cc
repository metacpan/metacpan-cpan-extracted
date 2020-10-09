#include "Idle.h"
using namespace panda::unievent;

const HandleType Idle::TYPE("idle");

const HandleType& Idle::type () const {
    return TYPE;
}

void Idle::start (idle_fn callback) {
    if (callback) event.add(callback);
    impl()->start();
}

void Idle::stop () {
    impl()->stop();
}

void Idle::reset () {
    impl()->stop();
}

void Idle::clear () {
    impl()->stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Idle::handle_idle () {
    IdleSP self = this;
    event(self);
    if (_listener) _listener->on_idle(self);
}
