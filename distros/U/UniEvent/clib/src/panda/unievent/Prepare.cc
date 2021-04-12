#include "Prepare.h"
using namespace panda::unievent;

const HandleType Prepare::TYPE("prepare");

PrepareSP Prepare::create (const prepare_fn& cb, const LoopSP& loop) {
    PrepareSP h = new Prepare(loop);
    h->start(cb);
    return h;
}

const HandleType& Prepare::type () const {
    return TYPE;
}

void Prepare::start (const prepare_fn& callback) {
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
