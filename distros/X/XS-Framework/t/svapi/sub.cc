#include "test.h"
#include <array>
#include <utility>

using Test = TestSv<Sub>;

void cmp_array (const Array& a, const std::initializer_list<int>& l) {
    REQUIRE(a.size() == l.size());
    auto chk = l.begin();
    for (size_t i = 0; i < l.size(); ++i) CHECK(a[i] == chk[i]);
}

template <class T, size_t N>
void cmp_array (const std::array<T,N>& a, const std::initializer_list<int>& l) {
    REQUIRE(a.size() == l.size());
    auto chk = l.begin();
    for (size_t i = 0; i < l.size(); ++i) CHECK(a[i] == chk[i]);
}

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
        REQUIRE(o.name() == "dummy");
    }

    SECTION("named") {
        Sub o("M1::dummy");
        REQUIRE(!o.named());
    }

    SECTION("call") {
        Stash s("M1");
        Simple call_cnt = s.scalar("call_cnt");
        Simple call_ret = s.scalar("call_ret");
        call_cnt = 0;

        SECTION("args") {
            auto sub = s.sub("check_args");
            SECTION("empty") {
                cmp_array(sub.call(), {});
                CHECK(call_cnt == 1);
                cmp_array(sub(), {});
                CHECK(call_cnt == 2);
            }
            SECTION("SV*") {
                cmp_array(sub.call(Simple(999).get()), {999});
            }
            SECTION("SV**") {
                Simple arg1(100), arg2(200);
                SV* args[] = {arg1, arg2};
                cmp_array(sub.call(args, 2), {100, 200});
            }
            SECTION("SV* + SV**") {
                Simple arg1(100), arg2(200), arg3(300);
                SV* args[] = {arg2, arg3};
                cmp_array(sub.call(Simple(100).get(), args, 2), {100, 200, 300});
            }
            SECTION("const Scalar*") {
                Scalar args[] = {Simple(111), Simple(222)};
                cmp_array(sub.call(args, 2), {111, 222});
            }
            SECTION("SV* + const Scalar*") {
                Scalar args[] = {Simple(111), Simple(222)};
                cmp_array(sub.call(Simple(666).get(), args, 2), {666, 111, 222});
            }
            SECTION("ilist") {
                std::initializer_list<Scalar> l = {Simple(123), Simple(321)};
                cmp_array(sub.call(l), {123, 321});
            }
            SECTION("SV* + ilist") {
                std::initializer_list<Scalar> l = {Simple(300), Simple(400)};
                cmp_array(sub.call(Simple(7).get(), l), {7, 300, 400});
            }
            SECTION("variadic-1") {
                Simple arg(10);
                cmp_array(sub.call(arg), {10});
                CHECK(arg.use_count() == 1); // check for argument leaks
            }
            SECTION("variadic-2") {
                cmp_array(sub.call(Simple(10), Simple(20)), {10, 20});
            }
            SECTION("variadic-3") {
                cmp_array(sub.call(Simple(10), Simple(20), Scalar(Simple(100))), {10, 20, 100});
            }
            SECTION("variadic-4") {
                cmp_array(sub.call(Simple(10), Simple(20), Scalar(Simple(100)), Sv(Simple(200))), {10, 20, 100, 200});
            }
            SECTION("empty/nullptr -> undef") {
                Array ret = sub.call(Simple(10), nullptr, Simple());
                CHECK(ret.use_count() == 1); // check for retval leaks
                REQUIRE(ret.size() == 3);
                CHECK(ret[0] == 10);
                CHECK(!ret[1].defined());
                CHECK(!ret[2].defined());
            }
        }

        SECTION("context") {
            auto sub = s.sub("check_context");
            SECTION("void") {
                static_assert(std::is_same<decltype(sub.call<void>()),void>::value, "wrong signature");
                sub.call<void>(Simple(333));
                CHECK(call_cnt == 1);
                CHECK(call_ret == 333);
            }
            SECTION("scalar") {
                static_assert(std::is_same<decltype(sub.call()),Scalar>::value, "wrong signature");
                static_assert(std::is_same<decltype(sub.call<Scalar>()),Scalar>::value, "wrong signature");
                static_assert(std::is_same<decltype(sub.call<Simple>()),Simple>::value, "wrong signature");
                CHECK(sub.call(Simple(999)) == 999);
                CHECK(sub.call(Simple(999), Simple(111)) == 999);
                CHECK(!sub.call().defined());
            }
            SECTION("fixed-list array") {
                static_assert(std::is_same<decltype(sub.call<std::array<Simple,3>>()),std::array<Simple,3>>::value, "wrong signature");
                cmp_array(sub.call<std::array<Simple,3>>(Simple(1), Simple(2), Simple(3)), {1,2,3});
                cmp_array(sub.call<std::array<Simple,2>>(Simple(4), Simple(5), Simple(6)), {4,5});
                cmp_array(sub.call<std::array<Simple,4>>(Simple(7), Simple(8), Simple(9)), {7,8,9,0});
            }
            SECTION("fixed-list tuple") {
                using Tuple = std::tuple<Sv,Simple,Simple,Ref>;
                static_assert(std::is_same<decltype(sub.call<Tuple>()),Tuple>::value, "wrong signature");
                static_assert(std::is_same<decltype(sub.call<Sv,Simple,Simple,Ref>()),Tuple>::value, "wrong signature");
                SECTION("explicit") {
                    Tuple res = sub.call<Tuple>(Simple(10), Simple(20), Simple(30));
                    CHECK(Simple(std::get<0>(res)) == 10);
                    CHECK(std::get<1>(res) == 20);
                    CHECK(std::get<2>(res) == 30);
                    CHECK(!std::get<3>(res));
                }
                SECTION("implicit") {
                    Tuple res = sub.call<Sv,Simple,Simple,Ref>(Simple(50), Simple(60), Simple(70), Ref::create(Simple(111)), Simple(999));
                    CHECK(Simple(std::get<0>(res)) == 50);
                    CHECK(std::get<1>(res) == 60);
                    CHECK(std::get<2>(res) == 70);
                    auto ref = std::get<3>(res);
                    CHECK(ref);
                    CHECK(ref.value<Scalar>() == 111);
                }
            }
            SECTION("unlimited-list") {
                static_assert(std::is_same<decltype(sub.call<List>()),List>::value, "wrong signature");
                cmp_array(sub.call<List>(Simple(10), Simple(20), Simple(30)), {10, 20, 30});
            }
            SECTION("panda::string") {
                static_assert(std::is_same<decltype(sub.call<panda::string>()),panda::string>::value, "wrong signature");
                auto str = sub.call<panda::string>(Simple("suka"));
                CHECK(str == "suka");
            }
            SECTION("numeric") {
                static_assert(std::is_same<decltype(sub.call<int>()),int>::value, "wrong signature");
                static_assert(std::is_same<decltype(sub.call<double>()),double>::value, "wrong signature");
                CHECK(sub.call<int>(Simple(200)) == 200);
                CHECK(sub.call<double>(Simple(1.234)) == 1.234);
                CHECK(sub.call<long long>(Simple(1.234)) == 1);
            }
        }

        SECTION("call result as argument") {
            auto sub = s.sub("check_args");
            Array ret = sub.call( sub.call(Simple(999)), sub.call(Simple(888), Simple(777)) );
            cmp_array(ret[0], {999});
            cmp_array(ret[1], {888, 777});
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
