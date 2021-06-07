#include "test.h"
#include <array>
#include <utility>
#include <xs/function.h>

#define TEST(name) TEST_CASE("Sub: " name, "[Sub]")

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

TEST("ctor") {
    perlvars vars;
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
        SECTION("IO")        { Test::ctor((SV*)vars.io, behaviour_t::THROWS); }
    }
    SECTION("CV") { Test::ctor(vars.cv, behaviour_t::VALID); }

    SECTION("Sub")        { Test::ctor(Sub(vars.cv), behaviour_t::VALID); }
    SECTION("valid Sv")   { Test::ctor(Sv(vars.cv), behaviour_t::VALID); }
    SECTION("invalid Sv") { Test::ctor(Sv(vars.gv), behaviour_t::THROWS); }

    SECTION("from string") {
        static auto _a = eval_pv("package MyTest::Sub::CtorFromString; sub func {}", 1); (void)_a;
        Sub c("MyTest::Sub::CtorFromString::func");
        REQUIRE(c);
        REQUIRE(c.get<CV>() == get_cv("MyTest::Sub::CtorFromString::func", 0));
        Sub c2("MyTest::Sub::CtorFromString::nonexistent");
        REQUIRE(!c2);
        Sub c3("MyTest::Sub::CtorFromString::nonexistent", GV_ADD);
        REQUIRE(c3);
        REQUIRE(c3.get<CV>() == get_cv("MyTest::Sub::CtorFromString::nonexistent", 0));
    }
}

TEST("operator=") {
    perlvars vars;
    auto o = Sub::create("1;");
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
        SECTION("IO")        { Test::assign(o, (SV*)vars.io, behaviour_t::THROWS); }
    }
    SECTION("CV")         { Test::assign(o, vars.cv, behaviour_t::VALID); }
    SECTION("Sub")        { Test::assign(o, Sub(vars.cv), behaviour_t::VALID); }
    SECTION("valid Sv")   { Test::assign(o, Sv(vars.cv), behaviour_t::VALID); }
    SECTION("invalid Sv") { Test::assign(o, Sv(vars.gv), behaviour_t::THROWS); }
}

TEST("set") {
    perlvars vars;
    Sub o;
    o.set(vars.iv); // no checks
    REQUIRE(o);
    REQUIRE(SvREFCNT(vars.iv) == 2);
    REQUIRE(o.get() == vars.iv);
}

