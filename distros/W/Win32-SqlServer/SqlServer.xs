/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/SqlServer.xs 101   24-07-15 23:50 Sommar $

  The main flie for Win32::SqlServer. This file only includes the XS
  parts these days. All other code is in other files.

  Copyright (c) 2004-2024   Erland Sommarskog

  $History: SqlServer.xs $
 * 
 * *****************  Version 101  *****************
 * User: Sommar       Date: 24-07-15   Time: 23:50
 * Updated in $/Perl/OlleDB
 * Added one more parameter to SetDefaultForEncryption
 * 
 * *****************  Version 100  *****************
 * User: Sommar       Date: 22-05-18   Time: 22:22
 * Updated in $/Perl/OlleDB
 * Added module routine SetDefaultForEncryption to permit changing the
 * default for the lgoin properties Encrypt, TrustServerCertificate and
 * HostNameInCertificate.
 * 
 * *****************  Version 99  *****************
 * User: Sommar       Date: 19-07-09   Time: 16:05
 * Updated in $/Perl/OlleDB
 * Added GetOEMCP for the benefit of 4_conversion.t.
 * 
 * *****************  Version 98  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:45
 * Updated in $/Perl/OlleDB
 * initbatch now hs a return value and a new (internal) parameter. Added
 * three more internal routines to get SQL Server version, Current
 * database and ANSI Code page.
 * 
 * *****************  Version 97  *****************
 * User: Sommar       Date: 16-07-15   Time: 13:46
 * Updated in $/Perl/OlleDB
 * Disable the new handcheck in Perl 5.22 and up on x86, since the check
 * fails with ActivePerl and StrawberryPerl.
 * 
 * *****************  Version 96  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:53
 * Updated in $/Perl/OlleDB
 * Moved OpenSqlFilestream to a file of its own.
 * 
 * *****************  Version 95  *****************
 * User: Sommar       Date: 12-08-08   Time: 23:22
 * Updated in $/Perl/OlleDB
 * The profile of olledb_message has changed, char * replaced with SV* to
 * handle Unicode data correctly. parsname now has a return value.
 * 
 * *****************  Version 94  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:30
 * Updated in $/Perl/OlleDB
 * Suppress/fix warnings about data truncation on x64.
 * 
 * *****************  Version 93  *****************
 * User: Sommar       Date: 10-10-29   Time: 16:20
 * Updated in $/Perl/OlleDB
 * Added GetProcessWorkingSetSize only to be able to test for memory
 * leaks. Any use of this routine outside this scope is unsupported. The
 * procedure could be removed without notice.
 *
 * *****************  Version 92  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:44
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared.
 *
 * *****************  Version 91  *****************
 * User: Sommar       Date: 09-04-25   Time: 22:29
 * Updated in $/Perl/OlleDB
 * setupinternaldata was incorrectly defined to return int, which botched
 * the pointer once address was > 7FFFFFFF.
 *
 * *****************  Version 90  *****************
 * User: Sommar       Date: 08-04-28   Time: 23:15
 * Updated in $/Perl/OlleDB
 * Fixed incorrect declaration in OpenSqlFileStream for 64-bit.
 *
 * *****************  Version 89  *****************
 * User: Sommar       Date: 08-02-17   Time: 18:01
 * Updated in $/Perl/OlleDB
 * Added support for allocation length, the last parameter to
 * OpenSqlFilestream.
 *
 * *****************  Version 88  *****************
 * User: Sommar       Date: 08-02-10   Time: 23:18
 * Updated in $/Perl/OlleDB
 * Need to have a typeinfo in definetablecolumn.
 *
 * *****************  Version 87  *****************
 * User: Sommar       Date: 08-01-05   Time: 20:48
 * Updated in $/Perl/OlleDB
 * Added parameter usedefault for definetablecolumn.
 *
 * *****************  Version 86  *****************
 * User: Sommar       Date: 08-01-05   Time: 0:23
 * Updated in $/Perl/OlleDB
 * Added definetablecolumn and inserttableparam to deal with table-valued
 * parameters.
 *
 * *****************  Version 85  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:38
 * Updated in $/Perl/OlleDB
 * Extracted out all code but the true XS part to separate file, as the
 * size was getting out of hand.
 *
 * *****************  Version 84  *****************
 * User: Sommar       Date: 07-12-01   Time: 23:39
 * Updated in $/Perl/OlleDB
 * Added support for OpenSqlFilestream.
 *
 * *****************  Version 83  *****************
 * User: Sommar       Date: 07-11-25   Time: 17:42
 * Updated in $/Perl/OlleDB
 * Added support for the spatial data types.
 *
 * *****************  Version 82  *****************
 * User: Sommar       Date: 07-11-12   Time: 23:04
 * Updated in $/Perl/OlleDB
 * Oops. Never called OptSqlVersion in initbatch. For conversion to
 * datetime classic with sql�variant require Year, Month and Day in hash.
 *
 * *****************  Version 81  *****************
 * User: Sommar       Date: 07-11-11   Time: 20:19
 * Updated in $/Perl/OlleDB
 * Moved the retrieval of SqlVersion to InitBatch. Can't do it in
 * do_connect when AutoConnect is on. Applicatoin of TZOffset did work for
 * dates before 1899-12-30. Wrong upper limit for smalldatetime.
 *
 * *****************  Version 80  *****************
 * User: Sommar       Date: 07-11-10   Time: 20:11
 * Updated in $/Perl/OlleDB
 * Various cleaning up for date/time handling.
 *
 * *****************  Version 79  *****************
 * User: Sommar       Date: 07-10-28   Time: 23:38
 * Updated in $/Perl/OlleDB
 * More work with date/time after testing.
 *
 * *****************  Version 78  *****************
 * User: Sommar       Date: 07-10-20   Time: 23:15
 * Updated in $/Perl/OlleDB
 * Completed support for date/time data types. Also addressed the fact
 * that junk after an ISO-date string was ignored and did not give an
 * error.
 *
 * *****************  Version 77  *****************
 * User: Sommar       Date: 07-10-14   Time: 18:27
 * Updated in $/Perl/OlleDB
 * Support now also added for input of the new date/time data types, save
 * sql_variant.
 *
 * *****************  Version 76  *****************
 * User: Sommar       Date: 07-10-06   Time: 23:10
 * Updated in $/Perl/OlleDB
 * Added support for new date/time data types in getcolumnsinfo.
 *
 * *****************  Version 75  *****************
 * User: Sommar       Date: 07-10-06   Time: 22:20
 * Updated in $/Perl/OlleDB
 * Added support for receiving data in the new date/time data types.
 *
 * *****************  Version 74  *****************
 * User: Sommar       Date: 07-09-16   Time: 22:39
 * Updated in $/Perl/OlleDB
 * Added support for large UDTs and the built-in hierarchyid type.
 *
 * *****************  Version 73  *****************
 * User: Sommar       Date: 07-09-09   Time: 0:13
 * Updated in $/Perl/OlleDB
 * Added support for SQL Server Native Client. Temporary fix to get
 * datetime to work with Katmai.
 *
 * *****************  Version 72  *****************
 * User: Sommar       Date: 07-07-10   Time: 21:59
 * Updated in $/Perl/OlleDB
 * Win32::SqlServer 2.003.
 *
  ---------------------------------------------------------------------*/


