#include "test.h"
#include <sstream>
using Test = TestSv<Sv>;

template <class T>
static void test_cast (SV* good, SV* bad) {
    auto rcnt = SvREFCNT(good);
    Sv o(good);
    T* r = o;
    REQUIRE(r == (T*)good);
    REQUIRE(SvREFCNT(good) == rcnt+1);

    if (!bad) return;
    auto rcnt_bad = SvREFCNT(bad);
    o = bad;
    REQUIRE(SvREFCNT(good) == rcnt);
    REQUIRE(SvREFCNT(bad) == rcnt_bad+1);
    REQUIRE((T*)o == nullptr);
}

template <class T>
static void test_get (SV* good, SV* bad) {
    auto rcnt = SvREFCNT(good);
    Sv o(good);
    REQUIRE(o.get<T>() == (T*)good);
    REQUIRE(SvREFCNT(good) == rcnt+1);

    if (!bad) return;
    auto rcnt_bad = SvREFCNT(bad);
    o = bad;
    REQUIRE(SvREFCNT(good) == rcnt);
    REQUIRE(SvREFCNT(bad) == rcnt_bad+1);
    REQUIRE(o.get<T>() == (T*)bad);
}

#define TEST(name) TEST_CASE("Sv: " name, "[Sv]")

TEST("ctor") {
    perlvars vars;
    SECTION("empty") {
        Sv sv;
        REQUIRE(!sv);
    }
    SECTION("undef") {
        auto sv = Sv::create();
        REQUIRE(sv);
        REQUIRE(!SvOK(sv));
    }
    SECTION("SV") { Test::ctor(vars.iv, behaviour_t::VALID); }
    SECTION("AV") { Test::ctor(vars.av, behaviour_t::VALID); }
    SECTION("HV") { Test::ctor(vars.hv, behaviour_t::VALID); }
    SECTION("CV") { Test::ctor(vars.cv, behaviour_t::VALID); }
    SECTION("GV") { Test::ctor(vars.gv, behaviour_t::VALID); }
    SECTION("IO") { Test::ctor(vars.io, behaviour_t::VALID); }
    SECTION("Sv") { Test::ctor(Sv(vars.iv), behaviour_t::VALID); }
}

TEST("operator=") {
    perlvars vars;
    auto o = Sv::create();
    SECTION("SV") { Test::assign(o, vars.pv, behaviour_t::VALID); }
    SECTION("AV") { Test::assign(o, vars.av, behaviour_t::VALID); }
    SECTION("HV") { Test::assign(o, vars.hv, behaviour_t::VALID); }
    SECTION("CV") { Test::assign(o, vars.cv, behaviour_t::VALID); }
    SECTION("GV") { Test::assign(o, vars.gv, behaviour_t::VALID); }
    SECTION("IO") { Test::assign(o, vars.io, behaviour_t::VALID); }
    SECTION("Sv") { Test::assign(o, Sv(vars.iv), behaviour_t::VALID); }
}

TEST("reset") {
    perlvars vars;
    Sv sv;
    REQUIRE(!sv);
    sv.reset();
    REQUIRE(!sv);

    auto cnt = SvREFCNT(vars.iv);
    sv = vars.iv;
    REQUIRE(SvREFCNT(vars.iv) == cnt+1);
    sv.reset();
    REQUIRE(!sv);
    REQUIRE(SvREFCNT(vars.iv) == cnt);
}

TEST("cast") {
    perlvars vars;
    SECTION("to SV") { test_cast<SV>(vars.iv, NULL); }
    SECTION("to AV") { test_cast<AV>((SV*)vars.av, vars.iv); }
    SECTION("to HV") { test_cast<HV>((SV*)vars.hv, vars.pv); }
    SECTION("to CV") { test_cast<CV>((SV*)vars.cv, vars.iv); }
    SECTION("to GV") { test_cast<GV>((SV*)vars.gv, vars.iv); }
    SECTION("to IO") { test_cast<IO>((SV*)vars.io, vars.iv); }
}

TEST("get") {
    perlvars vars;
    SECTION("SV") { test_get<SV>(vars.iv, NULL); }
    SECTION("AV") { test_get<AV>((SV*)vars.av, vars.iv); }
    SECTION("HV") { test_get<HV>((SV*)vars.hv, vars.pv); }
    SECTION("CV") { test_get<CV>((SV*)vars.cv, vars.iv); }
    SECTION("GV") { test_get<GV>((SV*)vars.gv, vars.iv); }
    SECTION("IO") { test_get<IO>((SV*)vars.io, vars.iv); }
}

