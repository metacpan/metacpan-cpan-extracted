/* -*- c-basic-offset:4 -*- */
//#define PLUGGABLE_RE_EXTENSION
#define PERL_EXT_RE_BUILD
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <hs/hs.h>
#include "Hyperscan.h"
#include "regcomp.h"

#ifndef strEQc
# define strEQc(s, c) strEQ(s, ("" c ""))
#endif

#if PERL_VERSION > 10
#define RegSV(p) SvANY(p)
#else
#define RegSV(p) (p)
#endif

static hs_platform_info_t *hs_platform_info = NULL;

REGEXP *
#if PERL_VERSION < 12
HS_comp(pTHX_ const SV * const pattern, const U32 flags)
#else
HS_comp(pTHX_ SV * const pattern, U32 flags)
#endif
{
    REGEXP *rx;
    regexp *re;
    char   *ri = NULL;

    STRLEN  plen;
    char    *exp = SvPV((SV*)pattern, plen);
    U32 extflags = flags;
    SV  *wrapped, *wrapped_unset;

    /* hs_compile */
    unsigned int options = HS_FLAG_SOM_LEFTMOST;
    hs_database_t *database;
    hs_scratch_t *scratch = NULL;
    hs_compile_error_t *compile_err;
    hs_error_t rc;

    int nparens = 0;

#ifdef RXf_PMf_EXTENDED_MORE
    if (flags & RXf_PMf_EXTENDED_MORE) {
        return Perl_re_compile(aTHX_ pattern, flags);
    }
#endif

    wrapped = newSVpvn_flags("(?", 2, SVs_TEMP);
    wrapped_unset = newSVpvn_flags("", 0, SVs_TEMP);

    /* C<split " ">, bypass the Hyperscan engine alltogether and act as perl does */
    if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ')
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);

    /* RXf_NULL - Have C<split //> split by characters */
    if (plen == 0)
        extflags |= RXf_NULL;

    /* RXf_START_ONLY - Have C<split /^/> split on newlines */
    else if (plen == 1 && exp[0] == '^')
        extflags |= RXf_START_ONLY;

    /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
    else if (plen == 3 && strnEQ("\\s+", exp, 3))
        extflags |= RXf_WHITE;

    /* Perl modifiers to Hyperscan flags, /s is implicit and /p isn't used
     * but they pose no problem so ignore them */
    /* qr// stringification, TODO: (?flags:pattern) */
    if (flags & RXf_PMf_FOLD) { /* /i */
        options |= HS_FLAG_CASELESS;
        sv_catpvn(wrapped, "i", 1);
    }
    if (flags & RXf_PMf_SINGLELINE) { /* /s */
        options |= HS_FLAG_DOTALL;
        sv_catpvn(wrapped, "s", 1);
    }
    if (flags & RXf_PMf_MULTILINE) { /* /m */
        options |= HS_FLAG_MULTILINE;
        sv_catpvn(wrapped, "m", 1);
    }
    if (flags & RXf_PMf_EXTENDED) { /* /x */
        /* prepend pattern with (?x) */
        SV* tmp = newSVpvn_flags("(?x)", 4+plen, SVs_TEMP);
        const char *ptmp = SvPVX_const(tmp);
        Copy(exp, &ptmp[4], plen+1, char);
        exp = SvPV(tmp, plen);
        sv_catpvn(wrapped, "x", 1);
    }
#ifdef RXf_PMf_NOCAPTURE
    if (flags & RXf_PMf_NOCAPTURE) {
        options |= HS_FLAG_SINGLEMATCH;
        options &= ~HS_FLAG_SOM_LEFTMOST;
    }
#endif
#ifdef RXf_PMf_CHARSET
    if (flags & RXf_PMf_CHARSET) {
      regex_charset cs;
      if ((cs = get_regex_charset(flags)) != REGEX_DEPENDS_CHARSET) {
        switch (cs) {
        case REGEX_UNICODE_CHARSET:
          options |= (HS_FLAG_UTF8);
          sv_catpvn(wrapped, "u", 1);
          break;
        case REGEX_ASCII_RESTRICTED_CHARSET:
          options &= ~HS_FLAG_UCP; /* /a */
          sv_catpvn(wrapped, "a", 1);
          break;
        case REGEX_ASCII_MORE_RESTRICTED_CHARSET:
          options &= ~HS_FLAG_UTF8; /* /aa */
          sv_catpvn(wrapped, "aa", 2);
          break;
        default:
          Perl_ck_warner(aTHX_ packWARN(WARN_REGEXP),
                         "local charset option ignored by Hyperscan");
        }
      }
    }
#endif
    /* TODO: l d g c */

    /* The pattern is known to be UTF-8. Perl wouldn't turn this on unless it's
     * a valid UTF-8 sequence so tell Hyperscan not to check for that */
#ifdef RXf_UTF8
    if (flags & RXf_UTF8)
#else
    if (SvUTF8(pattern))
