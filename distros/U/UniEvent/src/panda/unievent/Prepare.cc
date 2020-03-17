#include "Prepare.h"
using namespace panda::unievent;

const HandleType Prepare::TYPE("prepare");

const HandleType& Prepare::type () const {
    return TYPE;
}

void Prepare::start (prepare_fn callback) {
    if (callback) event.add(callback);
    impl()->start();
}

void Prepare::stop () {
    impl()->stop();
}

void Prepare::reset () {
    impl()->stop();
}

void Prepare::clear () {
    impl()->stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Prepare::handle_prepare () {
    PrepareSP self = this;
    event(self);
    if (_listener) _listener->on_prepare(self);
}
