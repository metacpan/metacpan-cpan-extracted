#include "function.h"
#include "catch.h"

namespace xs { namespace func {

Sv::payload_marker_t marker;

static bool init () {
    marker.svt_free = [](pTHX_ SV*, MAGIC* mg) -> int {
        auto fc = reinterpret_cast<IFunctionCaller*>(mg->mg_ptr);
        delete fc;
        return 0;
    };
    return true;
}
static const bool _init = init();

static void XS_function_call (pTHX_ CV* cv) { xs::throw_guard(aTHX_ cv, [aTHX_ cv](){
    dVAR; dXSARGS;
    SP -= items;
    Sub sub(cv);
    auto fc = reinterpret_cast<IFunctionCaller*>(sub.payload(&marker).ptr);
    if (!fc) throw "invalid function->sub subroutine";
    auto ret = fc->call(&ST(0), items);
    if (!ret) XSRETURN_EMPTY;
    mXPUSHs(ret.detach());
    XSRETURN(1);
}); }

static Sub clone_anon_xsub (CV* proto) {
    dTHX;
    CV* cv = MUTABLE_CV(newSV_type(SvTYPE(proto)));
    CvFLAGS(cv) = CvFLAGS(proto) & ~(CVf_CLONE|CVf_WEAKOUTSIDE|CVf_CVGV_RC);
    CvCLONED_on(cv);
    CvFILE(cv) = CvFILE(proto);
    CvGV_set(cv,CvGV(proto));
    CvSTASH_set(cv, CvSTASH(proto));
    CvISXSUB_on(cv);
    CvXSUB(cv) = CvXSUB(proto);
    #ifndef PERL_IMPLICIT_CONTEXT
        CvHSCXT(cv) = &PL_stack_sp;
    #else
        PoisonPADLIST(cv);
    #endif
    CvANON_on(cv);
    return Sub::noinc(cv);
}

static PERL_THREAD_LOCAL CV* proto = newXS(nullptr, &XS_function_call, "<C++>");

Sub create_sub (IFunctionCaller* fc) {
    auto ret = clone_anon_xsub(proto);
    ret.payload_attach(fc, &marker);
    return ret;
}

}}
