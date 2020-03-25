#include "../lib/test.h"
#include <iostream>
using std::cout;
using std::endl;

TEST_CASE("sync connect error", "[tcp][v-ssl][v-buf]") {
    AsyncTest test(2000, {"error"});
    net::SockAddr::Inet4 sa("255.255.255.255", 0); // makes underlying backend connect end with error synchronously

    TcpSP client = make_client(test.loop);
    client->connect_event.add([&](auto&, auto& err, auto&) {
        REQUIRE(err);

        SECTION("disconnect") {
            client->disconnect();
        }
        SECTION("just go") {}
    });

    client->connect(sa);

    client->write("123");
    client->disconnect();

    auto res = test.await(client->write_event, "error");
    auto err = std::get<1>(res);
    REQUIRE(err == std::errc::operation_canceled);
}

TEST_CASE("write without connection", "[tcp][v-ssl]") {
    AsyncTest test(2000, 1);
    TcpSP client = make_client(test.loop);
    client->write("1");
    client->write_event.add([&](auto, auto& err, auto) {
        REQUIRE(err == std::errc::not_connected);
        test.happens();
    });
    test.run();
}

TEST_CASE("write to closed socket", "[tcp][v-ssl][v-buf]") {
    AsyncTest test(2000, {"error"});
    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr();

    TcpSP client = make_client(test.loop);
    client->connect(sa);
    client->write("1");
    test.await(client->write_event);
    client->disconnect();

    SECTION ("write") {
        client->write("2");
        client->write_event.add([&](auto, auto& err, auto) {
            WARN(err);
            REQUIRE(err == std::errc::not_connected);
            test.happens("error");
            test.loop->stop();
        });
    }
    SECTION ("shutdown") {
        client->shutdown();
        client->shutdown_event.add([&](auto, auto& err, auto) {
            REQUIRE(err == std::errc::not_connected);
            test.happens("error");
            test.loop->stop();
        });
    }
    test.loop->run();
}

TEST_CASE("immediate disconnect", "[tcp][v-ssl][v-buf]") {
    AsyncTest test(5000, {});
    SockAddr sa1, sa2;
    sa1 = sa2 = test.get_refused_addr();
    TcpSP server1, server2;
    SECTION ("no server") {}
    SECTION ("first no server second with server") {
        server2 = make_server(test.loop);
        sa2 = server2->sockaddr();
    }
    SECTION ("with servers") {
        server1 = make_server(test.loop);
        sa1 = server1->sockaddr();
        server2 = make_server(test.loop);
        sa2 = server2->sockaddr();
    }

    TcpSP client = make_client(test.loop);
    string body;
    for (size_t i = 0; i < 100; ++i) body += "0123456789";
    size_t write_count = 0;
    client->connect_event.add([&](auto, auto& err, auto) {
        if (!err) client->disconnect();

        client->connect_event.remove_all();
        client->connect(sa2);

        for (size_t i = 0; i < 1200; ++i) {
            write_count++;
            client->write(body);
        }
        client->shutdown();
        client->disconnect();
    });

    size_t callback_count = 0;
    client->write_event.add([&](auto...){
        callback_count++;
        if (callback_count == write_count) {
            test.loop->stop();
        }
    });

    client->connect(sa1);

    test.run();
    REQUIRE(write_count == callback_count);
}

TEST_CASE("immediate client reset", "[tcp][v-ssl]") {
    AsyncTest test(2000, {"error"});
    SockAddr sa = test.get_refused_addr();
    TcpSP server;
    SECTION ("no server") {}
    SECTION ("with server") {
        server = make_server(test.loop);
        sa = server->sockaddr();
    }
    SECTION ("with nossl server") {
        server = make_basic_server(test.loop);
        sa = server->sockaddr();
    }
    TcpSP client = make_client(test.loop);

    client->connect(sa);

    client->connect_event.add([&](auto, auto& err, auto) {
        CHECK(err == std::errc::operation_canceled);
        test.happens("error");
    });

    client->reset();

}

TEST_CASE("immediate client write reset", "[tcp][v-ssl][v-buf]") {
    AsyncTest test(2000, {"c", "w"});
    TcpSP server = make_server(test.loop);
    TcpSP client = make_client(test.loop);

    client->connect_event.add([&](auto, auto& err, auto) {
        test.happens("c");
        REQUIRE_FALSE(err);
        client->reset();
        test.loop->stop();
    });

    client->connect(server->sockaddr());
    client->write("123");
    client->write_event.add([&](auto, auto& err, auto) {
        test.happens("w");
        CHECK(err == std::errc::operation_canceled);
    });

    test.loop->run();
}

