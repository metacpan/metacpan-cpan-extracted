#include "Check.h"
using namespace panda::unievent;

const HandleType Check::TYPE("check");

const HandleType& Check::type () const {
    return TYPE;
}

CheckSP Check::create (const check_fn& cb, const LoopSP& loop) {
    CheckSP h = new Check(loop);
    h->start(cb);
    return h;
}

void Check::start (const check_fn& callback) {
    if (callback) event.add(callback);
    impl()->start();
}

void Check::stop () {
    impl()->stop();
}

void Check::reset () {
    impl()->stop();
}

void Check::clear () {
    impl()->stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Check::handle_check () {
    CheckSP self = this;
    event(self);
    if (_listener) _listener->on_check(self);
}
