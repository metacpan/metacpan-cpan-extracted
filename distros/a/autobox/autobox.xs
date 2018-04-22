#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

#include "ptable.h"

static PTABLE_t *AUTOBOX_OP_MAP = NULL;
static U32 AUTOBOX_SCOPE_DEPTH = 0;
static OP *(*autobox_old_check_entersub)(pTHX_ OP *op) = NULL;

static SV * autobox_method_common(pTHX_ SV *method, U32 *hashp);
static const char * autobox_type(pTHX_ SV * const sv, STRLEN *len);
static void autobox_cleanup(pTHX_ void * unused);

OP * autobox_check_entersub(pTHX_ OP *o);
OP * autobox_method_named(pTHX);
OP * autobox_method(pTHX);

void auto_ref(pTHX_ OP *invocant, UNOP *parent, OP *prev);

/* handle non-reference invocants e.g. @foo->bar, %foo->bar etc. */
void auto_ref(pTHX_ OP *invocant, UNOP *parent, OP *prev) {
    /*
     * perlref:
     *
     *     As a special case, "\(@foo)" returns a list of references to the
     *     contents of @foo, not a reference to @foo itself. Likewise for %foo,
     *     except that the key references are to copies (since the keys are just
     *     strings rather than full-fledged scalars).
     *
     * we don't want that (it results in the invocant being a reference to the
     * last element in the list), so we toggle the parentheses off while creating
     * the reference then toggle them back on in case they're needed elsewhere
     *
     */
    bool toggled = FALSE;

    if (invocant->op_flags & OPf_PARENS) {
        invocant->op_flags &= ~OPf_PARENS;
        toggled = TRUE;
    }

#ifdef op_sibling_splice
    op_sibling_splice(
        (OP *)parent,
        prev,
        0,
        newUNOP(
            OP_REFGEN,
            0,
            op_sibling_splice(
                (OP *)parent,
                prev,
                1,
                NULL
            )
        )
    );
#else
    /* XXX if this (old?) way works, why do we need both? */
    OP *refgen = newUNOP(OP_REFGEN, 0, invocant);
    prev->op_sibling = refgen;
    refgen->op_sibling = invocant->op_sibling;
    invocant->op_sibling = NULL;
#endif

    /* Restore the parentheses in case something else expects them */
    if (toggled) {
        invocant->op_flags |= OPf_PARENS;
    }
}

