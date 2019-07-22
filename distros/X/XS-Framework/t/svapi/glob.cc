#include "test.h"

using Test = TestSv<Glob>;

template <class T> SV* _get_xv (const char* name);
template <> SV* _get_xv<Sv>     (const char* name) { return get_sv(name, 0); }
template <> SV* _get_xv<Scalar> (const char* name) { return get_sv(name, 0); }
template <> SV* _get_xv<Array>  (const char* name) { return (SV*)get_av(name, 0); }
template <> SV* _get_xv<Hash>   (const char* name) { return (SV*)get_hv(name, 0); }
template <> SV* _get_xv<Sub>    (const char* name) { return (SV*)get_cv(name, 0); }

template <class SlotClass, class T>
void test_set_slot (Glob& o, T* sv) {
    SV* initial = o.slot<SlotClass>();
    U32 icnt = 0;
    if (initial) {
        SvREFCNT_inc(initial);
        sv_2mortal(initial);
        icnt = SvREFCNT(initial);
        REQUIRE(initial == _get_xv<SlotClass>("M1::gv2set"));
    }
    auto cnt = sv ? SvREFCNT(sv) : 0;
    o.slot(sv);
    if (initial) REQUIRE(SvREFCNT(initial) == icnt-1);
    if (sv) REQUIRE(SvREFCNT(sv) == cnt+1);
    REQUIRE(o.slot<SlotClass>() != initial);
    REQUIRE(o.slot<SlotClass>() == _get_xv<SlotClass>("M1::gv2set"));
}

template <class SlotClass, class T>
void test_set_slot (Glob& o, const T& sv) {
    SV* initial = o.slot<SlotClass>();
    U32 icnt = 0;
    if (initial) {
        SvREFCNT_inc(initial);
        sv_2mortal(initial);
        icnt = SvREFCNT(initial);
        REQUIRE(initial == _get_xv<SlotClass>("M1::gv2set"));
    }
    auto cnt = sv ? SvREFCNT(sv) : 0;
    o.slot(sv);
    if (initial) REQUIRE(SvREFCNT(initial) == icnt-1);
    if (sv) REQUIRE(SvREFCNT(sv) == cnt+1);
    REQUIRE(o.slot<SlotClass>() != initial);
    REQUIRE(o.slot<SlotClass>() == _get_xv<SlotClass>("M1::gv2set"));
}

