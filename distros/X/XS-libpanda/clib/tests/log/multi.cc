#include "logtest.h"
#include <panda/log/multi.h>

#define TEST(name) TEST_CASE("log-multi: " name, "[log-multi]")

TEST("log to multi channels") {
    Ctx c;
    int cnt = 0;
    set_formatter("%m");
    set_logger(new MultiLogger({
        {
            [&](const string& msg, const Info& info) {
                CHECK(info.level == Level::Critical);
                CHECK(info.line == 28);
                CHECK(msg == "hi");
                ++cnt;
            }
        },
        {
            [&](const string& msg, const Info& info) {
                CHECK(info.level == Level::Critical);
                CHECK(info.line == 28);
                CHECK(msg == "hi");
                ++cnt;
            }
        }
    }));
    panda_log_critical("hi");
    CHECK(cnt == 2);
}

TEST("using min_level") {
    Ctx c;
    int cnt = 0;
    set_logger(new MultiLogger({
        { [&](const string&, const Info&) { cnt += 1; }, Level::Notice },
        { [&](const string&, const Info&) { cnt += 100; }, Level::Error },
        { [&](const string&, const Info&) { cnt += 10; }, Level::Warning },
    }));
    panda_log_warning("hi");
    CHECK(cnt == 11);
}

TEST("using different formatters") {
    Ctx c;
    set_formatter("F1:%m");
    string m1,m2,m3;
    set_logger(new MultiLogger({
        { [&](const string& m, const Info&) { m1=m; }, new PatternFormatter("F2:%m"), Level::Debug },
        { [&](const string& m, const Info&) { m2=m; }, "F3:%m" },
        { [&](const string& m, const Info&) { m3=m; } },
    }));
    panda_log_error("hi");
    CHECK(m1 == "F2:hi");
    CHECK(m2 == "F3:hi");
    CHECK(m3 == "F1:hi");
}

TEST("multi into multi") {
    Ctx c;
    int cnt = 0;
    string s[10];
    set_formatter("D:%m");

    set_logger(new MultiLogger({
        { [&](auto& m, auto&) { ++cnt; s[1]=m; } },
        { [&](auto& m, auto&) { ++cnt; s[2]=m; }, "L2:%m" },
        { [&](auto& m, auto&) { ++cnt; s[3]=m; }, "L3:%m", Level::Emergency },
        {
            new MultiLogger({
                { [&](auto& m, auto&) { ++cnt; s[4]=m; } },
                { [&](auto& m, auto&) { ++cnt; s[5]=m; }, "ML2:%m" },
                { [&](auto& m, auto&) { ++cnt; s[6]=m; }, "ML3:%m", Level::Emergency },
            }),
            "M:%m"
        }
    }));

    panda_log_alert("hi");

    CHECK(cnt == 4);
    CHECK(s[1] == "D:hi");
    CHECK(s[2] == "L2:hi");
    CHECK(s[3].empty());
    CHECK(s[4] == "M:hi");
    CHECK(s[5] == "ML2:hi");
    CHECK(s[6].empty());
}
