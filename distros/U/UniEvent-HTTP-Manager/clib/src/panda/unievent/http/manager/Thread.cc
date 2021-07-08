#include "Thread.h"
#include <mutex>
#include <future>

namespace panda { namespace unievent { namespace http { namespace manager {

static std::mutex mutex;

struct ThreadChild : Child {
    ThreadWorker::SharedData& shared;

    ThreadChild (ThreadWorker::SharedData& shared) : shared(shared) {}

    void run () override {
        Child::run();
        panda_log_info("worker thread: finishing");

        // protect iptrs in functions
        std::lock_guard<std::mutex> lock(mutex);

        server->stop(); // normally it should already be stopped
        server->request_event.remove_all();
    }

    void send_active_requests (uint32_t areqs) override {
        shared.active_requests = areqs;
    }

    void send_activity (time_t now, float la, uint32_t total_requests, uint32_t recent_requests) override {
        shared.load_average    = la;
        shared.activity_time   = now;
        shared.total_requests  = total_requests;
        shared.recent_requests = recent_requests;
    }
};


ThreadWorker::ThreadWorker () {
    shared.active_requests = 0;
    shared.activity_time   = 0;
    shared.load_average    = 0;
    shared.total_requests  = 0;
    shared.terminate       = false;
    shared.die             = false;
}

void ThreadWorker::fetch_state () {
    active_requests = shared.active_requests;
    load_average    = shared.load_average;
    activity_time   = shared.activity_time;
    total_requests  = shared.total_requests;
    recent_requests = shared.recent_requests;
    shared.recent_requests -= recent_requests;
}

void ThreadWorker::terminate () {
    panda_log_info("master thread: terminate worker thread=" << tid());
    shared.terminate = true;

    std::lock_guard<std::mutex> lock(shared.control_mutex);
    if (shared.control_handle) {
        shared.control_handle->send();
    }
}

void ThreadWorker::kill () {
    panda_log_info("master thread: killing worker thread=" << tid());
    shared.die = true;
    shared.control_handle->send();
}


Thread::Thread (const Config& _c, const LoopSP& _loop, const LoopSP& _worker_loop) : Mpm(_c, _loop, _worker_loop) {
    if (worker_loop != Loop::default_loop()) throw exception("you must use default loop as worker_loop for thread worker model");
}

void Thread::run () {
    Mpm::run();
}

WorkerPtr Thread::create_worker () {
    std::lock_guard<std::mutex> lock(mutex); // sync with thread dtors

    std::promise<bool> init_promise;

    auto worker = make_thread_worker();
    worker->shared.termination_handle = new Async(loop);
    worker->shared.termination_handle->event.add([this, worker = worker.get()](auto&) {
        panda_log_info("master: worker tid=" << worker->tid() << " terminated");
        worker->join();
        panda_log_info("master: worker tid=" << worker->tid() << " joined");
        worker_terminated(worker);
    });

    std::function<void()> thr_fn = [this, &shared = worker->shared, &init_promise] {
        ThreadChild child(shared);
        auto loop = Loop::default_loop(); // this loop is thread-local, DO NOT use this->loop !
        AsyncSP control_handle = new Async(loop);

        try {
            shared.control_handle = control_handle;
            shared.control_handle->weak(true);
            shared.control_handle->event.add([&shared, &child, &loop](auto&) {
                if (shared.die) {
                    loop->stop();
                }
                else if (shared.terminate) {
                    child.terminate();
                }
            });

            auto config = this->config; // copy
            if (config.bind_model == Manager::BindModel::Duplicate) { // we need to dup sockets
                for (auto& loc : config.server.locations) loc.sock = sock_dup(loc.sock.value());
            }

            child.init({loop, config, server_factory, spawn_event, request_event});
        }
        catch (...) {
            init_promise.set_value(true);
            shared.termination_handle->send();
            throw;
        }

        init_promise.set_value(true);

        child.run();

        {
            std::lock_guard<std::mutex> lock(shared.control_mutex);
            shared.control_handle = nullptr;
        }
        shared.termination_handle->send();
    };

    worker->create_thread(thr_fn);

    // wait until thread initializes to allow running thread-unsafe code in worker initialization callbacks
    init_promise.get_future().wait();

    return WorkerPtr(worker.release());
}

void Thread::stop () {
    Mpm::stop();
}

void Thread::stopped () {
    Mpm::stopped();
}

}}}}
