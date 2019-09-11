/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/handleattributes.cpp 5     19-07-08 22:34 Sommar $

  This file holds routines for getting and (in one case) retrieving
  handle attributes from the Win32::SqlServer hash. Many of them are
  format options.

  Copyright (c) 2004-2019   Erland Sommarskog

  $History: handleattributes.cpp $
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:34
 * Updated in $/Perl/OlleDB
 * Move SQL_version to be in internaldata intstead. Added support for the
 * codepages hash.
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:25
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64.
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
#include "convenience.h"
#include "handleattributes.h"


// The names for all OlleDB attributes.
static char *hash_keys[] =
   { "internaldata", "PropsDebug",     "AutoConnect",    "RowsAtATime",
     "DecimalAsStr", "DatetimeOption", "TZOffset",       "BinaryAsStr",
     "DateFormat",   "MsecFormat",     "CommandTimeout", "MsgHandler",
     "QueryNotification", "SQL_version", "CurrentDB",    "codepages"};

// This enum is used to address option_hash_keys array.
typedef enum hash_key_enum
{
    HV_internaldata, HV_propsdebug,     HV_autoconnect, HV_rowsatatime,
    HV_decimalasstr, HV_datetimeoption, HV_tzoffset,    HV_binaryasstr,
    HV_dateformat,   HV_msecformat,     HV_cmdtimeout,  HV_msgcallback,
    HV_querynotification, HV_SQLversion, HV_CurrentDB,  HV_codepages
} hash_key_enum;


// Private routines for operating on the hash directly.
//---------------------------------------------------------------------
static SV **fetch_from_hash (SV* olle_ptr, hash_key_enum id) {
   HV * hv;
   hv = (HV *) SvRV(olle_ptr);
   return hv_fetch(hv, hash_keys[id], (I32) strlen(hash_keys[id]), FALSE);
}
     

static SV * fetch_option(SV * olle_ptr, hash_key_enum id) {
// Fetches an option from the hash, and only returns an SV, if there is a
// defined value.
   SV  **svp;
   SV  * retsv = NULL;
   svp = fetch_from_hash(olle_ptr, id);
   if (svp != NULL && my_sv_is_defined(*svp)) {
       retsv = *svp;
   }
   return retsv;
}


BOOL OptAutoConnect (SV * olle_ptr) {
   SV *sv;
   BOOL retval = FALSE;
   if (sv = fetch_option(olle_ptr, HV_autoconnect)) {
      retval = SvTRUE(sv);
   }
   return retval;
}

BOOL OptPropsDebug(SV * olle_ptr) {
   SV * sv;
   BOOL retval = FALSE;
   if (sv = fetch_option(olle_ptr, HV_propsdebug)) {
      retval = SvTRUE(sv);
   }
   return retval;
}

IV OptRowsAtATime(SV * olle_ptr) {
   SV * sv;
   IV retval = 100;
   if (sv = fetch_option(olle_ptr, HV_rowsatatime)) {
      retval = SvIV(sv);
      if (retval <= 0) {
          retval = 1;
      }
   }
   return retval;
}

BOOL OptDecimalAsStr(SV * olle_ptr) {
   SV * sv;
   BOOL retval = FALSE;
   if (sv = fetch_option(olle_ptr, HV_decimalasstr)) {
      retval = SvTRUE(sv);
   }
   return retval;
}

dt_options OptDatetimeOption(SV * olle_ptr) {
   SV * sv;
   dt_options retval = dto_iso;
   if (sv = fetch_option(olle_ptr, HV_datetimeoption)) {
      retval = (dt_options) SvIV(sv);
   }
   return retval;
}

tzinfo OptTZOffset(SV * olle_ptr) {
   tzinfo    tz = {FALSE, 0, 0};
   SV      * sv;

   if (sv = fetch_option(olle_ptr, HV_tzoffset)) {
      STRLEN tzlen;
      char * tzstr = SvPV(sv, tzlen);

      tz.inuse = TRUE;

      if (strcmp(tzstr, "local") == 0) {
         TIME_ZONE_INFORMATION WinTZ;
         DWORD ret = GetTimeZoneInformation(&WinTZ);
         int bias = WinTZ.Bias + (ret == TIME_ZONE_ID_STANDARD ?
                                  WinTZ.StandardBias : 0) +
                                 (ret == TIME_ZONE_ID_DAYLIGHT ?
                                  WinTZ.DaylightBias : 0);
         tz.sign   = (bias > 0 ? -1 : 1);  // Yes, that is how .Bias work.
         tz.hour   = abs(bias / 60);
         tz.minute = abs(bias % 60);
      }
      else if (tzlen == 6) {
         char s;
         int cnt = sscanf_s(tzstr, "%c%2d:%2d", &s, 1, &tz.hour, &tz.minute);
         if (cnt != 3 || ! (s == '+' || s == '-') ||
             tz.hour > 14 || tz.hour < 0 || tz.minute < 0 || tz.minute > 59) {
            croak("Illegal value for option TZOffset: '%s'", tzstr);
         }
         tz.sign = (s == '+' ? 1 : -1);
      }
      else {
         croak("Illegal value for option TZOffset: '%s'", tzstr);
      }
    }

    return tz;
}


