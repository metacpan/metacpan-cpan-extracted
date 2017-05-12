/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/datatypemap.h 1     07-12-24 21:39 Sommar $

  This file defines the table that maps type names in SQL Server to
  type indicators in OLE DB.

  Copyright (c) 2004-2008   Erland Sommarskog

  $History: datatypemap.h $
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern void fill_type_map ();

extern DBTYPE lookup_type_map(const char * nameoftype);