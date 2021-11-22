#include "test.h"
#include <openssl/err.h>
#include <openssl/dh.h>
#include <openssl/ssl.h>
#include <openssl/conf.h>
#include <openssl/engine.h>
#include <chrono>
#include <iostream>

using panda::unievent::Timer;
using panda::unievent::TimerSP;

bool secure = false;
int TServer::dcnt;
int TClient::dcnt;

static int64_t _time_mark;

string active_scheme() { return string(secure ? "https" : "http"); }

int64_t get_time () {
    using namespace std::chrono;
    return duration_cast< milliseconds >(steady_clock::now().time_since_epoch()).count();
}

void    time_mark    () { _time_mark = get_time(); }
int64_t time_elapsed () { return get_time() - _time_mark; }

std::vector<ResponseSP> await_responses (const std::vector<RequestSP>& reqs, const LoopSP& loop) {
    std::vector<ResponseSP> r;
    for (auto& req : reqs) {
        req->response_event.add([&](auto, auto& res, auto& err){
            if (err) throw err.what();
            r.emplace_back(res);
            if (r.size() == reqs.size()) loop->stop();
        });
    }
    loop->run();
    return r;
}

ResponseSP await_any (const std::vector<RequestSP>& reqs, const LoopSP& loop) {
    ResponseSP r;
    for (auto& req : reqs) {
        req->response_event.add([&](auto, auto& res, auto& err){
            if (err) throw err;
            r = res;
            loop->stop();
        });
    }
    loop->run();
    return r;
}

ResponseSP await_response (const RequestSP& req, const LoopSP& loop) { return await_responses({req}, loop)[0]; } 

TServerSP make_server (const LoopSP& loop, Server::Config cfg) {
    TServerSP server = new TServer(loop);

    if (!cfg.locations.size()) {
        Server::Location loc;
        loc.host = "127.0.0.1";
        if (secure) { loc.ssl_ctx = TServer::get_context("ca"); }
        cfg.locations.push_back(loc);
    } else if (secure) {
        cfg.locations.front().ssl_ctx = TServer::get_context("ca");
    }

    cfg.tcp_nodelay = true;
    server->configure(cfg);

    server->run();
    return server;
}

TServerSP make_ssl_server (const LoopSP& loop) {
    auto server_ctx = TServer::get_context("ca");
    auto err = SSL_CTX_load_verify_locations(server_ctx, "tests/cert/ca.pem", nullptr);
    assert(err);

    SSL_CTX_set_verify(server_ctx, SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT, nullptr);
    SSL_CTX_set_verify_depth(server_ctx, 4);

    Server::Location loc;
    loc.host = "127.0.0.1";
    loc.ssl_ctx = server_ctx;

    Server::Config server_cfg;
    server_cfg.locations.push_back(loc);
    server_cfg.tcp_nodelay = true;

    TServerSP server = new TServer(loop);
    server->configure(server_cfg);
    server->run();
    return server;
}


void TServer::enable_echo () {
    request_event.remove_all();
    request_event.add([](auto& req){
        auto h = std::move(req->headers);
        h.remove("Host");
        h.remove("User-Agent");
        h.remove("Accept-Encoding");
        h.remove("Content-Length"); /* causes problems if req is not compressed, and res is */
        auto res = new ServerResponse(200, std::move(h), Body(req->body.to_string()));
        res->compression.type = Compression::GZIP;
        req->respond(res);
    });
}

void TServer::autorespond (const ServerResponseSP& res) {
    if (!autores) {
        autores = true;
        request_event.add([this](auto& req){
            if (!autoresponse_queue.size()) return;
            auto res = autoresponse_queue.front();
            autoresponse_queue.pop_front();
            req->respond(res);
        });
    }
    autoresponse_queue.push_back(res);
}

string TServer::location () const {
    auto sa = sockaddr().value();
    return sa.ip() + ':' + panda::to_string(sa.port());
}

