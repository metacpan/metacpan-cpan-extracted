#include "Child.h"
#include <iomanip>
#include <thread>

namespace panda { namespace unievent { namespace http { namespace manager {

void Child::init (ServerParams p) {
    panda_log_debug("worker: creating server");
    loop = p.loop;
    loop->track_load_average(p.config.load_average_period);

    if (p.server_factory) server = p.server_factory(p.config.server, loop);
    else {
        server = new Server(loop);
        server->configure(p.config.server);
    }

    if (p.request_event.has_listeners()) server->request_event = p.request_event;

    force_stop = p.config.force_worker_stop;

    p.spawn_event(server);

    server->route_event.add([this](auto& req) {
        ++reqcnt.total;
        ++reqcnt.recent;
        send_active_requests(++reqcnt.active);

        req->finish_event.add([this](auto&) {
            send_active_requests(--reqcnt.active);
        });
    });

    loop->update_time();
    la_last_time = loop->now();

    la_timer = Timer::create(p.config.check_interval * 1000, [this](auto&) {
        auto prev_time = la_last_time;
        loop->update_time();
        la_last_time = loop->now();
        float speed = reqcnt.recent * 1000 / (la_last_time == prev_time ?  1 : la_last_time - prev_time);
        panda_log_debug(
            "worker: load average=" << std::setprecision(3) << std::fixed << loop->get_load_average() <<
            ", speed " << std::setprecision(speed > 10 ? 0 : 1) << std::fixed << speed << " req/s" <<
            ", total " << reqcnt.total << " reqs"
        );
        send_activity(std::time(NULL), loop->get_load_average(), reqcnt.total, reqcnt.recent);
        reqcnt.recent = 0;
    }, loop);
    la_timer->weak(true);
}

void Child::run () {
    panda_log_info("worker: running");
    server->run();
    send_activity(std::time(NULL), 0, 0, 0); // mark as ready
    loop->run();
    panda_log_info("worker: end running, total requests served: " << reqcnt.total);
}

void Child::terminate () {
    panda_log_info("worker: terminating...");
    if (terminating) return;
    terminating = true;
    server->stop_event.add([this]() {
        if (force_stop) {
            panda_log_debug("worker: server is gracefully stopped. unblocking loop...");
            loop->stop();
        } else {
            panda_log_debug("worker: server is gracefully stopped. waiting for loop to unblock...");
        }
    });
    server->graceful_stop();
}

}}}}
