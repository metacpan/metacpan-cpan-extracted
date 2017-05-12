/* -*- c-basic-offset:4 -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
/* older versions: */
#ifndef PCRE2_ENDANCHORED
# define PCRE2_ENDANCHORED 0
#endif
#ifndef PCRE2_NO_JIT
# define PCRE2_NO_JIT 0
#endif
#include "PCRE2.h"
#include "regcomp.h"
#undef USE_MATCH_CONTEXT

#ifndef strEQc
# define strEQc(s, c) strEQ(s, ("" c ""))
#endif
#ifndef PERL_STATIC_INLINE
# define PERL_STATIC_INLINE static
#endif
#if PERL_VERSION <= 10
#define Perl_ck_warner Perl_warner
#endif

static char retbuf[64];

#if PERL_VERSION > 10
#define RegSV(p) SvANY(p)
#else
#define RegSV(p) (p)
#endif

static pcre2_match_context_8 *match_context = NULL;
#ifdef USE_MATCH_CONTEXT
static pcre2_jit_stack *jit_stack = NULL;
static pcre2_compile_context_8 *compile_context = NULL;

/* default is 32k already */
static pcre2_jit_stack *get_jit_stack(void)
{
    if (!jit_stack)
        jit_stack = pcre2_jit_stack_create(32*1024, 1024*1024, NULL);
    return jit_stack;
}
#endif

