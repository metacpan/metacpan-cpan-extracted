#include <xs.h>
#include <xs/Scope.h>
using namespace xs;
using namespace panda;

static void xs_hints_set (pTHX_ CV*) {
    dVAR; dXSARGS;
    if (items != 2) croak("epta!");
    auto name = xs::in<string_view>(ST(0));
    auto val  = ST(1);
    Scope::Hints::set(name, val);
    XSRETURN(0);
}

static void xs_hints_exists (pTHX_ CV*) {
    dVAR; dXSARGS;
    if (items != 1) croak("epta!");
    auto name = xs::in<string_view>(ST(0));
    auto ret = Scope::Hints::exists(name);
    ST(0) = ret ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static void xs_hints_get (pTHX_ CV*) {
    dVAR; dXSARGS;
    if (items != 1) croak("epta!");
    auto name = xs::in<string_view>(ST(0));
    auto ret = Scope::Hints::get(name);
    ST(0) = ret.detach_mortal();
    XSRETURN(1);
}

static void xs_hints_remove (pTHX_ CV*) {
    dVAR; dXSARGS;
    if (items != 1) croak("epta!");
    auto name = xs::in<string_view>(ST(0));
    Scope::Hints::remove(name);
    XSRETURN(0);
}

static void xs_hints_get_hash (pTHX_ CV*) {
    dVAR; dXSARGS;
    if (items != 0) croak("epta!");
    auto ret = Scope::Hints::get();
    EXTEND(SP, 1);
    ST(0) = Ref::create(ret).detach_mortal();
    XSRETURN(1);
}

static void xs_hints_get_ct (pTHX_ CV*) {
    dVAR; dXSARGS;
    if (items != 1) croak("epta!");
    auto name = xs::in<string_view>(ST(0));
    auto ret = Scope::Hints::get_ct(name);
    ST(0) = ret.detach_mortal();
    XSRETURN(1);
}

static bool init () {
    auto file = "scope.cc";
    newXS("MyTest::Hints::set", &xs_hints_set, file);
    newXS("MyTest::Hints::exists", &xs_hints_exists, file);
    newXS("MyTest::Hints::get", &xs_hints_get, file);
    newXS("MyTest::Hints::remove", &xs_hints_remove, file);
    newXS("MyTest::Hints::get_hash", &xs_hints_get_hash, file);
    newXS("MyTest::Hints::get_ct", &xs_hints_get_ct, file);
    return true;
}

static bool _init = init();
