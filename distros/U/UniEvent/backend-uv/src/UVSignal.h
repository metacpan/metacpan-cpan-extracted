#pragma once
#include "UVHandle.h"
#include <panda/unievent/backend/SignalImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVSignal : UVHandle<SignalImpl, uv_signal_t> {
    UVSignal (UVLoop* loop, ISignalImplListener* lst) : UVHandle<SignalImpl, uv_signal_t>(loop, lst) {
        uvx_strict(uv_signal_init(loop->uvloop, &uvh));
    }

    int signum () const override { return uvh.signum; }

    void start (int signum) override {
        uvx_strict(uv_signal_start(&uvh, _call, signum));
    }

    void once (int signum) override {
        uvx_strict(uv_signal_start_oneshot(&uvh, _call, signum));
    }

    void stop () override {
        uvx_strict(uv_signal_stop(&uvh));
    }

private:
    static void _call (uv_signal_t* p, int signum) {
        get_handle<UVSignal*>(p)->handle_signal(signum);
    }
};

}}}}
