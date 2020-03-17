#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct IAsyncImplListener {
    virtual void handle_async () = 0;
};

struct AsyncImpl : HandleImpl {
    IAsyncImplListener* listener;

    AsyncImpl (LoopImpl* loop, IAsyncImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual void send () = 0;

    void handle_async () noexcept {
        ltry([&]{ listener->handle_async(); });
    }
};

}}}
