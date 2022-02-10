#include "lib/test.h"
#include <chrono>
#include <panda/unievent/test/AsyncTest.h>
#include <panda/unievent/Timer.h>
#include <thread>

using namespace panda;
using namespace unievent;
using namespace test;

TEST_PREFIX("timer: ", "[timer]");

static int64_t get_time() {
    using namespace std::chrono;
    return duration_cast< milliseconds >(steady_clock::now().time_since_epoch()).count();
}

#define REQUIRE_ELAPSED(T0, EXPECTED) do { \
    auto diff = get_time() - T0;           \
    REQUIRE(diff >= EXPECTED);             \
} while(0)

#define CHECK_APPROX(val, expected, dev) CHECK(abs((long)val - (long)expected) <= dev)

TEST("static once") {
    AsyncTest test(1000, 1);
    auto t0 = get_time();
    int timeout = 30;
    auto timer = Timer::create_once(timeout, [&](auto) {
        test.happens();
        REQUIRE_ELAPSED(t0, timeout);
    }, test.loop);
    test.await(timer->event);
}

TEST("static repeat") {
    AsyncTest test(1000, 3);
    int timeout = 30;
    auto t0 = get_time();
    size_t counter = 3;
    auto timer = Timer::create(timeout, [&](auto& t) {
        test.happens();
        REQUIRE_ELAPSED(t0, timeout);
        if (--counter == 0) t->stop();
        t0 = get_time();
    }, test.loop);
    test.run();
}

TEST("event listener") {
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

TEST("due_in") {
    AsyncTest test(1000, 0);
    TimerSP t = new Timer(test.loop);
    test.loop->update_time();

    SECTION("normal") {
        t->start(10);
        CHECK_APPROX(t->due_in(), 10, 1);
        auto now = test.loop->now();
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
        test.loop->update_time();
        if (test.loop->now() - now <= 3) { // protect from insane sleep
            CHECK_APPROX(t->due_in(), 8, 1);
        }
    }
    SECTION("expired") {
        t->start(1);
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
        test.loop->update_time();
        CHECK(t->due_in() == 0);
    }
    SECTION("non armed") {
        CHECK(t->due_in() == 0);
    }
}

TEST("pause/resume") {
    AsyncTest test(1000, 0);
    TimerSP t = new Timer(test.loop);
    
    SECTION("pause") {
        t->event.add([](auto){ FAIL(); });
        t->start(1);
        test.run_nowait();
        t->pause();
        test.run();
        SUCCEED("loop inactive");
    }
    SECTION("pause inactive timer") {
        t->pause();
        test.run();
        SUCCEED("ok");
    }
    SECTION("resume") {
        test.set_expected(1);
        t->event.add([](auto){ FAIL(); });
        t->start(10);
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
        test.run_nowait();
        SECTION("normal") {
            t->pause();
        }
        SECTION("pause paused timer is no-op") {
            t->pause();
            t->pause();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(6));
        test.run_nowait();
        t->resume();
        CHECK(t->due_in() <= 5);
        t->event.remove_all();
        t->event.add([&](auto){ test.happens(); });
        std::this_thread::sleep_for(std::chrono::milliseconds(6));
        test.run_nowait();
    }
    SECTION("resume non-paused timer") {
        SECTION("active") {
            t->start(1);
            auto res = t->resume();
            REQUIRE(!res);
            CHECK(res.error() & std::errc::invalid_argument);
        }
                
        SECTION("stopped") {
            t->start(1);
            t->stop();
            auto res = t->resume();
            REQUIRE(!res);
            CHECK(res.error() & std::errc::invalid_argument);
        }
        
        SECTION("paused&stopped") {
            t->start(1);
            t->pause();
            t->stop();
            auto res = t->resume();
            REQUIRE(!res);
            CHECK(res.error() & std::errc::invalid_argument);
        }
    }
}