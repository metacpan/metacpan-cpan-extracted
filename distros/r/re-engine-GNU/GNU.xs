#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "config_REGEXP.h"
#include "regex.c"

/* Things that MUST be supported */
#if ! REGEXP_PPRIVATE_CAN
#  error "pprivate not found in structure regexp"
#endif

#ifndef RX_WRAPPED
#  if ! REGEXP_WRAPPED_CAN
#    error "RX_WRAPPED macro not found"
#  else
#    define RX_WRAPPED(rx) (_RegSV(rx))->wrapped
#  endif
#endif

#ifndef RX_WRAPLEN
#  if ! REGEXP_WRAPLEN_CAN
#    error "RX_WRAPLEN macro not found"
#  else
#    define RX_WRAPLEN(rx) (_RegSV(rx))->wraplen
#  endif
#endif

/* #define PERL_5_10_METHOD */

static regexp_engine engine_GNU;

typedef struct GNU_private {
  SV     *sv_pattern;
  SV     *sv_syntax;
  bool    is_utf8;
  int     isDebug;
  regex_t regex;
} GNU_private_t;

/******************************************************************/
/* Copy of DROLSKY/Params-Validate-1.18/lib/Params/Validate/XS.xs */
/******************************************************************/
/* type constants */
#define SCALAR    1
#define ARRAYREF  2
#define HASHREF   4
#define CODEREF   8
#define GLOB      16
#define GLOBREF   32
#define SCALARREF 64
#define UNKNOWN   128
#define UNDEF     256
#define OBJECT    512
#define HANDLE    (GLOB | GLOBREF)
#define BOOLEAN   (SCALAR | UNDEF)

GNU_STATIC
void GNU_dump_pattern(pTHX_ char *logHeader, REGEXP *rx)
{
  SV *sv_stringification = newSVpvn_utf8(RX_WRAPPED(rx), RX_WRAPLEN(rx), 1);
  fprintf(stderr, "%s: ... pattern:\n", logHeader);
  sv_dump(sv_stringification);
  SvREFCNT_dec(sv_stringification);
}

GNU_STATIC
IV
get_type(pTHX_ SV* sv) {
  IV type = 0;

  if (SvTYPE(sv) == SVt_PVGV) {
    return GLOB;
  }
  if (!SvOK(sv)) {
    return UNDEF;
  }
  if (!SvROK(sv)) {
    return SCALAR;
  }

  switch (SvTYPE(SvRV(sv))) {
  case SVt_NULL:
  case SVt_IV:
  case SVt_NV:
  case SVt_PV:
#if PERL_VERSION <= 10
  case SVt_RV:
#endif
  case SVt_PVMG:
  case SVt_PVIV:
  case SVt_PVNV:
#if PERL_VERSION <= 8
  case SVt_PVBM:
#elif PERL_VERSION >= 11
  case SVt_REGEXP:
#endif
    type = SCALARREF;
    break;
  case SVt_PVAV:
    type = ARRAYREF;
    break;
  case SVt_PVHV:
    type = HASHREF;
    break;
  case SVt_PVCV:
    type = CODEREF;
    break;
  case SVt_PVGV:
    type = GLOBREF;
    break;
    /* Perl 5.10 has a bunch of new types that I don't think will ever
       actually show up here (I hope), but not handling them makes the
       C compiler cranky. */
  default:
    type = UNKNOWN;
    break;
  }

  if (type) {
    if (sv_isobject(sv)) return type | OBJECT;
    return type;
  }

  /* Getting here should not be possible */
  return UNKNOWN;
}

SV* debugkey_sv;
SV* syntaxkey_sv;
int GNU_key2int(pTHX_ const char *key, SV * const key_sv) {
  if (GvHV(PL_hintgv) && (PL_hints & HINT_LOCALIZE_HH) == HINT_LOCALIZE_HH) {
    HE* const he = hv_fetch_ent(GvHV(PL_hintgv), key_sv, FALSE, 0U);
    if (he != NULL) {
      SV* val = HeVAL(he);
      if (val != &PL_sv_placeholder) {
        return (int)SvIV(val);
      }
    }
  }

  return 0;
}

