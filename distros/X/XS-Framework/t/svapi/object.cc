#include "test.h"

using Test = TestSv<Object>;

TEST_CASE("Object", "[Sv]") {
    perlvars vars;
    Object my(vars.ov);
    Sv oth_valid(vars.oavr), oth_invalid(vars.av);

    SECTION("ctor") {
        SECTION("empty") {
            Object r;
            REQUIRE(!r);
        }
        SECTION("SV") {
            SECTION("undef")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("number") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("string") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("RV")     { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("RV-OSV") { Test::ctor(vars.ovr, behaviour_t::VALID, vars.ov);  }
            SECTION("RV-OAV") { Test::ctor(vars.oavr, behaviour_t::VALID, (SV*)vars.oav); }
            SECTION("RV-OHV") { Test::ctor(vars.ohvr, behaviour_t::VALID, (SV*)vars.ohv); }
            SECTION("AV")     { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("OAV")    { Test::ctor((SV*)vars.oav, behaviour_t::VALID); }
            SECTION("HV")     { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")    { Test::ctor((SV*)vars.ohv, behaviour_t::VALID); }
            SECTION("CV")     { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::ctor((SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("AV") {
            SECTION("AV")     { Test::ctor(vars.av, behaviour_t::THROWS); }
            SECTION("OAV")    { Test::ctor(vars.oav, behaviour_t::VALID); }
        }
        SECTION("HV") {
            SECTION("HV")     { Test::ctor(vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")    { Test::ctor(vars.ohv, behaviour_t::VALID); }
        }
        SECTION("CV")         { Test::ctor(vars.cv, behaviour_t::THROWS); }
        SECTION("GV")         { Test::ctor(vars.gv, behaviour_t::THROWS); }

        SECTION("Object")     { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }

        SECTION("check refcnt") {
            auto ocnt = SvREFCNT(vars.ov);
            auto rcnt = SvREFCNT(vars.ovr);
            {
                Object o(vars.ovr);
                REQUIRE(SvREFCNT(vars.ov) == ocnt+1);
                REQUIRE(SvREFCNT(vars.ovr) == rcnt+1);
            }
            REQUIRE(SvREFCNT(vars.ov) == ocnt);
            REQUIRE(SvREFCNT(vars.ovr) == rcnt);
        }
    }

    SECTION("operator=") {
        Object o = Stash("MyTest").bless(Simple(100));

        SECTION("SV") {
            SECTION("undef")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")     { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("RV-OSV") { Test::assign(o, vars.ovr, behaviour_t::VALID, vars.ov); }
            SECTION("RV-OAV") { Test::assign(o, vars.oavr, behaviour_t::VALID, (SV*)vars.oav); }
            SECTION("RV-OHV") { Test::assign(o, vars.ohvr, behaviour_t::VALID, (SV*)vars.ohv); }
            SECTION("AV")     { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("OAV")    { Test::assign(o, (SV*)vars.oav, behaviour_t::VALID); }
            SECTION("HV")     { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")    { Test::assign(o, (SV*)vars.ohv, behaviour_t::VALID); }
            SECTION("CV")     { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::assign(o, (SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("AV") {
            SECTION("AV")     { Test::assign(o, vars.av, behaviour_t::THROWS); }
            SECTION("OAV")    { Test::assign(o, vars.oav, behaviour_t::VALID); }
        }
        SECTION("HV") {
            SECTION("HV")     { Test::assign(o, vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")    { Test::assign(o, vars.ohv, behaviour_t::VALID); }
        }
        SECTION("CV")         { Test::assign(o, vars.cv, behaviour_t::THROWS); }
        SECTION("GV")         { Test::assign(o, vars.gv, behaviour_t::THROWS); }

        SECTION("Object")     { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }

        SECTION("check refcnt") {
            auto obase = Simple(100);
            auto r = Ref::create(obase);
            Object o = Stash("MyTest").bless(r);
            auto ocnt = SvREFCNT(obase);
            auto rcnt = SvREFCNT(r);
            auto ocnt2 = SvREFCNT(vars.ov);
            auto rcnt2 = SvREFCNT(vars.ovr);
            o = vars.ovr;
            REQUIRE(SvREFCNT(r) == rcnt-1);
            REQUIRE(SvREFCNT(obase) == ocnt-1);
            REQUIRE(SvREFCNT(vars.ovr) == rcnt2+1);
            REQUIRE(SvREFCNT(vars.ov) == ocnt2+1);
        }
    }

    SECTION("set") {
        Object o;
        o.set(vars.iv); // no checks
        REQUIRE(o);
        REQUIRE(SvREFCNT(vars.iv) == 2);
        REQUIRE(o.get() == vars.iv);
    }

    SECTION("stash") {
        Object o(vars.ov);
        REQUIRE(o.stash());
        REQUIRE(o.stash() == vars.stash);

        Stash st("MyTest");
        o.stash(st);
        REQUIRE(o.stash() == gv_stashpvs("MyTest", 0));
        o.stash(vars.stash);
        REQUIRE(o.stash() == vars.stash);
    }

    SECTION("rebless") {
        Stash st("M1");
        auto o = st.bless(Simple(100));
        REQUIRE(o.stash() == st);
        Stash st2("M2");
        o.rebless(st2);
        REQUIRE(o.stash() == st2);
    }

    SECTION("ref") {
        Ref r;
        {
            auto o = Stash("M1").bless(Simple(100));
            r = o.ref();
            REQUIRE(r);
        }
        REQUIRE(r.use_count() == 1);
        Object o = r;
        REQUIRE(o.ref() == r);
        REQUIRE(r.use_count() == 2);
        o.reset();
        REQUIRE(r.use_count() == 1);
        o = r;
        o = vars.ov;
        REQUIRE(r.use_count() == 1);
        REQUIRE(o.ref() != r);
    }

    SECTION("method/method_strict") {
        auto o = Stash("M2").bless(Simple(333));
        o.stash().sub("child_method", vars.cv);
        REQUIRE(o.method("child_method"));
        REQUIRE(o.method("child_method") == get_cv("M2::child_method", 0));
        REQUIRE(o.method("child_method") == o.method_strict("child_method"));
        REQUIRE(o.method("method"));
        REQUIRE(o.method("method") == get_cv("M1::method", 0));
        REQUIRE(o.method("method") == o.method_strict("method"));
        REQUIRE(!o.method("nomethod"));
        REQUIRE_THROWS(o.method_strict("nomethod"));
    }

    SECTION("isa") {
        auto o = Stash("M2").bless(Simple(333));
        REQUIRE(o.isa("M1"));
        REQUIRE(o.isa(Stash("M1")));
        REQUIRE(!o.isa("M111"));
        REQUIRE(!o.isa(Stash("M222", GV_ADD)));
    }

    SECTION("call") {
        auto o = Stash("M2").bless(Simple(333));
        Simple ret = o.call("method");
        REQUIRE(ret == 343);
        o = vars.ov;
        ret = Simple(o.call("method", Simple(100)));
        REQUIRE(ret == 233);
    }

    SECTION("call_next/super/SUPER") {
        auto o = Stash("M4").bless(Simple(333));
        Sub sub = o.method("meth");
        Simple res;

        SECTION("SUPER") {
            res = o.call_SUPER(sub);
            REQUIRE(res == "M4(OBJ)-2");
            sub = sub.SUPER_strict();
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = o.call_SUPER(sub);
            REQUIRE(res == "M4(OBJ)-1");
            sub = sub.SUPER_strict();
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!sub.SUPER());
            REQUIRE_THROWS(sub.SUPER_strict());
            REQUIRE_THROWS(o.call_SUPER(sub));
        }

        SECTION("next") {
            res = o.call_next(sub);
            REQUIRE(res == "M4(OBJ)-2");
            sub = o.next_method_strict(sub);
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = o.call_next(sub);
            REQUIRE(res == "M4(OBJ)-3");
            sub = o.next_method_strict(sub);
            REQUIRE(sub == get_cv("M3::meth", 0));

            res = o.call_next(sub);
            REQUIRE(res == "M4(OBJ)-1");
            sub = o.next_method_strict(sub);
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!o.next_method(sub));
            REQUIRE_THROWS(o.next_method_strict(sub));
            REQUIRE_THROWS(o.call_next(sub));
        }

        SECTION("next_maybe") {
            res = o.call_next_maybe(sub);
            REQUIRE(res == "M4(OBJ)-2");
            sub = o.next_method(sub);

            res = o.call_next_maybe(sub);
            REQUIRE(res == "M4(OBJ)-3");
            sub = o.next_method(sub);

            res = o.call_next_maybe(sub);
            REQUIRE(res == "M4(OBJ)-1");
            sub = o.next_method(sub);

            res = o.call_next_maybe(sub);
            REQUIRE(!res);
        }

        SECTION("super/dfs") {
            res = o.call_super(sub);
            REQUIRE(res == "M4(OBJ)-2");
            sub = o.super_method_strict(sub);
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = o.call_super(sub);
            REQUIRE(res == "M4(OBJ)-1");
            sub = o.super_method_strict(sub);
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!o.super_method(sub));
            REQUIRE_THROWS(o.super_method_strict(sub));
            REQUIRE_THROWS(o.call_super(sub));
        }

        SECTION("super/c3") {
            o.call("enable_c3");

            res = o.call_super(sub);
            REQUIRE(res == "M4(OBJ)-2");
            sub = o.super_method_strict(sub);
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = o.call_super(sub);
            REQUIRE(res == "M4(OBJ)-3");
            sub = o.super_method_strict(sub);
            REQUIRE(sub == get_cv("M3::meth", 0));

            res = o.call_super(sub);
            REQUIRE(res == "M4(OBJ)-1");
            sub = o.super_method_strict(sub);
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!o.super_method(sub));
            REQUIRE_THROWS(o.super_method_strict(sub));
            REQUIRE_THROWS(o.call_super(sub));

            o.call("disable_c3");
        }

        SECTION("super_maybe") {
            res = o.call_super_maybe(sub);
            REQUIRE(res == "M4(OBJ)-2");
            sub = o.super_method(sub);

            res = o.call_super_maybe(sub);
            REQUIRE(res == "M4(OBJ)-1");
            sub = o.super_method(sub);

            res = o.call_super_maybe(sub);
            REQUIRE(!res);
        }
    }

    SECTION("detach") {
        auto obase = Simple(100);
        auto r = Ref::create(obase);
        Object o = Stash("MyTest").bless(r);
        REQUIRE(obase.use_count() == 3);
        REQUIRE(r.use_count() == 2);
        SV* osv = o.detach();
        REQUIRE(r.use_count() == 1);
        REQUIRE(obase.use_count() == 3);
        SvREFCNT_dec(osv);
    }
}