#endif
        options |= (HS_FLAG_UTF8);

    rc = hs_compile(
        exp,          /* pattern */
        options,      /* options */
        HS_MODE_BLOCK,
        hs_platform_info,
        &database,
        &compile_err);

    if (rc != HS_SUCCESS) {
        /* TODO GH #1: With illegal/unsupported patterns, we might try
           to add HS_FLAG_PREFILTER without SOM to eliminate failing
           matches but using the faster hs, and only for true matches
           later at scan, give over to the core re_engine.
           https://01org.github.io/hyperscan/dev-reference/compilation.html#prefiltering-mode

           Not supported are zero-width assertions, back-references or
           conditional references.
        */
        Perl_ck_warner(aTHX_ packWARN(WARN_REGEXP),
                       "Hyperscan compilation failed with %d: %s\n",
                       compile_err->expression, compile_err->message);
        hs_free_compile_error(compile_err);
        return Perl_re_compile(aTHX_ pattern, flags);
    }

#if PERL_VERSION >= 12
    rx = (REGEXP*) newSV_type(SVt_REGEXP);
#else
    Newxz(rx, 1, REGEXP);
    rx->refcnt = 1;
#endif

    re = RegSV(rx);
    re->intflags = options;
    re->extflags = extflags;
    re->engine   = &hs_engine;

    if (SvCUR(wrapped_unset)) {
        sv_catpvn(wrapped, "-", 1);
        sv_catsv(wrapped, wrapped_unset);
    }
    sv_catpvn(wrapped, ":", 1);
#if PERL_VERSION > 10
    re->pre_prefix = SvCUR(wrapped);
#endif
    sv_catpvn(wrapped, exp, plen);
    sv_catpvn(wrapped, ")", 1);

#if PERL_VERSION == 10
    re->wraplen = SvCUR(wrapped);
    re->wrapped = savepvn(SvPVX(wrapped), SvCUR(wrapped));
#else
    RX_WRAPPED(rx) = savepvn(SvPVX(wrapped), SvCUR(wrapped));
    RX_WRAPLEN(rx) = SvCUR(wrapped);
    DEBUG_r(sv_dump((SV*)rx));
#endif

#if PERL_VERSION == 10
    /* Preserve a copy of the original pattern */
    re->prelen = (I32)plen;
    re->precomp = SAVEPVN(exp, plen);
#endif

    re->nparens = re->lastparen = re->lastcloseparen = nparens;
    /*Newxz(re->offs, nparens + 1, regexp_paren_pair);*/
    
    if ((rc = hs_alloc_scratch(database, &scratch)) != HS_SUCCESS) {
        croak("Hyperscan scratch memory error %d\n", rc);
        return 0;
    }
    /* Store our private objects */
    re->pprivate = malloc(sizeof(hs_pprivate_t));
    HS_PPRIVATE(re)->database = database;
    HS_PPRIVATE(re)->scratch  = scratch;

    return rx;
}

#if PERL_VERSION >= 18
/* code blocks are extracted like this:
  /a(?{$a=2;$b=3;($b)=$a})b/ =>
  expr: list - const 'a' + getvars + const '(?{$a=2;$b=3;($b)=$a})' + const 'b'
 */
REGEXP*  HS_op_comp(pTHX_ SV ** const patternp, int pat_count,
                    OP *expr, const struct regexp_engine* eng,
                    REGEXP *old_re,
                    bool *is_bare_re, U32 orig_rx_flags, U32 pm_flags)
{
    SV *pattern = NULL;
    if (!patternp) {
        OP *o = expr;
        for (; !o || OP_CLASS(o) != OA_SVOP; o = o->op_next) ;
        if (o && OP_CLASS(o) == OA_SVOP) {
            /* having a single const op only? */
            if (o->op_next == o || o->op_next->op_type == OP_LIST)
                pattern = cSVOPx_sv(o);
            else { /* no, fallback to core with codeblocks */
                return Perl_re_op_compile
                    (aTHX_ patternp, pat_count, expr,
                     &PL_core_reg_engine,
                     old_re, is_bare_re, orig_rx_flags, pm_flags);
            }
        }
    } else {
        pattern = *patternp;
    }
    return HS_comp(aTHX_ pattern, orig_rx_flags);
}
#endif

static int HS_found_cb(unsigned int id, unsigned long long from,
                       unsigned long long to, unsigned int flags, void *ctx) {
    const REGEXP *rx = (const REGEXP*)ctx;
    regexp * re = RegSV(rx);
    hs_database_t *ri = HS_PPRIVATE(re)->database;
    int i = re->nparens;

    DEBUG_r(printf("Hyperscan match %u at offset %llu until %llu\n",
                   id, from, to));
    if (!re->offs)
        re->offs = malloc(sizeof(re->offs[0]));
    else
        re->offs = realloc(re->offs, sizeof(re->offs[0]) * i);
    /* from only avail with HS_FLAG_SOM_LEFTMOST */
    re->offs[i].start = from;
    re->offs[i].end   = to;
    re->nparens++;
    return 1;
}

