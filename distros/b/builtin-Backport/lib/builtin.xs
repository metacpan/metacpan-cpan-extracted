/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#ifndef av_count
#  define av_count(av)  (AvFILL(av)+1)
#endif

#ifndef intro_my
#  define intro_my()  Perl_intro_my(aTHX)
#endif

#if !HAVE_PERL_VERSION(5, 38, 0)

static U32 warning_offset;

#define warn_experimental_builtin(name, prefix) S_warn_experimental_builtin(aTHX_ name, prefix)
static void S_warn_experimental_builtin(pTHX_ const char *name, bool prefix)
{
    /* diag_listed_as: Built-in function '%s' is experimental */
    Perl_ck_warner_d(aTHX_ packWARN(warning_offset),
                     "Built-in function '%s%s' is experimental",
                     prefix ? "builtin::" : "", name);
}

#define prepare_export_lexical()  S_prepare_export_lexical(aTHX)
static void S_prepare_export_lexical(pTHX)
{
    assert(PL_compcv);

    /* We need to have PL_comppad / PL_curpad set correctly for lexical importing */
    ENTER;
    SAVESPTR(PL_comppad_name); PL_comppad_name = PadlistNAMES(CvPADLIST(PL_compcv));
    SAVESPTR(PL_comppad);      PL_comppad      = PadlistARRAY(CvPADLIST(PL_compcv))[1];
    SAVESPTR(PL_curpad);       PL_curpad       = PadARRAY(PL_comppad);
}

#define export_lexical(name, sv)  S_export_lexical(aTHX_ name, sv)
static void S_export_lexical(pTHX_ SV *name, SV *sv)
{
    if(SvTYPE(sv) == SVt_PVCV && CvISXSUB(sv)) {
        /* Before Perl v5.36, S_cv_clone() would crash on attempts to clone a
         * CV containing a lexically exported XSUB.
         *
         * See also
         *   https://github.com/Perl/perl5/pull/19232/files#diff-d6972c2c727b9f7dfb3dc6c58950ad9e884aeaa7464c1dfe70ed0c7512719e7fR2212-R2226
         */
        croak("Cannot lexically export an XSUB as %s on this version of perl", SvPVbyte_nolen(name));
    }
    else
        SvREFCNT_inc(sv);

    PADOFFSET off = pad_add_name_sv(name, padadd_STATE, 0, 0);
    SvREFCNT_dec(PL_curpad[off]);
    PL_curpad[off] = sv;
}

#define finish_export_lexical()  S_finish_export_lexical(aTHX)
static void S_finish_export_lexical(pTHX)
{
    intro_my();

    LEAVE;
}

OP *pp_builtin_export_lexically(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("export_lexically", true);

    if(!PL_compcv)
        Perl_croak(aTHX_
                "export_lexically can only be called at compile time");

    if(items % 2)
        Perl_croak(aTHX_ "Odd number of elements in export_lexically");

    SP -= items;
    SV **args = SP + 1;

    for(int i = 0; i < items; i += 2) {
        SV *name = args[i];
        SV *ref  = args[i+1];

        if(!SvROK(ref))
            /* diag_listed_as: Expected %s reference in export_lexically */
            Perl_croak(aTHX_ "Expected a reference in export_lexically");

        char sigil = SvPVX(name)[0];
        SV *rv = SvRV(ref);

        const char *bad = NULL;
        switch(sigil) {
            default:
                /* overwrites the pointer on the stack; but this is fine, the
                 * caller's value isn't modified */
                args[i] = name = sv_2mortal(Perl_newSVpvf(aTHX_ "&%" SVf, SVfARG(name)));

                /* FALLTHROUGH */
            case '&':
                if(SvTYPE(rv) != SVt_PVCV)
                    bad = "a CODE";
                break;

            case '$':
                /* Permit any of SVt_NULL to SVt_PVMG. Technically this also
                 * includes SVt_INVLIST but it isn't thought possible for pureperl
                 * code to ever manage to see one of those. */
                if(SvTYPE(rv) > SVt_PVMG)
                    bad = "a SCALAR";
                break;

            case '@':
                if(SvTYPE(rv) != SVt_PVAV)
                    bad = "an ARRAY";
                break;

            case '%':
                if(SvTYPE(rv) != SVt_PVHV)
                    bad = "a HASH";
                break;
        }

        if(bad)
            Perl_croak(aTHX_ "Expected %s reference in export_lexically", bad);
    }

    prepare_export_lexical();

    for(int i = 0; i < items; i += 2) {
        SV *name = args[i];
        SV *ref  = args[i+1];

        export_lexical(name, SvRV(ref));
    }

    finish_export_lexical();

    RETURN;
}

