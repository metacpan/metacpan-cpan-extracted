/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/datetime.cpp 7     16-07-11 22:21 Sommar $

  All routines converting between Perl values and the datetime data types
  in SQL Server.

  Copyright (c) 2004-2016   Erland Sommarskog

  $History: datetime.cpp $
 * 
 * *****************  Version 7  *****************
 * User: Sommar       Date: 16-07-11   Time: 22:21
 * Updated in $/Perl/OlleDB
 * Use fabs rather than abs to resolve compilation error with VS2015.
 * 
 * *****************  Version 6  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:55
 * Updated in $/Perl/OlleDB
 * Cannot use abs to be 64-bit safe.
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:22
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64.
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:44
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared.
 *
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-01-06   Time: 23:33
 * Updated in $/Perl/OlleDB
 * Replaced all unsafe CRT functions with their safe replacements in VC8.
 * olledb_message now takes a va_list as argument, so we pass it
 * parameterised strings and don't have to litter the rest of the code
 * with that.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-02   Time: 22:49
 * Updated in $/Perl/OlleDB
 * Fixed memory leak.
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
#include "datetime.h"


// These hash keys are used for datetime hashes when working with the
// date/time data types.
static char *datetime_keys[] =
   {"Year", "Month", "Day", "Hour", "Minute", "Second", "Fraction",
    "TZHour", "TZMinute"};

// And here is a enum that goes with it. The is for declaring arrays only.
typedef enum datetime_key_enum
{  DT_year, DT_month, DT_day, DT_hour, DT_minute, DT_second, DT_fraction,
   DT_tzhour, DT_tzminute, no_of_datetime_keys
} datetime_key_enum;


// This is called by SV_to_datetimetypes when the value is a HASH.
static BOOL HV_to_datetimetypes (SV               * sv,
                                 DBTYPE             typeind,
                                 DBTIMESTAMPOFFSET &dtoffset,
                                 BOOL               present_keys[no_of_datetime_keys],
                                 SV               * olle_ptr)
{
   HV    * hv;

   BOOL    needsdate = (typeind != DBTYPE_DBTIME2 &&
                        typeind != DBTYPE_SQLVARIANT);
   BOOL    needstime = (typeind == DBTYPE_DBTIME2);

   typedef struct {datetime_key_enum  part;
                   BOOL               ismandatory;
                   BOOL               isshort;
                   BOOL               isunsigned;} params_struct;
   params_struct  get_hash_valueparams[no_of_datetime_keys] =
     {{DT_year,     needsdate,  TRUE,  FALSE},
      {DT_month,    needsdate,  TRUE,  TRUE},
      {DT_day,      needsdate,  TRUE,  TRUE},
      {DT_hour,     needstime,  TRUE,  TRUE},
      {DT_minute,   needstime,  TRUE,  TRUE},
      {DT_second,   FALSE,      TRUE,  TRUE},
      {DT_fraction, FALSE,      FALSE, TRUE},
      {DT_tzhour,   FALSE,      TRUE,  FALSE},
      {DT_tzminute, FALSE,      TRUE,  FALSE}};

   // Verify that the sv is really a hash reference.
   if (strncmp(SvPV_nolen(sv), "HASH(", 5) != 0)
      return FALSE;

   hv = (HV *) SvRV(sv);

   for (int ix = DT_year; ix <= DT_tzminute; ix++) {
      params_struct *p = &get_hash_valueparams[ix];
      SV   ** svp;
      SV    * sv = NULL;

      svp = hv_fetch(hv, datetime_keys[p->part],
                     (int) strlen(datetime_keys[p->part]), 0);
      if (svp != NULL)
          sv = *svp;

      present_keys[ix] = my_sv_is_defined(sv);
      if (! present_keys[ix]) {
         if (! p->ismandatory) {
            continue;
         }
         else {
            olledb_message(olle_ptr, -1, 1, 10,
                           L"Mandatory part '%S' missing from datetime hash.",
                           datetime_keys[p->part]);
            return FALSE;
         }
      }

      IV partvalue = SvIV(sv);

      if (_abs64(partvalue) > 32767 && p->isshort ||
          partvalue < 0 && p->isunsigned) {
          olledb_message(olle_ptr, -1, 1, 10,
                         L"Part '%S' in datetime hash has illegal value %d.",
                         datetime_keys[p->part], partvalue);
          return FALSE;
      }

      switch (p->part) {
         case DT_year     : dtoffset.year = (SHORT) partvalue;
                            break;
         case DT_month    : dtoffset.month = (USHORT) partvalue;
                            break;
         case DT_day      : dtoffset.day = (USHORT) partvalue;
                            break;
         case DT_hour     : dtoffset.hour = (USHORT) partvalue;
                            break;
         case DT_minute   : dtoffset.minute = (USHORT) partvalue;
                            break;
         case DT_second   : dtoffset.second = (USHORT) partvalue;
                            break;
         case DT_fraction : dtoffset.fraction = (ULONG) (SvNV(sv) * 1000000);
                            break;
         case DT_tzhour   : dtoffset.timezone_hour = (SHORT) partvalue;
                            break;

         case DT_tzminute :
         // TZ Minute without hour is not permitted.
            if (! present_keys[DT_tzhour]) {
               olledb_message(olle_ptr, -1, 1, 10,
                              "TZMinute appears in datetime hash, but TZHour is missing.");
               return FALSE;
            }
            dtoffset.timezone_minute = (SHORT) partvalue;
            break;

         default : croak("Seroius error in DT_to_datetimetypes");
      }
   }

   return TRUE;
}


