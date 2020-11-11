#include "streamer.h"
#include <panda/unievent/streamer/File.h>
#include <panda/unievent/streamer/Stream.h>

#define TEST(name) TEST_CASE("streamer-stream: " name, "[streamer-stream]")

using namespace panda::unievent::streamer;

namespace {
    struct TestStreamInput : StreamInput {
        using StreamInput::StreamInput;

        int stop_reading_cnt = 0;

        void stop_reading () override {
            stop_reading_cnt++;
            StreamInput::stop_reading();
        }
    };

    TcpP2P make_pair (const LoopSP& loop, size_t amount, size_t count) {
        auto p = make_p2p(loop);
        int cnt = 0;
        TimerSP t = new Timer(loop);
        t->event.add([=](auto...) mutable {
            p.client->write(string(amount, 'x'));
            if (++cnt == count) {
                t.reset();
                p.client->disconnect();
            }
        });
        t->start(1);
        return p;
    }
}

TEST("normal input") {
    AsyncTest test(3000, 1);
    auto p = make_pair(test.loop, 10, 10);
    auto i = new TestStreamInput(p.sconn);
    auto o = new TestOutput(20000);
    StreamerSP s = new Streamer(i, o, 100000, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        if (err) WARN(err);
        CHECK(!err);
        test.happens();
        test.loop->stop();
    });
    test.run();
    CHECK(i->stop_reading_cnt == 0);
}

TEST("pause input") {
    AsyncTest test(3000, 1);
    auto p = make_pair(test.loop, 1000, 20);
    auto i = new TestStreamInput(p.sconn);
    auto o = new TestOutput(400);
    StreamerSP s = new Streamer(i, o, 3000, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        if (err) WARN(err);
        CHECK(!err);
        test.happens();
        test.loop->stop();
    });
    test.run();
    CHECK(i->stop_reading_cnt > 0);
}

TEST("normal output") {
    AsyncTest test(3000, 2);
    auto p2 = make_p2p(test.loop);
    auto p1 = make_pair(test.loop, 10000, 20);
    auto i = new TestStreamInput(p1.sconn);
    auto o = new StreamOutput(p2.sconn);
    StreamerSP s = new Streamer(i, o, 50000, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        if (err) WARN(err);
        CHECK(!err);
        test.happens();
        p2.sconn->disconnect();
    });

    string res;
    p2.client->read_event.add([&](auto&, const string& data, auto...) {
        res += data;
    });
    p2.client->eof_event.add([&](auto...){
        test.happens();
        test.loop->stop();
    });
    test.run();

    CHECK((res == string(200000, 'x')));
}

TEST("file in stream out with busy buffer") {
    AsyncTest test(3000, 1);
    auto p = make_p2p(test.loop);
    string file = "tests/streamer/file.txt";
    auto i = new FileInput(file, 10000);
    auto o = new StreamOutput(p.sconn);
    StreamerSP s = new Streamer(i, o, 100000, test.loop);

    s->start();

    int count = 0;
    p.client->read_event.add([&count](auto&, auto& data, auto& err) {
        if (err) throw err;
        count += data.length();
    });

    p.client->eof_event.add([&](auto&) {
        test.loop->stop();
    });

    s->finish_event.add([&](auto& err) {
        CHECK(!err);
        test.happens();
        p.sconn->disconnect();
    });

    string ku = "ku-ku";
    p.sconn->write(ku);

    test.run();

    auto res = Fs::stat(file).value();
    CHECK(count == res.size + ku.length());
}
