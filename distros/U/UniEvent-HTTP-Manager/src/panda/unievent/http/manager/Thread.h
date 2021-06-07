#pragma once
#include "Mpm.h"
#include <atomic>
#include <mutex>
#include <panda/unievent/Async.h>

namespace panda { namespace unievent { namespace http { namespace manager {

struct ThreadWorker : Worker {
    struct SharedData {
        Async*                control_handle;
        std::mutex            control_mutex;
        AsyncSP               termination_handle;
        std::atomic<uint32_t> active_requests;
        std::atomic<time_t>   activity_time;
        std::atomic<float>    load_average;
        std::atomic<uint32_t> total_requests;
        std::atomic<uint32_t> recent_requests;
        std::atomic<bool>     terminate;
        std::atomic<bool>     die;
    } shared;

    ThreadWorker ();

    void fetch_state () override;
    void terminate   () override;
    void kill        () override;

    virtual std::string tid () const = 0;

    virtual void create_thread (const std::function<void()>& fn) = 0;
    virtual void join          () = 0;
};

struct Thread : Mpm {
    Thread (const Config&, const LoopSP&, const LoopSP&);

    void      run           () override;
    WorkerPtr create_worker () override;
    void      stop          () override;
    void      stopped       () override;

protected:
    virtual std::unique_ptr<ThreadWorker> make_thread_worker () const = 0;
};

}}}}
