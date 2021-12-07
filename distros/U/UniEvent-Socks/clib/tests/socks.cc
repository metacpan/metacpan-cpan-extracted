#include <catch2/catch_test_macros.hpp>
#include <openssl/ssl.h>
#include <panda/unievent/socks.h>
#include <panda/unievent/test/AsyncTest.h>
#include <panda/unievent/socks/SocksFilter.h>

using namespace panda;
using namespace panda::unievent;
using namespace panda::unievent::test;
using namespace panda::unievent::socks;

static const SockAddr::Inet4 laddr("127.0.0.1", 0);

struct P2P {
    TcpSP    client;
    TcpSP    proxy;
    TcpSP    server;
    StreamSP sconn;
};

static P2P make_p2p (const LoopSP& loop, const SockAddr& sa_server = laddr, const SockAddr& sa_proxy = laddr);

static TcpSP make_basic_server (const LoopSP& loop, const SockAddr& sa = laddr);
static TcpSP make_socks_server (const LoopSP& loop, const SockAddr& sa = laddr);

static SSL_CTX* get_ssl_ctx ();

TEST_CASE("socks is client only", "[socks]") {
    TcpSP h = new Tcp();
    h->bind(laddr);
    h->listen(1);
    CHECK_THROWS(use_socks(h, "127.0.0.1", 123));

    h = new Tcp();
    use_socks(h, "127.0.0.1", 123);
    h->bind(laddr);
    CHECK_THROWS(h->listen(1));
}

TEST_CASE("bad socks server", "[socks]") {
    AsyncTest test(2000, 3);

    TcpSP proxy_server = new Tcp(test.loop);
    proxy_server->bind(SockAddr::Inet4("127.0.0.1", 0));
    proxy_server->listen(1);
    auto sa = proxy_server->sockaddr().value();

    TcpSP client = new Tcp(test.loop);
    client->use_ssl();
    use_socks(client, sa.ip(), sa.port());

    proxy_server->connection_event.add([&](auto, auto s, auto err) {
        REQUIRE_FALSE(err);
        s->write("bad socks");
        test.happens();
    });

    client->connect(test.get_refused_addr());
    client->connect_event.add([&](auto, auto& err, auto) {
        CHECK(err);
        test.happens();
    });
    client->write("123", [&](auto, auto& err, auto) {
        CHECK(err & std::errc::operation_canceled);
        test.happens();
        test.loop->stop();
    });

    test.loop->run();
}

TEST_CASE("socks chain", "[socks]") {
    AsyncTest test(3000, {"ping", "pong"});
    size_t proxies_count = 3;
    std::vector<TcpSP> proxies;
    for (size_t i = 0; i < proxies_count; ++i) proxies.push_back(make_socks_server(test.loop));

    auto server = make_basic_server(test.loop);
    auto sa = server->sockaddr().value();
    server->use_ssl(get_ssl_ctx());
    server->connection_event.add([&](auto, auto connection, auto& err) {
        REQUIRE_FALSE(err);
        test.happens("ping");
        connection->write("pong");
        connection->shutdown();
    });

    TcpSP client = new Tcp(test.loop);
    client->use_ssl();
    for (auto proxy : proxies) {
        auto sa = proxy->sockaddr().value();
        client->push_behind_filter(new SocksFilter(client, new socks::Socks(sa.ip(), sa.port())));
    }
    client->connect(sa.ip(), sa.port());
    client->write("ping");
    client->read_event.add([&](auto, auto& buf, auto& err) {
        REQUIRE_FALSE(err);
        REQUIRE(buf == string("pong"));
        test.happens("pong");
    });

    client->eof_event.add([&](auto){
        test.loop->stop();
    });
    test.loop->run();
}

TEST_CASE("reset in read", "[socks][v-ssl]") {
    AsyncTest test(1000, 0);

    auto p = make_p2p(test.loop);

    SECTION("in client") {
        p.sconn->write("server data");
        p.client->read_event.add([&](auto& h, auto& str, auto& err) {
            REQUIRE_FALSE(err);
            CHECK(str == "server data");
            h->reset();
            test.loop->stop();
        });
    }

    SECTION("in server") {
        p.client->write("client data");
        p.sconn->read_event.add([&](auto& h, auto& str, auto& err) {
            REQUIRE_FALSE(err);
            CHECK(str == "client data");
            h->reset();
            test.loop->stop();
        });
    }

    test.run();
}

static P2P make_p2p (const LoopSP& loop, const SockAddr& server_bind, const SockAddr& proxy_bind) {
    P2P ret;
    bool with_ssl = getenv("TESTV_SSL");
    int left = 2;

    ret.server = make_basic_server(loop, server_bind);
    if (with_ssl) ret.server->use_ssl(get_ssl_ctx());
    auto server_sa = ret.server->sockaddr().value();

    ret.proxy = make_socks_server(loop, proxy_bind);
    auto proxy_sa = ret.proxy->sockaddr().value();

    ret.client = new Tcp(loop);
    if (with_ssl) ret.client->use_ssl();
    use_socks(ret.client, new Socks(proxy_sa.ip(), proxy_sa.port()));
    ret.client->connect(server_sa.ip(), server_sa.port(), 1000);
    ret.client->connect_event.add([&](auto, auto& err, auto) {
        if (err) throw err;
        if (!--left) loop->stop();
    });

    ret.server->connection_event.add([&](auto, auto& sconn, auto& err) {
        if (err) throw err;
        ret.sconn = sconn;
        if (!--left) loop->stop();
    });

    loop->run();

    return ret;
}

static TcpSP make_basic_server (const LoopSP& loop, const SockAddr& sa) {
    TcpSP server = new Tcp(loop);
    server->bind(sa);
    server->listen(128);
    return server;
}

static TcpSP make_socks_server (const LoopSP& loop, const SockAddr& sa) {
    auto server = make_basic_server(loop, sa);
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
            panda_rlog_debug("buf = " << buf);
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

static SSL_CTX* get_ssl_ctx () {
    static SSL_CTX* ctx = nullptr;
    if (ctx) return ctx;
    ctx = SSL_CTX_new(SSLv23_server_method());
    SSL_CTX_use_certificate_file(ctx, "tests/cert/cert.pem", SSL_FILETYPE_PEM);
    SSL_CTX_use_PrivateKey_file(ctx, "tests/cert/key.pem", SSL_FILETYPE_PEM);
    SSL_CTX_check_private_key(ctx);
    return ctx;
}