#include "CommonInclude.h"
#include "handleattributes.h"
#include "convenience.h"
#include "init.h"
#include "internaldata.h"
#include "errcheck.h"
#include "connect.h"
#include "utils.h"
#include "senddata.h"
#include "getdata.h"
#include "tableparam.h"
#include "filestream.h"

#include <psapi.h>

// There is a new handshake check starting with Perl 5.22. Unfortunately,
// this check fails on x86 (but not x64!) when I build the module with
// Visual Studio and later run the module with ActivePerl or 
// StrawberryPerl. This #define disables the check. Note that this not
// documented or supported in any form - I arrived at the solution by
// looking at the source code.
#ifndef WIN64
#define XS_BOTHVERSION_SETXSUBFN_POPMARK_BOOTCHECK 1
#endif

MODULE = Win32::SqlServer           PACKAGE = Win32::SqlServer

PROTOTYPES: ENABLE

BOOT:
initialize();

void
SetDefaultForEncryption(sv_Encrypt, sv_Trust = NULL, sv_HostName = NULL, sv_ServerName = NULL)
   SV * sv_Encrypt
   SV * sv_Trust
   SV * sv_HostName
   SV * sv_ServerName


void
olledb_message (olle_ptr, msgno, state, severity, msg)
   SV   * olle_ptr
   int    msgno
   int    state
   int    severity
   SV   * msg