#ifdef HAVE_REGEXP_ENGINE_COMP
GNU_STATIC
#if PERL_VERSION <= 10
REGEXP * GNU_comp(pTHX_ const SV * const pattern, const U32 flags)
#else
REGEXP * GNU_comp(pTHX_ SV * const pattern, const U32 flags)
#endif
{
    REGEXP                   *rx;     /* SV */
    struct regexp            *r;      /* union part that really points to regexp structure */
    GNU_private_t            *ri;
    int                       isDebug = GNU_key2int(aTHX_ "re::engine::GNU/debug", debugkey_sv);
    int                       defaultSyntax = GNU_key2int(aTHX_ "re::engine::GNU/syntax", syntaxkey_sv);
    char                     *logHeader = "[re::engine::GNU] GNU_comp";
    bool                      is_utf8 = DO_UTF8(pattern);

    /* Input as char * */
    STRLEN plen;
    char  *exp;

    /* Copy of flags in input */
    U32 extflags = flags;

    /* SVs that are in input */
    IV pattern_type = get_type(aTHX_ (SV *)pattern);
    SV *sv_pattern;
    SV *sv_syntax = NULL;

    reg_errcode_t ret;
    SV * sv_stringification;

    if (isDebug) {
      fprintf(stderr, "%s: pattern=%p flags=0x%lx\n", logHeader, pattern, (unsigned long) flags);
      fprintf(stderr, "%s: ... default syntax: %d\n", logHeader, defaultSyntax);
    }

    /********************/
    /* GNU engine setup */
    /********************/
    Newxz(ri, 1, GNU_private_t);
    if (isDebug) {
      fprintf(stderr, "%s: ... allocated private structure ri=%p\n", logHeader, ri);
    }

    /* We accept in input:                                                  */
    /* - a scalar                                                           */
    /* - an arrayref with at least 2 members: the syntax and the pattern    */
    /* - a hash with with at least the key 'pattern', eventually 'syntax'   */

    if (pattern_type == SCALAR) {

      if (isDebug) {
        fprintf(stderr, "%s: ... input is a scalar\n", logHeader);
      }

      sv_pattern = newSVsv((SV *)pattern);

    } else if (pattern_type == ARRAYREF) {
      AV *av = (AV *)SvRV((SV *) pattern);
      SV **a_pattern;
      SV **a_syntax;

      if (isDebug) {
        fprintf(stderr, "%s: ... input is an array ref\n", logHeader);
      }

      if (av_len(av) < 1) {
        croak("%s: array ref must have at least two elements, i.e. [syntax => pattern]", logHeader);
      }
      a_pattern = av_fetch(av, 1, 1);
      a_syntax = av_fetch(av, 0, 1);

      if (a_pattern == NULL || get_type(aTHX_ (SV *)*a_pattern) != SCALAR) {
        croak("%s: array ref must have a scalar as second element, got %d", logHeader, get_type(aTHX_ (SV *)a_pattern));
      }
      if (a_syntax == NULL || get_type(aTHX_ (SV *)*a_syntax) != SCALAR) {
        croak("%s: array ref must have a scalar as first element, got %d", logHeader, get_type(aTHX_ (SV *)a_syntax));
      }

      sv_pattern = newSVsv(*a_pattern);
      sv_syntax  = newSVsv(*a_syntax);

    } else if (pattern_type == HASHREF) {
      HV  *hv        = (HV *)SvRV((SV *) pattern);
      SV **h_pattern = hv_fetch(hv, "pattern", 7, 0);
      SV **h_syntax  = hv_fetch(hv, "syntax", 6, 0);

      if (isDebug) {
        fprintf(stderr, "%s: ... input is a hash ref\n", logHeader);
      }

      if (h_pattern == NULL || get_type(aTHX_ (SV *)*h_pattern) != SCALAR) {
        croak("%s: hash ref key must have a key 'pattern' refering to a scalar", logHeader);
      }
      if (h_syntax == NULL || get_type(aTHX_ (SV *)*h_syntax) != SCALAR) {
        croak("%s: hash ref key must have a key 'syntax' refering to a scalar", logHeader);
      }

      sv_pattern = newSVsv(*h_pattern);
      sv_syntax  = newSVsv(*h_syntax);

    } else {
      croak("%s: pattern must be a scalar, an array ref [syntax => pattern], or a hash ref {'syntax' => syntax, 'pattern' => pattern} where syntax and flavour are exclusive", logHeader);
    }

    exp = SvPV(sv_pattern, plen);

    {
      /************************************************************/
      /* split optimizations - copied from re-engine-xxx by avar  */
      /************************************************************/
#if (defined(RXf_SPLIT) && defined(RXf_SKIPWHITE) && defined(RXf_WHITE))
      /* C<split " ">, bypass the PCRE engine alltogether and act as perl does */
      if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ') {
        if (isDebug) {
          fprintf(stderr, "%s: ... split ' ' optimization\n", logHeader);
        }
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);
      }
#endif

#ifdef RXf_NULL
      /* RXf_NULL - Have C<split //> split by characters */
      if (plen == 0) {
        if (isDebug) {
          fprintf(stderr, "%s: ... split // optimization\n", logHeader);
        }
        extflags |= RXf_NULL;
      }
#endif

#ifdef RXf_START_ONLY
      /* RXf_START_ONLY - Have C<split /^/> split on newlines */
      if (plen == 1 && exp[0] == '^') {
        if (isDebug) {
          fprintf(stderr, "%s: ... split /^/ optimization", logHeader);
        }
        extflags |= RXf_START_ONLY;
      }
#endif

#ifdef RXf_WHITE
      /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
      if (plen == 3 && strnEQ("\\s+", exp, 3)) {
        if (isDebug) {
          fprintf(stderr, "%s: ... split /\\s+/ optimization\n", logHeader);
        }
        extflags |= RXf_WHITE;
      }
#endif
    }

    ri->sv_pattern             = sv_pattern;
    ri->sv_syntax              = sv_syntax;
    ri->is_utf8                = is_utf8;
    ri->isDebug                = isDebug;
    ri->regex.buffer           = NULL;
    ri->regex.allocated        = 0;
    ri->regex.used             = 0;
    ri->regex.syntax           = (sv_syntax != NULL) ? (int)SvUV(sv_syntax) : defaultSyntax;
    ri->regex.fastmap          = NULL;
    ri->regex.translate        = NULL;
    ri->regex.re_nsub          = 0;
    ri->regex.can_be_null      = 0;
    ri->regex.regs_allocated   = 0;
    ri->regex.fastmap_accurate = 0;
    ri->regex.no_sub           = 0;
    ri->regex.not_bol          = 0;
    ri->regex.not_eol          = 0;
    ri->regex.newline_anchor   = 0;

    /* /msixp flags */
#ifdef RXf_PMf_MULTILINE
    /* /m */
    if ((flags & RXf_PMf_MULTILINE) == RXf_PMf_MULTILINE) {
      if (isDebug) {
        fprintf(stderr, "%s: ... /m flag\n", logHeader);
      }
      ri->regex.newline_anchor = 1;
    } else {
      if (isDebug) {
        fprintf(stderr, "%s: ... no /m flag\n", logHeader);
      }
    }
#endif
#ifdef RXf_PMf_SINGLELINE
    /* /s */
    if ((flags & RXf_PMf_SINGLELINE) == RXf_PMf_SINGLELINE) {
      if (isDebug) {
        fprintf(stderr, "%s: ... /s flag\n", logHeader);
      }
      ri->regex.syntax |= RE_DOT_NEWLINE;
    } else {
      if (isDebug) {
        fprintf(stderr, "%s: ... no /s flag\n", logHeader);
      }
    }
#endif
#ifdef RXf_PMf_FOLD
    /* /i */
    if ((flags & RXf_PMf_FOLD) == RXf_PMf_FOLD) {
      if (isDebug) {
        fprintf(stderr, "%s: ... /i flag\n", logHeader);
      }
      ri->regex.syntax |= RE_ICASE;
    } else {
      if (isDebug) {
        fprintf(stderr, "%s: ... no /i flag\n", logHeader);
      }
    }