TEST("noinc") {
    perlvars vars;
    Test::noinc(vars.iv, behaviour_t::VALID);
}

TEST("to bool / defined / is_true") {
    perlvars vars;

    Sv sv;
    REQUIRE(!sv);
    REQUIRE(!sv.defined());
    REQUIRE(!sv.is_true());

    sv = &PL_sv_undef;
    REQUIRE(sv);
    REQUIRE(!sv.defined());
    REQUIRE(!sv.is_true());

    sv = sv_2mortal(newSViv(0));
    REQUIRE(sv);
    REQUIRE(sv.defined());
    REQUIRE(!sv.is_true());

    sv = sv_2mortal(newSViv(10));
    REQUIRE(sv);
    REQUIRE(sv.defined());
    REQUIRE(sv.is_true());

    sv = vars.av;
    REQUIRE(sv);
    REQUIRE(!sv.defined());
    REQUIRE(!sv.is_true());

    sv = vars.hv;
    REQUIRE(sv);
    REQUIRE(!sv.defined());
    REQUIRE(!sv.is_true());

    sv = vars.cv;
    REQUIRE(sv);
    REQUIRE(!sv.defined());
    REQUIRE(!sv.is_true());

    sv = vars.gv;
    REQUIRE(sv);
    REQUIRE(sv.defined());
    REQUIRE(sv.is_true());

    sv = vars.io;
    REQUIRE(sv);
    REQUIRE(!sv.defined());
    REQUIRE(!sv.is_true());
}

TEST("type") {
    perlvars vars;

    Sv sv(vars.iv);
    REQUIRE(sv.type() == SVt_IV);
    sv = vars.pv;
    REQUIRE(sv.type() == SVt_PV);
    sv_setiv(sv, 10);
    REQUIRE(sv.type() == SVt_PVIV);
    sv = vars.av;
    REQUIRE(sv.type() == SVt_PVAV);
    sv = vars.hv;
    REQUIRE(sv.type() == SVt_PVHV);
    sv = vars.cv;
    REQUIRE(sv.type() == SVt_PVCV);
    sv = vars.ov;
    REQUIRE(sv.type() == SVt_PVMG);
    sv = vars.gv;
    REQUIRE(sv.type() == SVt_PVGV);
    sv = vars.io;
    REQUIRE(sv.type() == SVt_PVIO);
}

TEST("readonly") {
    perlvars vars;

    REQUIRE(Sv::undef.readonly());
    Sv sv(vars.iv);
    REQUIRE(!sv.readonly());
    sv.readonly(true);
    REQUIRE(sv.readonly());
    sv.readonly(false);
    REQUIRE(!sv.readonly());
}

TEST("static undef/yes/no") {
    REQUIRE(Sv::undef.readonly());
    REQUIRE(Sv::yes.readonly());
    REQUIRE(Sv::no.readonly());

    REQUIRE(Sv::undef);
    REQUIRE(Sv::yes);
    REQUIRE(Sv::no);

    REQUIRE(!Sv::undef.defined());
    REQUIRE(Sv::yes.defined());
    REQUIRE(Sv::no.defined());

    REQUIRE(!Sv::undef.defined());
    REQUIRE(Sv::yes.is_true());
    REQUIRE(!Sv::no.is_true());
}

TEST("upgrade") {
    Sv sv = Sv::create();

    sv.upgrade(SVt_IV);
    REQUIRE(sv.type() == SVt_IV);
    SvIV_set(sv, 10);
    REQUIRE(SvIVX(sv) == 10);

    sv.upgrade(SVt_PV);
    REQUIRE(sv.type() == SVt_PVIV);

    sv = Sv::create();
    sv.upgrade(SVt_PVAV);
    REQUIRE(sv.type() == SVt_PVAV);
    REQUIRE((AV*)sv);

    sv = Sv::create();
    sv.upgrade(SVt_PVHV);
    REQUIRE(sv.type() == SVt_PVHV);
    REQUIRE((HV*)sv);
}

