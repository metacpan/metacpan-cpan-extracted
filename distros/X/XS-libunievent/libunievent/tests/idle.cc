#include "lib/test.h"

TEST_CASE("idle", "[idle]") {
    auto l = Loop::default_loop();
    AsyncTest test(3000, {}, l);
    int cnt = 0;

    SECTION("start/stop/reset") {
        IdleSP h = new Idle;
        CHECK(h->type() == Idle::TYPE);

        h->event.add([&](auto){ cnt++; });
        h->start();
        CHECK(l->run_nowait());
        CHECK(cnt == 1);

        h->stop();
        CHECK(!l->run_nowait());
        CHECK(cnt == 1);

        h->start();
        CHECK(l->run_nowait());
        CHECK(cnt == 2);

        h->reset();
        CHECK(!l->run_nowait());
        CHECK(cnt == 2);
    }

    SECTION("runs rarely when loop is high loaded") {
        TimerSP t = new Timer;
        t->event.add([](auto& t){
            static int j = 0;
            if (++j % 10 == 0) t->loop()->stop();
        });
        t->start(1);

        int cnt = 0;
        IdleSP h = new Idle;
        h->start([&](auto) { cnt++; });
        l->run();

        int low_loaded_cnt = cnt;
        cnt = 0;

        std::vector<TimerSP> v;
        while (v.size() < 10000) {
            v.push_back(new Timer);
            v.back()->event.add([](auto){});
            v.back()->start(1);
        }

        l->run();
        CHECK(cnt < low_loaded_cnt); // runs rarely

        int high_loaded_cnt = cnt;
        cnt = 0;
        v.clear();
        l->run();
        CHECK(cnt > high_loaded_cnt); // runs often again
    }

    SECTION("call_now") {
        IdleSP h = new Idle;
        h->event.add([&](auto){ cnt++; });
        for (int i = 0; i < 5; ++i) h->call_now();
        CHECK(cnt == 5);
    }

    SECTION("event listener") {
        auto s = [](auto lst) {
            IdleSP h = new Idle;
            h->event_listener(&lst);
            h->event.add([&](auto){ lst.cnt += 10; });
            h->call_now();
            CHECK(lst.cnt == 11);
        };
        SECTION("std") {
            struct Lst : IIdleListener {
                int cnt = 0;
                void on_idle (const IdleSP&) override { ++cnt; }
            };
            s(Lst());
        }
        SECTION("self") {
            struct Lst : IIdleSelfListener {
                int cnt = 0;
                void on_idle () override { ++cnt; }
            };
            s(Lst());
        }
    }
}