REGEXP *
#if PERL_VERSION < 12
PCRE2_comp(pTHX_ const SV * const pattern, const U32 flags)
#else
PCRE2_comp(pTHX_ SV * const pattern, U32 flags)
#endif
{
    REGEXP *rx;
    regexp *re;
    pcre2_code *ri = NULL;

    STRLEN plen;
    char  *exp = SvPV((SV*)pattern, plen);
    char *xend = exp + plen;
    U32 extflags = flags;
    SV * wrapped = newSVpvn_flags("(?", 2, SVs_TEMP);
    SV * wrapped_unset = newSVpvn_flags("", 0, SVs_TEMP);

    /* pcre2_compile */
    int errcode;
    PCRE2_SIZE erroffset;

    /* pcre2_pattern_info */
    PCRE2_SIZE length;
    U32 nparens;

    /* pcre_compile */
    U32 options = PCRE2_DUPNAMES;

#if PERL_VERSION >= 14
    /* named captures */
    I32 namecount;
#endif

    if (plen == 1 && exp[0] == ' ') {
        /* C<split " ">, bypass the PCRE2 engine alltogether and act as perl does */
        if (flags & RXf_SPLIT)
            extflags |= (RXf_SKIPWHITE|RXf_WHITE);
        else /* Have C<split / /> split on whitespace. / /," x y " -> (,x,y) */
            extflags |= RXf_WHITE;
    }

    /* RXf_NULL - Have C<split //> split by characters */
    if (plen == 0)
        extflags |= RXf_NULL;

    /* RXf_START_ONLY - Have C<split /^/> split on newlines */
    else if (plen == 1 && exp[0] == '^')
        extflags |= RXf_START_ONLY;

    /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
    else if (plen == 3 && strnEQ("\\s+", exp, 3))
        extflags |= RXf_WHITE;

    /* bypass anchors for now. needs the 4 ->substrs buffers. */
    if
#ifdef RXf_IS_ANCHORED
        (flags & RXf_IS_ANCHORED) /* => 5.20 */
#else
        (flags & (RXf_ANCH|RXf_ANCH_GPOS))
#endif
    {
        /* options |= PCRE2_ANCHORED; */ /* no \g anchors yet */
        DEBUG_r(PerlIO_printf(Perl_debug_log,
            "anchored \"\\g\" at 0 fallback to core\n"));
        return Perl_re_compile(aTHX_ pattern, flags);
    }

    /* Perl modifiers to PCRE2 flags, /s is implicit and /p isn't used
     * but they pose no problem so ignore them */
    /* qr// stringification, TODO: (?flags:pattern) */
    if (flags & RXf_PMf_FOLD) {
        options |= PCRE2_CASELESS;  /* /i */
        sv_catpvn(wrapped, "i", 1);
    }
    if (flags & RXf_PMf_SINGLELINE) {
        sv_catpvn(wrapped, "s", 1);
    }
    if (flags & RXf_PMf_EXTENDED) {
        options |= PCRE2_EXTENDED;  /* /x */
        sv_catpvn(wrapped, "x", 1);
    }
#ifdef RXf_PMf_EXTENDED_MORE
    if (flags & RXf_PMf_EXTENDED_MORE) {
# ifdef PCRE2_EXTENDED_MORE
        /* allow space and tab in [ ] classes */
        options |= PCRE2_EXTENDED_MORE;
        sv_catpvn(wrapped, "x", 1);
# else
        Perl_ck_warner(aTHX_ packWARN(WARN_REGEXP), "/xx ignored by pcre2");
        return Perl_re_compile(aTHX_ pattern, flags);
# endif        
    }
#endif
    if (flags & RXf_PMf_MULTILINE) {
        options |= PCRE2_MULTILINE; /* /m */
        sv_catpvn(wrapped, "m", 1);
    }
#ifdef RXf_PMf_NOCAPTURE
    if (flags & RXf_PMf_NOCAPTURE) {
        options |= PCRE2_NO_AUTO_CAPTURE; /* (?: and /n */
        sv_catpvn(wrapped, "n", 1);
    }
#endif
    /* since 5.14: */
#ifdef RXf_PMf_CHARSET
    if (flags & RXf_PMf_CHARSET) {
        regex_charset cs = get_regex_charset(flags);
        switch (cs) {
        case REGEX_UNICODE_CHARSET:
          options |= (PCRE2_UTF|PCRE2_NO_UTF_CHECK);
          sv_catpvn(wrapped, "u", 1);
          break;
        case REGEX_ASCII_RESTRICTED_CHARSET:
          options |= PCRE2_NEVER_UCP; /* /a */
          sv_catpvn(wrapped, "a", 1);
          break;
        case REGEX_ASCII_MORE_RESTRICTED_CHARSET:
          options |= PCRE2_NEVER_UTF; /* /aa */
          sv_catpvn(wrapped, "aa", 2);
          break;
        case REGEX_DEPENDS_CHARSET:
            /* /d old, problematic, pre-5.14 B<D>efault character set
               behavior.  Its only use is to force that old behavior. */
          break;
        case REGEX_LOCALE_CHARSET:
            /* /l sets the character set to that of whatever B<L>ocale is in
               effect at the time of the execution of the pattern match. */
            /* XXX PCRE2 maketables if necessary */
          Perl_ck_warner(aTHX_ packWARN(WARN_REGEXP),
               "/l local charset option ignored by pcre2");
          return Perl_re_compile(aTHX_ pattern, flags);
        }
    }
#endif
    /* TODO: l d c */

    /* The pattern is known to be UTF-8. Perl wouldn't turn this on unless it's
     * a valid UTF-8 sequence so tell PCRE2 not to check for that */
#ifdef RXf_UTF8
    if (flags & RXf_UTF8)
#else
    if (SvUTF8(pattern))
#endif
        options |= (PCRE2_UTF|PCRE2_NO_UTF_CHECK);

    ri = pcre2_compile(
        (PCRE2_SPTR8)exp, plen,    /* pattern */
        options,      /* options */
        &errcode,     /* errors */
        &erroffset,   /* error offset */
#ifdef USE_MATCH_CONTEXT
        &compile_context
#else
        NULL
#endif
    );

    if (ri == NULL) {
        PCRE2_UCHAR buf[256];
        /* ignore matching errors. prefer the core error */
        if (errcode < 100) { /* Compile errors */
            pcre2_get_error_message(errcode, buf, sizeof(buf));
            Perl_ck_warner(aTHX_ packWARN(WARN_REGEXP),
                 "PCRE2 compilation failed at offset %u: %s (%d)\n",
                 (unsigned)erroffset, buf, errcode);
        }
        return Perl_re_compile(aTHX_ pattern, flags);
    }
    /* pcre2_config_8(PCRE2_CONFIG_JIT, &have_jit);
    if (have_jit) */
    pcre2_jit_compile(ri, PCRE2_JIT_COMPLETE); /* no partial matches */

#if PERL_VERSION >= 12
    rx = (REGEXP*) newSV_type(SVt_REGEXP);
#else
    Newxz(rx, 1, REGEXP);
    rx->refcnt = 1;
#endif

    re = RegSV(rx);
    re->intflags = options;
    re->extflags = extflags;
    re->engine   = &pcre2_engine;

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
#endif
    DEBUG_r(sv_dump((SV*)rx));

#if PERL_VERSION == 10
    /* Preserve a copy of the original pattern */
    re->prelen = (I32)plen;
    re->precomp = SAVEPVN(exp, plen);
#endif

    /* Store our private object */
    re->pprivate = ri;

    /* If named captures are defined make rx->paren_names */
#if PERL_VERSION >= 14
    (void)pcre2_pattern_info(ri, PCRE2_INFO_NAMECOUNT, &namecount);

    if ((namecount <= 0) || (options & PCRE2_NO_AUTO_CAPTURE)) {
        re->paren_names = NULL;
    } else {
        PCRE2_make_nametable(re, ri, namecount);
    }
#endif

    /* Check how many parens we need */
    (void)pcre2_pattern_info(ri, PCRE2_INFO_CAPTURECOUNT, &nparens);
    re->nparens = re->lastparen = re->lastcloseparen = nparens;
    Newxz(re->offs, nparens + 1, regexp_paren_pair);

    /* return the regexp */
    return rx;
}

