#include "test.h"

using Test = TestSv<Stash>;
using panda::string_view;

TEST_CASE("Stash", "[Sv]") {
    perlvars vars;
    Stash my(vars.stash);
    Hash h_valid(vars.stash), h_invalid(vars.hv);
    Sv oth_valid(vars.stash), oth_invalid(vars.hv);
    my.erase("test");

    SECTION("ctor") {
        SECTION("empty") {
            Stash o;
            REQUIRE(!o);
        }
        SECTION("SV") {
            SECTION("undef SV")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("AV")        { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")       { Test::ctor((SV*)vars.ohv, behaviour_t::THROWS); }
            SECTION("SHV")       { Test::ctor((SV*)vars.stash, behaviour_t::VALID); }
            SECTION("CV")        { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")        { Test::ctor((SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("HV")  { Test::ctor(vars.hv, behaviour_t::THROWS); }
        SECTION("OHV") { Test::ctor(vars.ohv, behaviour_t::THROWS); }
        SECTION("SHV") { Test::ctor(vars.stash, behaviour_t::VALID); }
        SECTION("string") {
            Stash o("MyTest");
            REQUIRE(o);
            REQUIRE(o == gv_stashpvs("MyTest", 0));
        }

        SECTION("Stash")        { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Hash")   { Test::ctor(h_valid, behaviour_t::VALID); }
        SECTION("invalid Hash") { Test::ctor(h_invalid, behaviour_t::THROWS); }
        SECTION("valid Sv")     { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv")   { Test::ctor(oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("operator=") {
        Stash o(gv_stashpvs("MyTest::__Dummy", GV_ADD));
        SECTION("SV") {
            SECTION("undef SV")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("AV")        { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("OHV")       { Test::assign(o, (SV*)vars.ohv, behaviour_t::THROWS); }
            SECTION("SHV")       { Test::assign(o, (SV*)vars.stash, behaviour_t::VALID); }
            SECTION("CV")        { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")        { Test::assign(o, (SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("HV")           { Test::assign(o, vars.hv, behaviour_t::THROWS); }
        SECTION("OHV")          { Test::assign(o, vars.ohv, behaviour_t::THROWS); }
        SECTION("SHV")          { Test::assign(o, vars.stash, behaviour_t::VALID); }
        SECTION("Stash")        { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Hash")   { Test::assign(o, h_valid, behaviour_t::VALID); }
        SECTION("invalid Hash") { Test::assign(o, h_invalid, behaviour_t::THROWS); }
        SECTION("valid Sv")     { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv")   { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Stash o;
        SECTION("SV") {
            auto cnt = SvREFCNT(vars.iv);
            o.set(vars.iv); // no checks
            REQUIRE(o);
            REQUIRE(SvREFCNT(vars.iv) == cnt+1);
            REQUIRE(o.get() == vars.iv);
        }
        SECTION("HV") {
            auto cnt = SvREFCNT(vars.hv);
            o.set(vars.hv); // no checks
            REQUIRE(o);
            REQUIRE(SvREFCNT(vars.hv) == cnt+1);
            REQUIRE(o.get<HV>() == vars.hv);
        }
    }

    SECTION("cast") {
        Stash o(vars.stash);
        auto rcnt = SvREFCNT(vars.stash);
        SECTION("to SV") {
            SV* sv = o;
            REQUIRE(sv == (SV*)vars.stash);
            REQUIRE(SvREFCNT(vars.stash) == rcnt);
        }
        SECTION("to HV") {
            HV* sv = o;
            REQUIRE(sv == vars.stash);
            REQUIRE(SvREFCNT(vars.stash) == rcnt);
        }
    }

    SECTION("get") {
        Stash o(vars.stash);
        auto rcnt = SvREFCNT(vars.stash);
        REQUIRE(o.get<>() == (SV*)vars.stash);
        REQUIRE(o.get<SV>() == (SV*)vars.stash);
        REQUIRE(o.get<HV>() == vars.stash);
        REQUIRE(SvREFCNT(vars.stash) == rcnt);
    }

    SECTION("name/effective_name") {
        REQUIRE(my.name() == "M1");
        REQUIRE(my.effective_name() == "M1");
    }

    SECTION("fetch") {
        auto glob = my.fetch("method");
        REQUIRE(glob);
        REQUIRE(glob.sub() == get_cv("M1::method", 0));
    }

    SECTION("[]const") {
        const Stash& o = my;
        auto glob = o["method"];
        REQUIRE(glob);
        REQUIRE(glob.sub() == get_cv("M1::method", 0));
    }

    SECTION("at") {
        auto glob = my.at("method");
        REQUIRE(glob);
        REQUIRE(glob.sub() == get_cv("M1::method", 0));
        REQUIRE_THROWS(my.at("jopa"));
    }

    SECTION("[]=") {
        SECTION("nullptr") {
            my["test"].scalar(Simple(10));
            REQUIRE(my.fetch("test").scalar());
            my["test"] = nullptr;
            REQUIRE(!my.fetch("test").scalar());
        }
        SECTION("SV") {
            SECTION("undef") {
                auto v = Sv::create();
                my["test"] = v.get();
                REQUIRE(my["test"].scalar() == v);
            }
            SECTION("simple") {
                Simple v(100);
                my["test"] = v.get();
                REQUIRE(my["test"].scalar() == v);
            }
            SECTION("AV") {
                auto v = Array::create();
                my["test"] = v.get();
                REQUIRE(my["test"].array() == v);
            }
            SECTION("HV") {
                auto v = Hash::create();
                my["test"] = v.get();
                REQUIRE(my["test"].hash() == v);
            }
            SECTION("CV") {
                Sub v(vars.cv);
                my["test"] = v.get();
                REQUIRE(my["test"].sub() == v);
            }
            SECTION("GV") {
                auto v = my["method"];
                my["test"] = v.get();
                REQUIRE(my["test"] == v);
            }
        }
        SECTION("AV") {
            auto v = Array::create();
            my["test"] = v.get<AV>();
            REQUIRE(my["test"].array() == v);
        }
        SECTION("HV") {
            auto v = Hash::create();
            my["test"] = v.get<HV>();
            REQUIRE(my["test"].hash() == v);
        }
        SECTION("CV") {
            Sub v(vars.cv);
            my["test"] = v.get<CV>();
            REQUIRE(my["test"].sub() == v);
        }
        SECTION("GV") {
            auto v = my["method"];
            my["test"] = v.get<GV>();
            REQUIRE(my["test"] == v);

            my.erase("test");
            auto o = my["test"];
            o.scalar(Simple(100));
            o.array(Array::create());
            o.hash(Hash::create());
            o.sub(Sub(vars.cv));
            my["test"] = (GV*)NULL;
            REQUIRE(!my["test"].scalar());
            REQUIRE(!my["test"].array());
            REQUIRE(!my["test"].hash());
            REQUIRE(!my["test"].sub());
        }
        SECTION("Sv") {
            Sv v = Simple(100);
            my["test"] = v;
            REQUIRE(my["test"].scalar() == v);
            v = Array::create();
            my["test"] = v;
            REQUIRE(my["test"].array() == v);
        }
        SECTION("Scalar") {
            Scalar v = Simple(222);
            my["test"] = v;
            REQUIRE(my["test"].scalar() == v);
        }
        SECTION("Ref") {
            Ref v = Ref::create(Simple(100));
            my["test"] = v;
            REQUIRE(my["test"].scalar() == v);
        }
        SECTION("Simple") {
            Simple v(222);
            my["test"] = v;
            REQUIRE(my["test"].scalar() == v);
        }
        SECTION("Array") {
            auto v = Array::create();
            my["test"] = v;
            REQUIRE(my["test"].array() == v);
        }
        SECTION("Hash") {
            auto v = Hash::create();
            my["test"] = v;
            REQUIRE(my["test"].hash() == v);
        }
        SECTION("Stash") {
            auto v = Stash(vars.stash);
            my["test"] = v;
            REQUIRE(my["test"].hash() == v);
        }
        SECTION("Sub") {
            Sub v(vars.cv);
            my["test"] = v;
            REQUIRE(my["test"].sub() == v);
        }
        SECTION("Object") {
            Object v(vars.ov);
            my["test"] = v;
            REQUIRE(my["test"].scalar() == v);
            v = vars.oav;
            my["test"] = v;
            REQUIRE(my["test"].array() == v);
        }
        SECTION("Glob") {
            my["test"] = my["method"];
            REQUIRE(my["test"] == my.fetch("method"));
            REQUIRE(my.fetch("test").sub() == get_cv("M1::method", 0));

            my.erase("test");
            auto o = my["test"];
            o.scalar(Simple(100));
            o.array(Array::create());
            o.hash(Hash::create());
            o.sub(Sub(vars.cv));
            my["test"] = Glob();
            REQUIRE(!my["test"].scalar());
            REQUIRE(!my["test"].array());
            REQUIRE(!my["test"].hash());
            REQUIRE(!my["test"].sub());
        }
    }

    SECTION("store") {
        my.store("test", my["method"]);
        REQUIRE(my.fetch("test"));
        REQUIRE(my.fetch("test").sub() == get_cv("M1::method", 0));
        my.erase("test");
        my.store("test", vars.iv);
        REQUIRE(my.fetch("test"));
        REQUIRE(my.fetch("test").scalar() == vars.iv);
    }

    SECTION("const sub promote") {
        Hash(my).store("test", Ref::create(Simple(1)));
        REQUIRE(my.fetch("test"));
        REQUIRE(my.fetch("test").sub() == get_cv("M1::test", 0));
    }

    SECTION("sub promote") {
        Hash(my).store("test", get_sv("M1::anon", 0));
        REQUIRE(my.fetch("test"));
        REQUIRE(my.fetch("test").sub() == get_cv("M1::test", 0));
    }

    SECTION("scalar") {
        REQUIRE(!my.scalar("jopa"));
        auto v = Simple(333);
        my.scalar("test", v);
        REQUIRE(my["test"].scalar() == v);
        REQUIRE(my.scalar("test") == v);
    }

    SECTION("array") {
        REQUIRE(!my.array("jopa"));
        auto v = Array::create();
        my.array("test", v);
        REQUIRE(my["test"].array() == v);
        REQUIRE(my.array("test") == v);
    }

    SECTION("hash") {
        REQUIRE(!my.hash("jopa"));
        auto v = Hash::create();
        my.hash("test", v);
        REQUIRE(my["test"].hash() == v);
        REQUIRE(my.hash("test") == v);
    }

    SECTION("sub") {
        REQUIRE(!my.sub("jopa"));
        auto v = Sub(vars.cv);
        my.sub("test", v);
        REQUIRE(my["test"].sub() == v);
        REQUIRE(my.sub("test") == v);
    }

    SECTION("path") {
        Stash o("AA::BB::CC", GV_ADD);
        REQUIRE(o.path() == "AA/BB/CC.pm");
    }

    SECTION("mark_as_loaded") {
        Stash o("M1");
        o.mark_as_loaded(Stash("MyTest"));
        REQUIRE(Stash::root().hash("INC").fetch(o.path()).is_true());
        REQUIRE_THROWS(o.mark_as_loaded(Stash("Nonexistent")));
    }

    SECTION("inherit") {
        Stash o("M_INH", GV_ADD);
        o.mark_as_loaded(Stash("MyTest"));
        o.inherit(Stash("M1"));
        auto ISA = o.array("ISA");
        REQUIRE(Simple(ISA[0]) == "M1");
    }

    SECTION("method/method_strict") {
        Stash o("M2");
        REQUIRE(o.method("child_method"));
        REQUIRE(o.method("child_method") == get_cv("M2::child_method", 0));
        REQUIRE(o.method("child_method") == o.method_strict("child_method"));
        REQUIRE(o.method("method"));
        REQUIRE(o.method("method") == get_cv("M1::method", 0));
        REQUIRE(o.method("method") == o.method_strict("method"));
        REQUIRE(!o.method("nomethod"));
        REQUIRE_THROWS(o.method_strict("nomethod"));
    }

    SECTION("name_hek") {
        auto hek = my.name_hek();
        REQUIRE(HEK_KEY(hek) == my.name().data());
    }

    SECTION("name_sv") {
        auto nm = my.name_sv();
        REQUIRE((string_view)nm == my.name());
        REQUIRE(nm.c_str() == my.name().data());
    }

    SECTION("isa") {
        Stash o("M2");
        REQUIRE(o.isa("M1"));
        REQUIRE(o.isa(Stash("M1")));
        REQUIRE(!o.isa("M254"));
        REQUIRE(!o.isa(Stash("M255", GV_ADD)));
    }

    SECTION("bless") {
        Stash st("MyTest");
        Simple obase(100);
        SECTION("SV") {
            auto o = st.bless(obase);
            REQUIRE(o);
            REQUIRE(o == obase);
            REQUIRE(o.stash() == st);
        }
        SECTION("RV") {
            auto r = Ref::create(obase);
            auto o = st.bless(r);
            REQUIRE(o);
            REQUIRE(o == obase);
            REQUIRE(o.stash() == st);
            REQUIRE(o.ref() == r);
        }
    }

    SECTION("call") {
        Simple ret = my.call("class_method");
        REQUIRE(ret);
        REQUIRE(ret == string_view("M1-hi"));
        my.call<void>("class_method", (SV**)NULL, 0);
        my.call<void>("class_method", (SV*)NULL);
        my.call<void>("class_method", Sv());
        my.call<Sv>("class_method");
    }

    SECTION("call_next/super/SUPER") {
        Stash s("M4");
        Sub sub = s.method("meth");
        Simple res;

        SECTION("SUPER") {
            res = s.call_SUPER(sub);
            REQUIRE(res == "M4-2");
            sub = sub.SUPER_strict();
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = s.call_SUPER(sub);
            REQUIRE(res == "M4-1");
            sub = sub.SUPER_strict();
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!sub.SUPER());
            REQUIRE_THROWS(sub.SUPER_strict());
            REQUIRE_THROWS(s.call_SUPER<void>(sub));
        }

        SECTION("next") {
            res = s.call_next(sub);
            REQUIRE(res == "M4-2");
            sub = s.next_method_strict(sub);
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = s.call_next(sub);
            REQUIRE(res == "M4-3");
            sub = s.next_method_strict(sub);
            REQUIRE(sub == get_cv("M3::meth", 0));

            res = s.call_next(sub);
            REQUIRE(res == "M4-1");
            sub = s.next_method_strict(sub);
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!s.next_method(sub));
            REQUIRE_THROWS(s.next_method_strict(sub));
            REQUIRE_THROWS(s.call_next<void>(sub));
        }

        SECTION("next_maybe") {
            res = s.call_next_maybe(sub);
            REQUIRE(res == "M4-2");
            sub = s.next_method(sub);

            res = s.call_next_maybe(sub);
            REQUIRE(res == "M4-3");
            sub = s.next_method(sub);

            res = s.call_next_maybe(sub);
            REQUIRE(res == "M4-1");
            sub = s.next_method(sub);

            res = s.call_next_maybe(sub);
            REQUIRE(!res);
        }

        SECTION("super/dfs") {
            res = s.call_super(sub);
            REQUIRE(res == "M4-2");
            sub = s.super_method_strict(sub);
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = s.call_super(sub);
            REQUIRE(res == "M4-1");
            sub = s.super_method_strict(sub);
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!s.super_method(sub));
            REQUIRE_THROWS(s.super_method_strict(sub));
            REQUIRE_THROWS(s.call_super<void>(sub));
        }

        SECTION("super/c3") {
            s.call<void>("enable_c3");

            res = s.call_super(sub);
            REQUIRE(res == "M4-2");
            sub = s.super_method_strict(sub);
            REQUIRE(sub == get_cv("M2::meth", 0));

            res = s.call_super(sub);
            REQUIRE(res == "M4-3");
            sub = s.super_method_strict(sub);
            REQUIRE(sub == get_cv("M3::meth", 0));

            res = s.call_super(sub);
            REQUIRE(res == "M4-1");
            sub = s.super_method_strict(sub);
            REQUIRE(sub == get_cv("M1::meth", 0));

            REQUIRE(!s.super_method(sub));
            REQUIRE_THROWS(s.super_method_strict(sub));
            REQUIRE_THROWS(s.call_super<void>(sub));

            s.call<void>("disable_c3");
        }

        SECTION("super_maybe") {
            res = s.call_super_maybe(sub);
            REQUIRE(res == "M4-2");
            sub = s.super_method(sub);

            res = s.call_super_maybe(sub);
            REQUIRE(res == "M4-1");
            sub = s.super_method(sub);

            res = s.call_super_maybe(sub);
            REQUIRE(!res);
        }
    }

    SECTION("add_const_sub") {
        Stash st(vars.stash);
        REQUIRE(!st.fetch("MYCONST"));

        SECTION("scalar") {
            Simple v(123);
            st.add_const_sub("MYCONST", v);
            REQUIRE(v.use_count() == 2);
            REQUIRE(st.fetch("MYCONST"));
            auto s = st["MYCONST"].sub();
            REQUIRE(s);
            Simple v2 = s.call();
            REQUIRE(v2 == v.get());
        }
        SECTION("array") {
            Array v({ Simple(1), Simple(2), Simple(3) });
            st.add_const_sub("MYCONST", v);
            REQUIRE(v.use_count() == 2);
            auto res = st["MYCONST"].sub().call<List>();
            REQUIRE(res.size() == v.size());
            REQUIRE(res != v);
            REQUIRE(res[0] == v[0]);
            REQUIRE(res[1] == v[1]);
            REQUIRE(res[2] == v[2]);
        }

        st.erase("MYCONST");
        REQUIRE(!st.fetch("MYCONST"));
    }
}
