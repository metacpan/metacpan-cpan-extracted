#include "../lib/test.h"
#include <thread>

TEST_CASE("connect to nowhere", "[tcp-connect-timeout][v-ssl]") {
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

TEST_CASE("connect timeout with real connection", "[tcp-connect-timeout][v-ssl]") {
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

TEST_CASE("connect timeout with real canceled connection", "[tcp-connect-timeout][v-ssl]") {
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

    test.loop->resolver()->clear_cache();

    for (int i = 0; i < tries; ++i) {
        clients[i]->disconnect();
        clients[i]->connect()->to(ip, port)->timeout(10000)->use_cache(i % 2)->run();
    }

    test.await(disps, "connected2");

    test.loop->resolver()->clear_cache();

    CHECK(connected == tries * 2);
    CHECK(successes >= tries);
    // NB some connections could be made nevertheless canceled
}

TEST_CASE("connect timeout with black hole", "[tcp-connect-timeout][v-ssl]") {
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

TEST_CASE("connect timeout clean queue", "[!][tcp-connect-timeout][v-ssl]") {
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

TEST_CASE("connect timeout with black hole in roll", "[tcp-connect-timeout][v-ssl]") {
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

TEST_CASE("regression on not cancelled timer in second (sync) connect", "[tcp-connect-timeout][v-ssl]") {
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

    test.loop->resolver()->clear_cache();

    client->connect(sa, 100);

    test.await(client->connect_event, "not_connected2");
}
