/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if !HAVE_PERL_VERSION(5,16,0)
#  define true  TRUE
#  define false FALSE

/* CvPROTO was just stored in SvPV */
#  define CvPROTO(cv)       SvPVX(cv)
#  define CvPROTOLEN(cv)    SvCUR(cv)
/* HvNAMELEN did not exist; stash names cannot contain \0 */
#  define HvNAMELEN(stash)  strlen(HvNAME(stash))
/* HvNAME and GvNAME could never be UTF-8 */
#  define HvNAMEUTF8(hv)    0
#  define GvNAMEUTF8(gv)    0

#  define gv_init_sv(gv, stash, sv, flags)  \
                            gv_init(gv, stash, SvPV_nolen(sv), SvCUR(sv), SvUTF8(sv) | flags)
#  define gv_init_pvn(gv, stash, pv, len, flags)  \
                            gv_init(gv, stash, pv, len, flags)
#endif

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_SUB_SIGNATURES
#endif

#ifndef av_count
#  define av_count(av)  (AvFILL(av)+1)
#endif

#ifndef G_LIST
#  define G_LIST  G_ARRAY
#endif

#ifndef CvREFCNT_inc
#  define CvREFCNT_inc(cv)  ((CV *)SvREFCNT_inc((SV *)(cv)))
#endif

#if defined (DEBUGGING) && defined(PERL_USE_GCC_BRACE_GROUPS)
#  define _MUST_SVTYPE_FROM_REFSV(rsv, type, svt)  \
    ({ type sv = (type)(SvUV(SvRV(rsv))); assert(sv && SvTYPE(sv) == svt); sv; })
#else
#  define _MUST_SVTYPE_FROM_REFSV(rsv, type, svt)  \
    ((type)(SvUV(SvRV(rsv))))
#endif

#define MUST_STASH_FROM_REFSV(sv)  _MUST_SVTYPE_FROM_REFSV(sv, HV *, SVt_PVHV)
#define MUST_GV_FROM_REFSV(sv)     _MUST_SVTYPE_FROM_REFSV(sv, GV *, SVt_PVGV)
#define MUST_CV_FROM_REFSV(sv)     _MUST_SVTYPE_FROM_REFSV(sv, CV *, SVt_PVCV)

#define SV_FROM_REFSV(sv)  \
  ((SV *)(SvUV(SvRV(sv))))

#define wrap_sv_refsv(sv)  S_wrap_sv_refsv(aTHX_ sv)
SV *S_wrap_sv_refsv(pTHX_ SV *sv)
{
  const char *metaclass;
  switch(SvTYPE(sv)) {
    case SVt_PVGV: metaclass = "meta::glob";       break;
    case SVt_PVCV: metaclass = "meta::subroutine"; break;
    default:       metaclass = "meta::variable";   break;
  }
  return sv_setref_uv(newSV(0), metaclass, PTR2UV(SvREFCNT_inc(sv)));
}

#define wrap_stash(stash)  S_wrap_stash(aTHX_ stash)
static SV *S_wrap_stash(pTHX_ HV *stash)
{
  // TODO: Do we need to refcnt_inc stash?
  return sv_setref_uv(newSV(0), "meta::package", PTR2UV(stash));
}

struct CVwithOP {
  CV *cv;
  OP *op;
};

#define wrap_cv_signature(cv, op)  S_wrap_cv_signature(aTHX_ cv, op)
static SV *S_wrap_cv_signature(pTHX_ CV *cv, OP *op)
{
  struct CVwithOP ret = { .cv = CvREFCNT_inc(cv), .op = op, };
  return sv_setref_pvn(newSV(0), "meta::subsignature", (const char *)&ret, sizeof(ret));
}

#ifdef SVf_QUOTEDPREFIX
#  define CROAK_QUOTED_PREFIX(msg, arg)  \
    croak(msg "%" SVf_QUOTEDPREFIX, arg)
#else
#  define CROAK_QUOTED_PREFIX(msg, arg)  \
    croak(msg "\"%" SVf "\"", arg)
#endif

#define gv_is_empty(gv)  S_gv_is_empty(aTHX_ gv)
static bool S_gv_is_empty(pTHX_ GV *gv)
{
  if(SvFAKE(gv) ||
    GvSV(gv) ||
    GvAV(gv) ||
    GvHV(gv) ||
    GvCV(gv) ||
    GvIO(gv) ||
    GvFORM(gv))
    return false;

  /* TODO: any other safety checks? */
  return true;
}

/* Some helpers for warnings.pm
 *
 * The custom warning categories defined by warnings.pm are implemented
 * entirely in the Perl code, so interacting with it means a lot of call_pv()
 * wrapper functions.
 *
 * The warnings::warnif function is intended to be called from Perl, and
 * presumes the caller stack will have a corresponding caller frame that it
 * should skip. Since we're calling it here from XSUBs that does not happen,
 * so we have to take extra measures to ensure it sees the correct caller
 * context.
 */