void *
setupinternaldata()

void
setloginproperty(sqlsrv, prop_name, prop_value)
   SV   * sqlsrv;
   char * prop_name;
   SV   * prop_value;


int
connect(sqlsrv)
   SV * sqlsrv
  CODE:
{
    internaldata  * mydata = get_internaldata(sqlsrv);

    // Check that we are not already connected.
    if (mydata->datasrc_ptr != NULL) {
       olle_croak(sqlsrv, "Attempt to connect despite already being connected");
    }

    RETVAL = do_connect(sqlsrv, FALSE);
}
OUTPUT:
   RETVAL

void
disconnect(sqlsrv)
   SV * sqlsrv

int
isconnected(sqlsrv)
   SV * sqlsrv
  CODE:
{
   internaldata  * mydata = get_internaldata(sqlsrv);
   RETVAL = mydata->datasrc_ptr != NULL;
}
OUTPUT:
   RETVAL

void
xs_DESTROY(olle_ptr)
        SV *    olle_ptr
  CODE:
{
// This routine is called from DESTROY in the Perl code. We cannot have
// DESTROY here directly, because the Perl code has to take some extra
// precautions.
    internaldata * mydata = get_internaldata(olle_ptr);
    if (mydata != NULL) {
       disconnect(olle_ptr);

       // Free up area allocated to all properties.
       for (int i = 0; gbl_init_props[i].propset_enum != not_in_use; i++) {
          VariantClear(&mydata->init_properties[i].vValue);
       }

       // Make sure strings for SQL version and current database are
       // cleared.
       free_sqlver_currentdb(mydata);

       // And dispense of mydata itself. The Perl DESTROY will set mydata
       // to 0, to avoid a second cleanup when Perl calls DESTROY a second
       // time. (Which it does for some reason.)
       Safefree(mydata);
   }
}

void
validatecallback(olle_ptr, callbackname)
          SV * olle_ptr
          SV * callbackname
CODE:
{
    // This is a help routine to validate that a name for a message handler
    // refers to an existing sub. It's called from STORE (which is in Perl
    // code).
    char *name = SvPV_nolen(callbackname);
    CV * callback = get_cv(name, FALSE);
    if (! callback) {
        olle_croak(olle_ptr, "Can't find specified message handler '%s'", name);
    }
    // OK, we found an message handler, but was it pure luck?
    else if (PL_dowarn && ! strstr(name, "::")) {
       warn("Message handler '%s' given as a unqualified name. This could fail next time you try", name);
    }
}


int
initbatch(sqlsrv, sv_cmdtext, isnestedquery = FALSE)
    SV   *sqlsrv
    SV   *sv_cmdtext
    int  isnestedquery

int
enterparameter(sqlsrv, nameoftype, sv_maxlen, paramname, isinput, isoutput, sv_value = NULL, sv_precision = NULL, sv_scale = NULL, typeinfo = NULL)
   SV   * sqlsrv;
   SV   * nameoftype;
   SV   * sv_maxlen;
   SV   * paramname;
   int    isinput;
   int    isoutput;
   SV   * sv_value;
   SV   * sv_precision;
   SV   * sv_scale;
   SV   * typeinfo;

