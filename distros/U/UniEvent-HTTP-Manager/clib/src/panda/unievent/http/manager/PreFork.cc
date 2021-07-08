#include "PreFork.h"
#include <unistd.h>
#include <cstdlib>
#include <signal.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/types.h>

namespace panda { namespace unievent { namespace http { namespace manager {

struct Shmem {
    struct Shdata {
        std::atomic<uint32_t> active_requests;
        std::atomic<uint32_t> activity_time;
        std::atomic<uint8_t>  load_average;
        std::atomic<uint32_t> total_requests;
        std::atomic<uint32_t> recent_requests;
    };

    void* mapped_mem = nullptr;

    Shdata& shmem () {
        return *(reinterpret_cast<Shdata*>(mapped_mem));
    }

    void unmap_mem () {
        if (!mapped_mem) return;
        auto res = munmap(mapped_mem, sizeof(Shdata));
        if (res) panda_log_critical("could not unmap memory");
        mapped_mem = nullptr;
    }

    ~Shmem () { unmap_mem(); }
};

struct PreForkWorker : Worker, Shmem {
    using Worker::Worker;
    pid_t pid;

    PreForkWorker () {
        mapped_mem = mmap(nullptr, sizeof(Shmem::Shdata), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (mapped_mem == MAP_FAILED) throw exception("could not map shared memory");
        shmem().active_requests = 0;
        shmem().activity_time   = 0;
        shmem().load_average    = 0;
        shmem().total_requests  = 0;
    }

    void fetch_state () override {
        active_requests = shmem().active_requests;
        load_average    = (float)shmem().load_average / 100;
        activity_time   = (time_t)shmem().activity_time;
        total_requests  = shmem().total_requests;
        recent_requests = shmem().recent_requests;
        shmem().recent_requests -= recent_requests;
    }

    void terminate () override {
        panda_log_info("terminating worker pid=" << pid);
        send_signal(SIGINT);
    }

    void kill () override {
        panda_log_info("killing worker pid=" << pid);
        send_signal(SIGKILL);
    }

    void send_signal (int signum) {
        auto res = ::kill(pid, signum);
        if (res == -1) panda_log_critical("could not send signal " << signum << " to worker pid=" << pid);
    }
};

struct PreForkChild : Child, Shmem {
    pid_t    master_pid;
    SignalSP term_signal;

    void init (ServerParams p) override {
        master_pid = getppid();

        Child::init(p);

        term_signal = Signal::create(SIGINT, [this](auto...) { terminate(); }, loop);
        term_signal->weak(true);
    }

    void run () override {
        Child::run();
        panda_log_info("worker terminated");
        server->stop(); // normally it should already be stopped
        std::exit(0);
    }

    void send_active_requests (uint32_t areqs) override {
        shmem().active_requests = areqs;
    }

    void send_activity (time_t now, float la, uint32_t total_requests, uint32_t recent_requests) override {
        if (kill(master_pid, 0) != 0) {
            panda_log_info("master process died, terminating...");
            server->stop();
            std::exit(0);
        }
        shmem().load_average     = la * 100;
        shmem().activity_time    = (uint32_t)now;
        shmem().total_requests   = total_requests;
        shmem().recent_requests += recent_requests;
    }
};

using ChildPtr = std::unique_ptr<Child>;

struct RunChildInOuterScope {
    ChildPtr child;
};

void PreFork::run () {
    sigchld = Signal::create(SIGCHLD, [this](auto...){ handle_sigchld(); }, loop);

    ChildPtr child;
    try {
        Mpm::run();
    }
    catch (RunChildInOuterScope& e) {
        child = std::move(e.child);
    }

    if (child) {
        child->run();
        std::abort(); // unreachable
    }
}

void PreFork::handle_sigchld () {
    pid_t pid;
    int wstatus;
    while ((pid = waitpid(-1, &wstatus, WNOHANG)) > 0) {
        panda_log_info("worker pid=" << pid << " terminated");
        for (auto& row : workers) {
            auto worker = static_cast<PreForkWorker*>(row.second.get());
            if (worker->pid == pid) {
                worker_terminated(worker);
                break;
            }
        }
    }
}

WorkerPtr PreFork::create_worker () {
    auto worker = std::make_unique<PreForkWorker>();

    auto pid = fork();
    if (pid == -1) throw exception("could not fork worker");

    if (pid) {
        worker->pid = pid;
        return WorkerPtr(worker.release());
    }

    // release shared memory for other workers as we forked and cloned all of them
    for (auto& row : workers) {
        auto worker = static_cast<PreForkWorker*>(row.second.get());
        worker->unmap_mem();
    }

    // release manager's resources
    check_timer.reset();
    check_termination_timer.reset();
    sigchld.reset();

    auto child = std::make_unique<PreForkChild>();
    child->mapped_mem = worker->mapped_mem;
    worker->mapped_mem = nullptr;
    child->init({worker_loop, config, server_factory, spawn_event, request_event});

    // we can't run child here because it would be a recursive loop run call.
    // we need to bail out of loop execution and run child from there
    throw RunChildInOuterScope{std::move(child)};
}

void PreFork::stop () {
    Mpm::stop();
}

void PreFork::stopped () {
    Mpm::stopped();
    sigchld.reset();
}

}}}}
