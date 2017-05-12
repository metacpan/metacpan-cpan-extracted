/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/utils.h 2     12-08-08 23:24 Sommar $

  This file includes various utility routines. In difference to
  the convenience routines, these may call the error handler and
  that. Several of these are called from Perl code as well.

  Copyright (c) 2004-2008   Erland Sommarskog

  $History: utils.h $
 * 
 * *****************  Version 2  *****************
 * User: Sommar       Date: 12-08-08   Time: 23:24
 * Updated in $/Perl/OlleDB
 * parsename now has a return value.
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern int parsename(SV   * olle_ptr,
                     SV   * sv_namestr,
                     int    retain_quotes,
                     SV   * sv_server,
                     SV   * sv_db,
                     SV   * sv_schema,
                     SV   * sv_object);


extern void replaceparamholders (SV * olle_ptr,
                                SV * cmdstring);

extern void codepage_convert(SV     * olle_ptr,
                             SV     * sv,
                             UINT     from_cp,
                             UINT     to_cp);