OP *pp_builtin_is_tainted(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("is_tainted", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    SvGETMAGIC(arg);
    PUSHs(boolSV(SvTAINTED(arg)));

    RETURN;
}
#endif /* !HAVE_PERL_VERSION(5, 38, 0) */

#if !HAVE_PERL_VERSION(5, 36, 0)

#define G_LIST G_ARRAY

/* Perl v5.36 added the 'scalar' warning category; before that such warnings
 * appeared in 'void' */
#define WARN_SCALAR WARN_VOID

#include <is_SPACE_utf8_safe_backwards.h>

#ifndef isSPACE_utf8_safe
#  define isSPACE_utf8_safe(start, end)  isSPACE_utf8(start)
#endif

#define report_uninit(sv)  Perl_report_uninit(aTHX_ sv)

#if !HAVE_PERL_VERSION(5, 28, 0)
#  define sv_rvunweaken(sv)  S_sv_rvunweaken(aTHX_ sv)
static void S_sv_rvunweaken(pTHX_ SV *sv)
{
    if(!SvOK(sv))
        return;
    if(!SvROK(sv))
        croak("Can't unweaken a nonreference");
    else if(!SvWEAKREF(sv)) {
        if(ckWARN(WARN_MISC))
            warn("Reference is not weak");
        return;
    }
    else if(SvREADONLY(sv))
        croak_no_modify();

    SV *tsv = SvRV(sv);
    SvWEAKREF_off(sv);
    SvROK_on(sv);
    SvREFCNT_inc_NN(tsv);
    Perl_sv_del_backref(aTHX_ tsv, sv);
}
#endif

#if !HAVE_PERL_VERSION(5, 24, 0)
#  ifndef sv_sethek
#    define sv_sethek(a, b)  Perl_sv_sethek(aTHX_ a, b)
#  endif

#  define sv_ref(dst, sv, ob)  S_sv_ref(aTHX_ dst, sv, ob)
static SV *S_sv_ref(pTHX_ SV *dst, SV *sv, int ob)
{
    /* copied from perl 5.22's sv.c */
    if(!dst)
        dst = sv_newmortal();

    if(ob && SvOBJECT(sv)) {
        if(HvNAME_get(SvSTASH(sv)))
            sv_sethek(dst, HvNAME_HEK(SvSTASH(sv)));
        else
            sv_setpvs(dst, "__ANON__");
    }
    else {
        const char *reftype = sv_reftype(sv, 0);
        sv_setpv(dst, reftype);
    }

    return dst;
}
#endif

OP *pp_builtin_blessed(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("blessed", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    SvGETMAGIC(arg);
    if(!SvROK(arg) || !SvOBJECT(SvRV(arg)))
        PUSHs(&PL_sv_undef);
    else
        PUSHs(sv_mortalcopy(sv_ref(NULL, SvRV(arg), TRUE)));

    RETURN;
}

OP *pp_builtin_ceil(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("ceil", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    mPUSHn(Perl_ceil(SvNV(arg)));

    RETURN;
}

OP *pp_builtin_false(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("false", true);
    if(items)
        croak_xs_usage(find_runcv(0), "");

    XPUSHs(&PL_sv_no);

    RETURN;
}

OP *pp_builtin_floor(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("floor", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    mPUSHn(Perl_floor(SvNV(arg)));

    RETURN;
}

OP *pp_builtin_indexed(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));

    SP -= items;

    switch(GIMME_V) {
        case G_VOID:
            Perl_ck_warner(aTHX_ packWARN(WARN_VOID),
                "Useless use of %s in void context", "builtin::indexed");
            RETURN;

        case G_SCALAR:
            Perl_ck_warner(aTHX_ packWARN(WARN_SCALAR),
                "Useless use of %s in scalar context", "builtin::indexed");
            mPUSHi(items * 2);

            RETURN;

        case G_LIST:
            break;
    }

    SSize_t retcount = items * 2;
    EXTEND(SP, retcount);

    SV **stack = SP + 1;

    /* Copy from [items-1] down to [0] so we don't have to make
     * temporary copies */
    for(SSize_t index = (SSize_t)items - 1; index >= 0; index--) {
        /* Copy, not alias */
        stack[index * 2 + 1] = sv_mortalcopy(stack[index]);
        stack[index * 2]     = sv_2mortal(newSViv(index));
    }

    SP += retcount;

    RETURN;
}

OP *pp_builtin_is_weak(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("is_weak", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    PUSHs(boolSV(SvROK(arg) && SvWEAKREF(arg)));

    RETURN;
}

OP *pp_builtin_refaddr(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("refaddr", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    SvGETMAGIC(arg);
    if(!SvROK(arg))
        PUSHs(&PL_sv_undef);
    else
        mPUSHu(PTR2UV(SvRV(arg)));

    RETURN;
}

OP *pp_builtin_reftype(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("reftype", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    SvGETMAGIC(arg);
    if(!SvROK(arg))
        PUSHs(&PL_sv_undef);
    else
        PUSHs(sv_2mortal(newSVpv(sv_reftype(SvRV(arg), FALSE), 0)));

    RETURN;
}

static XOP xop_builtin_trim;
OP *pp_builtin_trim(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("trim", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *source = TOPs;

    STRLEN len;
    const U8 *start;
    SV *dest;

    SvGETMAGIC(source);

    if (SvOK(source))
        start = (const U8*)SvPV_nomg_const(source, len);
    else {
        if (ckWARN(WARN_UNINITIALIZED))
            report_uninit(source);
        start = (const U8*)"";
        len = 0;
    }

    if (DO_UTF8(source)) {
        const U8 *end = start + len;

        /* Find the first non-space */
        while(len) {
            STRLEN thislen;
            if (!isSPACE_utf8_safe(start, end))
                break;
            start += (thislen = UTF8SKIP(start));
            len -= thislen;
        }

        /* Find the final non-space */
        STRLEN thislen;
        const U8 *cur_end = end;
        while ((thislen = is_SPACE_utf8_safe_backwards(cur_end, start))) {
            cur_end -= thislen;
        }
        len -= (end - cur_end);
    }
    else if (len) {
        while(len) {
            if (!isSPACE_L1(*start))
                break;
            start++;
            len--;
        }

        while(len) {
            if (!isSPACE_L1(start[len-1]))
                break;
            len--;
        }
    }

    dest = sv_newmortal();

    if (SvPOK(dest) && (dest == source)) {
        sv_chop(dest, (const char *)start);
        SvCUR_set(dest, len);
    }
    else {
        SvUPGRADE(dest, SVt_PV);
        SvGROW(dest, len + 1);

        Copy(start, SvPVX(dest), len, U8);
        SvPVX(dest)[len] = '\0';
        SvPOK_on(dest);
        SvCUR_set(dest, len);

        if (DO_UTF8(source))
            SvUTF8_on(dest);
        else
            SvUTF8_off(dest);

        if (SvTAINTED(source))
            SvTAINT(dest);
    }

    SvSETMAGIC(dest);
    TOPs = dest;

    RETURN;
}

OP *pp_builtin_true(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("true", true);
    if(items)
        croak_xs_usage(find_runcv(0), "");

    XPUSHs(&PL_sv_yes);

    RETURN;
}

OP *pp_builtin_unweaken(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("weaken", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    sv_rvunweaken(arg);

    RETURN;
}

OP *pp_builtin_weaken(pTHX)
{
    dSP;
    U32 items = av_count(GvAV(PL_defgv));
    warn_experimental_builtin("weaken", true);
    if(items != 1)
        croak_xs_usage(find_runcv(0), "arg");

    SV *arg = POPs;
    sv_rvweaken(arg);

    RETURN;
}

static const char builtin_not_recognised[] = "'%" SVf "' is not recognised as a builtin function";

XS(XS_builtin_import);
XS(XS_builtin_import)
{
    dXSARGS;

    if(!PL_compcv)
        Perl_croak(aTHX_
                "builtin::import can only be called at compile time");

    prepare_export_lexical();

    for(int i = 1; i < items; i++) {
        SV *sym = ST(i);
        if(strEQ(SvPV_nolen(sym), "import"))
            Perl_croak(aTHX_ builtin_not_recognised, sym);

        SV *ampname = sv_2mortal(Perl_newSVpvf(aTHX_ "&%" SVf, SVfARG(sym)));
        SV *fqname = sv_2mortal(Perl_newSVpvf(aTHX_ "builtin::%" SVf, SVfARG(sym)));

        CV *cv = get_cv(SvPV_nolen(fqname), SvUTF8(fqname) ? SVf_UTF8 : 0);
        if(!cv)
            Perl_croak(aTHX_ builtin_not_recognised, sym);

        export_lexical(ampname, (SV *)cv);
    }

    finish_export_lexical();
}

#endif /* !HAVE_PERL_VERSION(5, 36, 0) */

#define newCUSTOMOP_SUB(name, proto, ppfunc)  S_newCUSTOMOP_SUB(aTHX_ name, proto, ppfunc)
static CV *S_newCUSTOMOP_SUB(pTHX_ const char *name, const char *proto, OP *(*ppfunc)(pTHX))
{
    I32 floor_ix = start_subparse(FALSE, 0);

    OP *body = newOP(OP_CUSTOM, 0);
    body->op_ppaddr = ppfunc;

    OP *nameop = newSVOP(OP_CONST, 0, newSVpv(name, 0));
    OP *protoop = NULL;
    if(proto)
        protoop = newSVOP(OP_CONST, 0, newSVpv(proto, 0));
    CV *cv = newATTRSUB(floor_ix, nameop, protoop, NULL, body);
    return cv;
}

MODULE = builtin    PACKAGE = builtin

BOOT:
#if !HAVE_PERL_VERSION(5, 38, 0)
    {
        CV *trim_cv;
#  if HAVE_PERL_VERSION(5, 36, 0)
        trim_cv = get_cv("builtin::trim", 0);
#  else
        trim_cv = newCUSTOMOP_SUB("builtin::trim", "$", &pp_builtin_trim);
        XopENTRY_set(&xop_builtin_trim, xop_name, "trim");
        XopENTRY_set(&xop_builtin_trim, xop_desc, "trim");
        Perl_custom_op_register(aTHX_ &pp_builtin_trim, &xop_builtin_trim);
#  endif
        assert(trim_cv);

        /* prototype is stored directly in the PV slot */
        sv_setpv((SV *)trim_cv, "$");
    }

    newCUSTOMOP_SUB("builtin::is_tainted",       "$",  &pp_builtin_is_tainted);
    newCUSTOMOP_SUB("builtin::export_lexically", NULL, &pp_builtin_export_lexically);
#endif
#if HAVE_PERL_VERSION(5, 36, 0)
    warning_offset = WARN_EXPERIMENTAL__BUILTIN;
#else
    {
        HV *offsets_hv;
        SV **svp;

        dSP;

        ENTER;
        SAVETMPS;
        EXTEND(SP, 1);

        PUSHMARK(SP);
        mPUSHp("experimental::builtin", 21);
        PUTBACK;

        call_pv("warnings::register_categories", G_VOID);

        FREETMPS;
        LEAVE;

        offsets_hv = get_hv("warnings::Offsets", 0);
        assert(offsets_hv);

        svp = hv_fetchs(offsets_hv, "experimental::builtin", 0);
        assert(svp);
        assert(*svp);

        warning_offset = SvUV(*svp) / 2;
    }

    newCUSTOMOP_SUB("builtin::blessed",  "$",  &pp_builtin_blessed);
    newCUSTOMOP_SUB("builtin::ceil",     "$",  &pp_builtin_ceil);
    newCUSTOMOP_SUB("builtin::false",    "",   &pp_builtin_false);
    newCUSTOMOP_SUB("builtin::floor",    "$",  &pp_builtin_floor);
    newCUSTOMOP_SUB("builtin::indexed",  NULL, &pp_builtin_indexed);
    newCUSTOMOP_SUB("builtin::is_weak",  "$",  &pp_builtin_is_weak);
    newCUSTOMOP_SUB("builtin::refaddr",  "$",  &pp_builtin_refaddr);
    newCUSTOMOP_SUB("builtin::reftype",  "$",  &pp_builtin_reftype);
    newCUSTOMOP_SUB("builtin::true",     "",   &pp_builtin_true);
    newCUSTOMOP_SUB("builtin::unweaken", "$",  &pp_builtin_unweaken);
    newCUSTOMOP_SUB("builtin::weaken",   "$",  &pp_builtin_weaken);

    newXS_flags("builtin::import", &XS_builtin_import, __FILE__, NULL, 0);
#endif
