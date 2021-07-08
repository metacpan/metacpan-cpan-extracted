#include "StlThread.h"
#include <sstream>
#include <thread>

namespace panda { namespace unievent { namespace http { namespace manager {

struct StlThreadWorker : ThreadWorker {
    std::thread thread;

    std::string tid () const override {
        std::stringstream ss;
        ss << thread.get_id();
        return ss.str();
    }

    void create_thread (const std::function<void()>& fn) override {
        thread = std::thread(fn);
    }

    void join () override {
        thread.join();
    }
};

std::unique_ptr<ThreadWorker> StlThread::make_thread_worker () const {
    return std::make_unique<StlThreadWorker>();
}

}}}}