TEST("operator <<") {
    perlvars vars;
    Sv sv = vars.iv;
    std::stringstream ss;
    ss << sv << ' ';
    REQUIRE(ss.str() == "1000 ");

    sv = vars.pv;
    ss << sv << ' ';
    REQUIRE(ss.str() == "1000 hello ");

    sv = vars.rv;
    ss << sv << ' ';
    REQUIRE(ss.str().substr(0, 18) == "1000 hello SCALAR(");
}

TEST("is_scalar") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_scalar());
    REQUIRE(Sv::undef.is_scalar());
    o = vars.iv;
    REQUIRE(o.is_scalar());
    o = vars.pv;
    REQUIRE(o.is_scalar());
    o = vars.av;
    REQUIRE(!o.is_scalar());
    o = vars.hv;
    REQUIRE(!o.is_scalar());
    o = vars.rv;
    REQUIRE(o.is_scalar());
    o = vars.cv;
    REQUIRE(!o.is_scalar());
    o = vars.ov;
    REQUIRE(o.is_scalar());
    o = vars.stash;
    REQUIRE(!o.is_scalar());
    o = vars.gv;
    REQUIRE(o.is_scalar());
    o = vars.io;
    REQUIRE(!o.is_scalar());
}

TEST("is_ref") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_ref());
    o = vars.iv;
    REQUIRE(!o.is_ref());
    o = vars.pv;
    REQUIRE(!o.is_ref());
    o = vars.av;
    REQUIRE(!o.is_ref());
    o = vars.hv;
    REQUIRE(!o.is_ref());
    o = vars.rv;
    REQUIRE(o.is_ref());
    o = vars.cv;
    REQUIRE(!o.is_ref());
    o = vars.ov;
    REQUIRE(!o.is_ref());
    o = vars.stash;
    REQUIRE(!o.is_ref());
    o = vars.gv;
    REQUIRE(!o.is_ref());
    o = vars.io;
    REQUIRE(!o.is_ref());
}

TEST("is_simple") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_simple());
    REQUIRE(Sv::undef.is_simple());
    o = vars.iv;
    REQUIRE(o.is_simple());
    o = vars.pv;
    REQUIRE(o.is_simple());
    o = vars.av;
    REQUIRE(!o.is_simple());
    o = vars.hv;
    REQUIRE(!o.is_simple());
    o = vars.rv;
    REQUIRE(!o.is_simple());
    o = vars.cv;
    REQUIRE(!o.is_simple());
    o = vars.ov;
    REQUIRE(o.is_simple());
    o = vars.stash;
    REQUIRE(!o.is_simple());
    o = vars.gv;
    REQUIRE(!o.is_simple());
    o = vars.io;
    REQUIRE(!o.is_simple());
}

TEST("is_array") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_array());
    REQUIRE(!Sv::undef.is_array());
    o = vars.iv;
    REQUIRE(!o.is_array());
    o = vars.pv;
    REQUIRE(!o.is_array());
    o = vars.av;
    REQUIRE(o.is_array());
    o = vars.hv;
    REQUIRE(!o.is_array());
    o = vars.rv;
    REQUIRE(!o.is_array());
    o = vars.cv;
    REQUIRE(!o.is_array());
    o = vars.oav;
    REQUIRE(o.is_array());
    o = vars.stash;
    REQUIRE(!o.is_array());
    o = vars.gv;
    REQUIRE(!o.is_array());
    o = vars.io;
    REQUIRE(!o.is_array());
}

TEST("is_hash") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_hash());
    REQUIRE(!Sv::undef.is_hash());
    o = vars.iv;
    REQUIRE(!o.is_hash());
    o = vars.pv;
    REQUIRE(!o.is_hash());
    o = vars.av;
    REQUIRE(!o.is_hash());
    o = vars.hv;
    REQUIRE(o.is_hash());
    o = vars.rv;
    REQUIRE(!o.is_hash());
    o = vars.cv;
    REQUIRE(!o.is_hash());
    o = vars.ohv;
    REQUIRE(o.is_hash());
    o = vars.stash;
    REQUIRE(o.is_hash());
    o = vars.gv;
    REQUIRE(!o.is_hash());
    o = vars.io;
    REQUIRE(!o.is_hash());
}