#if PERL_VERSION >= 18

/* code blocks are extracted like this:
  /a(?{$a=2;$b=3;($b)=$a})b/ =>
  expr: list - const 'a' + getvars + const '(?{$a=2;$b=3;($b)=$a})' + const 'b'

  TODO: pat_count > 1 and !expr (t/variable_expand.t)
 */
REGEXP*
PCRE2_op_comp(pTHX_ SV ** const patternp, int pat_count,
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
            if (o->op_next == o || o->op_next->op_type == OP_LIST) {
                pattern = cSVOPx_sv(o);
                DEBUG_r(PerlIO_printf(Perl_debug_log,
                    "PCRE2 op_comp: single const op \"%" SVf "\"\n", SVfARG(pattern)));
            }
            else { /* no, fallback to core with codeblocks */
                DEBUG_r(PerlIO_printf(Perl_debug_log,
                    "PCRE2 op_comp: codeblock. fallback to core\n"));
                return Perl_re_op_compile
                    (aTHX_ patternp, pat_count, expr,
                     &PL_core_reg_engine,
                     old_re, is_bare_re, orig_rx_flags, pm_flags);
            }
        }
    } else if (pat_count > 1) {
        SV **svp;
        SV *concat = newSVpvn_flags("",0,SVs_TEMP);
        bool can_concat = TRUE; /* can we handle the concat patterns by ourselves? */
        DEBUG_r(PerlIO_printf(Perl_debug_log,
            "PCRE2 op_comp: multi pattern nargs=%d\n", pat_count));
        /* concat_pat problem: if all the members are ours (even core),
           concat by ourselves. #26 */
        for (svp = patternp; svp < patternp + pat_count; svp++) {
            SV *sv = SvROK(*svp) ? SvRV(*svp) : *svp;
            if (SvTYPE(sv) == SVt_REGEXP) {
                bool is_ours = RX_ENGINE((REGEXP*)sv) == &pcre2_engine;
                bool is_core = RX_ENGINE((REGEXP*)sv) == &PL_core_reg_engine;
                const char *engine = is_core ? "core" : is_ours ? "pcre" : "plugin";
                DEBUG_r(PerlIO_printf(Perl_debug_log,
                                      "  %" SVf " <%s engine>\n", SVfARG(sv), engine));
                if (!is_ours && !is_core) /* we can concat ours and core... */
                    can_concat = FALSE;
                if (can_concat)
                    sv_catsv(concat, sv);
                else if (!is_core) /* convert back to core for S_concat_pat */
                    *svp = (SV*)re_compile(sv, pm_flags);
            } else {
                if (can_concat && SvPOK(sv))
                    sv_catsv(concat, sv);
                else
                    can_concat = FALSE; /* ...but not others */
                DEBUG_r(PerlIO_printf(Perl_debug_log,
                                      "  %" SVf "\n", SVfARG(sv)));
            }
        }
        if (can_concat)
            pattern = concat;
        else
            return Perl_re_op_compile(aTHX_ patternp, pat_count, expr,
                                      &PL_core_reg_engine,
                                      old_re, is_bare_re, orig_rx_flags, pm_flags);
    } else {
        pattern = *patternp;
    }
    DEBUG_r(PerlIO_printf(Perl_debug_log,
        "PCRE2 op_comp: \"%" SVf "\" 0x%x 0x%x\n", SVfARG(pattern),
        orig_rx_flags, pm_flags));
