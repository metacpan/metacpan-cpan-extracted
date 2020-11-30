#include "logtest.h"

#define TEST(name) TEST_CASE("log: " name, "[log]")

TEST("set_level") {
    Ctx c;
    set_level(Level::VerboseDebug);
    panda_log_verbose_debug("");
    c.check_called();
    panda_log_critical("");
    c.check_called();

    set_level(Level::Debug);
    panda_log_verbose_debug("");
    REQUIRE(c.cnt == 0);
    panda_log_debug("");
    c.check_called();
}

TEST("should_log") {
    Ctx c;
    set_level(Level::Debug);
    REQUIRE_FALSE(panda_should_log(Level::VerboseDebug));
    REQUIRE(panda_should_log(Level::Debug));
    set_level(Level::Error);
    REQUIRE_FALSE(panda_should_log(Level::Debug));
    REQUIRE(panda_should_log(Level::Critical));
}

TEST("streaming params") {
    Ctx c;
    panda_log_warning("1" << "2" << "3");
    CHECK(c.str == "123");
}

TEST("code-eval logging") {
    Ctx c;
    bool val = false;

    panda_log_debug([&]{
        val = true;
    });

    REQUIRE_FALSE(val);

    panda_log_warning([&]{
        log << "text";
        val = true;
    });
    CHECK(c.str == "text");

    panda_log(Level::Error, [&]{
        log << "hello";
    });
    CHECK(c.str == "hello");

    REQUIRE(val);
}

TEST("empty log") {
    Ctx c;
    SECTION("case 1") {
        panda_log(Level::Error);
    }
    SECTION("case 2") {
        panda_log_error();
    }
    c.check_called();
    CHECK(c.str == "==> MARK <==");
}

//void test (int nthr, int cnt) {
//    struct Logger : ILogger {
//        void log (Level, const CodePoint&, const string&) override {
//            //std::time(NULL);
//        }
//    };
//
//    auto logger = [](Level, const CodePoint&, const string&){
//        //std::this_thread::sleep_for(std::chrono::microseconds(10));
//        //printf("log\n");
//    };
//    set_logger(logger);
//    set_logger(ILoggerSP(new Logger()));
//
//    std::vector<std::thread> v;
//    for (int i = 0; i < nthr; ++i) {
//        v.push_back(std::thread([](int cnt) {
//            for (int i = 0; i < cnt; ++i) {
//                panda_log_warning("");
//            }
//        }, cnt));
//    }
//
//    if (0) v.push_back(std::thread([](int cnt) {
//        for (int i = 0; i < cnt; ++i) {
//            if (i % 2 == 0) set_logger(ILoggerSP(new Logger()));
//            else            set_logger(nullptr);
//        }
//    }, cnt));
//
//    for (auto& t : v) t.join();
//}