#endif
#ifdef RXf_PMf_EXTENDED
    /* /x */
    if ((flags & RXf_PMf_EXTENDED) == RXf_PMf_EXTENDED) {
      /* Not supported: explicitely removed */
      if (isDebug) {
        fprintf(stderr, "%s: ... /x flag removed\n", logHeader);
      }
      extflags &= ~RXf_PMf_EXTENDED;
    }
#endif
#ifdef RXf_PMf_KEEPCOPY
    /* /p */
    if ((flags & RXf_PMf_KEEPCOPY) == RXf_PMf_KEEPCOPY) {
      if (isDebug) {
        fprintf(stderr, "%s: ... /p flag\n", logHeader);
      }
    } else {
      if (isDebug) {
        fprintf(stderr, "%s: ... no /p flag\n", logHeader);
      }
    }
#endif

    /* REGEX structure for perl */
#if PERL_VERSION > 10
    rx = (REGEXP*) newSV_type(SVt_REGEXP);
#else
    Newxz(rx, 1, REGEXP);
#endif

    r = _RegSV(rx);
    REGEXP_REFCNT_SET(r, 1);
    REGEXP_EXTFLAGS_SET(r, extflags);
    REGEXP_ENGINE_SET(r, &engine_GNU);

    /* AFAIK prelen and precomp macros do not always provide an lvalue */
    /*
    REGEXP_PRELEN_SET(r, (I32)plen);
    REGEXP_PRECOMP_SET(r, (exp != NULL) ? savepvn(exp, plen) : NULL);
    */

    /* qr// stringification */
    if (isDebug) {
      fprintf(stderr, "%s: ... allocating wrapped\n", logHeader);
    }
    sv_stringification = newSVpvn("(?", 2);

    if (ri->regex.newline_anchor == 1) {
        sv_catpvn(sv_stringification, "m", 1);
    }
    if ((ri->regex.syntax & RE_DOT_NEWLINE) == RE_DOT_NEWLINE) {
        sv_catpvn(sv_stringification, "s", 1);
    }
    if ((ri->regex.syntax & RE_ICASE) == RE_ICASE) {
        sv_catpvn(sv_stringification, "i", 1);
    }
    sv_catpvn(sv_stringification, ":", 1);
    sv_catpvn(sv_stringification, "(?#re::engine::GNU", 18);
    {
      char tmp[50];

      sprintf(tmp, "%d", defaultSyntax);
      sv_catpvn(sv_stringification, "/syntax=", 8);
      sv_catpvn(sv_stringification, tmp, strlen(tmp));
    }
    sv_catpvn(sv_stringification, ")", 1);

    sv_catpvn(sv_stringification, exp, plen);
    sv_catpvn(sv_stringification, ")", 1);
    RX_WRAPPED(rx) = savepvn(SvPVX(sv_stringification), SvCUR(sv_stringification));
    RX_WRAPLEN(rx) = SvCUR(sv_stringification);
    if (isDebug) {
      GNU_dump_pattern(aTHX_ logHeader, rx);
    }
    SvREFCNT_dec(sv_stringification);

    if (isDebug) {
      fprintf(stderr, "%s: ... re_compile_internal(preg=%p, pattern=\"%s\", length=%ld, syntax=0x%lx, is_utf8=%d)\n", logHeader, &(ri->regex), exp, (unsigned long) plen, (unsigned long) ri->regex.syntax, (int) ri->is_utf8);
    }

    ret = re_compile_internal (aTHX_ &(ri->regex), exp, plen, ri->regex.syntax, ri->is_utf8);

    if (ret != _REG_NOERROR) {
      extern const char __re_error_msgid[];
      extern const size_t __re_error_msgid_idx[];
      croak("%s: %s", logHeader, __re_error_msgid + __re_error_msgid_idx[(int) ret]);
    }

    REGEXP_PPRIVATE_SET(r, ri);
    REGEXP_LASTPAREN_SET(r, 0);
    REGEXP_LASTCLOSEPAREN_SET(r, 0);
    REGEXP_NPARENS_SET(r, (U32)ri->regex.re_nsub); /* cast from size_t */
    if (isDebug) {
      fprintf(stderr, "%s: ... %d () detected\n", logHeader, (int) ri->regex.re_nsub);
    }

    /*
      Tell perl how many match vars we have and allocate space for
      them, at least one is always allocated for $&
     */
    /* Note: we made sure that offs is always supported whatever the perl version */
    Newxz(REGEXP_OFFS_GET(r), REGEXP_NPARENS_GET(r) + 1, regexp_paren_pair);

    if (isDebug) {
      fprintf(stderr, "%s: return %p\n", logHeader, rx);
    }

    /* return the regexp structure to perl */
    return rx;
}
#endif /* HAVE_REGEXP_ENGINE_COMP */

#ifdef HAVE_REGEXP_ENGINE_EXEC

/* Copy of http://perl5.git.perl.org/perl.git/blob_plain/HEAD:/regexec.c */
/* and little adaptation -; 2015.03.15 */