bin_options OptBinaryAsStr(SV * olle_ptr) {
   SV * sv;
   bin_options retval = bin_binary;
   if (sv = fetch_option(olle_ptr, HV_binaryasstr)) {
      if (SvTRUE (sv)) {
         char * str = SvPV_nolen(sv);
         retval = bin_string;
         if (strcmp(str, "x") == 0) {
            retval = bin_string0x;
         }
      }
   }
   return retval;
}

char * OptDateFormat(SV * olle_ptr) {
   SV   * sv;
   char * retval = NULL;
   if (sv = fetch_option(olle_ptr, HV_dateformat)) {
      retval = SvPV_nolen(sv);
   }
   return retval;
}

char * OptMsecFormat(SV * olle_ptr) {
   SV * sv;
   char * retval = NULL;
   if (sv = fetch_option(olle_ptr, HV_msecformat)) {
      retval = SvPV_nolen(sv);
   }
   return retval;
}

SV * OptMsgCallback(SV * olle_ptr) {
    SV ** callback_ptr;
    SV * callback = NULL;
    // We must check that olle_ptr is OK, in case errors occurs at login.
    if (olle_ptr && SvOK(olle_ptr)) {
       if (callback_ptr = fetch_from_hash(olle_ptr, HV_msgcallback)) {
          callback = * callback_ptr;
       }
    }
    return callback;
}

IV OptCommandTimeout(SV * olle_ptr) {
   SV * sv;
   IV retval = 0;
   if (sv = fetch_option(olle_ptr, HV_cmdtimeout)) {
      retval = SvIV(sv);
   }
   return retval;
}

HV* OptQueryNotification(SV * olle_ptr) {
   SV * sv;
   HV * retval = NULL;
   if (sv = fetch_option(olle_ptr, HV_querynotification)) {
      retval = (HV *) SvRV(sv);
   }
   return retval;
}

HV * OptCodepagesHash(SV * olle_ptr) {
   SV * sv;
   HV * retval = NULL;
   if (sv = fetch_option(olle_ptr, HV_codepages)) {
      retval = (HV *) SvRV(sv);
   }
   return retval;
}

// Get the code page for the database in CurrentDB.
UINT OptCurrentCodepage (SV * olle_ptr) {
   SV * current_db   = fetch_option(olle_ptr, HV_CurrentDB);
   HV * codepages_hv = OptCodepagesHash(olle_ptr);
   UINT retval = 0;

   if (current_db != NULL && codepages_hv != NULL) {
      HE * he = hv_fetch_ent(codepages_hv, current_db, 0, 0);
      if (he != NULL) {
         SV * codepage_sv = HeVAL(he);
         if (codepage_sv != NULL && SvOK(codepage_sv)) {
            retval = SvUVx(codepage_sv);
         }
      }
   }

   return retval;
}

// This one returns all format options in one struct.
formatoptions getformatoptions(SV   * olle_ptr) {
   formatoptions opts;

   opts.DecimalAsStr = OptDecimalAsStr(olle_ptr);
   opts.BinaryAsStr = OptBinaryAsStr(olle_ptr);
   opts.DatetimeOption = OptDatetimeOption(olle_ptr);
   opts.TZOffset = OptTZOffset(olle_ptr);
   if (opts.DatetimeOption == dto_strfmt) {
       opts.DateFormat = OptDateFormat(olle_ptr);
       opts.MsecFormat = OptMsecFormat(olle_ptr);
   }
   else {
       opts.DateFormat = NULL;
       opts.MsecFormat = NULL;
   }

   return opts;
}

// And this returns most important attribute of them all: the pointer to
// the internal data area for the XS code. Here we return it a void pointer,
// and the internaldata module will have to reinterpret the pointer.
void * OptInternalData(SV *olle_ptr)
{
    HV *hv;
    SV **svp;
    void * internaldata;

    if(!SvROK(olle_ptr))
        croak("olle_ptr parameter is not a reference!");
    hv = (HV *)SvRV(olle_ptr);
    if(! (svp = fetch_from_hash(olle_ptr, HV_internaldata)) )
        croak("Internal error: no internaldata key in hash");
    internaldata = (void *) SvIV(*svp);
    return internaldata;
}

// Clears the codepages hash. Called when server changes.
void ClearCodepages(SV * olle_ptr) {
   HV * codepages_hv = OptCodepagesHash(olle_ptr);
   if (codepages_hv != NULL) {
      hv_clear(codepages_hv);
   }
}

