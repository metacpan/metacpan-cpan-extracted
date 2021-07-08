#include "Server.h"
#include <ostream>
#include <algorithm>
#include <panda/time.h>

namespace panda { namespace unievent { namespace http {

string rfc822_date (time::ptime_t);

std::atomic<uint64_t> Server::lastid(0);

Server::Server (const LoopSP& loop, IFactory* fac) : _loop(loop), _factory(fac) {}

Server::Server (const Config& conf, const LoopSP& loop, IFactory* fac) : Server(loop, fac) {
    configure(conf);
}

Server::~Server() {
    // close all connections to stop any delayed callbacks and self holdings, e.g. on_write. Connections should not leave longer than Server.
    // it can not lead to user callback because active http::Requests are impossible in Server dtor, so no retry or any sort of infinite loop
    while (_connections.size()) {
        _connections.begin()->second->close(make_error_code(std::errc::connection_reset));
    }
}

void Server::configure (const Config& conf) {
    if (!conf.locations.size()) throw HttpError("no locations to listen supplied");

    for (auto& loc : conf.locations) {
        if (!loc.host && !loc.sock) throw HttpError("neither host nor socket defined in one of the locations");
    }

    if (running()) stop_listening();

    _conf = conf;
    for (auto& loc : _conf.locations) {
        if (!loc.backlog) loc.backlog = DEFAULT_BACKLOG;
    }

    if (running()) start_listening();
}

void Server::run () {
    if (_state != State::initial) throw HttpError("server is already running");
    _state = State::running;
    start_listening();
    run_event();
}

void Server::stop () {
    if (!running() && _state != State::stopping) return;
    stop_listening();
    panda_log_notice("stopping HTTP server with " << _connections.size() << " connections");
    while (_connections.size()) _connections.begin()->second->close(errc::server_stopping);
    _state = State::initial;
    stop_event();
}

void Server::graceful_stop () {
    if (!running()) return;
    _state = State::stopping;
    stop_listening();
    panda_log_notice("gracefully stopping HTTP server with " << _connections.size() << " connections");

    std::vector<ServerConnectionSP> list;
    for (auto& row : _connections) list.push_back(row.second);
    for (auto& conn : list) conn->graceful_stop();
    _stop_if_done();
}

void Server::start_listening () {
    if (_listeners.size()) throw HttpError("server is already listening");
    for (auto& loc : _conf.locations) {
        TcpSP lst;

        if (loc.sock) {
            lst = new Tcp(_loop);
            lst->open(loc.sock.value());
        } else {
            lst = new Tcp(_loop, loc.domain);

            if (loc.reuse_port) {
                #ifdef _WIN32
                panda_log_warning("ignored reuse_port configuration parameter: not supported on windows");
                #else
                int on = 1;
                lst->setsockopt(SOL_SOCKET, SO_REUSEPORT, &on, sizeof(on));
                #endif
            }

            lst->bind(loc.host, loc.port);
        }

        lst->listen(loc.backlog);
        if (loc.ssl_ctx) lst->use_ssl(loc.ssl_ctx);

        lst->event_listener(this);

        panda_log_notice("listening: " << (loc.ssl_ctx ? "https://" : "http://") << (loc.sock ? lst->sockaddr()->ip() : loc.host) << ":" << lst->sockaddr()->port());
        _listeners.push_back(lst);
    }
}

void Server::stop_listening () {
    _listeners.clear();
}

StreamSP Server::create_connection (const StreamSP&) {
    ServerConnection::Config cfg {_conf.idle_timeout, _conf.max_keepalive_requests, _conf.max_headers_size, _conf.max_body_size, _factory};
    return new_connection(++lastid, cfg);
}

ServerConnectionSP Server::new_connection (uint64_t id, const ServerConnection::Config& conf) {
    ServerConnectionSP conn = new ServerConnection(this, id, conf);
    if (_conf.tcp_nodelay) conn->set_nodelay(true);
    return conn;
}

void Server::on_connection (const StreamSP& stream, const ErrorCode& err) {
    if (err) return;
    auto connection = dynamic_pointer_cast<ServerConnection>(stream);
    assert(connection);
    _connections[connection->id()] = connection;
    connection->start();
    panda_log_info("client connected to " << connection->sockaddr() << ", id=" << connection->id() << ", total connections: " << _connections.size());
}

const string& Server::date_header_now () {
    if (!_hdate_time || _hdate_time <= _loop->now() - 1000) {
        _hdate_time = _loop->now();
        _hdate_str  = rfc822_date(std::time(0));
    }
    return _hdate_str;
}

const char month_snames[12][4] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
const char day_snames   [7][4] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};

// adapted from apr_rfc822_date, https://apr.apache.org
string rfc822_date (time::ptime_t epoch) {
    time::datetime dt;
    time::gmtime(epoch, &dt);

    size_t length = sizeof("Mon, 20 Jan 2020 20:20:20 GMT") - 1;
    string result(length);
    result.length(length);
    char* date_str = result.buf();

    const char* s = &day_snames[dt.wday][0];
    *date_str++   = *s++;
    *date_str++   = *s++;
    *date_str++   = *s++;
    *date_str++   = ',';
    *date_str++   = ' ';
    *date_str++   = dt.mday / 10 + '0';
    *date_str++   = dt.mday % 10 + '0';
    *date_str++   = ' ';
    s             = &month_snames[dt.mon][0];
    *date_str++   = *s++;
    *date_str++   = *s++;
    *date_str++   = *s++;
    *date_str++   = ' ';

    *date_str++ = dt.year / 1000 + '0';
    *date_str++ = dt.year % 1000 / 100 + '0';
    *date_str++ = dt.year % 100 / 10 + '0';
    *date_str++ = dt.year % 10 + '0';
    *date_str++ = ' ';
    *date_str++ = dt.hour / 10 + '0';
    *date_str++ = dt.hour % 10 + '0';
    *date_str++ = ':';
    *date_str++ = dt.min / 10 + '0';
    *date_str++ = dt.min % 10 + '0';
    *date_str++ = ':';
    *date_str++ = dt.sec / 10 + '0';
    *date_str++ = dt.sec % 10 + '0';
    *date_str++ = ' ';
    *date_str++ = 'G';
    *date_str++ = 'M';
    *date_str++ = 'T';

    return result;
}

std::ostream& operator<< (std::ostream& os, const Server::Location& location) {
    os << "{uri: " << (location.ssl_ctx ? "https://" : "http://");
    if (location.sock) {
        auto res = unievent::getsockname(location.sock.value());
        if (res) {
            auto sa = res.value();
            #ifndef _WIN32
            if (sa.is_unix()) os << "<unix:" << sa.as_unix().path() << ">";
            else
            #endif
            { os << sa.ip() << ":" << sa.port(); }
        } else {
            os << "<unknown custom socket>";
        }
    } else {
        os << location.host << ":" << location.port;
    }
    if (location.reuse_port) os << ", reuse_port: true";
    os << ", backlog: " << location.backlog;
    os << "}";
    return os;
}

std::ostream& operator<< (std::ostream& os, const Server::Config& conf) {
    os << "{";
    os << "idle_timeout: " << (conf.idle_timeout / 1000) << "s";
    os << ", max_headers_size: " << conf.max_headers_size;
    if (conf.max_body_size != panda::protocol::http::SIZE_UNLIMITED) os << ", max_body_size: " << conf.max_body_size;
    if (conf.max_keepalive_requests) os << ", max_keepalive_requests: " << conf.max_keepalive_requests;
    if (conf.tcp_nodelay) os << ", tcp_nodelay: true";
    os << ", locations: [";
    for (auto loc : conf.locations) os << loc << ", ";
    os << "]}";
    return os;
}

bool Server::Location::operator== (const Location& oth) const {
    return host == oth.host && port == oth.port && reuse_port == oth.reuse_port && backlog == oth.backlog &&
           domain == oth.domain && ssl_ctx == oth.ssl_ctx && sock == oth.sock;
}

bool Server::Config::operator== (const Config& oth) const {
    return idle_timeout == oth.idle_timeout && max_headers_size == oth.max_headers_size && max_body_size == oth.max_body_size &&
           tcp_nodelay == oth.tcp_nodelay && max_keepalive_requests == oth.max_keepalive_requests &&
           locations.size() == oth.locations.size() && std::equal(locations.begin(), locations.end(), oth.locations.begin());
}

}}}
