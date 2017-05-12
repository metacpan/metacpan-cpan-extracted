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
**  eperl_global.h -- ePerl global header file
*/
#ifndef EPERL_GLOBAL_H
#define EPERL_GLOBAL_H 1


/*
**
**  The ePerl block delimiters
**
*/
#define BEGIN_DELIMITER_FILTER "<:"
#define   END_DELIMITER_FILTER ":>"
#define BEGIN_DELIMITER_CGI    "<?"
#define   END_DELIMITER_CGI    "!>"


/*
**
**  The ePerl runtime mode
**
*/
#define MODE_UNKNOWN    1
#define MODE_FILTER     2
#define MODE_CGI        4
#define MODE_NPHCGI     8


/* 
**
**   debugging
**
*/
#ifdef DEBUG_ENABLED
#ifdef HAVE_DMALLOC
#define DMALLOC_FUNC_CHECK 1
#include <dmalloc.h>
#endif
#endif


/*
**
**  CU() -- CleanUp Makro (implemented in a safety way)
**
*/
#define DECL_EXRC int rc
#define EXRC rc
#define ZERO 0
#define STMT(stuff) do { stuff } while (ZERO)
#define CU(returncode) STMT( rc = returncode; goto CUS; )
#define VCU STMT( goto CUS; )
#define RETURN_WVAL(val) return (val)
#define RETURN_EXRC return (rc)
#define RETURN_NORC return


#endif /* EPERL_GLOBAL_H */
/*EOF*/
