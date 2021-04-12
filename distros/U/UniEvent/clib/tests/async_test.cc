#include "lib/test.h"

TEST_PREFIX("async_test: ", "[async_test]");

TEST("simple") {
    bool called = false;
    AsyncTest test(200, {"timer"});

    auto timer = Timer::create_once(10, [&](auto) {
        called = true;
    }, test.loop);
    auto res = test.await(timer->event, "timer");
    REQUIRE(called);
    REQUIRE(std::get<0>(res) == timer.get());
}

TEST("dispatcher") {
    bool called = false;
    AsyncTest test(200, {"dispatched"});

    CallbackDispatcher<void(int)> d;
    auto timer1 = Timer::create_once(10, [&](auto) {
        called = true;
        d(10);
    }, test.loop);

    auto res = test.await(d, "dispatched");
    REQUIRE(called);
    REQUIRE(std::get<0>(res) == 10);
}


TEST("multi") {
    int called = 0;
    AsyncTest test(200, {});

    CallbackDispatcher<void(void)> d1;
    auto timer1 = Timer::create_once(10, [&](auto) {
        called++;
        d1();
    }, test.loop);
    CallbackDispatcher<void(void)> d2;
    auto timer2 = Timer::create_once(20, [&](auto) {
        called++;
        d2();
    }, test.loop);

    test.await_multi(d2, d1);
    REQUIRE(called == 2);
}

TEST("delay") {
    AsyncTest test(200, {"call"});
    size_t count = 0;
    test.loop->delay([&]() {
        count++;
        if (count >= 2) FAIL("called twice");
        test.happens("call");
        test.loop->stop();
    });
    TimerSP timer = Timer::create_once(50, [&](auto){
        test.loop->stop();
    }, test.loop);
    test.run();
    REQUIRE(count == 1);
}
