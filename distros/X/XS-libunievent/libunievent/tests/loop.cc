#include "lib/test.h"

namespace {
    static int dcnt = 0;
    static int ccnt = 0;

    struct MyLoop : Loop {
        MyLoop  () { ++ccnt; }
        ~MyLoop () { ++dcnt; }
    };
}

TEST_CASE("loop", "[loop]") {
    LoopSP loop;
    PrepareSP h;
    dcnt = ccnt = 0;

    SECTION("basic") {
        loop = new Loop();
        CHECK(!loop->alive());
        CHECK(!loop->is_default());
        CHECK(!loop->is_global());
    }

    SECTION("now/update_time") {
        loop = new Loop();
        auto now = loop->now();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        CHECK(now == loop->now());
        loop->update_time();
        CHECK(now != loop->now());
    }

    loop = Loop::default_loop();

    SECTION("default loop") {
        CHECK(!loop->alive());
        CHECK(loop->is_default());
        CHECK(loop->is_global());
        CHECK(Loop::default_loop() == loop);
        CHECK(Loop::global_loop() == loop);
    }

    SECTION("doesn't block when no handles") {
        TimeGuard a(100_ms);
        CHECK(!loop->run_once());
        CHECK(!loop->run());
        CHECK(!loop->run_nowait());
    }

    SECTION("loop is alive while handle exists") {
        h = new Prepare;
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

    SECTION("loop is alive while handle exists 2") {
        h = new Prepare;
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
    };

    SECTION("handles") {
        loop = new Loop();
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
    };

    SECTION("loop is held until there are no handles") {
        loop = new MyLoop();
        h = new Prepare(loop);
        h->start([](const PrepareSP&){});
        loop->run_nowait();
        loop = nullptr;

        CHECK(dcnt == 0);
        CHECK(h->loop());

        h = nullptr;
        CHECK(dcnt == 1);
    }

    SECTION("loop doesn't leak when it has internal prepare and resolver") {
        loop = new MyLoop();
        loop->delay([]{});
        loop->resolver()->resolve("localhost", [](auto...){});
        loop->run();
        loop = nullptr;
        CHECK(dcnt == 1);
    }

    SECTION("delay") {
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
        SECTION("events dont supress delay") {
            TimeGuard guard(1000_ms);
            PrepareSP h = new Prepare;
            h->start([&](const PrepareSP&){ n += 10; });
            loop->delay([&]{
                n++;
                loop->delay([&]{ n++; loop->stop(); });
            });
            CHECK(loop->run());
            CHECK(n == 22);
        }
    }

    SECTION("stop before run") {
        loop = new Loop;
        int n = 0;
        loop->delay([&]{ ++n; });
        loop->stop();
        loop->run_nowait();
        CHECK(n == 1);
        loop = nullptr;
    }

    if (ccnt != dcnt) CHECK(ccnt == dcnt);
}

#ifndef _WIN32
    #include <sys/types.h>
    #include <unistd.h>
    #include <stdlib.h>
    #include <sys/wait.h>

    TEST_CASE("automatic handle fork", "[loop]") {
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
