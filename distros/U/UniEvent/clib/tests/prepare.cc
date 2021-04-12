#include "lib/test.h"

TEST_PREFIX("prepare: ", "[prepare]");

TEST("start/stop/reset") {
    AsyncTest test(1000);
    PrepareSP h = new Prepare(test.loop);
    CHECK(h->type() == Prepare::TYPE);

    test.count_events(h->event);
    h->start();
    CHECK(test.run_nowait());
    CHECK(test.counter == 1);

    h->stop();
    CHECK(!test.run_nowait());
    CHECK(test.counter == 1);

    h->start();
    CHECK(test.run_nowait());
    CHECK(test.counter == 2);

    h->reset();
    CHECK(!test.run_nowait());
    CHECK(test.counter == 2);
}

TEST("call_now") {
    AsyncTest test(1000, 5);
    PrepareSP h = new Prepare(test.loop);
    test.happens_when(h->event);
    for (int i = 0; i < 5; ++i) h->call_now();
}

TEST("exception safety") {
    AsyncTest test(1000);
    PrepareSP h = new Prepare(test.loop);
    int cnt = 0;
    h->event.add([&](auto){ cnt++; if (cnt == 1) throw 10; });
    h->start();
    try {
        test.run_nowait();
    }
    catch (int err) {
        CHECK(err == 10);
        cnt++;
    }
    CHECK(cnt == 2);

    test.run_nowait();
    CHECK(cnt == 3);
}

TEST("event listener") {
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

TEST("static ctor") {
    AsyncTest test(1000, 1);
    auto h = Prepare::create([&](auto...){ test.happens(); }, test.loop);
    test.loop->run_nowait();
}
