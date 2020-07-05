#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct IPrepareImplListener {
    virtual void handle_prepare () = 0;
};

struct PrepareImpl : HandleImpl {
    IPrepareImplListener* listener;

    PrepareImpl (LoopImpl* loop, IPrepareImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual void start () = 0;
    virtual void stop  () = 0;

    void handle_prepare () noexcept {
        ltry([&]{ listener->handle_prepare(); });
    }
};

}}}