GNU_STATIC
void
GNU_exec_set_capture_string(pTHX_ REGEXP * const rx,
                            char *strbeg,
                            char *strend,
                            SV *sv,
                            U32 flags,
                            short utf8_target)
{
  char          *logHeader = "[re::engine::GNU] GNU_exec_set_capture_string";
  struct regexp *r = _RegSV(rx);
  GNU_private_t *ri = REGEXP_PPRIVATE_GET(r);
  int            isDebug = ri->isDebug;

  if (isDebug) {
    fprintf(stderr, "%s: rx=%p, strbeg=%p, strend=%p, sv=%p, flags=0x%lx, utf8_target=%d\n", logHeader, rx, strbeg, strend, sv, (unsigned long) flags, (int) utf8_target);
  }

  if ((flags & REXEC_COPY_STR) == REXEC_COPY_STR) {
    /* It is perl that decides if this version is COW enabled or not */
    /* From our point of view, it is equivalent to test if saved_copy */
    /* is available */
#if REGEXP_SAVED_COPY_CAN
    short canCow = 1;
#else
    short canCow = 0;
#endif
    if (canCow != 0) {
#if REGEXP_SAVED_COPY_CAN
      if ((REGEXP_SAVED_COPY_GET(r) != NULL
           && SvIsCOW(REGEXP_SAVED_COPY_GET(r))
           && SvPOKp(REGEXP_SAVED_COPY_GET(r))
           && SvIsCOW(sv)
           && SvPOKp(sv)
           && SvPVX(sv) == SvPVX(REGEXP_SAVED_COPY_GET(r)))) {
        /* just reuse saved_copy SV */
        if (isDebug) {
          fprintf(stderr, "%s: ... reusing save_copy SV\n", logHeader);
        }
        if (RX_MATCH_COPIED(rx)) {
#if REGEXP_SUBBEG_CAN
          Safefree(REGEXP_SUBBEG_GET(r));
#endif /* REGEXP_SUBBEG_CAN */
          RX_MATCH_COPIED_off(rx);
        }
      } else {
        if (isDebug) {
          fprintf(stderr, "%s: ... creating new COW sv\n", logHeader);
        }
        RX_MATCH_COPY_FREE(rx);
        REGEXP_SAVED_COPY_SET(r, sv_setsv_cow(REGEXP_SAVED_COPY_GET(r), sv));
      }
      REGEXP_SUBBEG_SET(r, (char *)SvPVX_const(REGEXP_SAVED_COPY_GET(r)));
      REGEXP_SUBLEN_SET(r, strend - strbeg);
      REGEXP_SUBOFFSET_SET(r, 0);
      REGEXP_SUBCOFFSET_SET(r, 0);
      if (isDebug) {
        fprintf(stderr, "%s: ..."
#if REGEXP_SUBBEG_CAN
                " subbeg=%p"
#endif
#if REGEXP_SUBLEN_CAN
                " sublen=%d"
#endif
#if REGEXP_SUBOFFSET_CAN
                " suboffset=%d"
#endif
#if REGEXP_SUBCOFFSET_CAN
                " subcoffset=%d"
#endif
                "\n", logHeader
#if REGEXP_SUBBEG_CAN
                , REGEXP_SUBBEG_GET(r)
#endif
#if REGEXP_SUBLEN_CAN
                , REGEXP_SUBLEN_GET(r)
#endif
#if REGEXP_SUBOFFSET_CAN
                , REGEXP_SUBOFFSET_GET(r)
#endif
#if REGEXP_SUBCOFFSET_CAN
                , REGEXP_SUBCOFFSET_GET(r)
#endif
                );
      }
#endif /* REGEXP_SAVED_COPY_CAN */
    } else {
      /* The following are optimizations that appeared in 5.20. This is almost */
      /* copied verbatim from it */
#if REGEXP_EXTFLAGS_CAN && REGEXP_LASTPAREN_CAN && REGEXP_OFFS_CAN && REGEXP_SUBLEN_CAN && REGEXP_SUBBEG_CAN
      {
        SSize_t min = 0;
        SSize_t max = strend - strbeg;
        SSize_t sublen;
#if defined(RXf_PMf_KEEPCOPY) && defined(PL_sawampersand) && defined(REXEC_COPY_SKIP_POST) && defined(SAWAMPERSAND_RIGHT) && defined(REXEC_COPY_SKIP_PRE) && defined(SAWAMPERSAND_LEFT)
        /* $' and $` optimizations */

        if (((flags & REXEC_COPY_SKIP_POST) == REXEC_COPY_SKIP_POST)
            && !((REGEXP_EXTFLAGS_GET(r) & RXf_PMf_KEEPCOPY) == RXf_PMf_KEEPCOPY) /* //p */
            && !((PL_sawampersand & SAWAMPERSAND_RIGHT) == SAWAMPERSAND_RIGHT)
            ) {
          /* don't copy $' part of string */
          U32 n = 0;
          max = -1;
          /* calculate the right-most part of the string covered
           * by a capture. Due to look-ahead, this may be to
           * the right of $&, so we have to scan all captures */
          if (isDebug) {
            fprintf(stderr, "%s: ... calculate right-most part of the string coverred by a capture\n", logHeader);
          }
          while (n <= REGEXP_LASTPAREN_GET(r)) {
            if (REGEXP_OFFS_GET(r)[n].end > max) {
              max = REGEXP_OFFS_GET(r)[n].end;
            }
            n++;
          }
          if (max == -1)
            max = ((PL_sawampersand & SAWAMPERSAND_LEFT) == SAWAMPERSAND_LEFT)
              ? REGEXP_OFFS_GET(r)[0].start
              : 0;
        }
        if (((flags & REXEC_COPY_SKIP_PRE) == REXEC_COPY_SKIP_PRE)
            && !((REGEXP_EXTFLAGS_GET(r) & RXf_PMf_KEEPCOPY) == RXf_PMf_KEEPCOPY) /* //p */
            && !((PL_sawampersand & SAWAMPERSAND_LEFT) == SAWAMPERSAND_LEFT)
            ) {
          /* don't copy $` part of string */
          U32 n = 0;
          min = max;
          /* calculate the left-most part of the string covered
           * by a capture. Due to look-behind, this may be to
           * the left of $&, so we have to scan all captures */
          if (isDebug) {
            fprintf(stderr, "%s: ... calculate left-most part of the string coverred by a capture\n", logHeader);
          }
          while (min && n <= REGEXP_LASTPAREN_GET(r)) {
            if (   REGEXP_OFFS_GET(r)[n].start != -1
                   && REGEXP_OFFS_GET(r)[n].start < min)
              {
                min = REGEXP_OFFS_GET(r)[n].start;
              }
            n++;
          }
          if (((PL_sawampersand & SAWAMPERSAND_RIGHT) == SAWAMPERSAND_RIGHT)
              && min > REGEXP_OFFS_GET(r)[0].end
              )
            min = REGEXP_OFFS_GET(r)[0].end;
        }
#endif /* RXf_PMf_KEEPCOPY && PL_sawampersand && REXEC_COPY_SKIP_POST && SAWAMPERSAND_RIGHT && REXEC_COPY_SKIP_PRE && SAWAMPERSAND_LEFT */

        sublen = max - min;

        if (RX_MATCH_COPIED(rx)) {
          if (sublen > REGEXP_SUBLEN_GET(r))
            REGEXP_SUBBEG_SET(r, (char*)saferealloc(REGEXP_SUBBEG_GET(r), sublen+1));
        }
        else {
          REGEXP_SUBBEG_SET(r, (char*)safemalloc(sublen+1));
        }
        Copy(strbeg + min, REGEXP_SUBBEG_GET(r), sublen, char);
        REGEXP_SUBBEG_GET(r)[sublen] = '\0';
        REGEXP_SUBOFFSET_SET(r, min);
        REGEXP_SUBLEN_SET(r, sublen);
        RX_MATCH_COPIED_on(rx);
        if (isDebug) {
          fprintf(stderr, "%s: ..."
#if REGEXP_SUBBEG_CAN
                  " subbeg=%p"
#endif
#if REGEXP_SUBLEN_CAN
                  " sublen=%d"
#endif
#if REGEXP_SUBOFFSET_CAN
                  " suboffset=%d"
#endif
#if REGEXP_SUBCOFFSET_CAN
                  " subcoffset=%d"
#endif
                  "\n", logHeader
#if REGEXP_SUBBEG_CAN
                  , REGEXP_SUBBEG_GET(r)
#endif
#if REGEXP_SUBLEN_CAN
                  , REGEXP_SUBLEN_GET(r)
#endif
#if REGEXP_SUBOFFSET_CAN
                  , REGEXP_SUBOFFSET_GET(r)
#endif
#if REGEXP_SUBCOFFSET_CAN
                  , REGEXP_SUBCOFFSET_GET(r)
#endif
                  );
        }
      }
#endif /* REGEXP_EXTFLAGS_CAN && REGEXP_LASTPAREN_CAN && REGEXP_OFFS_CAN && REGEXP_SUBLEN_CAN && REGEXP_SUBBEG_CAN */

#if REGEXP_SUBCOFFSET_CAN && REGEXP_SUBOFFSET_CAN
      REGEXP_SUBCOFFSET_SET(r, REGEXP_SUBOFFSET_GET(r));
      if (REGEXP_SUBOFFSET_GET(r) != 0 && utf8_target != 0) {
        /* Convert byte offset to chars.
         * XXX ideally should only compute this if @-/@+
         * has been seen, a la PL_sawampersand ??? */

        /* If there's a direct correspondence between the
         * string which we're matching and the original SV,
         * then we can use the utf8 len cache associated with
         * the SV. In particular, it means that under //g,
         * sv_pos_b2u() will use the previously cached
         * position to speed up working out the new length of
         * subcoffset, rather than counting from the start of
         * the string each time. This stops
         *   $x = "\x{100}" x 1E6; 1 while $x =~ /(.)/g;
         * from going quadratic */
#ifdef HAVE_SV_POS_B2U_FLAGS
        if (SvPOKp(sv) && SvPVX(sv) == strbeg)
          REGEXP_SUBCOFFSET_SET(r, sv_pos_b2u_flags(sv, REGEXP_SUBCOFFSET_GET(r),
                                                     SV_GMAGIC|SV_CONST_RETURN));
        else
#endif
          REGEXP_SUBCOFFSET_SET(r, utf8_length((U8*)strbeg,
                                                (U8*)(strbeg + REGEXP_SUBOFFSET_GET(r))));
      }
      if (isDebug) {
        fprintf(stderr, "%s: ... suboffset=%d and utf8target=%d => subcoffset=%d\n", logHeader, REGEXP_SUBOFFSET_GET(r), (int) utf8_target, REGEXP_SUBCOFFSET_GET(r));
      }
#endif /* REGEXP_SUBCOFFSET_CAN && REGEXP_SUBOFFSET_CAN */
    }
  } else {
    RX_MATCH_COPY_FREE(rx);
    REGEXP_SUBBEG_SET(r, strbeg);
    REGEXP_SUBOFFSET_SET(r, 0);
    REGEXP_SUBCOFFSET_SET(r, 0);
    REGEXP_SUBLEN_SET(r, strend - strbeg);
  }

  if (isDebug) {
    fprintf(stderr, "%s: return void\n", logHeader);
  }

}

