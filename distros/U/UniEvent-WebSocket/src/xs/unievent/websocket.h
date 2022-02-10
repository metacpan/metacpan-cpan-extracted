#pragma once
#include "panda/unievent/websocket/ServerConnection.h"
#include "xs/typemap/object.h"
#include <xs/unievent.h>
#include <xs/unievent/http.h>
#include <xs/protocol/websocket.h>
#include <panda/unievent/websocket.h>

namespace xs { namespace unievent  { namespace websocket {
    using namespace panda::unievent::websocket;
    using panda::unievent::LoopSP;
    using panda::unievent::StreamSP;

    inline uint64_t get_time (double val)   { return val * 1000; }
    inline double   out_time (uint64_t val) { return (double)val / 1000; }

    struct XSClient : Client, Backref {
        XSClient (const LoopSP& loop, const Client::Config& config) : Client(loop, config) {}
    private:
        ~XSClient () { Backref::dtor(); }
    };

    struct XSServerConnection : ServerConnection, Backref {
        XSServerConnection (Server* server, const ServerConnection::ConnectionData& data, const Config& conf)
            : ServerConnection(server, data, conf) {}
    private:
        ~XSServerConnection () { Backref::dtor(); }
    };

    struct XSConnectionIterator {
        XSConnectionIterator (const Server::Connections& connections) {
            cur = connections.begin();
            end = connections.end();
        }

        Scalar next() {
            if (cur == end) return Scalar::undef;
            Scalar res = xs::out(cur->second);
            ++cur;
            return res;
        }

    private:
        using iterator = Server::Connections::const_iterator;

        iterator cur;
        iterator end;
    };

    struct XSServer : Server, Backref {
        using Server::Server;

        ServerConnectionSP new_connection (const ServerConnection::ConnectionData& data) override {
            ServerConnectionSP ret = new XSServerConnection(this, data, conn_conf);
            xs::out(ret); // fill backref
            return ret;
        }

    private:
        ~XSServer () { Backref::dtor(); }
    };

    inline ClientConnectRequestSP  make_request  (const Hash& params, const ClientConnectRequestSP& dest = {}) {
        ClientConnectRequestSP ret = dest ? dest : ClientConnectRequestSP(new ClientConnectRequest());
        xs::protocol::websocket::make_request(params, ret);

        Scalar val;

        if ((val = params.fetch("addr_hints")))      ret->addr_hints = xs::in<panda::unievent::AddrInfoHints>(val);
        if ((val = params.fetch("cached_resolver"))) ret->cached_resolver = SvTRUE(val);
        if ((val = params.fetch("timeout")))         ret->connect_timeout = get_time(val.number());

        return ret;
    }
    
    static inline void connection_config_in (Connection::Config& cfg, const Hash& h) {
        xs::protocol::websocket::parser_config_in(cfg, h);
        Scalar val;
        if ((val = h.fetch("shutdown_timeout"))) cfg.shutdown_timeout = get_time(val.number());
    }
    
    static inline Hash connection_config_out (const Connection::Config& cfg) {
        auto ret = xs::protocol::websocket::parser_config_out(cfg);
        ret.store("shutdown_timeout", xs::out(out_time(cfg.shutdown_timeout)));
        return ret;
    }
    
    static inline void client_config_in (Client::Config& cfg, const Hash& h) {
        connection_config_in(cfg, h);
        Scalar val;
        if ((val = h.fetch("tcp_nodelay"))) cfg.tcp_nodelay = val.is_true();
    }
    
    static inline Hash client_config_out (const Client::Config& cfg) {
        auto ret = connection_config_out(cfg);
        ret.store("tcp_nodelay", xs::out(cfg.tcp_nodelay));
        return ret;
    }
    
    static inline void server_connection_config_in (ServerConnection::Config& cfg, const Hash& h) {
        connection_config_in(cfg, h);
    }
    
    static inline Hash server_connection_config_out (const ServerConnection::Config& cfg) {
        return connection_config_out(cfg);
    }

}}}

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::websocket::Server*, TYPE> :
    TypemapObject<panda::unievent::websocket::Server*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast>
{
    static std::string package () { return "UniEvent::WebSocket::Server"; }
};

