#include "test.h"

using Test = TestSv<Io>;

TEST_CASE("Io", "[Io]") {
    perlvars vars;
    Io my(vars.io);
    Sv oth_valid(vars.io), oth_invalid(vars.hv);

    SECTION("ctor") {
        SECTION("empty") {
            Io o;
            REQUIRE(!o);
        }
        SECTION("SV") {
            SECTION("undef")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("number") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("string") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("RV")     { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("AV")     { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")    { Test::ctor((SV*)vars.ohv, behaviour_t::THROWS); }
            SECTION("SHV")    { Test::ctor((SV*)vars.stash, behaviour_t::THROWS); }
            SECTION("CV")     { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::ctor((SV*)vars.iog, behaviour_t::VALID, vars.io); }
            SECTION("R-GV")   { Test::ctor((SV*)vars.iogr, behaviour_t::VALID, vars.io); }
            SECTION("IO")     { Test::ctor((SV*)vars.io, behaviour_t::VALID); }
        }
        SECTION("GV")         { Test::ctor(vars.iog, behaviour_t::VALID, vars.io); }
        SECTION("IO")         { Test::ctor(vars.io, behaviour_t::VALID); }

        SECTION("Io")         { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("operator=") {
        Io o(eval("*STDIN{IO}"));
        SECTION("SV") {
            SECTION("undef SV")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("AV")        { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")       { Test::assign(o, (SV*)vars.ohv, behaviour_t::THROWS); }
            SECTION("SHV")       { Test::assign(o, (SV*)vars.stash, behaviour_t::THROWS); }
            SECTION("CV")        { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")        { Test::assign(o, (SV*)vars.iog, behaviour_t::VALID, vars.io); }
            SECTION("R-GV")      { Test::assign(o, (SV*)vars.iogr, behaviour_t::VALID, vars.io); }
            SECTION("IO")        { Test::assign(o, (SV*)vars.io, behaviour_t::VALID); }
        }
        SECTION("GV")         { Test::assign(o, vars.iog, behaviour_t::VALID, vars.io); }
        SECTION("R-GV")       { Test::assign(o, vars.iogr, behaviour_t::VALID, vars.io); }
        SECTION("IO")         { Test::assign(o, vars.io, behaviour_t::VALID); }
        SECTION("Glob")       { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Io o;
        auto cnt = SvREFCNT(vars.iv);
        o.set(vars.iv); // no checks
        REQUIRE(o);
        REQUIRE(SvREFCNT(vars.iv) == cnt+1);
        REQUIRE(o.get() == vars.iv);
    }

    SECTION("cast") {
        Io o(vars.iogr);
        auto rcnt = SvREFCNT(vars.io);
        SECTION("to SV") {
            SV* sv = o;
            REQUIRE(sv == (SV*)vars.io);
            REQUIRE(SvREFCNT(vars.io) == rcnt);
        }
        SECTION("to IO") {
            IO* sv = o;
            REQUIRE(sv == vars.io);
            REQUIRE(SvREFCNT(vars.io) == rcnt);
        }
    }

    SECTION("get") {
        Io o(vars.iog);
        auto rcnt = SvREFCNT(vars.io);
        REQUIRE(o.get<>() == (SV*)vars.io);
        REQUIRE(o.get<SV>() == (SV*)vars.io);
        REQUIRE(o.get<IO>() == vars.io);
        REQUIRE(SvREFCNT(vars.io) == rcnt);
    }

    SECTION("fileno") {
        Io o(eval("*STDIN{IO}"));
        CHECK(o.fileno() == 0);
        o = eval("*STDOUT{IO}");
        CHECK(o.fileno() == 1);
        o = eval("*STDERR{IO}");
        CHECK(o.fileno() == 2);
    }

    SECTION("iotype") {
        Io o(eval("*STDIN{IO}"));
        CHECK(o.iotype() == IoTYPE_RDONLY);
        o = eval("*STDOUT{IO}");
        CHECK(o.iotype() == IoTYPE_WRONLY);
    }
}