GNU_STATIC
I32
#if PERL_VERSION >= 19
GNU_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend, char *strbeg, SSize_t minend, SV * sv, void *data, U32 flags)
#else
GNU_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend, char *strbeg, I32 minend, SV * sv, void *data, U32 flags)
#endif
{
    struct regexp      *r = _RegSV(rx);
    GNU_private_t      *ri = REGEXP_PPRIVATE_GET(r);
    int                 isDebug = ri->isDebug;
    regoff_t            rc;
    U32                 i;
    struct re_registers regs;     /* for subexpression matches */
    char               *logHeader = "[re::engine::GNU] GNU_exec";
    short               utf8_target = DO_UTF8(sv) ? 1 : 0;

    regs.num_regs = 0;
    regs.start = NULL;
    regs.end = NULL;

    if (isDebug) {
      fprintf(stderr, "%s: rx=%p, stringarg=%p, strend=%p, strbeg=%p, minend=%d, sv=%p, data=%p, flags=0x%lx\n", logHeader, rx, stringarg, strend, strbeg, (int) minend, sv, data, (unsigned long) flags);
      GNU_dump_pattern(aTHX_ logHeader, rx);
    }

    /* Take care: strend points to the character following the end of the physical string */
    if (isDebug) {
      fprintf(stderr, "%s: ... re_search(bufp=%p, string=%p, length=%d, sv=%p, start=%d, range=%d, regs=%p)\n", logHeader, &(ri->regex), strbeg, (int) (strend - strbeg), sv, (int) (stringarg - strbeg), (int) (strend - stringarg), &regs);
    }
    rc = re_search(aTHX_ &(ri->regex), strbeg, strend - strbeg, sv, stringarg - strbeg, strend - stringarg, &regs);

    if (rc <= -2) {
      croak("%s: Internal error in re_search()", logHeader);
    } else if (rc == -1) {
      if (isDebug) {
        fprintf(stderr, "%s: return 0 (no match)\n", logHeader);
      }
      return 0;
    }

    /* Why isn't it done by the higher level ? */
    RX_MATCH_UTF8_set(rx, utf8_target);
    RX_MATCH_TAINTED_off(rx);

    REGEXP_LASTPAREN_SET(r, REGEXP_NPARENS_GET(r));
    REGEXP_LASTCLOSEPAREN_SET(r, REGEXP_NPARENS_GET(r));

    /* There is always at least the index 0 for $& */
    for (i = 0; i < REGEXP_NPARENS_GET(r) + 1; i++) {
        if (isDebug) {
          fprintf(stderr, "%s: ... Match No %d: [%d,%d]\n", logHeader, i, (int) regs.start[i], (int) regs.end[i]);
        }
#if REGEXP_OFFS_CAN
        REGEXP_OFFS_GET(r)[i].start = regs.start[i];
        REGEXP_OFFS_GET(r)[i].end = regs.end[i];
#endif
    }

#ifndef PERL_5_10_METHOD
    if ((flags & REXEC_NOT_FIRST) != REXEC_NOT_FIRST) {
      GNU_exec_set_capture_string(aTHX_ rx, strbeg, strend, sv, flags, utf8_target);
    }
#else
    /* This is the perl-5.10 method */
    if ((flags & REXEC_NOT_FIRST) != REXEC_NOT_FIRST) {
      const I32 length = strend - strbeg;
#if REGEXP_SAVED_COPY_CAN
      short canCow = 1;
      short doCow = canCow ? (REGEXP_SAVED_COPY_GET(r) != NULL
                              && SvIsCOW(REGEXP_SAVED_COPY_GET(r))
                              && SvPOKp(REGEXP_SAVED_COPY_GET(r))
                              && SvIsCOW(sv)
                              && SvPOKp(sv)
                              && SvPVX(sv) == SvPVX(REGEXP_SAVED_COPY_GET(r))) : 0;
#else
      short canCow = 0;
      short doCow = 0;
#endif
      RX_MATCH_COPY_FREE(rx);
      if ((flags & REXEC_COPY_STR) == REXEC_COPY_STR) {
        /* Adapted from perl-5.10. Not performant, I know */
        if (canCow != 0 && doCow != 0) {
#if REGEXP_SAVED_COPY_CAN
          if (isDebug) {
            fprintf(stderr, "%s: ... reusing save_copy SV\n", logHeader);
          }
          REGEXP_SAVED_COPY_SET(r, sv_setsv_cow(REGEXP_SAVED_COPY_GET(r), sv));
#if REGEXP_SUBBEG_CAN
          {
             SV *csv = REGEXP_SAVED_COPY_GET(r);
             char *s = (char *) SvPVX_const(csv);
             REGEXP_SUBBEG_SET(r, s);
          }
#endif
#endif
        } else {
          RX_MATCH_COPIED_on(rx);
#if REGEXP_SUBBEG_CAN
          REGEXP_SUBBEG_SET(r, savepvn(strbeg, length));
#endif
        }
      } else {
          REGEXP_SUBBEG_SET(r, strbeg);
      }
      REGEXP_SUBLEN_SET(r, length);
      REGEXP_SUBOFFSET_SET(r, 0);
      REGEXP_SUBCOFFSET_SET(r, 0);
    }
#endif /* PERL_5_10_METHOD */

    if (regs.start != NULL) {
      Safefree(regs.start);
    }
    if (regs.end != NULL) {
      Safefree(regs.end);
    }

    if (isDebug) {
      fprintf(stderr, "%s: return 1 (match)\n", logHeader);
    }

    return 1;
}
#endif /* HAVE_REGEXP_ENGINE_EXEC */

