#include "../lib/test.h"
#include <thread>

#define TEST(name, var) TEST_CASE("tcp-connect: " name, "[tcp-connect]" var)

TEST("sync connect error", "[v-ssl][v-buf]") {
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
    REQUIRE(err & std::errc::operation_canceled);
}

TEST("connect with resolv request", "[v-ssl][v-buf]") {
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

TEST("connect to nowhere", "[v-ssl]") {
    AsyncTest test(2000, {"connected", "reset"});

    auto sa = test.get_refused_addr();
    size_t counter = 0;

    TcpSP client = make_client(test.loop);
    TimerSP timer = new Timer(test.loop);
    timer->event.add([&](Timer*) {
        test.loop->stop();
    });

    client->connect(sa);
    client->write("123");

    client->connect_event.add([&](auto, auto& err, auto) {
        CHECK(err);
        switch (counter) {
        case 0:
            test.happens("connected");
            counter++;
            client->connect(sa);
            client->write("123");
            break;
        case 1:
            test.happens("reset");
            counter++;
            client->reset();
            client->connect(sa);
            break;
        default:
            timer->once(10); // 100ms for close_reinit
            break;
        }
    });
    test.run();
}

TEST("connect timeout with real connection", "[v-ssl]") {
    AsyncTest test(1000, {"connected1", "connected2"});

    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr();

    SECTION("ordinary resolve") { test.loop->resolver()->cache_limit(0); }
    SECTION("cached resolve")   { }

    TcpSP client = make_client(test.loop);

    client->connect(sa, 1000);

    client->connect_event.add([&](auto, auto& err, auto) {
        CHECK_FALSE(err);
    });

    test.await(client->connect_event, "connected1");

    client->disconnect();

    client->connect(sa, 1000);

    test.await(client->connect_event, "connected2");

    REQUIRE(test.await_not(client->connect_event, 20));
}

TEST("connect timeout with real canceled connection", "[v-ssl]") {
    int connected = 0;
    int errors = 0;
    int successes = 0;
    int tries = getenv("TEST_FULL") ? (variation.ssl ? 200 : 4000) : (variation.ssl ? 50 : 100);

    AsyncTest test(50000, {"connected1", "connected2"});
    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr();
    auto ip = sa.ip();
    auto port = sa.port();
    server->connection_event.add([](auto...) {});

    std::vector<TcpSP> clients(tries);
    std::vector<decltype(clients[0]->connect_event)*> disps;

    for (int i = 0; i < tries; ++i) {
        auto client = clients[i] = make_client(test.loop);
        client->connect()->to(ip, port)->timeout(10)->use_cache(i % 2)->run();

        client->connect_event.add([&](auto, auto& err, auto) {
            ++connected;
            err ? ++errors : ++successes;
        });

        disps.push_back(&client->connect_event);
    }

    test.await(disps, "connected1");

    test.loop->resolver()->cache().clear();

    for (int i = 0; i < tries; ++i) {
        clients[i]->disconnect();
        clients[i]->connect()->to(ip, port)->timeout(10000)->use_cache(i % 2)->run();
    }

    test.await(disps, "connected2");

    test.loop->resolver()->cache().clear();

    CHECK(connected == tries * 2);
    CHECK(successes >= tries);
    // NB some connections could be made nevertheless canceled
}

TEST("connect timeout with black hole", "[v-ssl]") {
    AsyncTest test(5000, {"connected called"});

    SECTION("ordinary resolve") { test.loop->resolver()->cache_limit(0); }
    SECTION("cached resolve")   { }

    TcpSP client = make_client(test.loop);
    client->connect(test.get_blackhole_addr(), 10);

    client->connect_event.add([&](auto, auto& err, auto) {
        REQUIRE(err);
    });
    test.await(client->connect_event, "connected called");
}

TEST("connect timeout clean queue", "[!][v-ssl]") {
    AsyncTest test(2000, {"connected called"});

    SECTION("ordinary resolve") { test.loop->resolver()->cache_limit(0); }
    SECTION("cached resolve")   { }

    TcpSP client = make_client(test.loop);
    client->connect(test.get_blackhole_addr(), 10);

    client->write("123");

    client->connect_event.add([&](auto, auto& err, auto) {
        REQUIRE(err);
    });
    client->write_event.add([&](auto, auto& err, auto) {
        REQUIRE(err);
    });

    test.await(client->connect_event, "connected called");
    REQUIRE(test.await_not(client->write_event, 10));
}

TEST("connect timeout with black hole in roll", "[v-ssl]") {
    AsyncTest test(1000, {});

    TcpSP client = make_client(test.loop);
    auto req = client->connect()->to(test.get_blackhole_addr())->timeout(10);
    req->run();

    size_t counter = 5;
    client->connect_event.add([&](auto, auto& err, auto) {
        REQUIRE(err);
        if (--counter > 0) {
            client->connect(req);
            SECTION("usual") {}
            SECTION("sleep") {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        } else {
            test.loop->stop();
        }
    });
    test.run();
    CHECK(counter == 0);
}

TEST("regression on not cancelled timer in second (sync) connect", "[v-ssl]") {
    AsyncTest test(250, {"not_connected1", "not_connected2"});
    auto sa = test.get_refused_addr();

    SECTION("ordinary resolve") { test.loop->resolver()->cache_limit(0); }
    SECTION("cached resolve")   { }

    TcpSP client = make_client(test.loop);

    client->connect(sa, 100);

    client->connect_event.add([&](auto, auto& err, auto) {
        REQUIRE(err);
    });

    test.await(client->connect_event, "not_connected1");

    test.loop->resolver()->cache().clear();

    client->connect(sa, 100);

    test.await(client->connect_event, "not_connected2");
}

TEST("multi-dns round robin on connect error", "[v-ssl]") {
    AsyncTest test(5000, 0);
    string host = "google.com";
    auto resolver = test.loop->resolver();

    AddrInfo list;
    resolver->resolve()->node(host)->service("81")->hints(Tcp::defhints)->on_resolve([&](auto& ai, auto& err, auto) {
        REQUIRE_FALSE(err);
        list = ai;
    })->run();

    test.run();

    REQUIRE(list);
    REQUIRE(list.next());
    REQUIRE(resolver->find(host, "81", Tcp::defhints) == list);

    TcpSP client = make_client(test.loop);

    client->connect_event.add([&](auto h, auto& err, auto& req) {
        auto treq = static_cast<TcpConnectRequest*>(req.get());
        REQUIRE(err & std::errc::timed_out);
        REQUIRE(treq->addr == list.addr());
        h->reset();
    });
    client->connect(host, 81, 10);

    test.run();

    REQUIRE(resolver->find(host, "81", Tcp::defhints) == list.next());
}
