#include "../lib/test.h"

#define TEST(name) TEST_CASE("server-keep-alive: " name, "[server-keep-alive]" VSSL)

TEST("server closes") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200));
    RawResponseSP res;

    SECTION("when 1.0 and no C") {
        res = p.get_response("GET / HTTP/1.0\r\n\r\n");
    }
    SECTION("when 1.0 and C=CLOSE") {
        res = p.get_response("GET / HTTP/1.0\r\nConnection: close\r\n\r\n");
    }
    SECTION("when 1.1 and C=CLOSE") {
        res = p.get_response("GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
    }

    p.wait_eof();
    CHECK(res->code == 200);
}

TEST("server persists") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200));
    RawResponseSP res;

    SECTION("when 1.0 and C=KA") {
        res = p.get_response("GET / HTTP/1.0\r\nConnection: keep-alive\r\n\r\n");
    }
    SECTION("when 1.1 and no C") {
        res = p.get_response("GET / HTTP/1.1\r\n\r\n");
    }
    SECTION("when 1.1 and C=KA") {
        res = p.get_response("GET / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n");
    }

    CHECK(!p.wait_eof(5));
    CHECK(res->code == 200);
}

TEST("if req is <close>, then response also <close> regardless of user's choice in headers") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200, Headers().connection("keep-alive")));
    RawResponseSP res;

    SECTION("1.0 no C") {
        res = p.get_response("GET / HTTP/1.0\r\n\r\n");
    }
    SECTION("1.1 and C=CLOSE") {
        res = p.get_response("GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
    }

    p.wait_eof();
    CHECK(res->code == 200);
    CHECK_FALSE(res->keep_alive());
}

TEST("if user's response says <close> then don't give a fuck what request says") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200, Headers().connection("close")));
    RawResponseSP res;

    SECTION("1.0 and C=KA") {
        res = p.get_response("GET / HTTP/1.0\r\nConnection: keep-alive\r\n\r\n");
    }
    SECTION("1.1 and no C") {
        res = p.get_response("GET / HTTP/1.1\r\n\r\n");
    }
    SECTION("1.1 and C=KA") {
        res = p.get_response("GET / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n");
    }

    p.wait_eof();
    CHECK(res->code == 200);
    CHECK(res->headers.connection() == "close");
}

TEST("idle timeout before any requests") {
    AsyncTest test(1000);
    Server::Config cfg;
    cfg.idle_timeout = 50;
    time_mark();
    ServerPair p(test.loop, cfg);
    CHECK(p.wait_eof(1000));
    CHECK(time_elapsed() >= 49);
}

TEST("idle timeout during and after request") {
    AsyncTest test(5000);
    Server::Config cfg;
    cfg.idle_timeout = 10;
    ServerPair p(test.loop, cfg);
    TimerSP t = new Timer(test.loop);
    bool arrived = false;

    p.server->request_event.add([&](auto& req){
        arrived = true;
        t->event.add([&, req](auto){
            time_mark();
            req->respond(new ServerResponse(200, Headers(), Body("hello world")));
        });
        t->once(11); // longer that idle timeout, it should not break connection during active request
    });

    try {
        auto res = p.get_response("GET / HTTP/1.1\r\n\r\n");
        CHECK(res->body.to_string() == "hello world");
    } catch (const std::runtime_error& err) {
        if (string(err.what()) == "no response" && !arrived) { // under high load request might have not been arrived in time
            SUCCEED("server haven't received request in time");
            return;
        }
        throw;
    }
    CHECK(p.wait_eof(4000));
    /* -1 to compensate that idle timer and test timer do start at different times */
    CHECK(time_elapsed() >= cfg.idle_timeout - 1);
}

TEST("max keepalive requests") {
    AsyncTest test(1000);
    Server::Config cfg;
    cfg.max_keepalive_requests = 3;
    ServerPair p(test.loop, cfg);
    p.server->autorespond(new ServerResponse(200));
    p.server->autorespond(new ServerResponse(200));
    p.server->autorespond(new ServerResponse(200, Headers().connection("keep-alive")));
    auto res = p.get_response("GET / HTTP/1.1\r\n\r\n");
    CHECK(res->code == 200);
    CHECK(res->keep_alive());
    res = p.get_response("GET / HTTP/1.1\r\n\r\n");
    CHECK(res->code == 200);
    CHECK(res->keep_alive());
    res = p.get_response("GET / HTTP/1.1\r\n\r\n");
    CHECK(res->code == 200);
    CHECK_FALSE(res->keep_alive());
    p.wait_eof();
}
