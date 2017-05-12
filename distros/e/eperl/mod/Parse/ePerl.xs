/*
**        ____           _ 
**    ___|  _ \ ___ _ __| |
**   / _ \ |_) / _ \ '__| |
**  |  __/  __/  __/ |  | |
**   \___|_|   \___|_|  |_|
** 
**  ePerl -- Embedded Perl 5 Language
**
**  ePerl interprets an ASCII file bristled with Perl 5 program statements
**  by evaluating the Perl 5 code while passing through the plain ASCII
**  data. It can operate both as a standard Unix filter for general file
**  generation tasks and as a powerful Webserver scripting language for
**  dynamic HTML page programming. 
**
**  ======================================================================
**
**  Copyright (c) 1996,1997 Ralf S. Engelschall, All rights reserved.
**
**  This program is free software; it may be redistributed and/or modified
**  only under the terms of either the Artistic License or the GNU General
**  Public License, which may be found in the ePerl source distribution.
**  Look at the files ARTISTIC and COPYING or run ``eperl -l'' to receive
**  a built-in copy of both license files.
**
**  This program is distributed in the hope that it will be useful, but
**  WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
**  Artistic License or the GNU General Public License for more details.
**
**  ======================================================================
**
**  ePerl.xs -- Perl interface to the ePerl parser (XS part)
*/


/*  standard XS stuff  */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/*  private stuff  */
#include "eperl_proto.h"


static int
not_here(s)
    char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}


static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Parse::ePerl  PACKAGE = Parse::ePerl      

double
constant(name,arg)
    char *      name
    int     arg


## 
##  PP -- Run the preprocessor
##  $buffer = Parse::ePerl::PP($buffer, \@INC);
##
void
PP(cpIn, avpsvpINC)
    char *cpIn;
    SV *avpsvpINC;
PROTOTYPE: $$
PPCODE:
{
    SV *sv;
    AV *avINC;
    char *cpOut;
    char **cppINC;
    char *cp;
    int n;
    int i;
    STRLEN l;

    if (!SvROK(avpsvpINC))
        croak("arg2 is not of reference type");
    sv = SvRV(avpsvpINC);
    if (SvTYPE(sv) != SVt_PVAV)
        croak("arg2 is not a reference to an array");
    avINC = (AV *)sv;

    /* convert Perl array to C array of pointers to chars */
    n = av_len(avINC);
    cppINC = (char **)malloc(sizeof(char *) * (n+2));
    for (i = 0; i <= n; i++) {
        sv = av_shift(avINC);
        /* XXX SvREFCNT_dec(sv); */
        cp = SvPV(sv, l);
        cppINC[i] = (char *)malloc(sizeof(char)*(l+1));
        strncpy(cppINC[i], cp, l);
        cppINC[i][l] = '\0';
    }
    cppINC[i] = NULL;

    /* call the preprocessor */
    cpOut = ePerl_PP(cpIn, cppINC);

    /* free cppINC */
    for (i = 0; cppINC[i] != NULL; i++)
        free(cppINC[i]);
    free(cppINC);

    if (cpOut != NULL) {
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSVpv(cpOut, 0)));
        free(cpOut);
    }
}


## 
##  Bristled2Plain -- Convert a bristled script to a plain script
##  $buffer = Parse::ePerl::Bristled2Plain($buffer, [$beginDel, $endDel]);
##
void
Bristled2Plain(cpIn, cpBegin = "<:", cpEnd = ":>", fCase = TRUE, fConvertEntities = FALSE)
    char *cpIn;
    char *cpBegin;
    char *cpEnd;
    int  fCase;
    int  fConvertEntities;
PROTOTYPE: $;$$$$
PPCODE:
{
    char *cpOut;

    ePerl_begin_delimiter           = cpBegin;
    ePerl_end_delimiter             = cpEnd;
    ePerl_case_sensitive_delimiters = fCase;
    ePerl_convert_entities          = fConvertEntities;
    cpOut = ePerl_Bristled2Plain(cpIn);
    if (cpOut != NULL) {
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSVpv(cpOut, 0)));
        free(cpOut);
    }
}


##EOF##
