#include "streamer.h"

TEST_PREFIX("streamer-basic: ", "[streamer-basic]");

TEST("normal") {
    AsyncTest test(3000, 1);
    auto i = new TestInput(20, 1);
    auto o = new TestOutput(2);
    StreamerSP s = new Streamer(i, o, 5, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        CHECK(!err);
        test.happens();
    });
    test.run();
    CHECK(i->stop_reading_cnt == 0);
    CHECK(o->bufs.size() == 0);
}

TEST("pause input") {
    AsyncTest test(3000, 1);
    auto i = new TestInput(100, 20);
    auto o = new TestOutput(1);
    StreamerSP s = new Streamer(i, o, 30, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        CHECK(!err);
        test.happens();
    });
    test.run();
    CHECK(i->stop_reading_cnt > 0);
    CHECK(o->bufs.size() == 0);
}

TEST("no limit") {
    AsyncTest test(3000, 1);
    auto i = new TestInput(300, 4);
    auto o = new TestOutput(2);
    StreamerSP s = new Streamer(i, o, 0, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        CHECK(!err);
        test.happens();
    });
    test.run();
    CHECK(i->stop_reading_cnt == 0);
    CHECK(o->bufs.size() == 0);
}

TEST("stop") {
    AsyncTest test(3000, 1);
    auto i = new TestInput(300, 4);
    auto o = new TestOutput(2);
    StreamerSP s = new Streamer(i, o, 0, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        CHECK(err & make_error_code(std::errc::operation_canceled));
        test.happens();
    });
    s->stop();
    test.run();
}
