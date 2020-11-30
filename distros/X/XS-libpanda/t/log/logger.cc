#include "logtest.h"

#define TEST(name) TEST_CASE("log-logger: " name, "[log-logger]")

TEST("set_logger") {
    Ctx c;
    Info        info;
    std::string str;
    uint32_t    chk_line;
    bool        grep = false;
    set_formatter(nullptr); // formatter.cc doesn't clean after run

    SECTION("formatting callback") {
        set_logger([&](std::string& _str, const Info& _info, const IFormatter&) {
            info  = _info;
            str   = _str;
        });

        panda_log_alert("hello"); chk_line = __LINE__;
    }

    SECTION("simple callback") {
        grep = true;
        set_logger([&](const std::string& _str, const Info& _info) {
            info  = _info;
            str   = _str;
        });

        panda_log_alert("hello"); chk_line = __LINE__;
    }

    SECTION("object") {
        struct Logger : ILogger {
            Info   info;
            string str;
        };
        Logger* logger;


        SECTION("formating") {
            struct Logger1 : Logger {
                void log_format (std::string& _str, const Info& _info, const IFormatter&) override {
                    info = _info;
                    str  = string(_str.data(), _str.length());
                }
            };
            logger = new Logger1();
        }

        SECTION("simple") {
            grep = true;
            struct Logger2 : Logger {
                void log (const string& _str, const Info& _info) override {
                    info = _info;
                    str  = _str;
                }
            };
            logger = new Logger2();
        }

        set_logger(logger);

        panda_log_alert("hello"); chk_line = __LINE__;

        info = logger->info;
        str  = logger->str;
    }

    if (grep) REQUIRE_THAT(str, Catch::Contains("hello"));
    else      REQUIRE(str == "hello");
    REQUIRE(info.level == Level::Alert);
    REQUIRE(info.func == __func__);
    REQUIRE(info.file.length() > 0);
    REQUIRE(info.line == chk_line);
    REQUIRE(info.module == &::panda_log_module);
}

TEST("destroy old logger") {
    struct Logger : ILogger {
        int* dtor;
        void log (const string&, const Info&) override {}
        ~Logger () { (*dtor)++; }
    };

    int dtor = 0;
    auto logger = new Logger();
    logger->dtor = &dtor;

    set_logger(logger);
    panda_log_error("");
    REQUIRE(dtor == 0);

    auto logger2 = new Logger();
    logger2->dtor = &dtor;
    set_logger(logger2);
    REQUIRE(dtor == 1);

    set_logger(nullptr);
    REQUIRE(dtor == 2);
}
