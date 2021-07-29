/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/convenience.cpp 7     21-07-03 23:06 Sommar $

  This file holds general-purpose routines, mainly for converting
  between SV and BSTR and the like. All these are low-level, and do
  not have access to error handling. Such code should be in utils.cpp.

  Copyright (c) 2004-2021   Erland Sommarskog

  $History: convenience.cpp $
 * 
 * *****************  Version 7  *****************
 * User: Sommar       Date: 21-07-03   Time: 23:06
 * Updated in $/Perl/OlleDB
 * When converting from char to BSTR with a client codepage of UTF-8, we
 * need to consider that Perl may actually have the data in code page 1252
 * and not have the UTF8 bit set.
 * 
 * *****************  Version 6  *****************
 * User: Sommar       Date: 21-04-29   Time: 22:20
 * Updated in $/Perl/OlleDB
 * Need to pas length to BSTR_to_SV, or else embedded NUL characters in
 * varchar in sql_variant were handled incorrectly.
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:33
 * Updated in $/Perl/OlleDB
 * BSTR_to_char has been enchanced to support bstrlen and codepage. Added
 * char_tu_UTF8_SV.
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:19
 * Updated in $/Perl/OlleDB
 * Suppress warning about data truncation and other on x64.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:44
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-02-24   Time: 21:59
 * Updated in $/Perl/OlleDB
 * Added quotename().
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:40
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/

#include "CommonInclude.h"
#include "convenience.h"

// Converts a plain ANSI string to a BSTR in Unicode, using SysAllocStr. The
// caller must indicate whether the string is UTF-8 or not. (Most of the
// time we don't call this one directly.)
BSTR char_to_BSTR(char     * str,
                  STRLEN     inlen,
                  BOOL       isutf8,
                  DBLENGTH * bytelen,
                  BOOL       add_BOM)
{  int      widelen;
   int      ret;
   DWORD    err;
   BSTR     bstr;
   WCHAR  * tmp;
   UINT     decoding;
   DWORD    flags;

   if (inlen > 0) {
      // Determine the decoding. It the UTF-8 but set, it is UTF-8. If
      // the bit is not set, we assume the ANSI code page - but if that
      // page is UTF-8, we use 1252, Latin-1, as Perl may not set the
      // UTF-8 bit if you include Latin-1 charactes like \x{00F6}.
      if (isutf8) {
         decoding = CP_UTF8;
      }
      else if (GetACP() != CP_UTF8) {
         decoding = CP_ACP;
      }
      else {
         decoding = 1252;
      }

      // Flags are used by MultiByteToWideChar.
      flags = (decoding == CP_UTF8 ? 0 : MB_PRECOMPOSED);

      // Find out how long the wide string will be, by calling
      // MultiByteToWideChar without a buffer.
      widelen = MultiByteToWideChar(decoding, flags, str, (int) inlen, 
                                    NULL, 0);

      // Any BOM requires space.
      if (add_BOM) {
         widelen++;
      }

      // Allocate string.
      bstr = SysAllocStringLen(NULL, widelen);

      // Add BOM if required, add move point where to write the converted
      // data one step ahead.
      if (add_BOM) {
         bstr[0] = 0xFEFF;
         tmp = bstr + 1;
      }
      else {
         tmp = bstr;
      }

      // And now for the real thing.
      ret = MultiByteToWideChar(decoding, flags, str, (int) inlen, 
                                tmp, widelen);

      if (! ret) {
         err = GetLastError();
         croak("sv_to_bstr failed with %ld when converting string '%s' to Unicode",
                err, str);
      }
   }
   else {
      bstr = SysAllocString(L"");
      widelen = 0;
   }

   if (bytelen != NULL) {
      * bytelen = widelen * 2;
   }
   return bstr;
}

// This version is called the most often and works from an SV, a Perl string.
BSTR SV_to_BSTR (SV       * sv,
                 DBLENGTH * bytelen,
                 BOOL       add_BOM)
{  STRLEN   sv_len;
   char   * sv_text = (char *) SvPV(sv, sv_len);

   //warn("str = '%s', len = %d, utfblen = %d, utf8 = %x.\n",
   //     sv_text, sv_len, sv_len_utf8(sv), SvUTF8(sv));

   return char_to_BSTR(sv_text, sv_len, SvUTF8(sv), bytelen, add_BOM);
}


