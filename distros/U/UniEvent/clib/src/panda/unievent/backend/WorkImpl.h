#pragma once
#include "LoopImpl.h"

namespace panda { namespace unievent { namespace backend {

struct IWorkImplListener {
    virtual void handle_work       () = 0;
    virtual void handle_after_work (const std::error_code&) = 0;
};

struct WorkImpl {
    LoopImpl*          loop;
    IWorkImplListener* listener;

    WorkImpl (LoopImpl* loop, IWorkImplListener* lst) : loop(loop), listener(lst) { panda_log_ctor(); }

    virtual std::error_code queue () = 0;

    void handle_work () noexcept {
        loop->ltry([&]{ listener->handle_work(); });
    }

    void handle_after_work (const std::error_code& err) noexcept {
        loop->ltry([&]{ listener->handle_after_work(err); });
    }

    virtual bool destroy () noexcept = 0;

    virtual ~WorkImpl () { panda_log_dtor(); }
};

}}}
