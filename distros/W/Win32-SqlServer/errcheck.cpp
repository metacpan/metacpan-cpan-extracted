/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/errcheck.cpp 6     12-09-23 22:52 Sommar $

  This file holds routines for checking for errors and reporting
  errors and messages.

  Copyright (c) 2004-2012   Erland Sommarskog

  $History: errcheck.cpp $
 * 
 * *****************  Version 6  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:52
 * Updated in $/Perl/OlleDB
 * Updated Copyright note.
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 12-08-08   Time: 23:20
 * Updated in $/Perl/OlleDB
 * Added an overload of olledb_message that accepts an SV* - good for
 * calls from Perl.
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:23
 * Updated in $/Perl/OlleDB
 * Suppress warning about data truncation on x64.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:44
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared.
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
#include "handleattributes.h"
#include "convenience.h"
#include "init.h"
#include "internaldata.h"
#include "errcheck.h"

// olle_croak calls croak, but before that it calls free_batch_data to
// release all that is allocated.
void olle_croak(SV         * olle_ptr,
                const char * msg,
                ...)
{
    va_list args;

    if (olle_ptr != NULL) {
       free_batch_data(get_internaldata(olle_ptr));
    }

    va_start(args, msg);
    vcroak(msg, &args);
    va_end(args);     // Not reached.
}

// msg_handler invokes the user-defined callback, or the default built-in one.
// Most errors comes from SQL Server, which is reflected in the interface,
// but Win32::SqlServer can use it for its own errors too.
void msg_handler (SV        *olle_ptr,
                  int        msgno,
                  int        msgstate,
                  int        severity,
                  BSTR       msgtext,
                  LPOLESTR   srvname,
                  LPOLESTR   procname,
                  ULONG      line,
                  LPOLESTR   sqlstate,
                  LPOLESTR   source,
                  ULONG      n,
                  ULONG      no_of_errs)
{
    SV *  callback = OptMsgCallback(olle_ptr);

    if (my_sv_is_defined(callback))  {  // a perl error handler has been installed */
        dSP;
        IV  retval;
        int  count;
        SV * sv_srvname;
        SV * sv_msgtext;
        SV * sv_procname;
        SV * sv_sqlstate;
        SV * sv_source;

        PUSHMARK(sp);
        ENTER;
        SAVETMPS;

        // Push a copy of the Perl ptr to the stack.
        XPUSHs(sv_mortalcopy(olle_ptr));

        XPUSHs(sv_2mortal (newSViv (msgno)));
        XPUSHs(sv_2mortal (newSViv (msgstate)));
        XPUSHs(sv_2mortal (newSViv (severity)));

        if (SysStringLen(msgtext) > 0) {
            sv_msgtext = BSTR_to_SV(msgtext);
            XPUSHs(sv_2mortal(sv_msgtext));
        }
        else
            XPUSHs(&PL_sv_undef);

        if (srvname && wcslen(srvname) > 0) {
            sv_srvname = BSTR_to_SV(srvname);
            XPUSHs(sv_2mortal(sv_srvname));
        }
        else
            XPUSHs(&PL_sv_undef);

        if (procname && wcslen(procname) > 0) {
           sv_procname = BSTR_to_SV(procname);
           XPUSHs(sv_2mortal (sv_procname));
        }
        else
            XPUSHs(&PL_sv_undef);

        XPUSHs(sv_2mortal (newSViv (line)));

        if (sqlstate && wcslen(sqlstate) > 0) {
           sv_sqlstate = BSTR_to_SV(sqlstate);
           XPUSHs(sv_2mortal(sv_sqlstate));
        }
        else
           XPUSHs(&PL_sv_undef);

        if (source && wcslen(source) > 0) {
           sv_source = BSTR_to_SV(source);
           XPUSHs(sv_2mortal(sv_source));
        }
        else
           XPUSHs(&PL_sv_undef);

        XPUSHs(sv_2mortal (newSViv (n)));
        XPUSHs(sv_2mortal (newSViv (no_of_errs)));

        PUTBACK;
        if ((count = call_sv(callback, G_SCALAR)) != 1)
            croak("A msg handler cannot return a LIST");
        SPAGAIN;
        retval = POPi;

        PUTBACK;
        FREETMPS;
        LEAVE;

        if (retval == 0) {
           olle_croak(olle_ptr, "Terminating on fatal error");
        }
    }
    else {
       // Here follows the XS message handler.

       // Only print complete infomation for errors.
       if (severity >= 11)  {
          if (source && wcslen(source) > 0) {
             char * charstr = BSTR_to_char(source);
             if (strlen(charstr) > 0)
                PerlIO_printf(PerlIO_stderr(), "Source %s\n", charstr);
             Safefree(charstr);
          }
          if (srvname && wcslen(srvname) > 0) {
             char * charstr = BSTR_to_char(srvname);
             if (strlen(charstr) > 0)
                PerlIO_printf(PerlIO_stderr(), "Server %s, ", charstr);
             Safefree(charstr);
          }
          PerlIO_printf(PerlIO_stderr(),"Msg %ld, Level %d, State %d",
                        msgno, severity, msgstate);
          if (procname && wcslen(procname) > 0) {
             char * charstr = BSTR_to_char(procname);
             if (strlen(charstr) > 0)
                PerlIO_printf(PerlIO_stderr(), ", Procedure '%s'", charstr);
             Safefree(charstr);
          }
          if (line > 0)
              PerlIO_printf(PerlIO_stderr(), ", Line %d", line);
          PerlIO_printf(PerlIO_stderr(), "\n\t");
       }

       if (SysStringLen(msgtext) > 0) {
           char *  charstr = BSTR_to_char(msgtext);
           PerlIO_printf(PerlIO_stderr(), "%s\n", charstr);
           Safefree(charstr);
       }
       else {
           PerlIO_printf(PerlIO_stderr(), "\n");
       }
    }
}

