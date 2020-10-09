#pragma once
#include "UVHandle.h"
#include <panda/unievent/backend/CheckImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVCheck : UVHandle<CheckImpl, uv_check_t> {
    UVCheck (UVLoop* loop, ICheckImplListener* lst) : UVHandle<CheckImpl, uv_check_t>(loop, lst) {
        uv_check_init(loop->uvloop, &uvh);
    }

    void start () override {
        uv_check_start(&uvh, [](uv_check_t* p) {
            get_handle<UVCheck*>(p)->handle_check();
        });
    }

    void stop () override {
        uv_check_stop(&uvh);
    }
};

}}}}
