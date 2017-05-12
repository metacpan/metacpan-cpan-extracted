#include "EXTERN.h"
#include "perl.h"
#include "embed.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags_GLOBAL
#include "ppport.h"

#include "hook_op_check.h"

#if PERL_REVISION == 5 && PERL_VERSION >= 16
#define pad_findmy(a,b,c) Perl_pad_findmy_pvn(aTHX_ a, b, c)
#else
#if PERL_REVISION == 5 && PERL_VERSION >= 15 && PERL_SUBVERSION >= 1
#define pad_findmy(a,b,c) Perl_pad_findmy_pvn(aTHX_ a, b, c)

#else
#if PERL_REVISION == 5 && PERL_VERSION >= 13

#else

#define op_append_elem(a,b,c) Perl_append_elem(aTHX_ a,b,c)

#if PERL_REVISION == 5 && PERL_VERSION >= 12

#else
#define pad_findmy(a,b,c) Perl_pad_findmy(aTHX_ a)
#endif
#endif
#endif
#endif

typedef struct userdata_St {
    hook_op_check_id eval_hook;
    SV *class;
} userdata_t;

static OP *
invoker_ck_entersub(pTHX_ OP *o, void *ud) {
    OP *f = ((cUNOPo->op_first->op_sibling)
             ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first; // pushmark
    OP *arg = f->op_sibling; // the actual first argument

    if (arg->op_type == OP_RV2SV) {
        GV *gv;
        OP *gvop = cUNOPx(arg)->op_first;
        if (gvop->op_type == OP_GV &&
            (gv = cGVOPx_gv(gvop)) &&
            !strcmp(GvNAME_get(gv), "-")) {

	    const PADOFFSET tmp = pad_findmy("$self", 5, 0);
            if (tmp == -1) {
                gv = gv_fetchpvn_flags("self", 4, GV_NOINIT, SVt_PV);
                if (SvOK(gv) && SvTYPE(gv) == SVt_PVGV) {
                    // "$self" was defined as a package variable -- use it
                    cUNOPx(arg)->op_first = newGVOP(
                        gvop->op_type,
                        gvop->op_flags,
                        gv
                    );
                }
                else {
                    croak("$self not found");
                }
            }
            else {
                OP * const self = newOP(OP_PADSV, 0);
                self->op_targ = tmp;
                f->op_sibling = self;
                self->op_sibling = arg->op_sibling;
                op_free(arg);
            }
        }
    }
    return o;
}

MODULE = invoker	PACKAGE = invoker
PROTOTYPES: ENABLE

hook_op_check_id
setup (class)
        SV *class;
    PREINIT:
        userdata_t *ud;
    INIT:
        Newx (ud, 1, userdata_t);
    CODE:
        ud->class = newSVsv (class);
        RETVAL = hook_op_check (OP_ENTERSUB, invoker_ck_entersub, ud);
    OUTPUT:
        RETVAL

void
teardown (class, hook)
        hook_op_check_id hook
    PREINIT:
        userdata_t *ud;
    CODE:
        ud = (userdata_t *)hook_op_check_remove (OP_ENTERSUB, hook);
        if (ud) {
            SvREFCNT_dec (ud->class);
            Safefree (ud);
        }