int
definetablecolumn(sqlsrv, tblname, colname, nameoftype, sv_maxlen = NULL, sv_precision = NULL, sv_scale = NULL, usedefault = NULL, typeinfo = NULL)
   SV * sqlsrv;
   SV * tblname;
   SV * colname;
   SV * nameoftype;
   SV * sv_maxlen;
   SV * sv_precision;
   SV * sv_scale;
   SV * usedefault;
   SV * typeinfo;

int
inserttableparam(sqlsrv, tblname, inputref)
   SV * sqlsrv;
   SV * tblname;
   SV * inputref;

int
executebatch(sqlsrv, rows_affected = NULL)
  SV * sqlsrv;
  SV * rows_affected;

int
nextresultset(sqlsrv, rows_affected = NULL)
  SV * sqlsrv;
  SV * rows_affected;

void
getcolumninfo (sqlsrv, hashref, arrayref)
    SV * sqlsrv
    SV * hashref
    SV * arrayref
OUTPUT:
   hashref
   arrayref


int
nextrow (sqlsrv, hashref, arrayref)
    SV * sqlsrv
    SV * hashref
    SV * arrayref
OUTPUT:
   RETVAL
   hashref
   arrayref

void
getoutputparams (sqlsrv, hashref, arrayref)
    SV * sqlsrv
    SV * hashref
    SV * arrayref
OUTPUT:
   hashref
   arrayref


void
cancelbatch (sqlsrv)
    SV * sqlsrv
CODE:
{
    internaldata * mydata = get_internaldata(sqlsrv);
    free_batch_data(mydata);
}

void
cancelresultset (sqlsrv)
    SV * sqlsrv
CODE:
{
    internaldata * mydata = get_internaldata(sqlsrv);
    free_resultset_data(mydata);
}

int
getcmdstate (olle_ptr)
    SV * olle_ptr
CODE:
{
    typedef enum cmdstate_enum {
        cmdstate_init, cmdstate_enterexec, cmdstate_nextres, cmdstate_nextrow,
        cmdstate_getparams
    } cmdstate_enum;

    internaldata * mydata = get_internaldata(olle_ptr);

    if (mydata->pending_cmd == NULL) {
       RETVAL = cmdstate_init;
    }
    else if (mydata->cmdtext_ptr == NULL) {
       RETVAL = cmdstate_enterexec;
    }
    else if (mydata->params_available) {
       RETVAL = cmdstate_getparams;
    }
    else if (mydata->have_resultset) {
       RETVAL = cmdstate_nextrow;
    }
    else {
       RETVAL = cmdstate_nextres;
    }
}
OUTPUT:
   RETVAL

SV *
getcmdtext (olle_ptr)
    SV * olle_ptr
