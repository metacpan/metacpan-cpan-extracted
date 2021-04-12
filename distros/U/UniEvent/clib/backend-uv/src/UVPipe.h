#pragma once
#include "UVStream.h"
#include <panda/unievent/backend/PipeImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

template <class Func>
static inline expected<string, std::error_code> uvx_sockname (const uv_pipe_t* uvhp, Func&& f) {
    size_t len = 0;
    int err = f(uvhp, nullptr, &len);
    if (err && err != UV_ENOBUFS) return make_unexpected(uvx_error(err));

    panda::string ret(len);
    ret[0] = 0; /* prevent valgrind complains */
    err = f(uvhp, ret.buf(), &len);

    if (err) return make_unexpected(uvx_error(err));

    ret.length(len);
    return ret;
}

struct UVPipe : UVStream<PipeImpl, uv_pipe_t> {
    UVPipe (UVLoop* loop, IStreamImplListener* lst, bool ipc) : UVStream<PipeImpl, uv_pipe_t>(loop, lst) {
        uvx_strict(uv_pipe_init(loop->uvloop, &uvh, ipc));
    }

    std::error_code bind (string_view name) override {
        UE_NULL_TERMINATE(name, name_str);
        return uvx_ce(uv_pipe_bind(&uvh, name_str));
    }

    std::error_code open (fd_t file) override {
        return uvx_ce(uv_pipe_open(&uvh, file));
    }

    std::error_code connect (string_view name, ConnectRequestImpl* _req) override {
        UE_NULL_TERMINATE(name, name_str);
        auto req = static_cast<UVConnectRequest*>(_req);
        uv_pipe_connect(&req->uvr, &uvh, name_str, on_connect);
        req->active = true;
        return {};
    }

    expected<string, std::error_code> sockname () const override { return uvx_sockname(&uvh, &uv_pipe_getsockname); }
    expected<string, std::error_code> peername () const override { return uvx_sockname(&uvh, &uv_pipe_getpeername); }

    void pending_instances (int count) override {
        uv_pipe_pending_instances(&uvh, count);
    }

    int pending_count () const override {
        // uv has wrong API, it receives non-const uv_pipe_t while func is just a getter, so we cast it to make our API const
        return uv_pipe_pending_count(const_cast<uv_pipe_t*>(&uvh));
    }

    std::error_code chmod (int mode) override {
        int uv_mode = 0;
        if (mode & Mode::readable) uv_mode |= UV_READABLE;
        if (mode & Mode::writable) uv_mode |= UV_WRITABLE;
        return uvx_ce(uv_pipe_chmod(&uvh, uv_mode));
    }
};

}}}}
