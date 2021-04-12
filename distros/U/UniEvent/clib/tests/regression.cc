#include "lib/test.h"

TEST_PREFIX("regression: ", "[regression]");

//TODO: this test should have been failing before fix, but it did not
//TODO: find a way to reproduce SRV-1273 from UniEvent
TEST("UniEvent SRV-1273") {
    variation = GENERATE(values(ssl_vars));

    AsyncTest test(1000, {});
    SockAddr addr = test.get_refused_addr();
    std::vector<TcpSP> clients;
    size_t counter = 0;

    auto client_timer = Timer::create(30, [&](TimerSP) {
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

TEST("MEIACORE-734 ssl server backref") {
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
    client->connect(server->sockaddr().value());
    test.await(client->connect_event, "connect");

    server = nullptr;
    test.loop->run_nowait();
    client->reset();
    client = nullptr;

    test.run();
}

TEST("MEIACORE-751 callback recursion") {
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
