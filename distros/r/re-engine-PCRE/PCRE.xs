#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pcre.h>

#include "PCRE.h"

#if PERL_VERSION > 10
#define RegSV(p) SvANY(p)
#else
#define RegSV(p) (p)
#endif

REGEXP *
PCRE_comp(pTHX_ const SV * const pattern, const U32 flags)
{
    REGEXP *rx;
    regexp *re;
    pcre   *ri;

    STRLEN plen;
    char  *exp = SvPV((SV*)pattern, plen);
    char *xend = exp + plen;
    U32 extflags = flags;
    SV * wrapped = newSVpvn("(?", 2), * wrapped_unset = newSVpvn("", 0);

    /* pcre_compile */
    const char *error;
    int erroffset;

    /* pcre_fullinfo */
    unsigned long int length;
    int nparens;

    /* pcre_compile */
    int options = PCRE_DUPNAMES;

    /* named captures */
    int namecount;

    sv_2mortal(wrapped);
    sv_2mortal(wrapped_unset);

    /* C<split " ">, bypass the PCRE engine alltogether and act as perl does */
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

    /* Perl modifiers to PCRE flags, /s is implicit and /p isn't used
     * but they pose no problem so ignore them */
    if (flags & RXf_PMf_FOLD)
        options |= PCRE_CASELESS;  /* /i */
    if (flags & RXf_PMf_EXTENDED)
        options |= PCRE_EXTENDED;  /* /x */
    if (flags & RXf_PMf_MULTILINE)
        options |= PCRE_MULTILINE; /* /m */


    /* The pattern is known to be UTF-8. Perl wouldn't turn this on unless it's
     * a valid UTF-8 sequence so tell PCRE not to check for that */
#ifdef RXf_UTF8
    if (flags & RXf_UTF8)
#else
    if (SvUTF8(pattern))
#endif
        options |= (PCRE_UTF8|PCRE_NO_UTF8_CHECK);

    ri = pcre_compile(
        exp,          /* pattern */
        options,      /* options */
        &error,       /* errors */
        &erroffset,   /* error offset */
        NULL          /* use default character tables */
    );

    if (ri == NULL) {
        croak("PCRE compilation failed at offset %d: %s\n", erroffset, error);
        sv_2mortal(wrapped);
        return NULL;
    }

#if PERL_VERSION > 10
    rx = (REGEXP*) newSV_type(SVt_REGEXP);
#else
    Newxz(rx, 1, REGEXP);
    rx->refcnt = 1;
#endif

    re = RegSV(rx);
    re->extflags = extflags;
    re->engine   = &pcre_engine;

    /* qr// stringification, TODO: (?flags:pattern) */
    sv_catpvn(flags & RXf_PMf_FOLD ? wrapped : wrapped_unset, "i", 1);
    sv_catpvn(flags & RXf_PMf_EXTENDED ? wrapped : wrapped_unset, "x", 1);
    sv_catpvn(flags & RXf_PMf_MULTILINE ? wrapped : wrapped_unset, "m", 1);

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
    //Perl_sv_dump(rx);
#endif

#if PERL_VERSION == 10
    /* Preserve a copy of the original pattern */
    re->prelen = (I32)plen;
    re->precomp = SAVEPVN(exp, plen);
#endif

    /* Store our private object */
    re->pprivate = ri;

    /* If named captures are defined make rx->paren_names */
    pcre_fullinfo(
        ri,
        NULL,
        PCRE_INFO_NAMECOUNT,
        &namecount
    );

    if (namecount <= 0) {
        re->paren_names = NULL;
    } else {
        PCRE_make_nametable(re, ri, namecount);
    }

    /* set up space for the capture buffers */
    pcre_fullinfo(
        ri,
        NULL,
        PCRE_INFO_SIZE,
        &length
    );
    re->intflags = (U32)length;

    /* Check how many parens we need */
    pcre_fullinfo(
        ri,
        NULL,
        PCRE_INFO_CAPTURECOUNT,
        &nparens
    );

    re->nparens = re->lastparen = re->lastcloseparen = nparens;
    Newxz(re->offs, nparens + 1, regexp_paren_pair);

    /* return the regexp */
    return rx;
}

