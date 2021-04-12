#include "lib/test.h"

TEST_PREFIX("loop: ", "[loop]");

namespace {
    static int dcnt = 0;
    static int ccnt = 0;

    struct MyLoop : Loop {
        MyLoop  () { ++ccnt; }
        ~MyLoop () { ++dcnt; }
    };
}

TEST("basic") {
    LoopSP loop = new Loop();
    CHECK(!loop->alive());
    CHECK(!loop->is_default());
    CHECK(!loop->is_global());
}

TEST("now/update_time") {
    LoopSP loop = new Loop();
    auto now = loop->now();
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    CHECK(now == loop->now());
    loop->update_time();
    CHECK(now != loop->now());
}

TEST("default loop") {
    auto loop = Loop::default_loop();
    CHECK(!loop->alive());
    CHECK(loop->is_default());
    CHECK(loop->is_global());
    CHECK(Loop::default_loop() == loop);
    CHECK(Loop::global_loop() == loop);
}

TEST("doesn't block when no handles") {
    LoopSP loop = new Loop();
    TimeGuard a(100_ms);
    CHECK(!loop->run_once());
    CHECK(!loop->run());
    CHECK(!loop->run_nowait());
}

TEST("loop is alive while handle exists") {
    LoopSP loop = new Loop();
    PrepareSP h = new Prepare(loop);
    h->start([&](const PrepareSP&){
        CHECK(loop->alive());
        loop->stop();
    });

    time_guard(100_ms, [&]{
        CHECK(loop->run());
    });

    CHECK(loop->alive());
    h->stop();
    CHECK(!loop->alive());

    time_guard(100_ms, [&]{
        CHECK(!loop->run());
    });
}

TEST("loop is alive while handle exists 2") {
    LoopSP loop = new Loop();
    PrepareSP h = new Prepare(loop);
    h->start([&](const PrepareSP& hh){
        CHECK(loop->alive());
        hh->stop();
    });

    time_guard(100_ms, [&]{
        CHECK(!loop->run());
    });

    CHECK(!loop->alive());

    h->start();
    h = nullptr;

    time_guard(100_ms, [&]{
        CHECK(!loop->run());
    });
}

TEST("handles") {
    LoopSP loop = new Loop();
    CHECK(loop->handles().size() == 0);

    std::vector<PrepareSP> v;
    for (int i = 0; i < 3; ++i)
        v.push_back(new Prepare(loop));

    CHECK(loop->handles().size() == 3);

    for (auto h : loop->handles()) {
        CHECK(typeid(*h) == typeid(Prepare));
    }
    v.clear();

    CHECK(loop->handles().size() == 0);
}

TEST("loop is held until there are no handles") {
    dcnt = ccnt = 0;
    LoopSP loop = new MyLoop();
    PrepareSP h = new Prepare(loop);
    h->start([](const PrepareSP&){});
    loop->run_nowait();
    loop = nullptr;

    CHECK(dcnt == 0);
    CHECK(h->loop());

    h = nullptr;
    CHECK(dcnt == 1);
}

TEST("loop doesn't leak when it has internal prepare and resolver") {
    dcnt = ccnt = 0;
    LoopSP loop = new MyLoop();
    loop->delay([]{});
    loop->resolver()->resolve("localhost", [](auto...){});
    loop->run();
    loop = nullptr;
    CHECK(dcnt == 1);
}

TEST("delay") {
    LoopSP loop = new Loop();
    int n = 0;
    SECTION("simple") {
        loop->delay([&]{ n++; });
        for (int i = 0; i < 3; ++i) loop->run_nowait();
        CHECK(n == 1);
    }
    SECTION("recursive") {
        loop->delay([&]{ n++; });
        for (int i = 0; i < 3; ++i) loop->run_nowait();
        loop->delay([&]{
            n += 10;
            loop->delay([&]{ n += 100; });
        });
        for (int i = 0; i < 3; ++i) loop->run_nowait();
        CHECK(n == 111);
    }
    SECTION("doesn't block") {
        TimeGuard guard(100_ms);
        loop->delay([&]{
            n++;
            loop->delay([&]{
                n++;
                loop->delay([&]{ n++; });
            });
        });
        CHECK(!loop->run());
        CHECK(n == 3);
    }
    SECTION("events don't suppress delay") {
        TimeGuard guard(1000_ms);
        PrepareSP h = new Prepare(loop);
        h->start([&](const PrepareSP&){ n += 10; });
        loop->delay([&]{
            n++;
            loop->delay([&]{ n++; loop->stop(); });
        });
        CHECK(loop->run());
        CHECK(n == 22);
    }
}

TEST("stop before run") {
    LoopSP loop = new Loop;
    int n = 0;
    loop->delay([&]{ ++n; });
    loop->stop();
    loop->run_nowait();
    CHECK(n == 1);
}

TEST("track load average") {
    AsyncTest test(2000, 2);
    test.loop->track_load_average(1);
    auto p = make_p2p(test.loop);
    p.sconn->read_event.add([&](auto, auto, auto&) {
        test.happens();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    });
    p.sconn->eof_event.add([&](auto){
        test.happens();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        test.loop->stop();
    });
    p.client->write("epta");
    p.client->disconnect();

    auto t = Timer::create_once(1, [&](auto) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }, test.loop);

    test.run();

    CHECK(test.loop->get_load_average() > 0);
}

TEST_HIDDEN("bench_monotonic") {
    struct timespec ts;
    for (int i = 0; i < 10000000; ++i) clock_gettime(CLOCK_MONOTONIC, &ts);
}

TEST_HIDDEN("bench_realtime") {
    struct timespec ts;
    for (int i = 0; i < 10000000; ++i) clock_gettime(CLOCK_REALTIME, &ts);
}

#ifndef _WIN32
    #include <sys/types.h>
    #include <unistd.h>
    #include <stdlib.h>
    #include <sys/wait.h>

    TEST("automatic handle fork") {
        int forked = 0;
        LoopSP loop = new Loop();
        loop->fork_event.add([&forked](auto){ ++forked; });

        auto pid = fork();
        if (pid == -1) throw std::logic_error("could not fork");

        // some strange activity to check that Loop works
        size_t counter = 0;
        size_t size = 10;
        std::vector<TcpP2P> common_pairs(size);
        for (size_t i = 0; i < size; ++i) {
            common_pairs.emplace_back(make_p2p(loop));
            TcpP2P p = common_pairs.back();

            p.sconn->write("1");
            p.sconn->read_event.add([&](auto...) {
                counter++;
                if (counter == size) {
                    loop->stop();
                }
            });

            p.client->read_event.add([](auto s, auto buf, auto...) {
                s->write(buf);
            });
        }

        loop->run();

        if (!pid) exit(forked != 1);

        int wst;
        auto ret = waitpid(pid, &wst, 0);
        CHECK(ret == pid);
        CHECK(WEXITSTATUS(wst) == 0);
    }
#endif
