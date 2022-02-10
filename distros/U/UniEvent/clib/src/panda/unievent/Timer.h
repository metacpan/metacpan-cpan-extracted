#pragma once
#include "BackendHandle.h"
#include "backend/TimerImpl.h"
#include <limits>

namespace panda { namespace unievent {

struct ITimerListener {
    virtual void on_timer(const TimerSP&) = 0;
};

struct ITimerSelfListener : ITimerListener {
    virtual void on_timer () = 0;
    void on_timer(const TimerSP&) override { on_timer(); }
};

// All the values are in milliseconds.
struct Timer : virtual BackendHandle, private backend::ITimerImplListener {
    using timer_fptr = void(const TimerSP& handle);
    using timer_fn = function<timer_fptr>;

    static const HandleType TYPE;

    CallbackDispatcher<timer_fptr> event;

    static TimerSP create     (uint64_t repeat, const timer_fn&, const LoopSP& = Loop::default_loop());
    static TimerSP create_once(uint64_t initial, const timer_fn&, const LoopSP& = Loop::default_loop());

    Timer(const LoopSP& loop = Loop::default_loop()) : _listener() {
        _init(loop, loop->impl()->new_timer(this));
    }

    const HandleType& type () const override;

    ITimerListener* event_listener() const            { return _listener; }
    void            event_listener(ITimerListener* l) { _listener = l; }

    void once    (uint64_t initial, const timer_fn& cb = {}) { start(0, initial, cb); }
    void start   (uint64_t repeat,  const timer_fn& cb = {}) { start(repeat, repeat, cb); }
    void call_now()                                          { handle_timer(); }

    virtual void     start (uint64_t repeat, uint64_t initial, const timer_fn& cb = {});
    virtual void     stop  ();
    virtual void     pause ();
    virtual uint64_t repeat() const;
    virtual void     repeat(uint64_t repeat);
    virtual uint64_t due_in() const;

    virtual excepted<void, ErrorCode> again ();
    virtual excepted<void, ErrorCode> resume();

    void reset() override;
    void clear() override;

private:
    ITimerListener* _listener;
    uint64_t        _paused_due_in = std::numeric_limits<uint64_t>::max();

    void handle_timer() override;

    backend::TimerImpl* impl() const { return static_cast<backend::TimerImpl*>(_impl); }
};

}}
