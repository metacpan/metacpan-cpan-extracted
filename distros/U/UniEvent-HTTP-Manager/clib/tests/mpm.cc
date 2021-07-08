#include <catch2/catch.hpp>
#include <panda/unievent/http/manager/Mpm.h>

using namespace panda;
using namespace panda::unievent::http::manager;

struct TestWorker: Worker {
    using Worker::Worker;
    using callback = function<void()>;

    callback kill_cb;
    callback term_cb;

    void fetch_state () override { }
    void terminate   () override { if (term_cb) term_cb(); }
    void kill        () override { if (kill_cb) kill_cb(); }
};

struct TestMpm: Mpm {
    using Mpm::Mpm;
    uint32_t idle_cycles = 0;

    void run () override {
        auto_stop_loop();
        Mpm::run();
    }

    WorkerPtr create_worker () override { return std::make_unique<TestWorker>(); }
    void terminate_worker(WorkerPtr& it) { worker_terminated(it.get()); }

    void auto_stop_loop() {
        idle_cycles = 5;
        idle_cycle();
    }

    void idle_cycle() {
        if (idle_cycles > 0) {
            --idle_cycles;
            loop->delay([this]{ idle_cycle(); });
        } else {
            loop->stop();
        }
    }
    bool is_state_initial()  { return state == State::initial;  }
    bool is_state_running()  { return state == State::running;  }
    bool is_state_stopping() { return state == State::stopping; }
    bool is_state_stopped()  { return state == State::stopped;  }

    auto& get_check_timer()  { return check_timer; }
    auto& get_workers()      { return workers;     }
};

TEST_CASE("mpm", "[mpm]") {
    auto loop = panda::unievent::Loop::default_loop();
    auto cfg = Mpm::Config{};
    cfg.server.locations = { {"127.0.0.1", 0} };

    SECTION("run + start-event") {
        cfg.min_servers = 2;
        TestMpm mpm(cfg, loop, loop);
        CHECK(mpm.is_state_initial());

        int started = 0;
        mpm.start_event.add([&](auto...){ ++started; });
        mpm.run();
        CHECK(mpm.is_state_running());
        CHECK(started == 1);
        auto& workers = mpm.get_workers();
        CHECK(workers.size() == 2);
    }

    SECTION("stop + worker_terminated") {
        cfg.min_servers = 2;
        TestMpm mpm(cfg, loop, loop);
        mpm.run();
        CHECK(mpm.is_state_running());

        auto& workers = mpm.get_workers();
        CHECK(workers.size() == 2);

        mpm.stop();
        while (!workers.empty()) {
            mpm.terminate_worker(workers.begin()->second);
        }
        CHECK(workers.size() == 0);
    }

    SECTION("kill inactive workers") {
        cfg.max_servers = 1;
        cfg.activity_timeout = 1;
        TestMpm mpm(cfg, loop, loop);
        mpm.run();

        bool killed = false;
        auto w = static_cast<TestWorker*>(mpm.get_workers().begin()->second.get());
        w->kill_cb = [&](){ killed = true; };
        w->activity_time = 0;
        w->state = Worker::State::running;
        mpm.get_check_timer()->call_now();

        CHECK(killed);
        CHECK(mpm.get_workers().size() > 0);
    }

    SECTION("autorestart workers") {
        cfg.max_servers = 1;
        cfg.max_requests = 1;
        TestMpm mpm(cfg, loop, loop);
        mpm.run();

        auto w = static_cast<TestWorker*>(mpm.get_workers().begin()->second.get());
        w->total_requests = 2;
        w->creation_time = 0;
        w->state = Worker::State::running;
        mpm.get_check_timer()->call_now();

        CHECK(mpm.get_workers().size() == 2);
        CHECK(w->state == Worker::State::restarting);

        SECTION("terminate_restared_workers (simple)") {
            bool terminated = false;
            w->term_cb = [&](){ terminated = true; };
            mpm.get_check_timer()->call_now();
            CHECK(terminated);
        }
    }

    SECTION("load average") {
        // to spawn: round_up(1/0.3) - 1  = 3;
        cfg.max_servers = 5;
        cfg.max_load = 0.3;
        TestMpm mpm(cfg, loop, loop);
        mpm.run();
        REQUIRE(mpm.get_workers().size() == 1);

        auto w = static_cast<TestWorker*>(mpm.get_workers().begin()->second.get());
        w->load_average = 1;

        w->state = Worker::State::running;
        mpm.get_check_timer()->call_now();

        CHECK(mpm.get_workers().size() == 4);

        int terminated = 0;
        SECTION("back to min") {
            for(auto& it: mpm.get_workers()) {
                auto w = static_cast<TestWorker*>(it.second.get());
                w->state = Worker::State::running;
                w->load_average = 0;
                w->creation_time = 0; // to terminate;
                w->term_cb = [&](){ ++terminated; };
            }
            mpm.get_check_timer()->call_now();
            CHECK(terminated == 3);
        }
    }

    SECTION("reconfigure") {
        TestMpm mpm(cfg, loop, loop);
        cfg.check_interval = 1;
        mpm.run();
        auto& workers = mpm.get_workers();
        CHECK(workers.size() == 1);

        auto w1 = static_cast<TestWorker*>(workers.begin()->second.get());
        w1->state = Worker::State::running;

        auto cfg2 = cfg;
        cfg2.check_interval = 2;
        mpm.reconfigure(cfg2);
        mpm.auto_stop_loop();
        loop->run();

        REQUIRE(workers.size() == 2);
        auto w2 = static_cast<TestWorker*>(workers.at(w1->id + 1).get());
        CHECK(w1->state == Worker::State::terminating);
        CHECK(w2->state == Worker::State::running);

        mpm.reconfigure(cfg);
        mpm.auto_stop_loop();
        loop->run();

        REQUIRE(workers.size() == 3);
        auto w3 = static_cast<TestWorker*>(workers.at(w2->id + 1).get());
        CHECK(w1->state == Worker::State::terminating);
        CHECK(w2->state == Worker::State::terminating);
        CHECK(w3->state == Worker::State::running);
    }

}
