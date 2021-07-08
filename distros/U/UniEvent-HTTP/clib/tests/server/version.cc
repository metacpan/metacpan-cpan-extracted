#include "../lib/test.h"

#define TEST(name) TEST_CASE("server-version: " name, "[server-version]" VSSL)

TEST("preserves version 1.0") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200));
    auto res = p.get_response("GET / HTTP/1.0\r\n\r\n");
    CHECK(res->http_version == 10);
}

TEST("preserves version 1.1") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200));
    auto res = p.get_response("GET / HTTP/1.1\r\n\r\n");
    CHECK(res->http_version == 11);
}

TEST("forces version 1.1 when chunks") {
    AsyncTest test(1000);
    ServerPair p(test.loop);
    p.server->autorespond(new ServerResponse(200, Headers(), Body({"stsuka ", "nah"}), true));
    auto res = p.get_response("GET / HTTP/1.0\r\n\r\n");
    CHECK(res->http_version == 11);
    CHECK(res->chunked);
    CHECK(res->body.to_string() == "stsuka nah");
    CHECK(res->body.parts.size() == 2);
}
