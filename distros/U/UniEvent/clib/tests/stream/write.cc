#include "../lib/test.h"
#include <iostream>
#include <catch2/generators/catch_generators.hpp>

using std::cout;
using std::endl;

TEST_PREFIX("stream-write: ", "[stream-write]");

TEST("write without connection") {
    variation = GENERATE(values(ssl_vars));

    AsyncTest test(2000, 1);
    TcpSP client = make_client(test.loop);
    client->write("1");
    client->write_event.add([&](auto, auto& err, auto) {
        REQUIRE(err & std::errc::not_connected);
        test.happens();
    });
    test.run();
}

TEST("write to closed socket") {
    variation = GENERATE(values(ssl_buf_vars));

    AsyncTest test(2000, {"error"});
    TcpSP server = make_server(test.loop);
    auto sa = server->sockaddr().value();

    TcpSP client = make_client(test.loop);
    client->connect(sa);
    client->write("1");
    test.await(client->write_event);
    client->disconnect();

    SECTION ("write") {
        client->write("2");
        client->write_event.add([&](auto, auto& err, auto) {
            REQUIRE(err & std::errc::not_connected);
            test.happens("error");
            test.loop->stop();
        });
    }
    SECTION ("shutdown") {
        client->shutdown();
        client->shutdown_event.add([&](auto, auto& err, auto) {
            REQUIRE(err & std::errc::not_connected);
            test.happens("error");
            test.loop->stop();
        });
    }
    test.loop->run();
}

TEST("immediate disconnect") {
    variation = GENERATE(values(ssl_buf_vars));

    AsyncTest test(5000, {});
    SockAddr sa1, sa2;
    sa1 = sa2 = test.get_refused_addr();
    TcpSP server1, server2;
    SECTION ("no server") {}
    SECTION ("first no server second with server") {
        server2 = make_server(test.loop);
        sa2 = server2->sockaddr().value();
    }
    SECTION ("with servers") {
        server1 = make_server(test.loop);
        sa1 = server1->sockaddr().value();
        server2 = make_server(test.loop);
        sa2 = server2->sockaddr().value();
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

TEST("immediate client write reset") {
    variation = GENERATE(values(ssl_buf_vars));

    AsyncTest test(2000, {"c", "w"});
    TcpSP server = make_server(test.loop);
    TcpSP client = make_client(test.loop);

    client->connect_event.add([&](auto, auto& err, auto) {
        test.happens("c");
        REQUIRE_FALSE(err);
        client->reset();
        test.loop->stop();
    });

    client->connect(server->sockaddr().value());
    client->write("123");
    client->write_event.add([&](auto, auto& err, auto) {
        test.happens("w");
        CHECK(err & std::errc::operation_canceled);
    });

    test.loop->run();
}

TEST("write burst") {
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

TEST("write queue size") {
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

TEST("Stream::write range") {
    AsyncTest test(2000, {"connect"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr().value();

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

TEST("write stack overflow") {
    variation = GENERATE(values(ssl_buf_vars));

    AsyncTest test(2000, {"connection"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr().value();

    TcpSP client = make_client(test.loop);
    client->connect(sa);
    for (size_t i = 0; i < 10000; ++i) {
        client->write("q");
    }
    test.await(server->connection_event, "connection");
}

TEST("request holds") {
    variation = GENERATE(values(ssl_buf_vars));

    AsyncTest test(2000, {"write"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr().value();

    {
        TcpSP client = make_client(test.loop);
        client->connect(sa);
        client->write("q", [&](auto, auto& err, auto) {
            CHECK_FALSE(err);
            test.happens("write");
        });
        client->disconnect();
    }
    StreamSP sconn;
    server->connection_event.add([&](const StreamSP&, const StreamSP& conn, const ErrorCode& err) {
        CHECK_FALSE(err);
        sconn = conn;
        sconn->eof_event.add([&](auto...){
            test.loop->stop();
        });
    });
    test.loop->run();
}

TEST("bad example") {
    variation = GENERATE(values(ssl_buf_vars));

    AsyncTest test(2000, {"write"});
    TcpSP server = make_server(test.loop);
    net::SockAddr sa = server->sockaddr().value();

    {
        TcpSP client = make_client(test.loop);
        client->connect(sa);
        client->connect_event.add([&, client](auto, auto, auto) {
            client->write("q", [&](auto, auto, auto) {
                test.happens("write");
                client->disconnect();
            });
        });
    }
    StreamSP sconn;
    server->connection_event.add([&](const StreamSP&, const StreamSP& conn, const ErrorCode& err) {
        CHECK_FALSE(err);
        sconn = conn;
        sconn->eof_event.add([&](auto...){
            test.loop->stop();
        });
    });
    test.loop->run();
}