#if HAVE_PERL_VERSION(5, 28, 0)
#  define HAVE_WARNINGS_WARNIF_AT_LEVEL
#endif

#define warnings_register_category(category)  S_warnings_register_category(aTHX_ category)
static void S_warnings_register_category(pTHX_ const char *category)
{
  dSP;
  ENTER;

  EXTEND(SP, 1);
  PUSHMARK(SP);
  mPUSHp(category, strlen(category));
  PUTBACK;

  call_pv("warnings::register_categories", G_VOID);

  LEAVE;
}

#define warnings_warnsvif(category, msv)  S_warnings_warnsvif(aTHX_ category, msv)
static void S_warnings_warnsvif(pTHX_ const char *category, SV *msv)
{
  dSP;
  ENTER;

#ifdef HAVE_WARNINGS_WARNIF_AT_LEVEL
  EXTEND(SP, 3);
  PUSHMARK(SP);
  mPUSHp(category, strlen(category));
  mPUSHi(-1); // level = -1 because our XSUB does not have a caller frame
  PUSHs(msv);
  PUTBACK;

  call_pv("warnings::warnif_at_level", G_VOID);
#else
  // warnings::warnif needs to see an extra call frame here. There's no way
  // to hack this up using cx_pushblock etc... as that only works for pureperl
  // CVs. We'll just have to use a trampoline
  EXTEND(SP, 2);
  PUSHMARK(SP);
  mPUSHp(category, strlen(category));
  PUSHs(msv);
  PUTBACK;

  call_pv("meta::warnif_trampoline", G_VOID);
#endif

  LEAVE;
}

#define META_WARNING_CATEGORY "meta::experimental"

#define warn_experimental(fname)  S_warn_experimental(aTHX_ fname)
static void S_warn_experimental(pTHX_ const char *fname)
{
  warnings_warnsvif(META_WARNING_CATEGORY,
    sv_2mortal(newSVpvf("%s is experimental and may be changed or removed without notice", fname)));
}

#define warn_sub_deprecated(cv)  S_warn_sub_deprecated(aTHX_ cv)
static void S_warn_sub_deprecated(pTHX_ CV *cv)
{
  GV *gv = CvGV(cv);

  Perl_ck_warner(aTHX_ packWARN(WARN_DEPRECATED),
    "%s::%s() is deprecated and may be removed without notice",
      GvNAME(GvSTASH(gv)), GvNAME(gv));
}

#if HAVE_PERL_VERSION(5, 38, 0)
#  define HAVE_FEATURE_CLASS
#endif

// Flags for get-alike methods
enum {
  GET_OR_UNDEF,
  GET_OR_THROW,
  GET_OR_ADD,
  ADD_OR_THROW,

  GET_OR_UNDEF_WITH_WARNING,
};

static SV *S_get_metaglob_slot(pTHX_ SV *metaglob, U8 svt, const char *slotname, U8 ix)
{
  GV *gv = MUST_GV_FROM_REFSV(metaglob);
  SV *ret;
  switch(svt) {
    case SVt_PVMG: ret =       GvSV (gv); break;
    case SVt_PVAV: ret = (SV *)GvAV (gv); break;
    case SVt_PVHV: ret = (SV *)GvHV (gv); break;
    case SVt_PVCV: ret = (SV *)GvCVu(gv); break;
  }

  if(ret)
    return wrap_sv_refsv(ret);

  switch(ix) {
    case GET_OR_THROW:
      croak("Glob does not have a %s slot", slotname);
    case GET_OR_UNDEF_WITH_WARNING:
    case GET_OR_UNDEF:
      return &PL_sv_undef;
  }
}

static void split_fqname(const char *namepv, STRLEN namelen,
  const char **pkgnamepvp, STRLEN *pkgnamelenp, const char **basenamepvp, STRLEN *basenamelenp)
{
  STRLEN pkgnamelen = 0;
  const char *pkgnamepv = NULL;
  STRLEN basenamelen = namelen;
  const char *basenamepv = namepv;

  const char *s = namepv + namelen - 2;
  for(/**/; s > namepv; s--) {
    if(s[0] != ':' || s[1] != ':')
      continue;

    /* s now points at the final occurence of '::' in the name
     * pkgname is namepv up to s, basename is s+2 up to its original end */
    pkgnamepv   = namepv;
    pkgnamelen  = s - namepv;
    basenamepv  = s + 2;
    basenamelen = namelen - (basenamepv - namepv);
    break;
  }

  if(pkgnamepvp)   *pkgnamepvp   = pkgnamepv;
  if(pkgnamelenp)  *pkgnamelenp  = pkgnamelen;
  if(basenamepvp)  *basenamepvp  = basenamepv;
  if(basenamelenp) *basenamelenp = basenamelen;
}

