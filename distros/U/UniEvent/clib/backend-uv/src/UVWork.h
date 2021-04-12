#pragma once
#include "inc.h"
#include <panda/unievent/backend/WorkImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVWork : WorkImpl {
    bool      active;
    uv_work_t uvr;

    UVWork (UVLoop* loop, IWorkImplListener* lst) : WorkImpl(loop, lst), active() {
        uvr.loop = loop->uvloop;
        uvr.data = this;
    }

    std::error_code queue () override {
        auto err = uv_queue_work(uvr.loop, &uvr, on_work, on_after_work);
        if (!err) active = true;
        return uvx_ce(err);
    }

    bool destroy () noexcept override {
        if (active) {
            auto err = uv_cancel((uv_req_t*)&uvr);
            if (err) return false;
            uvr.after_work_cb = [](uv_work_t* p, int) { delete get(p); };
        }
        else delete this;
        return true;
    }

private:
    static UVWork* get (uv_work_t* p) { return static_cast<UVWork*>(p->data); }

    static void on_work (uv_work_t* p) {
        get(p)->handle_work();
    }

    static void on_after_work (uv_work_t* p, int status) {
        auto w = get(p);
        w->active = false;
        w->handle_after_work(uvx_ce(status));
    }
};

}}}}
