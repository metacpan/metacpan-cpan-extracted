/* $Id: Constants.xs,v 1.2 2006/06/11 21:00:15 robertemay Exp $
 * Copyright (c) Robert May 2006
 *
 * Code for the Minimal Perfect Hash algorithm from
 * http://burtleburtle.net/bob/hash/perfect.html,
 * modified by Robert May.
 */

#define _WIN32_IE 0x0501
#define _WIN32_WINNT 0x0501
#define WINVER 0x0501

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Headers to define all the constants that
 * we want
 */
#include <windows.h>
#include <richedit.h>
#include <commctrl.h>
#include <shlobj.h>
#include "constants.h"

/* Perfect Hash implementation for Win32::GUI::Constants */
#include "phash.inc"

MODULE = Win32::GUI::Constants        PACKAGE = Win32::GUI::Constants

PROTOTYPES: ENABLE

     ##########################################################################
     # (@)METHOD:constant(key)
     # Looks up string constant C<key> to its numeric value
     # See Constants.pm for full documentation
void constant(c)
    SV* c
PREINIT:
    ULONG hash;
    STRLEN len;
    LPSTR key;
PPCODE:
    key = SvPV(c,len);
    hash = phash(key,len);
    if(hash < PHASHNKEYS) {
        const LPSTR str = stringpool + const_table[hash].offset;
        if(*key == *str && !strncmp(key+1, str+1, len-1) && str[len] == '\0') {
            if(const_table[hash].flags & F_UV) {
                /* Care with the casting, as UV's are (currently)
                 * unsigned long long on cygwin */
                XSRETURN_UV((UV)((ULONG)const_table[hash].value));
            }
            else {
                XSRETURN_IV((IV)const_table[hash].value);
            }
        }
    }
    errno = EINVAL;
    SetLastError(ERROR_INVALID_PARAMETER);
    XSRETURN_UNDEF; //error - not found

     ##########################################################################
     # (@)INTERNAL:_export_ok()
     # Return an array ref to an array of all possible constants.
     # Array consists of readonly PV's that point into
     # our string table:  this avoids copying the strings, which
     # saves memory and is over 3 times faster than the obvious:
     # INIT:
     #    int i;
     #    AV *list = newAV()
     # CODE:
     #    for(i=0; i < PHASHNKEYS; ++i) {
     #        av_push(list, newSVpv((stringpool + const_table[i].offset),0);
     #    }
     #    RETVAL = newRV_noinc((SV *)list);
     # OUTPUT:
     #    RETVAL
SV* _export_ok()
INIT:
    int i;
    AV *list = newAV();
    av_extend(list, PHASHNKEYS-1);
CODE:
    for(i=0; i < PHASHNKEYS; ++i) {
        SV *sv;
        LPSTR s = (stringpool + const_table[i].offset);
        sv = newSV(0);             /* create new SV */
        sv_upgrade(sv, SVt_PV);    /* upgrade to PV */
        SvPV_set(sv, s);           /* set PV string pointer to point into our string table */
        SvCUR_set(sv, strlen(s));  /* set the string length in the PV */
        SvLEN_set(sv, 0);          /* set the allocated length to 0 to prevent perl trying to free it */
        SvREADONLY_on(sv);         /* set the readonly flag */
        SvPOK_on(sv);              /* There's a vaild string pointer in the PV */
        av_store(list, i, sv);     /* store the SV in the array */
    }
    RETVAL = newRV_noinc((SV *)list);  /* return an RV referencing the array */
OUTPUT:
    RETVAL