MODULE = meta    PACKAGE = meta

SV *
get_package(SV *pkgname)
  CODE:
    warn_experimental("meta::get_package");
    RETVAL = wrap_stash(gv_stashsv(pkgname, GV_ADD));
  OUTPUT:
    RETVAL

SV *
get_this_package()
  CODE:
    warn_experimental("meta::get_this_package");
    RETVAL = wrap_stash(CopSTASH(PL_curcop));
  OUTPUT:
    RETVAL

SV *
for_reference(SV *ref)
  CODE:
    warn_experimental("meta::for_reference");
    if(!SvROK(ref))
      croak("meta::for_reference requires a reference value");
    /* TODO: maybe there's some kinds of SV we'll forbid here? */
    RETVAL = wrap_sv_refsv(SvRV(ref));
  OUTPUT:
    RETVAL

MODULE = meta    PACKAGE = meta::package

SV *
get(SV *cls, SV *pkgname)
  CODE:
    if(SvROK(cls))
      croak("meta::package->get(name) should not be invoked on an instance "
          "(did you mean to call one of the ->get_... methods?)");
    warn_experimental("meta::package->get");
    RETVAL = wrap_stash(gv_stashsv(pkgname, GV_ADD));
  OUTPUT:
    RETVAL

bool
is_class(SV *metapkg)
  CODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
#ifdef HAVE_FEATURE_CLASS
    RETVAL = HvSTASH_IS_CLASS(stash);
#else
    RETVAL = false;
#endif
  }
  OUTPUT:
    RETVAL

SV *
name(SV *metapkg)
  CODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    RETVAL = newSVpvn_flags(HvNAME(stash), HvNAMELEN(stash), HvNAMEUTF8(stash) ? SVf_UTF8 : 0);
  }
  OUTPUT:
    RETVAL

SV *
get_glob(SV *metapkg, SV *name)
  ALIAS:
    can_glob = GET_OR_UNDEF_WITH_WARNING
    get_glob = GET_OR_THROW
    try_get_glob = GET_OR_UNDEF
  CODE:
  {
    if(ix == GET_OR_UNDEF_WITH_WARNING)
      warn_sub_deprecated(cv);
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    HE *he = hv_fetch_ent(stash, name, 0, 0);
    if(he) {
      GV *gv = (GV *)HeVAL(he);
      assert(SvTYPE(gv) == SVt_PVGV);
      RETVAL = wrap_sv_refsv((SV *)gv);
    }
    else switch(ix) {
      case GET_OR_THROW:
        CROAK_QUOTED_PREFIX("Package does not contain a glob called ", SVfARG(name));
      case GET_OR_UNDEF_WITH_WARNING:
      case GET_OR_UNDEF:
        RETVAL = &PL_sv_undef;
        break;
    }
  }
  OUTPUT:
    RETVAL

