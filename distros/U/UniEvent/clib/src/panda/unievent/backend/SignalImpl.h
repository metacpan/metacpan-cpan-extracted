#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct ISignalImplListener {
    virtual void handle_signal (int signum) = 0;
};

struct SignalImpl : HandleImpl {
    ISignalImplListener* listener;

    SignalImpl (LoopImpl* loop, ISignalImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual int signum () const = 0;

    virtual std::error_code start (int signum) = 0;
    virtual std::error_code once  (int signum) = 0;
    virtual std::error_code stop  ()           = 0;

    void handle_signal (int signum) noexcept {
        ltry([&]{ listener->handle_signal(signum); });
    }
};

}}}
