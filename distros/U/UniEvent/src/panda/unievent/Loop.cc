#include "Loop.h"
#include "error.h"
#include "Handle.h"
#include "Prepare.h"
#include "Resolver.h"
#include <panda/unievent/backend/uv.h>
#include <set>
#include <thread>
#ifndef _WIN32
    #include <pthread.h>
#endif

namespace panda { namespace unievent {

log::Module uelog("UniEvent", log::Warning);
static const auto& panda_log_module = uelog;

static std::thread::id main_thread_id = std::this_thread::get_id();

static backend::Backend* _default_backend = nullptr;

LoopSP              Loop::_global_loop;
thread_local LoopSP Loop::_default_loop;

thread_local std::vector<SyncLoop::Item> SyncLoop::loops;

static thread_local struct {
    std::set<Loop*>* loops = nullptr;
} tls;

static bool _init () {
    #ifndef _WIN32
    pthread_atfork(nullptr, nullptr, []{
        if (tls.loops) for (LoopSP loop : *tls.loops) {
            loop->impl()->handle_fork();
            loop->fork_event(loop);
        }
    });
    #endif
    return true;
}
static const bool __init = _init();

static void register_loop (Loop* loop) {
    auto list = tls.loops;
    if (!list) tls.loops = list = new std::set<Loop*>();
    list->insert(loop);
}

static void unregister_loop (Loop* loop) {
    auto list = tls.loops;
    list->erase(loop);
    if (list->size()) return;
    delete list;
    tls.loops = nullptr;
}

backend::Backend* default_backend () {
    return _default_backend ? _default_backend : backend::UV;
}

void set_default_backend (backend::Backend* backend) {
    if (!backend) throw std::invalid_argument("backend can not be nullptr");
    if (Loop::_global_loop || Loop::_default_loop) throw Error("default backend can not be set after global/default loop first used");
    _default_backend = backend;
}

void Loop::_init_global_loop () {
    _global_loop = new Loop(nullptr, LoopImpl::Type::GLOBAL);
}

void Loop::_init_default_loop () {
    if (std::this_thread::get_id() == main_thread_id) _default_loop = global_loop();
    else _default_loop = new Loop(nullptr, LoopImpl::Type::DEFAULT);
}

Loop::Loop (Backend* backend, LoopImpl::Type type) {
    _ECTOR();
    if (!backend) backend = default_backend();
    _backend = backend;
    _impl = backend->new_loop(type);
    register_loop(this);
}

Loop::~Loop () {
    _EDTOR();
    unregister_loop(this);
    _resolver = nullptr;
    assert(!_handles.size());
    delete _impl;
}

bool Loop::run (RunMode mode) {
    panda_log_info("Loop::run " << this << ", " << this->impl() << ", " << int(mode));
    LoopSP hold = this; (void)hold;
    return _impl->run(mode);
}

void Loop::stop () {
    _impl->stop();
}

void Loop::dump () const {
    for (auto h : _handles) {
        printf("%p %s%s [%s%s]\n",
            h,
            h->active() && !h->weak() ? "": "-",
            h->type().name,
            h->active() ? "A" : "",
            h->weak()   ? "W" : ""
        );
    }
}

Resolver* Loop::resolver () {
    if (!_resolver) _resolver = Resolver::create_loop_resolver(this); // does not hold strong backref to loop
    return _resolver.get();
}

}}
