#include "test.h"

TEST_PREFIX("methods: ", "[methods]");

#define CHECK_MROUTE(meth, path, val) do {                  \
    if (val == -1) CHECK_FALSE(r.route(path, meth));        \
    else {                                                  \
        REQUIRE(r.route(path, meth));                       \
        CHECK(r.route(path, meth).value().value == val);    \
    }                                                       \
} while (0)

static const std::vector<Method> methods = {
    Method::Options, Method::Get, Method::Head, Method::Post, Method::Put, Method::Delete, Method::Trace, Method::Connect
};

TEST("basic") {
    Router<int> r({
        {Method::Get, "path", 1},
        {Method::Unspecified, "path2", 2},
        {"path3", 3},
    });

    for (auto meth : methods) {
        if (meth == Method::Get) CHECK_MROUTE(meth, "/path", 1);
        else                     CHECK_MROUTE(meth, "/path", -1);
    }

    for (auto meth : methods) {
        CHECK_MROUTE(meth, "/path2", 2);
        CHECK_MROUTE(meth, "/path3", 3);
    }
}

TEST("different methods for single path") {
    Router<int> r({
        {Method::Get, "path", 1},
        {Method::Post, "path", 2},
        {Method::Put, "path", 3},
    });

    CHECK_MROUTE(Method::Get, "/path", 1);
    CHECK_MROUTE(Method::Post, "/path", 2);
    CHECK_MROUTE(Method::Put, "/path", 3);
    CHECK_MROUTE(Method::Head, "/path", -1);
}

TEST("do not fallback to less relevant path if method is not supported in the best path") {
    Router<int> r({
        {Method::Get, "/foo", 1},
        {"/*", 2},

        {Method::Get, "/bar/*", 3},
        {"/bar/..", 4},

        {Method::Get, "/baz/...", 5},
        {Regex("/baz/bar"), 6},

        {Method::Get, Regex("/hello/world"), 7},
        {Regex("/hello/world.*"), 8},
    });

    CHECK_MROUTE(Method::Get, "/foo", 1);
    CHECK_MROUTE(Method::Post, "/foo", -1);

    CHECK_MROUTE(Method::Get, "/bar/hello", 3);
    CHECK_MROUTE(Method::Post, "/bar/hello", -1);

    CHECK_MROUTE(Method::Get, "/baz/bar", 5);
    CHECK_MROUTE(Method::Post, "/baz/bar", -1);

    CHECK_MROUTE(Method::Get, "/hello/world", 7);
    CHECK_MROUTE(Method::Post, "/hello/world", -1);
}

TEST("method configure in path") {
    Router<int> r({
        {"OPTIONS/path1", 11},
        {"GET/path2",     22},
        {"HEAD/path3",    33},
        {"POST/path4",    44},
        {"PUT/path5",     55},
        {"DELETE/path6",  66},
        {"TRACE/path7",   77},
        {"CONNECT/path8", 88},
    });

    CHECK_MROUTE(Method::Options, "/path1", 11);
    CHECK_MROUTE(Method::Get, "/path1", -1);

    CHECK_MROUTE(Method::Get, "/path2", 22);
    CHECK_MROUTE(Method::Head, "/path2", -1);

    CHECK_MROUTE(Method::Head, "/path3", 33);
    CHECK_MROUTE(Method::Post, "/path3", -1);

    CHECK_MROUTE(Method::Post, "/path4", 44);
    CHECK_MROUTE(Method::Put, "/path4", -1);

    CHECK_MROUTE(Method::Put, "/path5", 55);
    CHECK_MROUTE(Method::Delete, "/path5", -1);

    CHECK_MROUTE(Method::Delete, "/path6", 66);
    CHECK_MROUTE(Method::Trace, "/path6", -1);

    CHECK_MROUTE(Method::Trace, "/path7", 77);
    CHECK_MROUTE(Method::Connect, "/path7", -1);

    CHECK_MROUTE(Method::Connect, "/path8", 88);
    CHECK_MROUTE(Method::Options, "/path8", -1);
}