#if PERL_VERSION == 18
    /* intflags missing */
    return PCRE2_comp(aTHX_ pattern, orig_rx_flags);
#else
    return PCRE2_comp(aTHX_ pattern, orig_rx_flags?orig_rx_flags:pm_flags);
#endif
}
#endif

I32
#if PERL_VERSION < 20
PCRE2_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, I32 minend, SV * sv,
          void *data, U32 flags)
#else
PCRE2_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, SSize_t minend, SV * sv,
          void *data, U32 flags)
#endif
{
    I32 rc;
    I32 i;
    int have_jit;
    PCRE2_SIZE *ovector;
    pcre2_match_data *match_data;
    regexp * re = RegSV(rx);
    pcre2_code *ri = (pcre2_code *)re->pprivate;

    /* TODO utf8 problem: if the subject turns out to be utf8 here, but the
       pattern was not compiled as utf8 aware, we'd need to recompile
       it here. See GH #15 */

    match_data = pcre2_match_data_create_from_pattern(ri, NULL);
    pcre2_config_8(PCRE2_CONFIG_JIT, &have_jit);
    if (have_jit) {
#ifdef USE_MATCH_CONTEXT
        /* no compile_context yet */
        match_context = pcre2_match_context_create(compile_context);
        /* default MATCH_LIMIT: 10000000 - uint32_t,
           but even 5120000000 is not big enough for the core test suite */
        /*pcre2_set_match_limit(match_context, 5120000000);*/
        /*pcre2_jit_stack_assign(match_context, NULL, get_jit_stack());*/
#endif
        /* Masks for identifying the public options that are permitted at match time. */
#define PUBLIC_JIT_MATCH_OPTIONS \
   (PCRE2_NO_UTF_CHECK|PCRE2_NOTBOL|PCRE2_NOTEOL|PCRE2_NOTEMPTY|\
    PCRE2_NOTEMPTY_ATSTART|PCRE2_PARTIAL_SOFT|PCRE2_PARTIAL_HARD)

        rc = (I32)pcre2_jit_match(
            ri,
            (PCRE2_SPTR8)stringarg,
            strend - strbeg,      /* length */
            stringarg - strbeg,   /* offset */
            re->intflags & PUBLIC_JIT_MATCH_OPTIONS,
            match_data,           /* block for storing the result */
            match_context
        );
    } else {

        DEBUG_r(PerlIO_printf(Perl_debug_log,
            "PCRE2 skip jit match \"%.*s\" =~ /%s/\n",
            (int)re->sublen, strbeg, RX_WRAPPED(rx)));

#define PUBLIC_MATCH_OPTIONS                                            \
  (PCRE2_ANCHORED|PCRE2_ENDANCHORED|PCRE2_NOTBOL|PCRE2_NOTEOL|PCRE2_NOTEMPTY| \
   PCRE2_NOTEMPTY_ATSTART|PCRE2_NO_UTF_CHECK|PCRE2_PARTIAL_HARD| \
   PCRE2_PARTIAL_SOFT|PCRE2_NO_JIT)

        rc = (I32)pcre2_match(
            ri,
            (PCRE2_SPTR8)stringarg,
            strend - strbeg,      /* length */
            stringarg - strbeg,   /* offset */
            re->intflags & PUBLIC_MATCH_OPTIONS,
            match_data,           /* block for storing the result */
            match_context
        );
    }

    /* Matching failed */
    if (rc < 0) {
        pcre2_match_data_free(match_data);
#ifdef USE_MATCH_CONTEXT
        if (have_jit && match_context)
            pcre2_match_context_free(match_context);
#endif
        if (rc != PCRE2_ERROR_NOMATCH) {
            PCRE2_UCHAR buf[256];
            pcre2_get_error_message(rc, buf, sizeof(buf));
            Perl_croak(aTHX_ "PCRE2 match error: %s (%d)\n", buf, (int)rc);
        }
        return 0;
    }

    re->subbeg = strbeg;
    re->sublen = strend - strbeg;

    rc = pcre2_get_ovector_count(match_data);
    ovector = pcre2_get_ovector_pointer(match_data);
    DEBUG_r(PerlIO_printf(Perl_debug_log,
        "PCRE2 match \"%.*s\" =~ /%s/: found %d matches\n",
        (int)re->sublen, strbeg, RX_WRAPPED(rx), rc-1));
    for (i = 0; i < rc; i++) {
        re->offs[i].start = ovector[i * 2];
        re->offs[i].end   = ovector[i * 2 + 1];
        DEBUG_r(PerlIO_printf(Perl_debug_log,
            "match[%d]: \"%.*s\" [%d,%d]\n",
            i, (int)(re->offs[i].end - re->offs[i].start), &stringarg[re->offs[i].start],
            (int)re->offs[i].start, (int)re->offs[i].end));
    }

    for (i = rc; i <= re->nparens; i++) {
        re->offs[i].start = -1;
        re->offs[i].end   = -1;
    }

    /* XXX: nparens needs to be set to CAPTURECOUNT */
    pcre2_match_data_free(match_data);
#ifdef USE_MATCH_CONTEXT
    if (have_jit && match_context)
        pcre2_match_context_free(match_context);
#endif
    return 1;
}

