#include "../lib/test.h"
#include <openssl/ssl.h>

#define TEST(name) TEST_CASE("client-live: " name, "[client-live]" VSSL)

#define panda_log_module panda::unievent::http::panda_log_module

TEST("get real sites") {
    std::vector<string> sites = {
        "http://google.com",
        "http://youtube.com",
        "http://facebook.com",
        "http://wikipedia.org",
        "http://yandex.ru",
        "http://ya.ru",
        "http://example.com"
    };

    AsyncTest test(5000, sites.size());

    for (auto site : sites) {
        panda_log_debug("request to: " << site);
        RequestSP req = Request::Builder()
            .uri(site)
            .response_callback([&](auto&, auto& res, auto& err) {
                panda_log_debug("GOT response " << res << ", " << res->body.length() << " bytes, err=" << err);
                test.happens();
                CHECK_FALSE(err);
                CHECK(res->code == 200);
            })
            .build();
        http_request(req, test.loop);
    }

    test.run();
}

TEST("validate host name") {
    AsyncTest test(5000, 1);
    RequestSP req = Request::Builder()
        .uri("https://a.b.c.dev.crazypanda.ru")
        .response_callback([&](auto&, auto& res, auto& err) {
            panda_log_debug("GOT response " << res << ", " << res->body.length() << " bytes, err=" << err);
            test.happens();
            CHECK(err);
        })
        .ssl_check_cert(true)
        .build();
    http_request(req, test.loop);
    test.run();
}