SV *
get_symbol(SV *metapkg, SV *name, SV *value = NULL)
  ALIAS:
    can_symbol = GET_OR_UNDEF_WITH_WARNING
    get_symbol = GET_OR_THROW
    try_get_symbol = GET_OR_UNDEF
    get_or_add_symbol = GET_OR_ADD
    add_symbol = ADD_OR_THROW
  CODE:
  {
    if(ix == GET_OR_UNDEF_WITH_WARNING)
      warn_sub_deprecated(cv);

    bool create = ix >= GET_OR_ADD;

    if(create) {
      if(value && !SvROK(value))
        croak("Expected a reference for the new value to add_symbol");
    }
    else {
      if(value)
        croak("meta::glob->get_symbol args");
    }

    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    char sigil = SvPV_nolen(name)[0];
    SV *valuesv = NULL;

    if(value) {
      valuesv = SvRV(value);
      switch(sigil) {
        case '*':
          croak("TODO: Cannot currently cope with adding GLOBs via ->add_symbol");
          break;
        case '$':
          if(SvTYPE(valuesv) > SVt_PVMG)
            croak("Expected a SCALAR reference for the new value to add_symbol('$...')");
          break;
        case '@':
          if(SvTYPE(valuesv) != SVt_PVAV)
            croak("Expected a ARRAY reference for the new value to add_symbol('@...')");
          break;
        case '%':
          if(SvTYPE(valuesv) != SVt_PVHV)
            croak("Expected a HASH reference for the new value to add_symbol('%%...')");
          break;
        case '&':
          if(SvTYPE(valuesv) != SVt_PVCV)
            croak("Expected a CODE reference for the new value to add_symbol('&...')");
          break;
        default:
          croak("Unrecognised name sigil for add_symbol");
      }
    }

    SV *basename = newSVpvn_flags(SvPV_nolen(name) + 1, SvCUR(name) - 1,
        (SvUTF8(name) ? SVf_UTF8 : 0) | SVs_TEMP);
    SV *ret = NULL;
    HE *he = hv_fetch_ent(stash, basename, create ? GV_ADD : 0, 0);
    if(!he)
      goto gv_missing;
    SV *sv = HeVAL(he);

    if(create && SvTYPE(sv) != SVt_PVGV) {
      gv_init_sv((GV *)sv, stash, basename, 0);
      GvMULTI_on(sv);
    }

    if(SvTYPE(sv) == SVt_PVGV) {
      GV *gv = (GV *)sv;
      switch(sigil) {
        case '*': ret = (SV *)      gv;  break;
        case '$': ret =       GvSV (gv); break;
        case '@': ret = (SV *)GvAV (gv); break;
        case '%': ret = (SV *)GvHV (gv); break;
        case '&': ret = (SV *)GvCVu(gv); break;
      }
    }
    else if(SvROK(sv)) {
      // GV-less optimisation; this is an RV to one kind of element
      SV *rv = SvRV(sv);
      switch(sigil) {
        case '*': /* We know it isn't an SVt_PVGV */ ret = NULL; break;
        case '$': ret = (SvTYPE(rv) <= SVt_PVMG) ? rv : NULL; break;
        case '@': ret = (SvTYPE(rv) == SVt_PVAV) ? rv : NULL; break;
        case '%': ret = (SvTYPE(rv) == SVt_PVHV) ? rv : NULL; break;
        case '&': ret = (SvTYPE(rv) == SVt_PVCV) ? rv : NULL; break;
      }
    }
    else
      croak("TODO: Not sure what to do with SvTYPE(sv)=%d\n", SvTYPE(sv));

    if(ix == ADD_OR_THROW && ret)
      CROAK_QUOTED_PREFIX("Already have a symbol named ", SVfARG(name));

    if(!ret && create) {
      GV *gv = (GV *)sv;
      ret = valuesv;

      switch(sigil) {
        case '*':
          croak("Cannot create the glob slot itself");
        case '$':
          if(!ret)
            ret = newSV(0);
          GvSV(gv) = SvREFCNT_inc(ret);
          break;
        case '@':
          if(!ret)
            ret = (SV *)newAV();
          GvAV(gv) = (AV *)SvREFCNT_inc(ret);
          break;
        case '%':
          if(!ret)
            ret = (SV *)newHV();
          GvHV(gv) = (HV *)SvREFCNT_inc(ret);
          break;
        case '&':
          if(!ret)
            croak("Cannot create a subroutine by ->get_or_add_symbol");
          GvCV_set(gv, (CV *)SvREFCNT_inc(ret));
          GvCVGEN(gv) = 0;
          break;
      }
    }

    gv_missing:
    if(ret)
      RETVAL = (GIMME_V != G_VOID) ? wrap_sv_refsv(ret) : &PL_sv_undef;
    else switch(ix) {
      case GET_OR_THROW:
        CROAK_QUOTED_PREFIX("Package has no symbol named ", SVfARG(name));
      case GET_OR_UNDEF_WITH_WARNING:
      case GET_OR_UNDEF:
        RETVAL = &PL_sv_undef;
        break;
    }
  }
  OUTPUT:
    RETVAL

SV *
add_named_sub(SV *metapkg, SV *name, SV *value)
  CODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);

    if(!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVCV)
      croak("Expected a CODE reference for the new value to add_named_sub");
    CV *cv = (CV *)SvRV(value);

    HE *he = hv_fetch_ent(stash, name, GV_ADD, 0);
    GV *gv;
    {
      assert(he);
      SV *sv = HeVAL(he);
      if(SvTYPE(sv) != SVt_PVGV) {
        gv_init_sv((GV *)sv, stash, name, 0);
        GvMULTI_on(sv);
      }

      gv = (GV *)sv;
    }

    if(GvCVu(gv))
      CROAK_QUOTED_PREFIX("Already have a symbol named &", SVfARG(name));

    /* Set these in the right order so the name GV works properly */
    GvCV_set(gv, CvREFCNT_inc(cv));
    GvCVGEN(gv) = 0;
    CvGV_set(cv, gv);

    RETVAL = wrap_sv_refsv((SV *)cv);
  }
  OUTPUT:
    RETVAL

