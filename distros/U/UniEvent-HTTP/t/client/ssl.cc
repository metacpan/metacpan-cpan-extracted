#include "../lib/test.h"
#include <openssl/err.h>
#include <openssl/dh.h>
#include <openssl/ssl.h>
#include <openssl/conf.h>
#include <openssl/engine.h>

#define TEST(name) TEST_CASE("ssl: " name, "[ssl]")

static TServerSP create_server(const LoopSP& loop) {
    auto server = make_ssl_server(loop);
    server->enable_echo();
    return server;
}

TEST("ssl client cert, server validates client, client validates server") {
    secure = true;
    AsyncTest test(1000, 2);

    auto server = create_server(test.loop);
    int connect_events = 0;

    TClientSP client = new TClient(test.loop);
    client->connect_event.add([&](auto...){ ++connect_events; });

    client->sa = server->sockaddr().value();

    server->request_event.add([&](auto&){
        test.happens();
    });

    auto client_cert = TClient::get_context("01-alice");
    auto req = Request::Builder().method(Request::Method::Get).uri("/")
            .ssl_ctx(client_cert)
            .build();
    auto res = client->get_response(req);

    CHECK(res->code == 200);
    CHECK(res->http_version == 11);

    req = Request::Builder().method(Request::Method::Get).uri("/")
         .ssl_ctx(client_cert)
         .build();
    res = client->get_response(req);
    CHECK(res->code == 200);
    CHECK(res->http_version == 11);
    CHECK(connect_events == 1);
    secure = false;
}

TEST("client uses 2 different valid certificates => 2 different connections are used") {
    secure = true;
    AsyncTest test(1000, 2);

    auto server = create_server(test.loop);
    int connect_events = 0;

    TClientSP client = new TClient(test.loop);
    client->connect_event.add([&](auto...){ ++connect_events; });
    client->sa = server->sockaddr().value();

    server->request_event.add([&](auto&){
        test.happens();
    });

    auto client_cert_a = TClient::get_context("01-alice");
    auto client_cert_b = TClient::get_context("02-bob");
    auto req = Request::Builder().method(Request::Method::Get).uri("/")
            .ssl_ctx(client_cert_a)
            .build();
    auto res = client->get_response(req);

    CHECK(res->code == 200);
    CHECK(res->http_version == 11);

    req = Request::Builder().method(Request::Method::Get).uri("/")
         .ssl_ctx(client_cert_b)
         .build();
    res = client->get_response(req);
    CHECK(res->code == 200);
    CHECK(res->http_version == 11);
    CHECK(connect_events == 2);
    secure = false;
}
