#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "hook_op_check.h"
#include "hook_op_annotation.h"

#ifndef CxOLD_OP_TYPE
#define CxOLD_OP_TYPE(cx) (cx->blk_eval.old_op_type)
#endif

STATIC hook_op_check_id TRUE_CHECK_LEAVEEVAL_ID = 0;
STATIC HV * TRUE_HASH = NULL;
STATIC OPAnnotationGroup TRUE_ANNOTATIONS = NULL;
STATIC OP * true_check_leaveeval(pTHX_ OP * o, void * user_data);
STATIC OP * true_leaveeval(pTHX);
STATIC U32 TRUE_COMPILING = 0;
STATIC U32 true_enabled(pTHX_ const char * const filename);
STATIC void true_leave(pTHX);
STATIC void true_unregister(pTHX_ const char * const filename);

STATIC void true_leave(pTHX) {
    if (TRUE_COMPILING != 1) {
        croak("true: scope underflow");
    } else {
        TRUE_COMPILING = 0;
        hook_op_check_remove(OP_LEAVEEVAL, TRUE_CHECK_LEAVEEVAL_ID);
    }
}

STATIC U32 true_enabled(pTHX_ const char * const filename) {
    SV **svp;
    svp = hv_fetch(TRUE_HASH, filename, strlen(filename), 0);
    return svp && *svp && SvOK(*svp) && SvTRUE(*svp);
}

STATIC void true_unregister(pTHX_ const char * const filename) {
    /* warn("true: deleting %s\n", filename); */
    (void)hv_delete(TRUE_HASH, filename, strlen(filename), G_DISCARD);

    if (HvKEYS(TRUE_HASH) == 0) {
        /* warn("true: hash is empty: disabling true\n"); */
        true_leave(aTHX);
    }
}

STATIC OP * true_check_leaveeval(pTHX_ OP * o, void * user_data) {
    char * ccfile = CopFILE(&PL_compiling);
    PERL_UNUSED_VAR(user_data);

    if (true_enabled(aTHX_ ccfile)) {
        op_annotate(TRUE_ANNOTATIONS, o, ccfile, NULL);
        o->op_ppaddr = true_leaveeval;
    }

    return o;
}

STATIC OP * true_leaveeval(pTHX) {
    dVAR; dSP;
    const PERL_CONTEXT * cx;
    SV ** newsp;
    OPAnnotation * annotation = op_annotation_get(TRUE_ANNOTATIONS, PL_op);
    const char *filename = annotation->data;

    cx = &cxstack[cxstack_ix];
    newsp = PL_stack_base + cx->blk_oldsp;

    /* make sure it hasn't been unimported */
    if ((CxOLD_OP_TYPE(cx) == OP_REQUIRE) && true_enabled(aTHX_ filename))  {
        if (!(cx->blk_gimme == G_SCALAR ? SvTRUE(*SP) : SP > newsp)) {
            XPUSHs(&PL_sv_yes);
            PUTBACK;
        }
        /* warn("executed leaveeval for %s\n", filename); */
        true_unregister(aTHX_ filename);
    }

    return annotation->op_ppaddr(aTHX);
}

MODULE = true                PACKAGE = true

PROTOTYPES: ENABLE

BOOT:
    TRUE_ANNOTATIONS = op_annotation_group_new();
    TRUE_HASH = get_hv("true::TRUE", GV_ADD);

void
END()
    PROTOTYPE:
    CODE:
        if (TRUE_ANNOTATIONS) { /* make sure it was initialised */
            op_annotation_group_free(aTHX_ TRUE_ANNOTATIONS);
        }

void
xs_enter()
    PROTOTYPE:
    CODE:
        /* don't hook OP_LEAVEEVAL if it's already been hooked */
        if (TRUE_COMPILING == 0) {
            TRUE_COMPILING = 1;
            TRUE_CHECK_LEAVEEVAL_ID = hook_op_check(OP_LEAVEEVAL, true_check_leaveeval, NULL);
        }

void
xs_leave()
    PROTOTYPE:
    CODE:
        true_leave(aTHX);