// And this is another that examines the end of a string to see if there
// is a time-zone indicator. If there is, a string terminator is written
// to where the TZ indicator begins, and the string and strlen is modified.
static BOOL get_time_zone (char            * str,
                           STRLEN          &strlen,
                           DBTIMESTAMPOFFSET &dtoffset)
{
  // Which state: we can be after a delimiter, before it, or within a number
  // of digits. This controls whether space is permitted and what we are
  // looking for next.
  enum {afterdelim, indigits, beforedelim} state = afterdelim;
  enum {minute, hour} part = minute;
  int  num;
  BOOL happy_end = FALSE;


  for (size_t ix = strlen - 1; ix >= 0; ix--) {
     char ch = str[ix];
     switch (state) {
        case afterdelim :
           if (isdigit(ch)) {
              state = indigits;
              num = ch - '0';
           }
           else if (! isspace(ch)) {
              return FALSE;
           }
           break;

        case indigits :
           if (part == minute && ch == ':') {
              state = afterdelim;
              part = hour;
              dtoffset.timezone_minute = num;
           }
           else if (part == hour && (ch == '+' || ch == '-')) {
              happy_end = TRUE;
           }
           else if (isspace(ch)) {
              state = beforedelim;
           }
           else if ( isdigit(ch)) {
              num += (ch - '0') * 10;
           }
           else {
              return FALSE;
           }
           break;

        case beforedelim :
           if (part == minute && ch == ':') {
              state = afterdelim;
              part = hour;
              dtoffset.timezone_minute = num;
           }
           else if (part == hour && (ch == '+' || ch == '-')) {
              happy_end = TRUE;
           }
           else if (! isspace(ch)) {
              return FALSE;
           }
           break;
      }

      if (happy_end) {
         dtoffset.timezone_hour = num;
         if (ch == '-') {
            dtoffset.timezone_hour   *= -1;
            dtoffset.timezone_minute *= -1;
         }
         str[ix] = '\0';
         strlen = ix;
         return TRUE;
      }
  }

  return FALSE;
}


// This functions parses str under the assumption that it obeys the ISO
// format with YYYY-MM-DD or YYYYMMDD and HH:MM[:SS.ffffffff], with space
// or T between date and time. Date may also be terminated with Z. The
// function also permits for time-only strings. This function does not
// perform any validation that the numbers are valid. Two-digit years
// are not handled. The result is put into dtoffset. However, the function
// assumes that the time zone has already been extracted from the string.
static BOOL parse_iso_string(char              * str,
                             STRLEN              stringlen,
                             DBTIMESTAMPOFFSET &dtoffset) {

  enum {afterdelim, indigits, beforedelim} state = afterdelim;

  typedef struct {datetime_key_enum    part;
                  char                 delim[5];
                  int                  maxdigits;
                  BOOL                 OK_as_final;} part_struct;
  part_struct parts[no_of_datetime_keys] =
      {{DT_year,     "-:TZ",  8, FALSE},    // 8? Yes, this is for YYYYMMDD.
       {DT_month,    "-",     2, FALSE},
       {DT_day,      "TZ ",   2, TRUE},
       {DT_hour,     ":",     2, FALSE},
       {DT_minute,   ":",     2, TRUE},
       {DT_second,   ".",     2, TRUE},
       {DT_fraction, "\0",    7, TRUE},
       {DT_tzhour,   "",      0, FALSE},
       {DT_tzminute, "",      0, FALSE}};
  datetime_key_enum  part = DT_year;
  int                num = 0;
  int                no_of_digits = 0;
  BOOL               savepart = FALSE;

  for (STRLEN ix = 0; ix <= stringlen; ix++) {
     char ch = str[ix];
     if (ix < stringlen) {
        switch (state) {
           case afterdelim :
              if (isdigit(ch)) {
                 state = indigits;
                 num = ch - '0';
                 no_of_digits = 1;
              }
              else if (! isspace(ch)) {
                 return FALSE;
              }
              break;

           case indigits :
              if (strchr(parts[part].delim, ch) ||
                  part == DT_year && no_of_digits > 4 && isspace(ch)) {
                 state = afterdelim;
                 savepart = TRUE;
              }
              else if (isspace(ch)) {
                 state = beforedelim;
              }
              else if (isdigit(ch) && ++no_of_digits <= parts[part].maxdigits) {
                 num = num*10 + (ch - '0');
              }
              else {
                 return FALSE;
              }
              break;

           case beforedelim :
              if (strchr(parts[part].delim, ch)) {
                 state = afterdelim;
                 savepart = TRUE;
              }
              else if (! isspace(ch)) {
                 return FALSE;
              }
              break;
        }
     }
     else {
        savepart = TRUE;
     }

     if (savepart) {
        switch (parts[part].part) {
           case DT_year :
              if (no_of_digits == 8 &&
                  (strchr(parts[DT_day].delim, ch) || ix == stringlen)) {
                 dtoffset.year = num / 10000;
                 dtoffset.month = (num % 10000) / 100;
                 dtoffset.day = num % 100;
                 part = DT_hour;
              }
              else if (no_of_digits == 4 && ch == '-') {
                 dtoffset.year = num;
                 part = DT_month;
              }
              else if (no_of_digits <= 2 && ch == ':') {
                 dtoffset.hour = num;
                 part = DT_minute;
              }
              else {
                 return FALSE;
              }
              break;

          case DT_month :
              dtoffset.month = num;
              part = DT_day;
              break;

          case DT_day :
              dtoffset.day = num;
              part = DT_hour;
              break;

          case DT_hour :
              dtoffset.hour = num;
              part = DT_minute;
              break;

          case DT_minute :
              dtoffset.minute = num;
              part = DT_second;
              break;

          case DT_second :
              dtoffset.second = num;
              part = DT_fraction;
              break;

          case DT_fraction :
              dtoffset.fraction = num * pow10(9 - no_of_digits);
              part = DT_tzhour;
              break;

          case DT_tzhour :
          case DT_tzminute :
              return FALSE;
        }

        // If T is the day delimiter, there must be hour and seconds. But if
        // there is a Z, the string must have no more parts.
        if (ch == 'T') {
           parts[DT_day].OK_as_final = FALSE;
        }
        else if (ch == 'Z') {
           // This is tricker than it looks, because after Z we are in the
           // the state afterdelim, and normally in this state, end-of-string
           // is not permitted. So this is an ugly trick.
           sprintf_s(parts[DT_hour].delim, 1, "");
           parts[DT_hour].maxdigits = 0;
           state = beforedelim;
           parts[DT_hour].OK_as_final = TRUE;
           parts[DT_minute].OK_as_final = FALSE;
        }

        savepart = FALSE;
        num = 0;
     }
  }

  // If we came here, it's OK, if we have a good part and we are in a good
  // state. The part is the part after the last part we found.
  return ((state == indigits || state == beforedelim) &&
           parts[part-1].OK_as_final);
}

