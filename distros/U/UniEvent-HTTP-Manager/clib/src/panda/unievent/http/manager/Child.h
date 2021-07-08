#pragma once
#include "Manager.h"
#include <panda/unievent/Signal.h>

namespace panda { namespace unievent { namespace http { namespace manager {

struct Child {
    struct ServerParams {
        const LoopSP&               loop;
        const Manager::Config&      config;
        Manager::server_factory_fn& server_factory;
        Manager::spawn_cd&          spawn_event;
        Manager::request_cd&        request_event;
    };

    virtual void init      (ServerParams);
    virtual void run       ();
    virtual void terminate ();

    virtual ~Child () {}

protected:
    LoopSP   loop;
    ServerSP server;
    TimerSP  la_timer;
    uint64_t la_last_time = 0;
    bool     force_stop   = false;
    bool     terminating  = false;

    struct {
        uint32_t active = 0;
        uint32_t total  = 0;
        uint32_t recent = 0;
    } reqcnt;

    virtual void send_active_requests (uint32_t) = 0;
    virtual void send_activity        (time_t now, float la, uint32_t total_requests, uint32_t recent_requests) = 0;
};

}}}}
