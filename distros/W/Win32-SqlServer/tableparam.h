/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/tableparam.h 4     11-08-07 23:31 Sommar $

  Implements all support for table parameters.

  Copyright (c) 2004-2011   Erland Sommarskog

  $History: tableparam.h $
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:31
 * Updated in $/Perl/OlleDB
 * Updated copyright.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-02-10   Time: 23:19
 * Updated in $/Perl/OlleDB
 * Added typeinfo to definetableparam.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-05   Time: 20:48
 * Updated in $/Perl/OlleDB
 * New parameter in definetablecolumn: usedefault.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 08-01-05   Time: 0:28
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/

extern BOOL setup_tableparam(SV        * olle_ptr,
                             SV        * paramname,
                             paramdata * this_param,
                             ULONG       no_of_cols,
                             SV        * tabletypename);

extern int definetablecolumn(SV * olle_ptr,
                             SV * tblname,
                             SV * colname,
                             SV * nameoftype,
                             SV * maxlen,
                             SV * precision,
                             SV * scale,
                             SV * usedefault,
                             SV * typeinfo);

extern int inserttableparam(SV * olle_ptr,
                            SV * tblname,
                            SV * inputref);


