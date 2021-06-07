#include "Mpm.h"
#include "math.h"
#include <iomanip>
#include <panda/unievent/util.h>

#ifdef _WIN32
    #include "windows.icc"
#else
    #include "unix.icc"
#endif

namespace panda { namespace unievent { namespace http { namespace manager {

static uint64_t lastid;

static excepted<Mpm::Config, string> normalize_config (const Mpm::Config& _config) {
    auto config = _config;

    #ifdef _WIN32
        if (config.bind_model == BindModel::ReusePort) {
            panda_log_warning("reuse port is not supported on windows, falling back to duplicate model");
            config.bind_model = BindModel::Duplicate;
        }
    #endif

    if (!config.check_interval || !config.load_average_period) {
        return make_unexpected<string>("check_interval, load_average_period must not be zero");
    }

    if (!config.max_servers) config.max_servers = std::max((size_t)config.min_servers, panda::unievent::cpu_info().value().size());

    if (!config.max_spare_servers && config.min_spare_servers) {
        config.max_spare_servers = std::min(config.min_spare_servers + config.min_servers, config.max_servers);
    }

    if (!config.max_load && !config.min_spare_servers) config.max_load = 0.7;
    if (!config.min_load && config.max_load) config.min_load = config.max_load / 2;

    if (config.min_servers > config.max_servers) {
        return make_unexpected<string>("max_servers should be equal to or higher than min_servers");
    }
    if (config.min_spare_servers > config.max_spare_servers) {
        return make_unexpected<string>("min_spare_servers should be lower than or equal to max_spare_servers");
    }
    if (config.min_spare_servers >= config.max_servers) {
        return make_unexpected<string>("min_spare_servers should be lower than max_servers");
    }
    if (config.max_spare_servers > config.max_servers) {
        return make_unexpected<string>("max_spare_servers should be equal to or lower than max_servers");
    }

    if (!config.server.locations.size()) {
        return make_unexpected<string>("no listen addresses supplied");
    }

    // if at least one location has socket, we switch to duplication mode
    for (auto& row : config.server.locations) {
        if (row.sock) {
            config.bind_model = Manager::BindModel::Duplicate;
            break;
        }
    }

    if (config.bind_model == Manager::BindModel::ReusePort) {
        for (auto& row : config.server.locations) row.reuse_port = true;
    }

    return config;
}

Mpm::Mpm (const Config& _config, const LoopSP& _loop, const LoopSP& _worker_loop) : loop(_loop), worker_loop(_worker_loop) {
    if (!loop) loop = new Loop();
    if (!worker_loop) worker_loop = Loop::default_loop();
    auto res = normalize_config(_config);
    if (!res) throw exception(res.error());
    config = res.value();
}

void Mpm::run () {
    if (state != State::initial) throw HttpError("http manager can only be run once");
    state = State::running;
    check_timer = new Timer(loop);
    check_timer->event.add([this](auto&){ check_workers(); });
    check_timer->start(config.check_interval * 1000);

    check_termination_timer = new Timer(loop);
    check_termination_timer->event.add([this](auto&){ kill_not_terminated(); });
    check_termination_timer->start(config.check_interval * 1000);
    check_termination_timer->weak(true);

    if (config.bind_model == Manager::BindModel::Duplicate) create_and_bind_sockets(config);

    start_event();

    loop->delay([this]{ check_workers(); });
    loop->run();
}

excepted<void, string> Mpm::create_and_bind_sockets (Config& config) {
    assert(config.bind_model == Manager::BindModel::Duplicate);
    // in duplication model we need to create bound sockets for every location in master process
    for (auto& loc : config.server.locations) {
        if (loc.sock) {
            loc.host = ""; // any user-supplied socket is transferred for our ownership so we don't need to do anything
        } else if (loc.host) {
            // here we create temporary tcp for cross-platform creation of socket, resolve and bind
            TcpSP tcp = new Tcp(loop);
            auto res = tcp->bind(loc.host, loc.port);
            if (!res) return make_unexpected<string>(res.error().what());
            // we can't detach socket from tcp handle (it will close the socket) so that we duplicate it to leave socket opened
            loc.sock = sock_dup(tcp->socket().value());
        } else {
            return make_unexpected<string>("neither host nor socket defined in one of the locations");
        }
    }
    return {};
}

std::vector<Worker*> Mpm::get_workers (int states) {
    std::vector<Worker*> ret;
    for (auto& row : workers) {
        if (!states || (states & (int)row.second->state)) ret.push_back(row.second.get());
    }
    return ret;
}

void Mpm::check_workers () {
    fetch_state();
    kill_not_responding();
    terminate_restared_workers();
    autorestart_workers();

    struct {
        uint32_t total    = 0;
        uint32_t inactive = 0;
    } cnt;

    float sumload = 0;

    uint64_t recent_requests = 0;
    for (auto& row : workers) recent_requests += row.second->recent_requests;
    auto prev_time = last_check_time;
    loop->update_time();
    last_check_time = loop->now();
    float req_speed = recent_requests * 1000 / (last_check_time == prev_time ? 1 : last_check_time - prev_time);

    for (auto w : get_workers((int)Worker::State::starting | (int)Worker::State::running)) {
        ++cnt.total;
        sumload += w->load_average;
        if (!w->active_requests) ++cnt.inactive;
    }

    float avgload = cnt.total ? sumload / cnt.total : 0;

    ++check_count;
    panda_log(check_count % 60 == 0 ? log::Level::Info : log::Level::Debug,
        "servers total=" << cnt.total <<
        ", inactive=" << cnt.inactive <<
        ", load average=" << std::setprecision(3) << std::fixed << avgload <<
        ", reqs=" << std::setprecision(req_speed > 10 ? 0 : 1) << std::fixed << req_speed << " reqs/s"
    );

    // first check if we have too few workers
    uint32_t needed[] = {0,0,0};
    uint32_t max_to_spawn = config.max_servers - cnt.total;

    if (cnt.total < config.min_servers)          needed[0] = config.min_servers - cnt.total;
    if (cnt.inactive < config.min_spare_servers) needed[1] = config.min_spare_servers - cnt.inactive;
    if (avgload > config.max_load)               needed[2] = ceil(sumload / config.max_load) - cnt.total;

    uint32_t cnt_to_spawn = std::min(max_to_spawn, std::max({needed[0], needed[1], needed[2]}));


    if (cnt_to_spawn) {
        panda_log_debug("needed by: min_servers=" << needed[0] << " min_spare_servers=" << needed[1] << " max_load=" << needed[2] << ". Allowed by max_servers " << max_to_spawn << " more");
        panda_log_info("adding " << cnt_to_spawn << " more servers");
        for (size_t i = 0; i < cnt_to_spawn; ++i) spawn();
        return;
    }

    // now check if we have too many workers
    uint32_t wanted[3] = {0,0,0};
    if (cnt.total > config.max_servers)                                      wanted[0] = cnt.total - config.max_servers;
    if (config.max_spare_servers && cnt.inactive > config.max_spare_servers) wanted[1] = cnt.inactive - config.max_spare_servers;
    if (config.min_load && avgload < config.min_load)                        wanted[2] = cnt.total - uint32_t(sumload / config.min_load);

    uint32_t max_to_term = cnt.total - config.min_servers;
    uint32_t cnt_to_term = std::min(max_to_term, std::max({wanted[0], wanted[1], wanted[2]}));

    if (cnt_to_term) {
        panda_log_debug("wanted to terminate by: max_servers=" << wanted[0] << " max_spare_servers=" << wanted[1] << " min_load=" << wanted[2] << ". Allowed by min_servers " << max_to_term);
        panda_log_info("terminating " << cnt_to_term << " servers");
        terminate_workers(cnt_to_term);
    }
}

void Mpm::fetch_state () {
    for (auto& row : workers) {
        auto worker = row.second.get();
        worker->fetch_state();
        // worker is ready when it first sends activity stats
        if (worker->state == Worker::State::starting && worker->activity_time) worker->state = Worker::State::running;
    }
}

void Mpm::kill_not_responding () {
    if (!config.activity_timeout) return;
    auto now = std::time(NULL);
    for (auto w : get_workers(Worker::State::running)) {
        if (now - w->activity_time < config.activity_timeout) continue;
        panda_log_info("killing not responding worker id=" << w->id);
        kill_worker(w);
    }
}

void Mpm::kill_not_terminated () {
    if (!config.termination_timeout) return;
    auto now = std::time(NULL);
    for (auto w : get_workers(Worker::State::terminating)) {
        if (now - w->termination_time < config.termination_timeout) continue;
        panda_log_info("killing not terminated worker id=" << w->id);
        kill_worker(w);
    }
}

void Mpm::terminate_restared_workers () {
    // find the first and the last worker in chain "restarting" -> "restarting" -> ... -> "starting/running"
    // terminate all the chain if the last worker is running
    auto list = get_workers(Worker::State::restarting);

    std::map<uint64_t, Worker*> replaced_by_index;
    for (auto w : list) {
        assert(w->replaced_by);
        assert(!replaced_by_index.count(w->replaced_by));
        replaced_by_index[w->replaced_by] = w;
    }

    for (auto w : list) {
        if (replaced_by_index.count(w->id)) continue;
        auto last = w;
        while (last->replaced_by) {
            auto it = workers.find(last->replaced_by);
            if (it == workers.end()) {
                panda_log_warning("restarting worker failed, spawning another one...");
                restart_worker(last);
                continue;
            }
            last = it->second.get();
        }

        if (last->state == Worker::State::starting) continue;
        assert(last->state == Worker::State::running);

        panda_log_info("restarting worker complete");
        auto curw = w;
        while (curw != last) {
            assert(curw->state == Worker::State::restarting);
            auto nextid = curw->replaced_by;
            terminate_worker(curw);
            curw = workers.at(nextid).get();
        }
    }
}

void Mpm::autorestart_workers () {
    if (!config.max_requests) return;
    auto now = std::time(NULL);
    for (auto w : get_workers(Worker::State::running)) {
        if (w->total_requests < config.max_requests || now - w->creation_time <= config.min_worker_ttl) continue;
        panda_log_notice("worker id=" << w->id << " max requests reached, restarting...");
        restart_worker(w);
    }
}

Worker* Mpm::spawn () {
    panda_log_debug("spawning worker");
    auto worker = create_worker();
    auto wptr = worker.get();
    worker->id = ++lastid;
    worker->creation_time = std::time(NULL);
    worker->activity_time = worker->creation_time;
    workers[worker->id] = std::move(worker);
    return wptr;
}

void Mpm::terminate_workers (uint32_t cnt) {
    if (!cnt) return;
    auto now = std::time(NULL);
    std::vector<Worker*> victims;
    for (auto& row : workers) {
        auto w = row.second.get();
        if (w->state == Worker::State::running && now - w->creation_time >= config.min_worker_ttl) {
            victims.push_back(w);
        }
    }
    panda_log_info("want to terminate " << cnt << " servers, allowed to terminate " << victims.size() << " servers");

    std::sort(victims.begin(), victims.end(), [](auto a, auto b) { return a->total_requests > b->total_requests; });

    for (uint32_t i = 0; i < cnt && i < victims.size(); ++i) terminate_worker(victims[i]);
}

void Mpm::terminate_worker (Worker* worker) {
    worker->state = Worker::State::terminating;
    worker->termination_time = std::time(NULL);
    worker->terminate();
}

void Mpm::kill_worker (Worker* worker) {
    worker->state = Worker::State::terminating;
    worker->kill();
}

Worker* Mpm::restart_worker (Worker* worker) {
    auto restarting_worker = spawn();
    worker->state = Worker::State::restarting;
    worker->replaced_by = restarting_worker->id;
    return restarting_worker;
}

void Mpm::worker_terminated (Worker* worker) {
    switch (worker->state) {
        case Worker::State::starting    : panda_log_critical("starting worker died"); break;
        case Worker::State::restarting  :
        case Worker::State::running     : panda_log_critical("running worker died"); break;
        case Worker::State::terminating : panda_log_info("worker terminated");
    }
    workers.erase(worker->id);

    switch (state) {
        case State::running : {
            check_workers();
            break;
        }
        case State::stopping : {
            if (workers.size()) break;
            panda_log_info("all workers terminated. server stopped.");
            stopped();
            break;
        }
        default: std::abort(); // should not happen
    }
}

void Mpm::stop () {
    if (state != State::running) return;
    panda_log_info("server is stopping...");
    state = State::stopping;
    check_timer.reset();

    if (config.bind_model == Manager::BindModel::Duplicate) {
        // we need to close all sockets we've created
        for (auto& loc : config.server.locations) {
            if (loc.sock) close_socket(loc.sock.value());
        }
    }

    if (!workers.size()) {
        stopped();
        return;
    }

    for (auto& worker : get_workers()) {
        switch (worker->state) {
            case Worker::State::starting    :
            case Worker::State::restarting  :
            case Worker::State::running     : terminate_worker(worker); break;
            default : break;
        }
    }
}

void Mpm::close_socket (sock_t sock) {
    // to cross-platform close a socket, we create tcp handle and transfer socket ownership to it. it will close it on destruction
    TcpSP h = new Tcp(loop);
    h->open(sock);
    h.reset();
}

void Mpm::stopped () {
    check_termination_timer.reset();
    state = State::stopped;
    loop->stop();
}

void Mpm::restart_workers () {
    loop->delay([this]{ restart_all_workers(); });
}

void Mpm::restart_all_workers () {
    panda_log_notice("restarting all workers");
    for (auto& worker : get_workers((int)Worker::State::starting | (int)Worker::State::running)) {
        auto new_worker = restart_worker(worker);
        new_worker->creation_time = worker->creation_time; // this is unplanned restart - preserve creation time to allow drop if limits reached
    }
}

excepted<void, string> Mpm::reconfigure (const Config& _newcfg) {
    auto res = normalize_config(_newcfg);
    if (!res) return make_unexpected(res.error());
    auto& newcfg = res.value();

    if (config.worker_model != newcfg.worker_model) {
        return make_unexpected<string>("changing worker model is not allowed");
    }
    if (config.bind_model != newcfg.bind_model) {
        return make_unexpected<string>("changing bind model is not allowed");
    }

    auto need_restart = (
        config.server != newcfg.server || config.load_average_period != newcfg.load_average_period || config.check_interval != newcfg.check_interval
    );

    if (need_restart && config.bind_model == Manager::BindModel::Duplicate) {
        auto& newlocs = newcfg.server.locations;
        for (auto& loc : config.server.locations) {
            auto it = newlocs.end();

            if (loc.host) {
                it = std::find_if(newlocs.begin(), newlocs.end(), [&loc](auto& elem) {
                    return elem.host == loc.host && elem.port == loc.port;
                });
            } else {
                it = std::find_if(newlocs.begin(), newlocs.end(), [&loc](auto& elem) {
                    return elem.sock == loc.sock;
                });
            }

            if (it == newlocs.end()) {
                close_socket(loc.sock.value());
            } else {
                it->sock = loc.sock;
            }
        }

        auto res = create_and_bind_sockets(newcfg);
        if (!res) return res;
    }

    check_timer->stop();
    check_termination_timer->stop();

    config = newcfg;

    // we must call spawn() only from pure loop code flow because of prefork child specific run-in-outer-loop exception
    loop->delay([this, need_restart] {
        if (need_restart) restart_all_workers();

        check_timer->start(config.check_interval * 1000);
        check_termination_timer->start(config.check_interval * 1000);

        check_workers();
    });

    return {};
}

Mpm::~Mpm () {
    stop();
}

}}}}
