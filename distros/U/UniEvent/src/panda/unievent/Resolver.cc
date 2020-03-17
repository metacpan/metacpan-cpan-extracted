#include "Resolver.h"
#include "Timer.h"
#include "Prepare.h"
#include <algorithm>
#include <functional>
#include <panda/log.h>
#include <panda/net/sockaddr.h>

namespace panda { namespace unievent {

log::Module resolver_log_module("EachResolve", log::Level::Warning);

static bool _init () {
    ares_library_init(ARES_LIB_INIT_ALL);
    return true;
}
static const bool __init = _init();

static void log_socket(const sock_t& sock) {
    net::SockAddr sock_peer, sock_from;
    struct sockaddr_storage sa;
    socklen_t sa_len = sizeof(sa);
    if (getpeername(sock, (sockaddr*)&sa, &sa_len) != -1) {
        sock_peer = (sockaddr*)&sa;
    }
    if (getsockname(sock, (sockaddr*)&sa, &sa_len) != -1) {
        sock_from = (sockaddr*)&sa;
    }
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, "sock from: " << sock_from << ", to: " << sock_peer);
}

Resolver::Worker::Worker (Resolver* r) : resolver(r), ares_async() {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " new for resolver " << r);

    ares_options options;
    int optmask = 0;

    options.sock_state_cb_data = this;
    options.sock_state_cb      = [](void* arg, sock_t sock, int read, int write) {
        static_cast<Worker*>(arg)->on_sockstate(sock, read, write);
    };
    optmask |= ARES_OPT_SOCK_STATE_CB;

    options.flags = ARES_FLAG_NOALIASES;
    optmask |= ARES_OPT_FLAGS;

    options.timeout = r->cfg.query_timeout;
    optmask |= ARES_OPT_TIMEOUTMS;

    auto ares_result = ares_init_options(&channel, &options, optmask);
    if (ares_result != ARES_SUCCESS) throw Error(string("resolver couldn't init c-ares: ") + to_string(ares_result));
}

Resolver::Worker::~Worker () {
    ares_destroy(channel);
    for (auto& row : polls) row.second->destroy();
}

void Resolver::Worker::on_sockstate (sock_t sock, int read, int write) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " resolver:" << resolver << " sock:" << sock << " mysocks:" << polls.size() << " read:" << read << " write:" << write);
    log_socket(sock);

    auto it = polls.find(sock);
    auto poll = (it == polls.end()) ? nullptr : it->second;

    if (!read && !write) { // c-ares notifies us that the socket is closed
        assert(poll);
        poll->destroy();
        polls.erase(it);
        return;
    }

    if (!poll) {
        poll = resolver->_loop->impl()->new_poll_sock(this, sock);
        polls.emplace(sock, poll);
    }

    poll->start((read ? Poll::READABLE : 0) | (write ? Poll::WRITABLE : 0));
}

void Resolver::Worker::handle_poll (int events, const std::error_code& err) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " events:" << events << " err:" << err);
    auto sz = polls.size();
    sock_t socks[sz];
    size_t i = 0;
    for (const auto& row : polls) socks[i++] = row.first;
    for (i = 0; i < sz; ++i) {
        ares_process_fd(channel, socks[i], socks[i]);
        log_socket(socks[i]);
    }
    if (exc) std::rethrow_exception(std::move(exc));
}

void Resolver::Worker::resolve (const RequestSP& req) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " req:" << req.get() << " node:" << req->_node << " service:" << req->_service << " tmt:" << req->_timeout);
    request = req;
    request->worker = this;

    UE_NULL_TERMINATE(req->_node, node_cstr);
    UE_NULL_TERMINATE(req->_service, service_cstr);

    ares_addrinfo h = { req->_hints.flags, req->_hints.family, req->_hints.socktype, req->_hints.protocol, 0, nullptr, nullptr, nullptr };
    ares_async = false;
    ares_getaddrinfo(
        channel,
        node_cstr,
        req->_service.length() ? service_cstr : nullptr,
        &h,
        [](void* arg, int status, int timeouts, ares_addrinfo* ai){
            static_cast<Worker*>(arg)->on_resolve(status, timeouts, ai);
        },
        this
    );
    ares_async = true;
}

