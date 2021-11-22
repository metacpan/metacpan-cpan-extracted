#include "test.h"

TEST_PREFIX("captures: ", "[captures]");

#define CHECK_CAPT(path, val, ...) do {             \
    Captures capts = {__VA_ARGS__};                 \
    auto res = r.route(path);                       \
    if (val == -1) CHECK_FALSE(res);                \
    else {                                          \
        REQUIRE(res);                               \
        CHECK(res.value().value == val);            \
        CHECK(res.value().captures == capts);       \
    }                                               \
} while (0)

TEST("static") {
    Router<int> r({
        {"/foo/*", 1},
        {"/foo/bar", 2},
        {"/bar", 3},
    });

    CHECK_CAPT("/foo/bar", 2);
    CHECK_CAPT("/bar", 3);
}

TEST("asterisk") {
    Router<int> r({
        {"/foo/*", 1},
        {"/foo/bar/*", 2},
        {"*/xyz/*", 3},
    });

    CHECK_CAPT("/foo/bar", 1, "bar");
    CHECK_CAPT("/foo/bar/baz", 2, "baz");
    CHECK_CAPT("/abc/xyz/def", 3, "abc", "def");
}

TEST("double asterisk") {
    Router<int> r({
        {"/foo/*", 1},
        {"/foo/...", 2},
        {"*/xyz/...", 3},
    });

    CHECK_CAPT("/foo/bar", 1, "bar");
    CHECK_CAPT("/foo/bar/", 1, "bar");
    CHECK_CAPT("/foo/bar/baz", 2, "bar", "baz");
    CHECK_CAPT("/abc/xyz/def", 3, "abc", "def");
    CHECK_CAPT("/abc/xyz/def/789", 3, "abc", "def", "789");
    CHECK_CAPT("////abc////xyz////def////789", 3, "abc", "def", "789");
}

TEST("regex") {
    Router<int> r({
        {Regex("/foo/(.+)"), 1},
        {Regex("/bar/(?:[^/]+)/(.+)"), 2},
    });

    CHECK_CAPT("/foo/bar", 1, "bar");
    CHECK_CAPT("/foo/bar/", 1, "bar");
    CHECK_CAPT("/bar/baz/foo", 2, "foo");
    CHECK_CAPT("/bar/baz/foo/hello", 2, "foo/hello");
    CHECK_CAPT("/bar/baz/foo/hello/", 2, "foo/hello");
}
