#include "../lib/test.h"
#include "panda/protocol/http/Headers.h"
#include "panda/unievent/http/Request.h"
#include "panda/unievent/http/ServerRequest.h"
#include "panda/unievent/http/ServerResponse.h"
#include <cstdlib>

#define TEST(name) TEST_CASE("client-pool: " name, "[client-pool]" VSSL)

TEST("reusing connection") {
    AsyncTest test(1000, 1);
    TPool p(test.loop);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200));
    srv->autorespond(new ServerResponse(200));

    CHECK_FALSE(p.size());
    CHECK_FALSE(p.nbusy());

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    auto req = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c = p.request(req);
    REQUIRE(c);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 1);

    c->connect_event.add([&](auto...){ test.happens(); }); // should connect only once

    auto res = await_response(req, test.loop);
    CHECK(res->code == 200);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 0);

    auto c2 = p.request(req); // should be the same client
    CHECK(c == c2);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 1);

    res = await_response(req, test.loop);
    CHECK(res->code == 200);
}

TEST("reusing connection after c=close") {
    AsyncTest test(1000, 2);
    TPool p(test.loop);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200, Headers().connection("close")));
    srv->autorespond(new ServerResponse(200));

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    auto req = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c = p.request(req);
    REQUIRE(c);

    c->connect_event.add([&](auto...){ test.happens(); }); // should connect twice

    auto res = await_response(req, test.loop);
    CHECK(res->code == 200);
    CHECK_FALSE(res->keep_alive());

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 0);

    auto c2 = p.request(req);
    CHECK(c == c2);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 1);

    res = await_response(req, test.loop);
    CHECK(res->code == 200);
}


TEST("different servers") {
    AsyncTest test(1000, 2);
    TPool p(test.loop);
    auto srv1 = make_server(test.loop);
    auto srv2 = make_server(test.loop);
    srv1->autorespond(new ServerResponse(200));
    srv2->autorespond(new ServerResponse(200));

    auto uri1 = active_scheme() +  "://" + srv1->location() + "/";
    auto req1 = Request::Builder().method(Request::Method::Get).uri(uri1).build();
    auto c = p.request(req1);
    REQUIRE(c);
    c->connect_event.add([&](auto...){ test.happens(); });

    auto res = await_response(req1, test.loop);
    CHECK(res->code == 200);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 0);

    auto uri2 = active_scheme() +  "://" + srv2->location() + "/";
    auto req2 = Request::Builder().method(Request::Method::Get).uri(uri2).build();
    auto c2 = p.request(req2);
    REQUIRE(c2);
    c2->connect_event.add([&](auto...){ test.happens(); });

    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 1);

    res = await_response(req2, test.loop);
    CHECK(res->code == 200);

    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 0);
}

TEST("several requests to the same server at once") {
    AsyncTest test(1000, 2);
    TPool p(test.loop);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200, Headers(), Body("1")));
    srv->autorespond(new ServerResponse(200, Headers(), Body("1")));
    srv->autorespond(new ServerResponse(200, Headers(), Body("2")));
    srv->autorespond(new ServerResponse(200, Headers(), Body("2")));

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    auto r1 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c1 = p.request(r1);
    REQUIRE(c1);
    c1->connect_event.add([&](auto...){ test.happens(); });

    auto r2 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c2 = p.request(r2);
    REQUIRE(c2);
    c2->connect_event.add([&](auto...){ test.happens(); });

    CHECK(c1 != c2);
    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 2);

    auto req1 =std::vector<RequestSP>{r1, r2};
    auto res1 = await_responses(req1, test.loop);
    REQUIRE(res1.size() == 2);
    CHECK(res1[0]->code == 200);
    CHECK(res1[0]->body.to_string() == "1");
    CHECK(res1[1]->code == 200);
    CHECK(res1[1]->body.to_string() == "1");
    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 0);


    auto r3 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c3 = p.request(r3);
    CHECK((c3 == c1 || c3 == c2));
    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 1);

    auto r4 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c4 = c2 = p.request(r4);
    CHECK((c4 == c1 || c4 == c2));
    CHECK(c4 != c3);
    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 2);

    auto req2 =std::vector<RequestSP>{r3, r4};
    auto res2 = await_responses(req2, test.loop);
    REQUIRE(res2.size() == 2);
    CHECK(res2[0]->code == 200);
    CHECK(res2[0]->body.to_string() == "2");
    CHECK(res2[1]->code == 200);
    CHECK(res2[1]->body.to_string() == "2");
    CHECK(p.size() == 2);
    CHECK(p.nbusy() == 0);
}

