#pragma once
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

struct IFsEventImplListener {
    virtual void handle_fs_event (const string_view& file, int events, const std::error_code&) = 0;
};

struct FsEventImpl : HandleImpl {
    struct Event {
        static constexpr int RENAME = 1;
        static constexpr int CHANGE = 2;
    };

    struct Flags {
        static constexpr int RECURSIVE = 1;
    };

    IFsEventImplListener* listener;

    FsEventImpl (LoopImpl* loop, IFsEventImplListener* lst) : HandleImpl(loop), listener(lst) {}

    virtual void start (string_view path, unsigned flags) = 0;
    virtual void stop  () = 0;

    void handle_fs_event (const string_view& file, int events, const std::error_code& err) noexcept {
        ltry([&]{ listener->handle_fs_event(file, events, err); });
    }
};

}}}