NetLoc TServer::netloc () const {
    return { sockaddr()->ip(), sockaddr()->port(), nullptr, {} };
}

SslContext TServer::get_context (string cert_name) {
    auto ctx = SSL_CTX_new(SSLv23_server_method());
    auto r = SslContext::attach(ctx);
    string path("tests/cert");
    string cert = path + "/" + cert_name + ".pem";
    string key = path + "/" + cert_name + ".key";
    int err;

    err = SSL_CTX_use_certificate_file(ctx, cert.c_str(), SSL_FILETYPE_PEM);
    assert(err);

    err = SSL_CTX_use_PrivateKey_file(ctx, key.c_str(), SSL_FILETYPE_PEM);
    assert(err);

    err = SSL_CTX_check_private_key(ctx);
    assert(err);
    return r;
}

string TServer::uri () const {
    string uri = secure ? string("https://") : string("http://");
    uri += sockaddr()->ip();
    uri += ":";
    uri += to_string(sockaddr()->port());
    uri += "/";
    return uri;
}

void TClient::request (const RequestSP& req) {
    req->tcp_nodelay = true;
    if (sa) {
        req->uri->host(sa.ip());
        req->uri->port(sa.port());
    }
    if (secure) req->uri->scheme("https");
    Client::request(req);
}

ResponseSP TClient::get_response (const RequestSP& req) {
    ResponseSP response;

    req->response_event.add([this, &response](auto, auto& res, auto& err){
        if (err) throw err;
        response = res;
        this->loop()->stop();
    });

    request(req);
    loop()->run();

    return response;
}

ResponseSP TClient::get_response (const string& uri, Headers&& headers, Body&& body, bool chunked) {
    auto b = Request::Builder().uri(uri).headers(std::move(headers)).body(std::move(body));
    if (chunked) b.chunked();
    return get_response(b.build());
}

ErrorCode TClient::get_error (const RequestSP& req) {
    ErrorCode error;

    req->response_event.add([this, &error](auto, auto, auto& err){
        error = err;
        this->loop()->stop();
    });

    request(req);
    loop()->run();

    return error;
}

ErrorCode TClient::get_error (const string& uri, Headers&& headers, Body&& body, bool chunked) {
    auto b = Request::Builder().uri(uri).headers(std::move(headers)).body(std::move(body));
    if (chunked) b.chunked();
    return get_error(b.build());
}

SslContext TClient::get_context(string cert_name, const string& ca_name) {
    auto ctx = SSL_CTX_new(SSLv23_client_method());
    auto r = SslContext::attach(ctx);
    string path("tests/cert");
    string ca = path + "/" + ca_name + ".pem";
    string cert = path + "/" + cert_name + ".pem";
    string key = path + "/" + cert_name + ".key";
    int err;

    err = SSL_CTX_load_verify_locations(ctx, ca.c_str(), nullptr);
    assert(err);

    err = SSL_CTX_use_certificate_file(ctx, cert.c_str(), SSL_FILETYPE_PEM);
    assert(err);

    err = SSL_CTX_use_PrivateKey_file(ctx, key.c_str(), SSL_FILETYPE_PEM);
    assert(err);

    SSL_CTX_check_private_key(ctx);
    assert(err);

    SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, nullptr);
    SSL_CTX_set_verify_depth(ctx, 4);

    return r;
}


TClientSP TPool::request (const RequestSP& req) {
    TClientSP client = dynamic_pointer_cast<TClient>(Pool::request(req));
    return client;
}

