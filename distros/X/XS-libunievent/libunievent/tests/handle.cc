#include "lib/test.h"

TEST_CASE("handle", "[handle]") {
    LoopSP l = new Loop;

    SECTION("loop") {
        TimerSP t = new Timer(l);
        CHECK(t->loop() == l);
        l = Loop::default_loop();
        t = new Timer;
        CHECK(t->loop()->is_default());
    };

    SECTION("type") {
        TimerSP t = new Timer;
        CHECK(t->type() == Timer::TYPE);
    };

    SECTION("active") {
        TimerSP t = new Timer(l);
        t->event.add([](const TimerSP& t){ t->stop(); });
        CHECK(!t->active());
        t->start(10);
        CHECK(t->active());
        l->run(); // timer stops himself on callback
        CHECK(!t->active());
    };

    SECTION("weak") {
        PrepareSP h = new Prepare(l);
        int cnt = 0;
        h->event.add([&](const PrepareSP& h){
            h->loop()->stop();
            ++cnt;
        });
        CHECK(!h->weak());
        h->start();
        l->run();
        CHECK(cnt == 1); // non-weak handle doesn't allow loop to bail out

        h->weak(1);
        CHECK(h->weak());
        h->start();
        l->run();
        CHECK(cnt == 1); // loop without any non-weak handles, bails out immediately
    };
}
