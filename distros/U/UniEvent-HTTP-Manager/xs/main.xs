#include <xs/export.h>
#include <xs/typemap/expected.h>
#include <xs/CallbackDispatcher.h>
#include <xs/unievent/http/manager.h>

#ifdef USE_ITHREADS
    #include "PerlThread.h"
#endif

using namespace panda;
using namespace panda::unievent;
using namespace panda::unievent::http;
using namespace xs;
using namespace xs::unievent::http;

static Manager* new_manager (const Manager::Config& config, const LoopSP& loop, const LoopSP& worker_loop) {
    if (config.worker_model != Manager::WorkerModel::Thread) {
        return xs::make_backref<Manager>(config, loop, worker_loop);
    }
    #ifdef USE_ITHREADS
        return xs::make_backref<Manager>(new PerlThread(config, loop, worker_loop));
    #else
        throw "Perl with threads support is required for thread worker model";
    #endif
}

MODULE = UniEvent::HTTP::Manager                PACKAGE = UniEvent::HTTP::Manager
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);

    xs::exp::create_constants(s, {
        {"WORKER_PREFORK",  Simple(int(Manager::WorkerModel::PreFork))},
        {"WORKER_THREAD",   Simple(int(Manager::WorkerModel::Thread))},
    });
}

Manager* Manager::new (Manager::Config config = {}, LoopSP master_loop = {}, LoopSP worker_loop = {}) {
    RETVAL = new_manager(config, master_loop, worker_loop);
}

LoopSP Manager::loop ()

void Manager::run ()

void Manager::stop ()

void Manager::restart_workers ()

Manager::Config Manager::config ()

void Manager::reconfigure (Hash newhv) {
    Manager::Config newcfg = THIS->config();
    fill(newcfg, newhv);
    XSRETURN_EXPECTED(THIS->reconfigure(newcfg));
}

XSCallbackDispatcher* Manager::start_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->start_event);
}

void Manager::start_callback (Manager::start_fn cb) {
    THIS->start_event.remove_all();
    if (cb) THIS->start_event.add(cb);
}

XSCallbackDispatcher* Manager::spawn_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->spawn_event);
}

void Manager::spawn_callback (Manager::spawn_fn cb) {
    THIS->spawn_event.remove_all();
    if (cb) THIS->spawn_event.add(cb);
}

XSCallbackDispatcher* Manager::request_event () {
    RETVAL = XSCallbackDispatcher::create(THIS->request_event);
}

void Manager::request_callback (ServerRequest::receive_fn cb) {
    THIS->request_event.remove_all();
    if (cb) THIS->request_event.add(cb);
}

SV* CLONE_SKIP (...) {
    XSRETURN_YES;
    PERL_UNUSED_VAR(items);
}
