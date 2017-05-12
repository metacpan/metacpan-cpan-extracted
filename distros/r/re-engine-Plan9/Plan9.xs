#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <utf.h>
#include <fmt.h>
#include <regexp9.h>

#include "Plan9.h"

REGEXP *
Plan9_comp(pTHX_ const SV * const pattern, const U32 flags)
{
    REGEXP * rx;
    Reprog * re;
    STRLEN plen;
    char*  exp = SvPV((SV*)pattern, plen);
    char* xend = exp + plen;
    U32 extflags = flags;

    /* C<split " ">, bypass the Plan 9 engine alltogether and act as perl does */
    if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ')
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);

    /* RXf_START_ONLY - Have C<split /^/> split on newlines */
    if (plen == 1 && exp[0] == '^')
        extflags |= RXf_START_ONLY;

    /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
    else if (plen == 3 && strnEQ("\\s+", exp, 3))
        extflags |= RXf_WHITE;

    /* REGEX structure for perl */
    Newxz(rx, 1, REGEXP);

    rx->refcnt = 1;
    rx->extflags = extflags;
    rx->engine = &engine_plan9;

    /* Precompiled regexp for pp_regcomp to use */
    rx->prelen = (I32)plen;
    rx->precomp = SAVEPVN(exp, rx->prelen);

    /* qr// stringification, reuse the space */
    rx->wraplen = rx->prelen;
    rx->wrapped = (char *)rx->precomp; /* from const char* */

    /* Catch invalid modifiers, the rest of the flags are ignored */
    if (flags & (RXf_PMf_MULTILINE|RXf_PMf_FOLD|RXf_PMf_KEEPCOPY))
        if (flags & RXf_PMf_MULTILINE) /* /m */
            croak("The `m' modifier is not supported by re::engine::Plan9");
        else if (flags & RXf_PMf_FOLD) /* /i */
            croak("The `i' modifier is not supported by re::engine::Plan9");
        else if (flags & RXf_PMf_KEEPCOPY) /* /p */
            croak("The `p' modifier is not supported by re::engine::Plan9");

    /* Modifiers valid, compile with the requested variant */
    if (flags & PMf_EXTENDED) /* /x */
        re = regcomplit(exp);
    if (flags & PMf_SINGLELINE) /* /s */
        re = regcompnl(exp);
    else
        re = regcomp(exp); /* / */

    if (re == 0)
        croak("Internal error in Plan 9 `regcomp'");

    /* Save for use in Plan9_exec */
    rx->pprivate = re;

    /* We always allocate 32 buffers */
    rx->nparens = NSUBEXP;
    Newxz(rx->offs, NSUBEXP + 1, regexp_paren_pair);

    return rx;
}

I32
Plan9_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
           char *strbeg, I32 minend, SV * sv,
           void *data, U32 flags)
{
    Reprog *re = rx->pprivate;
    Resub *match;;
    int ret;
    I32 i;
    char *s, *e;

    Newxz(match, NSUBEXP, Resub);

    rx->subbeg = strbeg;
    rx->sublen = strend - strbeg;

    match[0].s.sp = stringarg;
    match[0].e.ep = strend;
    
    ret = regexec(re, stringarg, match, NSUBEXP);

    /* Explicitly documented to return 1 on success */
    if (ret != 1) {
        Safefree(match);
        return 0;
    }

    /* Populate the match buffers, starting with $& */
    for (i = 0; match[i].s.sp; i++) {
        rx->offs[i].start = match[i].s.sp - strbeg;
        rx->offs[i].end   = match[i].e.ep - strbeg;
    }

    Safefree(match);

    /* Now that we actually know nparens set it to the currect value
       so split and //g will work */
    rx->nparens = i - 1;

    /* Mark the rest as unpopulated */
    for (; i <= NSUBEXP; i++) {
        rx->offs[i].start = -1;
        rx->offs[i].end   = -1;
    }

    /* Matched! */
    return 1;
}

char *
Plan9_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos,
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
Plan9_checkstr(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return NULL;
}

void
Plan9_free(pTHX_ REGEXP * const rx)
{
    free(rx->pprivate);
}

void *
Plan9_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    Reprog * re;
    Copy(rx->pprivate, re, 1, Reprog);
    return re;
}

SV *
Plan9_package(pTHX_ REGEXP * const rx)
{
    PERL_UNUSED_ARG(rx);
    return newSVpvs("re::engine::Plan9");
}

MODULE = re::engine::Plan9 PACKAGE = re::engine::Plan9
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
    XPUSHs(sv_2mortal(newSViv(PTR2IV(&engine_plan9))));
