#include "test.h"

using Test = TestSv<Ref>;

template <class T>
static void _test_create (T* sv, bool policy) {
    auto rcnt = SvREFCNT(sv);
    if (policy == Sv::NONE) SvREFCNT_inc(sv);
    SV* rsv;
    {
        Ref r = Ref::create(sv, policy);
        REQUIRE(r);
        REQUIRE(SvREFCNT(sv) == rcnt+1);
        REQUIRE(r.use_count() == 1);
        rsv = r;
        REQUIRE(SvREFCNT(rsv) == 1);
        REQUIRE(rsv != (SV*)sv);
        SvREFCNT_inc(rsv);
    }
    REQUIRE(SvREFCNT(rsv) == 1);
    SvREFCNT_dec(rsv);
    REQUIRE(SvREFCNT(sv) == rcnt);
}

template <class T>
static void test_create (T* sv) {
    _test_create(sv, Sv::INCREMENT);
    _test_create(sv, Sv::NONE);
}

template <class T>
static void test_create (const T& o) {
    REQUIRE(o);
    auto rcnt = SvREFCNT(o);
    SV* rsv;
    {
        Ref r = Ref::create(o);
        REQUIRE(r);
        REQUIRE(o.use_count() == rcnt+1);
        REQUIRE(r.use_count() == 1);
        rsv = r;
        REQUIRE(SvREFCNT(rsv) == 1);
        REQUIRE(rsv != (SV*)o);
        SvREFCNT_inc(rsv);
    }
    REQUIRE(SvREFCNT(rsv) == 1);
    SvREFCNT_dec(rsv);
    REQUIRE(o.use_count() == rcnt);
}

