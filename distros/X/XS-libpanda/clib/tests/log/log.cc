#include "logtest.h"
#include "panda/log/console.h"
#include "panda/log/log.h"
#include "panda/log/multi.h"
#include <iostream>

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

struct Hello {};
static std::ostream& operator<< (std::ostream& os, const Hello&) {
    os << "{hello:1}";
    return os;
}

TEST("prettify_json") {
    Ctx c;
    string_view s = "{epta:1, suka:2}";
    panda_log_warning(prettify_json{s});
    CHECK(c.str != s);

    panda_log_warning(prettify_json{Hello()});
    CHECK(c.str != "{hello:1}");
}

//TEST("VLA capture") {
//    // check if it compiles, gcc has bug with VLA capture
//    // https://gcc.gnu.org/bugzilla/show_bug.cgi?id=102272
//    int size = 10;
//    int a[size];
//    panda_log_error(a[1]);
//}

TEST("synopsis") {
    set_logger([](const string& msg, const Info&) {
        std::cout << msg << std::endl;
    });
    set_formatter("%1t %c[%L/%1M]%C %f:%l,%F(): %m");
    set_level(Level::Info);

    panda_log_info("info message");
    panda_log_warning("hello");
    panda_log(Level::Error, "Achtung!");
    panda_log_debug("here"); // will not be logged, because min level is INFO, and message will NOT be evaluated

    Module my_log_module("CustomName");
    panda_log_error(my_log_module, "custom only"); // use certain log module for logging

    int data[] = {1,42,5};
    //callback will not be called if log level is insufficient
    panda_log_notice([&] {
        for (auto v : data) {
            log << (v + 1);
        }
    });

    // macro uses name panda_log_module as logging module
    // first found by C++ name lookup is used
    // you may want to define panda_log_module in your application namespace
    {
        Module panda_log_module("my_module", Level::Error); // local variables have the highest priority

        panda_log_error("anything"); // logged with module "my_module"
        panda_log_warning("warn"); // will not be logged / evaluated
    }

    // choose a backend for logging
    set_logger(new ConsoleLogger());

    // or log to multiple backends
    set_logger(new MultiLogger({
        MultiLogger::Channel(new ConsoleLogger()),
        MultiLogger::Channel([](const string&, const Info&) {
            // custom logging function
        })
    }));
}
