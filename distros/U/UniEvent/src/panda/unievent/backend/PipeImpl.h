#pragma once
#include "StreamImpl.h"
#include <panda/optional.h>

namespace panda { namespace unievent { namespace backend {

struct PipeImpl : StreamImpl {
    PipeImpl (LoopImpl* loop, IStreamImplListener* lst) : StreamImpl(loop, lst) {}

    virtual void open (fd_t file) = 0;
    virtual void bind (string_view name) = 0;

    virtual std::error_code connect (string_view name, ConnectRequestImpl* req) = 0;

    virtual optional<string> sockname () const = 0;
    virtual optional<string> peername () const = 0;

    virtual void pending_instances (int count) = 0;
};

}}}