void
remove_symbol(SV *metapkg, SV *name)
  CODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    char sigil = SvPV_nolen(name)[0];
    SV *basename = newSVpvn_flags(SvPV_nolen(name) + 1, SvCUR(name) - 1,
        (SvUTF8(name) ? SVf_UTF8 : 0) | SVs_TEMP);
    SV *ret = NULL;
    HE *he = hv_fetch_ent(stash, basename, 0, 0);
    if(!he)
      goto missing;
    SV *sv = HeVAL(he);

    if(SvTYPE(sv) == SVt_PVGV) {
      GV *gv = (GV *)sv;
      SV *sv = NULL;
      switch(sigil) {
        case '*': croak("TODO: Cannot ->remove_symbol on a glob"); break;
        case '$':
          sv = GvSV(gv); GvSV(gv) = NULL;
          break;
        case '@':
          sv = (SV *)GvAV(gv); GvAV(gv) = NULL;
          break;
        case '%':
          sv = (SV *)GvHV(gv); GvHV(gv) = NULL;
          break;
        case '&':
          sv = (SV *)GvCVu(gv); GvCV_set(gv, NULL);
          GvCVGEN(gv) = 0;
          break;
      }

      if(!sv)
        missing:
        CROAK_QUOTED_PREFIX("Cannot remove non-existing symbol from package: ", SVfARG(name));

      SvREFCNT_dec(sv);

      /* TODO: Perl core has a gv_try_downgrade() we could call here, but XS
       * modules can't see it
       */
      if(gv_is_empty(gv))
        hv_delete_ent(stash, basename, G_DISCARD, 0);
    }
    else if(SvROK(sv)) {
      // GV-less optimisation; this is an RV to one kind of element
      SV *rv = SvRV(sv);
      switch(sigil) {
        case '*': /* We know it isn't a SVt_PVGV */ goto missing; break;
        case '$': if(SvTYPE(rv)  > SVt_PVMG) goto missing; break;
        case '@': if(SvTYPE(rv) != SVt_PVAV) goto missing; break;
        case '%': if(SvTYPE(rv) != SVt_PVHV) goto missing; break;
        case '&': if(SvTYPE(rv) != SVt_PVCV) goto missing; break;
      }

      hv_delete_ent(stash, basename, G_DISCARD, 0);
    }
    else
      croak("TODO: Not sure what to do with SvTYPE(sv)=%d\n", SvTYPE(sv));
  }

void
list_globs(SV *metapkg)
  ALIAS:
    list_all_globs        = 0
    list_globs            = 1
    list_subpackage_globs = 2
  PPCODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    UV retcount = 0;
    hv_iterinit(stash);
    HE *he;
    while((he = hv_iternext(stash))) {
      GV *gv = (GV *)HeVAL(he);
      assert(SvTYPE(gv) == SVt_PVGV);
      if(ix) {
        STRLEN keylen;
        const char *keypv = HePV(he, keylen);
        bool is_subpackage = keylen > 2 && keypv[keylen-2] == ':' && keypv[keylen-1] == ':';
        if(ix == 1 && is_subpackage)
          continue;
        if(ix == 2 && !is_subpackage)
          continue;
      }
      EXTEND(SP, 1);
      mPUSHs(wrap_sv_refsv((SV *)gv));
      retcount++;
    }
    XSRETURN(retcount);
  }

void
_list_symbols(SV *metapkg, SV *sigils)
  PPCODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    const char *sigilfilter = sigils && SvOK(sigils) ? SvPV_nolen(sigils) : NULL;

    UV retcount = 0;
    hv_iterinit(stash);
    HE *he;
    while((he = hv_iternext(stash))) {
      STRLEN keylen;
      const char *keypv = HePV(he, keylen);
      bool is_subpackage = keylen > 2 && keypv[keylen-2] == ':' && keypv[keylen-1] == ':';
      if(is_subpackage)
        continue;
#define PUSH_SVREF_IF(sv, sigil)                               \
      if((sv) &&                                               \
          (!sigilfilter || strchr(sigilfilter, sigil))) {      \
        SV *_sv = (SV *)(sv);                                  \
        SV *namesv = newSVpvf("%c%.*s", sigil, keylen, keypv); \
        if(HeUTF8(he)) SvUTF8_on(namesv);                      \
        EXTEND(SP, 2);                                         \
        mPUSHs(namesv);                                        \
        mPUSHs(wrap_sv_refsv(_sv));                            \
        retcount += 2;                                         \
      }

      SV *sv = HeVAL(he);
      if(SvTYPE(sv) == SVt_PVGV) {
        GV *gv = (GV *)sv;

        PUSH_SVREF_IF(GvSV (gv), '$');
        PUSH_SVREF_IF(GvAV (gv), '@');
        PUSH_SVREF_IF(GvHV (gv), '%');
        PUSH_SVREF_IF(GvCVu(gv), '&');
      }
      else if(SvROK(sv)) {
        // GV-less optimisation; this is an RV to one kind of element
        SV *rv = SvRV(sv);
        U8 type = SvTYPE(rv);

        PUSH_SVREF_IF(type <= SVt_PVMG ? rv : NULL, '$');
        PUSH_SVREF_IF(type == SVt_PVAV ? rv : NULL, '@');
        PUSH_SVREF_IF(type == SVt_PVHV ? rv : NULL, '%');
        PUSH_SVREF_IF(type == SVt_PVCV ? rv : NULL, '&');
      }
      else
        croak("TODO: Not sure what to do with SvTYPE(sv)=%d\n", SvTYPE(sv));
    }
