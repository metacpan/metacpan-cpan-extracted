#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tre/regex.h"

#include "TRE.h"

#if PERL_VERSION > 10
#define RegSV(p) SvANY(p)
#else
#define RegSV(p) (p)
#endif

REGEXP *
TRE_comp(pTHX_
#if PERL_VERSION == 10
    const
#endif
    SV * const pattern, const U32 flags)
{
    REGEXP  *rx;
    regexp  *re;
    regex_t *ri;

    STRLEN plen;
    char  *exp = SvPV((SV*)pattern, plen);
    char *xend = exp + plen;
    U32 extflags = flags;

    /* pregcomp vars */
    int cflags = 0;
    int err;
#define ERR_STR_LENGTH 512
    char err_str[ERR_STR_LENGTH];
    size_t err_str_length;

    /* C<split " ">, bypass the engine alltogether and act as perl does */
    if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ')
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);

    /* RXf_START_ONLY - Have C<split /^/> split on newlines */
    if (plen == 1 && exp[0] == '^')
        extflags |= RXf_START_ONLY;

    /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
    else if (plen == 3 && strnEQ("\\s+", exp, 3))
        extflags |= RXf_WHITE;

    /* REGEX structure for perl */
#if PERL_VERSION > 10
    rx = (REGEXP*) newSV_type(SVt_REGEXP);
#else
    Newxz(rx, 1, REGEXP);
    rx->refcnt = 1;
#endif

    re = RegSV(rx);
    re->extflags = extflags;
    re->engine = &engine_tre;

    /* Precompiled regexp for pp_regcomp to use */
#if PERL_VERSION == 10
    rx->prelen = (I32)plen;
    rx->precomp = SAVEPVN(exp, rx->prelen);
#endif

    /* qr// stringification, reuse the space */
#if PERL_VERSION == 10
    rx->wraplen = rx->prelen;
    rx->wrapped = (char *)rx->precomp; /* from const char* */
#else
    SV * wrapped = newSVpvn("(?", 2), * wrapped_unset = newSVpvn("", 0);
    sv_2mortal(wrapped);
    RX_WRAPPED(rx) = savepvn(SvPVX(wrapped), SvCUR(wrapped));
    RX_WRAPLEN(rx) = SvCUR(wrapped);
    //Perl_sv_dump(rx);
#endif

    /* Catch invalid modifiers, the rest of the flags are ignored */
    if (flags & (RXf_PMf_SINGLELINE|RXf_PMf_KEEPCOPY))
        if (flags & RXf_PMf_SINGLELINE) /* /s */
            croak("The `s' modifier is not supported by re::engine::TRE");
        else if (flags & RXf_PMf_KEEPCOPY) /* /p */
            croak("The `p' modifier is not supported by re::engine::TRE");

    /* Modifiers valid, munge to TRE cflags */
    if (flags & PMf_EXTENDED) /* /x */
        cflags |= REG_EXTENDED;
    if (flags & PMf_MULTILINE) /* /m */
        cflags |= REG_NEWLINE;
    if (flags & PMf_FOLD) /* /i */
        cflags |= REG_ICASE;

    Newxz(ri, 1, regex_t);

    err = regncomp(ri, exp, plen, cflags);

    if (err != 0) {
        /* note: we do not call regfree() when regncomp returns an error */
        err_str_length = regerror(err, ri, err_str, ERR_STR_LENGTH);
        if (err_str_length > ERR_STR_LENGTH) {
            croak("error compiling `%s': %s (error message truncated)", exp, err_str);
        } else {
            croak("error compiling `%s': %s", exp, err_str);
        }
    }

    /* Save for later */
    re->pprivate = ri;

    /*
      Tell perl how many match vars we have and allocate space for
      them, at least one is always allocated for $&
     */
    re->nparens = (U32)ri->re_nsub; /* cast from size_t */
    Newxz(re->offs, re->nparens + 1, regexp_paren_pair);

    /* return the regexp structure to perl */
    return rx;
}

I32
get_hint(const char *key, I32 def)
{
#if ((PERL_VERSION >= 13) && (PERL_SUBVERSION >= 7)) || (PERL_VERSION >= 14)
    SV *const val = cophh_fetch_pvn(PL_curcop->cop_hints_hash, key, strlen(key), 0, 0);
#else
    SV *const val = Perl_refcounted_he_fetch(aTHX_ PL_curcop->cop_hints_hash, Nullsv, key, strlen(key), 0, 0);
#endif
    if (SvOK(val) && SvIV_nomg(val)) {
        return SvIV(val);
    } else {
        return def;
    }
}

I32
TRE_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
           char *strbeg, I32 minend, SV * sv,
           void *data, U32 flags)
{
    regex_t *ri;
    regexp *re = RegSV(rx);
    regmatch_t *matches;
    regoff_t offs;
    size_t parens;
    int err;
    char *err_msg;
    int i;
    regamatch_t *match;
    regaparams_t params;

    //tre_regaparams_default(&params);
    params.cost_ins     = get_hint("re::engine::TRE::cost_ins",     1);
    params.cost_del     = get_hint("re::engine::TRE::cost_del",     1);
    params.cost_subst   = get_hint("re::engine::TRE::cost_subst",   1);
    params.max_cost     = get_hint("re::engine::TRE::max_cost",     0);
    params.max_ins      = get_hint("re::engine::TRE::max_ins",      INT_MAX);
    params.max_del      = get_hint("re::engine::TRE::max_del",      INT_MAX);
    params.max_subst    = get_hint("re::engine::TRE::max_subst",    INT_MAX);
    params.max_err      = get_hint("re::engine::TRE::max_err",      INT_MAX);

    ri = re->pprivate;
    parens = (size_t)re->nparens + 1;

    Newxz(matches, parens, regmatch_t);

    Newxz(match, 1, regamatch_t);
    match->nmatch = parens;
    match->pmatch = matches;

    err = reganexec(ri, stringarg, strend - stringarg, match, params, 0);

    if (err != 0) {
        assert(err == REG_NOMATCH);
        Safefree(matches);
        return 0;
    }

    re->subbeg = strbeg;
    re->sublen = strend - strbeg;

    /*
      regexec returns offsets from the start of `stringarg' but perl expects
      them to count from `strbeg'.
    */
    offs = stringarg - strbeg;

    for (i = 0; i < parens; i++) {
        if (matches[i].rm_eo == -1) {
            re->offs[i].start = -1;
            re->offs[i].end   = -1;
        } else {
            re->lastparen = i;
            re->offs[i].start = matches[i].rm_so + offs;
            re->offs[i].end   = matches[i].rm_eo + offs;
        }
    }

    Safefree(matches);
    Safefree(match);

    /* known to have matched by this point (see error handling above */
    return 1;
}

char *
TRE_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos,
             char *strend, U32 flags, re_scream_pos_data *data)
{
    PERL_UNUSED_ARG(rx);
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(strpos);
    PERL_UNUSED_ARG(strend);
    PERL_UNUSED_ARG(flags);
    PERL_UNUSED_ARG(data);
    return NULL;
}

SV *
TRE_checkstr(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return NULL;
}

void
TRE_free(pTHX_ REGEXP * const rx)
{
    regexp *re = RegSV(rx);
    regfree(re->pprivate);
}

void *
TRE_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    regexp *re = RegSV(rx);
    Copy(re->pprivate, re, 1, regexp);
    return re;
}

SV *
TRE_package(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return newSVpvs("re::engine::TRE");
}

MODULE = re::engine::TRE PACKAGE = re::engine::TRE
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(PTR2IV(&engine_tre))));
