#include "manager.h"

namespace xs { namespace unievent { namespace http {

void fill (Manager::Config& cfg, const Hash& h) {
    Scalar v;
    if ((v = h.fetch("server")))              fill(cfg.server, v);
    if ((v = h.fetch("min_servers")))         cfg.min_servers         = v.number();
    if ((v = h.fetch("max_servers")))         cfg.max_servers         = v.number();
    if ((v = h.fetch("min_spare_servers")))   cfg.min_spare_servers   = v.number();
    if ((v = h.fetch("max_spare_servers")))   cfg.max_spare_servers   = v.number();
    if ((v = h.fetch("min_load")))            cfg.min_load            = v.number();
    if ((v = h.fetch("max_load")))            cfg.max_load            = v.number();
    if ((v = h.fetch("load_average_period"))) cfg.load_average_period = v.number();
    if ((v = h.fetch("max_requests")))        cfg.max_requests        = v.number();
    if ((v = h.fetch("min_worker_ttl")))      cfg.min_worker_ttl      = v.number();
    if ((v = h.fetch("check_interval")))      cfg.check_interval      = v.number();
    if ((v = h.fetch("activity_timeout")))    cfg.activity_timeout    = v.number();
    if ((v = h.fetch("termination_timeout"))) cfg.termination_timeout = v.number();
    if ((v = h.fetch("force_worker_stop")))   cfg.force_worker_stop   = v.is_true();

    if ((v = h.fetch("worker_model"))) switch ((Manager::WorkerModel)v.as_number<int>()) {
        case Manager::WorkerModel::PreFork : cfg.worker_model = Manager::WorkerModel::PreFork; break;
        case Manager::WorkerModel::Thread  : cfg.worker_model = Manager::WorkerModel::Thread; break;
        default: throw Simple("bad worker model supplied");
    }
}

void fill (Hash& h, const Manager::Config& cfg) {
    h["server"]              = xs::out<>(cfg.server);
    h["min_servers"]         = xs::out<>(cfg.min_servers);
    h["max_servers"]         = xs::out<>(cfg.max_servers);
    h["min_spare_servers"]   = xs::out<>(cfg.min_spare_servers);
    h["max_spare_servers"]   = xs::out<>(cfg.max_spare_servers);
    h["min_load"]            = xs::out<>(cfg.min_load);
    h["max_load"]            = xs::out<>(cfg.max_load);
    h["load_average_period"] = xs::out<>(cfg.load_average_period);
    h["max_requests"]        = xs::out<>(cfg.max_requests);
    h["min_worker_ttl"]      = xs::out<>(cfg.min_worker_ttl);
    h["check_interval"]      = xs::out<>(cfg.check_interval);
    h["activity_timeout"]    = xs::out<>(cfg.activity_timeout);
    h["termination_timeout"] = xs::out<>(cfg.termination_timeout);
    h["force_worker_stop"]   = xs::out<>(cfg.force_worker_stop);
    h["worker_model"]        = xs::out<>(int(cfg.worker_model));
}

}}}