TEST("idle timeout") {
    AsyncTest test(1000, 2);
    TPoolSP p;

    SECTION("set at creation time") {
        Pool::Config cfg;
        cfg.idle_timeout = 5;
        p = new TPool(cfg, test.loop);
    }
    SECTION("set at runtime") {
        p = new TPool(test.loop);
        p->idle_timeout(5);
    }

    auto srv = make_server(test.loop);

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    auto req1 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto c = p->request(req1);
    REQUIRE(c);
    c->connect_event.add([&](auto...){ test.happens(); });

    test.wait(15); // more than idle_timeout
    // client is busy and not affected by idle timeout
    CHECK(p->size() == 1);
    CHECK(p->nbusy() == 1);

    req1->cancel();

    test.wait(15);
    CHECK(p->size() == 0);
    CHECK(p->nbusy() == 0);

    srv->autorespond(new ServerResponse(200));
    auto req2 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    c = p->request(req2);
    REQUIRE(c);
    c->connect_event.add([&](auto...){ test.happens(); });
    CHECK(p->size() == 1);
    CHECK(p->nbusy() == 1);

    auto res = await_response(req2, test.loop);
    CHECK(res->code == 200);
}

TEST("instance") {
    auto dpool = Pool::instance(Loop::default_loop());
    CHECK(dpool == Pool::instance(Loop::default_loop()));
    CHECK(dpool == Pool::instance(Loop::default_loop()));

    LoopSP l2 = new Loop();
    auto p2 = Pool::instance(l2);
    CHECK(p2 != dpool);
    CHECK(p2 == Pool::instance(l2));
}

TEST("http_request") {
    AsyncTest test(1000, 1);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200, Headers(), Body("hi")));

    auto uristr = active_scheme()+ string("://") + srv->location() + '/';
    auto req = Request::Builder().uri(uristr).build();
    req->response_event.add([&](auto, auto res, auto err) {
        CHECK_FALSE(err);
        CHECK(res->body.to_string() == "hi");
        test.happens();
        test.loop->stop();
    });

    http_request(req, test.loop);

    auto pool = Pool::instance(test.loop);
    CHECK(pool->size() == 1);
    CHECK(pool->nbusy() == 1);

    test.run();
}

TEST("SSL certificate nuances") {
    if (!secure) { return; }

    AsyncTest test(1000, 3);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200, Headers(), Body("hi")));
    srv->autorespond(new ServerResponse(200, Headers(), Body("hi")));
    srv->autorespond(new ServerResponse(200, Headers(), Body("hi")));
    auto cert1 = TClient::get_context("01-alice");
    auto cert2 = TClient::get_context("02-bob");
    TPool p(test.loop);

    TClientSP c1, c2, c3;
    auto uristr = active_scheme()+ string("://") + srv->location() + '/';
    auto req1 = Request::Builder().uri(uristr).ssl_ctx(cert1).build();
    {
        c1 = p.request(req1);
        REQUIRE(c1);
        c1->connect_event.add([&](auto...){ test.happens(); });

        auto res = await_response(req1, test.loop);

        CHECK(res->code == 200);

        CHECK(p.size() == 1);
        CHECK(p.nbusy() == 0);
    }

    {   //different client certificate
        auto req2 = Request::Builder().uri(uristr).ssl_ctx(cert2).build();
        c2 = p.request(req2);
        REQUIRE(c2);
        REQUIRE(c1 != c2);
        c2->connect_event.add([&](auto...){ test.happens(); });

        auto res = await_response(req2, test.loop);

        CHECK(res->code == 200);

        CHECK(p.size() == 2);
        CHECK(p.nbusy() == 0);
    }

    {   // no client certificate
        auto req3 = Request::Builder().uri(uristr).build();
        c3 = p.request(req3);
        REQUIRE(c3);
        REQUIRE(c3 != c2);
        REQUIRE(c3 != c1);
        c3->connect_event.add([&](auto...){ test.happens(); });

        auto res = await_response(req3, test.loop);

        CHECK(res->code == 200);

        CHECK(p.size() == 3);
        CHECK(p.nbusy() == 0);
    }

    { // with proxy, but the same cert as c1
        auto proxy = new_proxy(test.loop);
        auto req = Request::Builder().uri(uristr).ssl_ctx(cert1).proxy(proxy.url).build();
        auto c4 = p.request(req);
        REQUIRE(c4 != c1);
        REQUIRE(c4 != c2);
        REQUIRE(c4 != c3);
    }
}

