#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct ITimerImplListener {
    virtual void handle_timer () = 0;
};

struct TimerImpl : HandleImpl {
    ITimerImplListener* listener;

    TimerImpl (LoopImpl* loop, ITimerImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual void     start  (uint64_t repeat, uint64_t initial) = 0;
    virtual void     stop   () noexcept = 0;
    virtual uint64_t repeat () const = 0;
    virtual void     repeat (uint64_t repeat) = 0;
    virtual uint64_t due_in () const = 0;

    virtual std::error_code again() = 0;

    void handle_timer () noexcept {
        ltry([&]{ listener->handle_timer(); });
    }
};

}}}
