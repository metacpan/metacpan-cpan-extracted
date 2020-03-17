#pragma once
#include "HandleImpl.h"

#undef fileno

namespace panda { namespace unievent { namespace backend {

struct IPollImplListener {
    virtual void handle_poll (int events, const std::error_code& err) = 0;
};

struct PollImpl : HandleImpl {
    IPollImplListener* listener;

    PollImpl (LoopImpl* loop, IPollImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual optional<fh_t> fileno () const = 0;

    virtual void start (int events) = 0;
    virtual void stop  ()           = 0;

    void handle_poll (int events, const std::error_code& err) noexcept {
        ltry([&]{ listener->handle_poll(events, err); });
    }
};

}}}
