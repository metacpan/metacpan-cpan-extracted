#include "Client.h"
#include <panda/encode/base16.h>

namespace panda { namespace unievent { namespace websocket {

static ConnectResponseSP cres_from_cerr (const ErrorCode& err) {
    ConnectResponseSP res = new ConnectResponse();
    res->error(nest_error(errc::CONNECT_ERROR, err));
    return res;
}

Client::Client (const LoopSP& loop, const Config& conf) : tcp_nodelay(conf.tcp_nodelay) {
    init(parser, loop);
    configure(conf);
}

void Client::connect (const ClientConnectRequestSP& request) {
    if (_state != State::INITIAL) throw std::logic_error("can't connect(): you should close() the client connection first");
    parser.reset();

    if (!request || !request->uri) throw std::invalid_argument("ConnectRequest should contains uri");

    auto port = request->uri->port();
    panda_log_notice("connecting to " << request->uri->host() << ":" << port << " timeout " << request->connect_timeout << "ms");

    TcpSP tcp = new Tcp(loop());
    set_stream(tcp);

    if (request->uri->secure()) tcp->use_ssl();

    tcp->connect()->to(request->uri->host(), port)
                  ->use_cache(request->cached_resolver)
                  ->set_hints(request->addr_hints)
                  ->timeout(request->connect_timeout)
                  ->run();

    if (tcp_nodelay) try {
        tcp->set_nodelay(true);
    } catch (unievent::Error& e) {} // ignore errors, set_nodelay is optional

    connect_request = request;

    tcp->write(parser.connect_request(request));
    _state = State::TCP_CONNECTING;
}

void Client::connect(const string& host_path, bool secure, uint16_t port) {
    ClientConnectRequestSP req = new ClientConnectRequest();
    req->uri = new URI(host_path, URI::Flags::allow_suffix_reference);
    req->uri->scheme(ws_scheme(secure));
    if (port) req->uri->port(port);
    connect(req);
}

void Client::do_close (uint16_t code, const string& payload) {
    bool connecting = _state == State::CONNECTING;
    Connection::do_close(code, payload);
    if (connecting) {
        panda_log_notice("Client::close: connect started but not completed");
        call_on_connect(cres_from_cerr(make_error_code(std::errc::operation_canceled)));
    }
}

void Client::call_on_connect(const ConnectResponseSP &response) {
    panda_log_notice("websocket::Client::on_connect " << response->error());
    if (connect_request->_timer) {
        connect_request->_timer->pause();
        connect_request->_timer->event.remove_all();
    }

    if (response->error()) {
        _state = State::HALT;
    }
    on_connect(response);
}

void Client::on_connect (const ConnectResponseSP& response) {
    connect_event(this, response);
}

void Client::on_connect (const ErrorCode& err, const unievent::ConnectRequestSP& stream_creq) {
    panda_log_debug("websocket::Client::on_connect(unievent) " <<  err);
    if (err) {
        call_on_connect(cres_from_cerr(err));
        return;
    }

    if (connect_request->connect_timeout) {
        connect_request->_timer = stream_creq->timeout_timer();
        connect_request->_timer->event.add([this](auto&){
            ClientSP self = this; (void)self; // callback is last line, but just in case of loosing last ref in callback and new code after it
            Connection::do_close(CloseCode::ABNORMALLY, "");
            call_on_connect(cres_from_cerr(make_error_code(std::errc::timed_out)));
        });
        connect_request->_timer->resume();
    }

    _state = State::CONNECTING;
    stream()->read_start();
}

void Client::on_read (string& buf, const ErrorCode& err) {
    ClientSP hold = this; (void)hold;
    if (_state == State::INITIAL) { // just ignore everything, we are here after close
        panda_log_info("use websocket::Client after close");
        return;
    }

    if (_state == State::CONNECTED) return Connection::on_read(buf, err);
    if (_state != State::CONNECTING) { // may be read in state TCP_CONNECTED
        panda_log_info("ignore all reads if !CONNECTING and !CONNECTED");
        return;
    }

    if (err) return call_on_connect(cres_from_cerr(make_error_code(std::errc::operation_canceled)));

    panda_log_debug("Websocket on read (connecting):" << log::escaped{buf});

    auto res = parser.connect(buf);
    if (!res) return;

    if (parser.established()) _state = State::CONNECTED;
    call_on_connect(res);

    string empty;
    if (_state == State::CONNECTED) Connection::on_read(empty, err); // in case of messages in buffer with handshake
}

}}}
