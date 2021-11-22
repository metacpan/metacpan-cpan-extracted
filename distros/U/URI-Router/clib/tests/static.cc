#include "test.h"

TEST_PREFIX("static: ", "[static]");

TEST("basic") {
    Router<int> r({
        {"/my/path", 1},
        {"/hello/world", 2},
        {"/my/world", 3},
        {"/", 4},
    });

    CHECK_ROUTE("/my/path", 1);
    CHECK_ROUTE("/hello/world", 2);
    CHECK_ROUTE("/my/world", 3);
    CHECK_ROUTE("/", 4);
    CHECK_ROUTE("", 4);
}

TEST("slash-indifferent") {
    Router<int> r({
        {"my/path", 1},
        {"/hello/world/", 2},
        {"my/world/", 3},
    });

    CHECK_ROUTE("/my/path", 1);
    CHECK_ROUTE("/my/path/", 1);
    CHECK_ROUTE("////my////path////", 1);
    CHECK_ROUTE("/hello/world", 2);
    CHECK_ROUTE("/my/world", 3);
}

TEST("duplicates") {
    Router<int> r;
    r.add({"/my/path", 1});
    r.add({"/my/path", 2}); // overwrite
    CHECK_ROUTE("/my/path", 2);
    r.add({"/my/path/", 3});
    CHECK_ROUTE("/my/path", 3);
    r.add({"///////my/////path/////", 4});
    CHECK_ROUTE("/////////my/path", 4);
}

//TEST("benchmark") {
//    Router<int> r_small({
//        {"/my/path", 1},
//        {"/my/world", 2},
//        {"/interstitial/track", 3},
//    });
//
//    for (int i = 0; i < 20; ++i) {
//        r_small.add({panda::to_string(i) + "epta/dsfdasfds/dasfasd", i});
//    }
//
//    uint64_t res = 0;
//    for (int i = 0; i < 10000000; ++i) {
//        res += r_small.route("/interstitial/track").value().value;
//    }
//}