// Converts a BSTR to plain char* in some codepage, default UTF-8.
char * BSTR_to_char (BSTR     bstr,
                     int      bstrlen,
                     UINT     codepage,
                     STRLEN * retlen) {
   int    buflen = 0;
   char * retvalue = NULL;
   int    ret;

   if (bstr != NULL) {
      if (bstrlen != 0) {
         // First find out the length we need for the return value.
         buflen = WideCharToMultiByte(codepage, 0, bstr, bstrlen, NULL, 
                                      0, NULL, NULL);

         // Allocate buffer.
         New(902, retvalue, buflen + 1, char);

         // Get the goods
         ret = WideCharToMultiByte(codepage, 0, bstr, bstrlen, retvalue, 
                                   buflen, NULL, NULL);

         if (! ret) {
            int err = GetLastError();
            croak("Internal error: WideCharToMultiByte failed with %ld. Buflen was %d. bstrlen was %d. Codepage was %d.", 
                  err, buflen, bstrlen, codepage);
         }
      }
      else {
         buflen = 0;
         New(902, retvalue, buflen + 1, char);
         memcpy(retvalue, "", buflen);
      }
   }

   if (retlen != NULL) {
      (* retlen) = buflen - (bstrlen == -1 ? -1 : 0);
   }

   return retvalue;
}

// And this one takes the BSTR all the way to an SV. If bstrlen 
// is not passed, the string is assumed to be NULL-terminated.
SV * BSTR_to_SV (BSTR  bstr,
                 int   bstrlen) {
   int    buflen;
   char * tmp;
   int    ret;
   SV   * sv;

   if (bstr != NULL) {
      if (bstrlen != 0) {
         // First find out the length we need for the return value.
         buflen = WideCharToMultiByte(CP_UTF8, 0, bstr, bstrlen, NULL, 0, NULL, NULL);

         // Allocate buffer.
         New(902, tmp, buflen, char);

         // Get the goods
         ret = WideCharToMultiByte(CP_UTF8, 0, bstr, bstrlen, tmp, buflen, NULL, NULL);

         if (! ret) {
            int err = GetLastError();
            croak("Internal error: WideCharToMultiByte failed with %ld. Buflen was %d", err, buflen);
         }

         // If bstrlen was -1, then bstr is null-terminated, and so is tmp,
         // and buflen 1 too long.
         if (bstrlen == -1) {
            buflen--;
         }

         sv = newSVpvn(tmp, buflen);
         SvUTF8_on(sv);
         Safefree(tmp);
      }
      else {
         sv = newSVpvn("", 0);
      }
   }
   else {
      sv = NULL;
   }

   return sv;
}

// Converts a character string in any code page to a perl SV with
// the UTF8 bit set. If codepage is UTF8, but string is not a UTF8
// string, the ANSI code page is assumed.
SV * char_to_UTF8_SV (char    * str,
                      STRLEN    inlen,
                      UINT      codepage) {

   SV   * sv = NULL;
   BSTR bstr;
   int  widelen;
   int  ret;

   if (str == NULL) {
      return NULL;
   }

   if (inlen == 0) {
      return newSVpvn("", 0);
   }

   if (codepage == CP_UTF8) {
      if (is_utf8_string( (U8 *) str, inlen)) {
         sv = newSVpvn(str, inlen);
         SvUTF8_on(sv);
         return sv;
      }
      else {
         codepage = GetACP();
      }
   }


   // First convert to UTF-16
   widelen = MultiByteToWideChar(codepage, MB_PRECOMPOSED, str, 
                                 (int) inlen, NULL, 0);
   bstr = SysAllocStringLen(NULL, widelen);
   ret = MultiByteToWideChar(codepage, MB_PRECOMPOSED, str, (int) inlen, 
                             bstr, widelen);
   if (! ret) {
      int err = GetLastError();
      croak("MultiByteToWideChar failed with %ld when converting string '%s' to Unicode",
             err, str);
   }

   // Then convert it to UTF-8
   sv = BSTR_to_SV(bstr, SysStringLen(bstr));
   SysFreeString(bstr);

   return sv;
}

// Computes pow(10, n) using integer arithmetic.
LONG pow10(unsigned int n) {
  LONG ret = 1;
  while (n > 0) {
     ret *= 10;
     n--;
  }
  return ret;
}

// Quotestring adds [] around the string and doubles any occurrenes of ].
// The current string is deallocated and a new string created.
void quotename(BSTR &str) {
   UINT oldlen = SysStringLen(str);
   BSTR newstr = SysAllocStringLen(NULL, 2*oldlen + 2);
   UINT oldix = 0;
   UINT newix = 0;

   newstr[newix++] = L'[';
   for (oldix = 0; oldix < oldlen; oldix++) {
      WCHAR ch = str[oldix];
      newstr[newix++] = ch;
      if (ch == L']') {
         newstr[newix++] = ch;
      }
   }
   newstr[newix++] = L']';
   newstr[newix++] = L'\0';

   // Drop the old string
   SysFreeString(str);

   // And return the new.
   str = newstr;
}

// A wrapper on SvOK, which handles NULL pointers and potential "magic".
BOOL my_sv_is_defined(SV * sv) {
   if (sv == NULL) return FALSE;
   SvGETMAGIC(sv);
   return SvOK(sv);
}
