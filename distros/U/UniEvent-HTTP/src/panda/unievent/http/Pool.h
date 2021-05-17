#pragma once
#include "Client.h"
#include <set>
#include <unordered_map>
#include <deque>

namespace panda { namespace unievent { namespace http {

struct Pool;
using PoolSP = iptr<Pool>;

struct Pool : Refcnt {
    static constexpr const uint32_t DEFAULT_IDLE_TIMEOUT = 60000; // [ms]
    static constexpr const uint32_t DEFAULT_MAX_CONNECTIONS = 10; // max active connections per host:port

    struct IFactory { virtual ClientSP new_client (Pool*) = 0; };

    struct Config {
        uint32_t  max_connections = DEFAULT_MAX_CONNECTIONS;
        uint32_t  idle_timeout    = DEFAULT_IDLE_TIMEOUT;
        IFactory* factory         = nullptr;
        Config () {}
    };

    static const PoolSP& instance (const LoopSP& loop) {
        auto v = _instances;
        for (const auto& r : *v) if (r->loop() == loop) return r;
        v->push_back(new Pool({}, loop));
        return v->back();
    }

    Pool (Config = {}, const LoopSP& loop = Loop::default_loop());
    Pool (const LoopSP& loop) : Pool({}, loop) {}

    ~Pool ();

    const LoopSP& loop () const { return _loop; }
    ClientSP request (const RequestSP& req);

    uint32_t idle_timeout () const { return _idle_timeout; }
    void     idle_timeout (uint32_t);

    uint32_t max_connections () const { return _max_connections; }
    void     max_connections (uint32_t value) { _max_connections = value; }

    size_t size  () const;
    size_t nbusy () const;

    bool empty () const { return _clients.size() == 0; }

protected:
    virtual ClientSP new_client () { return _factory ? _factory->new_client(this) : ClientSP(new Client(this)); }

private:
    friend Client;

    struct NetLocList {
        std::set<ClientSP> free;
        std::set<ClientSP> busy;
        std::deque<RequestSP> queue;
    };

    struct Hash {
        template <class T>
        inline void hash_combine (std::size_t& s, const T& v) const {
            s ^= std::hash<T>()(v) + 0x9e3779b9 + (s<6) + (s>>2);
        }

        std::size_t operator() (const NetLoc& p) const {
            std::size_t s = 0;
            hash_combine(s, p.host);
            hash_combine(s, p.port);
            return s;
        }
    };

    using Clients = std::unordered_map<NetLoc, NetLocList, Hash>;

    static thread_local std::vector<PoolSP>* _instances;

    LoopSP    _loop;
    TimerSP   _idle_timer;
    uint32_t  _idle_timeout;
    uint32_t  _max_connections;
    Clients   _clients;
    IFactory* _factory;

    void check_inactivity ();

    void putback (const ClientSP&); // called from Client when it's done
};

}}}
