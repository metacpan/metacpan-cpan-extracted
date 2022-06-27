#include "../lib/test.h"

#define TEST(name) TEST_CASE("client-redirect: " name, "[client-redirect]" VSSL)

TEST("same server") {
    AsyncTest test(1000, {"connect", "redirect"});
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto req){
        if (req->uri->to_string() == "/") {
            CHECK(req->method_raw() == Request::Method::Post);
            req->redirect("/index");
        } else if (req->uri->to_string() == "/index") {
            CHECK(req->method_raw() == Request::Method::Post); // preserves original method
            req->respond(new ServerResponse(200, Headers().add("h", req->headers.get("h")), Body(req->body)));
        }
    });

    p.client->connect_event.add([&](auto...){ test.happens("connect"); });

    auto req = Request::Builder().method(Request::Method::Post).uri("/")
            .header("h", "v").header("Authorization", "secret")
            .cookie("c", "cv")
            .body("b").build();
    req->redirect_event.add([&](auto req, auto res, auto& red_ctx) {
        test.happens("redirect");
        CHECK(res->code == 302);
        CHECK(res->headers.location() == "/index");
        CHECK(req->uri->path() == "/index");
        CHECK(!req->ssl_ctx);
        CHECK(req->cookies.empty());
        CHECK(req->headers.get("h") == "v");
        CHECK(red_ctx->uri->path() == "/");
        CHECK(red_ctx->cookies.size() == 1);
        CHECK(red_ctx->cookies.get("c") == "cv");
        CHECK(red_ctx->removed_headers.size() == 1);
        CHECK(red_ctx->removed_headers.get("Authorization") == "secret");
    });

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
    CHECK(res->headers.get("h") == "v");
    CHECK(res->body.to_string() == "b");
    CHECK(req->uri->path() == "/index");
}

TEST("different server") {
    AsyncTest test(1000, {"connect", "redirect", "connect"});
    ClientPair p(test.loop);
    auto backend = make_server(test.loop);
    backend->enable_echo();

    p.server->request_event.add([&](auto req) {
        auto uri = req->uri;
        uri->host(backend->sockaddr()->ip());
        uri->port(backend->sockaddr()->port());
        req->redirect(uri);
    });

    p.client->connect_event.add([&](auto...){ test.happens("connect"); });

    auto req = Request::Builder().uri("/").header("h", "v").body("b").build();
    req->redirect_event.add([&](auto req, auto res, auto&) {
        test.happens("redirect");
        CHECK(res->code == 302);
        auto check_uri = string("//") + backend->location() + '/';
        CHECK(res->headers.location() == check_uri);
        auto& uri = req->uri;
        CHECK(uri->to_string() == (secure ? string("https:") : string("http:")) + check_uri);
    });

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
    CHECK(res->headers.get("h") == "v");
    CHECK(res->body.to_string() == "b");
}

TEST("redirection limit") {
    AsyncTest test(5000);

    auto req = Request::Builder().uri("/").build();

    int count = 10;
    SECTION("beyond limit") { req->redirection_limit = count; }
    SECTION("above limit")  { req->redirection_limit = count - 1; }
    SECTION("disallowed")   { req->redirection_limit = 0; }

    std::vector<TServerSP> backends = { make_server(test.loop) };
    backends[0]->autorespond(new ServerResponse(404));

    for (int i = 1; i <= count; ++i) {
        auto srv = make_server(test.loop);
        srv->request_event.add([&, i](auto req) {
            auto uri = req->uri;
            uri->host(backends[i-1]->sockaddr()->ip());
            uri->port(backends[i-1]->sockaddr()->port());
            req->redirect(uri);
        });
        backends.push_back(srv);
    }

    TClientSP client = new TClient(test.loop);
    client->sa = backends.back()->sockaddr().value();

    int rcnt = 0;
    req->redirect_event.add([&](auto...){ rcnt++; });

    if (req->redirection_limit == count) {
        auto res = client->get_response(req);
        CHECK(res->code == 404);
        CHECK(rcnt == count);
    } else if (req->redirection_limit) {
        auto err = client->get_error(req);
        CHECK(err & errc::redirection_limit);
        CHECK(rcnt == count - 1);
    } else {
        auto err = client->get_error(req);
        CHECK(err & errc::unexpected_redirect);
        CHECK(rcnt == 0);
    }
}

TEST("do not follow redirections") {
    AsyncTest test(1000);
    ClientPair p(test.loop);

    p.server->autorespond(new ServerResponse(302, Headers().location("http://ya.ru")));

    auto req = Request::Builder().uri("/").follow_redirect(false).build();
    auto res = p.client->get_response(req);
    CHECK(res->code == 302);
    CHECK(res->headers.get("Location") == "http://ya.ru");
}

TEST("timeout") { // timeout is for whole request including all redirections
    AsyncTest test(1000);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto req){
        if (req->uri->to_string() == "/") {
            req->redirect("/index");
        }
    });

    auto req = Request::Builder().uri("/").timeout(5).build();

    auto err = p.client->get_error(req);
    CHECK(err.contains(make_error_code(std::errc::timed_out)));
}

TEST("cancel from redirect event") {
    AsyncTest test(1000, {"srv", "redir", "response"});
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto req) {
        test.happens("srv");
        req->redirect("/index");
    });

    auto req = Request::Builder().uri("/").build();
    req->redirect_event.add([&](auto req, auto, auto) {
        test.happens("redir");
        req->cancel();
    });
    req->response_event.add([&](auto, auto, auto err) {
        test.happens("response");
        CHECK(err & std::errc::operation_canceled);
        test.loop->stop();
    });
    p.client->request(req);

    test.run();
}

TEST("redirect with connection close") {
    AsyncTest test(1000, {"connect", "redirect", "connect"});
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto req) {
        if (req->uri->to_string() == "/") {
            req->respond(new ServerResponse(302, Headers().location("/index").connection("close")));
        } else if (req->uri->to_string() == "/index") {
            req->respond(new ServerResponse(200));
        }
    });

    p.client->connect_event.add([&](auto...){ test.happens("connect"); });

    auto req = Request::Builder().uri("/").build();
    req->redirect_event.add([&](auto...) {
        test.happens("redirect");
    });

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("redirect with 303 (method changing to GET)") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto req){
        if (req->uri->to_string() == "/") {
            CHECK(req->method_raw() == Request::Method::Post);
            req->respond(new ServerResponse(303, Headers().location("/index")));
        } else if (req->uri->to_string() == "/index") {
            CHECK(req->method_raw() == Request::Method::Get); // method changed to GET
            req->respond(new ServerResponse(200));
        }
    });

    auto req = Request::Builder().method(Request::Method::Post).uri("/").redirect_callback([&](auto, auto res, auto) {
        test.happens();
        CHECK(res->code == 303);
    }).build();

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}
