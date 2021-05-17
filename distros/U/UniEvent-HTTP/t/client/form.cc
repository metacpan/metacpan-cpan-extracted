#include "../lib/test.h"
#include <panda/unievent/streamer/File.h>

using Catch::Matchers::Contains;

#define TEST(name) TEST_CASE("client-form: " name, "[client-form]")

TEST("form field") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    p.server->request_event.add([&](auto& req){
        // TODO: parse form
        test.happens();
        auto body = req->body.to_string();
        REQUIRE_THAT(body, Contains("secret"));
        REQUIRE_THAT(body, Contains("password"));
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
        REQUIRE_THAT(body, Contains("secret"));
        REQUIRE_THAT(body, Contains("password"));
        REQUIRE_THAT(body, Contains("resume"));
        REQUIRE_THAT(body, Contains("[pdf]"));
        REQUIRE_THAT(body, Contains("application/pdf"));
        REQUIRE_THAT(body, Contains("cv.pdf"));
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
        REQUIRE_THAT(body, Contains("source"));
        REQUIRE_THAT(body, Contains("test.happens()"));
        ServerResponseSP res = new ServerResponse(200, Headers(), Body());
        req->respond(res);
    });


    auto req = Request::Builder().uri("/")
            .form_file("source", new streamer::FileInput("t/client/form.cc"), "application/pdf", "cv.pdf")
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
        REQUIRE_THAT(body, Contains("secret"));
        REQUIRE_THAT(body, Contains("password"));
        REQUIRE_THAT(body, Contains("source"));
        REQUIRE_THAT(body, Contains("test.happens()"));
        REQUIRE_THAT(body, Contains("signature"));
        REQUIRE_THAT(body, Contains("Darth Vader"));
        ServerResponseSP res = new ServerResponse(200, Headers(), Body());
        req->respond(res);
    });

    auto req = Request::Builder().uri("/")
            .form_field("password", "secret")
            .form_file("source", new streamer::FileInput("t/client/form.cc"), "application/pdf", "cv.pdf")
            .form_field("signature", "Darth Vader")
            .build();
    auto res = p.client->get_response(req);
    CHECK(res->code == 200);
}

TEST("form file streaming error") {
    AsyncTest test(1000, 1);
    ClientPair p(test.loop);

    auto req = Request::Builder().uri("/")
            .form_file("source", new streamer::FileInput("t/client/not-existant.zzz"), "application/pdf", "cv.pdf")
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
