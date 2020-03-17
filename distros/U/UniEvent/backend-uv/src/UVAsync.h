#pragma once
#include "UVHandle.h"
#include <panda/unievent/backend/AsyncImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVAsync : UVHandle<AsyncImpl, uv_async_t> {
    UVAsync (UVLoop* loop, IAsyncImplListener* lst) : UVHandle<AsyncImpl, uv_async_t>(loop, lst) {
        int err = uv_async_init(loop->uvloop, &uvh, [](uv_async_t* p){
            get_handle<UVAsync*>(p)->handle_async();
        });
        if (err) throw uvx_code_error(err);
    }

    void send () override {
        int err = uv_async_send(&uvh);
        if (err) throw uvx_code_error(err);
    }
};

}}}}