#ifdef HAVE_REGEXP_ENGINE_INTUIT
GNU_STATIC
char *
#if PERL_VERSION >= 19
GNU_intuit(pTHX_ REGEXP * const rx, SV * sv, const char *strbeg, char *strpos, char *strend, U32 flags, re_scream_pos_data *data)
#else
GNU_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos, char *strend, U32 flags, re_scream_pos_data *data)
#endif
{
  struct regexp *r = _RegSV(rx);
  GNU_private_t *ri = REGEXP_PPRIVATE_GET(r);
  int            isDebug = ri->isDebug;
  char          *logHeader = "[re::engine::GNU] GNU_intuit";

  PERL_UNUSED_ARG(rx);
  PERL_UNUSED_ARG(sv);
#if PERL_VERSION >= 19
  PERL_UNUSED_ARG(strbeg);
#endif
  PERL_UNUSED_ARG(strpos);
  PERL_UNUSED_ARG(strend);
  PERL_UNUSED_ARG(flags);
  PERL_UNUSED_ARG(data);

  if (isDebug) {
    fprintf(stderr, "%s: rx=%p, sv=%p, strpos=%p, strend=%p, flags=0x%lx, data=%p\n", logHeader, rx, sv, strpos, strend, (unsigned long) flags, data);
    GNU_dump_pattern(aTHX_ logHeader, rx);
    fprintf(stderr, "%s: return NULL\n", logHeader);
  }

  return NULL;
}
#endif

#ifdef HAVE_REGEXP_ENGINE_CHECKSTR
GNU_STATIC
SV *
GNU_checkstr(pTHX_ REGEXP * const rx)
{
  struct regexp *r = _RegSV(rx);
  GNU_private_t *ri = REGEXP_PPRIVATE_GET(r);
  int            isDebug = ri->isDebug;
  char          *logHeader = "[re::engine::GNU] GNU_checkstr";

  PERL_UNUSED_ARG(rx);

  if (isDebug) {
    fprintf(stderr, "%s: rx=%p\n", logHeader, rx);
    GNU_dump_pattern(aTHX_ logHeader, rx);
    fprintf(stderr, "%s: return NULL\n", logHeader);
  }

  return NULL;
}
#endif