TEST_CASE("reset accepted connection", "[tcp][v-ssl]") {
    AsyncTest test(2000, {"a"});
    TcpSP server = make_server(test.loop);
    TcpSP client = make_client(test.loop);

    server->connection_event.add([&](auto, auto client, auto& err) {
        test.happens("a");
        REQUIRE_FALSE(err);
        client->reset();
        test.loop->stop();
    });

    client->connect(server->sockaddr());

    test.loop->run();
}

TEST_CASE("try use server without certificate", "[tcp]") {
    TcpSP server = new Tcp();
    server->bind("localhost", 0);

    SECTION("use_ssl after listen") {
        server->listen(1);
        REQUIRE_THROWS(server->use_ssl());
    }
    SECTION("use_ssl before listen") {
        server->use_ssl();
        REQUIRE_THROWS(server->listen(1));
    }
}

TEST_CASE("server read", "[tcp][v-ssl]") {
    AsyncTest test(2000, {"c", "r"});
    TcpSP client = make_client(test.loop);
    TcpSP server = make_server(test.loop);

    StreamSP session;
    server->connection_event.add([&](auto, auto s, auto& err) {
        test.happens("c");
        REQUIRE_FALSE(err);
        session = s;
        session->read_event.add([&](auto, string& str, auto& err){
            test.happens("r");
            REQUIRE_FALSE(err);
            REQUIRE(str == "123");
            test.loop->stop();
        });
    });

    client->connect(server->sockaddr());
    client->write("123");

    test.loop->run();
}

//TODO: this test should have been failing before fix, but it did not
//TODO: find a way to reproduce SRV-1273 from UniEvent
TEST_CASE("UniEvent SRV-1273", "[tcp][v-ssl]") {
    AsyncTest test(1000, {});
    SockAddr addr = test.get_refused_addr();
    std::vector<TcpSP> clients;
    size_t counter = 0;

    auto client_timer = unievent::Timer::start(30, [&](TimerSP) {
        if (++counter == 10) {
            test.loop->stop();
        }
        TcpSP client = new Tcp(test.loop);
        client->connect_event.add([](auto s, auto& err, auto){
            REQUIRE(err);
            s->reset();
        });

        client->connect(addr.ip(), addr.port());
        for (size_t i = 0; i < 2; ++i) {
            client->write("123", ([](auto s, auto& err, auto){
                REQUIRE(err);
                s->reset();
            }));
        }
        clients.push_back(client);
    }, test.loop);

    test.loop->run();
    clients.clear();
    REQUIRE(counter == 10);
}

TEST_CASE("MEIACORE-734 ssl server backref", "[tcp]") {
    AsyncTest test(500, {"connect"});
    TcpSP server = make_ssl_server(test.loop);
    TcpSP sconn;

    server->connection_factory = [&](auto) {
        sconn = new Tcp(test.loop);
        return sconn;
    };

    server->connection_event.add([&](auto...) {
        FAIL("should not be called");
    });

    TcpSP client = new Tcp(test.loop);
    client->connect(server->sockaddr());
    test.await(client->connect_event, "connect");

    server = nullptr;
    test.loop->run_nowait();
    client->reset();
    client = nullptr;

    test.run();
}

TEST_CASE("MEIACORE-751 callback recursion", "[tcp]") {
    AsyncTest test(10000, {});
    SockAddr addr = test.get_refused_addr();

    TcpSP client = new Tcp(test.loop);

    size_t counter = 0;
    client->connect_event.add([&](auto...) {
        if (++counter < 5) {
            client->connect()->to(addr.ip(), addr.port())->run();
            client->write("123");
        } else {
            test.loop->stop();
        }
    });

    client->connect()->to(addr.ip(), addr.port())->run();
    client->write("123");

    test.loop->run();
    REQUIRE(counter == 5);
}

TEST_CASE("correct callback order", "[tcp]") {
    AsyncTest test(900, {"connect", "write"});
    TcpSP server = make_basic_server(test.loop);
    SockAddr addr = server->sockaddr();

    TcpSP client = new Tcp(test.loop);
    client->connect()->to(addr.ip(), addr.port())->on_connect([&](auto...) {
        test.happens("connect");
    })->run();
    client->write("123", [&](auto...) {
        test.happens("write");
    });
    client->reset();
}

TEST_CASE("canceling queued requests with filter", "[tcp]") {
    TcpSP h = new Tcp();
    h->use_ssl();
    h->connect("localhost", 12345);
    h->disconnect();
    h->connect("localhost", 12345);
    h->write("lalala");
    h->write("hahaha");
    h->shutdown();
    h->disconnect();
    h->reset();
}

TEST_CASE("bind *", "[tcp]") {
    TcpSP h = new Tcp();
    h->bind("*", 12345);
}

