/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/CommonInclude.h 5     18-04-09 22:47 Sommar $

  This file is included by all files for Win32::SqlServer and it includes
  header files from Windows and Perl that are needed about everywhere.
  It also define some macros that are needed universally.

  Copyright (c) 2004-2018   Erland Sommarskog

  $History: CommonInclude.h $
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 18-04-09   Time: 22:47
 * Updated in $/Perl/OlleDB
 * Oops, msdasc.h should not be commented out.
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 18-04-09   Time: 22:45
 * Updated in $/Perl/OlleDB
 * Use the new Microsoft OLE DB Driver for SQL Server.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:17
 * Updated in $/Perl/OlleDB
 * Use STRICT define for best practice.
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


#define UNICODE
#define _UNICODE
#define DBINITCONSTANTS
#define INITGUID
#define STRICT


#include <windows.h>
#include <oledb.h>
#include <oledberr.h>
#include <msdasc.h>
#include <msdadc.h>
#include <msoledbsql.h>

// Here we include the Perl stuff.
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>



