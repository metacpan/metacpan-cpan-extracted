#include "Timer.h"
#include "panda/expected.h"
#include <limits>

namespace panda { namespace unievent {

const HandleType Timer::TYPE("timer");

TimerSP Timer::create(uint64_t repeat, const timer_fn& cb, const LoopSP& loop) {
    TimerSP timer = new Timer(loop);
    timer->start(repeat, cb);
    return timer;
}

TimerSP Timer::create_once(uint64_t initial, const timer_fn& cb, const LoopSP& loop) {
    TimerSP timer = new Timer(loop);
    timer->once(initial, cb);
    return timer;
}

const HandleType& Timer::type() const {
    return TYPE;
}

void Timer::start(uint64_t repeat, uint64_t initial, const timer_fn& cb) {
    if (cb) event.add(cb);
    loop()->update_time();
    impl()->start(repeat, initial);
}

void Timer::stop() {
    impl()->stop();
    _paused_due_in = std::numeric_limits<uint64_t>::max();
}

void Timer::pause() {
    if (!active()) return;
    loop()->update_time();
    _paused_due_in = due_in();
    impl()->stop();
}

excepted<void, ErrorCode> Timer::again() {
    loop()->update_time();
    return make_excepted(impl()->again());
}

excepted<void, ErrorCode> Timer::resume() {
    if (active() || _paused_due_in == std::numeric_limits<uint64_t>::max())
        return make_unexpected(make_error_code(std::errc::invalid_argument));
    
    loop()->update_time();
    auto rpt = repeat();
    rpt ? start(rpt, _paused_due_in) : once(_paused_due_in);
    _paused_due_in = std::numeric_limits<uint64_t>::max();
    return {};
}

uint64_t Timer::repeat() const {
    return impl()->repeat();
}

uint64_t Timer::due_in() const {
    return impl()->due_in();
}

void Timer::repeat(uint64_t repeat) {
    impl()->repeat(repeat);
}

void Timer::reset() {
    impl()->stop();
}

void Timer::clear() {
    impl()->stop();
    weak(false);
    _listener = nullptr;
    event.remove_all();
}

void Timer::handle_timer() {
    TimerSP self = this;
    panda_log_debug("on timer " << loop()->impl());
    event(self);
    if (_listener) _listener->on_timer(self);
}

}}