// Converts an SV that is known to be a string to DBTIMESTAMPOFFSET, which is
// a catch-all for all datetime data types.
static BOOL SVstr_to_datetimetypes (SV                * sv,
                                    DBTYPE             typeind,
                                    DBTIMESTAMPOFFSET &dtoffset,
                                    BOOL              &hastz)
{
   STRLEN    orglen;
   char    * orgstr = SvPV(sv, orglen);
   char    * copystr;
   STRLEN    copylen;
   BSTR      bstr;
   DBLENGTH  bstrlen;
   DATE      dateval;
   HRESULT   ret;

   // We work with a copy of the perl string, because we do weed out the
   // time-zone we need to mainpulate the string, and we don't want to
   // change the callers value.
   New(902, copystr, orglen + 1, char);
   memcpy(copystr, orgstr, orglen + 1);
   copylen = orglen;

   // See if there is an time-zone indicator at the end of the string.
   // if get_time_zone finds one, it will update the string and the
   // string length, to get the time zone out of the equation.
   hastz = get_time_zone (copystr, copylen, dtoffset);

   // Parse the string for ISO format, and be content if it fits.
   if (parse_iso_string(copystr, copylen, dtoffset)) {
      Safefree(copystr);
      return TRUE;
   }

   // ISO did not work out and we will try regional format. This requires
   // a BSTR.
   bstr = char_to_BSTR(copystr, copylen, TRUE, &bstrlen);
   Safefree(copystr);   // Not needed any more.

   // We use VarDateFromStr rather than IDataConvert, as IDataConvert tends
   // to accept junk at the end of the string. This is bad if the user have
   // an incorrectly formated TZ-offset. This gives a float vbalue.
   ret = VarDateFromStr(bstr, NULL, NULL, &dateval);

   SysFreeString(bstr);

   // If that failed, we have to give up.
   if (FAILED(ret))
      return FALSE;

   // Step 2, convert the float value to DBTYPE_DBTIMESTAMP.
   ret = data_convert_ptr->DataConvert(
         DBTYPE_DATE, DBTYPE_DBTIMESTAMP, sizeof(DATE), NULL,
         &dateval, &dtoffset, NULL, DBSTATUS_S_OK, NULL,
         NULL, NULL, 0);

   return SUCCEEDED(ret);
}

static DBTIMESTAMPOFFSET default_dtoffset(void) {
   DBTIMESTAMPOFFSET dtoffset;
   dtoffset.year            = 1899;
   dtoffset.month           = 12;
   dtoffset.day             = 30;
   dtoffset.hour            = 0;
   dtoffset.minute          = 0;
   dtoffset.second          = 0;
   dtoffset.fraction        = 0;
   dtoffset.timezone_hour   = 0;
   dtoffset.timezone_minute = 0;
   return dtoffset;
}

static BOOL illegal_dateval(datetime_key_enum   part,
                            int                 value,
                            int                 minval,
                            int                 maxval,
                            SV                * olle_ptr)
{
   if (value < minval || value > maxval) {
      olledb_message(olle_ptr, -1, 1, 10,
                     L"Part '%S' in datetime value has illegal value %d.",
                      datetime_keys[part], value);
      return TRUE;
   }
   else {
      return FALSE;
   }
}