TEST_CASE("Ref", "[Sv]") {
    perlvars vars;
    Ref my(vars.rv);
    Sv oth_valid(vars.rv), oth_invalid(vars.av);

    SECTION("ctor") {
        SECTION("empty") {
            Ref r;
            REQUIRE(!r);
        }
        SECTION("SV") {
            SECTION("undef")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("number") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("string") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("RV")     { Test::ctor(vars.rv, behaviour_t::VALID); }
            SECTION("AV")     { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")     { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::ctor((SV*)vars.gv, behaviour_t::THROWS); }
        }

        SECTION("Ref")        { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("create") {
        SECTION("empty") {
            Ref r = Ref::create();
            REQUIRE(r);
            REQUIRE(!SvOK(SvRV(r)));
            REQUIRE(r.use_count() == 1);
            REQUIRE(SvREFCNT(SvRV(r)) == 1);
        }
        SECTION("nullptr") {
            Ref r = Ref::create((SV*)nullptr);
            REQUIRE(r);
            REQUIRE(!SvOK(SvRV(r)));
            REQUIRE(r.use_count() == 1);
            REQUIRE(SvREFCNT(SvRV(r)) == 1);
        }
        SECTION("SV")     { test_create(vars.iv); }
        SECTION("AV")     { test_create(vars.av); }
        SECTION("HV")     { test_create(vars.hv); }
        SECTION("CV")     { test_create(vars.cv); }
        SECTION("GV")     { test_create(vars.gv); }
        SECTION("Sv")     { test_create(Sv(vars.pv)); }
        SECTION("Scalar") { test_create(Scalar(vars.iv)); }
        SECTION("Array")  { test_create(Array(vars.av)); }
        SECTION("Hash")   { test_create(Hash(vars.hv)); }
        SECTION("Object") { test_create(Object(vars.ov)); }
        SECTION("Sub")    { test_create(Sub(vars.cv)); }
        SECTION("Stash")  { test_create(Stash(vars.stash)); }
        SECTION("Glob")   { test_create(Glob(vars.gv)); }
        SECTION("Ref")    { test_create(Ref(vars.rv)); }
    }

    SECTION("operator=") {
        auto o = Ref::create(vars.iv);
        SECTION("SV") {
            SECTION("undef SV")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::assign(o, vars.rv, behaviour_t::VALID); }
            SECTION("AV")        { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")        { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")        { Test::assign(o, (SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("Ref")        { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Ref r;
        r.set(vars.iv); // no checks
        REQUIRE(r);
        REQUIRE(SvREFCNT(vars.iv) == 2);
        REQUIRE(r.get() == vars.iv);
    }

    SECTION("cast") {
        SECTION("to SV") {
            Ref r(vars.rv);
            SV* sv = r;
            REQUIRE(sv == vars.rv);
        }
    }

    SECTION("get") {
        SECTION("SV") {
            Ref r(vars.rv);
            REQUIRE(r.get<>() == vars.rv);
            REQUIRE(r.get<SV>() == vars.rv);
        }
    }

    SECTION("get ref") {
        SV* rv = sv_2mortal(newRV(vars.iv));
        Ref r(rv);

        REQUIRE(r.value().get() == vars.iv);
        REQUIRE(r.value<Sv>().get() == vars.iv);
        REQUIRE(r.value<Scalar>().get() == vars.iv);
        REQUIRE(r.value<Simple>().get() == vars.iv);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Hash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, (SV*)vars.av);
        REQUIRE(r.value().get<AV>() == vars.av);
        REQUIRE_THROWS_AS(r.value<Scalar>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Simple>().get(), std::invalid_argument);
        REQUIRE(r.value<Array>().get<AV>() == vars.av);
        REQUIRE_THROWS_AS(r.value<Hash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, (SV*)vars.hv);
        REQUIRE(r.value().get<HV>() == vars.hv);
        REQUIRE_THROWS_AS(r.value<Scalar>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Simple>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE(r.value<Hash>().get<HV>() == vars.hv);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, (SV*)vars.cv);
        REQUIRE(r.value().get<CV>() == vars.cv);
        REQUIRE_THROWS_AS(r.value<Scalar>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Simple>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Hash>().get(), std::invalid_argument);
        REQUIRE(r.value<Sub>().get<CV>() == vars.cv);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, (SV*)vars.ov);
        REQUIRE(r.value().get<SV>() == vars.ov);
        REQUIRE(r.value<Scalar>().get() == vars.ov);
        REQUIRE(r.value<Simple>().get() == vars.ov);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Hash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE(r.value<Object>().get() == vars.ov);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, (SV*)vars.stash);
        REQUIRE(r.value().get<HV>() == vars.stash);
        REQUIRE_THROWS_AS(r.value<Scalar>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Simple>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE(r.value<Hash>().get<HV>() == vars.stash);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE(r.value<Stash>().get<HV>() == vars.stash);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, (SV*)vars.gv);
        REQUIRE(r.value().get<GV>() == vars.gv);
        REQUIRE(r.value<Scalar>().get<GV>() == vars.gv);
        REQUIRE_THROWS_AS(r.value<Simple>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Hash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE(r.value<Glob>().get<GV>() == vars.gv);
        REQUIRE_THROWS_AS(r.value<Ref>().get(), std::invalid_argument);

        SvRV_set(rv, vars.rv);
        REQUIRE(r.value().get() == vars.rv);
        REQUIRE(r.value<Scalar>().get() == vars.rv);
        REQUIRE_THROWS_AS(r.value<Simple>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Array>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Hash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Sub>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Object>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Stash>().get(), std::invalid_argument);
        REQUIRE_THROWS_AS(r.value<Glob>().get(), std::invalid_argument);
        REQUIRE(r.value<Ref>().get() == vars.rv);

        SvRV_set(rv, vars.iv); // do not remove, or double free will occur
    }

    SECTION("set ref") {
        SV* rv = sv_2mortal(newRV(vars.iv));
        Ref r(rv);
        REQUIRE(SvREFCNT(vars.iv) == 2);
        REQUIRE(SvREFCNT(vars.pv) == 1);
        r.value(vars.pv);
        REQUIRE(SvREFCNT(vars.iv) == 1);
        REQUIRE(SvREFCNT(vars.pv) == 2);
        r.value(nullptr);
        REQUIRE(SvREFCNT(vars.pv) == 1);
        REQUIRE(r.value());
        REQUIRE(!r.value().defined());

        REQUIRE(r.get() == rv);
        r.reset();
        REQUIRE(!r);
        REQUIRE(!r.get());
        auto cnt = SvREFCNT(vars.av);
        r.value(vars.av);
        REQUIRE(r);
        REQUIRE(r.get());
        REQUIRE(r.get() != rv);
        REQUIRE(SvREFCNT(vars.av) == cnt+1);
    }

}