void Resolver::Worker::on_resolve (int status, int, ares_addrinfo* ai) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " req:" << request.get() << " status:" << ares_strerror(status) << " async:" << ares_async << " ai:" << ai);
    if (!request) return; // canceled

    std::error_code err;
    AddrInfo addr;
    switch (status) {
        case ARES_SUCCESS:
            addr = AddrInfo(ai);
            break;
        case ARES_ECANCELLED:
        case ARES_EDESTRUCTION:
            err = make_error_code(std::errc::operation_canceled);
            break;
        case ARES_ENOTIMP:
            err = make_error_code(std::errc::address_family_not_supported);
            break;
        case ARES_ENOMEM:
            err = make_error_code(std::errc::not_enough_memory);
            break;
        case ARES_ENOTFOUND:
        default:
            err = make_error_code(errc::unknown_error);
    }

    if (ares_async) {
        try {
            finish_resolve(addr, err);
        } catch (...) {
            // we need to transfer exception through ares code otherwise it would be in an undefined state
            // there are 2 ways to get here via ares - from poll event and from dns roll timer event
            exc = std::current_exception();
        }
    } else {
        request->delayed = resolver->loop()->delay([=]{
            request->delayed = 0;
            finish_resolve(addr, err);
        });
    }
}

void Resolver::Worker::cancel () {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " req:" << request.get());
    if (!request) return;
    request->worker = nullptr;
    request = nullptr;
    ares_cancel(channel);
}

void Resolver::Worker::finish_resolve (const AddrInfo& addr, const std::error_code& err) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " req:" << request.get() << " err:" << err);
    auto req = std::move(request);
    resolver->finish_resolve(req, addr, err);
}


ResolverSP Resolver::create_loop_resolver (const LoopSP& loop) {
    return new Resolver(Config(), loop.get());
}

Resolver::Resolver (const LoopSP& loop, const Config& cfg) : Resolver(cfg, loop.get()) {
    _loop_hold = loop;
}

Resolver::Resolver (const Config& cfg, Loop* loop) : _loop(loop), cfg(cfg) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this);
    add_worker();
    dns_roll_timer = _loop->impl()->new_timer(this);
    dns_roll_timer->set_weak();
}

Resolver::~Resolver () {
    for (auto& w : workers) assert(!w || !w->request);
    assert(!queue.size());
    dns_roll_timer->destroy();
}

void Resolver::handle_timer () {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " dns roll timer");
    for (auto& w : workers) if (w && w->request) {
        ares_process_fd(w->channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD);
        if (w->exc) std::rethrow_exception(std::move(w->exc));
    }
}

void Resolver::add_worker () {
    assert(workers.size() < cfg.workers);
    auto worker = new Worker(this);
    workers.emplace_back(worker);
}

void Resolver::resolve (const RequestSP& req) {
    if (req->_port) req->_service = string::from_number(req->_port);
    panda_log_m(resolver_log_module, log::Level::VerboseDebug,
                this << " req:" << req.get() << " [" << req->_node << ":" << req->_service << "] use_cache:" << req->_use_cache);
    req->_resolver = this;
    req->running   = true;
    req->loop      = _loop; // keep loop (for loop resolvers)

    if (req->_use_cache && cfg.cache_limit) {
        auto ai = find(req->_node, req->_service, req->_hints);
        if (ai) {
            req->_use_cache = false;
            cache_delayed.push_back(req);
            req->delayed = loop()->delay([=]{
                req->delayed = 0;
                finish_resolve(req, ai, {});
            });
            return;
        }
    }

    if (req->_timeout) {
        auto reqp = req.get();
        req->timer = Timer::once(req->_timeout, [this, reqp](auto&){
            panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " timed out req:" << reqp);
            reqp->cancel(make_error_code(std::errc::timed_out));
        }, _loop);
    }

    if (queue.empty()) {
        for (auto& w : workers) {
            if (w->request) continue;
            uint32_t roll_tmt = cfg.query_timeout / 5;
            if (roll_tmt < 1) roll_tmt = 1;
            if (!dns_roll_timer->active()) dns_roll_timer->start(roll_tmt, roll_tmt);
            w->resolve(req);
            return;
        }

        if (workers.size() < cfg.workers) {
            add_worker();
            workers.back()->resolve(req);
            return;
        }
    }

    req->queued = true;
    queue.push_back(req);
}

