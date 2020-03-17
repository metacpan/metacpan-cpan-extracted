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

    virtual void    set_mode    (Mode) = 0;
    virtual WinSize get_winsize ()     = 0;
};

}}}
