#include <xs.h>
#include <catch.hpp>

using namespace xs;
using namespace panda;

namespace {
    struct RefOnly {
        string s;
        RefOnly (string s) : s(s) {}
    };

    struct ValOnly {
        string s;
        ValOnly (string s) : s(s) {}
    };

    struct RefAndVal {
        string s;
        RefAndVal (string s) : s(s) {}
    };

    struct PtrOnly {
        string s;
        PtrOnly (string s) : s(s) {}
    };

    struct PtrAndVal {
        string s;
        PtrAndVal (string s) : s(s) {}
    };

    struct RefAndPtr {
        string s;
        RefAndPtr (string s) : s(s) {}
    };
}

namespace xs {
    template<> struct Typemap<RefOnly&> : TypemapBase<RefOnly&> {
        static RefOnly& in  (pTHX_ const Simple& arg)          { static RefOnly r(""); r.s = arg.as_string() + "iR&"; return r; }
        static Sv       out (pTHX_ RefOnly& v, const Sv& = {}) { return Simple(v.s + "oR&"); }
    };

    template<> struct Typemap<ValOnly> : TypemapBase<ValOnly> {
        static ValOnly in  (pTHX_ const Simple& arg)                { return ValOnly(arg.as_string() + "iV"); }
        static Sv      out (pTHX_ const ValOnly& v, const Sv& = {}) { return Simple(v.s + "oV"); }
    };

    template<> struct Typemap<RefAndVal> : TypemapBase<RefAndVal> {
        static RefAndVal in  (pTHX_ const Simple& arg)                  { return RefAndVal(arg.as_string() + "iRV"); }
        static Sv        out (pTHX_ const RefAndVal& v, const Sv& = {}) { return Simple(v.s + "oRV"); }
    };
    template<> struct Typemap<RefAndVal&> : TypemapBase<RefAndVal&> {
        static RefAndVal& in  (pTHX_ const Simple& arg)            { static RefAndVal r(""); r.s = arg.as_string() + "iRV&"; return r; }
        static Sv         out (pTHX_ RefAndVal& v, const Sv& = {}) { return Simple(v.s + "oRV&"); }
    };

    template<> struct Typemap<PtrOnly*> : TypemapBase<PtrOnly*> {
        static PtrOnly* in  (pTHX_ const Simple& arg)          { static PtrOnly r("");  r.s = arg.as_string() + "iP*"; return &r; }
        static Sv       out (pTHX_ PtrOnly* v, const Sv& = {}) { return Simple(v->s + "oP*"); }
    };

    template<> struct Typemap<PtrAndVal> : TypemapBase<PtrAndVal> {
        static PtrAndVal in  (pTHX_ const Simple& arg)                  { return PtrAndVal(arg.as_string() + "iPV"); }
        static Sv        out (pTHX_ const PtrAndVal& v, const Sv& = {}) { return Simple(v.s + "oPV"); }
    };
    template<> struct Typemap<PtrAndVal*> : TypemapBase<PtrAndVal*> {
        static PtrAndVal* in  (pTHX_ const Simple& arg)            { static PtrAndVal r("");  r.s = arg.as_string() + "iPV*"; return &r; }
        static Sv         out (pTHX_ PtrAndVal* v, const Sv& = {}) { return Simple(v->s + "oPV*"); }
    };

    template<> struct Typemap<RefAndPtr&> : TypemapBase<RefAndPtr&> {
        static RefAndPtr& in  (pTHX_ const Simple& arg)            { static RefAndPtr r(""); r.s = arg.as_string() + "iRP&"; return r; }
        static Sv         out (pTHX_ RefAndPtr& v, const Sv& = {}) { return Simple(v.s + "oRP&"); }
    };
    template<> struct Typemap<RefAndPtr*> : TypemapBase<RefAndPtr*> {
        static RefAndPtr* in  (pTHX_ const Simple& arg)            { static RefAndPtr r("");  r.s = arg.as_string() + "iRP*"; return &r; }
        static Sv         out (pTHX_ RefAndPtr* v, const Sv& = {}) { return Simple(v->s + "oRP*"); }
    };
}

TEST_CASE("ref&", "[ref&]") {
    SECTION("ref only") {
        auto ret = out<RefOnly&>(in<RefOnly&>(Sv()));
        CHECK(Simple(ret) == "iR&oR&");
    }
    SECTION("val only") {
        auto ret = out<ValOnly>(in<ValOnly>(Sv()));
        CHECK(Simple(ret) == "iVoV");
        ret = out<ValOnly&>(in<ValOnly&>(Sv()));
        CHECK(Simple(ret) == "iVoV");
    }
    SECTION("ref and val") {
        auto ret = out<RefAndVal>(in<RefAndVal>(Sv()));
        CHECK(Simple(ret) == "iRVoRV");
        ret = out<RefAndVal&>(in<RefAndVal&>(Sv()));
        CHECK(Simple(ret) == "iRV&oRV&");
    }
    SECTION("ptr only") {
        auto ret = out<PtrOnly*>(in<PtrOnly*>(Sv()));
        CHECK(Simple(ret) == "iP*oP*");
        ret = out<PtrOnly*>(&in<PtrOnly&>(Sv()));
        CHECK(Simple(ret) == "iP*oP*");
    }
    SECTION("ptr and val") {
        auto ret = out<PtrAndVal>(in<PtrAndVal>(Sv()));
        CHECK(Simple(ret) == "iPVoPV");
        ret = out<PtrAndVal*>(in<PtrAndVal*>(Sv()));
        CHECK(Simple(ret) == "iPV*oPV*");
        ret = out<PtrAndVal*>(&in<PtrAndVal&>(Sv()));
        CHECK(Simple(ret) == "iPV*oPV*");
    }
    SECTION("ref and ptr") {
        auto ret = out<RefAndPtr*>(in<RefAndPtr*>(Sv()));
        CHECK(Simple(ret) == "iRP*oRP*");
        ret = out<RefAndPtr&>(in<RefAndPtr&>(Sv()));
        CHECK(Simple(ret) == "iRP&oRP&");
    }
}