OP * autobox_check_entersub(pTHX_ OP *o) {
    UNOP *parent;
    OP *prev, *invocant, *cvop;
    SV **svp;
    HV *hh;
    bool has_bindings = FALSE;

    /*
     * XXX note: perl adopts a convention of calling the OP `o` and has shortcut
     * macros based on this convention like cUNOPo, among others. if the name
     * changes, the macro will need to change as well e.g. to cUNOPx(op)
     */

    /*
     * work around a %^H scoping bug by checking that PL_hints (which is
     * properly scoped) & an unused PL_hints bit (0x100000) is true
     *
     * XXX this is fixed in #33311:
     *
     *     http://www.nntp.perl.org/group/perl.perl5.porters/2008/02/msg134131.html
     */
    if ((PL_hints & 0x80020000) != 0x80020000) {
        goto done;
    }

    /*
     * the OP which yields the CV is the last OP in the ENTERSUB OP's list of
     * children. navigate to it by following the `op_sibling` pointers from the
     * first child in the list (the invocant)
     */

    parent = OpHAS_SIBLING(cUNOPo->op_first) ? cUNOPo : ((UNOP *)cUNOPo->op_first);
    prev = parent->op_first;
    invocant = OpSIBLING(prev);

    for (cvop = invocant; OpHAS_SIBLING(cvop); cvop = OpSIBLING(cvop));

    /*
     * now we have the CV OP, we can check if it's a method lookup.
     * bail out if it's not
     */
    if ((cvop->op_type != OP_METHOD) && (cvop->op_type != OP_METHOD_NAMED)) {
        goto done;
    }

    /* bail out if the invocant is a bareword e.g. Foo->bar */
    if ((invocant->op_type == OP_CONST) && (invocant->op_private & OPpCONST_BARE)) {
        goto done;
    }

    /*
     * the bareword flag is not set on the invocants of the `import`, `unimport`
     * and `VERSION` methods faked up by `use` and `no` [1]. we have no other way
     * to detect if an OP_CONST invocant is a bareword for these methods,
     * so we have no choice but to assume it is and bail out so that we don't
     * break `use`, `no` etc.
     *
     * (this is documented: the solution/workaround is to use
     * $value->autobox_class instead.)
     *
     * [1] XXX this is a bug (in perl)
     */
    if (cvop->op_type == OP_METHOD_NAMED) {
        /* SvPVX_const should be sane for the method name */
        const char * method_name = SvPVX_const(((SVOP *)cvop)->op_sv);

        if (
            strEQ(method_name, "import")   ||
            strEQ(method_name, "unimport") ||
            strEQ(method_name, "VERSION")
        ) {
            goto done;
        }
    }

    hh = GvHV(PL_hintgv); /* the hints hash (%^H) */

    /* is there a bindings hashref for this scope? */
    has_bindings = hh
        && (svp = hv_fetch(hh, "autobox", 7, FALSE))
        && *svp
        && SvROK(*svp);

    if (!has_bindings) {
        goto done;
    }

    /*
     * if the invocant is an @array, %hash, @{ ... } or %{ ... }, then
     * "auto-ref" it i.e. the optree equivalent of inserting a backslash
     * before it:
     *
     *     @foo->bar -> (\@foo)->bar
     */
    switch (invocant->op_type) {
        case OP_PADAV:
        case OP_PADHV:
        case OP_RV2AV:
        case OP_RV2HV:
            auto_ref(aTHX_ invocant, parent, prev);
    }

    cvop->op_flags |= OPf_SPECIAL;
    cvop->op_ppaddr = cvop->op_type == OP_METHOD
        ? autobox_method
        : autobox_method_named;

    PTABLE_store(AUTOBOX_OP_MAP, cvop, SvRV(*svp));

    done:
        return autobox_old_check_entersub(aTHX_ o);
}

OP* autobox_method(pTHX) {
    dVAR; dSP;
    SV * const sv = TOPs;
    SV * cv;

    if (SvROK(sv)) {
        cv = SvRV(sv);

        if (SvTYPE(cv) == SVt_PVCV) {
            SETs(cv);
            RETURN;
        }
    }

    cv = autobox_method_common(aTHX_ sv, NULL);

    if (cv) {
        SETs(cv);
        RETURN;
    } else {
        return PL_ppaddr[OP_METHOD](aTHXR);
    }
}

OP* autobox_method_named(pTHX) {
    dVAR; dSP;
    SV * const sv = cSVOP_sv;
    U32 hash = SvSHARED_HASH(sv);
    SV * cv;

    cv = autobox_method_common(aTHX_ sv, &hash);

    if (cv) {
        XPUSHs(cv);
        RETURN;
    } else {
        return PL_ppaddr[OP_METHOD_NAMED](aTHXR);
    }
}

#define AUTOBOX_TYPE_RETURN(type) STMT_START { \
    *len = (sizeof(type) - 1); return type;    \
} STMT_END

