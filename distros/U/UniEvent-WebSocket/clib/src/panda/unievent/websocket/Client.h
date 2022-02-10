#pragma once
#include "Connection.h"
#include "panda/protocol/websocket/ConnectRequest.h"
#include "panda/protocol/websocket/ConnectResponse.h"
#include "panda/uri/URI.h"
#include <panda/unievent/Tcp.h>
#include <panda/protocol/websocket/ClientParser.h>

namespace panda { namespace unievent { namespace websocket {

using URI               = uri::URI;
using URISP             = uri::URISP;
using ConnectResponse   = protocol::websocket::ConnectResponse;
using ConnectResponseSP = protocol::websocket::ConnectResponseSP;

struct Client;
using ClientSP = iptr<Client>;

struct ClientConnectRequest : panda::protocol::websocket::ConnectRequest {
    using panda::protocol::websocket::ConnectRequest::ConnectRequest;

    unievent::AddrInfoHints addr_hints = Tcp::defhints;
    bool cached_resolver = true;
    uint64_t connect_timeout = 0;
    
    const TimerSP& timeout_timer() const { return _timer; }
    
private:
    friend Client;
    TimerSP _timer;
};
using ClientConnectRequestSP = iptr<ClientConnectRequest>;

struct Client : virtual Connection {
    using connect_fptr = void(const ClientSP&, const ConnectResponseSP&);
    using connect_fn   = function<connect_fptr>;

    struct Config : virtual Connection::Config {
        Config () {}
        bool tcp_nodelay = false;
    };

    CallbackDispatcher<connect_fptr> connect_event;

    Client (const LoopSP& loop = Loop::default_loop(), const Config& = {});

    void connect (const ClientConnectRequestSP& request);
    void connect (const string& host_path, bool secure = false, uint16_t port = 0);

protected:
    using Connection::on_connect; // suppress 'hide' warnings

    virtual void on_connect (const ConnectResponseSP& response);

    void on_connect (const ErrorCode&, const unievent::ConnectRequestSP&) override;
    void on_read    (string& buf, const ErrorCode&) override;

    void do_close (uint16_t code, const string&) override;

    ClientConnectRequestSP connect_request;
private:
    using ClientParser = protocol::websocket::ClientParser;
    
    void call_on_connect(const ConnectResponseSP& response);

    ClientParser parser;
    bool         tcp_nodelay;
};

inline string ws_scheme(bool secure = false) {
    return secure ? string("wss") : string("ws");
}

}}}