void Resolver::finish_resolve (const RequestSP& req, const AddrInfo& addr, const std::error_code& err) {
    if (!req->running) return;
    panda_log_m(resolver_log_module, log::Level::VerboseDebug,
                this << " req done:" << req.get() << " [" << req->_node << ":" << req->_service << "], err:" << err);

    if (req->delayed) {
        loop()->cancel_delay(req->delayed);
        req->delayed = 0;
    }

    if (req->timer) {
        req->timer->stop();
        req->timer = nullptr;
    }

    auto worker = req->worker;
    if (worker) {
        worker->cancel();
    } else if (req->queued) {
        queue.erase(req);
    } else {
        cache_delayed.erase(req);
    }

    if (!err && req->_use_cache && cfg.cache_limit) {
        if (cache.size() >= cfg.cache_limit) {
            panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " cleaning cache " << cache.size());
            cache.clear();
        }
        cache.emplace(CacheKey(req->_node, req->_service, req->_hints), CachedAddress{addr});
    }

    req->queued  = false;
    req->running = false;

    scope_guard([&]{
        on_resolve(addr, err, req);
    }, [&]{
        if (!worker || worker->request) return; // worker might have been used again in callback

        if (queue.empty()) { // worker became free, check if any requests left
            bool busy = false;
            for (auto& w : workers) if (w->request) {
                busy = true;
                break;
            }
            if (!busy) dns_roll_timer->stop();
            return;
        }

        while (!queue.empty()) {
            auto req = queue.front();

            if (req->_use_cache) { // if just completed request filled cache for queued requests -> dont resolve them
                auto ai = find(req->_node, req->_service, req->_hints);
                if (ai) {
                    req->_use_cache = false;
                    finish_resolve(req, ai, {});
                    continue;
                }
            }

            queue.pop_front();
            worker->resolve(req);
            break;
        }
    });
}

void Resolver::on_resolve (const AddrInfo& addr, const std::error_code& err, const RequestSP& req) {
    req->event(addr, err, req);
}

void Resolver::reset () {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, this);

    dns_roll_timer->stop();

    // cancel only till last as cancel() might add new requests
    auto last_cached = cache_delayed.back();
    auto last_queued = queue.back();

    // some workers may start new resolve on cancel() because new request might be added on cancel()
    for (auto& w : workers) if (w->request) w->request->cancel();

    if (last_cached) {
        while (cache_delayed.front() != last_cached) cache_delayed.front()->cancel();
        last_cached->cancel();
    }

    if (last_queued) {
        while (queue.front() != last_queued) queue.front()->cancel();
        last_queued->cancel();
    }
}

AddrInfo Resolver::find (const string& node, const string& service, const AddrInfoHints& hints) {
    auto it = cache.find({node, service, hints});
    if (it != cache.end()) {
        panda_log_m(resolver_log_module, log::Level::VerboseDebug, this << " found in cache " << node);

        time_t now = time(0);
        if (!it->second.expired(now, cfg.cache_expiration_time)) return it->second.address;

        panda_log_m(resolver_log_module, log::Level::VerboseDebug,this << " expired " << node);
        cache.erase(it);
    }
    return {};
}

void Resolver::clear_cache () {
    cache.clear();
}

Resolver::Request::Request (const ResolverSP& r)
    : _resolver(r), _port(0), _use_cache(true), _timeout(DEFAULT_RESOLVE_TIMEOUT), worker(), delayed(), running(), queued()
{
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, "Request() " << this);
}

Resolver::Request::~Request () { panda_log_m(resolver_log_module, log::Level::VerboseDebug, "~Request " << this); }

void Resolver::Request::cancel (const std::error_code& err) {
    panda_log_m(resolver_log_module, log::Level::VerboseDebug, "cancel " << this);
    if (_resolver) _resolver->finish_resolve(this, nullptr, err);
}

}}
