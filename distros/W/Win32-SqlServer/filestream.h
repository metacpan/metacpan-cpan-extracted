/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/filestream.h 1     12-09-23 22:53 Sommar $

  This file includes the support for OpenSqlFileStream.

  Copyright (c) 2004-2012   Erland Sommarskog

  $History: filestream.h $
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:53
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern void * OpenSqlFilestream (SV         * olle_ptr,
                                 SV         * path,
                                 int          access,
                                 SV *         sv_context,
                                 unsigned int options,
                                 SV *         sv_alloclen);
