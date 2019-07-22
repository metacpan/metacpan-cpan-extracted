#pragma once
#include <xs.h>
#include <catch.hpp>

using namespace xs;

enum class behaviour_t { VALID, EMPTY, THROWS };

struct perlvars {
    SV* undef;
    SV* iv;
    SV* pv;
    AV* av;
    HV* hv;
    SV* rv;
    CV* cv;
    SV* cvr;
    GV* gv;
    SV* gvr;
    HV* stash;
    SV* ov;
    SV* ovr;
    AV* oav;
    SV* oavr;
    HV* ohv;
    SV* ohvr;

    perlvars () {
        undef = newSV(0);
        iv    = newSViv(1000);
        pv    = newSVpvs("hello");
        av    = newAV();
        hv    = newHV();
        rv    = newRV_noinc(newSViv(333));
        cv    = get_cv("M1::dummy", 0);
        if (!cv) throw std::logic_error("should not happen");
        cvr   = newRV((SV*)cv);
        stash = gv_stashpvs("M1", 0);
        if (!stash) throw std::logic_error("should not happen");
        ov    = newSViv(123);
        ovr   = sv_bless(newRV_noinc(ov), stash);
        oav   = newAV();
        oavr  = sv_bless(newRV_noinc((SV*)oav), stash);
        ohv   = newHV();
        ohvr  = sv_bless(newRV_noinc((SV*)ohv), stash);

        SV** gvref = hv_fetchs(stash, "class_method", 0);
        if (!gvref) throw std::logic_error("should not happen");
        gv = (GV*)(*gvref);
        gvr = newRV((SV*)gv);
    }

    ~perlvars () {
        SvREFCNT_dec_NN(undef);
        SvREFCNT_dec_NN(iv);
        SvREFCNT_dec_NN(pv);
        SvREFCNT_dec_NN(av);
        SvREFCNT_dec_NN(hv);
        SvREFCNT_dec_NN(rv);
        SvREFCNT_dec_NN(cvr);
        SvREFCNT_dec_NN(gvr);
        SvREFCNT_dec_NN(ovr);
        SvREFCNT_dec_NN(oavr);
        SvREFCNT_dec_NN(ohvr);
    }
};

template <class TestClass>
struct TestSv {

    template <class T>
    static void ctor (T* sv, behaviour_t behaviour, T* check = NULL) {
        SECTION("default") { _ctor(sv, behaviour, Sv::INCREMENT, check); }
        SECTION("noinc")   { _ctor(sv, behaviour, Sv::NONE, check); }
    }
    template <class T>
    static void ctor (T& src, behaviour_t behaviour) {
        SECTION("copy") { _ctor(src, behaviour, false); }
        SECTION("move") { _ctor(std::move(src), behaviour, true); }
    }

    template <class T>
    static void noinc (T* sv, behaviour_t behaviour) {
        SvREFCNT_inc(sv);
        auto rcnt = SvREFCNT(sv);
        {
            switch(behaviour) {
                case behaviour_t::VALID:
                    {
                        TestClass o = TestClass::noinc(sv);
                        REQUIRE(SvREFCNT(sv) == rcnt);
                        REQUIRE(o);
                    }
                    break;
                case behaviour_t::EMPTY:
                    {
                        TestClass o = TestClass::noinc(sv);
                        REQUIRE(!o);
                        REQUIRE(SvREFCNT(sv) == rcnt - 1);
                    }
                    break;
                case behaviour_t::THROWS:
                    REQUIRE_THROWS_AS(TestClass::noinc(sv), std::invalid_argument);
                    break;
            }
        }
        REQUIRE(SvREFCNT(sv) == rcnt-1);
    }

    template <class T>
    static void assign (const TestClass& o, T* sv, behaviour_t behaviour, T* check = NULL) {
        REQUIRE(o);
        SECTION("default")  { _assign(o, sv, behaviour, check); }
        SECTION("to empty") { _assign(TestClass(), sv, behaviour, check); }
    }

