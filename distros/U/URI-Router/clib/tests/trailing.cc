#include "test.h"

TEST_PREFIX("trailing: ", "[trailing]");

TEST("root") {
    Router<int> r({
        {"...", 1},
        {"/hello/world", 2},
    });

    CHECK_ROUTE("/", 1);
    CHECK_ROUTE("/a", 1);
    CHECK_ROUTE("/hello", 1);
    CHECK_ROUTE("/a/b", 1);
    CHECK_ROUTE("/hello/world", 2);
    CHECK_ROUTE("/hello/world/a", 1);
}

TEST("non-root") {
    Router<int> r({
        {"/jopa/...", 1},
        {"/hello/world", 2},
    });

    CHECK_ROUTE("/jopa/", 1);
    CHECK_ROUTE("/jopa/abc", 1);
    CHECK_ROUTE("/jopa/abc/def", 1);
    CHECK_ROUTE("/jopa/abc/def/xyz", 1);
    CHECK_ROUTE("/a", -1);
    CHECK_ROUTE("/hello/world", 2);
}

TEST("relevance") {
    Router<int> r({
        {"/my/...", 1},
        {"/my/*", 2},
        {"/my", 3},
    });
    CHECK_ROUTE("/my", 3);
    CHECK_ROUTE("/my/foo", 2);
    CHECK_ROUTE("/my/foo/bar", 1);
}

//TEST("benchmark") {
//    Router<int> r_small({
//        {"/my/path", 1},
//        {"/my/world", 2},
//    });
//
//    uint64_t res = 0;
//    for (int i = 0; i < 10000000; ++i) {
//        res += r_small.route("/my/path").value().value;
//    }
//}
