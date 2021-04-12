#include "lib/test.h"

TEST_PREFIX("check: ", "[check]");

TEST("start/stop/reset") {
    AsyncTest test(5000);

    CheckSP h = new Check(test.loop);
    CHECK(h->type() == Check::TYPE);

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

TEST("runs after prepare") {
    AsyncTest test(5000, {"p", "c"});
    PrepareSP p = new Prepare(test.loop);
    CheckSP   c = new Check(test.loop);
    p->start([&](auto){ test.happens("p"); });
    c->start([&](auto){ test.happens("c"); });
    test.run_nowait();
}

TEST("call_now") {
    AsyncTest test(5000, 5);
    CheckSP h = new Check(test.loop);
    test.happens_when(h->event);
    for (int i = 0; i < 5; ++i) h->call_now();
}

TEST("event listener") {
    AsyncTest test(5000);
    auto s = [&](auto lst) {
        CheckSP h = new Check(test.loop);
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

TEST("static ctor") {
    AsyncTest test(1000, 1);
    auto h = Check::create([&](auto...){ test.happens(); }, test.loop);
    test.loop->run_nowait();
}