//  This helper routine is used to validate data in a datetimeoffet record.
static BOOL validate_dtoffset(DBTIMESTAMPOFFSET &dtoffset,
                              SV               * olle_ptr,
                              int                firstyear,
                              int                lastyear,
                              BYTE               scale)
{
   if (illegal_dateval(DT_year, dtoffset.year, firstyear, lastyear, olle_ptr))
       return FALSE;

   if (illegal_dateval(DT_month, dtoffset.month, 1, 12, olle_ptr))
       return FALSE;

   int lastday = 31;
   switch (dtoffset.month) {
      case 1  :
      case 3  :
      case 5  :
      case 7  :
      case 8  :
      case 10 :
      case 12 :
         lastday = 31;
         break;

      case 4 :
      case 6 :
      case 9 :
      case 11 :
         lastday = 30;
         break;

      case 2 :
         // Yes, we ignore that some whole centuries are not leap years.
         // We are after all only trying to avoid un ugly error message.
         lastday = (dtoffset.year % 4 == 0 ? 29 : 28);
         break;
   }
   if (illegal_dateval(DT_day, dtoffset.day, 1, lastday, olle_ptr))
       return FALSE;

   if (illegal_dateval(DT_hour, dtoffset.hour, 0, 23, olle_ptr))
       return FALSE;

   if (illegal_dateval(DT_minute, dtoffset.minute, 0, 59, olle_ptr))
       return FALSE;

   if (illegal_dateval(DT_second, dtoffset.second, 0, 59, olle_ptr))
       return FALSE;

   if (illegal_dateval(DT_fraction, dtoffset.fraction, 0, 999999999, olle_ptr))
       return FALSE;

   // OLE DB does not like if there are two decimals. We are more permissive
   // and don't flag this as an error, but truncate instead.
   if (scale == 0) {
      dtoffset.fraction = 0;
   }
   else {
      LONG factor = pow10(7 - scale + 2);
      dtoffset.fraction = (dtoffset.fraction / factor) * factor;
   }

   if (illegal_dateval(DT_tzhour, dtoffset.timezone_hour, -14, 14, olle_ptr))
       return FALSE;

   int firstval = (dtoffset.timezone_hour <= 0 ? -59 : 0);
   int lastval  = (dtoffset.timezone_hour >= 0 ?  59 : 0);
   if (illegal_dateval(DT_tzminute, dtoffset.timezone_minute,
                       firstval, lastval, olle_ptr))
       return FALSE;

   // If we come here, all is OK.
   return TRUE;
}


// This is a generic function that handle all that is common to the datetime
// types. The value is returned in a DBTIMESTAMPOFFSET struct, since this struct
// covers all types.
static BOOL SV_to_datetimetypes (SV                * sv,
                                 DBTYPE             typeind,
                                 BYTE               scale,
                                 DBTIMESTAMPOFFSET &dtoffset,
                                 BOOL              &hastz,
                                 SV               * olle_ptr,
                                 int                firstyear = 1,
                                 int                lastyear = 9999)
{
   // Assume that no time-zone has been given, no matter the type.
   hastz = FALSE;

   // Set defaults
   dtoffset = default_dtoffset();

   if (SvROK(sv)) {
      BOOL    ispresent[no_of_datetime_keys];

      // Fork of HV_to_datetimetypes to crack the supposed hash.
      if (! HV_to_datetimetypes(sv, typeind, dtoffset, ispresent, olle_ptr)) {
         return FALSE;
      }

      hastz = ispresent[DT_tzhour];
   }
   else if (SvNOK(sv) || SvIOK(sv)) {
      // A float value. This is easy. Just convert to DBTIMESTAMP and smile.
      DATE           dateval = SvNV(sv);
      HRESULT        ret;

      ret = data_convert_ptr->DataConvert(
            DBTYPE_DATE, DBTYPE_DBTIMESTAMP, sizeof(DATE),
            NULL, &dateval, &dtoffset, NULL, DBSTATUS_S_OK, NULL,
            NULL, NULL, 0);

      if (FAILED(ret)) return FALSE;
   }
   else {
      // Looks like it is a string. At least we treat it as such.
      if (! SVstr_to_datetimetypes(sv, typeind, dtoffset, hastz)) {
         return FALSE;
      }
   }

   // We need to validate the values in dtoffset. Well, actually we don't,
   // because OLE DB is going to yell on illegal values. But it will not
   // tell us what is wrong, or even which parameter. So let's test ourselves.
   return validate_dtoffset(dtoffset, olle_ptr,  firstyear, lastyear, scale);
}

BOOL SV_to_date (SV           * sv,
                 DBDATE        &date,
                 SV           * olle_ptr)
{
   DBTIMESTAMPOFFSET  dtoffset;
   BOOL               hastz;
   BOOL               ret;

   ret = SV_to_datetimetypes(sv, DBTYPE_DBDATE, 0, dtoffset, hastz, olle_ptr);
   date.year  = dtoffset.year;
   date.month = dtoffset.month;
   date.day   = dtoffset.day;
   return ret;
}

BOOL SV_to_time (SV      * sv,
                 BYTE      scale,
                 DBTIME2  &time,
                 SV      * olle_ptr)
{
   DBTIMESTAMPOFFSET  dtoffset;
   BOOL               hastz;
   BOOL               ret;

   ret = SV_to_datetimetypes(sv, DBTYPE_DBTIME2, scale, dtoffset, hastz, olle_ptr);

   time.hour     = dtoffset.hour;
   time.minute   = dtoffset.minute;
   time.second   = dtoffset.second;
   time.fraction = dtoffset.fraction;
   return ret;
}


BOOL SV_to_datetime(SV        * sv,
                    BYTE        scale,
                    DBTIMESTAMP &datetime,
                    SV       *   olle_ptr,
                    int          firstyear,
                    int          lastyear)
{
   DBTIMESTAMPOFFSET  dtoffset;
   BOOL               hastz;
   BOOL               ret;

   ret = SV_to_datetimetypes(sv, DBTYPE_DBTIMESTAMP, scale,
                             dtoffset, hastz, olle_ptr, firstyear, lastyear);
   datetime.year     = dtoffset.year;
   datetime.month    = dtoffset.month;
   datetime.day      = dtoffset.day;
   datetime.hour     = dtoffset.hour;
   datetime.minute   = dtoffset.minute;
   datetime.second   = dtoffset.second;
   datetime.fraction = dtoffset.fraction;
   return ret;
}

