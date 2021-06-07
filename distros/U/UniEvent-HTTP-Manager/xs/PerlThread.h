#pragma once
#include <xs.h>
#include <panda/unievent/http/manager/Thread.h>

namespace xs { namespace unievent { namespace http {

using namespace panda::unievent;
using namespace panda::unievent::http::manager;

struct PerlThreadWorker : ThreadWorker {
    Object thread;

    std::string tid () const override {
        return thread.call<Simple>("tid").as_string<std::string>();
    }

    void create_thread (const std::function<void()>& fn) override {
        panda::function<void()> pfn(fn);
        thread = Stash("threads").call("create", xs::out(pfn));
    }

    void join () override {
        thread.call("join");
    }
};

struct PerlThread : Thread {
    PerlThread (const Config& config, const LoopSP& loop, const LoopSP& worker_loop) : Thread(config, loop, worker_loop) {
        eval("require threads");
    }

    std::unique_ptr<ThreadWorker> make_thread_worker () const override {
        return std::make_unique<PerlThreadWorker>();
    }
};

}}}