I32
PCRE_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, I32 minend, SV * sv,
          void *data, U32 flags)
{
    I32 rc;
    int *ovector;
    I32 i;
    int nparens;
    regexp * re = RegSV(rx);
    pcre *ri = re->pprivate;

    Newx(ovector, re->intflags, int);

    rc = (I32)pcre_exec(
        ri,
        NULL,
        stringarg,
        strend - strbeg,    /* length */
        stringarg - strbeg, /* offset */
        0,
        ovector,
        re->intflags /* XXX: was 30 */
    );

    /* Matching failed */
    if (rc < 0) {
        if (rc != PCRE_ERROR_NOMATCH) {
            Safefree(ovector);
            croak("PCRE error %d\n", rc);
        }


        Safefree(ovector);
        return 0;
    }

    re->subbeg = strbeg;
    re->sublen = strend - strbeg;

    for (i = 0; i < rc; i++) {
        re->offs[i].start = ovector[i * 2];
        re->offs[i].end   = ovector[i * 2 + 1];
    }

    for (i = rc; i <= re->nparens; i++) {
        re->offs[i].start = -1;
        re->offs[i].end   = -1;
    }



    /* XXX: nparens needs to be set to CAPTURECOUNT */

    Safefree(ovector);
    return 1;
}

char *
PCRE_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos,
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
PCRE_checkstr(pTHX_ REGEXP * const rx)
{
	PERL_UNUSED_ARG(rx);
    return NULL;
}

void
PCRE_free(pTHX_ REGEXP * const rx)
{
    regexp * re = RegSV(rx);
    pcre_free(re->pprivate);
}

void *
PCRE_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
	PERL_UNUSED_ARG(param);
    regexp * re = RegSV(rx);
    return re->pprivate;
}

SV *
PCRE_package(pTHX_ REGEXP * const rx)
{
	PERL_UNUSED_ARG(rx);
	return newSVpvs("re::engine::PCRE");
}

/*
 * Internal utility functions
 */

void
PCRE_make_nametable(regexp * const re, pcre * const ri, const int namecount)
{
    unsigned char *name_table, *tabptr;
    int name_entry_size;
    int i;
    IV j;

    /* The name table */
    pcre_fullinfo(
        ri,
        NULL,
        PCRE_INFO_NAMETABLE,
        &name_table
     );

    /* Size of each entry */
    pcre_fullinfo(
        ri,
        NULL,
        PCRE_INFO_NAMEENTRYSIZE,
        &name_entry_size
     );

    re->paren_names = newHV();
    tabptr = name_table;

    for (i = 0; i < namecount; i++)
    {
        const char *key = tabptr + 2;
        int npar = (tabptr[0] << 8) | tabptr[1];
        SV *sv_dat = *hv_fetch(re->paren_names, key, strlen(key), TRUE);

        if (!sv_dat)
            croak("panic: paren_name hash element allocation failed");

        if (!SvPOK(sv_dat)) {
            /* The first (and maybe only) entry with this name */
            (void)SvUPGRADE(sv_dat,SVt_PVNV);
            sv_setpvn(sv_dat, (char *)&(npar), sizeof(I32));
            SvIOK_on(sv_dat);
            SvIVX(sv_dat)= 1;
        } else {
            /* An entry under this name has appeared before, append */

            IV count = SvIV(sv_dat);
            I32 *pv = (I32*)SvPVX(sv_dat);
            IV j;

            for (j = 0 ; j < count ; j++) {
                if (pv[i] == npar) {
                    count = 0;
                    break;
                }
            }

            if (count) {
                pv = (I32*)SvGROW(sv_dat, SvCUR(sv_dat) + sizeof(I32)+1);
                SvCUR_set(sv_dat, SvCUR(sv_dat) + sizeof(I32));
                pv[count] = npar;
                SvIVX(sv_dat)++;
            }
        }

        tabptr += name_entry_size;
    }
}

MODULE = re::engine::PCRE	PACKAGE = re::engine::PCRE
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
	XPUSHs(sv_2mortal(newSViv(PTR2IV(&pcre_engine))));