#undef PUSH_SVREF_IF
    XSRETURN(retcount);
  }

void
list_subpackages(SV *metapkg)
  PPCODE:
  {
    HV *stash = MUST_STASH_FROM_REFSV(metapkg);
    UV retcount = 0;
    hv_iterinit(stash);
    HE *he;
    while((he = hv_iternext(stash))) {
      STRLEN keylen;
      const char *keypv = HePV(he, keylen);
      bool is_subpackage = keylen > 2 && keypv[keylen-2] == ':' && keypv[keylen-1] == ':';
      if(!is_subpackage)
        continue;

      GV *gv = (GV *)HeVAL(he);
      assert(SvTYPE(gv) == SVt_PVGV);
      HV *substash = GvHV(gv);

      EXTEND(SP, 2);

      mPUSHp(keypv, keylen - 2);
      if(HeUTF8(he))
        SvUTF8_on(*SP);

      mPUSHs(wrap_stash(substash));

      retcount += 2;
    }
    XSRETURN(retcount);
  }

MODULE = meta    PACKAGE = meta::symbol

void
DESTROY(SV *metasym)
  CODE:
  {
    SV *sv = SV_FROM_REFSV(metasym);
    SvREFCNT_dec(sv);
  }

bool
is_scalar(SV *metasym)
  CODE:
  {
    SV *sv = SV_FROM_REFSV(metasym);
    RETVAL = SvTYPE(sv) <= SVt_PVMG;
  }
  OUTPUT:
    RETVAL

bool
_is_type(SV *metasym)
  ALIAS:
    is_glob       = SVt_PVGV
    is_array      = SVt_PVAV
    is_hash       = SVt_PVHV
    is_subroutine = SVt_PVCV
  CODE:
  {
    SV *sv = SV_FROM_REFSV(metasym);
    RETVAL = SvTYPE(sv) == ix;
  }
  OUTPUT:
    RETVAL

SV *
reference(SV *metasym)
  CODE:
  {
    SV *sv = SV_FROM_REFSV(metasym);
    RETVAL = newRV_inc(sv);
  }
  OUTPUT:
    RETVAL

MODULE = meta    PACKAGE = meta::glob

SV *
get(SV *cls, SV *globname)
  ALIAS:
    get = GET_OR_THROW
    try_get = GET_OR_UNDEF
    get_or_add = GET_OR_ADD
  CODE:
  {
    bool create = (ix == GET_OR_ADD);

    warn_experimental("meta::glob->get");
    GV *gv = gv_fetchsv(globname, create ? GV_ADDMULTI : 0, SVt_PVGV);
    if(gv) {
      assert(SvTYPE(gv) == SVt_PVGV);
      RETVAL = wrap_sv_refsv((SV *)gv);
    }
    else switch(ix) {
      case GET_OR_THROW:
        CROAK_QUOTED_PREFIX("Symbol table does not contain a glob called ", SVfARG(globname));
      case GET_OR_UNDEF:
        RETVAL = &PL_sv_undef;
        break;
    }
  }
  OUTPUT:
    RETVAL

SV *
basename(SV *metaglob)
  CODE:
  {
    GV *gv = MUST_GV_FROM_REFSV(metaglob);
    RETVAL = newSVpvn_flags(GvNAME(gv), GvNAMELEN(gv), GvNAMEUTF8(gv) ? SVf_UTF8 : 0);
  }
  OUTPUT:
    RETVAL

SV *get_scalar(SV *metaglob)
  ALIAS:
    can_scalar = GET_OR_UNDEF_WITH_WARNING
    get_scalar = GET_OR_THROW
    try_get_scalar = GET_OR_UNDEF
  CODE:
    if(ix == GET_OR_UNDEF_WITH_WARNING)
      warn_sub_deprecated(cv);
    RETVAL = S_get_metaglob_slot(aTHX_ metaglob, SVt_PVMG, "scalar", ix);
  OUTPUT:
    RETVAL

