#include "catch2/catch_test_macros.hpp"
#include "panda/uri/URI.h"
#include "test.h"

TEST_CASE("synosis", "[.]") {
    URISP u = new URI("http://mysite.com:8080/my/path?a=b&c=d#myhash");
    CHECK(u->scheme() == "http");
    CHECK(u->host() == "mysite.com");
    CHECK(u->port() == 8080);
    CHECK(u->path() == "/my/path");
    CHECK(u->query_string() == "a=b&c=d");
    CHECK(u->fragment() == "myhash");

    URISP v = new URI(*u); // clone
    v->port(443);
    CHECK(v->port() == 443);

    v->fragment("any_else");
    CHECK(v->fragment() == "any_else");

    CHECK(v->to_string() == "http://mysite.com:443/my/path?a=b&c=d#any_else");
}