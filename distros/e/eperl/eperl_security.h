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
**  eperl_security.h -- ePerl security definitions
*/
#ifndef EPERL_SECURITY_H
#define EPERL_SECURITY_H 1


/*
 * General security for CGI modes
 */
#define CGI_NEEDS_ALLOWED_FILE_EXT       TRUE
#define LIST_OF_ALLOWED_FILE_EXT         { ".html", ".phtml", ".eperl", ".ephtml", ".epl", ".pl", ".cgi", NULL }

/* 
 * Perl security 
 * (BE CAREFUL HERE, THIS CAN MAKE YOUR LIVE HARD!) 
 */
#define CGI_MODES_FORCE_TAINTING         FALSE
#define CGI_MODES_FORCE_WARNINGS         FALSE

/*
 * SetUID security checks for CGI modes:
 * You can enable/disable any checked steps here.
 */
#define SETUID_NEEDS_VALID_CALLER_UID    TRUE
#define SETUID_NEEDS_ALLOWED_CALLER_UID  TRUE
#define SETUID_NEEDS_VALID_OWNER_UID     TRUE
#define SETUID_NEEDS_VALID_OWNER_GID     TRUE
#define SETUID_NEEDS_BELOW_OWNER_HOME    TRUE
#define LIST_OF_ALLOWED_CALLER_UID       { "nobody", "root", NULL }

/* 
 * Action when a SetUID security check failed.
 *
 * Define ``DO_FOR_FAILED_STEP'' to one of the following:
 *
 * MARK_AND_GO_ON: step is marked as failed and processing goes on.
 *                 BUT: No UID/GID switching takes place!
 *                 (default)
 *
 * STOP_AND_ERROR: immediately stop processing print an error.
 *                 (for the paranoid webmaster who really
 *                  wants to enable ePerl only succeded UID/GID
 *                  switching)
 */
#define MARK_AND_GO_ON      1
#define STOP_AND_ERROR      2
#define DO_FOR_FAILED_STEP  MARK_AND_GO_ON


#endif /* EPERL_SECURITY_H */
/*EOF*/