char *
#if PERL_VERSION < 20
PCRE2_intuit(pTHX_ REGEXP * const rx, SV * sv,
             char *strpos, char *strend, const U32 flags, re_scream_pos_data *data)
#else
PCRE2_intuit(pTHX_ REGEXP * const rx, SV * sv, const char *strbeg,
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
PCRE2_checkstr(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return NULL;
}

void
PCRE2_free(pTHX_ REGEXP * const rx)
{
    regexp *re = RegSV(rx);
    pcre2_code_free((pcre2_code *)re->pprivate);
}

void *
PCRE2_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    regexp *re = RegSV(rx);
    return re->pprivate;
}

SV *
PCRE2_package(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return newSVpvs("re::engine::PCRE2");
}

/*
 * Internal utility functions
 */

#if PERL_VERSION >= 14
void
PCRE2_make_nametable(regexp * const re, pcre2_code * const ri, const I32 namecount)
{
    unsigned char *name_table, *tabptr;
    U32 name_entry_size;
    int i;

    /* The name table */
    (void)pcre2_pattern_info(ri, PCRE2_INFO_NAMETABLE, &name_table);

    /* Size of each entry */
    (void)pcre2_pattern_info(ri, PCRE2_INFO_NAMEENTRYSIZE, &name_entry_size);

    re->paren_names = newHV();
    tabptr = name_table;

    for (i = 0; i < namecount; i++) {
        const char *key = (char*)tabptr + 2;
        I32 npar = (tabptr[0] << 8) | tabptr[1]; /* the groupno (little endian only?) */
        SV *sv = *hv_fetch(re->paren_names, key, strlen(key), TRUE);

        if (!sv)
            Perl_croak(aTHX_ "panic: paren_name hash element allocation failed");

        if (!SvPOK(sv)) {
            /* The first (and maybe only) entry with this name */
            (void)SvUPGRADE(sv, SVt_PVIV);
            /* buffer of I32 groupno */
            sv_setpvn(sv, (char *)&(npar), sizeof(I32));
            SvIOK_on(sv);
            SvIVX(sv) = 1;
        } else {
            /* duplicate names: An entry under this name has appeared before, append */
            IV count = SvIV(sv);
            STRLEN len = SvCUR(sv);
            I32 *pv = (I32*)SvPVX_const(sv);
            IV j;

            assert(count < namecount);
            assert(count <= len*sizeof(I32));
            for (j = 0; j < count; j++) {
                if (pv[j] == npar) {
                    count = 0;
                    break;
                }
            }

            if (count) {
                pv = (I32*)SvGROW(sv, len + sizeof(I32)+1);
                SvCUR_set(sv, len + sizeof(I32));
                pv[count] = npar;
                SvIVX(sv)++;
            }
        }

        tabptr += name_entry_size;
    }
}
#endif

