#include "lib/test.h"

TEST_PREFIX("async: ", "[async]");

struct TestAsync : AsyncTest {
    AsyncSP async;

    TestAsync (int tmt, int nhappens = 0) : AsyncTest(tmt, nhappens) {
        async = new Async([this](auto) {
            happens();
            loop->stop();
        }, loop);
    }
};

TEST("send from this thread") {
    TestAsync test(2000, 1);
    SECTION("after run") {
        test.loop->delay([&]{
            test.async->send();
        });
    }
    SECTION("before run") {
        test.async->send();
    }
    test.run();
}

TEST("send from another thread") {
    TestAsync test(2000, 1);
    std::thread t;
    SECTION("after run") {
        t = std::thread([](Async* h) {
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
            h->send();
        }, test.async.get());
        test.run();
    }
    SECTION("before run") {
        t = std::thread([](Async* h) {
            h->send();
        }, test.async.get());
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
        test.run();
    }
    t.join();
}

TEST("call_now") {
    TestAsync test(2000, 1);
    test.async->call_now();
}

TEST("event listener") {
    TestAsync test(2000, 1);

    auto s = [&](auto lst) {
        test.async->event_listener(&lst);
        test.async->event.add([&](auto){ lst.cnt += 10; });
        test.async->send();
        test.run();
        CHECK(lst.cnt == 11);
    };

    SECTION("std") {
        struct Lst : IAsyncListener {
            int cnt = 0;
            void on_async (const AsyncSP&) override { ++cnt; }
        };
        s(Lst());
    }
    SECTION("self") {
        struct Lst : IAsyncSelfListener {
            int cnt = 0;
            void on_async () override { ++cnt; }
        };
        s(Lst());
    }
}
