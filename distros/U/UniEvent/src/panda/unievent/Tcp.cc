#include "Tcp.h"
#include "util.h"
#include <ostream>

namespace panda { namespace unievent {

const HandleType Tcp::TYPE("tcp");

AddrInfoHints Tcp::defhints = AddrInfoHints(AF_UNSPEC, SOCK_STREAM, 0, AddrInfoHints::PASSIVE);

Tcp::Tcp (const LoopSP& loop, int domain) : domain(domain) {
    _ECTOR();
    _init(loop, loop->impl()->new_tcp(this, domain));
}

const HandleType& Tcp::type () const {
    return TYPE;
}

backend::HandleImpl* Tcp::new_impl () {
    return loop()->impl()->new_tcp(this, domain);
}

void Tcp::open (sock_t sock, Ownership ownership) {
    if (ownership == Ownership::SHARE) sock = sock_dup(sock);
    impl()->open(sock);
    if (peeraddr()) {
        auto err = set_connect_result(true);
        if (err) throw Error(err);
    }
}

excepted<void, ErrorCode> Tcp::bind (const net::SockAddr& addr, unsigned flags) {
    auto code = impl()->bind(addr, flags);
    if (code) {
        panda_mlog_info(uelog, "Tcp::bind error:" << code);
        return make_unexpected(ErrorCode(errc::bind_error, code));
    } else {
        return {};
    }
}

excepted<void, ErrorCode> Tcp::bind (string_view host, uint16_t port, const AddrInfoHints& hints, unsigned flags) {
    if (host == "*") return bind(broadcast_addr(port, hints), flags);
    auto ai = sync_resolve(loop()->backend(), host, port, hints);
    return bind(ai.addr(), flags);
}

StreamSP Tcp::create_connection () {
    return new Tcp(loop());
}

void Tcp::connect (const TcpConnectRequestSP& req) {
    req->set(this);
    queue.push(req);
}

void TcpConnectRequest::exec () {
    panda_mlog_debug(uelog, "TcpConnectRequest::exec " << this);
    ConnectRequest::exec();
    if (handle->filters().size()) {
        last_filter = handle->filters().front();
        last_filter->tcp_connect(this);
    }
    else finalize_connect();
}

void TcpConnectRequest::finalize_connect () {
    panda_mlog_debug(uelog, "TcpConnectRequest::finalize_connect " << this);

    if (addr) {
        auto err = handle->impl()->connect(addr, impl());
        if (err) delay([=]{ cancel(err); });
        return;
    }

    if (!resolve_request) {
        resolve_request = handle->loop()->resolver()->resolve();
    }
    if (host) {
        resolve_request->node(host);
    }
    if (port) {
        resolve_request->port(port);
    }

    resolve_request
       ->hints(hints)
       ->use_cache(cached)
       ->on_resolve([this](const AddrInfo& res, const std::error_code& res_err, const Resolver::RequestSP) {
           resolve_request = nullptr;
           if (res_err) return cancel(nest_error(errc::resolve_error, res_err));
           auto err = handle->impl()->connect(res.addr(), impl());
           if (err) cancel(err);
       });
    resolve_request->run();
}

void TcpConnectRequest::handle_event (const ErrorCode& err) {
    if (resolve_request) {
        resolve_request->event.remove_all();
        resolve_request->cancel();
        resolve_request = nullptr;
    }
    ConnectRequest::handle_event(err);
}


std::ostream& operator<< (std::ostream& os, const Tcp& tcp) {
    return os << "local:" << tcp.sockaddr() << " peer:" << tcp.peeraddr() << " connected:" << (tcp.connected() ? "yes" : "no");
}

std::ostream& operator<< (std::ostream& os, const TcpConnectRequest& r) {
    if (r.addr) return os << r.addr;
    else        return os << r.host << ':' << r.port;
}

}}