SV *get_array(SV *metaglob)
  ALIAS:
    can_array = GET_OR_UNDEF_WITH_WARNING
    get_array = GET_OR_THROW
    try_get_array = GET_OR_UNDEF
  CODE:
    if(ix == GET_OR_UNDEF_WITH_WARNING)
      warn_sub_deprecated(cv);
    RETVAL = S_get_metaglob_slot(aTHX_ metaglob, SVt_PVAV, "array", ix);
  OUTPUT:
    RETVAL

SV *get_hash(SV *metaglob)
  ALIAS:
    can_hash = GET_OR_UNDEF_WITH_WARNING
    get_hash = GET_OR_THROW
    try_get_hash = GET_OR_UNDEF
  CODE:
    if(ix == GET_OR_UNDEF_WITH_WARNING)
      warn_sub_deprecated(cv);
    RETVAL = S_get_metaglob_slot(aTHX_ metaglob, SVt_PVHV, "hash", ix);
  OUTPUT:
    RETVAL

SV *get_code(SV *metaglob)
  ALIAS:
    can_code = GET_OR_UNDEF_WITH_WARNING
    get_code = GET_OR_THROW
    try_get_code = GET_OR_UNDEF
  CODE:
    if(ix == GET_OR_UNDEF_WITH_WARNING)
      warn_sub_deprecated(cv);
    RETVAL = S_get_metaglob_slot(aTHX_ metaglob, SVt_PVCV, "code", ix);
  OUTPUT:
    RETVAL

MODULE = meta    PACKAGE = meta::variable

void
value(SV *metavar)
  PPCODE:
  {
    if(GIMME_V == G_VOID)
      // TODO: warn?
      XSRETURN(0);

    /* TODO: all of the-below is super-fragile and probably doesn't work
     * properly with tied scalars/arrays/hashes. Eugh.
     */

    SV *sv = SV_FROM_REFSV(metavar);
    if(SvTYPE(sv) <= SVt_PVMG) {
      SV *ret = sv_mortalcopy(sv);
      XPUSHs(ret);
      XSRETURN(1);
    }
    else if(SvTYPE(sv) == SVt_PVAV) {
      /* Array */
      AV *av = (AV *)sv;
      UV count = av_count(av);

      if(GIMME_V == G_SCALAR) {
        mXPUSHu(count);
        XSRETURN(1);
      }
      EXTEND(SP, count);
      UV i;
      for(i = 0; i < count; i++)
        PUSHs(sv_mortalcopy(*av_fetch(av, i, 0)));
      XSRETURN(count);
    }
    else if(SvTYPE(sv) == SVt_PVHV) {
      /* Hash */
      HV *hv = (HV *)sv;
      UV count = 0;
      U8 gimme = GIMME_V;

      HE *he;
      hv_iterinit(hv);
      while((he = hv_iternext(hv))) {
        SV *key = HeSVKEY(he);
        if(!key)
          key = newSVpvn_flags(HeKEY(he), HeKLEN(he), HeKFLAGS(he) | SVs_TEMP);

        if(gimme == G_LIST) {
          EXTEND(SP, 2);
          PUSHs(key);
          PUSHs(HeVAL(he));
        }
        count++;
      }

      if(gimme == G_LIST)
        XSRETURN(count * 2);

      mPUSHu(count);
      XSRETURN(1);
    }
    else
      croak("Argh unrecognised SvTYPE(sv)=%d", SvTYPE(sv));
  }

MODULE = meta    PACKAGE = meta::subroutine

bool
is_method(SV *metasub)
  CODE:
  {
    CV *cv = MUST_CV_FROM_REFSV(metasub);
#ifdef HAVE_FEATURE_CLASS
    RETVAL = CvIsMETHOD(cv);
#else
    RETVAL = false;
#endif
  }
  OUTPUT:
    RETVAL

SV *
subname(SV *metasub)
  CODE:
  {
    CV *cv = MUST_CV_FROM_REFSV(metasub);

    GV *gv = CvGV(cv);
    if(!gv)
      RETVAL = &PL_sv_undef;
    else
      RETVAL = newSVpvf("%s::%s", HvNAME(GvSTASH(gv)), GvNAME(gv));
  }
  OUTPUT:
    RETVAL

