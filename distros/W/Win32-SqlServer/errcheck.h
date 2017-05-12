/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/errcheck.h 3     12-08-08 23:20 Sommar $

  This file holds routines for checking for errors and reporting
  errors and messages.

  Copyright (c) 2004-2008   Erland Sommarskog

  $History: errcheck.h $
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 12-08-08   Time: 23:20
 * Updated in $/Perl/OlleDB
 * Added an overload of olledb_message that accepts an SV* - good for
 * calls from Perl.
 * 
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-06   Time: 23:33
 * Updated in $/Perl/OlleDB
 * Replaced all unsafe CRT functions with their safe replacements in VC8.
 * olledb_message now takes a va_list as argument, so we pass it
 * parameterised strings and don't have to litter the rest of the code
 * with that.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern void olle_croak(SV         * olle_ptr,
                       const char * msg,
                       ...);


extern void msg_handler (SV        *olle_ptr,
                         int        msgno,
                         int        msgstate,
                         int        severity,
                         BSTR       msgtext,
                         LPOLESTR   srvname,
                         LPOLESTR   procname,
                         ULONG      line,
                         LPOLESTR   sqlstate,
                         LPOLESTR   source,
                         ULONG      n,
                         ULONG      no_of_errs);


extern void olledb_message (SV    * olle_ptr,
                            int     msgno,
                            int     state,
                            int     severity,
                            BSTR    msg,
                            ...);

extern void olledb_message (SV          * olle_ptr,
                            int           msgno,
                            int           state,
                            int           severity,
                            const char  * msg,
                            ...);

extern void olledb_message (SV    * olle_ptr,
                            int     msgno,
                            int     state,
                            int     severity,
                            SV    * msg);


extern void check_for_errors(SV *          olle_ptr,
                             const char   *context,
                             const HRESULT hresult,
                             BOOL          dieonnosql);

extern void check_for_errors(SV *          olle_ptr,
                             const char   *context,
                             const HRESULT hresult);


extern void check_convert_errors (char*        msg,
                                  DBSTATUS     dbstatus,
                                  DBBINDSTATUS bind_status,
                                  HRESULT      ret);


extern void check_convert_errors (char*        msg,
                                  DBSTATUS     dbstatus,
                                  HRESULT      ret);
