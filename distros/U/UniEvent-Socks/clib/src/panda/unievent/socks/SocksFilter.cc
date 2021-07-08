#include "SocksFilter.h"
#include <panda/log.h>
#include <panda/string.h>
#include <panda/unievent/Tcp.h>
#include <panda/unievent/Timer.h>
#include <panda/unievent/Resolver.h>
#include <vector>

namespace panda { namespace unievent { namespace socks {

static log::Module panda_log_module("UniEvent::Socks", log::Level::Notice);

const void* SocksFilter::TYPE = &typeid(SocksFilter);

#define ERROR_SERVER_USE Error("this stream is listening but socks is a client filter only")

SocksFilter::SocksFilter (Stream* stream, const SocksSP& socks) : StreamFilter(stream, TYPE, PRIORITY), socks(socks), state(State::initial) {
    panda_log_ctor();
    if (stream->listening()) throw ERROR_SERVER_USE;
    init_parser();
}

SocksFilter::~SocksFilter () { panda_log_dtor(); }

void SocksFilter::init_parser () {
    atyp   = 0;
    rep    = 0;
    noauth = false;
}

void SocksFilter::listen () { throw ERROR_SERVER_USE; }

void SocksFilter::tcp_connect (const TcpConnectRequestSP& req) {
    panda_log_debug("tcp_connect: " << req << " state:" << state);
    if (state == State::terminal) return NextFilter::tcp_connect(req);

    if (req->addr) {
        addr = req->addr;
        if (!addr.is_inet4() && !addr.is_inet6()) throw Error("Unknown address family");
    } else {
        host  = req->host;
        port  = req->port;
        hints = req->hints;
    }

    connect_request = req;

    auto subreq = (new TcpConnectRequest())->to(socks->host, socks->port);
    state = State::connecting_proxy;
    subreq_tcp_connect(connect_request, subreq);
}

void SocksFilter::handle_connect (const ErrorCode& err, const ConnectRequestSP& req) {
    panda_log_debug("handle_connect, err: " << err << " state:" << state);
    if (state == State::terminal) return NextFilter::handle_connect(err, req);
    if (state == State::connecting_proxy) subreq_done(req); // might be cancel for connect request while resolving in do_resolve()
    
    if (err) return do_error(err);
    auto read_err = read_start();
    if (read_err) return do_error(read_err);

    if (socks->socks_resolve || addr) do_handshake(); // we have resolved the host or proxy will resolve it for us
    else                              do_resolve();   // we will resolve the host ourselves
}

void SocksFilter::handle_write (const ErrorCode& err, const WriteRequestSP& req) {
    panda_log_debug("handle_write, err: " << err << " state:" << state);
    if (state == State::terminal) return NextFilter::handle_write(err, req);
    subreq_done(req);
    if (err) return do_error(err);
}

void SocksFilter::handle_eof () {
    panda_log_debug("handle_eof, state:" << state);
    if (state == State::terminal) return NextFilter::handle_eof();

    if (state == State::parsing || state == State::handshake_reply || state == State::auth_reply || state == State::connect_reply) {
        do_error(make_error_code(std::errc::connection_aborted));
        return;
    }
}

void SocksFilter::reset () {
    panda_log_debug("reset, state:" << state);
    state = State::initial;
    NextFilter::reset();
}

void SocksFilter::do_handshake () {
    panda_log_debug("do_handshake");
    state = State::handshake_reply;
    string data = socks->loginpassw() ? string("\x05\x02\x00\x02") : string("\x05\x01\x00");
    subreq_write(connect_request, new WriteRequest(data));
}

void SocksFilter::do_auth () {
    panda_log_debug("do_auth");
    state = State::auth_reply;
    string data = string("\x01") + (char)socks->login.length() + socks->login + (char)socks->passw.length() + socks->passw;
    subreq_write(connect_request, new WriteRequest(data));
}

void SocksFilter::do_resolve () {
    panda_log_debug("do_resolve_host");
    state = State::resolving_host;
    resolve_request = handle->loop()->resolver()->resolve()
        ->node(host)
        ->port(port)
        ->hints(hints)
        ->use_cache(connect_request->cached)
        ->on_resolve([this](const AddrInfo& ai, const std::error_code& err, const Resolver::RequestSP&) {
            panda_log_debug("resolved, err: " << err);
            if (err) return do_error(unievent::nest_error(unievent::errc::resolve_error, err));
            addr = ai.addr();
            resolve_request = nullptr;
            do_handshake();
        })
    ->run();
}

void SocksFilter::do_connect () {
    panda_log_debug("do_connect");
    state = State::connect_reply;
    string data;
    if (addr) {
        if (addr.is_inet4()) {
            auto& sa4 = addr.as_inet4();
            data = string("\x05\x01\x00\x01") + string_view((char*)&sa4.addr(), 4) + string_view((char*)&sa4.get()->sin_port, 2);
        } else {
            auto& sa6 = addr.as_inet6();
            data = string("\x05\x01\x00\x04") + string((char*)&sa6.addr(), 16) + string((char*)&sa6.get()->sin6_port, 2);
        }
    } else {
        uint16_t nport = htons(port);
        data = string("\x05\x01\x00\x03") + (char)host.length() + host + string((char*)&nport, 2);
    }
    subreq_write(connect_request, new WriteRequest(data));
}

void SocksFilter::do_connected () {
    panda_log_debug("do_connected");
    state = State::terminal;
    read_stop();
    auto creq = connect_request;
    connect_request = nullptr;
    NextFilter::handle_connect({}, creq);
}

void SocksFilter::do_error (const ErrorCode& err) {
    panda_log_debug("do_error");
    if (state == State::error) return;

    if (resolve_request) {
        resolve_request->event.remove_all();
        resolve_request->cancel();
        resolve_request = nullptr;
    }

    read_stop();
    init_parser();

    state = (err & std::errc::operation_canceled) ? State::initial : State::error;

    auto creq = connect_request;
    connect_request = nullptr;
    NextFilter::handle_connect(unievent::nest_error(errc::socks_error, err), creq);
}

std::ostream& operator<< (std::ostream& s, SocksFilter::State state) {
    return s << int(state);
}

}}}