// A wrapper on msg_handler to produce a message with OlleDB as source.
// The string may have format codes for
void olledb_message (SV    * olle_ptr,
                     int     msgno,
                     int     state,
                     int     severity,
                     BSTR    msg,
                     ...)
{
   BSTR expandmsg = SysAllocStringLen(NULL, 4000);
   va_list(ap);
   va_start(ap, msg);
   _vsnwprintf_s(expandmsg, 4000, _TRUNCATE, msg, ap);
   va_end(ap);
   msg_handler(olle_ptr, msgno, state, severity, expandmsg,
               NULL, NULL, 0, NULL, L"Win32::SqlServer", 1, 1);
}

// The same with msg in 8-bit.
void olledb_message (SV          * olle_ptr,
                     int           msgno,
                     int           state,
                     int           severity,
                     const char  * msg,
                     ...)
{
   char expandmsg[4000];
   va_list(ap);
   va_start(ap, msg);
   _vsnprintf_s(expandmsg, 4000, _TRUNCATE, msg, ap);
   va_end(ap);
   BSTR  bstr_msg = SysAllocStringLen(NULL, 4000);
   _snwprintf_s(bstr_msg, 4000, _TRUNCATE, L"%S", expandmsg);
   msg_handler(olle_ptr, msgno, state, severity, bstr_msg,
               NULL, NULL, 0, NULL, L"Win32::SqlServer", 1, 1);
   SysFreeString(bstr_msg);
}

// And one with an SV, called from Perl-code. This one does not take
// format codes.
void olledb_message (SV   * olle_ptr,
                     int    msgno,
                     int    state,
                     int    severity,
                     SV   * msg)
{
   BSTR  bstr_msg = SV_to_BSTR(msg);
   msg_handler(olle_ptr, msgno, state, severity, bstr_msg,
               NULL, NULL, 0, NULL, L"Win32::SqlServer", 1, 1);
   SysFreeString(bstr_msg);
}



