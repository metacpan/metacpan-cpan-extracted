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
**  Copyright (c) 1996,1997,1998 Ralf S. Engelschall <rse@engelschall.com>
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
**  eperl_perl5.c -- ePerl Perl5 related stuff
*/

#include "eperl_config.h"
#include "eperl_global.h"
#include "eperl_perl5.h"
#include "eperl_perl5_sm.h"
#include "eperl_proto.h"

#ifdef HAVE_PERL_DYNALOADER

extern void boot_DynaLoader _((CV* cv));

/*
**
**  the Perl XS init function for dynamic library loading
**
*/
void Perl5_XSInit(void)
{
   char *file = __FILE__;
   /* dXSUB_SYS; */
   /* dummy = 0; */ /* make gcc -Wall happy ;-) */

   /* do newXS() the available modules */
   DO_NEWXS_STATIC_MODULES
}
#endif /* HAVE_PERL_DYNALOADER */

/*
**
**  Force Perl to use unbuffered I/O
**
*/
void Perl5_ForceUnbufferedStdout(void)
{
    IoFLAGS(GvIOp(defoutgv)) |= IOf_FLUSH; /* $|=1 */
    return;
}

/*
**
**  set a Perl environment variable
**
*/
char **Perl5_SetEnvVar(char **env, char *str) 
{
    char ca[1024];
    char *cp;

    strcpy(ca, str);
    cp = strchr(ca, '=');
    *cp++ = '\0';
    return mysetenv(env, ca, cp);
}

/*
**
**  sets a Perl scalar variable
**
*/
void Perl5_SetScalar(char *pname, char *vname, char *vvalue)
{
    ENTER;
    save_hptr(&curstash); 
    curstash = gv_stashpv(pname, TRUE);
    sv_setpv(perl_get_sv(vname, TRUE), vvalue);
    LEAVE;
    return;
}

/*
**
**  remember a Perl scalar variable
**  and set it later
**
**  (this is needed because we have to
**   remember the scalars when parsing 
**   the command line, but actually setting
**   them can only be done later when the
**   Perl 5 interpreter is allocated !!)
**
*/

char *Perl5_RememberedScalars[1024] = { NULL };

void Perl5_RememberScalar(char *str) 
{
    int i;

    for (i = 0; Perl5_RememberedScalars[i] != NULL; i++)
        ;
    Perl5_RememberedScalars[i++] = strdup(str);
    Perl5_RememberedScalars[i++] = NULL;
    return;
}

void Perl5_SetRememberedScalars(void) 
{
    char ca[1024];
    char *cp;
    int i;

    for (i = 0; Perl5_RememberedScalars[i] != NULL; i++) {
        strcpy(ca, Perl5_RememberedScalars[i]);
        cp = strchr(ca, '=');
        *cp++ = '\0';
        Perl5_SetScalar("main", ca, cp);
    }
}

/*EOF*/
