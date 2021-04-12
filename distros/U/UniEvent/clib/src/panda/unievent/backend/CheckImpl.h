#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct ICheckImplListener {
    virtual void handle_check () = 0;
};

struct CheckImpl : HandleImpl {
    ICheckImplListener* listener;

    CheckImpl (LoopImpl* loop, ICheckImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual void start () = 0;
    virtual void stop  () = 0;

    void handle_check () noexcept {
        ltry([&]{ listener->handle_check(); });
    }
};

}}}
