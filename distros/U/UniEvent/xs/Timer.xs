#include <xs/unievent/Timer.h>
#include <xs/unievent/Listener.h>
#include <xs/CallbackDispatcher.h>

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

Timer* Timer::new (LoopSP loop = {}) {
    if (!loop) loop = Loop::default_loop();
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

# $timer->start($repeat, [$initial])
# UniEvent::Timer->start($repeat, $cb, [$loop])
TimerSP start (Sv proto, double repeat_s, Sv arg2 = Sv(), Sv arg3 = Sv()) {
    uint64_t repeat = s2ms(repeat_s);
    if (proto.is_object_ref()) {
        auto& THIS = xs::in<Timer&>(proto);
        THIS.start(repeat, arg2 ? s2ms(SvNV(arg2)) : repeat);
        XSRETURN_UNDEF;
    } else {
        if (!arg2) throw "callback must be passed";
        PROTO = proto;
        auto cb = xs::in<Timer::timer_fn&>(arg2);
        LoopSP loop;
        if (arg3) loop = xs::in<LoopSP>(arg3);
        if (!loop) loop = Loop::default_loop();
        RETVAL = make_backref<Timer>(loop);
        RETVAL->event.add(cb);
        RETVAL->start(repeat);
    }
}

# $timer->once($initial)
# UniEvent::Timer->once($initial, $cb, [$loop])
TimerSP once (Sv proto, double initial_s, Sv callback = Sv(), Sv svloop = Sv()) {
    uint64_t initial = s2ms(initial_s);
    if (proto.is_object_ref()) {
        auto& THIS = xs::in<Timer&>(proto);
        THIS.once(initial);
        XSRETURN_UNDEF;
    } else {
        if (!callback) throw "callback must be passed";
        PROTO = proto;
        auto cb = xs::in<Timer::timer_fn&>(callback);
        LoopSP loop;
        if (svloop) loop = xs::in<LoopSP>(svloop);
        if (!loop) loop = Loop::default_loop();
        RETVAL = make_backref<Timer>(loop);
        RETVAL->event.add(cb);
        RETVAL->once(initial);
    }
}

void Timer::call_now () {
    THIS->call_now();
    XSRETURN(1);
}

void Timer::stop ()

void Timer::again ()

double Timer::repeat (double new_repeat = -1) {
    if (new_repeat > 0) {
        THIS->repeat(new_repeat*1000);
        XSRETURN_UNDEF;
    }
    RETVAL = ((double)THIS->repeat())/1000;
}