I32
#if PERL_VERSION < 20
HS_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, I32 minend, SV * sv,
          void *data, U32 flags)
#else
HS_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, SSize_t minend, SV * sv,
          void *data, U32 flags)
#endif
{
    regexp * re = RegSV(rx);
    hs_database_t *ri     = HS_PPRIVATE(re)->database;
    hs_scratch_t *scratch = HS_PPRIVATE(re)->scratch;
    int rc;
    I32 i;

    rc = hs_scan(ri, stringarg,
                 strend - strbeg,      /* length */
                 stringarg - strbeg,   /* offset */
                 scratch, HS_found_cb,
                 rx);

    /* match failed */
    if (rc != HS_SUCCESS) {
        croak("Hyperscan match error %d\n", rc);
        return 0;
    }

    re->subbeg = strbeg;
    re->sublen = strend - strbeg;

    return 1;
}

char *
#if PERL_VERSION < 20
HS_intuit(pTHX_ REGEXP * const rx, SV * sv,
             char *strpos, char *strend, const U32 flags, re_scream_pos_data *data)
#else
HS_intuit(pTHX_ REGEXP * const rx, SV * sv, const char *strbeg,
             char *strpos, char *strend, U32 flags, re_scream_pos_data *data)
#endif
{
	PERL_UNUSED_ARG(rx);
	PERL_UNUSED_ARG(sv);
#if PERL_VERSION >= 20
	PERL_UNUSED_ARG(strbeg);
#endif
	PERL_UNUSED_ARG(strpos);
	PERL_UNUSED_ARG(strend);
	PERL_UNUSED_ARG(flags);
	PERL_UNUSED_ARG(data);
    return NULL;
}

SV *
HS_checkstr(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return NULL;
}

void
HS_free(pTHX_ REGEXP * const rx)
{
    regexp * re = RegSV(rx);
    hs_free_database(HS_PPRIVATE(re)->database);
    hs_free_scratch (HS_PPRIVATE(re)->scratch);
    free(HS_PPRIVATE(re));
}

void *
HS_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    regexp * re = RegSV(rx);
    return re->pprivate;
}

SV *
HS_package(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return newSVpvs("re::engine::Hyperscan");
}

MODULE = re::engine::Hyperscan	PACKAGE = re::engine::Hyperscan
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
    mXPUSHs(newSViv(PTR2IV(&hs_engine)));

# pattern options

UV
min_width(REGEXP *rx)
PROTOTYPE: $
CODE:
    hs_expr_info_t *info;
    hs_compile_error_t *error;
    regexp * re = RegSV(rx);
    hs_expression_info(RX_WRAPPED(rx), re->intflags, &info, &error);
    if (error) hs_free_compile_error(error);
    RETVAL = (UV)info->min_width;
    free(info);
OUTPUT:
    RETVAL

UV
max_width(REGEXP *rx)
PROTOTYPE: $
CODE:
    hs_expr_info_t *info;
    hs_compile_error_t *error;
    regexp * re = RegSV(rx);
    hs_expression_info(RX_WRAPPED(rx), re->intflags, &info, &error);
    if (error) hs_free_compile_error(error);
    RETVAL = (UV)info->max_width;
    free(info);
OUTPUT:
    RETVAL

bool
unordered_matches(REGEXP *rx)
PROTOTYPE: $
CODE:
    hs_expr_info_t *info;
    hs_compile_error_t *error;
    regexp * re = RegSV(rx);
    hs_expression_info(RX_WRAPPED(rx), re->intflags, &info, &error);
    if (error) hs_free_compile_error(error);
    RETVAL = info->unordered_matches ? &PL_sv_yes : &PL_sv_no;
    free(info);
OUTPUT:
    RETVAL

bool
matches_at_eod(REGEXP *rx)
PROTOTYPE: $
CODE:
    hs_expr_info_t *info;
    hs_compile_error_t *error;
    regexp * re = RegSV(rx);
    hs_expression_info(RX_WRAPPED(rx), re->intflags, &info, &error);
    if (error) hs_free_compile_error(error);
    RETVAL = info->matches_at_eod ? &PL_sv_yes : &PL_sv_no;
    free(info);
OUTPUT:
    RETVAL

bool
matches_only_at_eod(REGEXP *rx)
PROTOTYPE: $
CODE:
    hs_expr_info_t *info;
    hs_compile_error_t *error;
    regexp * re = RegSV(rx);
    hs_expression_info(RX_WRAPPED(rx), re->intflags, &info, &error);
    if (error) hs_free_compile_error(error);
    RETVAL = info->matches_only_at_eod ? &PL_sv_yes : &PL_sv_no;
    free(info);
OUTPUT:
    RETVAL

BOOT:
{
    /* HS_ARCH_ERROR: Hyperscan requires SSSE3. */
    if (hs_populate_platform(hs_platform_info) < 0) {
        Perl_ck_warner(aTHX_ packWARN(WARN_REGEXP),
                       "Unsupported CPU by Hyperscan (need SSSE3)");
        return;
    }
}
