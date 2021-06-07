#include "manager.h"

namespace xs { namespace unievent { namespace http {

void fill (Manager::Config& cfg, const Hash& h) {
    Sv sv; Simple v;
    if ((sv = h.fetch("server")))              fill(cfg.server, sv);
    if ((v  = h.fetch("min_servers")))         cfg.min_servers         = v;
    if ((v  = h.fetch("max_servers")))         cfg.max_servers         = v;
    if ((v  = h.fetch("min_spare_servers")))   cfg.min_spare_servers   = v;
    if ((v  = h.fetch("max_spare_servers")))   cfg.max_spare_servers   = v;
    if ((v  = h.fetch("min_load")))            cfg.min_load            = v;
    if ((v  = h.fetch("max_load")))            cfg.max_load            = v;
    if ((v  = h.fetch("load_average_period"))) cfg.load_average_period = v;
    if ((v  = h.fetch("max_requests")))        cfg.max_requests        = v;
    if ((v  = h.fetch("min_worker_ttl")))      cfg.min_worker_ttl      = v;
    if ((v  = h.fetch("check_interval")))      cfg.check_interval      = v;
    if ((v  = h.fetch("activity_timeout")))    cfg.activity_timeout    = v;
    if ((v  = h.fetch("termination_timeout"))) cfg.termination_timeout = v;
    if ((sv = h.fetch("force_worker_stop")))   cfg.force_worker_stop   = sv.is_true();

    if ((v = h.fetch("worker_model"))) switch ((Manager::WorkerModel)(int)v) {
        case Manager::WorkerModel::PreFork : cfg.worker_model = Manager::WorkerModel::PreFork; break;
        case Manager::WorkerModel::Thread  : cfg.worker_model = Manager::WorkerModel::Thread; break;
        default: throw Simple("bad worker model supplied");
    }
    if ((v = h.fetch("bind_model"))) switch ((Manager::BindModel)(int)v) {
        case Manager::BindModel::Duplicate : cfg.bind_model = Manager::BindModel::Duplicate; break;
        case Manager::BindModel::ReusePort : cfg.bind_model = Manager::BindModel::ReusePort; break;
        default: throw Simple("bad bind model supplied");
    }
}

}}}
