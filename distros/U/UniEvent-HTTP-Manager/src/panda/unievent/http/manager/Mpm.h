#pragma once
#include "Child.h"
#include "Manager.h"
#include <time.h>
#include <memory>
#include <panda/unievent/http/Server.h>

namespace panda { namespace unievent { namespace http { namespace manager {

struct Worker {
    enum class State { starting = 1, running = 2, restarting = 4, terminating = 8 };
    uint64_t id;
    State    state = State::starting;
    time_t   creation_time;
    time_t   activity_time;
    size_t   active_requests  = 0;
    size_t   total_requests   = 0;
    size_t   recent_requests  = 0;
    float    load_average     = 0;
    uint64_t replaced_by      = 0;
    time_t   termination_time = 0;

    virtual void fetch_state () = 0;
    virtual void terminate   () = 0;
    virtual void kill        () = 0;

    virtual ~Worker () {}
};

using WorkerPtr = std::unique_ptr<Worker>;
using Workers   = std::map<uint64_t, WorkerPtr>;

struct Mpm {
    using Config = Manager::Config;

    Manager::server_factory_fn server_factory;
    Manager::start_cd          start_event;
    Manager::spawn_cd          spawn_event;
    Manager::request_cd        request_event;

    Mpm (const Config&, const LoopSP&, const LoopSP&);

    const LoopSP& get_loop   () const { return loop; }
    const Config& get_config () const { return config; }

    virtual void run  ();
    virtual void stop ();

    virtual void restart_workers ();

    virtual excepted<void, string> reconfigure (const Config&);

    virtual ~Mpm ();

protected:
    enum class State { initial, running, stopping, stopped };
    LoopSP   loop;
    LoopSP   worker_loop;
    Config   config;
    State    state = State::initial;
    TimerSP  check_timer;
    TimerSP  check_termination_timer;
    Workers  workers;
    uint64_t last_check_time = 0;
    uint64_t check_count = 0;

    virtual WorkerPtr create_worker     () = 0;
    void              worker_terminated (Worker*);
    virtual void      stopped           ();

private:
    std::vector<Worker*> get_workers (int states = 0);
    std::vector<Worker*> get_workers (Worker::State state) { return get_workers((int)state); }

    void check_workers              ();
    void fetch_state                ();
    void terminate_restared_workers ();
    void autorestart_workers        ();
    void kill_not_responding        ();
    void kill_not_terminated        ();

    Worker* spawn               ();
    void    terminate_workers   (uint32_t cnt);
    void    terminate_worker    (Worker*);
    void    kill_worker         (Worker*);
    Worker* restart_worker      (Worker*);
    void    restart_all_workers ();

    excepted<void, string> create_and_bind_sockets (Config&);
    void close_socket (sock_t);
};

}}}}
