/* ------------------------------------------------------------------------
@NAME       : btxs_support.h
@DESCRIPTION: Macros, prototypes, and whatnot needed by both btxs_support.c
              and BibTeX.xs.
@GLOBALS    : 
@CREATED    : 1997/11/16, Greg Ward
@MODIFIED   : 
@VERSION    : $Id$
@COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.
-------------------------------------------------------------------------- */

#ifndef BTXS_SUPPORT_H
#define BTXS_SUPPORT_H

#ifndef BT_DEBUG
# define BT_DEBUG 0
#endif

#if BT_DEBUG
# define DBG_ACTION(level,action) if (BT_DEBUG >= level) { action; }
#else
# define DBG_ACTION(level,action)
#endif

/* Portability hacks go here... */

/* 
 * First, on SGIs, <string.h> doesn't prototype strdup() if _POSIX_SOURCE
 * is defined -- and it usually is for Perl, because that's the default.
 * So we workaround this by putting a prototype here.  Yuck.
 */
#if defined(__sgi) && defined(_POSIX_SOURCE)
extern char *strdup(const char *);
#endif


/* Prototypes */
void store_stringlist (HV *hash, char *key, char **list, int num_strings);
void ast_to_hash (SV *    entry_ref, 
                  AST *   top, 
                  boolean parse_status,
                  boolean preserve);
int constant (char * name, IV * arg);

#endif /* BTXS_SUPPORT_H */
