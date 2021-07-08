#pragma once
#include "Mpm.h"
#include <panda/unievent/Signal.h>

namespace panda { namespace unievent { namespace http { namespace manager {

struct PreFork : Mpm {
    using Mpm::Mpm;

    void      run           () override;
    WorkerPtr create_worker () override;
    void      stop          () override;
    void      stopped       () override;

private:
    SignalSP sigchld;

    void handle_sigchld ();
};

}}}}