    template <class T>
    static void assign (const TestClass& o, T& oth, behaviour_t behaviour) {
        REQUIRE(o);
        SECTION("copy") {
            SECTION("default")  { _assign(o, oth, behaviour, false); }
            SECTION("to empty") { _assign(TestClass(), oth, behaviour, false); }
        }
        SECTION("move") {
            SECTION("default")  { _assign(o, std::move(oth), behaviour, true); }
            SECTION("to empty") { _assign(TestClass(), std::move(oth), behaviour, true); }
        }
    }

private:
    template <class T>
    static void _ctor (T* sv, behaviour_t behaviour, bool policy, T* check) {
        if (!check) check = sv;
        auto cnt = SvREFCNT(check);
        if (policy == Sv::NONE) SvREFCNT_inc(sv);
        {
            switch(behaviour) {
                case behaviour_t::VALID:
                    {
                        TestClass o(sv, policy);
                        REQUIRE(o);
                        REQUIRE(SvREFCNT(check) == cnt+1);
                        REQUIRE(o.template get<T>() == check);
                    }
                    break;
                case behaviour_t::EMPTY:
                    {
                        TestClass o(sv, policy);
                        REQUIRE(!o);
                        REQUIRE(SvREFCNT(check) == cnt);
                    }
                    break;
                case behaviour_t::THROWS:
                    REQUIRE_THROWS_AS(TestClass(sv, policy), std::invalid_argument);
                    REQUIRE(SvREFCNT(check) == cnt);
                    break;
            }
        }
        REQUIRE(SvREFCNT(check) == cnt);
    }

    template <class T>
    static void _ctor (T&& src, behaviour_t behaviour, bool move) {
        SV* sv = src;
        auto cnt = SvREFCNT(sv);
        {
            switch(behaviour) {
                case behaviour_t::VALID:
                    {
                        TestClass o(std::forward<T>(src));
                        REQUIRE(o);
                    }
                    break;
                case behaviour_t::EMPTY:
                    {
                        TestClass o(std::forward<T>(src));
                        REQUIRE(!o);
                    }
                    break;
                case behaviour_t::THROWS:
                    REQUIRE_THROWS_AS(TestClass(std::forward<T>(src)), std::invalid_argument);
                    break;
            }
            if (move) REQUIRE(!src);
            else REQUIRE(src);

        }
        REQUIRE(SvREFCNT(sv) == cnt-move);
    }

    template <class T>
    static void _assign (const TestClass& co, T* sv, behaviour_t behaviour, T* check) {
        if (!check) check = sv;
        SV* src = co;
        auto src_cnt = src ? SvREFCNT(src) : 0;
        auto cnt = SvREFCNT(check);
        {
            TestClass o(co);
            switch(behaviour) {
                case behaviour_t::VALID:
                    o = sv;
                    REQUIRE(o);
                    REQUIRE(o.template get<T>() == check);
                    REQUIRE(SvREFCNT(check) == cnt + 1);
                    break;
                case behaviour_t::EMPTY:
                    o = sv;
                    REQUIRE(!o);
                    REQUIRE(o.template get<T>() == nullptr);
                    REQUIRE(SvREFCNT(check) == cnt);
                    break;
                case behaviour_t::THROWS:
                    REQUIRE_THROWS_AS(o = sv, std::invalid_argument);
                    REQUIRE(SvREFCNT(check) == cnt);
                    break;
            }
            if (src) REQUIRE(SvREFCNT(src) == src_cnt);
        }
        REQUIRE(SvREFCNT(check) == cnt);
        if (src) REQUIRE(SvREFCNT(src) == src_cnt);
    }

    template <class T>
    static void _assign (const TestClass& co, T&& oth, behaviour_t behaviour, bool move) {
        SV* src = co;
        SV* sv = oth;
        auto src_cnt = src ? SvREFCNT(src) : 0;
        auto cnt = SvREFCNT(sv);
        {
            TestClass o(co);
            switch(behaviour) {
                case behaviour_t::VALID:
                    o = std::forward<T>(oth);
                    REQUIRE(o);
                    break;
                case behaviour_t::EMPTY:
                    o = std::forward<T>(oth);
                    REQUIRE(!o);
                    break;
                case behaviour_t::THROWS:
                    REQUIRE_THROWS_AS(o = std::forward<T>(oth), std::invalid_argument);
                    break;
            }
            if (move) REQUIRE(oth.get() == src);
            else REQUIRE(oth.get() == sv);
            REQUIRE(SvREFCNT(sv) == cnt+(behaviour == behaviour_t::VALID)-move);
            if (src) REQUIRE(SvREFCNT(src) == src_cnt+move);

        }
        REQUIRE(SvREFCNT(sv) == cnt-move);
        if (src) REQUIRE(SvREFCNT(src) == src_cnt+move);
    }
};