static const char *autobox_type(pTHX_ SV * const sv, STRLEN *len) {
    switch (SvTYPE(sv)) {
        case SVt_NULL:
            AUTOBOX_TYPE_RETURN("UNDEF");
        case SVt_IV:
            AUTOBOX_TYPE_RETURN("INTEGER");
        case SVt_PVIV:
            if (SvIOK(sv)) {
                AUTOBOX_TYPE_RETURN("INTEGER");
            } else {
                AUTOBOX_TYPE_RETURN("STRING");
            }
        case SVt_NV:
            if (SvIOK(sv)) {
                AUTOBOX_TYPE_RETURN("INTEGER");
            } else {
                AUTOBOX_TYPE_RETURN("FLOAT");
            }
        case SVt_PVNV:
            /*
             * integer before float:
             * https://rt.cpan.org/Ticket/Display.html?id=46814
             */
            if (SvIOK(sv)) {
                AUTOBOX_TYPE_RETURN("INTEGER");
            } else if (SvNOK(sv)) {
                AUTOBOX_TYPE_RETURN("FLOAT");
            } else {
                AUTOBOX_TYPE_RETURN("STRING");
            }
#ifdef SVt_RV /* no longer defined by default if PERL_CORE is defined */
        case SVt_RV:
#endif
        case SVt_PV:
        case SVt_PVMG:
#ifdef SvVOK
            if (SvVOK(sv)) {
                AUTOBOX_TYPE_RETURN("VSTRING");
            }
#endif
            if (SvROK(sv)) {
                AUTOBOX_TYPE_RETURN("REF");
            } else {
                AUTOBOX_TYPE_RETURN("STRING");
            }
        case SVt_PVLV:
            if (SvROK(sv)) {
                AUTOBOX_TYPE_RETURN("REF");
            } else if (LvTYPE(sv) == 't' || LvTYPE(sv) == 'T') { /* tied lvalue */
                if (SvIOK(sv)) {
                    AUTOBOX_TYPE_RETURN("INTEGER");
                } else if (SvNOK(sv)) {
                    AUTOBOX_TYPE_RETURN("FLOAT");
                } else {
                    AUTOBOX_TYPE_RETURN("STRING");
                }
            } else {
                AUTOBOX_TYPE_RETURN("LVALUE");
            }
        case SVt_PVAV:
            AUTOBOX_TYPE_RETURN("ARRAY");
        case SVt_PVHV:
            AUTOBOX_TYPE_RETURN("HASH");
        case SVt_PVCV:
            AUTOBOX_TYPE_RETURN("CODE");
        case SVt_PVGV:
            AUTOBOX_TYPE_RETURN("GLOB");
        case SVt_PVFM:
            AUTOBOX_TYPE_RETURN("FORMAT");
        case SVt_PVIO:
            AUTOBOX_TYPE_RETURN("IO");
#ifdef SVt_BIND
        case SVt_BIND:
            AUTOBOX_TYPE_RETURN("BIND");
#endif
#ifdef SVt_REGEXP
        case SVt_REGEXP:
            AUTOBOX_TYPE_RETURN("REGEXP");
#endif
        default:
            AUTOBOX_TYPE_RETURN("UNKNOWN");
    }
}

