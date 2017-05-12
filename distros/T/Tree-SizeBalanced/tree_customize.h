// vim: filetype=xs
#ifndef TREE_CUSTOMIZE__H
#define TREE_CUSTOMIZE__H

#define void_id 0
#define int_id 1
#define num_id 2
#define str_id 3
#define any_id 4

#define void_t void*
#define int_t IV
#define num_t NV
#define str_t SV*
#define any_t SV*

static inline T(void) from_sv_void(pTHX_ SV * sv){
    return NULL;
}
static inline T(int) from_sv_int(pTHX_ SV * sv){
    return SvIV(sv);
}
static inline T(num) from_sv_num(pTHX_ SV * sv){
    return SvNV(sv);
}
static inline T(str) from_sv_str(pTHX_ SV * sv){
    return sv;
}
static inline T(any) from_sv_any(pTHX_ SV * sv){
    return sv;
}

static inline T(void) copy_sv_void(pTHX_ SV * sv){
    return NULL;
}
static inline T(int) copy_sv_int(pTHX_ SV * sv){
    return SvIV(sv);
}
static inline T(num) copy_sv_num(pTHX_ SV * sv){
    return SvNV(sv);
}
static inline T(str) copy_sv_str(pTHX_ SV * sv){
    return newSVsv(sv);
}
static inline T(any) copy_sv_any(pTHX_ SV * sv){
    return newSVsv(sv);
}

static inline SV** ret_int(pTHX_ SV ** SP, T(int) key){
    dTARGET;
    PUSHi(key);
    return SP;
}
static inline SV** ret_num(pTHX_ SV ** SP, T(num) key){
    dTARGET;
    PUSHn(key);
    return SP;
}
static inline SV** ret_str(pTHX_ SV ** SP, T(str) key){
    PUSHs(key);
    return SP;
}
static inline SV** ret_any(pTHX_ SV ** SP, T(any) key){
    PUSHs(key);
    return SP;
}

static inline SV** mret_int(pTHX_ SV ** SP, T(int) key){
    mPUSHi(key);
    return SP;
}
static inline SV** mret_num(pTHX_ SV ** SP, T(num) key){
    mPUSHn(key);
    return SP;
}
static inline SV** mret_str(pTHX_ SV ** SP, T(str) key){
    PUSHs(key);
    return SP;
}
static inline SV** mret_any(pTHX_ SV ** SP, T(any) key){
    PUSHs(key);
    return SP;
}

static inline SV** mxret_int(pTHX_ SV ** SP, T(int) key){
    mXPUSHi(key);
    return SP;
}
static inline SV** mxret_num(pTHX_ SV ** SP, T(num) key){
    mXPUSHn(key);
    return SP;
}
static inline SV** mxret_str(pTHX_ SV ** SP, T(str) key){
    XPUSHs(key);
    return SP;
}
static inline SV** mxret_any(pTHX_ SV ** SP, T(any) key){
    XPUSHs(key);
    return SP;
}

static inline IV cmp_int(pTHX_ SV**SP, T(int) a, T(int) b, SV* cmp){
    return a - b;
}
static inline NV cmp_num(pTHX_ SV**SP, T(num) a, T(num) b, SV* cmp){
    return a - b;
}
static inline IV cmp_str(pTHX_ SV**SP, T(str) a, T(str) b, SV* cmp){
    return (IV) sv_cmp(a, b);
}
static inline IV cmp_any(pTHX_ SV**SP, T(any) a, T(any) b, SV* cmp){
    SV * a_SV = GvSV(a_GV);
    SV * b_SV = GvSV(b_GV);
    SvSetSV(a_SV, a);
    SvSetSV(b_SV, b);

    //dSP;
    PUTBACK;

    PUSHMARK(SP);
    I32 ret_count = call_sv(cmp, G_SCALAR | G_NOARGS);

    SPAGAIN;

    IV res = 0;
    if( ret_count==1 )
        res = POPi;

    //PUTBACK;

    //return cmp(a, b);
    return res;
}

#endif
