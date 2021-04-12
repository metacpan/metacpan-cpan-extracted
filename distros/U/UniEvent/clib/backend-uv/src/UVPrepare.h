#pragma once
#include "UVHandle.h"
#include <panda/unievent/backend/PrepareImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVPrepare : UVHandle<PrepareImpl, uv_prepare_t> {
    UVPrepare (UVLoop* loop, IPrepareImplListener* lst) : UVHandle<PrepareImpl, uv_prepare_t>(loop, lst) {
        uv_prepare_init(loop->uvloop, &uvh);
    }

    void start () override {
        uv_prepare_start(&uvh, [](uv_prepare_t* p) {
            get_handle<UVPrepare*>(p)->handle_prepare();
        });
    }

    void stop () override {
        uv_prepare_stop(&uvh);
    }
};

}}}}
