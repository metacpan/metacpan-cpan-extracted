#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* ------------------------------------------------------------------ */
/* Custom op forward declarations (5.14+ only)                        */
/* ------------------------------------------------------------------ */

#if PERL_VERSION >= 14
static OP *pp_tlaloc_wet(pTHX);
static OP *pp_tlaloc_drench(pTHX);
static OP *pp_tlaloc_dry(pTHX);
static OP *pp_tlaloc_wetness(pTHX);
static OP *pp_tlaloc_is_wet(pTHX);
static OP *pp_tlaloc_is_dry(pTHX);
static OP *pp_tlaloc_evap_rate(pTHX);
static XOP tlaloc_xop_wet;
static XOP tlaloc_xop_drench;
static XOP tlaloc_xop_dry;
static XOP tlaloc_xop_wetness;
static XOP tlaloc_xop_is_wet;
static XOP tlaloc_xop_is_dry;
static XOP tlaloc_xop_evap_rate;
#endif

/* ------------------------------------------------------------------ */
/* Constants and struct                                                */
/* ------------------------------------------------------------------ */

#define EVAP_STEP_DEFAULT 10
#define WETNESS_MAX 100

typedef struct {
    int wetness;    /* 0–100, decremented on each access via mg_get */
    int evap_step;  /* amount to decrement per access (default 10) */
} wetness_magic_t;

/* ------------------------------------------------------------------ */
/* Forward declaration — vtable referenced by callbacks below         */
/* ------------------------------------------------------------------ */

static MGVTBL wetness_vtbl;

/* ------------------------------------------------------------------ */
/* MGVTBL callbacks                                                    */
/* ------------------------------------------------------------------ */

/* svt_get: fires on every Perl-level read of the scalar */
static int
wetness_mg_get(pTHX_ SV *sv, MAGIC *mg) {
    wetness_magic_t *wm = (wetness_magic_t *)mg->mg_ptr;
    if (wm) {
        wm->wetness -= wm->evap_step;
        if (wm->wetness < 0) wm->wetness = 0;
    }
    return 0;
}

/* svt_free: fires when the SV is garbage-collected */
static int
wetness_mg_free(pTHX_ SV *sv, MAGIC *mg) {
    wetness_magic_t *wm = (wetness_magic_t *)mg->mg_ptr;
    if (wm) {
        Safefree(wm);
        mg->mg_ptr = NULL;
    }
    return 0;
}

/* ------------------------------------------------------------------ */
/* Static vtable definition                                            */
/* ------------------------------------------------------------------ */

static MGVTBL wetness_vtbl = {
    wetness_mg_get,   /* svt_get   */
    NULL,             /* svt_set   */
    NULL,             /* svt_len   */
    NULL,             /* svt_clear */
    wetness_mg_free,  /* svt_free  */
    NULL,             /* svt_copy  */
    NULL,             /* svt_dup   */
    NULL              /* svt_local */
};

/* ------------------------------------------------------------------ */
/* Helper functions                                                    */
/* ------------------------------------------------------------------ */

/* Find our magic on an SV, keyed by vtable address not just type.
   SvMAGIC is only valid for SVt_PVMG+; return NULL for smaller types. */
static MAGIC *
tlaloc_find_magic(pTHX_ SV *sv) {
    if (SvTYPE(sv) < SVt_PVMG) return NULL;
    return mg_findext(sv, PERL_MAGIC_ext, &wetness_vtbl);
}

/* Remove our magic (triggers mg_free -> Safefree) */
static void
tlaloc_remove_magic(pTHX_ SV *sv) {
    sv_unmagicext(sv, PERL_MAGIC_ext, &wetness_vtbl);
}

/* Attach magic at add_level with evap_step, or top-up if already wet (capped at WETNESS_MAX) */
/* evap_step of -1 means "use default or keep existing" */
static void
tlaloc_attach_magic(pTHX_ SV *sv, int add_level, int evap_step) {
    MAGIC *mg = tlaloc_find_magic(aTHX_ sv);
    if (mg && mg->mg_ptr) {
        wetness_magic_t *wm = (wetness_magic_t *)mg->mg_ptr;
        wm->wetness += add_level;
        if (wm->wetness > WETNESS_MAX) wm->wetness = WETNESS_MAX;
        if (evap_step >= 0) wm->evap_step = evap_step;  /* Update evap if specified */
    } else {
        wetness_magic_t *wm;
        /* Break COW and upgrade to PVMG before attaching magic */
        if (SvPOK(sv) && SvIsCOW(sv))
            sv_force_normal_flags(sv, 0);
        SvUPGRADE(sv, SVt_PVMG);
        Newxz(wm, 1, wetness_magic_t);
        wm->wetness = (add_level > WETNESS_MAX) ? WETNESS_MAX : add_level;
        wm->evap_step = (evap_step >= 0) ? evap_step : EVAP_STEP_DEFAULT;
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &wetness_vtbl, (char *)wm, -1);
    }
}

