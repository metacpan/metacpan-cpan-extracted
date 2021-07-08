#include "../lib/test.h"

#define TEST(name) TEST_CASE("server-partial: " name, "[server-partial]" VSSL)

TEST("request receive") {
    AsyncTest test(1000, 5);
    ServerPair p(test.loop);

    p.server->route_event.add([&](auto& req){
        test.happens();
        req->enable_partial();
        req->receive_event.add(fail_cb);
        req->partial_event.add([&](auto& req, auto& err) {
            test.happens();
            CHECK(!err);
            auto body = req->body.to_string();
            if (!body) {
                CHECK(!req->is_done());
                p.conn->write("1");
            }
            else if (body == "1") {
                CHECK(!req->is_done());
                p.conn->write("2");
            } else if (body == "12") {
                CHECK(!req->is_done());
                p.conn->write("3");
            } else if (body == "123") {
                CHECK(req->is_done());
                req->respond(new ServerResponse(200, Headers(), Body("epta")));
            }
        });
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "Content-Length: 3\r\n"
        "\r\n"
    );

    auto res = p.get_response();
    CHECK(res->code == 200);
    CHECK(res->body.to_string() == "epta");
}

TEST("full response on route event") {
    AsyncTest test(1000, 3);
    ServerPair p(test.loop);

    p.server->route_event.add([&](auto& req) {
        test.happens();
        req->enable_partial();
        req->partial_event.add([&](auto& req, auto& err) {
            test.happens();
            CHECK(!err);
            if (req->is_done()) test.loop->stop();
        });
        req->respond(new ServerResponse(302, Headers(), Body("route-res")));
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "Content-Length: 4\r\n"
        "\r\n"
    );

    auto res = p.get_response();
    CHECK(res->code == 302);
    CHECK(res->body.to_string() == "route-res");

    p.conn->write("epta");
    test.run();
}

TEST("full response on partial event when request is not yet fully parsed") {
    AsyncTest test(1000, 3);
    ServerPair p(test.loop);

    p.server->route_event.add([&](auto& req) {
        test.happens();
        req->enable_partial();
        req->partial_event.add([&](auto& req, auto& err) {
            test.happens();
            CHECK(!err);
            if (req->is_done()) test.loop->stop();
            else req->respond(new ServerResponse(200, Headers(), Body("partial-res")));
        });
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "Content-Length: 4\r\n"
        "\r\n"
    );

    auto res = p.get_response();
    CHECK(res->code == 200);
    CHECK(res->body.to_string() == "partial-res");

    p.conn->write("epta");
    test.run();
}

TEST("client disconnects or request error while in partial mode") {
    AsyncTest test(1000, 2);
    ServerPair p(test.loop);

    bool send_junk = false;
    bool partial_response = false;
    SECTION("client disconnects") { }
    SECTION("parsing error") { send_junk = true; }
    SECTION("partial response") { partial_response = true; }

    p.server->error_event.add(fail_cb);

    p.server->route_event.add([&](auto& req) {
        req->enable_partial();
        req->drop_event.add(fail_cb);
        req->partial_event.add([&](auto& req, auto& err) {
            test.happens();
            CHECK(!err);
            CHECK(!req->is_done());
            req->partial_event.remove_all();
            req->partial_event.add([&](auto& req, auto& err) {
                test.happens();
                if (send_junk) {
                    CHECK(req->is_done());
                    CHECK(err & panda::protocol::http::errc::lexical_error);
                }
                else {
                    CHECK(err & std::errc::connection_reset);
                }
                test.loop->stop();
            });
            if (partial_response) req->respond(new ServerResponse(200, Headers(), Body(), true));
            if (send_junk) p.conn->write("something not looking like chunk");
            else           p.conn->disconnect();
        });
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
    );

    test.run();
}

TEST("client disconnects when partial mode is finished") {
    AsyncTest test(1000, 3);
    ServerPair p(test.loop);

    p.server->error_event.add(fail_cb);

    p.server->route_event.add([&](auto& req) {
        req->enable_partial();
        req->drop_event.add([&](auto...){
            test.happens();
            test.loop->stop();
        });
        req->partial_event.add([&](auto& req, auto& err) {
            test.happens();
            CHECK(!err);
            CHECK(!req->is_done());
            p.conn->write("1234");
            req->partial_event.remove_all();
            req->partial_event.add([&](auto& req, auto& err) {
                test.happens();
                CHECK(!err);
                CHECK(req->is_done());
                req->partial_event.remove_all();
                req->partial_event.add(fail_cb);
                p.conn->disconnect();
            });
        });
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "Content-Length: 4\r\n"
        "\r\n"
    );

    test.run();
}

// this test checks that we are able to receive remaining request parts even if we have given a complete response for this request
// and if our response is non-KA or request was non-KA, then connection closes only after request if fully received
TEST("response is complete before request fully received") {
    AsyncTest test(1000, 2);
    ServerPair p(test.loop);

    bool chunked = GENERATE(false, true);
    int closed   = GENERATE(0, 1, 2); // 1 - closed by request, 2 - closed by response
    SECTION(string(chunked ? "chunked" : "non-chunked") + ' ' + (closed ? (closed == 1 ? "request-close" : "response-close") : "keep-alive")) {}

    p.server->route_event.add([&](auto& req) {
        req->enable_partial();
        req->partial_event.add([&](auto& req, auto& err) {
            test.happens();
            CHECK(!err);
            CHECK(!req->is_done());
            ServerResponseSP res = new ServerResponse(200);
            if (closed == 2) res->keep_alive(false);

            if (chunked) {
                res->chunked = true;
                req->respond(res);
                req->response()->send_chunk("ans");
                req->response()->send_final_chunk();
            }
            else {
                res->body = "ans";
                req->respond(res);
            }

            req->partial_event.remove_all();
            req->partial_event.add([&](auto& req, auto& err) {
                test.happens();
                CHECK(!err);
                CHECK(req->is_done());
                CHECK(req->body.to_string() == "1234");
                test.loop->stop();
            });
        });
    });

    if (closed == 1)
        p.conn->write(
            "GET / HTTP/1.0\r\n"
            "Content-Length: 4\r\n"
            "\r\n"
        );
    else
        p.conn->write(
            "GET / HTTP/1.1\r\n"
            "Content-Length: 4\r\n"
            "\r\n"
        );

    auto res = p.get_response();
    CHECK(res->body.to_string() == "ans");
    CHECK(res->keep_alive() == bool(!closed));

    p.conn->write("1234");
    test.run();

    if (closed) CHECK(p.wait_eof(50));
    else        CHECK(!p.wait_eof(10));
}

TEST("100-continue") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    p.server->route_event.add([&](auto req) {
        req->send_continue();
    });
    p.server->autorespond(new ServerResponse(200));

    p.source_request = new RawRequest(Request::Method::Put, new URI("/"), Headers().add("Expect", "100-continue"));
    auto res = p.get_response(
        "PUT / HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Expect: 100-continue\r\n"
        "\r\n"
        "0\r\n\r\n"
    );
    CHECK(res->code == 100);

    res = p.get_response();
    CHECK(res->code == 200);
}

TEST("100-continue is not sent") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    ServerRequestSP pipelined_req;

    SECTION("when 1.0") {
        p.conn->write(
            "PUT / HTTP/1.0\r\n"
            "Transfer-Encoding: chunked\r\n"
            "Expect: 100-continue\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }
    SECTION("when not requested") {
        p.conn->write(
            "PUT / HTTP/1.1\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }
    SECTION("when pipelined") {
        p.conn->write("GET / HTTP/1.1\r\n\r\n");
        p.server->route_event.add([&](auto req) {
            pipelined_req = req;
            test.loop->stop();
            p.server->route_event.remove_all();
        });
        test.run();

        p.conn->write(
            "PUT / HTTP/1.1\r\n"
            "Transfer-Encoding: chunked\r\n"
            "Expect: 100-continue\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }

    p.server->route_event.add([&](auto req) {
        req->send_continue();
        if (pipelined_req) pipelined_req->respond(new ServerResponse(200));
    });
    p.server->autorespond(new ServerResponse(200));

    p.source_request = new RawRequest(Request::Method::Put, new URI("/"), Headers().add("Expect", "100-continue"));

    auto res = p.get_response();
    CHECK(res->code == 200);
    if (pipelined_req) {
        res = p.get_response();
        CHECK(res->code == 200);
    }
}

TEST("100-continue after response given") {
    AsyncTest test(1000);
    ServerPair p(test.loop);

    p.server->request_event.add([&](auto req) {
        req->respond(new ServerResponse(200, Headers(), Body(), true));
        CHECK_THROWS(req->send_continue());
        req->response()->send_final_chunk();
    });

    auto res = p.get_response(
        "PUT / HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Expect: 100-continue\r\n"
        "\r\n"
        "0\r\n\r\n"
    );
    CHECK(res->code == 200);
}

TEST("drop request") {
    AsyncTest test(2000);
    ServerPair p(test.loop);

    auto dcb = [&](auto, auto& err) {
        CHECK(err & std::errc::operation_canceled);
        test.happens("drop");
    };

    string data;
    p.conn->read_event.add([&](auto&, auto& str, auto& err) {
        if (err) throw err;
        data += str;
    });

    p.conn->eof_event.add([&](auto) {
        test.happens("eof");
        test.loop->stop();
    });

    SECTION("fully received but not started response") {
        test.expected = std::vector<string>{"drop", "eof"};
        p.server->request_event.add([&](auto req) {
            req->drop_event.add(dcb);
            req->drop();
        });
        p.conn->write("GET / HTTP/1.1\r\n\r\n");
        test.run();
        CHECK(data.length() == 0);
    }

    SECTION("not yet fully received") {
        test.expected = std::vector<string>{"partial", "partial", "eof"};
        p.server->route_event.add([&](auto& req){
            req->enable_partial();
            req->drop_event.add(dcb);
            req->partial_event.add([&](auto& req, auto& err) {
                REQUIRE(!err);
                test.happens("partial");
                req->partial_event.remove_all();
                req->partial_event.add([&](auto&, auto& err) {
                    test.happens("partial");
                    CHECK(err & std::errc::operation_canceled);
                });
                req->drop();
            });
        });
        p.conn->write(
            "GET / HTTP/1.1\r\n"
            "Content-Length: 10\r\n"
            "\r\n"
            "12345"
        );
        test.run();
        CHECK(data.length() == 0);
    }

    SECTION("received and started response") {
        test.expected = std::vector<string>{"drop", "eof"};
        p.server->request_event.add([&](auto req) {
            ServerResponseSP res = new ServerResponse(200);
            res->chunked = true;
            req->respond(res);
            res->send_chunk("epta");
            req->drop_event.add(dcb);
            req->drop();
        });
        p.conn->write("GET / HTTP/1.1\r\n\r\n");
        test.run();
        auto npos = string::npos;
        CHECK(data.find("4\r\nepta\r\n") != npos);
    }

    SECTION("received and fully sent response") {
        test.expected = std::vector<string>{"eof"};
        p.server->request_event.add([&](auto req) {
            ServerResponseSP res = new ServerResponse(200);
            res->keep_alive(false);
            req->respond(res);
            req->drop_event.add(dcb);
            req->drop(); // will be ignored, drop_event should not be called
        });
        p.conn->write("GET / HTTP/1.1\r\n\r\n");
        test.run();
        CHECK(data.length() > 0);
    }
}
