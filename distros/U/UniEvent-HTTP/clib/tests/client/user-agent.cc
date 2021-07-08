#include "../lib/test.h"

#define TEST(name) TEST_CASE("user-agent: " name, "[user-agent]" VSSL)

TEST("simple + identity") {
    AsyncTest test(1000, {"connect"});
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto req){
        ServerResponseSP res = new ServerResponse(200, Headers(), Body(req->body));
        if (req->cookies.get("coo")) {
            res->headers.add("h", "ok");
            res->cookies.add("coo-2", Response::Cookie("val-val"));
        }
        if (req->cookies.get("coo-2")) {
            res->cookies.add("coo-3", Response::Cookie("val-val-val"));
        }
        if (req->headers.has("User-Agent")) res->headers.add("ua", req->headers.get("User-Agent"));
        req->respond(res);
    });

    URISP uri(new URI(p.server->uri()));

    auto cfg = UserAgent::Config();
    cfg.identity = "test-ua/1.0";

    UserAgentSP ua(new UserAgent(test.loop, "", cfg));
    Response::Cookie coo("coo-val");
    ua->cookie_jar()->add("coo", coo, uri);

    auto req = Request::Builder().uri(uri).build();
    ua->request(req)->connect_event.add([&](auto...){ test.happens("connect"); });
    auto res = await_response(req, test.loop);

    CHECK(res->code == 200);
    CHECK(res->headers.get("h") == "ok");
    CHECK(res->headers.get("ua") == cfg.identity);
    CHECK(res->cookies.get("coo-2").value().value() == "val-val");
    CHECK(res->cookies.find("coo-3") == res->cookies.end());

    // another one
    req = Request::Builder().uri(uri).build();
    ua->identity(UserAgent::Identity());
    ua->request(req);
    res = await_response(req, test.loop);
    CHECK(res->code == 200);
    CHECK(res->headers.get("h") == "ok");
    CHECK(!res->headers.has("ua"));
    CHECK(res->cookies.get("coo-2").value().value() == "val-val");
    CHECK(res->cookies.get("coo-3").value().value() == "val-val-val");
}

TEST("cookies gathering during redirection") {
    AsyncTest test(1000);
    auto srv1 = make_server(test.loop);
    auto srv2 = make_server(test.loop);

    URISP uri1(new URI(srv1->uri()));
    URISP uri2(new URI(srv2->uri()));

    srv1->request_event.add([&](auto req){
        ServerResponseSP res = new ServerResponse(303, Headers().add("Location", uri2->to_string()), Body());
        res->cookies.add("coo-1", Response::Cookie("c1"));
        req->respond(res);
    });

    srv2->request_event.add([&](auto req){
        ServerResponseSP res = new ServerResponse(200, Headers(), Body(req->body));
        res->cookies.add("coo-2", Response::Cookie("c2"));
        if (req->cookies.get("coo-X")) {
            res->headers.add("h-x", "ok");
        }
        req->respond(res);
    });

    UserAgentSP ua(new UserAgent(test.loop));
    auto jar = ua->cookie_jar();
    Response::Cookie cooX("coo-X");
    jar->add("coo-X", cooX, uri2);

    auto req = Request::Builder().uri(uri1).build();
    ua->request(req);
    auto res = await_response(req, test.loop);
    CHECK(res->code == 200);
    CHECK(res->headers.get("h-x") == "ok");


    /* acutally cookies are stored for domain only, and here domain is IP address of
     * the local server, i.e. url1 and url2 point to the "same" domain */
    auto coo = jar->find(uri1);
    REQUIRE(coo.size() == 3);
    REQUIRE(coo[0].value() == "coo-X");
    REQUIRE(coo[1].value() == "c1");
    REQUIRE(coo[2].value() == "c2");
}

TEST("SSL-context injection") {
    if(!secure) return;
    AsyncTest test(1000);

    auto srv = make_ssl_server(test.loop);
    srv->autorespond(new ServerResponse(200, Headers(), Body("hi")));

    URISP uri(new URI(srv->uri()));

    UserAgentSP ua(new UserAgent(test.loop));
    auto client_cert = TClient::get_context("01-alice");
    ua->ssl_ctx(client_cert);

    auto req = Request::Builder().uri(uri).build();
    ua->request(req);
    auto res = await_response(req, test.loop);
    CHECK(res->code == 200);
}

TEST("proxy injection") {
    AsyncTest test(1000, {"proxy"});
    ClientPair p(test.loop, true);
    URISP uri(new URI(p.server->uri()));

    auto cfg = UserAgent::Config();
    cfg.proxy = p.proxy.url;

    UserAgentSP ua(new UserAgent(test.loop, "", cfg));
    auto req = Request::Builder().method(Request::Method::Get).uri(uri).build();

    p.proxy.server->connection_event.add([&](auto...){ test.happens("proxy"); });
    p.server->enable_echo();

    ua->request(req);
    auto res = await_response(req, test.loop);
    CHECK(res->code == 200);
}