CODE:
{
    internaldata * mydata = get_internaldata(olle_ptr);
    if (mydata->pending_cmd != NULL) {
       RETVAL = BSTR_to_SV(mydata->pending_cmd);
    }
    else {
       RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
   RETVAL


SV *
get_sqlversion (olle_ptr) 
   SV * olle_ptr;
CODE:
{   
    // Implements FETCH for Olle->{SQL_version];
    internaldata * mydata = get_internaldata(olle_ptr);
    if (! my_sv_is_defined(mydata->SQL_version) && 
        OptAutoConnect(olle_ptr)) {
       // If value is not set, but AutoConnect is on, connect 
       // and disconnect to have it set.
       do_connect(olle_ptr, TRUE);
       disconnect(olle_ptr);
    }

    // Need to increment refcnt before return.
    if (my_sv_is_defined(mydata->SQL_version)) {
       SvREFCNT_inc(mydata->SQL_version);
    }
    RETVAL = mydata->SQL_version;
}
OUTPUT:
   RETVAL

SV *
get_currentdb (olle_ptr) 
   SV * olle_ptr;
CODE:
{   
    // Implements FETCH for Olle->{CurrentDB];
    internaldata * mydata = get_internaldata(olle_ptr);
    if (! my_sv_is_defined(mydata->CurrentDB) && 
        OptAutoConnect(olle_ptr)) {
       // If value is not set, but AutoConnect is on, connect 
       // and disconnect to have it set.
       do_connect(olle_ptr, TRUE);
       disconnect(olle_ptr);
    }

    if (my_sv_is_defined(mydata->CurrentDB)) {
       SvREFCNT_inc(mydata->CurrentDB);
    }
    RETVAL = mydata->CurrentDB;
}
OUTPUT:
   RETVAL




int
get_provider_enum(olle_ptr)
    SV * olle_ptr
CODE:
{
    // Implements FETCH for Olle->{Provider}.
    internaldata * mydata = get_internaldata(olle_ptr);
    RETVAL = mydata->provider;
}
OUTPUT:
   RETVAL

int
set_provider_enum(olle_ptr, provider)
    SV * olle_ptr
    int  provider;
CODE:
{
    // Implements STORE for Olle->{Provider}. We return -1 if connected.
    // The Perl module will do the croaking for better location of error
    // message.
    internaldata * mydata = get_internaldata(olle_ptr);
    if (mydata->datasrc_ptr != NULL) {
       RETVAL = -1;
    }
    else {
       mydata->provider = (provider_enum) provider;
       if (mydata->provider == provider_default) {
          // If the called want the default, give it to him.
          mydata->provider = default_provider();
       }
       RETVAL = mydata->provider;
    }
}
OUTPUT:
   RETVAL


int
parsename(olle_ptr, sv_namestr, retain_quotes, sv_server, sv_db, sv_schema, sv_object)
   SV * olle_ptr
   SV * sv_namestr
   int retain_quotes
   SV * sv_server
   SV * sv_db
   SV * sv_schema
   SV * sv_object

void
replaceparamholders (olle_ptr, cmdstring)
   SV * olle_ptr
   SV * cmdstring

void codepage_convert(olle_ptr, string, from_cp, to_cp)
  SV   * olle_ptr
  SV   * string
  unsigned int   from_cp
  unsigned int   to_cp

void *
OpenSqlFilestream (olle_ptr, path, access, sv_context, options=0, sv_alloclen = NULL)
   SV         * olle_ptr
   SV         * path
   int          access
   SV *         sv_context
   unsigned int options
   SV *         sv_alloclen
OUTPUT:
   RETVAL

int
SQL_FILESTREAM_OPEN_FLAG_ASYNC()
CODE:
{ RETVAL = SQL_FILESTREAM_OPEN_FLAG_ASYNC; }
OUTPUT:
   RETVAL

int
SQL_FILESTREAM_OPEN_FLAG_NO_BUFFERING()
CODE:
{ RETVAL = SQL_FILESTREAM_OPEN_FLAG_NO_BUFFERING; }
OUTPUT:
   RETVAL

int
SQL_FILESTREAM_OPEN_FLAG_NO_WRITE_THROUGH()
CODE:
{ RETVAL = SQL_FILESTREAM_OPEN_FLAG_NO_WRITE_THROUGH; }
OUTPUT:
   RETVAL

int
SQL_FILESTREAM_OPEN_FLAG_SEQUENTIAL_SCAN()
CODE:
{ RETVAL = SQL_FILESTREAM_OPEN_FLAG_SEQUENTIAL_SCAN; }
OUTPUT:
   RETVAL

int
SQL_FILESTREAM_OPEN_FLAG_RANDOM_ACCESS()
CODE:
{ RETVAL = SQL_FILESTREAM_OPEN_FLAG_RANDOM_ACCESS; }
OUTPUT:
   RETVAL

int
GetACP()
CODE:
{ RETVAL = GetACP(); }
OUTPUT:
   RETVAL


int
GetOEMCP()
CODE:
{ RETVAL = GetOEMCP(); }
OUTPUT:
   RETVAL


size_t
GetProcessWorkingSetSize()
CODE:
{
   HANDLE h = GetCurrentProcess();
   PROCESS_MEMORY_COUNTERS counters;
   GetProcessMemoryInfo(h, &counters, sizeof(PROCESS_MEMORY_COUNTERS));
   RETVAL = counters.WorkingSetSize;
}
OUTPUT:
   RETVAL