TEST("request/client continue to work fine after pool is unreferenced") {
    AsyncTest test(1000, 1);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200));

    auto req = Request::Builder().uri("/").response_callback([&](auto, auto res, auto err) {
        CHECK_FALSE(err);
        CHECK(res->code == 200);
        test.happens();
        test.loop->stop();
    }).build();
    req->uri->host(srv->sockaddr()->ip());
    req->uri->port(srv->sockaddr()->port());
    if (secure) req->uri->scheme("https");

    {
        Pool p(test.loop);
        p.request(req);
    }

    test.run();
}

TEST("connection queuing") {
    AsyncTest test(5000);
    Pool::Config cfg;
    cfg.max_connections = 1;
    TPool p(cfg, test.loop);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200));
    srv->autorespond(new ServerResponse(200));

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    std::vector<RequestSP> v;

    auto r1 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto r2 = Request::Builder().method(Request::Method::Get).uri(uri).build();
    auto r3 = Request::Builder().method(Request::Method::Get).uri(uri).build();

    auto c1 = p.request(r1);
    auto c2 = p.request(r2);

    REQUIRE(c1);
    REQUIRE(!c2);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 1);

    auto res = await_response(r1, test.loop);
    CHECK(res->code == 200);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 1);

    res = await_response(r2, test.loop);
    CHECK(res->code == 200);

    CHECK(p.size() == 1);
    CHECK(p.nbusy() == 0);
}

TEST("proxies using") {
    AsyncTest test(1000, 3);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200));
    srv->autorespond(new ServerResponse(200));
    srv->autorespond(new ServerResponse(200));
    TPool p(test.loop);

    TClientSP c1, c2, c3;
    auto p1 = new_proxy(test.loop), p2 = new_proxy(test.loop);
    REQUIRE(p1.url != p2.url);
    auto uristr = active_scheme()+ string("://") + srv->location() + '/';
    auto req1 = Request::Builder().uri(uristr).proxy(p1.url).build();
    {
        c1 = p.request(req1);
        REQUIRE(c1);

        c1->connect_event.add([&](auto...){ test.happens(); });

        auto res = await_response(req1, test.loop);

        CHECK(res->code == 200);

        CHECK(p.size() == 1);
        CHECK(p.nbusy() == 0);
    }

    {   //different proxy
        auto req2 = Request::Builder().uri(uristr).proxy(p2.url).build();
        c2 = p.request(req2);
        REQUIRE(c2);
        REQUIRE(c1 != c2);
        c2->connect_event.add([&](auto...){ test.happens(); });

        auto res = await_response(req2, test.loop);

        CHECK(res->code == 200);

        CHECK(p.size() == 2);
        CHECK(p.nbusy() == 0);
    }

    {   // no proxy
        auto req3 = Request::Builder().uri(uristr).build();
        c3 = p.request(req3);
        REQUIRE(c3);
        REQUIRE(c3 != c2);
        REQUIRE(c3 != c1);
        c3->connect_event.add([&](auto...){ test.happens(); });

        auto res = await_response(req3, test.loop);

        CHECK(res->code == 200);

        CHECK(p.size() == 3);
        CHECK(p.nbusy() == 0);
    }

    { // same as client 1
        auto c4 = p.request(req1);
        CHECK(c4 == c1);
    }
}

