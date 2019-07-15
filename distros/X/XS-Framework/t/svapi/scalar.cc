#include "test.h"

using Test = TestSv<Scalar>;

// when policy = INCREMENT, and SV* declined, do nothing (+1 -1)
// when policy = NONE and SV* declined, it MUST be decremented

TEST_CASE("Scalar", "[Sv]") {
    perlvars vars;
    Scalar my(vars.iv);
    Sv oth_valid(vars.rv), oth_invalid(vars.av);

    SECTION("ctor") {
        SECTION("empty") {
            Scalar obj;
            REQUIRE(!obj);
        }
        SECTION("SV") {
            SECTION("undef")  { Test::ctor(vars.undef, behaviour_t::VALID); }
            SECTION("number") { Test::ctor(vars.iv, behaviour_t::VALID); }
            SECTION("string") { Test::ctor(vars.pv, behaviour_t::VALID); }
            SECTION("OSV")    { Test::ctor(vars.ov, behaviour_t::VALID); }
            SECTION("RV")     { Test::ctor(vars.rv, behaviour_t::VALID); }
            SECTION("AV")     { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")     { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::ctor((SV*)vars.gv, behaviour_t::VALID); }
        }
        SECTION("GV")         { Test::ctor(vars.gv, behaviour_t::VALID); }

        SECTION("Scalar")     { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("noinc") {
        SECTION("SV") {
            SECTION("undef")  { Test::noinc(vars.undef, behaviour_t::VALID); }
            SECTION("number") { Test::noinc(vars.iv, behaviour_t::VALID); }
            SECTION("string") { Test::noinc(vars.pv, behaviour_t::VALID); }
            SECTION("OSV")    { Test::noinc(vars.ov, behaviour_t::VALID); }
            SECTION("RV")     { Test::noinc(vars.rv, behaviour_t::VALID); }
            SECTION("AV")     { Test::noinc((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::noinc((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")     { Test::noinc((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::noinc((SV*)vars.gv, behaviour_t::VALID); }
        }
        SECTION("GV")         { Test::noinc(vars.gv, behaviour_t::VALID); }
    }

    SECTION("operator=") {
        Scalar o(newSViv(10), Sv::NONE);
        SECTION("SV") {
            SECTION("undef")  { Test::assign(o, vars.undef, behaviour_t::VALID); }
            SECTION("number") { Test::assign(o, vars.iv, behaviour_t::VALID); }
            SECTION("string") { Test::assign(o, vars.pv, behaviour_t::VALID); }
            SECTION("OSV")    { Test::assign(o, vars.ov, behaviour_t::VALID); }
            SECTION("RV")     { Test::assign(o, vars.rv, behaviour_t::VALID); }
            SECTION("AV")     { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")     { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::assign(o, (SV*)vars.gv, behaviour_t::VALID); }
        }
        SECTION("GV")         { Test::assign(o, vars.gv, behaviour_t::VALID); }
        SECTION("Scalar")     { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        SECTION("SV") {
            Scalar o;
            o.set((SV*)vars.cv);
            REQUIRE(o.get() == (SV*)vars.cv);
        }
        SECTION("GV") {
            Scalar o;
            o.set((GV*)vars.cv);
            REQUIRE(o.get() == (SV*)vars.cv);
        }
    }

    SECTION("cast") {
        SECTION("to SV") {
            Scalar o(vars.iv);
            auto cnt = SvREFCNT(vars.iv);
            SV* r = o;
            REQUIRE(r == vars.iv);
            REQUIRE(SvREFCNT(vars.iv) == cnt);
        }
        SECTION("to GV") {
            Scalar o(vars.iv);
            auto cnt = SvREFCNT(vars.iv);
            GV* r = o;
            REQUIRE(r == nullptr);
            REQUIRE(SvREFCNT(vars.iv) == cnt);
        }
    }

    SECTION("get") {
        SECTION("SV") {
            Scalar o(vars.iv);
            auto cnt = SvREFCNT(vars.iv);
            REQUIRE(o.get<SV>() == vars.iv);
            REQUIRE(SvREFCNT(vars.iv) == cnt);
        }
        SECTION("GV") {
            Scalar o(vars.iv);
            auto cnt = SvREFCNT(vars.iv);
            REQUIRE(o.get<GV>() == (GV*)vars.iv);
            REQUIRE(SvREFCNT(vars.iv) == cnt);
        }
    }

    SECTION("upgrade") {
        Scalar o = Sv::create();
        o.upgrade(SVt_PVMG); // upgrade till PVMG works
        REQUIRE(o.type() == SVt_PVMG);
        REQUIRE_THROWS(o.upgrade(SVt_PVAV));
    }

    SECTION("as_string") {
        REQUIRE(Scalar(Simple(111)).as_string() == panda::string("111"));
        const char* str = "ebanarot";
        Scalar s = Simple(str);
        REQUIRE(s.as_string() == str);
        REQUIRE(s.as_string().data() != str);

        REQUIRE(Scalar().as_string() == panda::string());
        REQUIRE(Scalar::undef.as_string() == panda::string());
        REQUIRE_THROWS_AS(Ref::create(Array::create()).as_string(), std::invalid_argument);
    }

    SECTION("as_number") {
        REQUIRE(Scalar(Simple(111)).as_number() == 111);
        REQUIRE(Scalar(Simple(111.7)).as_number() == 111);
        REQUIRE(Scalar(Simple(111.7)).as_number<double>() == 111.7);
        REQUIRE(Scalar().as_number() == 0);
        REQUIRE(Scalar::undef.as_number() == 0);
        REQUIRE_THROWS_AS(Ref::create(Array::create()).as_number(), std::invalid_argument);
   }
}
