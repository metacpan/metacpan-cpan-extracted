/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/getdata.h 1     07-12-24 21:39 Sommar $

  Implements the routines for getting data and metadata from SQL Server:
  nextresultset, getcolumninfo, nextrow, getoutputparams. Includes routines
  to Server data types to Perl values, save datetime data; those are in
  datetime.cpp.

  Copyright (c) 2004-2008   Erland Sommarskog

  $History: getdata.h $
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern int nextresultset (SV * olle_ptr,
                          SV * sv_rows_affected);


extern void getcolumninfo (SV   * olle_ptr,
                           SV   * hashref,
                           SV   * arrayref);


extern int nextrow (SV   * olle_ptr,
                    SV   * hashref,
                    SV   * arrayref);

extern void getoutputparams (SV * olle_ptr,
                             SV * hashref,
                             SV * arrayref);


