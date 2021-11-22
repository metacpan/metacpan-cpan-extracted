#include "test.h"

TEST_PREFIX("asterisk: ", "[asterisk]");

TEST("basic1") {
    Router<int> r({
        {"*", 1},
        {"/hello/world", 2},
    });

    CHECK_ROUTE("/a", 1);
    CHECK_ROUTE("/helloworld", 1);
    CHECK_ROUTE("/a/b", -1);
    CHECK_ROUTE("/hello/world", 2);
}

TEST("basic2") {
    Router<int> r({
        {"/jopa/*", 1},
        {"/hello/world", 2},
    });

    CHECK_ROUTE("/jopa/abc", 1);
    CHECK_ROUTE("/jopa/def", 1);
    CHECK_ROUTE("/a", -1);
    CHECK_ROUTE("/jopa", -1);
    CHECK_ROUTE("/hello/world", 2);
}

TEST("basic3") {
    Router<int> r({
        {"/*/jopa", 1},
        {"/hello/world", 2},
    });

    CHECK_ROUTE("/abc/jopa", 1);
    CHECK_ROUTE("/dddddd/jopa", 1);
    CHECK_ROUTE("/a", -1);
    CHECK_ROUTE("/jopa", -1);
    CHECK_ROUTE("/hello/world", 2);
}

TEST("multiple") {
    Router<int> r({
        {"/*/jopa/*/", 1},
        {"/hello/world", 2},
    });
    CHECK_ROUTE("/abc/jopa/def", 1);
    CHECK_ROUTE("/123456/jopa/7890123", 1);
    CHECK_ROUTE("/a/jop/b", -1);
    CHECK_ROUTE("/a/jopa", -1);
    CHECK_ROUTE("/jopa/a", -1);
    CHECK_ROUTE("/hello/world", 2);
}

TEST("relevance") {
    Router<int> r({
        {"/*/*/view", 1},
        {"/*/user/*", 2},
        {"/*/a/b/c/d/e/f/g/h", 3},
        {"0/*/*/*/*/*/*/*/*", 4},
        {"/my/user/view", 5},
    });
    CHECK_ROUTE("/xx/epta/view", 1);
    CHECK_ROUTE("/xx/user/epta", 2);
    CHECK_ROUTE("/xx/user/view", 2);
    CHECK_ROUTE("/my/user/view", 5);

    CHECK_ROUTE("/00/a/b/c/d/e/f/g/h", 3);
    CHECK_ROUTE("/0/aa/b/c/d/e/f/g/h", 4);
    CHECK_ROUTE("/0/a/b/c/d/e/f/g/h", 4);
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
