#include "../lib/test.h"

#define TEST(name) TEST_CASE("client-partial: " name, "[client-partial]" VSSL)

TEST("chunked response receive") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    ServerResponseSP sres;

    p.server->request_event.add([&](auto req) {
        sres = new ServerResponse(200, Headers(), Body(), true);
        req->respond(sres);
    });

    auto req = Request::Builder().uri("/").build();

    size_t count = 10;
    req->partial_event.add([&](auto, auto, auto err) {
        if (err) throw err;

        if (count--) {
            sres->send_chunk("a");
            return;
        }

        sres->send_final_chunk();

        req->partial_event.remove_all();
        req->partial_event.add([&](auto, auto res, auto err) {
            if (err) throw err;
            if (!res->is_done()) return;
            test.happens();
            CHECK(res->body.to_string() == "aaaaaaaaaa");
        });
    });

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
    CHECK(res->chunked);
    CHECK(res->is_done());
    CHECK(res->body.to_string() == "aaaaaaaaaa");
}

TEST("chunked request send") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    ServerResponseSP sres;

    auto req = Request::Builder().uri("/").method(Request::Method::Post).chunked().build();

    size_t count = 10;
    p.server->route_event.add([&](auto sreq) {
        CHECK(sreq->method_raw() == Request::Method::Post);
        CHECK(sreq->uri->path() == "/");
        sreq->enable_partial();

        sreq->partial_event.add([&](auto sreq, auto err) {
            if (err) throw err;
            if (--count) {
                req->send_chunk("a");
                return;
            }
            req->send_final_chunk();

            sreq->partial_event.remove_all();
            sreq->partial_event.add([&](auto sreq, auto err) {
                if (err) throw err;
                if (!sreq->is_done()) return;
                CHECK(sreq->chunked);
                test.happens();
                CHECK(sreq->body.to_string() == "aaaaaaaaaa");
                sreq->respond(new ServerResponse(200, Headers(), Body(sreq->body)));
            });
        });

        req->send_chunk("a");
    });

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
    CHECK_FALSE(res->chunked);
    CHECK(res->body.to_string() == "aaaaaaaaaa");
}

TEST("receiving full response before transfer completed") {
    AsyncTest test(1000);
    ClientPair p(test.loop);

    ServerResponseSP sres;

    p.server->route_event.add([&](auto sreq) {
        sreq->enable_partial();
        sreq->partial_event.add([&](auto sreq, auto err) {
            if (err) throw err;
            CHECK(!sreq->is_done());
            sreq->respond(new ServerResponse(200, Headers(), Body("hi")));
            sreq->partial_event.remove_all();
        });
    });

    auto req = Request::Builder().uri("/").method(Request::Method::Post).chunked().build();
    req->response_event.add([&](auto, auto res, auto err) {
        CHECK(res->code == 200);
        CHECK(res->body.to_string() == "hi");
        CHECK(err & errc::transfer_aborted);
        CHECK_THROWS(req->send_chunk("epta")); // client must cease transmission on receiving final status code
        test.loop->stop();
    });

    p.client->request(req);
    test.loop->run();
}

TEST("100-continue") {
    AsyncTest test(1000, 3);
    ClientPair p(test.loop);

    p.server->route_event.add([&](auto req) {
        req->send_continue();
        req->send_continue();
        req->send_continue();
    });
    p.server->autorespond(new ServerResponse(200));

    auto req = Request::Builder().uri("/").headers(Headers().expect_continue()).build();
    req->continue_event.add([&](auto) { test.happens(); });

    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("100-continue unexpected") {
    AsyncTest test(1000, 0);
    ClientPair p(test.loop);

    p.server->route_event.add([&](auto req) {
        req->headers.expect_continue(); // we need to hack server otherwise it won't send 100-continue
        req->send_continue();
    });
    p.server->autorespond(new ServerResponse(200));

    auto req = Request::Builder().uri("/").build();
    req->continue_event.add([&](auto) { test.happens(); });

    auto err = p.client->get_error(req);
    CHECK(err & panda::protocol::http::errc::unexpected_continue);
}
