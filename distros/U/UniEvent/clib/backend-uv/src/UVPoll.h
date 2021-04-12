#pragma once
#include "UVHandle.h"
#include <panda/unievent/backend/PollImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVPoll : UVHandle<PollImpl, uv_poll_t> {
    UVPoll (UVLoop* loop, IPollImplListener* lst, sock_t sock) : UVHandle<PollImpl, uv_poll_t>(loop, lst) {
        uvx_strict(uv_poll_init_socket(loop->uvloop, &uvh, sock));
    }

    UVPoll (UVLoop* loop, IPollImplListener* lst, int fd, std::nullptr_t) : UVHandle<PollImpl, uv_poll_t>(loop, lst) {
        uvx_strict(uv_poll_init(loop->uvloop, &uvh, fd));
    }

    std::error_code start (int events) override {
        return uvx_ce(uv_poll_start(&uvh, events, [](uv_poll_t* p, int status, int events) {
            auto h = get_handle<UVPoll*>(p);
            h->handle_poll(events, uvx_ce(status));
        }));
    }

    std::error_code stop () override {
        return uvx_ce(uv_poll_stop(&uvh));
    }

    expected<fh_t, std::error_code> fileno () const override { return uvx_fileno(uvhp()); }
};

}}}}
