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

    virtual expected<fh_t, std::error_code> fileno () const = 0;

    virtual std::error_code start (int events) = 0;
    virtual std::error_code stop  ()           = 0;

    void handle_poll (int events, const std::error_code& err) noexcept {
        ltry([&]{ listener->handle_poll(events, err); });
    }
};

}}}