TEST_CASE("Glob", "[Sv]") {
    perlvars vars;
    Glob my(vars.gv);
    Sv oth_valid(vars.gv), oth_invalid(vars.hv);

    SECTION("ctor") {
        SECTION("empty") {
            Glob o;
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
            SECTION("GV")     { Test::ctor((SV*)vars.gv, behaviour_t::VALID); }
        }
        SECTION("GV") { Test::ctor(vars.gv, behaviour_t::VALID); }

        SECTION("Glob")       { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("operator=") {
        Glob o((GV*)(*hv_fetchs(vars.stash, "_dummy", GV_ADD)));
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
            SECTION("GV")        { Test::assign(o, (SV*)vars.gv, behaviour_t::VALID); }
        }
        SECTION("GV")         { Test::assign(o, vars.gv, behaviour_t::VALID); }
        SECTION("Glob")       { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Glob o;
        SECTION("SV") {
            auto cnt = SvREFCNT(vars.iv);
            o.set(vars.iv); // no checks
            REQUIRE(o);
            REQUIRE(SvREFCNT(vars.iv) == cnt+1);
            REQUIRE(o.get() == vars.iv);
        }
        SECTION("GV") {
            auto cnt = SvREFCNT(vars.pv);
            o.set((GV*)vars.pv); // no checks
            REQUIRE(o);
            REQUIRE(SvREFCNT(vars.hv) == cnt+1);
            REQUIRE(o.get<GV>() == (GV*)vars.pv);
        }
    }

    SECTION("cast") {
        Glob o(vars.gv);
        auto rcnt = SvREFCNT(vars.gv);
        SECTION("to SV") {
            SV* sv = o;
            REQUIRE(sv == (SV*)vars.gv);
            REQUIRE(SvREFCNT(vars.gv) == rcnt);
        }
        SECTION("to GV") {
            GV* sv = o;
            REQUIRE(sv == vars.gv);
            REQUIRE(SvREFCNT(vars.gv) == rcnt);
        }
    }

    SECTION("get") {
        Glob o(vars.gv);
        auto rcnt = SvREFCNT(vars.gv);
        REQUIRE(o.get<>() == (SV*)vars.gv);
        REQUIRE(o.get<SV>() == (SV*)vars.gv);
        REQUIRE(o.get<GV>() == vars.gv);
        REQUIRE(SvREFCNT(vars.gv) == rcnt);
    }

    SECTION("name/effective_name") {
        REQUIRE(my.name() == "class_method");
        REQUIRE(my.effective_name() == "class_method");
    }

    SECTION("stash/effective_stash") {
        REQUIRE(my.stash() == vars.stash);
        REQUIRE(my.effective_stash() == vars.stash);
    }

    SECTION("get slot") {
        Glob o = Stash(vars.stash)["allgv"];
        REQUIRE(o.slot<Scalar>());
        REQUIRE(Simple(o.slot<Scalar>()) == "scalar");

        REQUIRE(o.slot<Array>());
        REQUIRE(Simple(o.slot<Array>()[0]) == "array");

        REQUIRE(o.slot<Hash>());
        REQUIRE(Simple(o.slot<Hash>()["key"]) == "hash");

        REQUIRE(o.slot<Sub>());
        REQUIRE(o.slot<Sub>() == get_cv("M1::allgv", 0));
    }

    SECTION("set slot") {
        Glob o = Stash(vars.stash)["gv2set"];
        SECTION("SV") {
            SECTION("simple")  { test_set_slot<Scalar>(o, Simple(100).get()); }
            SECTION("nullify") { test_set_slot<Scalar>(o, (SV*)NULL); }
            SECTION("AV")      { test_set_slot<Array>(o, Array::create().get()); }
            SECTION("HV")      { test_set_slot<Hash>(o, Hash::create().get()); }
            SECTION("CV")      { test_set_slot<Sub>(o, Sub("M1::dummy").get()); }
        }
        SECTION("AV")         { test_set_slot<Array>(o, Array::create().get<AV>()); }
        SECTION("AV-nullify") { test_set_slot<Array>(o, (AV*)NULL); }
        SECTION("HV")         { test_set_slot<Hash>(o, Hash::create().get<HV>()); }
        SECTION("HV-nullify") { test_set_slot<Hash>(o, (HV*)NULL); }
        SECTION("CV")         { test_set_slot<Sub>(o, Sub("M1::dummy2").get<CV>()); }
        SECTION("CV-nullify") { test_set_slot<Sub>(o, (CV*)NULL); }
        SECTION("Sv") {
            SECTION("simple")  { test_set_slot<Scalar>(o, static_cast<Sv>(Simple(100))); }
            SECTION("nullify") { test_set_slot<Scalar>(o, Sv()); }
            SECTION("AV")      { test_set_slot<Array>(o, static_cast<Sv>(Array::create())); }
            SECTION("HV")      { test_set_slot<Hash>(o, static_cast<Sv>(Hash::create())); }
            SECTION("CV")      { test_set_slot<Sub>(o, static_cast<Sv>(Sub("M1::dummy"))); }
        }
        SECTION("Scalar")         { test_set_slot<Scalar>(o, Scalar(Simple(200))); }
        SECTION("Scalar-nullify") { test_set_slot<Scalar>(o, Scalar()); }
        SECTION("Simple")         { test_set_slot<Scalar>(o, Simple(200)); }
        SECTION("Simple-nullify") { test_set_slot<Scalar>(o, Simple()); }
        SECTION("Ref")            { test_set_slot<Scalar>(o, Ref::create(Simple(200))); }
        SECTION("Ref-nullify")    { test_set_slot<Scalar>(o, Ref()); }
        SECTION("Array")          { test_set_slot<Array>(o, Array::create()); }
        SECTION("Array-nullify")  { test_set_slot<Array>(o, Array()); }
        SECTION("Hash")           { test_set_slot<Hash>(o, Hash::create()); }
        SECTION("Hash-nullify")   { test_set_slot<Hash>(o, Hash()); }
        SECTION("Stash")          { test_set_slot<Hash>(o, Stash(vars.stash)); }
        SECTION("Stash-nullify")  { test_set_slot<Hash>(o, Stash()); }
        SECTION("Sub")            { test_set_slot<Sub>(o, Sub("M1::dummy2")); }
        SECTION("Sub-nullify")    { test_set_slot<Sub>(o, Sub()); }
        SECTION("Object-Scalar")  { test_set_slot<Scalar>(o, Object(vars.ov)); }
        SECTION("Object-Nullify") { test_set_slot<Scalar>(o, Object()); }
        SECTION("Object-Array")   { test_set_slot<Array>(o, Object(vars.oav)); o.slot(Array()); }
    }

    SECTION("create") {
        Stash stash(vars.stash);
        auto glob = Glob::create(stash, "autogen");
        REQUIRE(glob);
        REQUIRE(glob.stash() == vars.stash);
        REQUIRE(glob.name() == "autogen");
        glob.slot(Sub("M1::dummy"));
        stash["aliased"] = glob;
        REQUIRE(get_cv("M1::dummy", 0) == get_cv("M1::aliased", 0));
    }

    SECTION("scalar") {
        Glob o;
        REQUIRE(!o.scalar());
        o = Stash(vars.stash)["gv2set"];
        auto v = Simple(200);
        o.scalar(v);
        REQUIRE(o.slot<Scalar>() == v);
        REQUIRE(o.scalar() == v);
    }

    SECTION("array") {
        Glob o;
        REQUIRE(!o.array());
        o = Stash(vars.stash)["gv2set"];
        auto v = Array::create();
        o.array(v);
        REQUIRE(o.slot<Array>() == v);
        REQUIRE(o.array() == v);
    }

    SECTION("hash") {
        Glob o;
        REQUIRE(!o.hash());
        o = Stash(vars.stash)["gv2set"];
        auto v = Hash::create();
        o.hash(v);
        REQUIRE(o.slot<Hash>() == v);
        REQUIRE(o.hash() == v);
    }

    SECTION("sub") {
        Glob o;
        REQUIRE(!o.sub());
        o = Stash(vars.stash)["gv2set"];
        auto v = Sub("M1::dummy");
        o.sub(v);
        REQUIRE(o.slot<Sub>() == v);
        REQUIRE(o.sub() == v);
    }
}