BOOL SV_to_datetimeoffset(SV                * sv,
                          BYTE                scale,
                          tzinfo              TZOffset,
                          DBTIMESTAMPOFFSET &dtoffset,
                          SV                * olle_ptr)
{
   BOOL               hastz;
   BOOL               ret;

   ret = SV_to_datetimetypes(sv, DBTYPE_DBTIMESTAMPOFFSET, scale,
                             dtoffset, hastz, olle_ptr);

   // If there is no timezone in the value, get it from TZOffset.
   if (! hastz) {
      if (TZOffset.inuse) {
         dtoffset.timezone_hour   = TZOffset.sign * TZOffset.hour;
         dtoffset.timezone_minute = TZOffset.sign * TZOffset.minute;
      }
      else {
         // Go for UTC.
         dtoffset.timezone_hour = 0;
         dtoffset.timezone_minute = 0;
      }
   }

   return ret;
}

// This routine is called from SV_to_ssvariant to see if the SV may be a
// datetime hash. It returns false, if it looks close enough but is in
// error. But if the hash is something completely different we return TRUE,
// but don't set the variant.
BOOL SV_to_ssvariant_datetime(SV          * sv,
                              SSVARIANT     &variant,
                              SV          * olle_ptr,
                              provider_enum provider)
{
   // Get the value as a DBTIMESTAMPOFFSET, and which fields that actually was there.
   DBTIMESTAMPOFFSET dtoffset = default_dtoffset();
   BOOL              ispresent[no_of_datetime_keys];

   if (HV_to_datetimetypes(sv, DBTYPE_SQLVARIANT, dtoffset, ispresent,
                           olle_ptr)) {
      if (provider >= provider_sqlncli10 && OptSqlVersion(olle_ptr) >= 10) {
      // If we have SQL 2008 and SQL Native Client 10, then we have the
      // full range of data types available.
         if (! validate_dtoffset(dtoffset, olle_ptr, 1, 9999, 7)) {
            return FALSE;
         }

         if (ispresent[DT_year] && ispresent[DT_month] && ispresent[DT_day]) {
             if (ispresent[DT_tzhour]) {
                variant.vt = VT_SS_DATETIMEOFFSET;
                variant.DateTimeOffsetVal.tsoDateTimeOffsetVal = dtoffset;
                variant.DateTimeOffsetVal.bScale = 7;
             }
             else if (ispresent[DT_hour] || ispresent[DT_minute] ||
                      ispresent[DT_second] || ispresent[DT_fraction]) {
                variant.vt = VT_SS_DATETIME2;
                variant.DateTimeVal.tsDateTimeVal.year = dtoffset.year;
                variant.DateTimeVal.tsDateTimeVal.month = dtoffset.month;
                variant.DateTimeVal.tsDateTimeVal.day = dtoffset.day;
                variant.DateTimeVal.tsDateTimeVal.hour = dtoffset.hour;
                variant.DateTimeVal.tsDateTimeVal.minute = dtoffset.minute;
                variant.DateTimeVal.tsDateTimeVal.second = dtoffset.second;
                variant.DateTimeVal.tsDateTimeVal.fraction = dtoffset.fraction;
                variant.DateTimeVal.bScale = 7;
            }
            else {
                variant.vt = VT_SS_DATE;
                variant.dDateVal.year  = dtoffset.year;
                variant.dDateVal.month = dtoffset.month;
                variant.dDateVal.day   = dtoffset.day;
            }
         }
         else if (ispresent[DT_hour] && ispresent[DT_minute] &&
                  ! ispresent[DT_year] &&  ! ispresent[DT_month] &&
                  ! ispresent[DT_day]) {
             variant.vt = VT_SS_TIME2;
             variant.Time2Val.tTime2Val.hour     = dtoffset.hour;
             variant.Time2Val.tTime2Val.minute   = dtoffset.minute;
             variant.Time2Val.tTime2Val.second   = dtoffset.second;
             variant.Time2Val.tTime2Val.fraction = dtoffset.fraction;
             variant.Time2Val.bScale = 7;
         }
      }
      else {
         // Legacy provider or an earlier version of SQL Server. Only
         // datetime supported.
         if (ispresent[DT_year] && ispresent[DT_month] && ispresent[DT_day]) {
            if (! validate_dtoffset(dtoffset, olle_ptr, 1753, 9999, 3)) {
               return FALSE;
            }

            variant.vt = VT_SS_DATETIME;
            variant.tsDateTimeVal.year = dtoffset.year;
            variant.tsDateTimeVal.month = dtoffset.month;
            variant.tsDateTimeVal.day = dtoffset.day;
            variant.tsDateTimeVal.hour = dtoffset.hour;
            variant.tsDateTimeVal.minute = dtoffset.minute;
            variant.tsDateTimeVal.second = dtoffset.second;
            variant.tsDateTimeVal.fraction = dtoffset.fraction;
         }
      }
   }

   return TRUE;
}


//---------------------------------------------------------------------
// Here follows routines for converting datetime values from SQL Server
// to SV.s.
//---------------------------------------------------------------------

