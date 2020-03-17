#include "lib/test.h"

TEST_CASE("check", "[check]") {
    auto l = Loop::default_loop();
    AsyncTest test(5000, {}, l);
    int cnt = 0;

    SECTION("start/stop/reset") {
        CheckSP h = new Check;
        CHECK(h->type() == Check::TYPE);

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

    SECTION("runs after prepare") {
        PrepareSP p = new Prepare;
        p->start([&](auto){ cnt++; });
        CheckSP c = new Check;
        c->start([&](auto) {
            CHECK(cnt == 1);
            cnt += 10;
        });
        l->run_nowait();
        CHECK(cnt == 11);
    }

    SECTION("call_now") {
        CheckSP h = new Check;
        h->event.add([&](auto){ cnt++; });
        for (int i = 0; i < 5; ++i) h->call_now();
        CHECK(cnt == 5);
    };

    SECTION("event listener") {
        auto s = [](auto lst) {
            CheckSP h = new Check;
            h->event_listener(&lst);
            h->event.add([&](auto){ lst.cnt += 10; });
            h->call_now();
            CHECK(lst.cnt == 11);
        };
        SECTION("std") {
            struct Lst : ICheckListener {
                int cnt = 0;
                void on_check (const CheckSP&) override { ++cnt; }
            };
            s(Lst());
        }
        SECTION("self") {
            struct Lst : ICheckSelfListener {
                int cnt = 0;
                void on_check () override { ++cnt; }
            };
            s(Lst());
        }
    }
}