TEST("ssl_cert_check") {
    AsyncTest test(1000, {"res", "res"});
    TPool p(test.loop);
    auto srv = make_server(test.loop);
    srv->autorespond(new ServerResponse(200));
    srv->autorespond(new ServerResponse(200));

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    auto builder = Request::Builder().method(Request::Method::Get).uri(uri);
    auto req = builder.ssl_check_cert(true).build();
    auto c = p.request(req);
    REQUIRE(c);

    test.await(req->response_event, "res");

    req = builder.ssl_check_cert(false).build();
    auto c2 = p.request(req);

    REQUIRE(c != c2);

    test.await(req->response_event, "res");
}

TEST("request timeout applied when not yet executing (queued)") {
    AsyncTest test(5000, {"srv", "r2"});
    bool asan = getenv("ASAN_OPTIONS");
    TPool p(test.loop);
    p.max_connections(1);
    auto srv = make_server(test.loop);
    srv->request_event.add([&](const ServerRequestSP& req){
        test.happens("srv");
        REQUIRE_FALSE(req->uri->path() == "/r2");
    });

    auto uri = active_scheme() +  "://" + srv->location() + "/";
    auto req1 = Request::Builder().method(Request::Method::Get).uri(uri + "r1").timeout(0).build();
    auto req2 = Request::Builder().method(Request::Method::Get).uri(uri + "r2").timeout(asan ? 1000 : 50).build();
    auto c1 = p.request(req1);
    REQUIRE(c1);
    auto c2 = p.request(req2);
    REQUIRE_FALSE(c2);

    req1->response_event.add([&](auto...) {
        FAIL("should not happen");
    });
    
    req2->response_event.add([&](auto, auto, auto& err) {
        test.happens("r2");
        CHECK(err & std::errc::timed_out);
        test.loop->stop();
    });

    test.run();
    
    req1->response_event.remove_all();
    req1->cancel();
}

TEST("request timeout applied when not yet executing (queued) after redirect") {
    AsyncTest test(5000, {"srv1-r1", "srv1-r2", "r2"});
    TPool p(test.loop);
    bool asan = getenv("ASAN_OPTIONS");
    p.max_connections(1);
    auto srv1 = make_server(test.loop);
    auto srv2 = make_server(test.loop);
    auto uri1 = active_scheme() +  "://" + srv1->location() + "/";
    auto uri2 = active_scheme() +  "://" + srv2->location() + "/";
    
    srv1->request_event.add([&](const ServerRequestSP& req) {
        if (req->uri->path() == "/r1") test.happens("srv1-r1");
        else                           test.happens("srv1-r2");
        req->respond(new ServerResponse(302, Headers().location(uri2)));
    });
    
    srv2->request_event.add([&](const ServerRequestSP& req) {
        REQUIRE_FALSE(req->uri->path() == "/r2");
    });

    auto req1 = Request::Builder().method(Request::Method::Get).uri(uri1 + "r1").timeout(0).build();
    auto req2 = Request::Builder().method(Request::Method::Get).uri(uri1 + "r2").timeout(asan ? 2000 : 100).build();
    auto c1 = p.request(req1);
    REQUIRE(c1);
    auto c2 = p.request(req2);
    REQUIRE_FALSE(c2);
    
    req1->response_event.add([&](auto...) {
        FAIL("should not happen");
    });

    req2->response_event.add([&](auto, auto, auto& err) {
        test.happens("r2");
        CHECK(err & std::errc::timed_out);
        test.loop->stop();
    });
    
    test.run();
    
    req1->response_event.remove_all();
    req1->cancel();
}
