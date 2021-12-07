#include "test.h"
#include <panda/exception.h>
#include <iostream>
#include <catch2/matchers/catch_matchers_string.hpp>

// prevent inlining
extern "C" {

int v = 0;

void fnxx() { ++v; }
void fn00() { ++v; fnxx(); throw bt<std::invalid_argument>("Oops!"); }
void fn01() { fn00(); ++v; }
void fn02() { fn01(); ++v; }
void fn03() { fn02(); ++v; }
void fn04() { fn03(); ++v; }
void fn05() { fn04(); ++v; }
void fn06() { fn05(); ++v; }
void fn07() { fn06(); ++v; }
void fn08() { fn07(); ++v; }
void fn09() { fn08(); ++v; }
void fn10() { fn09(); ++v; }
void fn11() { fn10(); ++v; }
void fn12() { fn11(); ++v; }
void fn13() { fn12(); ++v; }
void fn14() { fn13(); ++v; }
void fn15() { fn14(); ++v; }
void fn16() { fn15(); ++v; }
void fn17() { fn16(); ++v; }
void fn18() { fn17(); ++v; }
void fn19() { fn18(); ++v; }
void fn20() { fn19(); ++v; }
void fn21() { fn20(); ++v; }
void fn22() { fn21(); ++v; }
void fn23() { fn22(); ++v; }
void fn24() { fn23(); ++v; }
void fn25() { fn24(); ++v; }
void fn26() { fn25(); ++v; }
void fn27() { fn26(); ++v; }
void fn28() { fn27(); ++v; }
void fn29() { fn28(); ++v; }
void fn30() { fn29(); ++v; }
void fn31() { fn30(); ++v; }
void fn32() { fn31(); ++v; }
void fn33() { fn32(); ++v; }
void fn34() { fn33(); ++v; }
void fn35() { fn34(); ++v; }
void fn36() { fn35(); ++v; }
void fn37() { fn36(); ++v; }
void fn38() { fn37(); ++v; }
void fn39() { fn38(); ++v; }
void fn40() { fn39(); ++v; }
void fn41() { fn40(); ++v; }
void fn42() { fn41(); ++v; }
void fn43() { fn42(); ++v; }
void fn44() { fn43(); ++v; }
void fn45() { fn44(); ++v; }
void fn46() { fn45(); ++v; }
void fn47() { fn46(); ++v; }
void fn48() { fn47(); ++v; }

}

TEST_CASE("esception", "[exception]") {
    if (Backtrace().get_backtrace_info()->frames.size() == 0) {
        // *bsd 32bit: libunwind: EHHeaderParser::decodeTableEntry: bad fde: CIE ID is not zero
        // https://forums.freebsd.org/threads/freebsd-12-0-libunwind-error.70851/
        // other: should be ok
        SUCCEED("it seems the system has buggy glibc/libunwind, no sense to test");
        return;
    }

    bool was_catch = false;
    SECTION("exception with trace, catch exact exception") {
        try {
            fn48();
        } catch( const bt<std::invalid_argument>& e) {
            auto trace = e.get_backtrace_info();
            REQUIRE(e.get_trace().size() >= 49);
            REQUIRE((bool)trace);
            REQUIRE(e.what() == std::string("Oops!"));

            auto frames = trace->get_frames();
            REQUIRE(frames.size() >= 47);

            StackframeSP fn01_frame = nullptr;
            StackframeSP fn45_frame = nullptr;

            for(auto& f : frames)  {
                std::cout << "fn name: " << f->name << "\n";
                if (f->name.find("fn01") != string::npos) { fn01_frame = f; }
                if (f->name.find("fn45") != string::npos) { fn45_frame = f; }
            }
            // windows single executable don't have names, and musl-bases linuxes have no symbolic names too.
            bool has_named_frames = (fn01_frame) && (fn45_frame);
            if(has_named_frames) {
                REQUIRE(fn01_frame);
                REQUIRE(fn45_frame);

                CHECK_THAT( fn01_frame->library, Catch::Matchers::ContainsSubstring( "MyTest" ) );
                CHECK_THAT( fn01_frame->name, Catch::Matchers::ContainsSubstring( "fn01" ) );
                CHECK( fn01_frame->address > 0);
                CHECK( fn45_frame->address > 0);
                CHECK_THAT( fn45_frame->library, Catch::Matchers::ContainsSubstring( "MyTest" ) );
            }
            was_catch = true;
        }
        REQUIRE(was_catch);
    }

    SECTION("exception with trace, catch non-final class") {
        try {
            fn48();
        } catch( const std::logic_error& e) {
            REQUIRE(e.what() == std::string("Oops!"));
            auto bt = dyn_cast<const panda::Backtrace*>(&e);
            REQUIRE(bt);
            REQUIRE(bt->get_trace().size() >= 49);
            auto trace = bt->get_backtrace_info();
            REQUIRE((bool)trace);
            auto frames = trace->get_frames();
            REQUIRE(frames.size() >= 47);
            StackframeSP fn01_frame = nullptr;
            StackframeSP fn45_frame = nullptr;
            for(auto& f : frames)  {
                if (f->name.find("fn01") != string::npos) { fn01_frame = f; }
                if (f->name.find("fn45") != string::npos) { fn45_frame = f; }
            }
            bool has_named_frames = (fn01_frame) && (fn45_frame);
            if(has_named_frames) {
                CHECK(fn01_frame->name);
                CHECK(fn45_frame->name);
            }
            was_catch = true;
        }
        REQUIRE(was_catch);
    }

    SECTION("panda::exception with string") {
        try {
            throw panda::exception("my-description");
        } catch( const exception& e) {
            REQUIRE(e.whats() == "my-description");
            was_catch = true;
        }
        REQUIRE(was_catch);
    }
    SECTION("Backtrace::dump_trace()") {
        auto trace = Backtrace::dump_trace();
        CHECK_THAT( trace, Catch::Matchers::ContainsSubstring( "Backtrace" ) || Catch::Matchers::ContainsSubstring( "0x" )  );
    }
}
