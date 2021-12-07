#include "../lib/test.h"
#include <panda/unievent/streamer/File.h>

using Catch::Matchers::ContainsSubstring;

#define TEST(name) TEST_CASE("client-form: " name, "[client-form]")

TEST("form field") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto& req){
        // TODO: parse form
        test.happens();
        auto body = req->body.to_string();
        REQUIRE_THAT(body, ContainsSubstring("secret"));
        REQUIRE_THAT(body, ContainsSubstring("password"));
        ServerResponseSP res = new ServerResponse(200, Headers(), Body());
        req->respond(res);
    });

    auto req = Request::Builder().uri("/").form_field("password", "secret").build();
    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("embedded form file + field") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto& req){
        // TODO: parse form
        test.happens();
        auto body = req->body.to_string();
        REQUIRE_THAT(body, ContainsSubstring("secret"));
        REQUIRE_THAT(body, ContainsSubstring("password"));
        REQUIRE_THAT(body, ContainsSubstring("resume"));
        REQUIRE_THAT(body, ContainsSubstring("[pdf]"));
        REQUIRE_THAT(body, ContainsSubstring("application/pdf"));
        REQUIRE_THAT(body, ContainsSubstring("cv.pdf"));
        ServerResponseSP res = new ServerResponse(200, Headers(), Body());
        req->respond(res);
    });

    auto req = Request::Builder().uri("/")
            .form_field("password", "secret")
            .form_file("resume", "[pdf]", "application/pdf", "cv.pdf")
            .build();
    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("form file streaming") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto& req){
        // TODO: parse form
        test.happens();
        auto body = req->body.to_string();
        REQUIRE_THAT(body, ContainsSubstring("source"));
        REQUIRE_THAT(body, ContainsSubstring("test.happens()"));
        ServerResponseSP res = new ServerResponse(200, Headers(), Body());
        req->respond(res);
    });


    auto req = Request::Builder().uri("/")
            .form_file("source", new streamer::FileInput("tests/client/form.cc"), "application/pdf", "cv.pdf")
            .build();
    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("form file streaming + fields") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto& req){
        // TODO: parse form
        test.happens();
        auto body = req->body.to_string();
        REQUIRE_THAT(body, ContainsSubstring("secret"));
        REQUIRE_THAT(body, ContainsSubstring("password"));
        REQUIRE_THAT(body, ContainsSubstring("source"));
        REQUIRE_THAT(body, ContainsSubstring("test.happens()"));
        REQUIRE_THAT(body, ContainsSubstring("signature"));
        REQUIRE_THAT(body, ContainsSubstring("Darth Vader"));
        ServerResponseSP res = new ServerResponse(200, Headers(), Body());
        req->respond(res);
    });

    auto req = Request::Builder().uri("/")
            .form_field("password", "secret")
            .form_file("source", new streamer::FileInput("tests/client/form.cc"), "application/pdf", "cv.pdf")
            .form_field("signature", "Darth Vader")
            .build();
    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("form file streaming error") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    auto req = Request::Builder().uri("/")
            .form_file("source", new streamer::FileInput("tests/client/not-existant.zzz"), "application/pdf", "cv.pdf")
            .form_field("signature", "Looser")
            .build();
    try {
        p.client->get_response(req);
    }  catch (const ErrorCode& ec) {
        using namespace panda::unievent;
        test.happens();
        CHECK(ec);
        CHECK(ec.code() == streamer_errc::read_error);
    }
}
