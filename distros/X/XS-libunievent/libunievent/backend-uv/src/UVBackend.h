#pragma once
#include "UVLoop.h"

namespace panda { namespace unievent { namespace backend { namespace uv {

struct UVBackend : Backend {
    UVBackend () : Backend("uv") {}

    LoopImpl* new_loop (LoopImpl::Type type) override {
        return new UVLoop(type);
    };
};

}}}}
