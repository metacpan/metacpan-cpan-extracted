#pragma once
#include "BackendHandle.h"
#include "backend/TimerImpl.h"

namespace panda { namespace unievent {

struct ITimerListener {
    virtual void on_timer (const TimerSP&) = 0;
};

struct ITimerSelfListener : ITimerListener {
    virtual void on_timer () = 0;
    void on_timer (const TimerSP&) override { on_timer(); }
};

// All the values are in milliseconds.
struct Timer : virtual BackendHandle, private backend::ITimerImplListener {
    using timer_fptr = void(const TimerSP& handle);
    using timer_fn = function<timer_fptr>;

    static const HandleType TYPE;

    CallbackDispatcher<timer_fptr> event;

    Timer (const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_timer(this));
    }

    const HandleType& type () const override;

    ITimerListener* event_listener () const            { return _listener; }
    void            event_listener (ITimerListener* l) { _listener = l; }

    void once     (uint64_t initial) { start(0, initial); }
    void start    (uint64_t repeat)  { start(repeat, repeat); }
    void call_now ()                 { handle_timer(); }

    virtual void     start  (uint64_t repeat, uint64_t initial);
    virtual void     stop   ();
    virtual void     again  ();
    virtual uint64_t repeat () const;
    virtual void     repeat (uint64_t repeat);

    void reset () override;
    void clear () override;

    static TimerSP once  (uint64_t initial, timer_fn cb, const LoopSP& loop = Loop::default_loop());
    static TimerSP start (uint64_t repeat,  timer_fn cb, const LoopSP& loop = Loop::default_loop());

private:
    ITimerListener* _listener;

    void handle_timer () override;

    backend::TimerImpl* impl () const { return static_cast<backend::TimerImpl*>(_impl); }
};

}}
