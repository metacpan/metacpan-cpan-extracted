#include "Work.h"
using namespace panda::unievent;

WorkSP Work::queue (const work_fn& wcb, const after_work_fn& awcb, const LoopSP& loop) {
    WorkSP ret = new Work(loop);
    ret->work_cb = wcb;
    ret->after_work_cb = awcb;
    ret->queue();
    return ret;
}

void Work::queue () {
    _loop->register_work(this);
    impl()->queue();
    _active = true;
}

bool Work::cancel () {
    if (!_active) return true;
    if (!_impl->destroy()) return false;
    _impl = nullptr;
    handle_after_work(make_error_code(std::errc::operation_canceled));
    return true;
}

void Work::handle_work () {
    if (work_cb) work_cb(this);
    else if (_listener) _listener->on_work(this);
    else throw std::logic_error("work callback must be set");
}

void Work::handle_after_work (const std::error_code& err) {
    WorkSP self = this;
    _loop->unregister_work(self);
    _active = false;
    if (after_work_cb) after_work_cb(self, err);
    else if (_listener) _listener->on_after_work(self, err);
    else throw std::logic_error("after_work callback must be set");
}
