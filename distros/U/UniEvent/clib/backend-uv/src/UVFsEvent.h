#pragma once
#include "UVHandle.h"
#include <panda/unievent/backend/FsEventImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVFsEvent : UVHandle<FsEventImpl, uv_fs_event_t> {
    UVFsEvent (UVLoop* loop, IFsEventImplListener* lst) : UVHandle<FsEventImpl, uv_fs_event_t>(loop, lst) {
        uvx_strict(uv_fs_event_init(loop->uvloop, &uvh));
    }

    std::error_code start (string_view path, unsigned flags) override {
        unsigned uv_flags = 0;
        if (flags & Flags::RECURSIVE) uv_flags |= UV_FS_EVENT_RECURSIVE;
        UE_NULL_TERMINATE(path, path_str);
        return uvx_ce(uv_fs_event_start(&uvh, on_fs_event, path_str, flags));
    }

    std::error_code stop () override {
        return uvx_ce(uv_fs_event_stop(&uvh));
    }

private:
    static void on_fs_event (uv_fs_event_t* p, const char* filename, int uv_events, int status) {
        auto h = get_handle<UVFsEvent*>(p);
        auto sv = (status || !filename) ? string_view() : string_view(filename);
        int events = 0;
        if (uv_events & UV_RENAME) events |= Event::RENAME;
        if (uv_events & UV_CHANGE) events |= Event::CHANGE;
        h->handle_fs_event(sv, events, uvx_ce(status));
    }
};

}}}}
