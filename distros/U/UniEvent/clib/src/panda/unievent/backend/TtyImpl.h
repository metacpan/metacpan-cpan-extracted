#pragma once
#include "StreamImpl.h"

namespace panda { namespace unievent { namespace backend {

struct TtyImpl : StreamImpl {
    enum class Mode { STD = 0, RAW, IO };

    struct WinSize {
        int width;
        int height;
    };

    TtyImpl (LoopImpl* loop, IStreamImplListener* lst) : StreamImpl(loop, lst) {}

    virtual std::error_code set_mode (Mode) = 0;
    virtual expected<WinSize, std::error_code> get_winsize () = 0;
};

}}}
