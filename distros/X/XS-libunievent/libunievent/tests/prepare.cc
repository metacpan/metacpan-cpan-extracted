#include "lib/test.h"

TEST_CASE("prepare", "[prepare]") {
    auto l = Loop::default_loop();
    AsyncTest test(1000, {}, l);
    int cnt = 0;

    SECTION("start/stop/reset") {
        PrepareSP h = new Prepare;
        CHECK(h->type() == Prepare::TYPE);

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

    SECTION("call_now") {
        PrepareSP h = new Prepare;
        h->event.add([&](auto){ cnt++; });
        for (int i = 0; i < 5; ++i) h->call_now();
        CHECK(cnt == 5);
    };

    SECTION("exception safety") {
        PrepareSP h = new Prepare;
        h->event.add([&](auto){ cnt++; if (cnt == 1) throw 10; });
        h->start();
        try {
            l->run_nowait();
        }
        catch (int err) {
            CHECK(err == 10);
            cnt++;
        }
        CHECK(cnt == 2);

        l->run_nowait();
        CHECK(cnt == 3);
    }

    SECTION("event listener") {
        auto s = [](auto lst) {
            PrepareSP h = new Prepare;
            h->event_listener(&lst);
            h->event.add([&](auto){ lst.cnt += 10; });
            h->call_now();
            CHECK(lst.cnt == 11);
        };
        SECTION("std") {
            struct Lst : IPrepareListener {
                int cnt = 0;
                void on_prepare (const PrepareSP&) override { ++cnt; }
            };
            s(Lst());
        }
        SECTION("self") {
            struct Lst : IPrepareSelfListener {
                int cnt = 0;
                void on_prepare () override { ++cnt; }
            };
            s(Lst());
        }
    }
}