/* Note: some pcre versions overwrite the uint32_t value, esp. size.
   because some values are longer, size_t vs u32! */
#define DECL_U32_PATTERN_INFO(rx,name,UCNAME) \
PERL_STATIC_INLINE U32 \
PCRE2_##name(REGEXP* rx)  {  \
    regexp *re = RegSV(rx); \
    pcre2_code *ri = (pcre2_code *)re->pprivate; \
    U32 retval = -1; \
    pcre2_pattern_info(ri, PCRE2_INFO_##UCNAME, &retval);   \
    return retval; \
}
#define DECL_UV_PATTERN_INFO(rx,name,UCNAME) \
PERL_STATIC_INLINE UV \
PCRE2_##name(REGEXP* rx)  {  \
    regexp *re = RegSV(rx); \
    pcre2_code *ri = (pcre2_code *)re->pprivate; \
    size_t retval = 0; \
    pcre2_pattern_info(ri, PCRE2_INFO_##UCNAME, &retval); \
    return (UV)retval; \
}
#define DECL_UNDEF_PATTERN_INFO(rx,name,UCNAME) \
PERL_STATIC_INLINE UV \
PCRE2_##name(REGEXP* rx)  {  \
    return (UV)-1; \
}

DECL_U32_PATTERN_INFO(rx, _alloptions, ALLOPTIONS)
DECL_U32_PATTERN_INFO(rx, _argoptions, ARGOPTIONS)
DECL_U32_PATTERN_INFO(rx, backrefmax, BACKREFMAX)
DECL_U32_PATTERN_INFO(rx, bsr, BSR)
DECL_U32_PATTERN_INFO(rx, capturecount, CAPTURECOUNT)
DECL_U32_PATTERN_INFO(rx, firstcodetype, FIRSTCODETYPE)
DECL_U32_PATTERN_INFO(rx, firstcodeunit, FIRSTCODEUNIT)
#ifdef PCRE2_INFO_HASBACKSLASHC
DECL_U32_PATTERN_INFO(rx, hasbackslashc, HASBACKSLASHC)
#endif
DECL_U32_PATTERN_INFO(rx, hascrorlf, HASCRORLF)
#ifdef PCRE2_INFO_HEAPLIMIT
DECL_U32_PATTERN_INFO(rx, heaplimit, HEAPLIMIT)
#endif
DECL_U32_PATTERN_INFO(rx, jchanged, JCHANGED)
DECL_U32_PATTERN_INFO(rx, lastcodetype, LASTCODETYPE)
DECL_U32_PATTERN_INFO(rx, lastcodeunit, LASTCODEUNIT)
DECL_U32_PATTERN_INFO(rx, matchempty, MATCHEMPTY)
DECL_U32_PATTERN_INFO(rx, matchlimit, MATCHLIMIT)
DECL_U32_PATTERN_INFO(rx, maxlookbehind, MAXLOOKBEHIND)
DECL_U32_PATTERN_INFO(rx, minlength, MINLENGTH)
DECL_U32_PATTERN_INFO(rx, namecount, NAMECOUNT)
DECL_U32_PATTERN_INFO(rx, nameentrysize, NAMEENTRYSIZE)
DECL_U32_PATTERN_INFO(rx, newline, NEWLINE)
DECL_U32_PATTERN_INFO(rx, recursionlimit, RECURSIONLIMIT)

