#pragma once
#include "UVStream.h"
#include <panda/unievent/backend/PipeImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

template <class Func>
static inline optional<string> uvx_sockname (const uv_pipe_t* uvhp, Func&& f) {
    size_t len = 0;
    int err = f(uvhp, nullptr, &len);
    if (err) {
        if (err == UV_EBADF || err == UV_ENOTCONN) return {};
        if (err != UV_ENOBUFS) throw uvx_code_error(err);
    }
    panda::string ret(len);
    uvx_strict(f(uvhp, ret.buf(), &len));
    ret.length(len);
    return ret;
}

struct UVPipe : UVStream<PipeImpl, uv_pipe_t> {
    UVPipe (UVLoop* loop, IStreamImplListener* lst, bool ipc) : UVStream<PipeImpl, uv_pipe_t>(loop, lst) {
        uvx_strict(uv_pipe_init(loop->uvloop, &uvh, ipc));
    }

    void bind (string_view name) override {
        UE_NULL_TERMINATE(name, name_str);
        uvx_strict(uv_pipe_bind(&uvh, name_str));
    }

    void open (fd_t file) override {
        uvx_strict(uv_pipe_open(&uvh, file));
    }

    std::error_code connect (string_view name, ConnectRequestImpl* _req) override {
        UE_NULL_TERMINATE(name, name_str);
        auto req = static_cast<UVConnectRequest*>(_req);
        uv_pipe_connect(&req->uvr, &uvh, name_str, on_connect);
        req->active = true;
        return {};
    }

    optional<string> sockname () const override { return uvx_sockname(&uvh, &uv_pipe_getsockname); }
    optional<string> peername () const override { return uvx_sockname(&uvh, &uv_pipe_getpeername); }

    void pending_instances (int count) override {
        uv_pipe_pending_instances(&uvh, count);
    }
};

}}}}
