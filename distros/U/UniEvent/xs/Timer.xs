#include <xs/unievent/Timer.h>
#include <xs/typemap/expected.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>
#include <xs/unievent/error.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;

static PERL_THREAD_LOCAL struct {
    Simple on_timer = Simple::shared("on_timer");
} cbn;

struct XSTimerListener : ITimerListener, XSListener {
    void on_timer (const TimerSP& h) override {
        call(cbn.on_timer, xs::out(h));
    }
};

static inline uint64_t s2ms (double s) {
    if (s > 0 && s < 0.001) return 1;
    return s * 1000;
}

MODULE = UniEvent::Timer                PACKAGE = UniEvent::Timer
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.inherit("UniEvent::Handle");
    stash.add_const_sub("TYPE", Simple(Timer::TYPE.name));
    xs::at_perl_destroy([]() { cbn.on_timer = nullptr; });
    unievent::register_perl_class(Timer::TYPE, stash);
}

TimerSP create (SV* proto, double repeat_s, Timer::timer_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Timer>(loop);
    RETVAL->start(s2ms(repeat_s), cb);
}

TimerSP create_once (SV* proto, double initial_s, Timer::timer_fn cb, DLoopSP loop = {}) {
    PROTO = proto;
    RETVAL = make_backref<Timer>(loop);
    RETVAL->once(s2ms(initial_s), cb);
}

Timer* Timer::new (DLoopSP loop = {}) {
    RETVAL = make_backref<Timer>(loop);
}

XSCallbackDispatcher* Timer::event () {
    RETVAL = XSCallbackDispatcher::create(THIS->event);
}

void Timer::callback (Timer::timer_fn cb) {
    THIS->event.remove_all();
    if (cb) THIS->event.add(cb);
}

Ref Timer::event_listener (Sv lst = Sv(), bool weak = false) {
    RETVAL = event_listener<XSTimerListener>(THIS, ST(0), lst, weak);
}

# $timer->start($repeat, [$callback])
# $timer->start($repeat, $initial, [$callback])
# DEPRECATED!!! UniEvent::Timer->start($repeat, $cb, [$loop])
TimerSP start (Sv proto, double repeat_s, Sv arg2 = {}, Sv arg3 = {}) {
    uint64_t repeat = s2ms(repeat_s);
    if (proto.is_object_ref()) {
        auto& THIS = xs::in<Timer&>(proto);
        uint64_t initial = repeat;
        Timer::timer_fn cb;
        if (arg3) {
            cb = xs::in<Timer::timer_fn>(arg3);
            initial = s2ms(SvNV(arg2));
        } else if (arg2) {
            if (arg2.is_sub_ref()) cb = xs::in<Timer::timer_fn>(arg2);
            else                   initial = s2ms(SvNV(arg2));
        }
        THIS.start(repeat, initial, cb);
        XSRETURN_UNDEF;
    } else {
        panda_log_warn(panda::unievent::panda_log_module, "UniEvent::Timer->start is deprecated, use UniEvent::Timer->create or UniEvent::timer instead");
        if (!arg2) throw "callback must be passed";
        PROTO = proto;
        auto cb = xs::in<Timer::timer_fn&>(arg2);
        DLoopSP loop;
        if (arg3) loop = xs::in<DLoopSP>(arg3);
        RETVAL = make_backref<Timer>(loop);
        RETVAL->event.add(cb);
        RETVAL->start(repeat);
    }
}

# $timer->once($initial, [$callback])
# DEPRECATED!!! UniEvent::Timer->once($initial, $cb, [$loop])
TimerSP once (Sv proto, double initial_s, Timer::timer_fn callback = {}, DLoopSP loop = {}) {
    uint64_t initial = s2ms(initial_s);
    if (proto.is_object_ref()) {
        auto& THIS = xs::in<Timer&>(proto);
        THIS.once(initial, callback);
        XSRETURN_UNDEF;
    } else {
        panda_log_warn(panda::unievent::panda_log_module, "UniEvent::Timer->once is deprecated, use UniEvent::Timer->create_once or UniEvent::timer_once instead");
        if (!callback) throw "callback must be passed";
        PROTO = proto;
        RETVAL = make_backref<Timer>(loop);
        RETVAL->once(initial, callback);
    }
}

void Timer::call_now () {
    THIS->call_now();
    XSRETURN(1);
}

void Timer::stop ()

void Timer::pause ()

void Timer::again () {
    XSRETURN_EXPECTED(THIS->again());
}

void Timer::resume () {
    XSRETURN_EXPECTED(THIS->resume());
}

double Timer::repeat (double new_repeat = -1) {
    if (new_repeat > 0) {
        THIS->repeat(new_repeat*1000);
        XSRETURN_UNDEF;
    }
    RETVAL = ((double)THIS->repeat())/1000;
}

double Timer::due_in () {
    RETVAL = ((double)THIS->due_in())/1000;
}

MODULE = UniEvent::Timer                PACKAGE = UniEvent
PROTOTYPES: DISABLE

TimerSP timer (double repeat_s, Timer::timer_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Timer>(loop);
    RETVAL->start(s2ms(repeat_s), cb);
}

TimerSP timer_once (double initial_s, Timer::timer_fn cb, DLoopSP loop = {}) {
    RETVAL = make_backref<Timer>(loop);
    RETVAL->once(s2ms(initial_s), cb);
}
