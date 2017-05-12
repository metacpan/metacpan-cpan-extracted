/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/datatypemap.cpp 4     11-08-07 23:20 Sommar $

  This file defines the table that maps type names in SQL Server to
  type indicators in OLE DB.

  Copyright (c) 2004-2011   Erland Sommarskog

  $History: datatypemap.cpp $
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:20
 * Updated in $/Perl/OlleDB
 * Suppress warning about data truncation on x64.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-02-10   Time: 17:12
 * Updated in $/Perl/OlleDB
 * Added the type name rowversion.
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
 * User: Sommar       Date: 07-12-24   Time: 21:40
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


#include "CommonInclude.h"
#include "datatypemap.h"


// Type map that maps name of SQL Server types to OLE DB type indicators.
// These two static arrays that we fill on first load. typenames has all
// the name of the types, and typeindicators has on the same index the
// the indicator to use.
#define SIZE_TYPE_MAP 1000
static char   typenames[SIZE_TYPE_MAP];
static DBTYPE typeindicators[SIZE_TYPE_MAP];


// Internal, called from fill_type_map.
static void add_type_entry(const char * name,
                           DBTYPE       indicator,
                           int         &ix)
{
   int new_ix = ix + (int) strlen(name) + 1;

   if (ix + strlen(name) + 1 > SIZE_TYPE_MAP) {
       croak ("Internal error: Adding %s at index ix = %d exceeds the size %d of the type map",
               name, ix, SIZE_TYPE_MAP);
   }
   strcpy_s(&(typenames[ix]), SIZE_TYPE_MAP - ix, name);
   typenames[new_ix - 1] = ' ';
   typeindicators[ix] = indicator;
   ix = new_ix;
}

// Called on initialisation.
void fill_type_map ()
{
   int    ix  = 1;

   typenames[0] = ' ';
   memset(typeindicators, 0, sizeof(DBTYPE) * SIZE_TYPE_MAP);
   add_type_entry("bigint",           DBTYPE_I8, ix);
   add_type_entry("binary",           DBTYPE_BYTES, ix);
   add_type_entry("bit",              DBTYPE_BOOL, ix);
   add_type_entry("char",             DBTYPE_STR, ix);
   add_type_entry("date",             DBTYPE_DBDATE, ix);
   add_type_entry("datetime",         DBTYPE_DBTIMESTAMP, ix);
   add_type_entry("datetime2",        DBTYPE_DBTIMESTAMP, ix);
   add_type_entry("datetimeoffset",   DBTYPE_DBTIMESTAMPOFFSET, ix);
   add_type_entry("decimal",          DBTYPE_NUMERIC, ix);
   add_type_entry("float",            DBTYPE_R8, ix);
   add_type_entry("geography",        DBTYPE_UDT, ix);
   add_type_entry("geometry",         DBTYPE_UDT, ix);
   add_type_entry("hierarchyid",      DBTYPE_UDT, ix);
   add_type_entry("image",            DBTYPE_BYTES, ix);
   add_type_entry("int",              DBTYPE_I4, ix);
   add_type_entry("money",            DBTYPE_CY, ix);
   add_type_entry("nchar",            DBTYPE_WSTR, ix);
   add_type_entry("ntext",            DBTYPE_WSTR, ix);
   add_type_entry("numeric",          DBTYPE_NUMERIC, ix);
   add_type_entry("nvarchar",         DBTYPE_WSTR, ix);
   add_type_entry("real",             DBTYPE_R4, ix);
   add_type_entry("rowversion",       DBTYPE_BYTES, ix);
   add_type_entry("smalldatetime",    DBTYPE_DBTIMESTAMP, ix);
   add_type_entry("smallint",         DBTYPE_I2, ix);
   add_type_entry("smallmoney",       DBTYPE_CY, ix);
   add_type_entry("sql_variant",      DBTYPE_SQLVARIANT, ix);
   add_type_entry("table",            DBTYPE_TABLE, ix);
   add_type_entry("text",             DBTYPE_STR, ix);
   add_type_entry("time",             DBTYPE_DBTIME2, ix);
   add_type_entry("timestamp",        DBTYPE_BYTES, ix);
   add_type_entry("tinyint",          DBTYPE_UI1, ix);
   add_type_entry("uniqueidentifier", DBTYPE_GUID, ix);
   add_type_entry("UDT",              DBTYPE_UDT, ix);
   add_type_entry("varbinary",        DBTYPE_BYTES, ix);
   add_type_entry("varchar",          DBTYPE_STR, ix);
   add_type_entry("xml",              DBTYPE_XML, ix);

   typenames[ix] = '\0';
}

// And this routine looks up a name in the type map.
DBTYPE lookup_type_map(const char * nameoftype)
{
   char * tmp;
   size_t ix;
   size_t strsize =  strlen(nameoftype) + 10;

   New(902, tmp, strsize, char);

   sprintf_s(tmp, strsize, " %s ", nameoftype);
   char * hit = strstr(typenames, tmp);
   Safefree(tmp);

   if (hit == NULL) {
      return DBTYPE_EMPTY;
   }
   ix = hit + 1 - typenames;
   return typeindicators[ix];
}