#if (defined(HAVE_REGEXP_ENGINE_FREE) || defined(HAVE_REGEXP_ENGINE_RXFREE))
GNU_STATIC
void
GNU_free(pTHX_ REGEXP * const rx)
{
  struct regexp *r = _RegSV(rx);
  GNU_private_t *ri = REGEXP_PPRIVATE_GET(r);
  int            isDebug = ri->isDebug;
  char          *logHeader = "[re::engine::GNU] GNU_free";

  if (isDebug) {
    fprintf(stderr, "%s: rx=%p\n", logHeader, rx);
    GNU_dump_pattern(aTHX_ logHeader, rx);
  }

  if (isDebug) {
    fprintf(stderr, "%s: ... SvREFCNT_dec(ri->sv_pattern=%p)\n", logHeader, ri->sv_pattern);
  }
  SvREFCNT_dec(ri->sv_pattern);
  if (ri->sv_syntax != NULL) {
    if (isDebug) {
      fprintf(stderr, "%s: ... SvREFCNT_dec(ri->sv_syntax=%p)\n", logHeader, ri->sv_syntax);
    }
    SvREFCNT_dec(ri->sv_syntax);
  }

  if (isDebug) {
    fprintf(stderr, "%s: ... regfree(preg=%p)\n", logHeader, &(ri->regex));
  }
  regfree(aTHX_ &(ri->regex));

  if (isDebug) {
    fprintf(stderr, "%s: ... Safefree(ri=%p)\n", logHeader, ri);
  }
  Safefree(ri);

  if (isDebug) {
    fprintf(stderr, "%s: return void\n", logHeader);
  }

}
#endif

#ifdef HAVE_REGEXP_ENGINE_QR_PACKAGE
GNU_STATIC
SV *
GNU_qr_package(pTHX_ REGEXP * const rx)
{
  struct regexp *r = _RegSV(rx);
  GNU_private_t *ri = REGEXP_PPRIVATE_GET(r);
  int            isDebug = ri->isDebug;
  char          *logHeader = "[re::engine::GNU] GNU_qr_package";
  SV            *rc;

  PERL_UNUSED_ARG(rx);

  if (isDebug) {
    fprintf(stderr, "%s: rx=%p\n", logHeader, rx);
    GNU_dump_pattern(aTHX_ logHeader, rx);
  }

  rc = newSVpvs("re::engine::GNU");

  if (isDebug) {
    fprintf(stderr, "%s: return %p\n", logHeader, rc);
  }

  return rc;

}
#endif

#ifdef HAVE_REGEXP_ENGINE_DUPE
GNU_STATIC
void *
GNU_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
  char          *logHeader = "[re::engine::GNU] GNU_dupe";
  struct regexp *r = _RegSV(rx);
  GNU_private_t *oldri = REGEXP_PPRIVATE_GET(r);
  int            isDebug = oldri->isDebug;
  GNU_private_t *ri;
  STRLEN         plen;
  char          *exp;
  reg_errcode_t  ret;

  PERL_UNUSED_ARG(param);

  Newxz(ri, 1, GNU_private_t);
  if (isDebug) {
    fprintf(stderr, "%s: ... allocated private structure ri=%p\n", logHeader, ri);
  }

  if (isDebug) {
    fprintf(stderr, "%s: rx=%p, param=%p\n", logHeader, rx, param);
    GNU_dump_pattern(aTHX_ logHeader, rx);
  }

  ri->sv_pattern             = newSVsv(oldri->sv_pattern);
  ri->sv_syntax              = oldri->sv_syntax != NULL ? newSVsv(oldri->sv_syntax) : NULL;
  ri->isDebug                = oldri->isDebug;
  ri->is_utf8                = oldri->is_utf8;
  ri->regex.buffer           = NULL;
  ri->regex.allocated        = 0;
  ri->regex.used             = 0;
  ri->regex.syntax           = oldri->regex.syntax;
  ri->regex.fastmap          = NULL;
  ri->regex.translate        = NULL;
  ri->regex.re_nsub          = 0;
  ri->regex.can_be_null      = 0;
  ri->regex.regs_allocated   = 0;
  ri->regex.fastmap_accurate = 0;
  ri->regex.no_sub           = 0;
  ri->regex.not_bol          = 0;
  ri->regex.not_eol          = 0;
  ri->regex.newline_anchor   = oldri->regex.newline_anchor;

  exp = SvPV(ri->sv_pattern, plen);

  if (isDebug) {
    fprintf(stderr, "%s: ... re_compile_internal(preg=%p, pattern=\"%s\", length=%ld, syntax=0x%lx, is_utf8=%d)\n", logHeader, &(ri->regex), exp, (unsigned long) plen, (unsigned long) ri->regex.syntax, (int) ri->is_utf8);
  }

  ret = re_compile_internal (aTHX_ &(ri->regex), exp, plen, ri->regex.syntax, ri->is_utf8);

  if (ret != _REG_NOERROR) {
    extern const char __re_error_msgid[];
    extern const size_t __re_error_msgid_idx[];
    croak("%s: %s", logHeader, __re_error_msgid + __re_error_msgid_idx[(int) ret]);
  }

  if (isDebug) {
    fprintf(stderr, "%s: return %p\n", logHeader, ri);
  }

  return ri;
}
#endif

MODULE = re::engine::GNU		PACKAGE = re::engine::GNU		
PROTOTYPES: ENABLE

BOOT:
    debugkey_sv = newSVpvs_share("re::engine::GNU/debug");
    syntaxkey_sv = newSVpvs_share("re::engine::GNU/syntax");
#ifdef HAVE_REGEXP_ENGINE_COMP
  engine_GNU.comp = GNU_comp;
#endif
#ifdef HAVE_REGEXP_ENGINE_EXEC
  engine_GNU.exec = GNU_exec;
#endif
#ifdef HAVE_REGEXP_ENGINE_INTUIT
  engine_GNU.intuit = GNU_intuit;
