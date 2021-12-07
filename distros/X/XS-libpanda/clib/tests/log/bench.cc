//#define CATCH_CONFIG_ENABLE_BENCHMARKING
#include "logtest.h"
#include <thread>

#define TEST(name) TEST_CASE("bench: " name, "[bench]")

//TEST("log") {
//    auto logger = [](const string&, const Info&){};
//    set_logger(logger);
//
//    BENCHMARK("enabled") {
//        panda_log_error("epta");
//    };
//    BENCHMARK("disabled") {
//        panda_log_debug("epta");
//    };
//}

TEST_CASE("thread-safe test", "[.]") {
    int nthr = 0, cnt = 0;
    auto nthr_str = getenv("NTHR");
    if (nthr_str) nthr = atoi(nthr_str);
    auto cnt_str = getenv("CNT");
    if (cnt_str) cnt = atoi(cnt_str);
    if (!nthr) nthr = 8;
    if (!cnt) cnt = 1000000;

    struct Logger : ILogger {
        void log (const string&, const Info&) override {
            //std::time(NULL);
        }
    };

    auto logger = [](const string&, const Info&){
        //std::this_thread::sleep_for(std::chrono::microseconds(10));
        //printf("log\n");
    };
    set_logger(logger);
    set_logger(ILoggerSP(new Logger()));

    std::vector<std::thread> v;
    for (int i = 0; i < nthr; ++i) {
        v.push_back(std::thread([](int cnt) {
            for (int i = 0; i < cnt; ++i) {
                panda_log_warning("");
            }
        }, cnt));
    }

    if (1) v.push_back(std::thread([](int cnt) {
        for (int i = 0; i < cnt; ++i) {
            if (i % 2 == 0) set_logger(ILoggerSP(new Logger()));
            else            set_logger(nullptr);
        }
    }, cnt));

    for (auto& t : v) t.join();
}