static SV * datetimetypes_to_SV (SV               * olle_ptr,
                                 DBTIMESTAMPOFFSET datetime,
                                 DBTYPE            datatype,
                                 formatoptions     opts,
                                 BYTE              precision,
                                 BYTE              scale)
{
// This routine handles all datetime data types: date, time, datetime(2)
// and datetimeoffset. The value is passed as DBTIMESTAMPOFFSET, as this
// type as all fields used by the other types.

   SV   * perl_value;

   // IDataConvert does not support the SQL Server-specific DBTYPE_DBTIME2 and
   // DBTYPE_DBTIMESTAMPOFFSET, so we need to use DBTIMEOFFSET for these.
   DBTYPE typeind  = (datatype == DBTYPE_DATE ? datatype : DBTYPE_DBTIMESTAMP);
   int    typesize = (datatype == DBTYPE_DATE ? sizeof(DBDATE)
                                              : sizeof(DBTIMESTAMP));

   // Because of the type issue, we need to modify the precision to work with
   // time and datetimeoffset.
   if (datatype == DBTYPE_DBTIME2) {
      precision += 11;
   }
   else if (datatype == DBTYPE_DBTIMESTAMPOFFSET) {
      precision -= 7;
   }

   // For dates there is a multitude of options.
   switch (opts.DatetimeOption) {
      case dto_hash : {
            HV * hv = newHV();

            if (datatype != DBTYPE_DBTIME2) {
               SV * year  = newSViv(datetime.year);
               SV * month = newSViv(datetime.month);
               SV * day   = newSViv(datetime.day);
               hv_store(hv, datetime_keys[DT_year],
                            (I32) strlen(datetime_keys[DT_year]), year, 0);
               hv_store(hv, datetime_keys[DT_month],
                            (I32) strlen(datetime_keys[DT_month]), month, 0);
               hv_store(hv, datetime_keys[DT_day],
                            (I32) strlen(datetime_keys[DT_day]), day, 0);
            }

            if (datatype != DBTYPE_DBDATE) {
               SV * hour = newSViv(datetime.hour);
               SV * minute = newSViv(datetime.minute);
               SV * second = newSViv(datetime.second);
               SV * fraction = newSVnv(datetime.fraction / 1000000.0);
               hv_store(hv, datetime_keys[DT_hour],
                            (I32) strlen(datetime_keys[DT_hour]),     hour, 0);
               hv_store(hv, datetime_keys[DT_minute],
                            (I32) strlen(datetime_keys[DT_minute]),   minute, 0);
               hv_store(hv, datetime_keys[DT_second],
                            (I32) strlen(datetime_keys[DT_second]),   second, 0);
               hv_store(hv, datetime_keys[DT_fraction],
                            (I32) strlen(datetime_keys[DT_fraction]), fraction, 0);
            }

            if (datatype == DBTYPE_DBTIMESTAMPOFFSET) {
               SV * TZhour   = newSViv(datetime.timezone_hour);
               SV * TZminute = newSViv(datetime.timezone_minute);
               hv_store(hv, datetime_keys[DT_tzhour],
                            (I32) strlen(datetime_keys[DT_tzhour]), TZhour, 0);
               hv_store(hv, datetime_keys[DT_tzminute],
                            (I32) strlen(datetime_keys[DT_tzminute]), TZminute, 0);
            }

            perl_value = newSV(NULL);
            sv_setsv(perl_value, sv_2mortal(newRV_noinc((SV *) hv)));
         }
         break;

      case dto_iso : {
            DBLENGTH       strlen;
            char           str[35];
            DBSTATUS       strstatus;
            HRESULT        ret;

            ret = data_convert_ptr->DataConvert(
                  typeind, DBTYPE_STR, typesize, &strlen, &datetime,
                  &str, 35, DBSTATUS_S_OK, &strstatus, precision, scale, 0);
            check_convert_errors("Convert datetime-to-str", strstatus, ret);

            // DataConvert does not fill in msecs if they are zero.
            if (precision > 19 && strlen == 19) {
               sprintf_s(&str[19], 15, ".0000000");
            }

            // Post-manipulate the string for time and timeoffset.
            if (datatype == DBTYPE_DBTIME2) {
               perl_value = newSVpvn(&str[11], precision - 11);
            }
            else if (datatype == DBTYPE_DBTIMESTAMPOFFSET) {
               sprintf_s(&str[precision], 35 - precision, " %+2.2d:%2.2d",
                       datetime.timezone_hour, abs(datetime.timezone_minute));
               perl_value = newSVpvn(str, precision + 7);
            }
            else {
               perl_value = newSVpvn(str, precision);
            }
         }
         break;

      case dto_regional : {
            // This conversion requires a double conversion. First to DATE.
            // and then to string.
            DATE           dateval;
            BSTR           bstr;
            DBSTATUS       dbstatus;
            HRESULT        ret;
            DWORD          bstr_flags;

            ret = data_convert_ptr->DataConvert(
                  typeind, DBTYPE_DATE, typesize, NULL, &datetime,
                  &dateval, sizeof(DATE), DBSTATUS_S_OK, &dbstatus,
                  precision, scale, 0);
            check_convert_errors("Convert datetime-to-date", dbstatus, ret);

            if (datatype == DBTYPE_DBDATE) {
               bstr_flags = VAR_DATEVALUEONLY;
            }
            else if (datatype == DBTYPE_DBTIME2) {
               bstr_flags = VAR_TIMEVALUEONLY;
            }
            else {
               bstr_flags = 0;
            }

            ret = VarBstrFromDate(dateval, 0, bstr_flags, &bstr);
            check_convert_errors("Convert date-to-str", dbstatus, ret);

            perl_value = BSTR_to_SV(bstr);
            SysFreeString(bstr);

            // For a datetimeoffset value, we should add the timezone.
            if (datatype == DBTYPE_DBTIMESTAMPOFFSET) {
               STRLEN strlen = SvCUR(perl_value);
               char *str = SvGROW(perl_value, strlen + 10);
               SvCUR_set(perl_value, strlen + 7);
               sprintf_s(&str[strlen], 10, " %+2.2d:%2.2d",
                         datetime.timezone_hour, abs(datetime.timezone_minute));
            }
         }
         break;

      case dto_float : {
            DATE           dateval;
            DBSTATUS       dbstatus;
            HRESULT        ret;

            ret = data_convert_ptr->DataConvert(
                  typeind, DBTYPE_DATE, typesize, NULL, &datetime,
                  &dateval, sizeof(DATE), DBSTATUS_S_OK, &dbstatus,
                  NULL, NULL, 0);
            check_convert_errors("Convert datetime-to-date", dbstatus, ret);

            // For time the date sent into us was 1900-01-01, which gives
            // value between 2 and 3, since OLE DB day 0 is 1899-12-30.
            if (datatype == DBTYPE_DBTIME2) {
               dateval -= 2;
            }

            perl_value = newSVnv(dateval);
        }
        break;

      case dto_strfmt : {
      // For this format, there is no special handling for time or datetimeoffset
            struct tm tm_date;
            size_t     len;
            size_t     msec_len = 0;
            char       str[256];

            if (opts.DateFormat == NULL || ! *opts.DateFormat) {
               olle_croak(olle_ptr, "Datetime option set to dt_strfmt, but there is no format defined");
            }

            // Move over data to the tm_struct.
            tm_date.tm_hour  = datetime.hour;
            tm_date.tm_isdst = 0; // Seriously, we don't know.
            tm_date.tm_mday  = datetime.day;
            tm_date.tm_min   = datetime.minute;
            tm_date.tm_mon   = datetime.month - 1;
            tm_date.tm_sec   = datetime.second;
            tm_date.tm_wday  = 0;
            tm_date.tm_yday  = 0;
            tm_date.tm_year  = datetime.year - 1900;

            // Convert the beast
            len = strftime(str, 256, opts.DateFormat, &tm_date);
            if (len <= 0) {
               olle_croak(olle_ptr, "strftime failed for dateFormat '%s'", opts.DateFormat);
            }

            // Are we also requested to format milliseconds?
            if (scale > 0 && opts.MsecFormat && * opts.MsecFormat) {
               msec_len = _snprintf_s(&str[len], 256 - len, _TRUNCATE,
                                      opts.MsecFormat,
                                      datetime.fraction / 1000000);
               if (msec_len <= 0) {
                  olle_croak(olle_ptr, "sprintf_s failed for msecFormat '%s'", opts.MsecFormat);
               }
            }

            perl_value = newSVpv(str, len + msec_len);
         }
         break;

      default :
         olle_croak(olle_ptr, "Illegal value for DatetimeOption %d", opts.DatetimeOption);

   }

   return perl_value;
}

