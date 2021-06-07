#pragma once
#include "Thread.h"

namespace panda { namespace unievent { namespace http { namespace manager {

struct StlThread : Thread {
    using Thread::Thread;

    std::unique_ptr<ThreadWorker> make_thread_worker () const override;
};

}}}}
