#pragma once
#include "Loop.h"
#include "Poll.h"
#include "Timer.h"
#include "Request.h"
#include "AddrInfo.h"

#include <map>
#include <ctime>
#include <vector>
#include <iosfwd>
#include <ares.h>
#include <cstdlib>
#include <unordered_map>
#include <panda/string_view.h>

namespace panda { namespace unievent {

struct Resolver : Refcnt, private backend::ITimerImplListener {
    static constexpr uint64_t DEFAULT_RESOLVE_TIMEOUT       = 5000;  // [ms]
    static constexpr uint32_t DEFAULT_CACHE_EXPIRATION_TIME = 10*60; // [s]
    static constexpr size_t   DEFAULT_CACHE_LIMIT           = 10000; // [records]
    static constexpr uint32_t DEFAULT_QUERY_TIMEOUT         = 500;   // [ms]
    static constexpr uint32_t DEFAULT_WORKERS               = 5;
    static constexpr size_t   MAX_WORKER_POLLS              = 3;

    struct Request;
    using RequestSP = iptr<Request>;

    using resolve_fptr = void(const AddrInfo&, const std::error_code&, const RequestSP&);
    using resolve_fn   = function<resolve_fptr>;

    struct Config {
        uint32_t cache_expiration_time;
        size_t   cache_limit;
        uint32_t query_timeout;
        uint32_t workers;

        Config (uint32_t exptime = DEFAULT_CACHE_EXPIRATION_TIME, size_t limit = DEFAULT_CACHE_LIMIT,
                uint32_t query_timeout = DEFAULT_QUERY_TIMEOUT, uint32_t workers = DEFAULT_WORKERS)
            : cache_expiration_time(exptime), cache_limit(limit), query_timeout(query_timeout), workers(workers) {}
    };

    struct CachedAddress {
        CachedAddress (const AddrInfo& ai, std::time_t update_time = std::time(0)) : address(ai), update_time(update_time) {}

        bool expired (time_t now, time_t expiration_time) const { return update_time + expiration_time < now; }

        AddrInfo    address;
        std::time_t update_time;
    };

    struct CacheKey : Refcnt {
        CacheKey (const string& node, const string& service = {}, const AddrInfoHints& hints = {}) : node(node), service(service), hints(hints) {}

        bool operator== (const CacheKey& other) const {
            return node == other.node && service == other.service && hints == other.hints;
        }

        string        node;
        string        service;
        AddrInfoHints hints;
    };

    struct CacheHash {
        template <class T> inline void hash_combine (std::size_t& seed, const T& v) const {
            seed ^= std::hash<T>()(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
        }

        std::size_t operator() (const CacheKey& p) const {
            std::size_t seed = 0;
            hash_combine(seed, p.node);
            hash_combine(seed, p.service);
            hash_combine(seed, p.hints.flags);
            hash_combine(seed, p.hints.family);
            hash_combine(seed, p.hints.socktype);
            hash_combine(seed, p.hints.protocol);
            return seed;
        }
    };

    struct Cache : std::unordered_map<const CacheKey, CachedAddress, CacheHash> {
        using Super = std::unordered_map<const CacheKey, CachedAddress, CacheHash>;
        void mark_bad_address (const CacheKey&, const net::SockAddr&);
    };

    static ResolverSP create_loop_resolver  (const LoopSP& loop);
    static void       disable_loop_resolver (Resolver*);

    Resolver (const LoopSP& loop = Loop::default_loop(), uint32_t exptime = DEFAULT_CACHE_EXPIRATION_TIME, size_t limit = DEFAULT_CACHE_LIMIT)
        : Resolver(loop, Config(exptime, limit)) {}
    Resolver (const LoopSP& loop, const Config&);

    Resolver (Resolver& other) = delete;
    Resolver& operator= (Resolver& other) = delete;

    LoopSP loop () const { return _loop; }

    RequestSP resolve ();
    RequestSP resolve (string node, resolve_fn callback, uint64_t timeout = DEFAULT_RESOLVE_TIMEOUT);

    virtual void resolve (const RequestSP&);

