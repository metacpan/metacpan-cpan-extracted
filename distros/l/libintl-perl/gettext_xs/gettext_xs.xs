/* -*- C -*- */
/*
# Perl binding for Uniforum message translation.
# Copyright (C) 2002-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <locale.h>
#include <libintl.h>
/* Handle the case that we link against GNU libintl but include a non
 * GNU libintl.h.  */
#ifndef __USE_GNU_GETTEXT
# error "<libintl.h> is not GNU gettext.  Maybe you have to adjust your include path."
#endif

MODULE = Locale::gettext_xs	PACKAGE = Locale::gettext_xs

PROTOTYPES: ENABLE

char*
__gettext_xs_version ()
     CODE:
	  RETVAL = (VERSION);
     OUTPUT:
	  RETVAL
 
double
LC_CTYPE ()
     CODE:
          RETVAL = (double) LC_CTYPE;
     OUTPUT:
          RETVAL

double
LC_NUMERIC ()
     CODE:
          RETVAL = (double) LC_NUMERIC;
     OUTPUT:
          RETVAL

double
LC_TIME ()
     CODE:
          RETVAL = (double) LC_TIME;
     OUTPUT:
          RETVAL

double
LC_COLLATE ()
     CODE:
          RETVAL = (double) LC_COLLATE;
     OUTPUT:
          RETVAL

double
LC_MONETARY ()
     CODE:
          RETVAL = (double) LC_MONETARY;
     OUTPUT:
          RETVAL

double
LC_MESSAGES ()
     CODE:
          RETVAL = (double) LC_MESSAGES;
     OUTPUT:
          RETVAL

double
LC_ALL ()
     CODE:
          RETVAL = (double) LC_ALL;
     OUTPUT:
          RETVAL

char*
gettext (msgid)
     char* msgid
     PROTOTYPE: $
     CODE:
    	  RETVAL = (char*) gettext (msgid);
     OUTPUT:
	  RETVAL

char*
dgettext (domainname, msgid)
	char* domainname
	char* msgid
    PROTOTYPE: $$
    CODE:
	RETVAL = (char*) dgettext (domainname, msgid);
    OUTPUT:
	RETVAL

char* 
dcgettext (domainname, msgid, category)
	char* domainname
	char* msgid
	int category
    PROTOTYPE: $$$
    CODE:
	RETVAL = (char*) dcgettext (domainname, msgid, category);
    OUTPUT:
	RETVAL

char*
ngettext (msgid1, msgid2, n)
	char* msgid1
	char* msgid2
	unsigned long n
    PROTOTYPE: $$$
    CODE:
	RETVAL = (char*) ngettext (msgid1, msgid2, n);
    OUTPUT:
	RETVAL

char*
dngettext (domainname, msgid1, msgid2, n)
	char* domainname
	char* msgid1
	char* msgid2
	unsigned long n
    PROTOTYPE: $$$$
    CODE:
	RETVAL = (char*) dngettext (domainname, msgid1, msgid2, n);
    OUTPUT:
	RETVAL

char*
dcngettext (domainname, msgid1, msgid2, n, category)
	char* domainname
	char* msgid1
	char* msgid2
	unsigned long n
	int category
    PROTOTYPE: $$$$$
    CODE:
	RETVAL = (char*) dcngettext (domainname, msgid1, msgid2, n, category);
    OUTPUT:
	RETVAL

char*
_pgettext_aux (domain, msg_ctxt_id, msgid, category)
    char* domain
    char* msg_ctxt_id
    char* msgid
    int category
    PROTOTYPE: $$$$
    PREINIT:
    char* translation;
    CODE:
    /* Treat empty or undefined strings as NULL. */
    if (!domain || domain[0] == '\000')
        domain = NULL;
    /* Treat -1 as null, and default to LC_MESSAGES */
    if (category == -1)
        category = LC_MESSAGES;
    /* reimplemented from gettext-0.17 */
    translation = (char*) dcgettext (domain, msg_ctxt_id, category);
    if (translation == msg_ctxt_id)
        RETVAL = msgid;
    else
        RETVAL = translation;
    OUTPUT:
    RETVAL

char*
_npgettext_aux (domain, msg_ctxt_id, msgid1, msgid2, n, category)
    char* domain
    char* msg_ctxt_id
    char* msgid1
    char* msgid2
	unsigned long n
    int category
    PROTOTYPE: $$$$$$
    PREINIT:
    char* translation;
    CODE:
    /* Treat empty or undefined strings as NULL. */
    if (!domain || domain[0] == '\000')
        domain = NULL;
    /* Treat -1 as null, and default to LC_MESSAGES */
    if (category == -1)
        category = LC_MESSAGES;
    translation = (char*) dcngettext (domain, msg_ctxt_id, msgid2, n, category);
    if (translation == msg_ctxt_id || translation == msgid2)
        RETVAL = (n == 1 ? msgid1 : msgid2);
    else
        RETVAL = translation;
    OUTPUT:
    RETVAL

# FIXME: The prototype should actually be ';$' but it doesn't work
# as expected.  Passing no argument results in an error. 
char*
_textdomain (domain)
	char* domain
    PROTOTYPE: $
    CODE:
	/* Treat empty or undefined strings as NULL.  */
	if (!domain || domain[0] == '\000')
		domain = NULL;
	RETVAL = (char*) textdomain (domain);
	if (!RETVAL || RETVAL[0] == '\000') {
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

# This function is a no-op except for MS-DOS with its completely 
# brain-damaged environment interface.
int
_nl_putenv (str)
        char* str
    PROTOTYPE: $
    CODE:
#if defined (WIN32)
        RETVAL = _putenv (str);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL
        
char*
_bindtextdomain (domain = NULL, dirname = NULL)
	char* domain
	char* dirname
    PROTOTYPE: $;$
    CODE:
	/* Treat empty or undefined strings as NULL.  */
	if (!domain || domain[0] == '\000')
		XSRETURN_UNDEF;
	if (!dirname || dirname[0] == '\000')
		dirname = NULL;
	RETVAL = (char*) bindtextdomain (domain, dirname);
	if (!RETVAL || RETVAL[0] == '\000') {
		XSRETURN_UNDEF;
	}

    OUTPUT:
	RETVAL


char*
bind_textdomain_codeset (domainname, codeset)
	char* domainname
	char* codeset
    PROTOTYPE: $;$
    CODE:
	/* Treat empty or undefined strings as NULL.  */
	if (!domainname || domainname[0] == '\000')
		domainname = NULL;
	if (!codeset || codeset[0] == '\000')
		codeset = NULL;
	RETVAL = (char*) bind_textdomain_codeset (domainname, codeset);
	if (!RETVAL || RETVAL[0] == '\000') {
		XSRETURN_UNDEF;
	}

    OUTPUT:
	RETVAL

char* setlocale (category, locale = NULL)
     int category
     char *locale
     PROTOTYPE: $;$
     CODE:
    	  RETVAL = (char*) setlocale (category, locale);
     OUTPUT:
	  RETVAL

	
