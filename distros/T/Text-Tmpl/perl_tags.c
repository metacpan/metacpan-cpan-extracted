/* ====================================================================
 * Copyright 1999 Web Juice, LLC. All rights reserved.
 *
 * perl_tags.c
 *
 * These are the C functions which bridge the gap between the C template
 * extensions and perl template extensions.
 *
 * ==================================================================== */

#include <stdio.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <context.h>
#include <template.h>

#include "ppport.h"

#include "perl_tags.h"


/* ====================================================================
 * NAME:          perl_simple_tag
 *
 * DESCRIPTION:   The tag function for perl simple tags.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
perl_simple_tag(context_p ctx, char **output, int argc, char **argv)
{
    HV *perl_simple_tags = perl_get_hv(PERL_TAGS_SIMPLE_TAG_HASH, TRUE);
    SV **coderef         = NULL;
    SV *perlcontext      = sv_newmortal();
    SV *tc               = sv_newmortal();
    int i, retval;
    char key[20];
    dSP;
    CV *code;

    /* Build the unique key for this context */
    snprintf(key, 20, "%p", context_root(ctx));

    /* Create and bless a perl version of the context */
    sv_magic(tc, sv_2mortal(newSViv((IV)ctx)), '~', NULL, 0);
    perlcontext = sv_bless(newRV(tc), gv_stashpv(TEMPLATE_PACKAGE, 0));

    /* Fetch a code reference out of the perl_simple_tags hash */
    if (hv_exists(perl_simple_tags, key, strlen(key)))
    {
        HV *stags = (HV *)SvRV(*(hv_fetch(perl_simple_tags,
                                          key, strlen(key), FALSE)));
        coderef = hv_fetch(stags, argv[0], strlen(argv[0]), FALSE);
    }
    else
    {
        *output = NULL;
	return;
    }
    if (coderef == NULL)
    {
        *output = NULL;
        return;
    }
    code = (CV *)*coderef;

    ENTER;
    SAVETMPS;


    /* push arguments */
    PUSHMARK(sp);
    /* first the context */
    XPUSHs(perlcontext);
    for (i = 0; i <= argc; i++)
    {
        if (argv[i] != NULL)
        {
            XPUSHs(sv_2mortal(newSVpv(argv[i], strlen(argv[i]))));
        }
        else
        {
            XPUSHs(&PL_sv_undef);
        }
    }

    PUTBACK;

    retval = perl_call_sv((SV *)code, G_SCALAR);

    SPAGAIN;

    /* Translate the return into a char* for parser */
    if (retval == 1)
    {
        SV *s = POPs;

        if (! SvPOK(s)) {
            *output = NULL;
        } else {
            char *t = SvPVX(s);

            *output = (char *)malloc(strlen(t) + 1);
            strncpy(*output, t, strlen(t));
            (*output)[strlen(t)] = '\0';
        }
    }
    else
    {
        *output = NULL;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}



/* ====================================================================
 * NAME:          perl_tag_pair
 *
 * DESCRIPTION:   The tag pair function for perl tag pairs.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
perl_tag_pair(context_p ctx, int argc, char **argv)
{
    HV *perl_tag_pairs = perl_get_hv(PERL_TAGS_TAG_PAIR_HASH, TRUE);
    SV **coderef       = NULL;
    SV *perlcontext    = sv_newmortal();
    SV *tc             = sv_newmortal();
    int i;
    char key[20];
    dSP;
    CV *code;

    /* Build the unique key for this context */
    snprintf(key, 20, "%p", context_root(ctx));


    /* Create and bless a perl version of the context */
    sv_magic(tc, sv_2mortal(newSViv((IV)ctx)), '~', NULL, 0);
    perlcontext = sv_bless(newRV(tc), gv_stashpv(TEMPLATE_PACKAGE, 0));


    /* Fetch a code reference out of the perl_tag_pairs hash */
    if (hv_exists(perl_tag_pairs, key, strlen(key)))
    {
        HV *tagps = (HV *)SvRV(*(hv_fetch(perl_tag_pairs, key, strlen(key),
                                          FALSE)));
        coderef = hv_fetch(tagps, argv[0], strlen(argv[0]), FALSE);
    }
    else
    {
        return;
    }
    if (coderef == NULL)
    {
        return;
    }
    code = (CV *)*coderef;


    ENTER;
    SAVETMPS;


    /* push arguments */
    PUSHMARK(sp);
    /* first the context */
    XPUSHs(perlcontext);
    for (i = 0; i <= argc; i++)
    {
        if (argv[i] != NULL)
        {
            XPUSHs(sv_2mortal(newSVpv(argv[i], strlen(argv[i]))));
        }
        else
        {
            XPUSHs(&PL_sv_undef);
        }
    }

    PUTBACK;

    perl_call_sv((SV *)code, G_DISCARD);

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}