#endif
#ifdef HAVE_REGEXP_ENGINE_CHECKSTR
  engine_GNU.checkstr = GNU_checkstr;
#endif
#ifdef HAVE_REGEXP_ENGINE_FREE
#  undef _PREVIOUS_FREE_MACRO
#  ifdef free
#    define _PREVIOUS_FREE_MACRO free
#  endif
#  undef free
  engine_GNU.free = GNU_free;
#  ifdef _PREVIOUS_FREE_MACRO
#    define free _PREVIOUS_FREE_MACRO
#  endif
#endif
#ifdef HAVE_REGEXP_ENGINE_RXFREE
  engine_GNU.rxfree = GNU_free;
#endif
#ifdef HAVE_REGEXP_ENGINE_NUMBERED_BUFF_FETCH
#ifdef HAVE_PERL_REG_NUMBERED_BUFF_FETCH
  engine_GNU.numbered_buff_FETCH = Perl_reg_numbered_buff_fetch;
#else
  engine_GNU.numbered_buff_FETCH = NULL;
#endif
#endif
#ifdef HAVE_REGEXP_ENGINE_NUMBERED_BUFF_STORE
#ifdef HAVE_PERL_REG_NUMBERED_BUFF_STORE
  engine_GNU.numbered_buff_STORE = Perl_reg_numbered_buff_store;
#else
  engine_GNU.numbered_buff_STORE = NULL;
#endif
#endif
#ifdef HAVE_REGEXP_ENGINE_NUMBERED_BUFF_LENGTH
#ifdef HAVE_PERL_REG_NUMBERED_BUFF_LENGTH
  engine_GNU.numbered_buff_LENGTH = Perl_reg_numbered_buff_length;
#else
  engine_GNU.numbered_buff_LENGTH = NULL;
#endif
#endif
#ifdef HAVE_REGEXP_ENGINE_NAMED_BUFF
#ifdef HAVE_PERL_REG_NAMED_BUFF
  engine_GNU.named_buff = Perl_reg_named_buff;
#else
  engine_GNU.named_buff = NULL;
#endif
#endif
#ifdef HAVE_REGEXP_ENGINE_NAMED_BUFF_ITER
#ifdef HAVE_PERL_REG_NAMED_BUFF_ITER
  engine_GNU.named_buff_iter = Perl_reg_named_buff_iter;
#else
  engine_GNU.named_buff_iter = NULL;
#endif
#endif
#ifdef HAVE_REGEXP_ENGINE_QR_PACKAGE
  engine_GNU.qr_package = GNU_qr_package;
#endif
#ifdef HAVE_REGEXP_ENGINE_DUPE
  engine_GNU.dupe = GNU_dupe;
#endif

void
ENGINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(PTR2IV(&engine_GNU))));

void
RE_SYNTAX_AWK(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_AWK)));

void
RE_SYNTAX_ED(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_ED)));

void
RE_SYNTAX_EGREP(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_EGREP)));

void
RE_SYNTAX_EMACS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_EMACS)));

void
RE_SYNTAX_GNU_AWK(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_GNU_AWK)));

void
RE_SYNTAX_GREP(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_GREP)));

void
RE_SYNTAX_POSIX_AWK(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_POSIX_AWK)));

void
RE_SYNTAX_POSIX_BASIC(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_POSIX_BASIC)));

void
RE_SYNTAX_POSIX_EGREP(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_POSIX_EGREP)));

void
RE_SYNTAX_POSIX_EXTENDED(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_POSIX_EXTENDED)));

void
RE_SYNTAX_POSIX_MINIMAL_BASIC(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_POSIX_MINIMAL_BASIC)));

void
RE_SYNTAX_POSIX_MINIMAL_EXTENDED(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_POSIX_MINIMAL_EXTENDED)));

void
RE_SYNTAX_SED(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_SYNTAX_SED)));

void
RE_BACKSLASH_ESCAPE_IN_LISTS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_BACKSLASH_ESCAPE_IN_LISTS)));

void
RE_BK_PLUS_QM(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_BK_PLUS_QM)));

void
RE_CHAR_CLASSES(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_CHAR_CLASSES)));

void
RE_CONTEXT_INDEP_ANCHORS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_CONTEXT_INDEP_ANCHORS)));

void
RE_CONTEXT_INDEP_OPS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_CONTEXT_INDEP_OPS)));

void
RE_CONTEXT_INVALID_OPS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_CONTEXT_INVALID_OPS)));

void
RE_DOT_NEWLINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_DOT_NEWLINE)));

void
RE_DOT_NOT_NULL(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_DOT_NOT_NULL)));

void
RE_HAT_LISTS_NOT_NEWLINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_HAT_LISTS_NOT_NEWLINE)));

void
RE_INTERVALS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_INTERVALS)));

void
RE_LIMITED_OPS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_LIMITED_OPS)));

void
RE_NEWLINE_ALT(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NEWLINE_ALT)));

void
RE_NO_BK_BRACES(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_BK_BRACES)));

void
RE_NO_BK_PARENS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_BK_PARENS)));

void
RE_NO_BK_REFS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_BK_REFS)));

void
RE_NO_BK_VBAR(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_BK_VBAR)));

void
RE_NO_EMPTY_RANGES(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_EMPTY_RANGES)));

void
RE_UNMATCHED_RIGHT_PAREN_ORD(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_UNMATCHED_RIGHT_PAREN_ORD)));

void
RE_NO_POSIX_BACKTRACKING(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_POSIX_BACKTRACKING)));

void
RE_NO_GNU_OPS(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_GNU_OPS)));

void
RE_DEBUG(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_DEBUG)));

void
RE_INVALID_INTERVAL_ORD(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_INVALID_INTERVAL_ORD)));

void
RE_ICASE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_ICASE)));

void
RE_CARET_ANCHORS_HERE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_CARET_ANCHORS_HERE)));

void
RE_CONTEXT_INVALID_DUP(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_CONTEXT_INVALID_DUP)));

void
RE_NO_SUB(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(RE_NO_SUB)));
