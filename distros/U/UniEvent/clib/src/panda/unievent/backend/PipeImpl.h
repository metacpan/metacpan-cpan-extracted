#pragma once
#include "StreamImpl.h"
#include <panda/optional.h>

namespace panda { namespace unievent { namespace backend {

struct PipeImpl : StreamImpl {
    struct Mode {
        static constexpr int not_connected = 0;
        static constexpr int readable      = 1;
        static constexpr int writable      = 2;
    };

    PipeImpl (LoopImpl* loop, IStreamImplListener* lst) : StreamImpl(loop, lst) {}

    virtual std::error_code open (fd_t file) = 0;
    virtual std::error_code bind (string_view name) = 0;

    virtual std::error_code connect (string_view name, ConnectRequestImpl* req) = 0;

    virtual expected<string, std::error_code> sockname () const = 0;
    virtual expected<string, std::error_code> peername () const = 0;

    virtual void pending_instances (int count) = 0;
    virtual int  pending_count     () const    = 0;

    virtual std::error_code chmod (int mode) = 0;
};

}}}
