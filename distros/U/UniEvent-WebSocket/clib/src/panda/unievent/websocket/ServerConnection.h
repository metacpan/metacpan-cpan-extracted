#pragma once
#include "Connection.h"
#include "panda/protocol/http/Request.h"
#include "panda/protocol/websocket/ConnectRequest.h"
#include "panda/protocol/websocket/ConnectResponse.h"
#include <panda/protocol/websocket/ServerParser.h>

namespace panda { namespace unievent { namespace websocket {

using ConnectRequest    = protocol::websocket::ConnectRequest;
using ConnectRequestSP  = protocol::websocket::ConnectRequestSP;
using ConnectResponse   = protocol::websocket::ConnectResponse;
using ConnectResponseSP = protocol::websocket::ConnectResponseSP;

struct Server;
struct ServerConnection;
using ServerConnectionSP = iptr<ServerConnection>;

struct ServerConnection : virtual Connection {
    using accept_fptr = void(const ServerConnectionSP&, const ConnectRequestSP&);
    using accept_fn   = function<accept_fptr>;

    struct Config : virtual Connection::Config {};

    struct ConnectionData {
        uint64_t        id;
        const StreamSP& stream;
        uint64_t        establish_time;
    };

    ServerConnection (Server*, const ConnectionData&, const Config&);

    uint64_t id () const { return _id; }

    virtual void send_accept_error    (panda::protocol::http::Response*);
    virtual void send_accept_response (ConnectResponseSP);

    template <typename T = Server> T* get_server () const { return dyn_cast<T*>(server); }

protected:
    virtual void handshake(const protocol::http::RequestSP&);

    virtual void on_handshake (const ConnectRequestSP&);
    virtual void on_connection(const ConnectRequestSP&);

    void do_close (uint16_t code, const string& payload) override;

    ~ServerConnection () {
        panda_log_verbose_debug("connection destroy " << this);
    }

private:
    using ServerParser = protocol::websocket::ServerParser;
    friend Server;

    uint64_t     _id;
    Server*      server;
    ServerParser parser;
    bool         handshake_response_sent = false;

    void endgame () { server = nullptr; }
};

}}}
