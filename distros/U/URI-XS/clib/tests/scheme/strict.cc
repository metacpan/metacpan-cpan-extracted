#include "../test.h"

#define TEST(name) TEST_CASE("scheme-strict: " name, "[scheme-strict]")

TEST("no class") {
    auto uri = URI::create("lalala");
    CHECK_TYPE(uri, URI);

    uri = URI::create("//crazypanda.ru/abc");
    CHECK_TYPE(uri, URI);
}

TEST("same scheme assignable") {
    auto uri = URI::create("http://a.b");
    CHECK_TYPE(uri, URI::http);
    *uri = "http://b.c/d";
    CHECK(uri->host() == "b.c");
    CHECK(uri->path() == "/d");
    CHECK_NOTHROW(uri->scheme("http"));
}

TEST("wrong scheme") {
    auto uri = URI::create("http://ru.ru");
    CHECK_THROWS_AS(*uri = "ftp://ru.ru", WrongScheme);
    CHECK_THROWS_AS(uri->scheme("ftp"), WrongScheme);
}

TEST("copy assign (set)") {
    auto uri = URI::create("http://a.b");
    *uri = URI::http("http://c.d");
    CHECK(uri->host() == "c.d");
    *uri = URI("https://e.f");
    CHECK(uri->host() == "e.f");
    CHECK_THROWS_AS(*uri = URI::ftp("ftp://e.f"), WrongScheme);
}

TEST("create strict class") {
    URI::http uri("http://ya.ru");
    CHECK_THROWS_AS(URI::http("ftp://syber.ru"), WrongScheme);
}

TEST("apply strict scheme to proto-relative urls") {
    {
        URI::http uri("//syber.ru");
        CHECK(uri.to_string() == "http://syber.ru");
    }
    {
        URI::https uri("//syber.ru");
        CHECK(uri.to_string() == "https://syber.ru");
    }
    {
        URI::ftp uri("syber.ru/abc", URI::Flags::allow_suffix_reference);
        CHECK(uri.to_string() == "ftp://syber.ru/abc");
    }
}
