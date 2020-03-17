#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct IIdleImplListener {
    virtual void handle_idle () = 0;
};

struct IdleImpl : HandleImpl {
    IIdleImplListener* listener;

    IdleImpl (LoopImpl* loop, IIdleImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual void start () = 0;
    virtual void stop  () = 0;

    void handle_idle () noexcept {
        panda_mlog_debug(uebacklog, "on idle " << loop);
        ltry([&]{ listener->handle_idle(); });
    }
};

}}}
