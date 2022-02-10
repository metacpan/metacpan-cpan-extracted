#include "ServerConnection.h"
#include "Server.h"
#include "panda/protocol/http/Request.h"
#include "panda/unievent/forward.h"
#include <panda/encode/base16.h>

namespace panda { namespace unievent { namespace websocket {

ServerConnection::ServerConnection (Server* server, const ConnectionData& data, const Config& conf)
    : _id(data.id), server(server)
{
    panda_log_notice("id = " << _id);
    init(parser, server->loop());
    configure(conf);
    set_stream(data.stream);
    _state = State::CONNECTING;
}

void ServerConnection::handshake(const protocol::http::RequestSP& req) {
    // TODO: implement better without stringification
    auto buf = req->to_string();
    panda_log_debug("Websocket handshake:" << log::escaped{buf});

    assert(!parser.accept_parsed());

    auto creq = parser.accept(buf);
    assert(creq); // buf must be a full http request

    if (creq->error()) panda_log_notice("Websocket accept error: " << creq->error());

    on_handshake(creq);
    if (_state != State::CONNECTING) return; // connection might get removed in callback

    // automatically send appropriate handshake http response if user hasn't done it in callback
    if (!handshake_response_sent) {
        // here we pass empty objects because everything needed by RFC will be filled with defaults by websocket parser
        if (creq->error()) send_accept_error(new protocol::http::Response());
        else               send_accept_response(new ConnectResponse());
    }

    if (creq->error()) {
        close();
        return;
    }

    _state = State::CONNECTED;
    on_connection(creq);
}

void ServerConnection::on_handshake(const ConnectRequestSP& req) {
    server->on_handshake(this, req);
}

void ServerConnection::on_connection(const ConnectRequestSP& req) {
    server->on_connection(this, req);
}

void ServerConnection::send_accept_error (panda::protocol::http::Response* res) {
    if (handshake_response_sent) throw std::logic_error("handshake response has been already sent");
    handshake_response_sent = true;
    stream()->write(parser.accept_error(res));
    close();
}

void ServerConnection::send_accept_response (ConnectResponseSP res) {
    if (handshake_response_sent) throw std::logic_error("handshake response has been already sent");
    handshake_response_sent = true;

    stream()->write(parser.accept_response(res));

    auto using_deflate = parser.is_deflate_active();
    panda_log_notice("websocket::ServerConnection " << id() << " has been accepted, deflate is " << (using_deflate ? "on" : "off"));

    panda_log_debug([&]{
        auto deflate_cfg = parser.effective_deflate_config();
        if (deflate_cfg) {
            log << "websocket::ServerConnection " << id() << " agreed deflate settings"
                << ": server_max_window_bits = " << (int)deflate_cfg->server_max_window_bits
                << ", client_max_window_bits = " << (int)deflate_cfg->client_max_window_bits
                << ", server_no_context_takeover = " << deflate_cfg->server_no_context_takeover
                << ", client_no_context_takeover = " << deflate_cfg->client_no_context_takeover;
        }
    });
}

void ServerConnection::do_close (uint16_t code, const string& payload) {
    auto state_was = _state;
    Connection::do_close(code, payload);
    if (server) server->remove_connection(this, state_was, code, payload); // server might have been removed in callbacks
}

}}}
