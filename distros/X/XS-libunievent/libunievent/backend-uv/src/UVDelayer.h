#pragma once
#include <panda/unievent/backend/Delayer.h>
#include <panda/unievent/backend/IdleImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVDelayer : Delayer, private IIdleImplListener {
    UVDelayer (LoopImpl* loop) : Delayer(loop), handle() {}

    uint64_t add (const delayed_fn& f, const iptr<Refcnt>& guard = {}) {
        if (!callbacks.size()) {
            if (!handle) handle = loop->new_idle(this);
            handle->start();
        }
        return Delayer::add(f, guard);
    }

    void destroy () {
        if (handle) handle->destroy();
    }

private:
    IdleImpl* handle;

    void handle_idle () override {
        Delayer::call();
        if (!callbacks.size()) handle->stop();
    }
};

}}}}
