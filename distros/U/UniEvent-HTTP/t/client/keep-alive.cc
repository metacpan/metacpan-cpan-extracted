#include "../lib/test.h"

#define TEST(name) TEST_CASE("client-keep-alive: " name, "[client-keep-alive]" VSSL)

TEST("closes") {
    AsyncTest test(1000, 2);
    ClientPair p(test.loop);

    auto req = Request::Builder().uri("/").build();

    SECTION("request close") {
        req->headers.connection("close");
        p.server->autorespond(new ServerResponse(200));
    }
    SECTION("response close") {
        p.server->autorespond(new ServerResponse(200, Headers().connection("close")));
    }

    p.client->connect_event.add([&](auto...){ test.happens(); }); // main test is here - check for two connections

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
    CHECK_FALSE(res->keep_alive());

    p.server->autorespond(new ServerResponse(200));
    p.client->get_response("/"); // should connect again
}

TEST("persists") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.client->connect_event.add([&](auto...){ test.happens(); });

    for (int i = 0; i < 5; ++i) {
        p.server->autorespond(new ServerResponse(200));
        auto res = p.client->get_response("/");
        CHECK(res->code == 200);
        CHECK(res->keep_alive());
    }
}

TEST("n+n") {
    int srv_cnt = 3;
    int req_cnt = 3;
    AsyncTest test(1000, srv_cnt);

    TClientSP client = new TClient(test.loop);

    client->connect_event.add([&](auto...){ test.happens(); });

    for (int j = 0; j < srv_cnt; ++j) {
        auto srv = make_server(test.loop);
        client->sa = srv->sockaddr().value();

        for (int i = 0; i < req_cnt; ++i) {
            srv->autorespond(new ServerResponse(200));
            auto req = Request::Builder().uri("/").build();
            auto res = client->get_response(req);
            CHECK(res->code == 200);
            CHECK(res->keep_alive());
        }
    }
}
