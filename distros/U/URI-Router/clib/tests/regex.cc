#include "test.h"

TEST_PREFIX("regex: ", "[regex]");

TEST("basic") {
    Router<int> r({
        {Regex("/user/\\d+"), 1},
        {Regex("/user/\\d+a?"), 2},
    });

    CHECK_ROUTE("/user/1", 1);
    CHECK_ROUTE("/user/1111", 1);
    CHECK_ROUTE("/user", -1);
    CHECK_ROUTE("/user/", -1);
    CHECK_ROUTE("/user/a", -1);
    CHECK_ROUTE("/user/123a", 2);
    CHECK_ROUTE("/user/123/a", -1);
}

TEST("trailing-slash-indifferent") {
    Router<int> r({
        {Regex("/user/\\d+"), 1},
    });
    CHECK_ROUTE("/user/1", 1);
    CHECK_ROUTE("/user/1/", 1);
    CHECK_ROUTE("/user/1////", 1);
}

TEST("relevance") {
    // regex must be the least relevant
    Router<int> r({
        {Regex("/foo/bar.*"), 10},
        {"/foo/bar/...", 20},
        {"/foo/bar/*", 30},
        {"/foo/bar/baz", 40},
    });
    CHECK_ROUTE("/foo", -1);
    CHECK_ROUTE("/foo/bar", 20);
    CHECK_ROUTE("/foo/bar/abc", 30);
    CHECK_ROUTE("/foo/bar/abc/def", 20);
    CHECK_ROUTE("/foo/barabc/def", 10);
}

//TEST("benchmark") {
//    Router<int> r_small({
//        {Regex("/user/\\d+"), 1},
//        {Regex("/user/\\d+a?"), 2},
//    });
//
//    uint64_t res = 0;
//    for (int i = 0; i < 1000000; ++i) {
//        res += r_small.route("/user/1111").value().value;
//    }
//}
