#include "test.h"
#include <utility>

using Test = TestSv<Sub>;

TEST_CASE("Sub", "[Sv]") {
    perlvars vars;
    Sub my(vars.cv);
    Sv oth_valid(vars.cv), oth_invalid(vars.gv);

    SECTION("ctor") {
        SECTION("empty") {
            Sub o;
            REQUIRE(!o);
        }
        SECTION("SV") {
            SECTION("undef SV")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("RV-OAV")    { Test::ctor(vars.oavr, behaviour_t::THROWS); }
            SECTION("RV-OHV")    { Test::ctor(vars.ohvr, behaviour_t::THROWS); }
            SECTION("RV-CV")     { Test::ctor(vars.cvr, behaviour_t::VALID, (SV*)vars.cv); }
            SECTION("AV")        { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")        { Test::ctor((SV*)vars.cv, behaviour_t::VALID); }
            SECTION("GV")        { Test::ctor((SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("CV") { Test::ctor(vars.cv, behaviour_t::VALID); }

        SECTION("Sub")        { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }

        SECTION("from string") {
            Sub c("M1::dummy2");
            REQUIRE(c);
            REQUIRE(c.get<CV>() == get_cv("M1::dummy2", 0));
            Sub c2("M1::nonexistent");
            REQUIRE(!c2);
            Sub c3("M1::nonexistent", GV_ADD);
            REQUIRE(c3);
            REQUIRE(c3.get<CV>() == get_cv("M1::nonexistent", 0));
        }
    }

    SECTION("operator=") {
        Sub o("M1::dummy2");
        SECTION("SV") {
            SECTION("undef SV")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("RV-OAV")    { Test::assign(o, vars.oavr, behaviour_t::THROWS); }
            SECTION("RV-OHV")    { Test::assign(o, vars.ohvr, behaviour_t::THROWS); }
            SECTION("RV-CV")     { Test::assign(o, vars.cvr, behaviour_t::VALID, (SV*)vars.cv); }
            SECTION("AV")        { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")        { Test::assign(o, (SV*)vars.cv, behaviour_t::VALID); }
            SECTION("GV")        { Test::assign(o, (SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("CV")         { Test::assign(o, vars.cv, behaviour_t::VALID); }
        SECTION("Sub")        { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Sub o;
        o.set(vars.iv); // no checks
        REQUIRE(o);
        REQUIRE(SvREFCNT(vars.iv) == 2);
        REQUIRE(o.get() == vars.iv);
    }

    SECTION("cast") {
        Sub o(vars.cv);
        auto rcnt = SvREFCNT(vars.cv);
        SECTION("to SV") {
            SV* sv = o;
            REQUIRE(sv == (SV*)vars.cv);
            REQUIRE(SvREFCNT(vars.cv) == rcnt);
        }
        SECTION("to CV") {
            CV* sv = o;
            REQUIRE(sv == vars.cv);
            REQUIRE(SvREFCNT(vars.cv) == rcnt);
        }
    }

    SECTION("get") {
        Sub o(vars.cv);
        auto rcnt = SvREFCNT(vars.cv);
        REQUIRE(o.get<>() == (SV*)vars.cv);
        REQUIRE(o.get<SV>() == (SV*)vars.cv);
        REQUIRE(o.get<CV>() == vars.cv);
        REQUIRE(SvREFCNT(vars.cv) == rcnt);
    }

    SECTION("stash") {
        Sub o("M1::dummy");
        REQUIRE(o.stash());
        REQUIRE(o.stash() == gv_stashpvs("M1", 0));
    }

    SECTION("glob") {
        Sub o("M1::dummy");
        REQUIRE(o.glob());
        REQUIRE(o.glob() == Stash("M1")["dummy"]);
    }

    SECTION("name") {
        Sub o("M1::dummy");
        REQUIRE(o.name() == string_view("dummy"));
    }

    SECTION("named") {
        Sub o("M1::dummy");
        REQUIRE(!o.named());
    }

    SECTION("call") {
        Stash s("M1");
        Sub sub = s.sub("dummy");
        Simple call_cnt = s.scalar("call_cnt");
        Simple call_ret = s.scalar("call_ret");
        int initial_cnt = call_cnt;

        SECTION("void") {
            SECTION("no args") {
                sub.call();
                REQUIRE(call_cnt == initial_cnt+1);
                sub.call();
                sub();
                REQUIRE(call_cnt == initial_cnt+3);
            }
            SECTION("SV*") {
                sub.call(Simple(111));
                REQUIRE(call_cnt == initial_cnt+1);
                REQUIRE(call_ret == 111);
                sub(Scalar());
                REQUIRE(call_cnt == initial_cnt+2);
                REQUIRE(call_ret == 0);
            }
            SECTION("SV**/items") {
                Simple arg1(10), arg2(2), arg3(3);
                SV* args[] = {arg1, arg2, arg3};
                sub(args, 3);
                REQUIRE(call_cnt == initial_cnt+1);
                REQUIRE(call_ret == 60);
            }
            SECTION("ilist") {
                sub({Simple(2), Scalar(Simple(3)), Sv(Simple(4))});
                REQUIRE(call_cnt == initial_cnt+1);
                REQUIRE(call_ret == 24);
            }
        }
        SECTION("scalar") {
            SECTION("no args") {
                Sv res = sub.call();
                REQUIRE(call_cnt == initial_cnt+1);
                REQUIRE(res.defined());
                REQUIRE(Simple(res).get<int>() == 0);
                REQUIRE(res.use_count() == 1);
            }
            SECTION("args") {
                Simple res = sub.call({Simple(2), Simple(3), Simple(4)});
                REQUIRE(call_cnt == initial_cnt+1);
                REQUIRE(Simple(res).get<int>() == 9);
                REQUIRE(res.use_count() == 1);
            }
        }
        SECTION("fixed-list array") {
            std::array<Simple,4> res = sub.call({Simple(2), Simple(3), Simple(4)});
            REQUIRE(call_cnt == initial_cnt+1);
            REQUIRE(res[0] == 10);
            REQUIRE(res[1] == 15);
            REQUIRE(res[2] == 20);
            REQUIRE(!res[3]);
        }
        SECTION("fixed-list tuple") {
            std::tuple<Sv,Simple,Simple,Ref> res = sub.call({Simple(5), Simple(6), Simple(7)});
            REQUIRE(call_cnt == initial_cnt+1);
            REQUIRE(Simple(get<0>(res)) == 25);
            REQUIRE(get<1>(res) == 30);
            REQUIRE(get<2>(res) == 35);
            REQUIRE(!get<3>(res));
        }
        SECTION("unlimited-list") {
            List res = sub.call({Simple(10), Simple(20), Simple(30)});
            REQUIRE(call_cnt == initial_cnt+1);
            REQUIRE(res.size() == 3);
            REQUIRE(Simple(res[0]) == 50);
            REQUIRE(Simple(res[1]) == 100);
            REQUIRE(Simple(res[2]) == 150);
        }
    }

    SECTION("super/super_strict") {
        Sub sub("M4::meth");
        sub = sub.SUPER();
        REQUIRE(sub == Sub("M2::meth"));
        sub = sub.SUPER_strict();
        REQUIRE(sub == Sub("M1::meth"));
        REQUIRE(!sub.SUPER());
        REQUIRE_THROWS(sub.SUPER_strict());
    }
}
