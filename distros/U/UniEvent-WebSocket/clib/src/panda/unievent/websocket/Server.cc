#include "Server.h"
#include "panda/expected.h"
#include "panda/unievent/http/Server.h"
#include "panda/unievent/http/ServerRequest.h"
#include "panda/unievent/http/ServerResponse.h"
#include "panda/unievent/websocket/ServerConnection.h"
#include <panda/protocol/websocket/utils.h>
#include <panda/log.h>

using namespace std::placeholders;
namespace panda { namespace unievent { namespace websocket {
    
using protocol::websocket::string_contains_ci;

std::atomic<uint64_t> Server::lastid(0);

Server::Server (const LoopSP& loop) : running(false), _loop(loop) {
    panda_log_notice("Server(): loop is default = " << (_loop == Loop::default_loop()));
    // for websocket standalone server we use http server to make the server
    _http = new http::Server(_loop);
    // for websocket standalone server, auto-upgrade all non explicitly handled requests
    _http->request_event.add(std::bind(&Server::auto_upgrade_http_requests, this, _1));
}

void Server::on_delete () noexcept {
    try {
        stop();
        if (_http) _http->request_event.remove_all();
    }
    catch (const std::exception& e) {
        panda_log_critical("[Websocket ~Server] exception caught in while stopping server: " << e.what());
    }
    catch (...) {
        panda_log_critical("[Websocket ~Server] unknown exception caught while stopping server");
    }
    panda_log_notice("server destroy");
}

void Server::configure (const Config& conf) {
    if (conf.locations.size()) {
        _http->configure(conf);
        _listening = true;
    } else {
        _http->stop();
        _listening = false;
    }
    
    conn_conf = conf;
}

void Server::run () {
    if (running) throw std::logic_error("already running");
    running = true;
    panda_log_notice("websocket::Server::run with conn_conf:" << conn_conf);
    if (_listening) _http->run();
}

void Server::stop () { stop((uint16_t)CloseCode::AWAY); }

void Server::stop (uint16_t code) {
    if (!running) return;
    running = false;
    panda_log_notice("WebSocket server stop!");
    if (_listening) _http->stop();

    auto tmp = _connections;
    for (auto& it : tmp) {
        auto& conn = it.second;
        conn->close(code);
        conn->endgame();
        conn.reset();
    }
    // connections may not be empty if stop() is called from on_close() callback
}

void Server::start_listening () {
    if (_listening) _http->start_listening();
}

void Server::stop_listening () {
    if (_listening) _http->stop_listening();
}

const http::Server::Listeners& Server::listeners() const {
    if (!_http) {
        static http::Server::Listeners _empty;
        return _empty;
    }
    return _http->listeners();
}

excepted<net::SockAddr, ErrorCode> Server::sockaddr () const {
    if (!_http) return make_unexpected(make_error_code(std::errc::not_connected));
    return _http->sockaddr();
}

void Server::auto_upgrade_http_requests(const http::ServerRequestSP& req) {
    if (req->response()) return; // do not auto-upgrade requests that have been handled
    // do not auto-upgrade wrong requests
    if (!string_contains_ci(req->headers.connection(), "Upgrade") || !string_contains_ci(req->headers.get("Upgrade"), "websocket")) return; 
    auto res = upgrade_connection(req);
    if (!res) return; // the only case for error left here is a connection loss (race or already upgraded by user)
}

excepted<void, ErrorCode> Server::upgrade_connection(const http::ServerRequestSP& req) {
    ServerSP hold = this; (void)hold;
    auto est_time = req->connection() ? req->connection()->establish_time() : 0;
    auto res = req->upgrade();
    if (!res) return make_unexpected(res.error());
    auto stream = res.value();
    
    auto id = ++lastid;
    
    auto connection = new_connection({id, stream, est_time});
    _connections[id] = connection;
    panda_log_notice("somebody connected to " << stream->sockaddr() << ", now i have " << _connections.size() << " connections");
    
    // will accept or deny connection. will call on_handshake and on_connection on server(us)
    // connection may get closed after this method if something is wrong
    connection->handshake(req);
    
    return {};
}

ServerConnectionSP Server::new_connection (const ServerConnection::ConnectionData& data) {
    return new ServerConnection(this, data, conn_conf);
}

void Server::on_handshake(const ServerConnectionSP& conn, const ConnectRequestSP& req) {
    if (handshake_callback) handshake_callback(this, conn, req);
}

void Server::on_connection (const ServerConnectionSP& conn, const ConnectRequestSP& creq) {
    connection_event(this, conn, creq);
}

void Server::remove_connection (const ServerConnectionSP& conn, Connection::State state_was, uint16_t code, const string& payload) {
    _connections.erase(conn->id());
    panda_log_notice("[remove_connection]: now i have " << _connections.size() << " connections");
    if (state_was == Connection::State::CONNECTED) {
        on_disconnection(conn, code, payload);
    }
}

void Server::on_disconnection (const ServerConnectionSP& conn, uint16_t code, const string& payload) {
    disconnection_event(this, conn, code, payload);
}


}}}
