#include "../lib/test.h"

#define TEST(name) TEST_CASE("server-upgrade: " name, "[server-upgrade]" VSSL)

TEST("normal upgrade") {
    AsyncTest test(1000, 2);
    ServerPair p(test.loop);

    ServerRequestSP req;

    p.server->request_event.add([&](auto _req) {
        req = _req;
        test.loop->stop();
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Connection: upgrade\r\n"
        "Upgrade: my videocard\r\n"
        "\r\n"
    );

    test.run();
    REQUIRE(req);
    CHECK(req->headers.get("Upgrade") == "my videocard");

    auto res = req->upgrade();
    REQUIRE(res);
    auto s = res.value();

    p.conn->read_event.add([&](auto, auto& str, auto...) {
        test.happens();
        CHECK(str == "hello");
        test.loop->stop();
    });

    s->write("hello");
    test.run();

    s->read_event.add([&](auto, auto& str, auto...) {
        test.happens();
        CHECK(str == "world");
        test.loop->stop();
    });

    p.conn->write("world");
    test.run();
}

TEST("upgrade in pipeline") {
    AsyncTest test(1000, {"get", "error"});
    ServerPair p(test.loop);

    ServerRequestSP req;

    p.server->request_event.add([&](auto _req) {
        req = _req;
        test.happens("get");
    });

    p.server->error_event.add([&](auto&, auto& error) {
        test.happens("error");
        CHECK(error & errc::upgrade_in_pipeline);
        test.loop->stop();
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "\r\n"
    );

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Connection: upgrade\r\n"
        "Upgrade: websocket\r\n"
        "\r\n"
    );

    test.run();
    REQUIRE(req);

    req->respond(new ServerResponse(200));

    auto res = p.get_response();
    CHECK(res->code == 200);
    CHECK(!res->body.length());

    res = p.get_response();
    CHECK(res->code == 400);
}

TEST("upgrade wrong request") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    ServerRequestSP req;
    p.server->request_event.add([&](auto _req) {
        req = _req;
        test.loop->stop();
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "Upgrade: websocket\r\n"
        "\r\n"
    );

    test.run();
    REQUIRE(req);

    auto res = req->upgrade();
    REQUIRE(!res);
    CHECK(res.error() & errc::upgrade_wrong_request);
}

TEST("upgrade after disconnect") {
    AsyncTest test(1000, {"req", "drop"});
    ServerPair p(test.loop);

    ServerRequestSP req;

    p.server->request_event.add([&](auto _req) {
        test.happens("req");
        req = _req;
        test.loop->stop();
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Connection: upgrade\r\n"
        "Upgrade: websocket\r\n"
        "\r\n"
    );

    test.run();

    REQUIRE(req);
    CHECK(req->headers.connection() == "upgrade");

    req->drop_event.add([&](auto...) {
        test.happens("drop");
        test.loop->stop();
    });

    p.conn->reset();
    test.run();

    auto res = req->upgrade();
    REQUIRE_FALSE(res);
    REQUIRE(res.error() & std::errc::connection_aborted);
}