/* returns either the method, or NULL, meaning delegate to the original op */
/* FIXME this has diverged from the implementation in pp_hot.c */
static SV * autobox_method_common(pTHX_ SV * method, U32* hashp) {
    SV * const sv = *(PL_stack_base + TOPMARK + 1);

    /*
     * if autobox is enabled (in scope) for this op and the invocant isn't
     * an object...
     */
    /* don't use sv_isobject - we don't want to call SvGETMAGIC twice */
    if ((PL_op->op_flags & OPf_SPECIAL) && ((!SvROK(sv)) || !SvOBJECT(SvRV(sv)))) {
        HV * autobox_bindings;

        SvGETMAGIC(sv);

        /* this is the "bindings hash" that maps datatypes to package names */
        autobox_bindings = (HV *)(PTABLE_fetch(AUTOBOX_OP_MAP, PL_op));

        if (autobox_bindings) {
            const char * reftype; /* autobox_bindings key */
            SV **svp; /* pointer to autobox_bindings value */
            STRLEN typelen = 0;

            /*
             * the type is either the invocant's reftype(), a subtype of
             * SCALAR if it's not a ref, or UNDEF if it's not defined
             */

            if (SvOK(sv)) {
                reftype = autobox_type(aTHX_ (SvROK(sv) ? SvRV(sv) : sv), &typelen);
            } else {
                reftype = "UNDEF";
                typelen = sizeof("UNDEF") - 1;
            }

            svp = hv_fetch(autobox_bindings, reftype, typelen, 0);

            if (svp && SvOK(*svp)) {
                SV * packsv = *svp;
                STRLEN packlen;
                HV * stash;
                GV * gv;
                const char * packname = SvPV_const(packsv, packlen);

                stash = gv_stashpvn(packname, packlen, FALSE);

                if (hashp) {
                    /* shortcut for simple names */
                    const HE* const he = hv_fetch_ent(stash, method, 0, *hashp);

                    if (he) {
                        gv = (GV*)HeVAL(he);

                        /*
                         * FIXME this has diverged from the implementation
                         * in pp_hot.c
                         */
                        if (
                               isGV(gv)
                            && GvCV(gv)
                            && (!GvCVGEN(gv) || GvCVGEN(gv) == PL_sub_generation)
                        ) {
                            return ((SV*)GvCV(gv));
                        }
                    }
                }

                /*
                 * SvPV_nolen_const returns the method name as a const char *,
                 * stringifying names that are not strings (e.g. undef, SvIV,
                 * SvNV &c.) - see name.t
                 */
                gv = gv_fetchmethod(
                    stash ? stash : (HV*)packsv,
                    SvPV_nolen_const(method)
                );

                if (gv) {
                    return(isGV(gv) ? (SV*)GvCV(gv) : (SV*)gv);
                }
            }
        }
    }

    return NULL;
}

static void autobox_cleanup(pTHX_ void * unused) {
    PERL_UNUSED_VAR(unused); /* silence warning */

    if (AUTOBOX_OP_MAP) {
        PTABLE_free(AUTOBOX_OP_MAP);
        AUTOBOX_OP_MAP = NULL;
    }
}

MODULE = autobox                PACKAGE = autobox

PROTOTYPES: ENABLE

BOOT:
/*
 * XXX the BOOT section extends to the next blank line, so don't add one
 * for readability
 */
AUTOBOX_OP_MAP = PTABLE_new();
if (AUTOBOX_OP_MAP) {
    Perl_call_atexit(aTHX_ autobox_cleanup, NULL);
} else {
    Perl_croak(aTHX_ "Can't initialize OP map");
}

void
_enter()
    PROTOTYPE:
    CODE:
        if (AUTOBOX_SCOPE_DEPTH > 0) {
            ++AUTOBOX_SCOPE_DEPTH;
        } else {
            AUTOBOX_SCOPE_DEPTH = 1;
            /*
             * capture the check routine in scope when autobox is used.
             * usually, this will be Perl_ck_subr, though, in principle,
             * it could be a bespoke checker spliced in by another module.
             */
            autobox_old_check_entersub = PL_check[OP_ENTERSUB];
            PL_check[OP_ENTERSUB] = autobox_check_entersub;
        }

void
_leave()
    PROTOTYPE:
    CODE:
        if (AUTOBOX_SCOPE_DEPTH == 0) {
            Perl_warn(aTHX_ "scope underflow");
        }

        if (AUTOBOX_SCOPE_DEPTH > 1) {
            --AUTOBOX_SCOPE_DEPTH;
        } else {
            AUTOBOX_SCOPE_DEPTH = 0;
            PL_check[OP_ENTERSUB] = autobox_old_check_entersub;
        }

void
_scope()
    PROTOTYPE:
    CODE:
        XSRETURN_UV(PTR2UV(GvHV(PL_hintgv)));

MODULE = autobox                PACKAGE = autobox::universal

SV *
type(SV * sv)
    PROTOTYPE:$
    PREINIT:
        STRLEN len = 0;
        const char *type;
    CODE:
        if (SvOK(sv)) {
            type = autobox_type(aTHX_ (SvROK(sv) ? SvRV(sv) : sv), &len);
            RETVAL = newSVpv(type, len);
        } else {
            RETVAL = newSVpv("UNDEF", sizeof("UNDEF") - 1);
        }
    OUTPUT:
        RETVAL