SV * date_to_SV (SV          * olle_ptr,
                 DBDATE       dateval,
                 formatoptions opts)
{
  DBTIMESTAMPOFFSET dtoffset = {1900,1,1,0,0,0,0,0,0};

  dtoffset.year   = dateval.year;
  dtoffset.month  = dateval.month;
  dtoffset.day    = dateval.day;

  return datetimetypes_to_SV(olle_ptr, dtoffset, DBTYPE_DBDATE,
                             opts, 10, 0);
}


SV * time_to_SV (SV          * olle_ptr,
                 DBTIME2       timeval,
                 formatoptions opts,
                 BYTE          precision,
                 BYTE          scale)
{
  DBTIMESTAMPOFFSET dtoffset = {1900,1,1,0,0,0,0,0,0};

  dtoffset.hour      = timeval.hour;
  dtoffset.minute    = timeval.minute;
  dtoffset.second    = timeval.second;
  dtoffset.fraction  = timeval.fraction;

  return datetimetypes_to_SV(olle_ptr, dtoffset, DBTYPE_DBTIME2,
                             opts, precision, scale);
}

SV * datetime_to_SV (SV             * olle_ptr,
                     DBTIMESTAMP      datetime,
                     formatoptions    opts,
                     BYTE             precision,
                     BYTE             scale)
{
  DBTIMESTAMPOFFSET dtoffset = {1900,1,1,0,0,0,0,0,0};

  dtoffset.year      = datetime.year;
  dtoffset.month     = datetime.month;
  dtoffset.day       = datetime.day;
  dtoffset.hour      = datetime.hour;
  dtoffset.minute    = datetime.minute;
  dtoffset.second    = datetime.second;
  dtoffset.fraction  = datetime.fraction;

  return datetimetypes_to_SV(olle_ptr, dtoffset, DBTYPE_DBTIMESTAMP,
                             opts, precision, scale);
}