/* Decrement wetness by evap_step and return current level (0–100) */
static int
tlaloc_read_wetness(pTHX_ SV *sv) {
    MAGIC *mg = tlaloc_find_magic(aTHX_ sv);
    wetness_magic_t *wm;
    if (!mg || !mg->mg_ptr) return 0;
    wm = (wetness_magic_t *)mg->mg_ptr;
    wm->wetness -= wm->evap_step;
    if (wm->wetness < 0) wm->wetness = 0;
    return wm->wetness;
}

/* ------------------------------------------------------------------ */
/* Tied wetness struct (for arrays and hashes)                         */
/* ------------------------------------------------------------------ */

typedef struct {
    SV *data;       /* reference to underlying AV or HV */
    int wetness;    /* 0–100 */
    int evap_step;  /* evaporation rate */
    int skip_evap;  /* skip next evaporation (workaround for double-FETCH after STORE) */
} tied_wetness_t;

static void
tied_evaporate(tied_wetness_t *tw) {
    if (tw->skip_evap) {
        tw->skip_evap = 0;
        return;
    }
    tw->wetness -= tw->evap_step;
    if (tw->wetness < 0) tw->wetness = 0;
}

/* ------------------------------------------------------------------ */
/* Custom op implementations (pp_* functions) — 5.14+ only           */
/* ------------------------------------------------------------------ */

#if PERL_VERSION >= 14

/* pp_tlaloc_wet: wet(sv [, evap_step]) */
static OP *
pp_tlaloc_wet(pTHX) {
    dSP;
    SV *sv;
    int evap_step = -1;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("wet requires at least 1 argument");
    
    sv = PL_stack_base[ax];
    if (items > 1)
        evap_step = SvIV(PL_stack_base[ax + 1]);
    
    if (SvROK(sv)) sv = SvRV(sv);
    tlaloc_attach_magic(aTHX_ sv, 50, evap_step);
    
    SP = PL_stack_base + TOPMARK;
    PUTBACK;
    return NORMAL;
}

/* pp_tlaloc_drench: drench(sv [, evap_step]) */
static OP *
pp_tlaloc_drench(pTHX) {
    dSP;
    SV *sv;
    int evap_step = -1;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("drench requires at least 1 argument");
    
    sv = PL_stack_base[ax];
    if (items > 1)
        evap_step = SvIV(PL_stack_base[ax + 1]);
    
    if (SvROK(sv)) sv = SvRV(sv);
    tlaloc_remove_magic(aTHX_ sv);
    tlaloc_attach_magic(aTHX_ sv, WETNESS_MAX, evap_step);
    
    SP = PL_stack_base + TOPMARK;
    PUTBACK;
    return NORMAL;
}

/* pp_tlaloc_dry: dry(sv) */
static OP *
pp_tlaloc_dry(pTHX) {
    dSP;
    SV *sv;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("dry requires 1 argument");
    
    sv = PL_stack_base[ax];
    if (SvROK(sv)) sv = SvRV(sv);
    tlaloc_remove_magic(aTHX_ sv);
    
    SP = PL_stack_base + TOPMARK;
    PUTBACK;
    return NORMAL;
}

/* pp_tlaloc_wetness: wetness(sv) -> int */
static OP *
pp_tlaloc_wetness(pTHX) {
    dSP;
    SV *sv;
    int wetness;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("wetness requires 1 argument");
    
    sv = PL_stack_base[ax];
    if (SvROK(sv)) sv = SvRV(sv);
    wetness = tlaloc_read_wetness(aTHX_ sv);
    
    SP = PL_stack_base + TOPMARK;
    XPUSHs(sv_2mortal(newSViv(wetness)));
    PUTBACK;
    return NORMAL;
}

