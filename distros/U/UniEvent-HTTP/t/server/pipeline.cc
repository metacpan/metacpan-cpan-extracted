#include "../lib/test.h"

#define TEST(name) TEST_CASE("server-pipeline: " name, "[server-pipeline]" VSSL)

TEST("basic") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    bool async = false, reverse = false;
    SECTION("sync response") {}
    SECTION("async response, same order") { async = true; }
    SECTION("async response, reverse order") { async = true; reverse = true; }

    std::vector<ServerRequestSP> reqs;

    p.server->request_event.add([&](auto& req) {
        if (!async) {
            req->respond(new ServerResponse(200, Headers(), Body(req->uri->path())));
            return;
        }

        reqs.push_back(req);
        if (reqs.size() < 3) return;

        test.loop->delay([&]{
            if (!reverse) {
                for (auto req : reqs) {
                    req->respond(new ServerResponse(200, Headers(), Body(req->uri->path())));
                }
            } else {
                for (auto it = reqs.rbegin(); it != reqs.rend(); ++it) {
                    auto req = *it;
                    req->respond(new ServerResponse(200, Headers(), Body(req->uri->path())));
                }
            }
        });
    });

    p.conn->write(
        "GET /a HTTP/1.1\r\n\r\n"
        "GET /b HTTP/1.1\r\n\r\n"
        "GET /c HTTP/1.1\r\n\r\n"
    );

    auto res = p.get_response();
    CHECK(res->code == 200);
    CHECK(res->body.to_string() == "/a");

    res = p.get_response();
    CHECK(res->code == 200);
    CHECK(res->body.to_string() == "/b");

    res = p.get_response();
    CHECK(res->code == 200);
    CHECK(res->body.to_string() == "/c");
}

TEST("chunked response captured and sent later") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    bool full;
    string check = "1234";
    SECTION("full chunked response") { full = true;}
    SECTION("partial chunked response") { full = false; check += "56"; }

    ServerRequestSP req1;
    p.server->request_event.add([&](auto& req) {
        if (!req1) {
            req1 = req;
            return;
        }

        auto res = new ServerResponse(200, Headers(), Body(), true);
        req->respond(res);
        res->send_chunk("12");
        res->send_chunk("34");
        if (full) res->send_final_chunk();

        test.loop->delay([&, res]{
            req1->respond(new ServerResponse(302, Headers(), Body("000")));
            if (!full) {
                res->send_chunk("56");
                res->send_final_chunk();
            }
        });
    });

    p.conn->write(
        "GET /a HTTP/1.1\r\n\r\n"
        "GET /b HTTP/1.1\r\n\r\n"
    );

    auto res = p.get_response();
    CHECK(res->code == 302);
    CHECK(res->body.to_string() == "000");

    res = p.get_response();
    CHECK(res->code == 200);
    CHECK(res->body.to_string() == check);
}

TEST("request connection close") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    bool chunked = GENERATE(false, true);
    SECTION(chunked ? "response chunked" : "response full") {}

    bool second = false;
    p.server->request_event.add([&](auto& req) {
        if (!second) {
            req->respond(new ServerResponse(200, Headers(), Body("ans1")));
            second = true;
            return;
        }

        if (!chunked) {
            req->respond(new ServerResponse(200, Headers(), Body("ans2")));
            return;
        } else {
            req->respond(new ServerResponse(200, Headers(), Body(), true));
            test.loop->delay([&, req]{
                req->response()->send_chunk("ans2");
                test.loop->delay([&, req]{
                    req->response()->send_final_chunk();
                });
            });
        }
    });

    p.conn->write(
        "GET /a HTTP/1.1\r\n\r\n"

        "GET /b HTTP/1.1\r\n"
        "Connection: close\r\n"
        "\r\n"
    );

    auto res = p.get_response();
    CHECK(res->body.to_string() == "ans1");
    res = p.get_response();
    CHECK(res->body.to_string() == "ans2");

    CHECK(p.wait_eof(50));
}

TEST("request connection close waits until all previous requests are done") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    bool chunked1 = GENERATE(false, true);
    bool chunked2 = GENERATE(false, true);
    SECTION(string("chunked first-second response: ") + char(chunked1 + '0') + '-' + char(chunked2 + '0')){}

    ServerRequestSP req1;

    auto req1_ans = [&]{
        if (chunked1) {
            req1->respond(new ServerResponse(200, Headers(), Body(), true));
            test.loop->delay([&]{
                req1->response()->send_chunk("ans1");
                test.loop->delay([&]{
                    req1->response()->send_final_chunk();
                });
            });
        }
        else req1->respond(new ServerResponse(200, Headers(), Body("ans1")));
    };

    p.server->request_event.add([&](auto& req) {
        if (!req1) { req1 = req; return; }
        test.loop->delay([&, req]{
            if (chunked2) {
                req->respond(new ServerResponse(200, Headers(), Body(), true));
                test.loop->delay([&, req]{
                    req->response()->send_chunk("ans2");
                    test.loop->delay([&, req]{
                        req->response()->send_final_chunk();
                        test.loop->delay(req1_ans);
                    });
                });
            } else {
                req->respond(new ServerResponse(200, Headers(), Body("ans2")));
                test.loop->delay(req1_ans);
            }
        });
    });

    p.conn->write(
        "GET /a HTTP/1.1\r\n\r\n"

        "GET /b HTTP/1.1\r\n"
        "Connection: close\r\n"
        "\r\n"
    );

    auto res = p.get_response();
    CHECK(res->body.to_string() == "ans1");
    res = p.get_response();
    CHECK(res->body.to_string() == "ans2");

    CHECK(p.wait_eof(50));
}

TEST("all requests after one with connection=close are ignored") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    p.server->request_event.add([&](auto& req){
        p.conn->write("GET /c HTTP/1.0\r\n\r\n");
        req->respond(new ServerResponse(200));
        p.server->request_event.remove_all();
        p.server->request_event.add(fail_cb);
    });
    p.server->error_event.add(fail_cb);

    p.conn->write(
        "GET /a HTTP/1.0\r\n\r\n"
        "GET /b HTTP/1.0\r\n\r\n"
    );

    auto res = p.get_response();
    CHECK(res->code == 200);

    CHECK(p.wait_eof(50));
}

TEST("response connection=close cancels all further requests") {
    AsyncTest test(1000, {"drop", "partial-err"});
    ServerPair p(test.loop);

    std::vector<ServerRequestSP> reqs;

    p.server->route_event.add([&](auto& req){
        reqs.push_back(req);
        if (reqs.size() == 2) req->drop_event.add([&](auto&, auto& err){
            test.happens("drop");
            CHECK(err & errc::pipeline_canceled);
        });
        if (reqs.size() < 3) return;
        req->enable_partial();
        req->partial_event.add([&](auto& req, auto& err){
            CHECK_FALSE(err);
            CHECK(!req->is_done());
            req->partial_event.remove_all();
            req->partial_event.add([&](auto&, auto& err){
                CHECK(err & errc::pipeline_canceled);
                test.happens("partial-err");
            });
            reqs[0]->respond(new ServerResponse(200, Headers().connection("close"), Body("hello")));
        });
    });
    p.server->error_event.add(fail_cb);

    p.conn->write(
        "GET /a HTTP/1.1\r\n\r\n"
        "GET /b HTTP/1.1\r\n\r\n"
        "GET /c HTTP/1.1\r\n"
        "Content-Length: 4\r\n"
        "\r\n"
    );

    auto res = p.get_response();
    CHECK(res->body.to_string() == "hello");
    CHECK(!res->keep_alive());

    CHECK(p.wait_eof(50));
}