TEST("cast") {
    perlvars vars;
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

TEST("get") {
    perlvars vars;
    Sub o(vars.cv);
    auto rcnt = SvREFCNT(vars.cv);
    REQUIRE(o.get<>() == (SV*)vars.cv);
    REQUIRE(o.get<SV>() == (SV*)vars.cv);
    REQUIRE(o.get<CV>() == vars.cv);
    REQUIRE(SvREFCNT(vars.cv) == rcnt);
}

TEST("stash") {
    static auto _a = eval_pv("package MyTest::Sub::Stash; sub func {}", 1); (void)_a;
    Sub o("MyTest::Sub::Stash::func");
    REQUIRE(o.stash());
    REQUIRE(o.stash() == gv_stashpvs("MyTest::Sub::Stash", 0));
}

TEST("glob") {
    static auto _a = eval_pv("package MyTest::Sub::Glob; sub func {}", 1); (void)_a;
    Sub o("MyTest::Sub::Glob::func");
    REQUIRE(o.glob());
    REQUIRE(o.glob() == Stash("MyTest::Sub::Glob")["func"]);
}

TEST("name") {
    static auto _a = eval_pv("package MyTest::Sub::Name; sub func {}", 1); (void)_a;
    Sub o("MyTest::Sub::Name::func");
    REQUIRE(o.name() == "func");
}

TEST("named") {
    static auto _a = eval_pv("package MyTest::Sub::Named; sub func {}", 1); (void)_a;
    Sub o("MyTest::Sub::Named::func");
    REQUIRE(!o.named());
}

TEST("call args") {
    static auto _a = eval_pv(R"EOF(
        package MyTest::Sub::CallArgs;
        our $call_cnt = 0;

        sub check_args {
            $call_cnt++;
            return [@_]
        }
    )EOF", 1); (void)_a;

    Stash s("MyTest::Sub::CallArgs");
    auto sub        = s.sub("check_args");
    Simple call_cnt = s.scalar("call_cnt");
    call_cnt = 0;

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

TEST("call context") {
    static auto _a = eval_pv(R"EOF(
        package MyTest::Sub::CallContext;
        our $call_cnt = 0;
        our $call_ret;

        sub check_context {
            $call_cnt++;
            return @_ if wantarray();
            return $_[0] if defined wantarray();
            $call_ret = $_[0];
        }
    )EOF", 1); (void)_a;

    Stash s("MyTest::Sub::CallContext");
    auto sub        = s.sub("check_context");
    Simple call_cnt = s.scalar("call_cnt");
    Simple call_ret = s.scalar("call_ret");
    call_cnt = 0;

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

TEST("call result as argument") {
    auto sub = Sub::create("[@_]");
    Array ret = sub.call( sub.call(Simple(999)), sub.call(Simple(888), Simple(777)) );
    cmp_array(ret[0], {999});
    cmp_array(ret[1], {888, 777});
}

TEST("super/super_strict") {
    static auto _a = eval_pv(R"EOF(
        package MyTest::Sub::Super::Parent;
        sub func {}
        package MyTest::Sub::Super::Child;
        our @ISA = 'MyTest::Sub::Super::Parent';
        sub func {}
    )EOF", 1); (void)_a;

    auto psub = Sub("MyTest::Sub::Super::Child::func");
    auto sub = psub.SUPER();
    REQUIRE(sub == Sub("MyTest::Sub::Super::Parent::func"));
    REQUIRE(sub == psub.SUPER_strict());
    REQUIRE(!sub.SUPER());
    REQUIRE_THROWS(sub.SUPER_strict());
}

TEST("create from code") {
    auto sub = Sub::create("return shift() + 10");
    Simple res = sub.call(Simple(3));
    CHECK(res == 13);
}

TEST("want") {
    Sub::Want ret;
    panda::function<void()> f = [&ret]{ ret = Sub::want(); };
    auto sub = xs::out(f);
    SECTION("void") {
        Sub::create("$_[0]->(); return").call(sub);
        CHECK(ret == Sub::Want::Void);
    }
    SECTION("scalar") {
        Sub::create("my $a = $_[0]->()").call(sub);
        CHECK(ret == Sub::Want::Scalar);
    }
    SECTION("array") {
        Sub::create("my @a = $_[0]->()").call(sub);
        CHECK(ret == Sub::Want::Array);
    }
}

TEST("want_count") {
    int ret;
    panda::function<void()> f = [&ret]{ ret = Sub::want_count(); };
    auto sub = xs::out(f);
    SECTION("void") {
        Sub::create("$_[0]->(); return").call(sub);
        CHECK(ret == 0);
    }
    SECTION("scalar") {
        Sub::create("my $a = $_[0]->()").call(sub);
        CHECK(ret == 1);
    }
    SECTION("2-list") {
        Sub::create("my ($a,$b) = $_[0]->()").call(sub);
        CHECK(ret == 2);
        Sub::create("($a,$b) = $_[0]->()").call(sub);
        CHECK(ret == 2);
    }
    SECTION("2-list with junk") {
        Sub::create("my ($a,$b) = ($_[0]->(), 1)").call(sub);
        CHECK(ret == 2);
        Sub::create("my (undef,$b) = ($_[0]->(), 1)").call(sub);
        CHECK(ret == 2);
    }
    SECTION("3-list") {
        Sub::create("my ($a,$b,$c) = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("array slice list") {
        Sub::create("my @a; @a[0,1,2] = $_[0]->()").call(sub);
        CHECK(ret == 3);
        Sub::create("my @a; my $i1 = 1; my $i2 = 2; @a[0,$i1,$i2] = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("arrayref slice list") {
        Sub::create("my $a = []; @$a[0,1,2] = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("array slice dia") {
        Sub::create("my @a; @a[2..4] = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("array elem") {
        Sub::create("my @a; ($a[0], $a[1]) = $_[0]->()").call(sub);
        CHECK(ret == 2);
        Sub::create("my @a; my ($b,$c) = (0,1); ($a[$b], $a[$c]) = $_[0]->()").call(sub);
        CHECK(ret == 2);
    }
    SECTION("hash elem") {
        Sub::create("my %a; ($a{0}, $a{1}) = $_[0]->()").call(sub);
        CHECK(ret == 2);
        Sub::create("my %a; my ($b,$c) = (0,1); ($a{$b}, $a{$c}) = $_[0]->()").call(sub);
        CHECK(ret == 2);
    }
    SECTION("hash slice list") {
        Sub::create("my %a; @a{qw/a b c/} = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("hashref slice list") {
        Sub::create("my $a = {}; @$a{qw/a b c/} = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("hash slice dia") {
        Sub::create("my %a; @a{2..4} = $_[0]->()").call(sub);
        CHECK(ret == 3);
    }
    SECTION("complex") {
        Sub::create("my ($a, $b, @arr, %hash); ($a, @arr[0,1], @arr[2..4], @hash{qw/a b/}, @hash{0..2}, $b, $arr[5], $hash{10}) = $_[0]->()").call(sub);
        CHECK(ret == 14);
    }
    SECTION("infinite") {
        Sub::create("my @a = $_[0]->()").call(sub); CHECK(ret == -1);
        Sub::create("my ($a, @a) = $_[0]->()").call(sub); CHECK(ret == -1);
        Sub::create("my ($a, @a, $b) = $_[0]->()").call(sub); CHECK(ret == -1);
        Sub::create("my @a; my $i = 1; my $j = 3; @a[$i..$j] = $_[0]->()").call(sub); CHECK(ret == -1);
        Sub::create("my @a; my @b; @a[@b] = $_[0]->()").call(sub); CHECK(ret == -1);
        Sub::create("($a, substr($a,0,1)) = $_[0]->()").call(sub); CHECK(ret == -1);
        Sub::create("my ($a) = [ 1, $_[0]->() ]").call(sub); CHECK(ret == -1);
        Sub::create("my ($a) = { key => 'val', $_[0]->() }").call(sub); CHECK(ret == -1);
        Sub::create("my $a = sub {}; my ($b) = $a->($_[0]->())").call(sub); CHECK(ret == -1);
    }
    //SECTION("benchmark") {
    //    f = []{ for (int i = 0; i < 1000; ++i) Sub::want_count(); };
    //    auto sub = xs::out(f);
    //    Sub::create("use Benchmark; my $sub = shift; Benchmark::timethis(-1, sub { my ($a,$b) = $sub->()})").call(sub);
    //}
}