    virtual void reset ();

    AddrInfo find (const string& node, const string& service = {}, const AddrInfoHints& hints = {});

    uint32_t cache_expiration_time () const { return cfg.cache_expiration_time; }
    size_t   cache_limit           () const { return cfg.cache_limit; }
    size_t   queue_size            () const { return queue.size(); }

    Cache& cache () { return _cache; }

    void cache_expiration_time (uint32_t val) { cfg.cache_expiration_time = val; }

    void cache_limit (size_t val) {
        cfg.cache_limit = val;
        if (_cache.size() > val) _cache.clear();
    }

protected:
    virtual void on_resolve (const AddrInfo&, const std::error_code&, const RequestSP&);

    ~Resolver ();

private:
    using BTimer = backend::TimerImpl;
    using BPoll  = backend::PollImpl;

    struct Worker : private backend::IPollImplListener {
        Worker (Resolver*);
        virtual ~Worker ();

        void on_sockstate (sock_t sock, int read, int write);

        void resolve    (const RequestSP&);
        void on_resolve (int status, int timeouts, ares_addrinfo* ai);

        void finish_resolve (const AddrInfo&, const std::error_code& err);
        void cancel ();

        void handle_poll (int, const std::error_code&) override;

        void rethrow_exception ();

        using Polls = std::map<sock_t, BPoll*>;

        Resolver*          resolver;
        ares_channel       channel;
        Polls              polls;
        RequestSP          request;
        bool               ares_async;
        std::exception_ptr exc;
    };

    using Requests = IntrusiveChain<RequestSP>;
    using Workers  = std::vector<std::unique_ptr<Worker>>;

    Loop*    _loop;
    LoopSP   _loop_hold;
    Config   cfg;
    BTimer*  dns_roll_timer;
    Workers  workers;
    Requests queue;
    Requests cache_delayed;
    Cache    _cache;

    Resolver (const Config&, Loop*);

    void add_worker ();

    void resolve_localhost (const RequestSP&);
    void finish_resolve    (const RequestSP&, const AddrInfo&, const std::error_code&);

    void handle_timer () override;

    friend Request; friend Worker;
};

struct Resolver::Request : Refcnt, IntrusiveChainNode<Resolver::RequestSP>, AllocatedObject<Resolver::Request> {
    CallbackDispatcher<resolve_fptr> event;

    Request (const ResolverSP& r = {});

    const ResolverSP& resolver () const { return _resolver; }

    RequestSP node       (string val)               { _node      = val; return this; }
    RequestSP service    (string val)               { _service   = val; return this; }
    RequestSP port       (uint16_t val)             { _port      = val; return this; }
    RequestSP hints      (const AddrInfoHints& val) { _hints     = val; return this; }
    RequestSP on_resolve (const resolve_fn& val)    { event.add(val);   return this; }
    RequestSP use_cache  (bool val)                 { _use_cache = val; return this; }
    RequestSP timeout    (uint64_t val)             { _timeout   = val; return this; }

    RequestSP run () {
        RequestSP self = this;
        _resolver->resolve(self);
        return self;
    }

    void cancel (const std::error_code& = make_error_code(std::errc::operation_canceled));

protected:
    ~Request ();

private:
    friend Resolver;

    LoopSP        loop;      // keep loop (for loop resolvers where resolver doesn't have strong ref to loop)
    ResolverSP    _resolver; // keep resolver
    string        _node;
    string        _service;
    uint16_t      _port;
    AddrInfoHints _hints;
    resolve_fn    _callback;
    bool          _use_cache;
    uint64_t      _timeout;
    Worker*       worker;
    TimerSP       timer;
    uint64_t      delayed;
    bool          running;
    bool          queued;
};

inline Resolver::RequestSP Resolver::resolve () { return new Request(this); }

inline Resolver::RequestSP Resolver::resolve (string node, resolve_fn callback, uint64_t timeout) {
    return resolve()->node(node)->on_resolve(callback)->timeout(timeout)->run();
}

std::ostream& operator<< (std::ostream&, const Resolver::CacheKey&);

}}