DECL_UV_PATTERN_INFO(rx, size, SIZE)
DECL_UV_PATTERN_INFO(rx, jitsize, JITSIZE)
#ifdef PCRE2_INFO_FRAMESIZE
DECL_UV_PATTERN_INFO(rx, framesize, FRAMESIZE)
#endif

MODULE = re::engine::PCRE2	PACKAGE = re::engine::PCRE2	PREFIX = PCRE2_
PROTOTYPES: ENABLE

void
PCRE2_ENGINE(...)
PROTOTYPE:
PPCODE:
    mXPUSHs(newSViv(PTR2IV(&pcre2_engine)));

# pattern options

#if 0

void
debug(REGEXP *rx, bool print_lengths=1)
CODE:
    regexp *re = RegSV(rx);
    pcre2_code *ri = (pcre2_code *)re->pprivate;
    FILE *f = stdout;
    pcre2_printint_8(ri,f,print_lengths);

#endif

U32
PCRE2__alloptions(REGEXP *rx)

U32
PCRE2__argoptions(REGEXP *rx)

U32
PCRE2_backrefmax(REGEXP *rx)

U32
PCRE2_bsr(REGEXP *rx, U32 value=0)
CODE:
    if (items == 2)
        croak("bsr setter nyi");
    RETVAL = PCRE2_bsr(rx);
    if (RETVAL == (U32)-1)
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

U32
PCRE2_capturecount(REGEXP *rx)

# returns a 256-bit table
void
firstbitmap(REGEXP *rx)
CODE:
    char* table;
    regexp *re = RegSV(rx);
    pcre2_code *ri = (pcre2_code *)re->pprivate;
    pcre2_pattern_info(ri, PCRE2_INFO_FIRSTBITMAP, table);
    if (table) {
        ST(0) = sv_2mortal(newSVpvn(table, 256/8));
        XSRETURN(1);
    }

U32
PCRE2_firstcodetype(REGEXP *rx)

U32
PCRE2_firstcodeunit(REGEXP *rx)

void
PCRE2_framesize(REGEXP *rx)
PPCODE:
#ifdef PCRE2_INFO_FRAMESIZE
    mXPUSHu(PCRE2_framesize(rx));
#else
    XSRETURN_UNDEF;
#endif

void
PCRE2_hasbackslashc(REGEXP *rx)
PPCODE:
#ifdef PCRE2_INFO_HASBACKSLASHC
    mXPUSHu(PCRE2_hasbackslashc(rx));
#else
    XSRETURN_UNDEF;
#endif

U32
PCRE2_hascrorlf(REGEXP *rx)

void
heaplimit(REGEXP *rx, U32 value=0)
PPCODE:
#ifdef PCRE2_INFO_HEAPLIMIT
    if (items == 2 && match_context)
        pcre2_set_heap_limit(match_context, (PCRE2_SIZE)value);
    mXPUSHu(PCRE2_heaplimit(rx));
#else
    XSRETURN_UNDEF;
#endif

U32
PCRE2_jchanged(REGEXP *rx)

UV
PCRE2_jitsize(REGEXP *rx)

UV
PCRE2_size(REGEXP *rx)

U32
PCRE2_lastcodetype(REGEXP *rx)

U32
PCRE2_lastcodeunit(REGEXP *rx)

U32
PCRE2_matchempty(REGEXP *rx)

U32
matchlimit(REGEXP *rx, U32 value=0)
CODE:
    if (items == 2)
        croak("matchlimit setter nyi");
    RETVAL = PCRE2_matchlimit(rx);
    if (RETVAL == (U32)-1)
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

U32
PCRE2_maxlookbehind(REGEXP *rx)

U32
PCRE2_minlength(REGEXP *rx)

U32
PCRE2_namecount(REGEXP *rx)

U32
PCRE2_nameentrysize(REGEXP *rx)

#if 0