SV * datetimeoffset_to_SV (SV                   * olle_ptr,
                           DBTIMESTAMPOFFSET      dtoffset,
                           formatoptions          opts,
                           BYTE                   precision,
                           BYTE                   scale)
{
  if (! opts.TZOffset.inuse) {
     // Simple, just pass the bucket.
     return datetimetypes_to_SV(olle_ptr, dtoffset, DBTYPE_DBTIMESTAMPOFFSET,
                                opts, precision, scale);
  }
  else {
     // If TZOffset is set, then we modify the value, and pretend that we got
     // a datetime2 value.
     DBTIMESTAMP valuecopy;
     DBTIMESTAMP tzvalue;
     DBTIMESTAMP tzoption;
     int         tzvaluesign;
     DATE        valuefloat;
     DATE        valuetzfloat;
     DATE        optionfloat;
     HRESULT     ret;
     DBSTATUS    dbstatus;

     // Copy the value from SQL Server, but skip seconds and fractions.
     valuecopy.year     = dtoffset.year;
     valuecopy.month    = dtoffset.month;
     valuecopy.day      = dtoffset.day;
     valuecopy.hour     = dtoffset.hour;
     valuecopy.minute   = dtoffset.minute;
     valuecopy.second   = 0;
     valuecopy.fraction = 0;

     // And get the time-zone offset into separate DBTIMESTAMP value with
     // with OLE DB's zero date. We need to store the sign of the time zone
     // separately.
     tzvalue.year     = 1899;
     tzvalue.month    = 12;
     tzvalue.day      = 30;
     tzvalue.hour     = abs(dtoffset.timezone_hour);
     tzvalue.minute   = abs(dtoffset.timezone_minute);
     tzvalue.second   = 0;
     tzvalue.fraction = 0;
     tzvaluesign = (dtoffset.timezone_hour < 0 ||
                    dtoffset.timezone_minute < 0) ? -1 : 1;

     // And the same for the TZOption, but here the sign is already separated
     // for us.
     tzoption.year      = 1899;
     tzoption.month     = 12;
     tzoption.day       = 30;
     tzoption.hour      = opts.TZOffset.hour;
     tzoption.minute    = opts.TZOffset.minute;
     tzoption.second    = 0;
     tzoption.fraction  = 0;

     // Now we convert these three to float.
     ret = data_convert_ptr->DataConvert(
              DBTYPE_DBTIMESTAMP, DBTYPE_DATE, sizeof(DBTIMESTAMP), NULL,
              &valuecopy, &valuefloat, sizeof(DATE), DBSTATUS_S_OK,
              &dbstatus, NULL, NULL, 0);
     check_convert_errors("Convert datetimeoffset-to-date", dbstatus, ret);

     ret = data_convert_ptr->DataConvert(
              DBTYPE_DBTIMESTAMP, DBTYPE_DATE, sizeof(DBTIMESTAMP), NULL,
              &tzvalue, &valuetzfloat, sizeof(DATE), DBSTATUS_S_OK,
              &dbstatus, NULL, NULL, 0);
     check_convert_errors("Convert time zone to date", dbstatus, ret);

     ret = data_convert_ptr->DataConvert(
              DBTYPE_DBTIMESTAMP, DBTYPE_DATE, sizeof(DBTIMESTAMP), NULL,
              &tzoption, &optionfloat, sizeof(DATE), DBSTATUS_S_OK,
              &dbstatus, NULL, NULL, 0);
     check_convert_errors("Convert TZOption to date", dbstatus, ret);

     // Compute the time in the requesed time-zone. This is messier than it
     // looks like because the DATE data type is discontinuous before
     // 1899-12-30, so that -2.25 is 1899-12-28 06:00, and not 18:00.
     // newtime is the new time portdion.
     DATE newtime = fabs(valuefloat) - floor(fabs(valuefloat)) -
                    tzvaluesign * valuetzfloat +
                    opts.TZOffset.sign * optionfloat;

     // If newtime is not in [0,1[, we need to modify valuefloat with the
     // integer part, with special consideration around 1899-12-30, as
     // 0.24 = -0.24 in this context.
     if (valuefloat >= 0 && valuefloat + floor(newtime) < 0) {
        valuefloat += floor(newtime) - 1;
     }
     else if (valuefloat < 0 && valuefloat + floor(newtime) >= 0) {
        valuefloat += floor(newtime) + 1;
     }
     else {
        valuefloat += floor(newtime);
     }

     // Remove integer part from newtime.
     newtime = newtime - floor(newtime);

     // And add newtime to the integer part of valuefloat.
     if (valuefloat >= 0) {
        valuefloat = floor(valuefloat) + newtime;
     }
     else {
        valuefloat = ceil(valuefloat) - newtime;
     }

     // And convert back to DBTIMESTAMP
     ret = data_convert_ptr->DataConvert(
              DBTYPE_DATE, DBTYPE_DBTIMESTAMP, sizeof(DATE), NULL,
              &valuefloat, &valuecopy, sizeof(DBTIMESTAMP), DBSTATUS_S_OK,
              &dbstatus, NULL, NULL, 0);
     check_convert_errors("Convert valuecopy to DBTIMESTAMP ", dbstatus, ret);

     // And update the value with the fields that might have change.d
     dtoffset.year   = valuecopy.year;
     dtoffset.month  = valuecopy.month;
     dtoffset.day    = valuecopy.day;
     dtoffset.hour   = valuecopy.hour;
     dtoffset.minute = valuecopy.minute;

     // And so call datetimetypes_to_SV for the real conversion, but
     // pretent that we have a datetime2 value.
     return datetimetypes_to_SV(olle_ptr, dtoffset, DBTYPE_DBTIMESTAMP,
                                opts, precision - 7, scale - 7);
  }
}