/* pp_tlaloc_is_wet: is_wet(sv) -> bool */
static OP *
pp_tlaloc_is_wet(pTHX) {
    dSP;
    SV *sv;
    int wetness;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("is_wet requires 1 argument");
    
    sv = PL_stack_base[ax];
    if (SvROK(sv)) sv = SvRV(sv);
    wetness = tlaloc_read_wetness(aTHX_ sv);
    
    SP = PL_stack_base + TOPMARK;
    XPUSHs(wetness > 0 ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_tlaloc_is_dry: is_dry(sv) -> bool */
static OP *
pp_tlaloc_is_dry(pTHX) {
    dSP;
    SV *sv;
    int wetness;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("is_dry requires 1 argument");
    
    sv = PL_stack_base[ax];
    if (SvROK(sv)) sv = SvRV(sv);
    wetness = tlaloc_read_wetness(aTHX_ sv);
    
    SP = PL_stack_base + TOPMARK;
    XPUSHs(wetness == 0 ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_tlaloc_evap_rate: evap_rate(sv [, new_rate]) -> int */
static OP *
pp_tlaloc_evap_rate(pTHX) {
    dSP;
    SV *sv;
    MAGIC *mg;
    wetness_magic_t *wm;
    int result = 0;
    I32 ax = TOPMARK + 1;
    /* items = total args on stack between TOPMARK and SP, minus 1 for the CV */
    I32 items = (SP - PL_stack_base - TOPMARK) - 1;
    
    if (items < 1)
        croak("evap_rate requires at least 1 argument");
    
    sv = PL_stack_base[ax];
    if (SvROK(sv)) sv = SvRV(sv);
    
    mg = tlaloc_find_magic(aTHX_ sv);
    if (mg && mg->mg_ptr) {
        wm = (wetness_magic_t *)mg->mg_ptr;
        if (items > 1) {
            wm->evap_step = SvIV(PL_stack_base[ax + 1]);
        }
        result = wm->evap_step;
    }
    
    SP = PL_stack_base + TOPMARK;
    XPUSHs(sv_2mortal(newSViv(result)));
    PUTBACK;
    return NORMAL;
}

#endif /* PERL_VERSION >= 14 — end of pp_* functions */

/* ------------------------------------------------------------------ */
/* Check functions to intercept XSUB calls and replace with custom ops */
/* ------------------------------------------------------------------ */

#if PERL_VERSION >= 14
static CV *tlaloc_cv_wet;
static CV *tlaloc_cv_drench;
static CV *tlaloc_cv_dry;
static CV *tlaloc_cv_wetness;
static CV *tlaloc_cv_is_wet;
static CV *tlaloc_cv_is_dry;
static CV *tlaloc_cv_evap_rate;

static OP *
tlaloc_ck_wet(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_wet;
    return entersubop;
}

static OP *
tlaloc_ck_drench(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_drench;
    return entersubop;
}

static OP *
tlaloc_ck_dry(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_dry;
    return entersubop;
}

static OP *
tlaloc_ck_wetness(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_wetness;
    return entersubop;
}

static OP *
tlaloc_ck_is_wet(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_is_wet;
    return entersubop;
}

static OP *
tlaloc_ck_is_dry(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_is_dry;
    return entersubop;
}

static OP *
tlaloc_ck_evap_rate(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(protosv);
    entersubop->op_ppaddr = pp_tlaloc_evap_rate;
    return entersubop;
}
#endif

/* ------------------------------------------------------------------ */
/* Exportable function names                                           */
/* ------------------------------------------------------------------ */

static const char * const tlaloc_exports[] = {
    "wet", "drench", "dry", "wetness", "is_wet", "is_dry",
    "evap_rate", "wet_tie", "untie_wet", NULL
};

static void
tlaloc_export_to(pTHX_ HV *caller_stash, const char *name) {
    HV *tlaloc_stash = gv_stashpvs("Tlaloc", 0);
    GV **src_gvp;
    if (!tlaloc_stash) return;
    src_gvp = (GV **)hv_fetch(tlaloc_stash, name, strlen(name), FALSE);
    if (src_gvp && *src_gvp && GvCV(*src_gvp)) {
        CV *cv = GvCV(*src_gvp);
        GV **dst_gvp = (GV **)hv_fetch(caller_stash, name, strlen(name), TRUE);
        GV *dst = *dst_gvp;
        if (SvTYPE(dst) != SVt_PVGV)
            gv_init(dst, caller_stash, name, strlen(name), TRUE);
        GvCV_set(dst, (CV *)SvREFCNT_inc(cv));
        GvIMPORTED_CV_on(dst);
    }
}

MODULE = Tlaloc    PACKAGE = Tlaloc

PROTOTYPES: DISABLE

BOOT:
{
#if PERL_VERSION >= 14
    /* ------------------------------------------------------------------ */
    /* Register custom ops with XOP descriptors                            */
    /* ------------------------------------------------------------------ */

    XopENTRY_set(&tlaloc_xop_wet, xop_name, "tlaloc_wet");
    XopENTRY_set(&tlaloc_xop_wet, xop_desc, "wet a scalar");
    Perl_custom_op_register(aTHX_ pp_tlaloc_wet, &tlaloc_xop_wet);

    XopENTRY_set(&tlaloc_xop_drench, xop_name, "tlaloc_drench");
    XopENTRY_set(&tlaloc_xop_drench, xop_desc, "drench a scalar");
    Perl_custom_op_register(aTHX_ pp_tlaloc_drench, &tlaloc_xop_drench);

    XopENTRY_set(&tlaloc_xop_dry, xop_name, "tlaloc_dry");
    XopENTRY_set(&tlaloc_xop_dry, xop_desc, "dry a scalar");
    Perl_custom_op_register(aTHX_ pp_tlaloc_dry, &tlaloc_xop_dry);

    XopENTRY_set(&tlaloc_xop_wetness, xop_name, "tlaloc_wetness");
    XopENTRY_set(&tlaloc_xop_wetness, xop_desc, "get wetness level");
    Perl_custom_op_register(aTHX_ pp_tlaloc_wetness, &tlaloc_xop_wetness);

    XopENTRY_set(&tlaloc_xop_is_wet, xop_name, "tlaloc_is_wet");
    XopENTRY_set(&tlaloc_xop_is_wet, xop_desc, "check if wet");
    Perl_custom_op_register(aTHX_ pp_tlaloc_is_wet, &tlaloc_xop_is_wet);

    XopENTRY_set(&tlaloc_xop_is_dry, xop_name, "tlaloc_is_dry");
    XopENTRY_set(&tlaloc_xop_is_dry, xop_desc, "check if dry");
    Perl_custom_op_register(aTHX_ pp_tlaloc_is_dry, &tlaloc_xop_is_dry);

    XopENTRY_set(&tlaloc_xop_evap_rate, xop_name, "tlaloc_evap_rate");
    XopENTRY_set(&tlaloc_xop_evap_rate, xop_desc, "get/set evaporation rate");
    Perl_custom_op_register(aTHX_ pp_tlaloc_evap_rate, &tlaloc_xop_evap_rate);

    /* ------------------------------------------------------------------ */
    /* Hook XSUBs to use custom ops via cv_set_call_checker                */
    /* ------------------------------------------------------------------ */

    tlaloc_cv_wet = get_cv("Tlaloc::wet", 0);
    cv_set_call_checker(tlaloc_cv_wet, tlaloc_ck_wet, (SV *)tlaloc_cv_wet);

    tlaloc_cv_drench = get_cv("Tlaloc::drench", 0);
    cv_set_call_checker(tlaloc_cv_drench, tlaloc_ck_drench, (SV *)tlaloc_cv_drench);

    tlaloc_cv_dry = get_cv("Tlaloc::dry", 0);
    cv_set_call_checker(tlaloc_cv_dry, tlaloc_ck_dry, (SV *)tlaloc_cv_dry);

    tlaloc_cv_wetness = get_cv("Tlaloc::wetness", 0);
    cv_set_call_checker(tlaloc_cv_wetness, tlaloc_ck_wetness, (SV *)tlaloc_cv_wetness);

    tlaloc_cv_is_wet = get_cv("Tlaloc::is_wet", 0);
    cv_set_call_checker(tlaloc_cv_is_wet, tlaloc_ck_is_wet, (SV *)tlaloc_cv_is_wet);

    tlaloc_cv_is_dry = get_cv("Tlaloc::is_dry", 0);
    cv_set_call_checker(tlaloc_cv_is_dry, tlaloc_ck_is_dry, (SV *)tlaloc_cv_is_dry);

    tlaloc_cv_evap_rate = get_cv("Tlaloc::evap_rate", 0);
    cv_set_call_checker(tlaloc_cv_evap_rate, tlaloc_ck_evap_rate, (SV *)tlaloc_cv_evap_rate);
#endif
}

void
import(SV *class, ...)
    PREINIT:
        HV *caller_stash;
        int i, j;
        const char *arg;
        STRLEN len;
    PPCODE:
        /* During 'use' at compile time, PL_curcop points at the use statement
           in the calling package, so CopSTASH gives us the correct caller */
        caller_stash = CopSTASH(PL_curcop);
        
        if (items == 1) {
            /* No args: export nothing */
            XSRETURN_EMPTY;
        }
        
        for (i = 1; i < items; i++) {
            arg = SvPV(ST(i), len);
            if (strEQ(arg, "all")) {
                for (j = 0; tlaloc_exports[j]; j++) {
			tlaloc_export_to(aTHX_ caller_stash, tlaloc_exports[j]);
                }
            } else {
                /* Individual function name */
                for (j = 0; tlaloc_exports[j]; j++) {
                    if (strEQ(arg, tlaloc_exports[j])) {
                        tlaloc_export_to(aTHX_ caller_stash, arg);
                        break;
                    }
                }
                if (!tlaloc_exports[j]) {
                    croak("'%s' is not exported by Tlaloc", arg);
                }
            }
        }
        XSRETURN_EMPTY;

void
wet(sv, ...)
        SV *sv
    PREINIT:
        int evap_step = -1;  /* -1 means not specified */
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        if (items > 1) evap_step = SvIV(ST(1));
        tlaloc_attach_magic(aTHX_ sv, 50, evap_step);

void
drench(sv, ...)
        SV *sv
    PREINIT:
        int evap_step = -1;  /* -1 means not specified */
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        if (items > 1) evap_step = SvIV(ST(1));
        tlaloc_remove_magic(aTHX_ sv);
        tlaloc_attach_magic(aTHX_ sv, WETNESS_MAX, evap_step);

void
dry(sv)
        SV *sv
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        tlaloc_remove_magic(aTHX_ sv);

int
wetness(sv)
        SV *sv
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        RETVAL = tlaloc_read_wetness(aTHX_ sv);
    OUTPUT:
        RETVAL

int
is_wet(sv)
        SV *sv
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        RETVAL = (tlaloc_read_wetness(aTHX_ sv) > 0) ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_dry(sv)
        SV *sv
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        RETVAL = (tlaloc_read_wetness(aTHX_ sv) == 0) ? 1 : 0;
    OUTPUT:
        RETVAL

int
evap_rate(sv, ...)
        SV *sv
    PREINIT:
        MAGIC *mg;
        wetness_magic_t *wm;
    CODE:
        if (SvROK(sv)) sv = SvRV(sv);
        mg = tlaloc_find_magic(aTHX_ sv);
        if (!mg || !mg->mg_ptr) {
            RETVAL = 0;  /* No magic, return 0 */
        } else {
            wm = (wetness_magic_t *)mg->mg_ptr;
            if (items > 1) {
                wm->evap_step = SvIV(ST(1));
            }
            RETVAL = wm->evap_step;
        }
    OUTPUT:
        RETVAL

SV *
wet_tie(ref, ...)
        SV *ref
    PREINIT:
        int evap_step;
        SV *tied_obj;
        tied_wetness_t *tw;
        SV *sv;
    CODE:
        evap_step = (items > 1) ? SvIV(ST(1)) : EVAP_STEP_DEFAULT;
        
        if (!SvROK(ref))
            croak("wet_tie requires an array or hash reference");
        
        sv = SvRV(ref);
        
        /* Allocate tied struct */
        Newxz(tw, 1, tied_wetness_t);
        tw->wetness = WETNESS_MAX;
        tw->evap_step = evap_step;
        
        if (SvTYPE(sv) == SVt_PVAV) {
            AV *orig = (AV *)sv;
            AV *copy;
            SSize_t i, len;
            
            /* Copy array contents */
            len = av_len(orig) + 1;
            copy = newAV();
            av_extend(copy, len - 1);
            for (i = 0; i < len; i++) {
                SV **elem = av_fetch(orig, i, 0);
                if (elem) av_store(copy, i, SvREFCNT_inc(*elem));
            }
            tw->data = newRV_noinc((SV *)copy);
            
            /* Create blessed object */
            tied_obj = newSV(0);
            sv_setiv(newSVrv(tied_obj, "Tlaloc::Tied::Array"), PTR2IV(tw));
            
            /* Clear original array BEFORE adding tie (to avoid triggering tied CLEAR) */
            av_clear(orig);
            
            /* Tie the array - store the blessed reference in magic */
            sv_magic((SV *)orig, tied_obj, PERL_MAGIC_tied, NULL, 0);
            
            RETVAL = tied_obj;
        }
        else if (SvTYPE(sv) == SVt_PVHV) {
            HV *orig = (HV *)sv;
            HV *copy;
            HE *entry;
            
            /* Copy hash contents — reuse pre-computed hash to avoid re-hashing */
            copy = newHV();
            hv_iterinit(orig);
            while ((entry = hv_iternext(orig))) {
                hv_store(copy, HeKEY(entry), HeKLEN(entry),
                         SvREFCNT_inc(HeVAL(entry)), HeHASH(entry));
            }
            tw->data = newRV_noinc((SV *)copy);
            
            /* Create blessed object */
            tied_obj = newSV(0);
            sv_setiv(newSVrv(tied_obj, "Tlaloc::Tied::Hash"), PTR2IV(tw));
            
            /* Clear original hash BEFORE adding tie (to avoid triggering tied CLEAR) */
            hv_clear(orig);
            
            /* Tie the hash - store the blessed reference in magic */
            sv_magic((SV *)orig, tied_obj, PERL_MAGIC_tied, NULL, 0);
            
            RETVAL = tied_obj;
        }
        else {
            Safefree(tw);
            croak("wet_tie requires an array or hash reference");
        }
    OUTPUT:
        RETVAL

void
untie_wet(ref)
        SV *ref
    PREINIT:
        SV *sv;
        MAGIC *mg;
        tied_wetness_t *tw;
    CODE:
        if (!SvROK(ref)) XSRETURN_EMPTY;
        sv = SvRV(ref);
        
        mg = mg_find(sv, PERL_MAGIC_tied);
        if (!mg || !mg->mg_obj) XSRETURN_EMPTY;
        
        if (SvTYPE(sv) == SVt_PVAV) {
            SV *tied_sv = mg->mg_obj;
            if (sv_derived_from(tied_sv, "Tlaloc::Tied::Array")) {
                AV *orig = (AV *)sv;
                AV *data_av;
                SSize_t i, len;
                AV *copy;
                
                tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(tied_sv)));
                if (tw && tw->data && SvROK(tw->data)) {
                    data_av = (AV *)SvRV(tw->data);
                    
                    /* Copy data BEFORE removing magic (DESTROY will free tw) */
                    len = av_len(data_av) + 1;
                    copy = newAV();
                    av_extend(copy, len - 1);
                    for (i = 0; i < len; i++) {
                        SV **elem = av_fetch(data_av, i, 0);
                        if (elem) av_store(copy, i, SvREFCNT_inc(*elem));
                    }
                    
                    /* Remove tie magic (this may trigger DESTROY) */
                    sv_unmagic(sv, PERL_MAGIC_tied);
                    
                    /* Restore data from our copy */
                    av_clear(orig);
                    len = av_len(copy) + 1;
                    for (i = 0; i < len; i++) {
                        SV **elem = av_fetch(copy, i, 0);
                        if (elem) av_store(orig, i, SvREFCNT_inc(*elem));
                    }
                    SvREFCNT_dec((SV *)copy);
                }
            }
        }
        else if (SvTYPE(sv) == SVt_PVHV) {
            SV *tied_sv = mg->mg_obj;
            if (sv_derived_from(tied_sv, "Tlaloc::Tied::Hash")) {
                HV *orig = (HV *)sv;
                HV *data_hv;
                HE *entry;

                tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(tied_sv)));
                if (tw && tw->data && SvROK(tw->data)) {
                    data_hv = (HV *)SvRV(tw->data);

                    /* Bump the HV's refcount so DESTROY (which decrements tw->data
                       the RV) doesn't free the underlying HV when sv_unmagic fires */
                    SvREFCNT_inc((SV *)data_hv);

                    /* Remove tie magic (this triggers DESTROY, freeing tw + the RV) */
                    sv_unmagic(sv, PERL_MAGIC_tied);

                    /* Restore directly from data_hv — no intermediate copy needed.
                       Reuse pre-computed hashes to avoid re-hashing each key. */
                    hv_clear(orig);
                    hv_iterinit(data_hv);
                    while ((entry = hv_iternext(data_hv))) {
                        hv_store(orig, HeKEY(entry), HeKLEN(entry),
                                 SvREFCNT_inc(HeVAL(entry)), HeHASH(entry));
                    }
                    SvREFCNT_dec((SV *)data_hv);
                }
            }
        }