template <class TYPE> struct Typemap<panda::unievent::websocket::Connection*, TYPE>
    : TypemapObject<panda::unievent::websocket::Connection*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast>
{
    static std::string package () { throw "can't return abstract class without backref"; }
};

template <class TYPE> struct Typemap<panda::unievent::websocket::ServerConnection*, TYPE> : Typemap<panda::unievent::websocket::Connection*, TYPE> {
    static std::string package () { return "UniEvent::WebSocket::ServerConnection"; }
};

template <class TYPE> struct Typemap<panda::unievent::websocket::Client*, TYPE> : Typemap<panda::unievent::websocket::Connection*, TYPE> {
    static std::string package () { return "UniEvent::WebSocket::Client"; }
};

template <class TYPE> struct Typemap<xs::unievent::websocket::XSConnectionIterator*, TYPE> :
    TypemapObject<xs::unievent::websocket::XSConnectionIterator*, TYPE, ObjectTypePtr, ObjectStorageMG, StaticCast>
{
    static std::string package () { return "UniEvent::WebSocket::XSConnectionIterator"; }
};

template <class TYPE> struct Typemap<unievent::websocket::Connection::Statistics*, TYPE> :
    TypemapObject<xs::unievent::websocket::Connection::Statistics*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG, StaticCast>
{
    static std::string package () { return "UniEvent::WebSocket::Connection::Statistics"; }
};

template <> struct Typemap<unievent::websocket::Connection::Statistics>  {
    static Ref out(const unievent::websocket::Connection::Statistics& s, const Sv& = Sv()) {
        return Ref::create(Hash {
            {"msgs_in",  xs::out<size_t>(s.msgs_in)},
            {"msgs_out", xs::out<size_t>(s.msgs_out)},
            {"bytes_in",  xs::out<size_t>(s.bytes_in)},
            {"bytes_out", xs::out<size_t>(s.bytes_out)}
        });
    }
};

template <class TYPE> struct Typemap<xs::unievent::websocket::ClientConnectRequest*, TYPE> :
    Typemap<xs::protocol::websocket::ConnectRequest*, TYPE>
{
    static std::string package () { return "UniEvent::WebSocket::ConnectRequest"; }
};

template <class TYPE>
struct Typemap<xs::unievent::websocket::ClientConnectRequestSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static panda::iptr<TYPE> in (Sv arg) {
        if (!arg.defined()) return {};
        if (arg.is_object_ref()) return Super::in(arg);
        panda::iptr<TYPE> ret = make_backref<TYPE>();
        xs::unievent::websocket::make_request(arg, ret.get());
        return ret;
    }
};

template <class TYPE> struct Typemap<panda::unievent::websocket::Client::Config, TYPE>
{
    static TYPE in (SV* arg) {
        TYPE cfg;
        xs::unievent::websocket::client_config_in(cfg, arg);
        return cfg;
    }

    static Sv out (TYPE var, const Sv& = Sv()) {
        return Ref::create(xs::unievent::websocket::client_config_out(var));
    }
};


template <class TYPE> struct Typemap<panda::unievent::websocket::ServerConnection::Config, TYPE>
{
    static TYPE in (SV* arg) {
        TYPE cfg;
        xs::unievent::websocket::server_connection_config_in(cfg, arg);
        return cfg;
    }

    static Sv out (TYPE var, const Sv& = Sv()) {
        return Ref::create(xs::unievent::websocket::server_connection_config_out(var));
    }
};

template <class TYPE> struct Typemap<panda::unievent::websocket::Server::Config, TYPE>
    : Typemap<panda::unievent::http::Server::Config, TYPE>
{
    using Super = Typemap<panda::unievent::http::Server::Config, TYPE>;
    
    static TYPE in (SV* arg) {
        auto cfg = Super::in(arg);
        auto deprecated = Hash(arg).fetch("connection");
        if (deprecated) unievent::websocket::server_connection_config_in(cfg, deprecated);
        unievent::websocket::server_connection_config_in(cfg, arg);
        return cfg;
    }

    static Sv out (TYPE var, const Sv& = Sv()) {
        auto ret = Super::out(var);
        Hash h = ret;
        Hash h2 = unievent::websocket::server_connection_config_out(var);
        for (auto& row : h2) h[row.key()] = row.value();
        return ret;
    }
};

}
