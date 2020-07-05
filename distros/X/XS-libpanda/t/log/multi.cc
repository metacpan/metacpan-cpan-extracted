#include "logtest.h"
#include <panda/log/multi.h>

#define TEST(name) TEST_CASE("log-multi: " name, "[log-multi]")

TEST("log to multi channels") {
    Ctx c;
    int cnt = 0;
    set_format("%m");
    set_logger(new MultiLogger({
        {
            fn2logger([&](const string& msg, const Info& info) {
                CHECK(info.level == CRITICAL);
                CHECK(info.line == 28);
                CHECK(msg == "hi");
                ++cnt;
            })
        },
        {
            fn2logger([&](const string& msg, const Info& info) {
                CHECK(info.level == CRITICAL);
                CHECK(info.line == 28);
                CHECK(msg == "hi");
                ++cnt;
            })
        }
    }));
    panda_log_critical("hi");
    CHECK(cnt == 2);
}

TEST("using min_level") {
    Ctx c;
    int cnt = 0;
    set_logger(new MultiLogger({
        { fn2logger([&](const string&, const Info&) { cnt += 1; }), NOTICE },
        { fn2logger([&](const string&, const Info&) { cnt += 100; }), ERROR },
        { fn2logger([&](const string&, const Info&) { cnt += 10; }), WARNING },
    }));
    panda_log_warning("hi");
    CHECK(cnt == 11);
}

TEST("using different formatters") {
    Ctx c;
    set_format("F1:%m");
    string m1,m2,m3;
    set_logger(new MultiLogger({
        { fn2logger([&](const string& m, const Info&) { m1=m; }), new PatternFormatter("F2:%m"), DEBUG },
        { fn2logger([&](const string& m, const Info&) { m2=m; }), new PatternFormatter("F3:%m") },
        { fn2logger([&](const string& m, const Info&) { m3=m; }) },
    }));
    panda_log_error("hi");
    CHECK(m1 == "F2:hi");
    CHECK(m2 == "F3:hi");
    CHECK(m3 == "F1:hi");
}