// Dumps the contents of error_info_obj. This is a helper to check_for_errors
// below.
static void dump_error_info(SV            * olle_ptr,
                            const char    * context,
                            const HRESULT   hresult,
                            BOOL            call_msg_handler,
                            IErrorInfo    * error_info_obj,
                            ERRORINFO     * error_info_rec)
{

   if (error_info_obj != NULL) {
      BSTR bstr_source;
      BSTR bstr_description;

      error_info_obj->GetSource(&bstr_source);
      error_info_obj->GetDescription(&bstr_description);

      if (call_msg_handler) {
         BSTR bstr_context = SysAllocStringLen(NULL, (int) strlen(context) + 1);
         BSTR hres_str = SysAllocStringLen(NULL, 11);
         wsprintf(bstr_context, L"%S", context);
         wsprintf(hres_str, L"%08x", hresult);

         msg_handler(olle_ptr, -1, 127, 16, bstr_description, NULL,
                     bstr_context, 0,
                     hres_str, bstr_source, 1, 1);

         SysFreeString(hres_str);
         SysFreeString(bstr_context);
      }
      else {
         char * source = BSTR_to_char(bstr_source);
         char * description = BSTR_to_char(bstr_description);

         warn("Source '%s' said '%s'.\n", source, description);

         Safefree(source);
         Safefree(description);
      }

      SysFreeString(bstr_source);
      SysFreeString(bstr_description);
   }

   if (error_info_rec != NULL && ! call_msg_handler) {
      LPOLESTR uni_clsid_str;
      LPOLESTR uni_iid_str;
      char    *clsid_str;
      char    *iid_str;

      // To display the GUIDs, we first we need to format them as strings,
      // but as we get UTF-16 strings we then convert to UTF-8.
      StringFromCLSID(error_info_rec->clsid, &uni_clsid_str);
      StringFromIID(error_info_rec->iid, &uni_iid_str);
      clsid_str = BSTR_to_char(uni_clsid_str);
      iid_str = BSTR_to_char(uni_iid_str);
      warn("HRESULT: %08x, Minor: %d, CLSID: %s, Interface ID: %s, DispID %ld.\n",
            error_info_rec->hrError, error_info_rec->dwMinor,
            clsid_str, iid_str, error_info_rec->dispid);
      CoTaskMemFree(uni_clsid_str);
      CoTaskMemFree(uni_iid_str);
      Safefree(clsid_str);
      Safefree(iid_str);
   }
}

