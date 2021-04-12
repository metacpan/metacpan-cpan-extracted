#include "lib/test.h"

TEST_PREFIX("idle: ", "[idle]");

TEST("start/stop/reset") {
    AsyncTest test(3000);
    IdleSP h = new Idle(test.loop);
    CHECK(h->type() == Idle::TYPE);

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

TEST("runs rarely when loop is high loaded") {
    AsyncTest test(3000);
    TimerSP t = new Timer(test.loop);
    t->event.add([](auto& t){
        static int j = 0;
        if (++j % 10 == 0) t->loop()->stop();
    });
    t->start(1);

    IdleSP h = new Idle(test.loop);
    test.count_events(h->event);
    h->start();
    test.run();

    auto low_loaded_cnt = test.counter;
    test.counter = 0;

    std::vector<TimerSP> v;
    while (v.size() < 10000) {
        v.push_back(new Timer(test.loop));
        v.back()->event.add([](auto){});
        v.back()->start(1);
    }

    test.run();
    CHECK(test.counter < low_loaded_cnt); // runs rarely

    auto high_loaded_cnt = test.counter;
    test.counter = 0;
    v.clear();
    test.run();
    CHECK(test.counter > high_loaded_cnt); // runs often again
}

TEST("call_now") {
    AsyncTest test(3000, 5);
    IdleSP h = new Idle(test.loop);
    test.happens_when(h->event);
    for (int i = 0; i < 5; ++i) h->call_now();
}

TEST("event listener") {
    AsyncTest test(3000);
    auto s = [&](auto lst) {
        IdleSP h = new Idle(test.loop);
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

TEST("static ctor") {
    AsyncTest test(1000, 1);
    auto h = Idle::create([&](auto...){ test.happens(); }, test.loop);
    test.loop->run_nowait();
}
