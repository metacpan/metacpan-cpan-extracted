#include <catch2/catch_test_macros.hpp>
#include <xs/function.h>
#include <thread>

using namespace xs;
using namespace panda;

struct RefOnly {
    string s;
    RefOnly (string s) : s(s) {}
};

struct RefAny {
    string s;
    RefAny (string s) : s(s) {}
};

namespace xs {
    template<> struct Typemap<RefOnly&> : TypemapBase<RefOnly&> {
        static RefOnly in (const Simple& arg) {
            return RefOnly(arg.as_string() + "_in");
        }
        static Sv out (RefOnly& v, const Sv& = {}) { return Simple(v.s + "_out"); }
    };

    template<> struct Typemap<RefAny> : TypemapBase<RefAny> {
        static RefAny in (const Simple& arg) {
            return RefAny(arg.as_string() + "_inV");
        }
        static Sv out (const RefAny& v, const Sv& = {}) { return Simple(v.s + "_outV"); }
    };

    template<> struct Typemap<RefAny&> : TypemapBase<RefAny&> {
        static RefAny& in (const Simple& arg) {
            static RefAny r("");
            r.s = arg.as_string() + "_inR";
            return r;
        }
        static Sv out (RefAny& v, const Sv& = {}) { return Simple(v.s + "_outR"); }
    };
}

using vv_fn  = function<void()>;
using vi_fn  = function<void(int)>;
using iid_fn = function<int(int, panda::string_view)>;
using iis_fn = function<int(int, panda::string_view)>;

struct Data {
    int i;
    Data (int i) : i(i) {}
};

TEST_CASE("sub->function", "[function]") {
    eval("$MyTest::_marker = undef");
    auto marker = Stash("MyTest")["_marker"].scalar();

    SECTION("void()") {
        auto fn = xs::in<vv_fn>(Sub::create("$MyTest::_marker = 1"));
        fn();
        CHECK(marker.is_true());
    }
    SECTION("void(int)") {
        auto fn = xs::in<vi_fn>(Sub::create("$MyTest::_marker = shift"));
        fn(42);
        CHECK(Simple(marker) == 42);
    }
    SECTION("void(int) custom") {
        auto sub = Sub::create("$MyTest::_marker = shift");
        auto fn = xs::sub2function<vi_fn>(sub, [](int val) { return Simple(val + 100); });
        fn(42);
        CHECK(Simple(marker) == 142);
    }
    SECTION("int(int,string_view)") {
        auto sub = Sub::create("$MyTest::_marker = [@_]; return 10");
        auto fn = xs::in<iis_fn>(sub);
        auto res = fn(42, "the string");
        CHECK(res == 10);
        CHECK(Simple(Array(marker)[0]) == 42);
        CHECK(Simple(Array(marker)[1]) == "the string");
    }
    SECTION("int(int,string_view) custom") {
        auto sub = Sub::create("$MyTest::_marker = [@_]; return 10");

        auto fn = xs::sub2function<iis_fn>(
            sub,
            [=](const Sv& sv) { return SvIV(sv) + 10; },
            [](int val)       { return Simple(val + 100); }
        );

        auto res = fn(42, "a string");
        CHECK(res == 20);
        CHECK(Simple(Array(marker)[0]) == 142);
        CHECK(Simple(Array(marker)[1]) == "a string");
    }
    SECTION("sub->function->sub") {
        auto src = Sub::create("$MyTest::_marker = shift");
        auto fn = xs::in<vi_fn>(src);
        Sub sub = xs::out(fn);
        CHECK(sub == src);
        sub.call(Simple(43));
        CHECK(Simple(marker) == 43);
    }
    SECTION("custom when no typemap") {
        auto sub = Sub::create("$MyTest::_marker = $_[0]; return $_[0] + 100");

        auto fn = sub2function<function<Data(const Data&)>>(
            sub,
            [=](const Sv& sv)     { return Data((int)Simple(sv) + 1); },
            [] (const Data& data) { return Simple(data.i + 2); }
        );

        auto ret = fn(Data(100));
        CHECK(ret.i == 203);
        CHECK(Simple(marker) == 102);
    }
    #ifdef USE_ITHREADS
    SECTION("with threads") {
        eval("require threads");
        Stash threads("threads");
        int tid = threads.call<Simple>("tid");
        auto sub = Sub::create("$MyTest::_marker = threads->tid(); return $_[0] + 10");
        auto fn = xs::in<function<int(int)>>(sub);

        auto res = fn(1);
        CHECK(res == 11);
        CHECK(Simple(marker) == tid);

        function<void()> thr_fn = [&] { res = fn(2); };

        // fn() must call correct sub (from correct interpreter thread)
        Stash("threads").call<Object>("create", xs::out(thr_fn)).call("join");
        CHECK(res == 12);
        CHECK(Simple(marker) == tid); // marker in master thread should not be changed

        // check that fn() is not corrupted by svt_dup or svt_free
        res = fn(3);
        CHECK(res == 13);
        CHECK(Simple(marker) == tid);
    }
    #endif
}