# ================================================================
# TIED ARRAY PACKAGE
# ================================================================

MODULE = Tlaloc    PACKAGE = Tlaloc::Tied::Array

void
DESTROY(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        if (tw) {
            if (tw->data) SvREFCNT_dec(tw->data);
            Safefree(tw);
        }

SV *
FETCH(self, idx)
        SV *self
        IV idx
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
        SV **elem;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (AV *)SvRV(tw->data);
        elem = av_fetch(data, idx, 0);
        RETVAL = elem ? SvREFCNT_inc(*elem) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
STORE(self, idx, val)
        SV *self
        IV idx
        SV *val
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tw->skip_evap = 1;  /* Workaround: next FETCH is spurious internal call */
        data = (AV *)SvRV(tw->data);
        av_store(data, idx, SvREFCNT_inc(val));

IV
FETCHSIZE(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        /* Don't evaporate - FETCHSIZE is metadata access, not element access.
         * Also avoids spurious evaporation when Perl calls FETCHSIZE internally
         * before STORE on some platforms (e.g., Perl 5.18/Solaris).
         */
        data = (AV *)SvRV(tw->data);
        RETVAL = av_len(data) + 1;
    OUTPUT:
        RETVAL

void
STORESIZE(self, count)
        SV *self
        IV count
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (AV *)SvRV(tw->data);
        av_fill(data, count - 1);

int
EXISTS(self, idx)
        SV *self
        IV idx
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (AV *)SvRV(tw->data);
        RETVAL = av_exists(data, idx);
    OUTPUT:
        RETVAL

SV *
DELETE(self, idx)
        SV *self
        IV idx
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (AV *)SvRV(tw->data);
        RETVAL = av_delete(data, idx, 0);
        if (!RETVAL) RETVAL = &PL_sv_undef;
        else SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

void
CLEAR(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (AV *)SvRV(tw->data);
        av_clear(data);

IV
PUSH(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
        int i;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (AV *)SvRV(tw->data);
        for (i = 1; i < items; i++) {
            av_push(data, SvREFCNT_inc(ST(i)));
        }
        RETVAL = av_len(data) + 1;
    OUTPUT:
        RETVAL

SV *
POP(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (AV *)SvRV(tw->data);
        RETVAL = av_pop(data);
        if (!RETVAL) RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
SHIFT(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (AV *)SvRV(tw->data);
        RETVAL = av_shift(data);
        if (!RETVAL) RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

IV
UNSHIFT(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
        int i;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (AV *)SvRV(tw->data);
        av_unshift(data, items - 1);
        for (i = 1; i < items; i++) {
            av_store(data, i - 1, SvREFCNT_inc(ST(i)));
        }
        RETVAL = av_len(data) + 1;
    OUTPUT:
        RETVAL

void
SPLICE(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        AV *data;
        IV offset, length, i, sz;
        AV *result;
    PPCODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (AV *)SvRV(tw->data);
        sz = av_len(data) + 1;
        
        offset = (items > 1) ? SvIV(ST(1)) : 0;
        if (offset < 0) offset += sz;
        if (offset < 0) offset = 0;
        if (offset > sz) offset = sz;
        
        length = (items > 2) ? SvIV(ST(2)) : sz - offset;
        if (length < 0) length = 0;
        if (offset + length > sz) length = sz - offset;
        
        /* Collect removed elements */
        result = newAV();
        for (i = 0; i < length; i++) {
            SV **elem = av_fetch(data, offset + i, 0);
            if (elem) av_push(result, SvREFCNT_inc(*elem));
        }
        
        /* Remove old elements */
        for (i = 0; i < length; i++) {
            av_delete(data, offset, G_DISCARD);
        }
        
        /* Shift remaining elements */
        if (length > 0 && offset < sz - length) {
            for (i = offset; i < sz - length; i++) {
                SV **elem = av_fetch(data, i + length, 0);
                if (elem) av_store(data, i, SvREFCNT_inc(*elem));
            }
            av_fill(data, sz - length - 1);
        }
        
        /* Insert new elements (items - 3 new elements starting at ST(3)) */
        if (items > 3) {
            IV new_count = items - 3;
            IV new_sz = av_len(data) + 1;
            av_extend(data, new_sz + new_count - 1);
            /* Shift existing elements to make room */
            for (i = new_sz - 1; i >= offset; i--) {
                SV **elem = av_fetch(data, i, 0);
                if (elem) av_store(data, i + new_count, SvREFCNT_inc(*elem));
            }
            /* Insert new elements */
            for (i = 0; i < new_count; i++) {
                av_store(data, offset + i, SvREFCNT_inc(ST(3 + i)));
            }
        }
        
        /* Return removed elements */
        sz = av_len(result) + 1;
        EXTEND(SP, sz);
        for (i = 0; i < sz; i++) {
            SV **elem = av_fetch(result, i, 0);
            PUSHs(elem ? sv_2mortal(SvREFCNT_inc(*elem)) : &PL_sv_undef);
        }
        SvREFCNT_dec(result);

int
wetness(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        RETVAL = tw->wetness;
    OUTPUT:
        RETVAL

int
is_wet(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        RETVAL = (tw->wetness > 0) ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_dry(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        RETVAL = (tw->wetness == 0) ? 1 : 0;
    OUTPUT:
        RETVAL

int
evap_rate(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        if (items > 1) {
            tw->evap_step = SvIV(ST(1));
        }
        RETVAL = tw->evap_step;
    OUTPUT:
        RETVAL

void
drench(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tw->wetness = WETNESS_MAX;
        if (items > 1) {
            tw->evap_step = SvIV(ST(1));
        }

void
wet(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tw->wetness += 50;
        if (tw->wetness > WETNESS_MAX) tw->wetness = WETNESS_MAX;
        if (items > 1) {
            tw->evap_step = SvIV(ST(1));
        }

# ================================================================
# TIED HASH PACKAGE
# ================================================================

MODULE = Tlaloc    PACKAGE = Tlaloc::Tied::Hash

void
DESTROY(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        if (tw) {
            if (tw->data) SvREFCNT_dec(tw->data);
            Safefree(tw);
        }

SV *
FETCH(self, key)
        SV *self
        SV *key
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
        SV **val;
        STRLEN klen;
        const char *kstr;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (HV *)SvRV(tw->data);
        kstr = SvPV(key, klen);
        val = hv_fetch(data, kstr, klen, 0);
        RETVAL = val ? SvREFCNT_inc(*val) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
STORE(self, key, val)
        SV *self
        SV *key
        SV *val
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
        STRLEN klen;
        const char *kstr;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tw->skip_evap = 1;  /* Workaround: next FETCH is spurious internal call */
        data = (HV *)SvRV(tw->data);
        kstr = SvPV(key, klen);
        hv_store(data, kstr, klen, SvREFCNT_inc(val), 0);

int
EXISTS(self, key)
        SV *self
        SV *key
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
        STRLEN klen;
        const char *kstr;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (HV *)SvRV(tw->data);
        kstr = SvPV(key, klen);
        RETVAL = hv_exists(data, kstr, klen);
    OUTPUT:
        RETVAL

SV *
DELETE(self, key)
        SV *self
        SV *key
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
        STRLEN klen;
        const char *kstr;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (HV *)SvRV(tw->data);
        kstr = SvPV(key, klen);
        RETVAL = hv_delete(data, kstr, klen, 0);
        if (!RETVAL) RETVAL = &PL_sv_undef;
        else SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

void
CLEAR(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (HV *)SvRV(tw->data);
        hv_clear(data);

SV *
FIRSTKEY(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
        HE *entry;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (HV *)SvRV(tw->data);
        hv_iterinit(data);
        entry = hv_iternext(data);
        if (entry) {
            RETVAL = newSVpvn(HeKEY(entry), HeKLEN(entry));
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
NEXTKEY(self, lastkey)
        SV *self
        SV *lastkey
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
        HE *entry;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        data = (HV *)SvRV(tw->data);
        entry = hv_iternext(data);
        if (entry) {
            RETVAL = newSVpvn(HeKEY(entry), HeKLEN(entry));
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
SCALAR(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
        HV *data;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        data = (HV *)SvRV(tw->data);
        RETVAL = newSViv(HvUSEDKEYS(data));
    OUTPUT:
        RETVAL

int
wetness(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        RETVAL = tw->wetness;
    OUTPUT:
        RETVAL

int
is_wet(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        RETVAL = (tw->wetness > 0) ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_dry(self)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tied_evaporate(tw);
        RETVAL = (tw->wetness == 0) ? 1 : 0;
    OUTPUT:
        RETVAL

int
evap_rate(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        if (items > 1) {
            tw->evap_step = SvIV(ST(1));
        }
        RETVAL = tw->evap_step;
    OUTPUT:
        RETVAL

void
drench(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tw->wetness = WETNESS_MAX;
        if (items > 1) {
            tw->evap_step = SvIV(ST(1));
        }

void
wet(self, ...)
        SV *self
    PREINIT:
        tied_wetness_t *tw;
    CODE:
        tw = INT2PTR(tied_wetness_t *, SvIV(SvRV(self)));
        tw->wetness += 50;
        if (tw->wetness > WETNESS_MAX) tw->wetness = WETNESS_MAX;
        if (items > 1) {
            tw->evap_step = SvIV(ST(1));
        }