// This routine checks for errors. If there are errors that comes from SQL
// Server, we call msg_handle for each message, and msg_handle may call a
// customed-installed error handler. If any erros comes from SQLOLEDB,
// we consider them programming errors, and croak. The parameters context
// and hresult are included in the croak message. The routine only checks
// whether hersult is an error in the case that GetErrorInfo does not return
// anything.
void check_for_errors(SV *          olle_ptr,
                      const char   *context,
                      const HRESULT hresult,
                      BOOL          dieonnosql)
{
   IErrorInfo*     error_info_main      = NULL;
   int             no_of_sqlerrs        = 0;
   IErrorRecords*  error_records        = NULL;
   ULONG           no_of_errs;
   LCID            our_locale = GetUserDefaultLCID();

   // The OLE DB documentation says that we should check the interface for
   // ISupportErrorInfo, before we call GetErrorInfo. However, it appears
   // that IMultipleResults does not support ISupportErrorInfo, and it is
   // here we get the SQL errors. So we approach GetErrorInfo directly.

   GetErrorInfo(0, &error_info_main);

   // Check first if got any error information.
   if (error_info_main == NULL) {
     if (FAILED(hresult)) {
        // There was no error message, but obviously things went wrong anyway.
        // There is no reason to carry on.
        olle_croak(olle_ptr,
           "Internal error: %s failed with %08x. No further error information was collected",
           context, hresult);
     }
     // It seems that everything went just fine.
     return;
   }

   // If we come here we have an error_info_main. Try to get the detail records.
   error_info_main->QueryInterface(IID_IErrorRecords,
                                   (void **) &error_records);
   if (error_records == NULL) {
   // We did not, but we some error have occurred, and we are going do die.
   // And here we don't care about dieonnosql.
      dump_error_info(olle_ptr, context, hresult, FALSE, error_info_main, NULL);
      error_info_main->Release();
      olle_croak(olle_ptr, "Internal error: %s failed with %08x", context, hresult);
   }

   // Get number of errors.
   error_records->GetRecordCount(&no_of_errs);

   // Then loop over the errors backwards. That will gives at least the
   // SQL errors in the order SQL Server produces them.
   for (ULONG n = 0; n < no_of_errs; n++) {
      ULONG errorno = no_of_errs - n - 1;
      ISQLErrorInfo*  sql_error_info  = NULL;

      // Try to get customer objects, for SQL errors and SQL Server errors.
      error_records->GetCustomErrorObject(errorno, IID_ISQLErrorInfo,
                                         (IUnknown **) &sql_error_info);

      if (sql_error_info != NULL) {
      // This is an SQL error, so we will call the message handler, and
      // we will survive the ordeal.
         LONG                  msgno;
         BSTR                  sqlstate;
         SSERRORINFO         * sserror_rec = NULL;
         OLECHAR             * sserror_strings = NULL;
         ISQLServerErrorInfo*  sqlserver_error_info = NULL;

         no_of_sqlerrs++;

         // Get SQLstate and message number and convert to char *.
         sql_error_info->GetSQLInfo(&sqlstate, &msgno);

         // Now, get the SQL Server errors.
         sql_error_info->QueryInterface(IID_ISQLServerErrorInfo,
                                       (void **) &sqlserver_error_info);

         // We're done with this object.
         sql_error_info->Release();

         // See if there is any SQL Server information. Normally there is,
         // but not if there is an SQL error detected by SQLOLEDB.
         if (sqlserver_error_info != NULL) {
            sqlserver_error_info->GetErrorInfo(&sserror_rec,
                                               &sserror_strings);
            sqlserver_error_info->Release();
         }

         if (sserror_rec != NULL) {
         // This is a regular SQL error. Call msg_handler.
            msg_handler(olle_ptr, sserror_rec->lNative,
                        sserror_rec->bState, sserror_rec->bClass,
                        sserror_rec->pwszMessage, sserror_rec->pwszServer,
                        sserror_rec->pwszProcedure, sserror_rec->wLineNumber,
                        sqlstate, NULL, n + 1, no_of_errs);

            // Clean-up time.
            OLE_malloc_ptr->Free(sserror_rec);
            OLE_malloc_ptr->Free(sserror_strings);
         }
         else {
         // An SQL error detected by SQLOLEBB.
            BSTR         source;
            BSTR         description;
            IErrorInfo*  error_info_detail    = NULL;

            error_records->GetErrorInfo(errorno, our_locale, &error_info_detail);

            if (error_info_detail != NULL) {
               error_info_detail->GetSource(&source);
               error_info_detail->GetDescription(&description);
               // Call msg_handler, providing values for missing items.
               msg_handler(olle_ptr, msgno, 1, 16, description, NULL, NULL, 0,
                           sqlstate, source, n + 1, no_of_errs);

               SysFreeString(source);
               SysFreeString(description);
               error_info_detail->Release();
            }
            else {
            // Eh? Missing locale? Whatever, don't drop it on the floor.
               BSTR msg = SysAllocString(L"Error message missing");
               BSTR source = SysAllocString(L"Win32::SqlServer");
               msg_handler(olle_ptr, msgno, 0, 16, msg, NULL, NULL, 0,
                           sqlstate, source, n + 1, no_of_errs);
               SysFreeString(msg);
               SysFreeString(source);
            }

         }
         SysFreeString(sqlstate);
      }
      else {
      // This is could be an internal error. Then again, sometimes SQLOLEDB
      // does not do better than this.
         IErrorInfo*  error_info_detail   = NULL;
         ERRORINFO    error_rec;
         error_records->GetErrorInfo(errorno, our_locale, &error_info_detail);
         error_records->GetBasicErrorInfo(errorno, &error_rec);
         dump_error_info(olle_ptr, context, hresult, ! dieonnosql,
                         error_info_detail, &error_rec);
         error_info_detail->Release();
      }
   }

   error_records->Release();
   error_info_main->Release();

   if (no_of_sqlerrs == 0 && dieonnosql) {
   // Game over
      olle_croak(olle_ptr, "Internal error: %s failed with %08X",
                 context, hresult);
   }
}