TEST("is_sub") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_sub());
    REQUIRE(!Sv::undef.is_sub());
    o = vars.iv;
    REQUIRE(!o.is_sub());
    o = vars.pv;
    REQUIRE(!o.is_sub());
    o = vars.av;
    REQUIRE(!o.is_sub());
    o = vars.hv;
    REQUIRE(!o.is_sub());
    o = vars.rv;
    REQUIRE(!o.is_sub());
    o = vars.cv;
    REQUIRE(o.is_sub());
    o = vars.ov;
    REQUIRE(!o.is_sub());
    o = vars.stash;
    REQUIRE(!o.is_sub());
    o = vars.gv;
    REQUIRE(!o.is_sub());
    o = vars.io;
    REQUIRE(!o.is_sub());
}

TEST("is_object") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_object());
    REQUIRE(!Sv::undef.is_object());
    o = vars.iv;
    REQUIRE(!o.is_object());
    o = vars.pv;
    REQUIRE(!o.is_object());
    o = vars.av;
    REQUIRE(!o.is_object());
    o = vars.hv;
    REQUIRE(!o.is_object());
    o = vars.rv;
    REQUIRE(!o.is_object());
    o = vars.cv;
    REQUIRE(!o.is_object());
    o = vars.ov;
    REQUIRE(o.is_object());
    o = vars.stash;
    REQUIRE(!o.is_object());
    o = vars.gv;
    REQUIRE(!o.is_object());
    o = vars.io;
    REQUIRE(o.is_object());
}

TEST("is_stash") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_stash());
    REQUIRE(!Sv::undef.is_stash());
    o = vars.iv;
    REQUIRE(!o.is_stash());
    o = vars.pv;
    REQUIRE(!o.is_stash());
    o = vars.av;
    REQUIRE(!o.is_stash());
    o = vars.hv;
    REQUIRE(!o.is_stash());
    o = vars.rv;
    REQUIRE(!o.is_stash());
    o = vars.cv;
    REQUIRE(!o.is_stash());
    o = vars.ov;
    REQUIRE(!o.is_stash());
    o = vars.stash;
    REQUIRE(o.is_stash());
    o = vars.gv;
    REQUIRE(!o.is_stash());
    o = vars.io;
    REQUIRE(!o.is_stash());
}

TEST("is_glob") {
    perlvars vars;
    Sv o;
    REQUIRE(!o.is_glob());
    REQUIRE(!Sv::undef.is_glob());
    o = vars.iv;
    REQUIRE(!o.is_glob());
    o = vars.pv;
    REQUIRE(!o.is_glob());
    o = vars.av;
    REQUIRE(!o.is_glob());
    o = vars.hv;
    REQUIRE(!o.is_glob());
    o = vars.rv;
    REQUIRE(!o.is_glob());
    o = vars.cv;
    REQUIRE(!o.is_glob());
    o = vars.ov;
    REQUIRE(!o.is_glob());
    o = vars.stash;
    REQUIRE(!o.is_glob());
    o = vars.gv;
    REQUIRE(o.is_glob());
    o = vars.io;
    REQUIRE(!o.is_glob());
}

TEST("operator==") {
    perlvars vars;
    Sv o(vars.iv);
    REQUIRE(o == vars.iv);
    REQUIRE(vars.iv == o);
    REQUIRE(o == Sv(vars.iv));
    o = vars.av;
    REQUIRE(o == vars.av);
    REQUIRE(vars.av == o);
    o = vars.hv;
    REQUIRE(o == vars.hv);
    REQUIRE(vars.hv == o);
    o = vars.cv;
    REQUIRE(o == vars.cv);
    REQUIRE(vars.cv == o);
    o = vars.gv;
    REQUIRE(o == vars.gv);
    REQUIRE(vars.gv == o);
    o = vars.io;
    REQUIRE(o == vars.io);
    REQUIRE(vars.io == o);
}

TEST("detach") {
    perlvars vars;
    Sv o;
    REQUIRE(o.detach() == nullptr);
    o.reset();
    o = vars.iv;
    auto rcnt = o.use_count();
    SV* sv = o.detach();
    REQUIRE(sv == vars.iv);
    REQUIRE(SvREFCNT(sv) == rcnt);
    o.reset();
    REQUIRE(SvREFCNT(sv) == rcnt);
    SvREFCNT_dec(sv);
}

TEST("eval") {
    Simple res = eval("2**5");
    CHECK(res == 32);

    Sv err;

    try {
        eval("my $a = $non_existent->method();");
    }
    catch (PerlRuntimeException& e) {
        err = e.sv;
    }

    CHECK(err.is_true());
}
