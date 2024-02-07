#include "Resolver.h"
#include "Timer.h"
#include <ostream>
#include <algorithm>
#include <functional>
#include <panda/log.h>
#include <panda/net/sockaddr.h>

namespace panda { namespace unievent {

static log::Module logmod("UniEvent::Resolver", log::Level::Warning);

static ares_addrinfo_node empty_ares_addrinfo;

static void* my_ares_malloc  (size_t sz)            { return malloc(sz); }
static void  my_ares_free    (void* ptr)            { free(ptr); }
static void* my_ares_realloc (void* ptr, size_t sz) { return realloc(ptr, sz); }

static std::error_code ares2stderr (int);

static bool _init () {
    ares_library_init_mem(ARES_LIB_INIT_ALL, my_ares_malloc, my_ares_free, my_ares_realloc);
    return true;
}
static const bool __init = _init();

static inline void log_socket (const sock_t& sock) {
    panda_log_verbose_debug(logmod, [&]{
        net::SockAddr sock_peer;
        net::SockAddr sock_from;
        struct sockaddr_storage sa;
        socklen_t sa_len = sizeof(sa);
        if (getpeername(sock, (sockaddr*)&sa, &sa_len) != -1) sock_peer = net::SockAddr((sockaddr*)&sa, sa_len);
        if (getsockname(sock, (sockaddr*)&sa, &sa_len) != -1) sock_from = net::SockAddr((sockaddr*)&sa, sa_len);
        log << "sock from: " << sock_from << ", to: " << sock_peer;
    });
}

Resolver::Worker::Worker (Resolver* r) : resolver(r), ares_async() {
    panda_log_notice(logmod, this << " new Worker for resolver " << r);

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
    if (ares_result != ARES_SUCCESS) throw Error(ares2stderr(ares_result));
}

Resolver::Worker::~Worker () {
    ares_destroy(channel);
    for (auto& row : polls) row.second->destroy();
}

void Resolver::Worker::on_sockstate (sock_t sock, int read, int write) {
    panda_log_debug(logmod, this << " resolver:" << resolver << " sock:" << sock << " mysocks:" << polls.size() << " read:" << read << " write:" << write);
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
    panda_log_debug(logmod, this << " Worker::handle_poll events:" << events << " err:" << err);
    auto sz = polls.size();
    sock_t socks[sz];
    size_t i = 0;
    for (const auto& row : polls) socks[i++] = row.first;
    for (i = 0; i < sz; ++i) {
        ares_process_fd(channel, socks[i], socks[i]);
        log_socket(socks[i]);
    }
    if (exc) rethrow_exception();
}

void Resolver::Worker::rethrow_exception () { // resume exception caused by user callback after c-ares flow done
    auto _exc = std::move(exc);
    exc = nullptr;
    std::rethrow_exception(_exc);
}

void Resolver::Worker::resolve (const RequestSP& req) {
    panda_log_info(logmod, this << " Resolver::Worker started  req:" << req.get() << " node:" << req->_node << " service:" << req->_service << " tmt:" << req->_timeout);
    request = req;
    request->worker = this;

    UE_NULL_TERMINATE(req->_node, node_cstr);
    UE_NULL_TERMINATE(req->_service, service_cstr);

    ares_addrinfo_hints h {req->_hints.flags, req->_hints.family, req->_hints.socktype, req->_hints.protocol};
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
    panda_log_info(logmod, this << " Resolver::Worker done req:" << request.get() << " status:" << ares_strerror(status) << " async:" << ares_async << " ai:" << ai);
    AddrInfo addr;
    if (ai) addr = AddrInfo(ai);
    if (!request) return; // canceled

    std::error_code err;
    if (status != ARES_SUCCESS) err  = ares2stderr(status);

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
    panda_log_info(logmod, this << " Resolver::Worker cancel req:" << request.get());
    if (!request) return;
    request->worker = nullptr;
    request = nullptr;
    ares_cancel(channel);
}

void Resolver::Worker::finish_resolve (const AddrInfo& addr, const std::error_code& err) {
    panda_log_info(logmod, this << " Resolver::Worker finish req:" << request.get() << " err:" << err);
    auto req = std::move(request);
    resolver->finish_resolve(req, addr, err);
}


ResolverSP Resolver::create_loop_resolver (const LoopSP& loop) {
    return new Resolver(Config(), loop.get());
}

void Resolver::disable_loop_resolver (Resolver* r) {
    r->reset();
    r->workers.clear();
    r->dns_roll_timer->destroy();
    r->dns_roll_timer = nullptr;
    r->_loop = nullptr;
}

Resolver::Resolver (const LoopSP& loop, const Config& cfg) : Resolver(cfg, loop.get()) {
    _loop_hold = loop;
}

Resolver::Resolver (const Config& cfg, Loop* loop) : _loop(loop), cfg(cfg) {
    panda_log_ctor(logmod);
    add_worker();
    dns_roll_timer = _loop->impl()->new_timer(this);
    dns_roll_timer->set_weak();
}

Resolver::~Resolver () {
    for (auto& w : workers) assert(!w || !w->request);
    assert(!queue.size());
    if (dns_roll_timer) dns_roll_timer->destroy();
}

void Resolver::handle_timer () {
    panda_log_debug(logmod, this << " dns roll timer");
    for (auto& w : workers) if (w && w->request) {
        ares_process_fd(w->channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD);
        if (w->exc) w->rethrow_exception();
    }
}

void Resolver::add_worker () {
    assert(workers.size() < cfg.workers);
    auto worker = new Worker(this);
    workers.emplace_back(worker);
}

void Resolver::resolve (const RequestSP& req) {
    if (!_loop) throw Error("using loop resolver after it's loop death");
    if (req->_port) req->_service = string::from_number(req->_port);
    panda_log_notice(logmod, this << " start resolving req:" << req.get() << " [" << req->_node << ":" << req->_service << "] use_cache:" << req->_use_cache);
    req->_resolver = this;
    req->running   = true;
    req->loop      = _loop; // keep loop (for loop resolvers)

    if (req->_use_cache && cfg.cache_limit) {
        auto ai = find(req->_node, req->_service, req->_hints);
        if (ai) {
            panda_log_notice(logmod, this << " host found in cache req:" << req.get() << " [" << req->_node << ":" << req->_service << "]");
            req->_use_cache = false;
            cache_delayed.push_back(req);
            req->delayed = loop()->delay([=]{
                req->delayed = 0;
                finish_resolve(req, ai, {});
            });
            return;
        }
    }

    #ifdef _WIN32
    if (req->_node == "localhost") return resolve_localhost(req);
    #endif

    if (req->_timeout) {
        auto reqp = req.get();
        req->timer = Timer::create_once(req->_timeout, [this, reqp](auto&){
            panda_log_notice(logmod, this << " dns timed out req:" << reqp << " [" << reqp->_node << ":" << reqp->_service << "]");
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

void Resolver::resolve_localhost (const RequestSP& req) {
    panda_log_info(logmod, this << " resolving localhost:" << req.get());
    cache_delayed.push_back(req);
    req->delayed = loop()->delay([=]{
        req->delayed = 0;
        auto ares_ai = (ares_addrinfo_node*)my_ares_malloc(sizeof(struct ares_addrinfo_node));
        if (!ares_ai) return finish_resolve(req, {}, make_error_code(std::errc::not_enough_memory));
        *ares_ai = empty_ares_addrinfo;

        auto ares_ai_struct = (ares_addrinfo*)my_ares_malloc(sizeof(struct ares_addrinfo));
        if (!ares_ai_struct) return finish_resolve(req, {}, make_error_code(std::errc::not_enough_memory));
        ares_ai_struct->nodes = ares_ai;
        ares_ai_struct->cnames = nullptr;

        AddrInfo ai(ares_ai_struct);

        auto port = req->_port;
        if (req->_service) {
            auto res = from_chars(req->_service.data(), req->_service.data() + req->_service.length(), port);
            if (res.ec) port = 0;
        }

        if (req->_hints.family == AF_INET6) {
            auto sa = net::SockAddr::Inet6("::1", port);
            ares_ai->ai_family = AF_INET6;
            ares_ai->ai_addrlen = sizeof(sockaddr_in6);
            ares_ai->ai_addr = (sockaddr*)my_ares_malloc(ares_ai->ai_addrlen);
            if (!ares_ai->ai_addr) return finish_resolve(req, ai, make_error_code(std::errc::not_enough_memory));
            memcpy(ares_ai->ai_addr, sa.get(), ares_ai->ai_addrlen);
        }
        else {
            auto sa = net::SockAddr::Inet4("127.0.0.1", port);
            ares_ai->ai_family = AF_INET;
            ares_ai->ai_addrlen = sizeof(sockaddr_in);
            ares_ai->ai_addr = (sockaddr*)my_ares_malloc(ares_ai->ai_addrlen);
            if (!ares_ai->ai_addr) return finish_resolve(req, ai, make_error_code(std::errc::not_enough_memory));
            memcpy(ares_ai->ai_addr, sa.get(), ares_ai->ai_addrlen);
        }

        ares_ai->ai_socktype = req->_hints.socktype;
        ares_ai->ai_protocol = req->_hints.protocol;

        finish_resolve(req, ai, {});
    });
}

void Resolver::finish_resolve (const RequestSP& req, const AddrInfo& addr, const std::error_code& err) {
    if (!req->running) return;
    panda_log_notice(logmod, this << " dns finish_resolve done:" << req.get() << " [" << req->_node << ":" << req->_service << "], err:" << err << ", addr:" << addr);

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
        if (_cache.size() >= cfg.cache_limit) {
            panda_log_info(logmod, this << " cache limit exceeded, cleaning cache " << _cache.size());
            _cache.clear();
        }
        _cache.emplace(CacheKey(req->_node, req->_service, req->_hints), CachedAddress{addr});
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
    panda_log_debug(logmod, this << " resolver reset");

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
    auto it = _cache.find({node, service, hints});
    if (it != _cache.end()) {
        panda_log_info(logmod, this << " found in cache " << node);

        time_t now = time(0);
        auto& ai = it->second.address;
        auto expiration_time = std::min<time_t>(ai.ttl(), cfg.cache_expiration_time);
        if (!it->second.expired(now, expiration_time)) return ai;

        panda_log_info(logmod, this << " expired " << node);
        _cache.erase(it);
    }
    return {};
}

void Resolver::Cache::mark_bad_address (const CacheKey& key, const net::SockAddr& sa) {
    panda_log_info(logmod, "request for marking bad address " << sa << " for key " << key);

    auto it = find(key);
    if (it == end()) {
        panda_log_info(logmod, "key not found " << key);
        return;
    }

    auto& ai = it->second.address;
    if (ai.addr() != sa) {
        panda_log_info(logmod, "addr doesn't match " << ai.addr() << " != " << sa);
        return;
    }

    if (ai.next()) ai = ai.next();
    else           ai = ai.first();
}

Resolver::Request::Request (const ResolverSP& r)
    : _resolver(r), _port(0), _use_cache(true), _timeout(DEFAULT_RESOLVE_TIMEOUT), worker(), delayed(), running(), queued()
{
    panda_log_ctor(logmod);
}

Resolver::Request::~Request () { panda_log_dtor(logmod); }

void Resolver::Request::cancel (const std::error_code& err) {
    panda_log_debug(logmod, "cancel " << this);
    if (_resolver) _resolver->finish_resolve(this, nullptr, err);
}

static std::error_code ares2stderr (int ares_err) {
    switch (ares_err) {
        case ARES_SUCCESS               : return {};
        case ARES_ECANCELLED            :
        case ARES_EDESTRUCTION          : return make_error_code(std::errc::operation_canceled);
        case ARES_ENOMEM                : return make_error_code(std::errc::not_enough_memory);
        case ARES_ENOTFOUND             : return resolve_errc::host_not_found;
        case ARES_ENOTIMP               : return resolve_errc::not_implemented;
        case ARES_ENODATA               : return resolve_errc::no_data;
        case ARES_ESERVICE              : return resolve_errc::service_not_found;
        case ARES_EFORMERR              : return resolve_errc::bad_format;
        case ARES_ESERVFAIL             : return resolve_errc::server_failed;
        case ARES_EREFUSED              : return resolve_errc::refused;
        case ARES_EBADQUERY             : return resolve_errc::bad_query;
        case ARES_EBADNAME              : return resolve_errc::bad_name;
        case ARES_EBADFAMILY            : return make_error_code(std::errc::address_family_not_supported);
        case ARES_EBADRESP              : return resolve_errc::bad_response;
        case ARES_ECONNREFUSED          : return make_error_code(std::errc::connection_refused);
        case ARES_ETIMEOUT              : return make_error_code(std::errc::timed_out);
        case ARES_EOF                   : return resolve_errc::eof;
        case ARES_EFILE                 : return resolve_errc::file_read_error;
        case ARES_EBADSTR               : return resolve_errc::bad_string;
        case ARES_EBADFLAGS             : return resolve_errc::bad_flags;
        case ARES_ENONAME               : return resolve_errc::noname;
        case ARES_EBADHINTS             : return resolve_errc::bad_hints;
        case ARES_ENOTINITIALIZED       : return resolve_errc::not_initialized;
        case ARES_ELOADIPHLPAPI         : return resolve_errc::iphlpapi_load_error;
        case ARES_EADDRGETNETWORKPARAMS : return resolve_errc::no_get_network_params;
        default                         : return errc::unknown_error;
    }
}

std::ostream& operator<< (std::ostream& os, const Resolver::CacheKey& key) {
    os << key.node << ":" << (key.service ? key.service : string("0")) << " {" << key.hints << "}";
    return os;
}

}}
