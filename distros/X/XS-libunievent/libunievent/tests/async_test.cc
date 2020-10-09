#include "lib/test.h"

TEST_CASE("async_test simple", "[async_test]") {
    bool called = false;
    AsyncTest test(200, {"timer"});

    auto timer = test.timer_once(10, [&]() {
        called = true;
    });
    auto res = test.await(timer->event, "timer");
    REQUIRE(called);
    REQUIRE(std::get<0>(res) == timer.get());
}

TEST_CASE("async_test dispatcher", "[async_test]") {
    bool called = false;
    AsyncTest test(200, {"dispatched"});

    CallbackDispatcher<void(int)> d;
    auto timer1 = test.timer_once(10, [&]() {
        called = true;
        d(10);
    });

    auto res = test.await(d, "dispatched");
    REQUIRE(called);
    REQUIRE(std::get<0>(res) == 10);
}


TEST_CASE("async_test multi", "[async_test]") {
    int called = 0;
    AsyncTest test(200, {});

    CallbackDispatcher<void(void)> d1;
    auto timer1 = test.timer_once(10, [&]() {
        called++;
        d1();
    });
    CallbackDispatcher<void(void)> d2;
    auto timer2 = test.timer_once(20, [&]() {
        called++;
        d2();
    });

    test.await_multi(d2, d1);
    REQUIRE(called == 2);
}

TEST_CASE("async_test delay", "[async_test]") {
    AsyncTest test(200, {"call"});
    size_t count = 0;
    test.loop->delay([&]() {
        count++;
        if (count >= 2) FAIL("called twice");
        test.happens("call");
        test.loop->stop();
    });
    TimerSP timer = Timer::once(50, [&](Timer*){
        test.loop->stop();
    }, test.loop);
    test.run();
    REQUIRE(count == 1);
}