SV*
nametable(REGEXP *rx)
PROTOTYPE: $
PPCODE:
    U8* table;
    regexp *re = RegSV(rx);
    pcre2_code *ri = (pcre2_code *)re->pprivate;
    pcre2_pattern_info(ri, PCRE2_INFO_NAMETABLE, &RETVAL);
    if (table)
        ST(0) = sv_2mortal(newSVpvn(table, strlen(table)));

#endif

U32
PCRE2_newline(REGEXP *rx)

U32
recursionlimit(REGEXP *rx, U32 value=0)
CODE:
    if (items == 2 && match_context)
        /* name changed from set_recursion_limit at Mar 12 2017 with 10.30 */
#if PCRE2_MINOR>=30 && defined(pcre2_code_copy_with_tables)
        pcre2_set_depth_limit(match_context, (PCRE2_SIZE)value);
#else
        pcre2_set_recursion_limit(match_context, (PCRE2_SIZE)value);
#endif
    RETVAL = PCRE2_recursionlimit(rx);
    if (RETVAL == (U32)-1)
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

# better check with rx->alloptions & PCRE2_USE_OFFSET_LIMIT
U32
offsetlimit(U32 value=0)
CODE:
    if (match_context) {
        if (items == 1)
            pcre2_set_offset_limit(match_context, (PCRE2_SIZE)value);
#ifdef USE_MATCH_CONTEXT
        RETVAL = match_context->offset_limit;
#endif
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
PCRE2_JIT(...)
PROTOTYPE:
PPCODE:
    uint32_t jit;
    if (pcre2_config(PCRE2_CONFIG_JIT, &jit) < 0)
        XSRETURN_UNDEF;
    mXPUSHi(jit ? 1 : 0);
    XSRETURN(1);

#define RET_STR(name) \
    if (strEQc(opt, #name)) { \
        if (pcre2_config(PCRE2_CONFIG_##name, &retbuf) >= 0) { \
            ST(0) = sv_2mortal(newSVpvn(retbuf, strlen(retbuf))); \
        } else {                             \
            XSRETURN_UNDEF;                  \
        }                                    \
        XSRETURN(1);                         \
    }
#define RET_INT(name) \
    if (strEQc(opt, #name)) { \
        if (pcre2_config(PCRE2_CONFIG_##name, &retint) >= 0) {   \
            ST(0) = sv_2mortal(newSViv(retint)); \
        } else {                            \
            XSRETURN_UNDEF;                 \
        }                                   \
        XSRETURN(1);                        \
    }
#define RET_NO(name) \
    if (strEQc(opt, #name)) { \
        XSRETURN_UNDEF;       \
    }

void
PCRE2_config(char* opt)
PROTOTYPE: $
PPCODE:
    int retint;
    RET_STR(JITTARGET) else
    RET_STR(UNICODE_VERSION) else
    RET_STR(VERSION) else
    RET_INT(BSR) else
    RET_INT(JIT) else
    RET_INT(LINKSIZE) else
    RET_INT(MATCHLIMIT) else
    RET_INT(NEWLINE) else
    RET_INT(PARENSLIMIT) else
    RET_INT(UNICODE)
#ifdef PCRE2_CONFIG_DEPTHLIMIT
    RET_INT(DEPTHLIMIT) else
#else
    RET_NO(DEPTHLIMIT) else
#endif
#ifdef PCRE2_CONFIG_RECURSIONLIMIT
    RET_INT(RECURSIONLIMIT) else /* Obsolete synonym */
#else
    RET_NO(RECURSIONLIMIT) else
#endif
#ifdef PCRE2_CONFIG_STACKRECURSE
    RET_INT(STACKRECURSE) else   /* Obsolete. Always 0 in newer libs */
#else
    RET_NO(STACKRECURSE) else
#endif
#ifdef PCRE2_CONFIG_HEAPLIMIT
    RET_INT(HEAPLIMIT) else /* Since 10.30 only */
#else
    RET_NO(HEAPLIMIT) else
#endif
    Perl_croak(aTHX_ "Invalid config argument %s", opt);
