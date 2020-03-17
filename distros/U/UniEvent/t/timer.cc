#include <catch.hpp>
#include <chrono>
#include <panda/unievent/test/AsyncTest.h>
#include <panda/unievent/Timer.h>

using namespace panda;
using namespace unievent;
using namespace test;

static int64_t get_time() {
    using namespace std::chrono;
    return duration_cast< milliseconds >(steady_clock::now().time_since_epoch()).count();
}

#define REQUIRE_ELAPSED(T0, EXPECTED) do { \
    auto diff = get_time() - T0;           \
    REQUIRE(diff >= EXPECTED);             \
} while(0)

TEST_CASE("timer", "[timer]") {
    AsyncTest test(1000, 0);

    SECTION("static once") {
        test.set_expected(1);
        auto t0 = get_time();
        int timeout = 30;
        auto timer = Timer::once(timeout, [&](auto) {
            test.happens();
            REQUIRE_ELAPSED(t0, timeout);
        }, test.loop);
        test.await(timer->event);
    }

    SECTION("static repeat") {
        test.set_expected(3);
        int timeout = 30;
        auto t0 = get_time();
        size_t counter = 3;
        auto timer = Timer::start(timeout, [&](auto& t) {
            test.happens();
            REQUIRE_ELAPSED(t0, timeout);
            if (--counter == 0) t->stop();
            t0 = get_time();
        }, test.loop);
        test.run();
    }

    SECTION("event listener") {
        auto s = [](auto lst) {
            TimerSP h = new Timer;
            h->event_listener(&lst);
            h->event.add([&](auto){ lst.cnt += 10; });
            h->call_now();
            CHECK(lst.cnt == 11);
        };
        SECTION("std") {
            struct Lst : ITimerListener {
                int cnt = 0;
                void on_timer (const TimerSP&) override { ++cnt; }
            };
            s(Lst());
        }
        SECTION("self") {
            struct Lst : ITimerSelfListener {
                int cnt = 0;
                void on_timer () override { ++cnt; }
            };
            s(Lst());
        }
    }
}