TEST_CASE("function->sub", "[function]") {
    int ecnt = 0;
    int cnt = 0;
    SECTION("void()") {
        ecnt = 1;
        vv_fn fn = [&](){ cnt++; };
        auto sub = function2sub(fn);
        sub.call<void>();
    }
    SECTION("void(int)") {
        ecnt = 1;
        vi_fn fn = [&](int val) {
            CHECK(val == 42);
            cnt++;
        };
        auto sub = function2sub(fn);
        sub.call<void>(Simple(42));
    }
    SECTION("void(int) custom") {
        ecnt = 1;
        vi_fn fn = [&](int val) {
            CHECK(val == 942);
            cnt++;
        };
        auto sub = function2sub(fn, [](const Sv& sv){ return (int)Simple(sv) + 900; });
        sub.call<void>(Simple(42));
    }
    SECTION("int(int, double)") {
        ecnt = 1;
        iid_fn fn = [&](int i, panda::string_view d) {
            CHECK(i == 42);
            CHECK(d == "hello");
            cnt++;
            return 255;
        };
        Sub sub = xs::out(fn);
        Scalar ret = sub.call(Simple(42), Simple("hello"));
        CHECK(Simple(ret) == 255);
    }
    SECTION("int(int, double) custom") {
        ecnt = 1;
        iid_fn fn = [&](int i, panda::string_view d) {
            CHECK(i == 842);
            CHECK(d == "hi");
            cnt++;
            return 255;
        };
        auto sub = function2sub(fn,
            [](int r) { return Simple(r - 200); },
            [](const Sv& sv) { return (int)Simple(sv) + 800; }
        );
        Scalar ret = sub.call(Simple(42), Simple("hi"));
        CHECK(Simple(ret) == 55);
    }
    SECTION("function->sub->function") {
        ecnt = 2;
        vi_fn fn = [&](int val) {
            CHECK(val == 42);
            cnt++;
        };
        auto sub = function2sub(fn);
        sub.call<void>(Simple(42));
        auto fn2 = xs::in<vi_fn>(sub);
        fn2(42);
        CHECK(fn == fn2);
    }
    SECTION("removing references") {
        ecnt = 1;
        function<void(int&)> fn = [&](int& val) {
            CHECK(val == 42);
            cnt++;
        };
        auto sub = function2sub(fn);
        sub.call<void>(Simple(42));
    }
    SECTION("custom when no typemap") {
        function<Data(const Data&)> fn = [&](const Data& data) { return data.i + 100; };
        auto sub = function2sub(fn,
            [](const Data& data) { return Simple(data.i + 1000); },
            [](const Sv& sv)     { return Data((int)Simple(sv) + 10); }
        );
        Scalar ret = sub.call(Simple(1));
        CHECK(Simple(ret) == 1111);
    }
    SECTION("use ref typemap when it exists") {
        SECTION("exists only ref typemap") {
            using ref_fn  = function<RefOnly&(RefOnly&)>;
            ref_fn fn = [](RefOnly& v) -> RefOnly& { v.s += "_call"; return v; };
            auto sub = function2sub(fn);
            Scalar ret = sub.call(Simple("hello"));
            CHECK(Simple(ret) == "hello_in_call_out");
        }
        SECTION("prefer ref when both exists") {
            using val_fn = function<RefAny(RefAny)>;
            val_fn vfn = [](const RefAny& v) -> RefAny { return RefAny(v.s + "_call"); };
            auto sub = function2sub(vfn);
            Scalar ret = sub.call(Simple("hello"));
            CHECK(Simple(ret) == "hello_inV_call_outV");

            using ref_fn = function<RefAny&(RefAny&)>;
            ref_fn rfn = [](RefAny& v) -> RefAny& { v.s += "_call"; return v; };
            sub = function2sub(rfn);
            ret = sub.call(Simple("hello"));
            CHECK(Simple(ret) == "hello_inR_call_outR");
        }
    }
    #ifdef USE_ITHREADS
    SECTION("with threads") {
        std::thread::id id;
        eval("require threads");
        function<int()> fn = [&]{ id = std::this_thread::get_id(); return 55; };
        Sub sub = xs::out(fn);
        // sub must clone it's magic ptr on svt_dup
        Object thr = Stash("threads").call("create", Ref::create(sub));
        Simple res = thr.call("join");
        CHECK(res == 55);
        CHECK(id != std::this_thread::get_id());
        //check that sub isn't broken by svt_dup
        res = sub.call();
        CHECK(res == 55);
        CHECK(id == std::this_thread::get_id());
    }
    #endif

    CHECK(cnt == ecnt);
}

//uint64_t bench_vv (Sub sub, int cnt) {
//    RETVAL = 0;
//    for (int i = 0; i < cnt; ++i) {
//        RETVAL += (uint64_t)sub2function<vv_fn>(sub).func.get();
//    }
//}
//
//uint64_t bench_vi (Sub sub, int cnt) {
//    RETVAL = 0;
//    for (int i = 0; i < cnt; ++i) {
//        RETVAL += (uint64_t)sub2function<vi_fn>(sub).func.get();
//    }
//}
//
//uint64_t bench_iis (Sub sub, int cnt) {
//    RETVAL = 0;
//    for (int i = 0; i < cnt; ++i) {
//        RETVAL += (uint64_t)sub2function<iis_fn>(sub).func.get();
//    }
//}
//
//uint64_t bench_vvR (int cnt) {
//    RETVAL = 0;
//    vv_fn fn = [](){};
//    for (int i = 0; i < cnt; ++i) {
//        RETVAL += (uint64_t)function2sub(fn).get();
//    }
//}
//
//uint64_t bench_viR (int cnt) {
//    RETVAL = 0;
//    vi_fn fn = [](int){};
//    for (int i = 0; i < cnt; ++i) {
//        RETVAL += (uint64_t)function2sub(fn).get();
//    }
//}
//
//uint64_t bench_iisR (int cnt) {
//    RETVAL = 0;
//    iis_fn fn = [](int a, string_view d) -> int { return a + d.length(); };
//    for (int i = 0; i < cnt; ++i) {
//        RETVAL += (uint64_t)function2sub(fn).get();
//    }
//}
