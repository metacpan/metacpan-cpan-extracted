#include <catch2/catch.hpp>
#include <panda/backtrace.h>
#include <panda/exception.h>
#include "fn.h"
#include <iostream>

using namespace panda::backtrace;
using namespace panda;


TEST_CASE("backtrace", "[backtrace]") {
    install();
    bool got_it = false;
    try {
        fn03();
    }  catch (const exception& ex) {
        got_it = true;
        auto bt = ex.get_backtrace_info();
        std::cout << bt->to_string() << "\n";
        auto frames = bt->frames;
        CHECK(frames.size() >= 3);
        int fn_01_idx = -1;
        for(int i = 0; i <  (int)frames.size(); ++i) {
            if (frames[i]->name.find("fn01") != string::npos) { fn_01_idx = i; }
        }
        REQUIRE(fn_01_idx >= 0);
        CHECK(frames[fn_01_idx + 1]->name.find("fn02") != string::npos);
        CHECK(frames[fn_01_idx + 2]->name.find("fn03") != string::npos);

    }
    REQUIRE(got_it);
}
