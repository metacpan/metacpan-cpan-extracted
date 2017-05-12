/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/filestream.cpp 2     15-05-24 21:06 Sommar $

  This file includes the support for OpenSqlFileStream.

  Copyright (c) 2004-2015   Erland Sommarskog

  $History: filestream.cpp $
 * 
 * *****************  Version 2  *****************
 * User: Sommar       Date: 15-05-24   Time: 21:06
 * Updated in $/Perl/OlleDB
 * Replaced check on _WIN64 with USE_64_BIT_INT, so that it works with
 * 64-integers on 32-bit Perl.
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:53
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


#include "CommonInclude.h"
#include "handleattributes.h"
#include "convenience.h"
#include "init.h"
#include "internaldata.h"
#include "errcheck.h"
#include "filestream.h"
#include "senddata.h"

// Function prototype for OpenSqlFilestream.
typedef HANDLE (CALLBACK * OpenSqlFilestream_type)
       (LPCWSTR, SQL_FILESTREAM_DESIRED_ACCESS, ULONG,
        LPBYTE, SSIZE_T, PLARGE_INTEGER);


void * OpenSqlFilestream (SV         * olle_ptr,
                          SV         * path,
                          int          access,
                          SV *         sv_context,
                          unsigned int options,
                          SV *         sv_alloclen)
{
   BSTR            bstr_path = SV_to_BSTR(path);
   DBLENGTH        context_len;
   BYTE          * context_ptr;
   SQL_FILESTREAM_DESIRED_ACCESS acc = (SQL_FILESTREAM_DESIRED_ACCESS) access;
   LARGE_INTEGER   alloclen = {0, 0};
   PLARGE_INTEGER  alloclen_ptr = NULL;
   int             msgno;
   internaldata  * mydata = get_internaldata(olle_ptr);
   const int       namelen = 20;
   char            sqlncli_name[namelen];

   // Set the library name.
   if (mydata->provider == provider_sqlncli11) {
      sprintf_s(sqlncli_name, namelen, "sqlncli11.dll");
   }
   else if (mydata->provider == provider_sqlncli10) {
      sprintf_s(sqlncli_name, namelen, "sqlncli10.dll");
   }
   else {
      croak("To use OpenSqlFilestream you must use the SQLNCLI10 provider or later.\n");
   }

   // Try to get the library.
   HMODULE libhandle = LoadLibraryA(sqlncli_name);
   if (libhandle == NULL) {
      msgno = GetLastError();
      olle_croak(olle_ptr, "Load of %s failed with error %d.\n", 
                 sqlncli_name, msgno);
   }

   // And then get a pointer to OpenSqlFilestream
   OpenSqlFilestream_type OpenSqlFilestream_ptr = (OpenSqlFilestream_type) 
               GetProcAddress(libhandle, "OpenSqlFilestream");
   if (OpenSqlFilestream_ptr == NULL) {
      msgno = GetLastError();
      olle_croak(olle_ptr,
            "Could not get address for OpenSqlFilestream. Error code = %d\n", 
             msgno);
   }

   // Convert the context parameter toa binary value.
   SV_to_binary(sv_context, OptBinaryAsStr(olle_ptr), FALSE, context_ptr,
                context_len);

   // Deal with the allocation length parameter.
   if (my_sv_is_defined(sv_alloclen)) {
      alloclen_ptr = &alloclen;

      if (SvROK(sv_alloclen) &&
          strncmp(SvPV_nolen(sv_alloclen), "HASH(", 5) == 0) {
         HV * hv = (HV *) SvRV(sv_alloclen);
         SV ** svp;

         svp = hv_fetch(hv, "High", 4, 0);
         if (svp != NULL && my_sv_is_defined(*svp)) {
            alloclen.HighPart = (LONG) SvUV(*svp);
         }

         svp = hv_fetch(hv, "Low", 3, 0);
         if (svp != NULL && my_sv_is_defined(*svp)) {
            alloclen.LowPart = (DWORD) SvUV(*svp);
         }
      }
      else {
#ifdef USE_64_BIT_INT
         alloclen.QuadPart = SvUV(sv_alloclen);
#else
         alloclen.HighPart = 0;
         alloclen.LowPart = SvUV(sv_alloclen);
#endif
      }
   }

   // Now we can cal OpenSqlFilestream.
   HANDLE h = (*OpenSqlFilestream_ptr)(bstr_path, acc, options, context_ptr,
                                       context_len, alloclen_ptr);
   msgno = GetLastError();

   SysFreeString(bstr_path);
   Safefree(context_ptr);

   if (h == INVALID_HANDLE_VALUE) {
      BSTR  msg = SysAllocStringLen(NULL, 200);
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, msgno, 0, msg, 200, NULL);
      for (SIZE_T ix = wcslen(msg) - 1; msg[ix] == L'\n' || msg[ix] == L'\r'; ix--) {
          msg[ix] = L'\0';
      }
      msg_handler(olle_ptr, -msgno, 1, 16, msg,
                  NULL, NULL, 0, NULL, L"OpenSqlFilestream", 1, 1);
      SysFreeString(msg);
   }

   // Free the libraru.
   FreeLibrary(libhandle);

   return h;
}

