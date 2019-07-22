#include <xs/function.h>
#include <catch.hpp>

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
        static RefOnly in (pTHX_ const Simple& arg) {
            return RefOnly(arg.as_string() + "_in");
        }
        static Sv out (pTHX_ RefOnly& v, const Sv& = {}) { return Simple(v.s + "_out"); }
    };

    template<> struct Typemap<RefAny> : TypemapBase<RefAny> {
        static RefAny in (pTHX_ const Simple& arg) {
            return RefAny(arg.as_string() + "_inV");
        }
        static Sv out (pTHX_ const RefAny& v, const Sv& = {}) { return Simple(v.s + "_outV"); }
    };

    template<> struct Typemap<RefAny&> : TypemapBase<RefAny&> {
        static RefAny& in (pTHX_ const Simple& arg) {
            static RefAny r("");
            r.s = arg.as_string() + "_inR";
            return r;
        }
        static Sv out (pTHX_ RefAny& v, const Sv& = {}) { return Simple(v.s + "_outR"); }
    };
}

using vv_fn   = function<void()>;
using vi_fn   = function<void(int)>;
using iid_fn  = function<int(int, double)>;

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
        iid_fn fn = [&](int i, double d) {
            CHECK(i == 42);
            CHECK(d == 3.14);
            cnt++;
            return 255;
        };
        Sub sub = xs::out(fn);
        Scalar ret = sub.call(Simple(42), Simple(3.14));
        CHECK(Simple(ret) == 255);
    }
    SECTION("int(int, double) custom") {
        ecnt = 1;
        iid_fn fn = [&](int i, double d) {
            CHECK(i == 842);
            CHECK(d == 3.14);
            cnt++;
            return 255;
        };
        auto sub = function2sub(fn,
            [](int r) { return Simple(r - 200); },
            [](const Sv& sv) { return (int)Simple(sv) + 800; }
        );
        Scalar ret = sub.call(Simple(42), Simple(3.14));
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
        struct Data {
            int i;
            Data (int i) : i(i) {}
        };
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

    CHECK(cnt == ecnt);
}
