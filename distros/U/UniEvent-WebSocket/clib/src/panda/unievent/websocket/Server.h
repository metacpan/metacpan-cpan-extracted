#pragma once
#include <map>
#include <vector>
#include <atomic>
#include "ServerConnection.h"
#include "panda/protocol/websocket/ConnectRequest.h"
#include "panda/unievent/forward.h"
#include "panda/unievent/http/ServerConnection.h"
#include "panda/unievent/http/ServerRequest.h"
#include <panda/unievent/http/Server.h>

namespace panda { namespace unievent { namespace websocket {

using ConnectRequest   = protocol::websocket::ConnectRequest;
using ConnectRequestSP = protocol::websocket::ConnectRequestSP;

struct Server;
using ServerSP = iptr<Server>;

struct Server : virtual Refcntd {
    using Connections        = std::map<uint64_t, ServerConnectionSP>;
    using handshake_fn       = function<void(const ServerSP&, const ServerConnectionSP&, const ConnectRequestSP&)>;
    using connection_fptr    = void(const ServerSP&, const ServerConnectionSP&, const ConnectRequestSP&);
    using connection_fn      = function<connection_fptr>;
    using disconnection_fptr = void(const ServerSP&, const ServerConnectionSP&, uint16_t code, const string& payload);
    using disconnection_fn   = function<disconnection_fptr>;
    
    using Location = http::Server::Location;

    struct Config : http::Server::Config, virtual ServerConnection::Config {};
    
    handshake_fn                           handshake_callback;
    CallbackDispatcher<connection_fptr>    connection_event;
    CallbackDispatcher<disconnection_fptr> disconnection_event;

    Server (const LoopSP& loop = Loop::default_loop());

    virtual void configure(const Config&);
    
    const LoopSP& loop() const { return _loop; }
    
    virtual void run ();
    virtual void stop();
    virtual void stop(uint16_t code);

    void start_listening();
    void stop_listening ();
    
    void close_connection(const ServerConnectionSP& conn, uint16_t code)  { conn->close(code); }
    void close_connection(const ServerConnectionSP& conn, int code)       { conn->close(code); }

    template <class Conn = ServerConnection>
    iptr<Conn> get_connection(uint64_t id) {
        auto iter = _connections.find(id);
        if (iter == _connections.end()) return {};
        else return dynamic_pointer_cast<Conn>(iter->second);
    }

    const http::Server::Listeners& listeners() const;
    const Connections&             connections() { return _connections; }
    
    excepted<net::SockAddr, ErrorCode> sockaddr() const;
    
    excepted<void, ErrorCode> upgrade_connection(const unievent::http::ServerRequestSP&);
    
    const http::ServerSP& http() const { return _http; }

protected:
    bool        running;
    Connections _connections;
    ServerConnection::Config conn_conf;

    virtual ServerConnectionSP new_connection(const ServerConnection::ConnectionData&);

    virtual void on_handshake    (const ServerConnectionSP& conn, const ConnectRequestSP&);
    virtual void on_connection   (const ServerConnectionSP& conn, const ConnectRequestSP&);
    virtual void on_disconnection(const ServerConnectionSP& conn, uint16_t = uint16_t(CloseCode::ABNORMALLY), const string& = {});

    void on_delete() noexcept override;

private:
    friend ServerConnection;

    static std::atomic<uint64_t> lastid;

    LoopSP         _loop;
    http::ServerSP _http;
    bool           _listening = false;
    
    void auto_upgrade_http_requests(const http::ServerRequestSP&);

    void remove_connection(const ServerConnectionSP&, Connection::State, uint16_t code, const string& payload);
};

inline std::ostream& operator<<(std::ostream& stream, const Server::Config& conf) {
    stream << "Server::Config{ locations:[";
    for (auto loc : conf.locations) stream << loc << ",";
    stream << "]};";
    return stream;
}

}}}
