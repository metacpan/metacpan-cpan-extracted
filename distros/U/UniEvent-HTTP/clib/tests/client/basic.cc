#include "../lib/test.h"

#define TEST(name) TEST_CASE("client-basic: " name, "[client-basic]" VSSL)

TEST("trivial get") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);
    p.server->enable_echo();

    p.server->request_event.prepend([&](auto& req){
        test.happens();
        auto sa = p.server->sockaddr().value();
        CHECK(req->headers.get("Host") == sa.ip() + ':' + panda::to_string(sa.port()));
    });

    auto res = p.client->get_response("/", Headers().add("Hello", "world"));

    CHECK(res->code == 200);
    CHECK(res->http_version == 11);
    CHECK(res->headers.get("Hello") == "world");
}

TEST("trivial post") {
    AsyncTest test(1000);
    ClientPair p(test.loop);
    p.server->enable_echo();

    auto res = p.client->get_response(Request::Builder().method(Request::Method::Post).uri("/").body("hello").build());

    CHECK(res->code == 200);
    CHECK(res->http_version == 11);
    CHECK(res->body.to_string() == "hello");
}

TEST("request and response larger than mtu") {
    AsyncTest test(1000);
    ClientPair p(test.loop);
    p.server->enable_echo();

    size_t sz = 1024*1024;
    string body(sz);
    for (size_t i = 0; i < sz; ++i) body[i] = 'a';

    auto res = p.client->get_response(Request::Builder().method(Request::Method::Post).uri("/").body(body).build());

    CHECK(res->code == 200);
    CHECK(res->body.to_string() == body);
}

TEST("timeout") {
    AsyncTest test(1000);
    ClientPair p(test.loop);

    auto err = p.client->get_error(Request::Builder().uri("/").timeout(5).build());
    CHECK(err.contains(make_error_code(std::errc::timed_out)));
}

TEST("client retains until request is complete") {
    AsyncTest test(1000);
    ClientPair p(test.loop);
    p.server->enable_echo();

    TClient::dcnt = 0;

    auto req = Request::Builder().uri("/").body("hi").build();
    req->response_event.add([&](auto, auto res, auto err) {
        CHECK_FALSE(err);
        REQUIRE(res);
        CHECK(res->body.to_string() == "hi");
        test.loop->stop();
    });

    auto client = p.client;
    p.client.reset();

    client->request(req);

    client.reset();
    CHECK(TClient::dcnt == 0);
    test.run();
    CHECK(TClient::dcnt == 1);
}

TEST("client doesn't retain when no active requests") {
    TClient::dcnt = 0;
    TClientSP client = new TClient();
    client.reset();
    CHECK(TClient::dcnt == 1);
}

TEST("close instead of response") {
    AsyncTest test(1000);
    TcpSP srv = new Tcp(test.loop);
    srv->bind("127.0.0.1", 0);
    srv->listen();
    srv->connection_event.add([&](auto, auto cli, auto) {
        cli->shutdown();
    });

    TClientSP client = new TClient(test.loop);
    client->sa = srv->sockaddr().value();
    auto err = client->get_error("/");
    CHECK(err); // various depending on if ssl in use or not
}

TEST("non-null response even for earliest errors") {
    AsyncTest test(1000, 1);
    TClientSP client = new TClient(test.loop);

    auto req = Request::Builder().uri("https://ya.ru").build();
    client->request(req);

    req->response_event.add([&](auto, auto& res, auto& err) {
        test.happens();
        CHECK(err);
        CHECK(res);
    });

    req->cancel();
}

TEST("compression") {
    AsyncTest test(1000);
    ClientPair p(test.loop);
    p.server->enable_echo();

    auto req = Request::Builder()
        .method(Request::Method::Post)
        .uri("/")
        .body("hello world")
        .compress(Compression::GZIP)
        .build();
    CHECK(req->compression.type == Compression::GZIP);
    
    auto res = p.client->get_response(req);
    CHECK(res->compression.type == Compression::GZIP);

    CHECK(res->code == 200);
    CHECK(res->http_version == 11);
    CHECK(res->body.to_string() == "hello world");
}

TEST("accept-encoding") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);
    p.server->enable_echo();

    SECTION("gzip by default") {
        auto req = Request::Builder()
            .method(Request::Method::Post)
            .uri("/")
            .build();

        p.server->request_event.prepend([&](auto& req){
            test.happens();
            CHECK(req->headers.get("Accept-Encoding") == "gzip");
        });
        p.client->get_response("/");
    }

    SECTION("gzip can be turned off") {
        auto req = Request::Builder()
            .method(Request::Method::Post)
            .uri("/")
            .allow_compression(Compression::IDENTITY)
            .build();

        CHECK(req->compression_prefs != static_cast<std::uint8_t>(Compression::IDENTITY));

        p.server->request_event.prepend([&](auto& req){
            test.happens();
            CHECK(!req->headers.has("Accept-Encoding"));
        });
        p.client->get_response(req);
    }
}

TEST("request via proxy") {
    AsyncTest test(1000, {"proxy-1", "proxy-2"});
    ClientPair p(test.loop, true);
    p.server->enable_echo();


    p.proxy.server->connection_event.add([&](auto...){ test.happens("proxy-1"); });
    auto req1 = Request::Builder().method(Request::Method::Get).uri("/").proxy(p.proxy.url).build();
    auto res1 = p.client->get_response(req1);

    CHECK(res1->code == 200);
    CHECK(res1->http_version == 11);

    auto proxy2 = new_proxy(test.loop);
    proxy2.server->connection_event.add([&](auto...){ test.happens("proxy-2"); });
    auto req2 = Request::Builder().method(Request::Method::Get).uri("/").proxy(proxy2.url).build();
    auto res2 = p.client->get_response(req2);

    CHECK(res2->code == 200);
    CHECK(res2->http_version == 11);
}
