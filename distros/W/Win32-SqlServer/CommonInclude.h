/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/CommonInclude.h 3     11-08-07 23:17 Sommar $

  This file is included by all files for Win32::SqlServer and it includes
  header files from Windows and Perl that are needed about everywhere.
  It also define some macros that are needed universally.

  Copyright (c) 2004-2011   Erland Sommarskog

  $History: CommonInclude.h $
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
#define _SQLNCLI_OLEDB
#define STRICT


#include <windows.h>
#include <oledb.h>
#include <oledberr.h>
#include <msdasc.h>
#include <msdadc.h>
#include <SQLNCLI.h>

// Here we include the Perl stuff.
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>