static TcpSP make_socks_server (const LoopSP& loop, const net::SockAddr& sa) {
    TcpSP server = new Tcp(loop);
    server->bind(sa);
    server->listen(128);

    server->connection_event.add([](auto server, auto stream, auto& err) {
        if (err) throw err;
        std::shared_ptr<int> state = std::make_shared<int>(0);

        TcpSP client = new Tcp(server->loop());
        client->read_event.add([stream](auto, auto& buf, auto& err) {
            if (err) throw err;
            // read from remote server
            stream->write(buf);
        });
        client->eof_event.add([stream](auto) mutable {
            stream->shutdown();
        });
        client->write_event.add([](auto, auto& err, auto) { if (err) throw err; });

        stream->read_event.add([client, state](auto stream, auto& buf, auto&err) {
            if (err) throw err;
            switch (*state) {
                case 0: {
                    stream->write("\x05\x00");
                    *state = 1;
                    break;
                }
                case 1: {
                    string request_type = buf.substr(0, 4);
                    if (request_type == string("\x05\x01\x00\x03")) {
                        int host_length = buf[4];
                        string host = buf.substr(5, host_length);
                        uint16_t port = ntohs(*(uint16_t*)buf.substr(5 + host_length).data());
                        client->connect("127.0.0.1", port);
                        client->connect_event.add([](auto, auto& err, auto){ if (err) throw err; });
                    } else {
                        throw std::runtime_error("bad request");
                    }

                    stream->write("\x05\x00\x00\x01\xFF\xFF\xFF\xFF\xFF\xFF");
                    *state = 2;
                    break;
                }
                case 2: {
                    // write to remote server
                    client->write(buf);
                    break;
                }
            }
        });
    });

    return server;
}

TProxy new_proxy(const LoopSP& loop, const net::SockAddr& sa) {
    auto server = make_socks_server(loop, sa);
    auto real_sa = server->sockaddr().value();
    URISP url = new URI(string("socks5://") + real_sa.ip()  + ":" + to_string(real_sa.port()));
    return TProxy { server, url };
}


ClientPair::ClientPair (const LoopSP& loop, bool with_proxy) {
    server = make_server(loop, {});
    client = new TClient(loop);
    client->sa = server->sockaddr().value();
    if (with_proxy) {
        proxy = new_proxy(loop);
    }
}

ServerPair::ServerPair (const LoopSP& loop, Server::Config cfg) {
    server = make_server(loop, cfg);

    conn = new Tcp(loop);
    if (secure) {  conn->use_ssl( TClient::get_context("01-alice")); }
    conn->connect_event.add([](auto& conn, auto& err, auto){
        if (err) {
            printf("server pair connect error: %s\n", err.what().c_str());
            throw err;
        }
        conn->loop()->stop();
    });
    conn->connect(server->sockaddr().value());
    loop->run();
}

RawResponseSP ServerPair::get_response () {
    if (!response_queue.size()) {
        conn->read_event.remove_all();
        conn->eof_event.remove_all();

        conn->read_event.add([&, this](auto, auto& str, auto& err) {
            if (err) throw err;
            while (str) {
                if (!parser.context_request()) {
                    if (source_request) parser.set_context_request(source_request);
                    else                parser.set_context_request(new RawRequest(Request::Method::Get, new URI("/")));
                }
                auto result = parser.parse_shift(str);
                if (result.error) {
                    WARN(result.error);
                    throw result.error;
                }
                if (result.state != State::done) return;
                response_queue.push_back(result.response);
            }
            if (response_queue.size()) conn->loop()->stop();
        });
        conn->eof_event.add([&, this](auto){
            eof = get_time();
            auto result = parser.eof();
            if (result.error) throw result.error;
            if (result.response) response_queue.push_back(result.response);
            conn->loop()->stop();
        });
        conn->loop()->run();
        conn->read_event.remove_all();
        conn->eof_event.remove_all();
    }

    if (!response_queue.size()) throw std::runtime_error("no response");
    auto ret = response_queue.front();
    response_queue.pop_front();
    return ret;
}

int64_t ServerPair::wait_eof (int tmt) {
    if (eof) return eof;

    TimerSP timer;
    if (tmt) timer = Timer::create(tmt, [this](auto) {
        conn->loop()->stop();
    }, conn->loop());

    conn->eof_event.add([this](auto){
        eof = get_time();
        conn->loop()->stop();
    });

    conn->loop()->run();
    return eof;
}