TEST_CASE("write burst", "[tcp]") {
    AsyncTest test(2000, 5);
    auto p = make_p2p(test.loop);

    panda::string rcv;
    p.sconn->read_event.add([&](auto, auto& str, auto){
        rcv += str;
        if (rcv == "abcd") {
            test.happens();
            test.loop->stop();
        }
    });

    p.client->write("a");
    CHECK(p.client->write_queue_size() == 0);
    p.client->write("b");
    CHECK(p.client->write_queue_size() == 0);
    p.client->write("c");
    CHECK(p.client->write_queue_size() == 0);
    p.client->write("d");
    CHECK(p.client->write_queue_size() == 0);
    p.client->write_event.add([&](auto, auto, auto) {
        test.happens();
    });

    test.loop->run();
}

TEST_CASE("write queue size", "[tcp]") {
    AsyncTest test(500, {});
    SECTION("queued") {
        auto p = make_tcp_pair(test.loop);
        CHECK(p.client->write_queue_size() == 0);
        p.client->write("a");
        CHECK(p.client->write_queue_size() == 1);
        p.client->write("b", [&](auto, auto, auto){ test.loop->stop(); });
        CHECK(p.client->write_queue_size() == 2);
        test.run();
        CHECK(p.client->write_queue_size() == 0);
    }
    SECTION("sync") {
        auto p = make_p2p(test.loop);
        CHECK(p.client->write_queue_size() == 0);
        p.client->write("a");
        CHECK(p.client->write_queue_size() == 0);
        p.client->write("b");
        CHECK(p.client->write_queue_size() == 0);
    }
    SECTION("reset") {
        auto p = make_tcp_pair(test.loop);
        p.client->write("12345");
        CHECK(p.client->write_queue_size() == 5);
        p.client->write("67890");
        CHECK(p.client->write_queue_size() == 10);
        p.client->reset();
        CHECK(p.client->write_queue_size() == 0);
    }
}

TEST_CASE("disconnection should be caught as EOF", "[tcp]") {
    AsyncTest test(500, 1);
    auto p = make_p2p(test.loop);
    p.sconn->read_event.add([&](auto, auto, auto& err) {
        FAIL("read event called err=" << err);
        test.loop->stop();
    });
    p.sconn->eof_event.add([&](auto){
        test.happens();
        test.loop->stop();
    });
    panda::string str = "9";
    for (int i = 0; i < 20; ++i) str += str;
    p.sconn->write(str);
    p.sconn->write_event.add([](auto, auto& err, auto){
        WARN("write event err " << err);
    });
    p.client->disconnect();
    test.run();
}

TEST_CASE("disconnect during ssl handshake", "[tcp][v-ssl]") {
    AsyncTest test(2000, {"done"});
    CallbackDispatcher<void()> killed;

    struct TcpTracer : Tcp {
        CallbackDispatcher<void()>& killed;

        TcpTracer(CallbackDispatcher<void()>& killed, LoopSP loop) : Tcp(loop), killed(killed) {}

        ~TcpTracer() {
            killed();

        }
    };

    TcpSP server = make_server(test.loop);
    SockAddr sa = server->sockaddr();

    TcpSP client = new Tcp(test.loop, AF_INET);
    client->connect(sa);

    server->connection_factory = [&](auto&){
        client->reset();
        return new TcpTracer(killed, test.loop);
    };

    test.await(killed, "done");
}

TEST_CASE("no on_read after read_stop", "[.][tcp][v-ssl]") {
    bool old_ssl = variation.ssl;
    variation.ssl = true;
    AsyncTest test(2000, {"conn", "read", "read"});
    TcpSP server = make_server(test.loop);
    TcpSP client = make_client(test.loop);
    TcpSP sconn;

    server->connection_event.add([&](auto&, auto& cl, auto& err) {
        REQUIRE_FALSE(err);
        sconn = dynamic_pointer_cast<Tcp>(cl);
        cl->read_stop();
    });

    client->connect(server->sockaddr());
    test.await(server->connection_event, "conn");

    //idea: read 2 ssl packends in one tcp read
    //tcp uses Nagle's algorithm: the first message would be sent immediately, but ths second would wait for new messages for some shor timeout
    //so the third would be sent in batch with the second and hopefully it would be read the same way
    client->write("01");
    test.wait(1);  // to prevent from UniEvent write batching
    client->write("ab");
    test.wait(1); // to prevent from UniEvent write batching
    client->write("cd");
    client->shutdown();

    sconn->read_start();
    sconn->read_event.add([&](auto&, auto& msg, auto&){
        if (msg.size() >= 2 && msg.substr(0,2) == "ab") sconn->read_stop();
        test.happens("read");
        test.loop->stop();
    });
    test.run();

    test.wait(10); //just in case of dangling messages
    variation.ssl = old_ssl;
}

