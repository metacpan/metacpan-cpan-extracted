#include "../lib/test.h"
#include <iostream>
using std::cout;
using std::endl;

TEST_PREFIX("tcp-base: ", "[tcp-base]");

TEST("immediate client reset") {
    variation = GENERATE(values(ssl_vars));

    AsyncTest test(2000, {"error"});
    SockAddr sa = test.get_refused_addr();
    TcpSP server;
    SECTION ("no server") {}
    SECTION ("with server") {
        server = make_server(test.loop);
        sa = server->sockaddr().value();
    }
    SECTION ("with nossl server") {
        server = make_basic_server(test.loop);
        sa = server->sockaddr().value();
    }
    TcpSP client = make_client(test.loop);

    client->connect(sa);

    client->connect_event.add([&](auto, auto& err, auto) {
        CHECK(err & std::errc::operation_canceled);
        test.happens("error");
    });

    client->reset();
}

TEST("reset accepted connection") {
    variation = GENERATE(values(ssl_vars));

    AsyncTest test(2000, {"a"});
    TcpSP server = make_server(test.loop);
    TcpSP client = make_client(test.loop);

    server->connection_event.add([&](auto, auto client, auto& err) {
        test.happens("a");
        REQUIRE_FALSE(err);
        client->reset();
        test.loop->stop();
    });

    client->connect(server->sockaddr().value());

    test.loop->run();
}

TEST("server read") {
    variation = GENERATE(values(ssl_vars));

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

    client->connect(server->sockaddr().value());
    client->write("123");

    test.loop->run();
}

TEST("correct callback order") {
    AsyncTest test(900, {"connect", "write"});
    TcpSP server = make_basic_server(test.loop);
    SockAddr addr = server->sockaddr().value();

    TcpSP client = new Tcp(test.loop);
    client->connect()->to(addr.ip(), addr.port())->on_connect([&](auto...) {
        test.happens("connect");
    })->run();
    client->write("123", [&](auto...) {
        test.happens("write");
    });
    client->reset();
}

TEST("canceling queued requests with filter") {
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

TEST("bind *") {
    TcpSP h = new Tcp();
    h->bind("*", 12345);
}

TEST("disconnection should be caught as EOF") {
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
    p.client->disconnect();
    test.run();
}

TEST_HIDDEN("no on_read after read_stop") {
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

    client->connect(server->sockaddr().value());
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

TEST("run in order") {
    AsyncTest test(2000);
    TcpSP h = new Tcp(test.loop);
    string s;
    h->run_in_order([&](auto&){ s +=  "1"; });
    CHECK(s == "1");

    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr().value();

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

TEST("shutdown timeout") {
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
        CHECK(err & std::errc::timed_out);
    });

    p.client->run_in_order([&](auto) {
        test.happens("postreq");
        test.loop->stop();
    });

    test.run();
}

TEST("reset in write request while timeouted shutdown") {
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
        CHECK(err & std::errc::timed_out);
        test.loop->stop();
    });

    test.run();
}

TEST("bind excepted error") {
    AsyncTest test(1000, {});

    TcpSP server = new Tcp(test.loop);
    SockAddr sa = SockAddr::Inet4("4.4.4.4", 80);
    auto ret = server->bind(sa);
    server->listen(1);

    REQUIRE_FALSE(ret.has_value());
    REQUIRE(ret.error() & errc::bind_error);
}

TEST("listen excepted error") {
    if (is_wsl() == Wsl::_1) {
        //on WSL 1 double of one port does not lead to error
        SUCCEED("skipped for WSL 1");
        return;
    }
    AsyncTest test(1000, {});

    TcpSP first_listener = make_server(test.loop);

    TcpSP second_listener = new Tcp(test.loop);;
    second_listener->bind(first_listener->sockaddr().value());
    auto ret = second_listener->listen(1);

    REQUIRE_FALSE(ret.has_value());
    REQUIRE(ret.error() & errc::listen_error);
}

TEST("on_connection noclient") {
    AsyncTest test(2000, {"conn"});
    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr().value();

    TcpSP client = make_client(test.loop);
    client->connect(sa);

    TcpSP server2 = make_server(test.loop);
    auto sa2 = server2->sockaddr().value();

    TcpSP client2 = make_client(test.loop);
    client2->connect(sa2);

    bool done = false;
    auto on_connection = [&](const TcpSP& self, const TcpSP& oth, const StreamSP& client, const ErrorCode& err) {
        if (done) {
            self->reset();
            REQUIRE(err);
            REQUIRE(client == nullptr);
            return;
        }
        auto sock = oth->socket().value();
        accept(sock, nullptr, nullptr);
        unievent::close(sock);
        done = true;
        test.loop->stop();
        test.happens("conn");
    };

    server->connection_event.add([&](const StreamSP&, const StreamSP& client, const ErrorCode& err) {
        on_connection(server, server2, client, err);
    });
    server2->connection_event.add([&](const StreamSP&, const StreamSP& client, const ErrorCode& err) {
        on_connection(server2, server, client, err);
    });
    test.run();
}

TEST("pair") {
    AsyncTest test(1000, 2);
    std::pair<TcpSP,TcpSP> p;

    SECTION("basic handles") {
        p = Tcp::pair(test.loop).value();
    }
    SECTION("custom handles") {
        struct MyTcp : Tcp { using Tcp::Tcp; };
        p = Tcp::pair(new MyTcp(test.loop), new MyTcp(test.loop)).value();
        CHECK(panda::dyn_cast<MyTcp*>(p.first.get()));
        CHECK(panda::dyn_cast<MyTcp*>(p.second.get()));
    }

    p.first->write("hello");
    p.second->read_event.add([&](auto...){
        test.happens();
        p.second->write("world");
    });

    p.first->read_event.add([&](auto...){
        test.happens();
        p.first->reset();
        p.second->reset();
    });

    test.run();
    SUCCEED("ok");
}