SV *
set_subname(SV *metasub, SV *name)
  CODE:
  {
    CV *cv = MUST_CV_FROM_REFSV(metasub);

    STRLEN namelen;
    const char *namepv = SvPV(name, namelen);

    const char *pkgnamepv, *basenamepv;
    STRLEN pkgnamelen, basenamelen;
    split_fqname(namepv, namelen,
      &pkgnamepv, &pkgnamelen, &basenamepv, &basenamelen);

    HV *stash;
    if(pkgnamelen)
      stash = gv_stashpvn(pkgnamepv, pkgnamelen, GV_ADD | SvUTF8(name));
    else
      stash = CopSTASH(PL_curcop);

    /* We can't just change the name in the sub's GV because that might be
     * shared and break all kinds of things. We'll have to make a new GV.
     */
    GV *newgv = (GV *)newSV(0);
    gv_init_pvn(newgv, stash, basenamepv, basenamelen, SvUTF8(name));

    CvANON_off(cv);
    CvGV_set(cv, newgv);

    /* CvGV_set claimed a reference to newgv; we can drop it now */
    SvREFCNT_dec(newgv);

    RETVAL = SvREFCNT_inc(metasub);
  }
  OUTPUT:
    RETVAL

SV *
prototype(SV *metasub)
  CODE:
  {
    CV *cv = MUST_CV_FROM_REFSV(metasub);

    if(!SvPOK(cv))
      RETVAL = &PL_sv_undef;
    else
      RETVAL = newSVpvn_flags(CvPROTO(cv), CvPROTOLEN(cv), SvUTF8(cv));
  }
  OUTPUT:
    RETVAL

SV *
set_prototype(SV *metasub, SV *proto)
  CODE:
  {
    CV *cv = MUST_CV_FROM_REFSV(metasub);

    if(SvOK(proto))
      sv_copypv((SV *)cv, proto);
    else
      SvPOK_off((SV *)cv);

    RETVAL = SvREFCNT_inc(metasub);
  }
  OUTPUT:
    RETVAL

SV *
signature(SV *metasub)
  CODE:
  {
    CV *cv = MUST_CV_FROM_REFSV(metasub);

    RETVAL = &PL_sv_undef;
#ifdef HAVE_SUB_SIGNATURES
    if(CvISXSUB(cv))
      goto nosig;

    OP *oproot = CvROOT(cv);
    if(!oproot)
      goto nosig;

    /* The optree of a signatured sub should be an OP_LEAVESUB at toplevel.
     * Nested inside will be maybe one or two OP_NULL[OP_LINESEQ[...]]
     * subtrees, inside of which will be a COP, OP_ARGCHECK, ...
     * It is the OP_ARGCHECK we are looking for
     */

    assert(oproot->op_type == OP_LEAVESUB);
    OP *o = cUNOPx(oproot)->op_first;

    /* Descend into OP_NULL / OP_LINESEQ trees while skipping past COPs
     */
    while(o) {
      if(o->op_type == OP_NULL)
        o = cUNOPo->op_first;
      else if(o->op_type == OP_LINESEQ)
        o = (o->op_flags & OPf_KIDS) ? cUNOPo->op_first : NULL;
      else if(o->op_type == OP_NEXTSTATE || o->op_type == OP_DBSTATE)
        o = OpSIBLING(o);
      else
        break;
    }

    if(!o || o->op_type != OP_ARGCHECK)
      goto nosig;

    RETVAL = wrap_cv_signature(cv, o);

    nosig:
      ;
#endif
  }
  OUTPUT:
    RETVAL

MODULE = meta    PACKAGE = meta::subsignature

void
DESTROY(SV *metasig)
  CODE:
  {
    struct CVwithOP *cvop = (struct CVwithOP *)SvPVX(SvRV(metasig));

    SvREFCNT_dec(cvop->cv);
    // ->op is not refcounted
  }

SV *
mandatory_params(SV *metasig)
  ALIAS:
    mandatory_params = 0
    optional_params  = 1
    slurpy           = 2
    min_args         = 0
    max_args         = 3
  CODE:
  {
#ifdef HAVE_SUB_SIGNATURES
    struct CVwithOP *cvop = (struct CVwithOP *)SvPVX(SvRV(metasig));
#  if HAVE_PERL_VERSION(5, 31, 5)
    struct op_argcheck_aux *aux = (struct op_argcheck_aux *)cUNOP_AUXx(cvop->op)->op_aux;
    int params     = aux->params;
    int opt_params = aux->opt_params;
    char slurpy    = aux->slurpy;
#  else
    UNOP_AUX_item *aux = cUNOP_AUXx(cvop->op)->op_aux;
    int params     = aux[0].iv;
    int opt_params = aux[1].iv;
    char slurpy    = aux[2].iv;
#  endif

    switch(ix) {
      case 0:
        RETVAL = newSViv(params - opt_params);
        break;
      case 1:
        RETVAL = newSViv(opt_params);
        break;
      case 2:
        RETVAL = slurpy ? newSVpvf("%c", slurpy) : &PL_sv_undef;
        break;
      case 3:
        RETVAL = slurpy ? &PL_sv_undef : newSViv(params);
        break;
    }
#endif
  }
  OUTPUT:
    RETVAL

BOOT:
  warnings_register_category(META_WARNING_CATEGORY);
