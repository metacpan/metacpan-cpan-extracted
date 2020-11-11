#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "hook_op_check.h"
#include "hook_op_annotation.h"

/* return a pointer to the current context */
/* FIXME this (introduced in 2015) should be in ppport.h */
#ifndef CX_CUR
    #define CX_CUR() (&cxstack[cxstack_ix])
#endif

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

/*
 * remove our custom checker for LEAVEEVAL OPs
 */
STATIC void true_leave(pTHX) {
    if (TRUE_COMPILING != 1) {
        croak("true: scope underflow");
    } else {
        TRUE_COMPILING = 0;
        hook_op_check_remove(OP_LEAVEEVAL, TRUE_CHECK_LEAVEEVAL_ID);
    }
}

/*
 * look in the global filename (string) -> registered (boolean)
 * hash (%TRUE) and return true if the supplied filename is
 * registered i.e. if we should hook the op_ppaddr function.
 */
STATIC U32 true_enabled(pTHX_ const char * const filename) {
    SV **svp;
    svp = hv_fetch(TRUE_HASH, filename, strlen(filename), 0);
    return svp && *svp && SvOK(*svp) && SvTRUE(*svp);
}

/*
 * delete a filename from the %TRUE hash. if this empties the hash,
 * unregister the file i.e. stop hooking LEAVEEVAL checks.
 */
STATIC void true_unregister(pTHX_ const char * const filename) {
    /* warn("true: deleting %s\n", filename); */
    (void)hv_delete(TRUE_HASH, filename, strlen(filename), G_DISCARD);

    if (HvKEYS(TRUE_HASH) == 0) {
        /* warn("true: hash is empty: disabling true\n"); */
        true_leave(aTHX);
    }
}

/*
 * assign a new implementation function (op_ppaddr) to a LEAVEEVAL OP
 * if true.pm is enabled for the currently-compiling file
 */
STATIC OP * true_check_leaveeval(pTHX_ OP * o, void * user_data) {
    char * const ccfile = CopFILE(&PL_compiling);
    PERL_UNUSED_VAR(user_data);

    if (true_enabled(aTHX_ ccfile)) {
        op_annotate(TRUE_ANNOTATIONS, o, ccfile, NULL);
        o->op_ppaddr = true_leaveeval;
    }

    return o;
}

/*
 * our custom version of the LEAVEEVAL OP's implementation function (op_ppaddr),
 * which forcibly returns a true value (by pushing the internal true SV on the
 * stack) if one hasn't been returned already
 *
 * only applied if a) this OP is attached to a `require` and b) true.pm is
 * enabled for the `require`d file
 */
STATIC OP * true_leaveeval(pTHX) {
    dVAR; dSP;
    const PERL_CONTEXT * cx = CX_CUR();
    OPAnnotation * annotation = op_annotation_get(TRUE_ANNOTATIONS, PL_op);
    const char * const filename = annotation->data;
    bool file_returns_true;

    /* make sure it hasn't been unimported */
    bool enabled = (CxOLD_OP_TYPE(cx) == OP_REQUIRE) && true_enabled(aTHX_ filename);

    if (!enabled) {
        goto done;
    }

#if (PERL_BCDVERSION < 0x5024000)
    /*
     * on perl < 5.24, forcibly return true regardless of whether or not it's
     * needed (i.e. don't check to see if the file has returned true).
     *
     * XXX this is a hack to fix RT-124745 [1]. it's no longer needed on perl >=
     * 5.24
     *
     * [1] https://rt.cpan.org/Public/Bug/Display.html?id=124745
     */
    file_returns_true = FALSE;
#else
    {
        SV ** oldsp;

        /* XXX is the context ever not scalar? */
        if (cx->blk_gimme == G_SCALAR) {
            file_returns_true = SvTRUE_NN(*SP);
        } else {
            oldsp = PL_stack_base + cx->blk_oldsp;
            file_returns_true = SP > oldsp;
        }
    }
#endif

    if (!file_returns_true) {
        XPUSHs(&PL_sv_yes);
        PUTBACK;
    }

    true_unregister(aTHX_ filename);

    done:
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
