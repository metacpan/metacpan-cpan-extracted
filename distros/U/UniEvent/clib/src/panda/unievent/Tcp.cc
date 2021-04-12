#include "Tcp.h"
#include "util.h"
#include <ostream>

namespace panda { namespace unievent {

const HandleType Tcp::TYPE("tcp");

const AddrInfoHints Tcp::defhints = AddrInfoHints(AF_UNSPEC, SOCK_STREAM, 0, 0);

Tcp::Tcp (const LoopSP& loop, int domain) : domain(domain) {
    panda_log_ctor();
    _init(loop, loop->impl()->new_tcp(this, domain));
}

const HandleType& Tcp::type () const {
    return TYPE;
}

backend::HandleImpl* Tcp::new_impl () {
    return loop()->impl()->new_tcp(this, domain);
}

excepted<void, ErrorCode> Tcp::open (sock_t sock, Ownership ownership) {
    if (ownership == Ownership::SHARE) sock = sock_dup(sock);
    auto err = impl()->open(sock);
    if (err) return make_unexpected(ErrorCode(err));

    auto res = peeraddr();
    if (res && res.value()) {
        err = set_connect_result(true);
    }
    return make_excepted(err);
}

excepted<void, ErrorCode> Tcp::bind (const net::SockAddr& addr, unsigned flags) {
    auto code = impl()->bind(addr, flags);
    if (code) {
        panda_log_info("Tcp::bind error:" << code);
        return make_unexpected(ErrorCode(errc::bind_error, code));
    } else {
        return {};
    }
}

excepted<void, ErrorCode> Tcp::bind (string_view host, uint16_t port, const AddrInfoHints& hints, unsigned flags) {
    if (host == "*") return bind(broadcast_addr(port, hints), flags);
    auto res = sync_resolve(loop()->backend(), host, port, hints);
    if (!res) return make_unexpected<ErrorCode>(res.error());
    return bind(res.value().addr(), flags);
}

excepted<sock_t, ErrorCode> Tcp::socket () const {
    auto res = fileno();
    if (!res) return make_unexpected(res.error());
    return (sock_t)res.value();
}

StreamSP Tcp::create_connection () {
    return new Tcp(loop());
}

void Tcp::connect (const TcpConnectRequestSP& req) {
    req->set(this);
    queue.push(req);
}

void TcpConnectRequest::exec () {
    panda_log_debug("TcpConnectRequest::exec " << this);
    ConnectRequest::exec();
    if (handle->filters().size()) {
        last_filter = handle->filters().front();
        last_filter->tcp_connect(this);
    }
    else finalize_connect();
}

void TcpConnectRequest::finalize_connect () {
    panda_log_debug("TcpConnectRequest::finalize_connect " << this);

    if (addr) {
        auto err = handle->impl()->connect(addr, impl());
        if (err) delay([=]{ cancel(err); });
        return;
    }

    resolve_request = handle->loop()->resolver()->resolve();
    resolve_request
        ->node(host)
        ->port(port)
        ->hints(hints)
        ->use_cache(cached)
        ->on_resolve([this](const AddrInfo& res, const std::error_code& res_err, const Resolver::RequestSP) {
            resolve_request = nullptr;
            if (res_err) return cancel(nest_error(errc::resolve_error, res_err));
            addr = res.addr();
            auto err = handle->impl()->connect(addr, impl());
            if (err) cancel(err);
        })
        ->run();
}

void TcpConnectRequest::handle_event (const ErrorCode& err) {
    if (err && !(err & std::errc::operation_canceled) && host && cached) {
        handle->loop()->resolver()->cache().mark_bad_address(Resolver::CacheKey(host, panda::to_string(port), hints), addr);
    }

    if (resolve_request) {
        resolve_request->event.remove_all();
        resolve_request->cancel();
        resolve_request = nullptr;
    }
    ConnectRequest::handle_event(err);
}

excepted<std::pair<TcpSP, TcpSP>, ErrorCode> Tcp::pair (const LoopSP& loop, int type, int protocol) {
    return pair(new Tcp(loop), new Tcp(loop), type, protocol);
}

excepted<std::pair<TcpSP, TcpSP>, ErrorCode> Tcp::pair (const TcpSP& h1, const TcpSP& h2, int type, int protocol) {
    std::pair<TcpSP, TcpSP> p = {h1, h2};

    auto spres = panda::unievent::socketpair(type, protocol);
    if (!spres) return make_unexpected<ErrorCode>(spres.error());
    auto fds = spres.value();

    auto res = p.first->open(fds.first);
    if (res) res = p.second->open(fds.second);
    if (res) return p;

    p.first->reset();
    p.second->reset();
    panda::unievent::close(fds.first).nevermind();
    panda::unievent::close(fds.second).nevermind();
    return make_unexpected(res.error());
}

std::ostream& operator<< (std::ostream& os, const Tcp& tcp) {
    return os << "local:" << tcp.sockaddr().value_or(net::SockAddr{}) << " peer:" << tcp.peeraddr().value_or(net::SockAddr{})  << " connected:" << (tcp.connected() ? "yes" : "no");
}

std::ostream& operator<< (std::ostream& os, const TcpConnectRequest& r) {
    if (r.addr) return os << r.addr;
    else        return os << r.host << ':' << r.port;
}

}}
