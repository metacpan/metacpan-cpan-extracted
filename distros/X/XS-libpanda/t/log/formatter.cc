#include "logtest.h"
#include <regex>

#define TEST(name) TEST_CASE("log-formatter: " name, "[log-formatter]")

static inline void REGCHECK (const string& s, const string& re) {
    WARN("checking '" << s << "' with regex '" << re <<"'");
    CHECK(std::regex_search(std::string(s.c_str()), std::regex(std::string(re.c_str()))));
}

TEST("set_formatter") {
    Ctx c;
    string str;

    set_logger([&str](const string& s, const Info&) {
        str = s;
    });

    SECTION("callback") {
        set_formatter([](std::string&, const Info&) -> string {
            return "jopa";
        });
    }
    SECTION("object") {
        struct Formatter : IFormatter {
            string format (std::string&, const Info&) const override {
                return "jopa";
            }
        };
        set_formatter(new Formatter());
    }

    panda_log_alert("hello");
    REQUIRE(str == "jopa");
}

TEST("set_format") {
    Ctx c;
    Module panda_log_module("epta");

    SECTION("level") {
        set_format("LEVEL=%L");
        panda_log_alert();
        CHECK(c.fstr == "LEVEL=alert");
    }

    SECTION("module") {
        SECTION("default") {
            set_format("MODULE=%M");
            panda_log_alert();
            CHECK(c.fstr == "MODULE=epta");
        }
        SECTION("strip") {
            set_format(" MOD=%4.1M ");
            panda_log_alert(::panda_log_module, "");
            CHECK(c.fstr == " ");
        }
    }

    SECTION("function") {
        set_format("FUNC=%F");
        panda_log_alert();
        CHECK(c.fstr.find("FUNC=____C_A_T_C_H____T_E_S_T____") == 0);
    }

    SECTION("file") {
        SECTION("short name") {
            set_format("FILE=%f");
            panda_log_alert();
            CHECK(c.fstr == "FILE=formatter.cc");
        }
        SECTION("full name") {
            set_format("FILE=%1f");
            panda_log_alert();
            REGCHECK(c.fstr, "FILE=.*t[\\/]log[\\/]formatter.cc");
        }
    }

    SECTION("line") {
        set_format("LINE=%l");
        panda_log_alert();
        CHECK(c.fstr == "LINE=81");
    }

    SECTION("message") {
        set_format("MSG=%m");
        panda_log_alert("mymsg");
        CHECK(c.fstr == "MSG=mymsg");
    }

    SECTION("current time") {
        string pat = "TIME=";
        string re;
        SECTION("Y4 date") {
            re = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}";
            SECTION("low-res") {
                pat += "%t";
            }
            SECTION("hi-res") {
                pat += "%.1t";
                re += "\\.\\d{1}";
            }
        }
        SECTION("Y2 date") {
            re = "\\d{2}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}";
            SECTION("low-res") {
                pat += "%1t";
            }
            SECTION("hi-res") {
                pat += "%1.2t";
                re += "\\.\\d{2}";
            }
        }
        SECTION("hms") {
            re = "\\d{2}:\\d{2}:\\d{2}";
            SECTION("low-res") {
                pat += "%2t";
            }
            SECTION("hi-res") {
                pat += "%2.3t";
                re += "\\.\\d{3}";
            }
        }
        SECTION("unix ts") {
            re = "\\d+";
            SECTION("low-res") {
                pat += "%3t";
            }
            SECTION("hi-res") {
                pat += "%3.9t";
                re += "\\.\\d{9}";
            }
        }
        set_format(pat);
        panda_log_alert();
        REGCHECK(c.fstr, re + '$');
    }

    SECTION("thread id") {
        set_format("THREAD=%T");
        panda_log_alert();
        REGCHECK(c.fstr, "THREAD=\\d+");
    }

    SECTION("process id") {
        set_format("PID=%p");
        panda_log_alert();
        REGCHECK(c.fstr, "PID=\\d+");
    }

    SECTION("process title") {
        set_format("TITLE=%P");
        panda_log_alert();
        REGCHECK(c.fstr, "TITLE=.+");
    }
}