TEST_CASE("connect with resolv request", "[tcp][v-ssl][v-buf]") {
    AsyncTest test(3000, {"resolve", "connection"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr();

    TcpSP client = make_client(test.loop);
    Resolver::RequestSP res_req = new Resolver::Request(test.loop->resolver());
    res_req->on_resolve([&](auto...){
        test.happens("resolve");
    });
    TcpConnectRequestSP con_req = client->connect();
    SECTION("host in") {
        res_req->node(sa.ip())->port(sa.port());
    }
    SECTION("host overwirite") {
        con_req->to(sa.ip(), sa.port());
    }
    SECTION("host conflict") {
        auto blackhole = test.get_blackhole_addr();
        res_req->node(blackhole.ip())->port(blackhole.port());
        con_req->to(sa.ip(), sa.port());
    }

    con_req->to(res_req)->run();
    test.await(server->connection_event, "connection");
}

TEST_CASE("Stream::write range", "[tcp]") {
    AsyncTest test(2000, {"connect"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr();

    TcpSP client = make_client(test.loop);
    client->connect()->to(sa)->run();

    string arr[] = {"123", "456"};
    string* b = arr;
    void* e = b + 2; // emulating different tipe of end iterator

    struct Range {
        string* b;
        void* e;

        string* begin() const { return b; }
        void* end() const { return e; }
        size_t size() const {
            return (string*)e - b;
        }
    };

    client->write(Range{b, e});

    test.await(server->connection_event, "connect");
}

TEST_CASE("write stack overflow", "[tcp][v-ssl][v-buf]") {
    AsyncTest test(2000, {"connection"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr();

    TcpSP client = make_client(test.loop);
    client->connect(sa);
    for (size_t i = 0; i < 10000; ++i) {
        client->write("q");
    }
    test.await(server->connection_event, "connection");
}

TEST_CASE("run in order", "[tcp]") {
    AsyncTest test(2000);
    TcpSP h = new Tcp(test.loop);
    string s;
    h->run_in_order([&](auto&){ s +=  "1"; });
    CHECK(s == "1");

    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr();

    h->connect(sa);
    h->connect_event.add([&](auto...){
        CHECK(s == "1");
    });

    h->run_in_order([&](auto&){ s +=  "2"; });

    h->write("123");
    h->write_event.add([&](auto...){
        CHECK(s == "12");
    });

    h->run_in_order([&](auto&){ s +=  "3"; });

    h->shutdown();
    h->shutdown_event.add([&](auto...){
        CHECK(s == "123");
        test.loop->stop();
    });

    CHECK(s == "1");
    test.run();
    CHECK(s == "123");
}

TEST_CASE("shutdown timeout", "[tcp]") {
    AsyncTest test(1000, {"shutdown", "postreq"});
    auto p = make_tcp_pair(test.loop);
    StreamSP client;
    p.server->connection_event.add([&](auto, auto cli, auto) {
        client = cli;
    });
    string str;
    str.resize(10000000, 'x');
    for (int i = 0; i < 1000; ++i) p.client->write(str);
    p.client->shutdown(1, [&](auto, auto& err, auto) {
        test.happens("shutdown");
        CHECK(err == std::errc::timed_out);
    });

    p.client->run_in_order([&](auto) {
        test.happens("postreq");
        test.loop->stop();
    });

    test.run();
}

TEST_CASE("reset in write request while timeouted shutdown", "[tcp]") {
    AsyncTest test(1000, {"reset", "shutdown"});
    auto p = make_tcp_pair(test.loop);
    StreamSP client;
    p.server->connection_event.add([&](auto, auto cli, auto) {
        client = cli;
    });
    string str;
    str.resize(10000000, 'x');
    for (int i = 0; i < 1000; ++i) p.client->write(str);
    p.client->write(str, [&](auto& client, auto& err, auto) {
        if (err) {
            test.happens("reset");
            client->reset();
        }
    });
    p.client->shutdown(1, [&](auto, auto& err, auto) {
        test.happens("shutdown");
        CHECK(err == std::errc::timed_out);
        test.loop->stop();
    });

    test.run();
}

TEST_CASE("bind excepted error", "[tcp]") {
    AsyncTest test(1000, {});

    TcpSP server = new Tcp(test.loop);
    SockAddr sa = SockAddr::Inet4("4.4.4.4", 80);
    auto ret = server->bind(sa);
    server->listen(1);

    REQUIRE_FALSE(ret.has_value());
    REQUIRE(ret.error() == errc::bind_error);
}

TEST_CASE("listen excepted error", "[tcp]") {
    if (is_wsl() == Wsl::_1) {
        //on WSL 1 double of one port does not lead to error
        SUCCEED("skipped for WSL 1");
        return;
    }
    AsyncTest test(1000, {});

    TcpSP first_listener = make_server(test.loop);

    TcpSP second_listener = new Tcp(test.loop);;
    second_listener->bind(first_listener->sockaddr());
    auto ret = second_listener->listen(1);

    REQUIRE_FALSE(ret.has_value());
    REQUIRE(ret.error() == errc::listen_error);
}