// The default version of check_for_errors that dies on all non-SQL errors.
void check_for_errors(SV *          olle_ptr,
                      const char   *context,
                      const HRESULT hresult)
{
    check_for_errors(olle_ptr, context, hresult, TRUE);
}


// This routine checks specifically for conversion errors. We look at
// return code and at DBSTATUS, but we don't try any error object. God
// knows whether IDataConvert supports that.
void check_convert_errors (char*        msg,
                           DBSTATUS     dbstatus,
                           DBBINDSTATUS bind_status,
                           HRESULT      ret)
{
   char  * bad_status;
   BOOL    has_failed = TRUE;   // We clear in case we see a good status.

   switch (dbstatus) {
      case DBSTATUS_S_TRUNCATED :    // This merits only a warning.
         warn("Truncatation occured with '%s'", msg);
         // Fall-through
      case DBSTATUS_S_OK :
         has_failed  = FALSE;
         break;

      case DBSTATUS_S_ISNULL :
      // This should have been handled elsewhere, so if it comes where its
      // an error.
         bad_status  = "DBSTATUS_S_ISNULL";
         break;

      case DBSTATUS_E_BADACCESSOR :
          switch (bind_status) {
           case DBBINDSTATUS_OK :
              bad_status  = "DBSTATUS_E_BADACCESSOR/DBBINDSTATUS_OK";
              break;
           case DBBINDSTATUS_BADORDINAL :
              bad_status  = "DBSTATUS_E_BADACCESSOR/DBBINDSTATUS_BADORDINAL";
              break;
           case DBBINDSTATUS_UNSUPPORTEDCONVERSION :
              bad_status  = "DBSTATUS_E_BADACCESSOR/DBBINDSTATUS_UNSUPPORTEDCONVERSION";
              break;
           case DBBINDSTATUS_BADBINDINFO :
              bad_status  = "DBSTATUS_E_BADACCESSOR/DBBINDSTATUS_BADBINDINFO";
              break;
           case DBBINDSTATUS_BADSTORAGEFLAGS :
              bad_status  = "DBSTATUS_E_BADACCESSOR/DBBINDSTATUS_BADSTORAGEFLAGS";
              break;
           case DBBINDSTATUS_NOINTERFACE :
              bad_status  = "DBSTATUS_E_BADACCESSOR/DBBINDSTATUS_NOINTERFACE";
              break;
           default :
              New(902, bad_status, 2000, char);
              sprintf_s(bad_status, 2000,
                        "DBSTATUS_E_BADACCESSOR/unidentified status %d", bind_status);
              break;
        }
        break;

      case DBSTATUS_E_CANTCONVERTVALUE :
          bad_status  = "DBSTATUS_E_CANTCONVERTVALUE";
          break;

      case DBSTATUS_E_CANTCREATE :
          bad_status  = "DBSTATUS_E_CANTCREATE";
          break;

      case DBSTATUS_E_DATAOVERFLOW :
          bad_status  = "DBSTATUS_E_DATAOVERFLOW";
          break;

      case DBSTATUS_E_SIGNMISMATCH :
          bad_status  = "DBSTATUS_E_SIGNMISMATCH";
          break;

      case DBSTATUS_E_UNAVAILABLE :
          bad_status  = "DBSTATUS_E_UNAVAILABLE";
          break;

      default :
          New(902, bad_status, 2000, char);
          sprintf_s(bad_status, 2000, "Unidentified status value: %d", dbstatus);
          break;
    }

    if (has_failed) {
       if (FAILED(ret))
          warn("Operation '%s' failed with return status %d", msg, ret);
       croak("Operation '%s' gave bad status '%s'", msg, bad_status);
    }

    if (FAILED(ret)) {
       croak("Operation '%s' failed with return status %d", msg, ret);
    }
}

// Overloaded version with out bind_status.
void check_convert_errors (char*        msg,
                           DBSTATUS     dbstatus,
                           HRESULT      ret)
{
    check_convert_errors(msg, dbstatus, DBBINDSTATUS_OK, ret);
}

