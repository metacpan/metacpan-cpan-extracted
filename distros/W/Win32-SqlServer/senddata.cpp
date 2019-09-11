/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/senddata.cpp 21    19-07-09 16:53 Sommar $

  Implements the routines for sending data and command to SQL Server:
  initbatch, enterparameter and executebatch, including routines to
  convert from Perl variables to SQL Server data types, save datetime
  data; those are in datetime.cpp.

  Copyright (c) 2004-2019   Erland Sommarskog

  $History: senddata.cpp $
 * 
 * *****************  Version 21  *****************
 * User: Sommar       Date: 19-07-09   Time: 16:53
 * Updated in $/Perl/OlleDB
 * Fixed type errors in 32-bit compile.
 * 
 * *****************  Version 20  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:42
 * Updated in $/Perl/OlleDB
 * To support UTF-8 collations (and other collations not in the ANSI code
 * page), we always convert to the database collation and assume that
 * AutoTranslate is off. initbatch now makes an explicit callback to the
 * Perl code to get the codepage, whereas SQL Version (and current
 * database) are retrieved from the init object.
 * 
 * *****************  Version 19  *****************
 * User: Sommar       Date: 16-07-17   Time: 22:58
 * Updated in $/Perl/OlleDB
 * Check explicitly for scanret = 1, since it can return -1 as well, which
 * is not any form of success.
 * 
 * *****************  Version 18  *****************
 * User: Sommar       Date: 16-07-12   Time: 19:28
 * Updated in $/Perl/OlleDB
 * Bugfix: conversion of string to bigint could incorrectly be taken as
 * failed.
 * 
 * *****************  Version 17  *****************
 * User: Sommar       Date: 16-07-11   Time: 22:23
 * Updated in $/Perl/OlleDB
 * Removed h in format string with sscan_f as this caused a crash on
 * VS2015. Also avoid compilation warnings with VS2015.
 * 
 * *****************  Version 16  *****************
 * User: Sommar       Date: 15-05-24   Time: 21:06
 * Updated in $/Perl/OlleDB
 * Replaced check on _WIN64 with USE_64_BIT_INT, so that it works with
 * 64-integers on 32-bit Perl.
 * 
 * *****************  Version 15  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:52
 * Updated in $/Perl/OlleDB
 * Updated Copyright note.
 * 
 * *****************  Version 14  *****************
 * User: Sommar       Date: 12-08-08   Time: 23:20
 * Updated in $/Perl/OlleDB
 * parsename now has a return value.
 * 
 * *****************  Version 13  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:28
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64 and more.
 * 
 * *****************  Version 12  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:44
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared.
 *
 * *****************  Version 11  *****************
 * User: Sommar       Date: 08-04-28   Time: 23:12
 * Updated in $/Perl/OlleDB
 * maxlen was incorrectly ULONG or UINT when it should have been DBLENGTH.
 *
 * *****************  Version 10  *****************
 * User: Sommar       Date: 08-03-23   Time: 23:40
 * Updated in $/Perl/OlleDB
 * Handle unidentified parameter types differently and more directly. The
 * check for larges UDT and SQLOLEDB was incorrect. Extra protection for
 * parameter properties.
 *
 * *****************  Version 9  *****************
 * User: Sommar       Date: 08-03-16   Time: 21:29
 * Updated in $/Perl/OlleDB
 * If input to initbatch is undef or the empty string, use one blank as
 * the command text.
 *
 * *****************  Version 8  *****************
 * User: Sommar       Date: 08-02-24   Time: 16:09
 * Updated in $/Perl/OlleDB
 * Correct handling of empty table parameters.
 *
 * *****************  Version 7  *****************
 * User: Sommar       Date: 08-02-10   Time: 17:13
 * Updated in $/Perl/OlleDB
 * Added special handling of type name rowversion, since no provider
 * understands this name.
 *
 * *****************  Version 6  *****************
 * User: Sommar       Date: 08-01-06   Time: 23:33
 * Updated in $/Perl/OlleDB
 * Replaced all unsafe CRT functions with their safe replacements in VC8.
 * olledb_message now takes a va_list as argument, so we pass it
 * parameterised strings and don't have to litter the rest of the code
 * with that.
 *
 * *****************  Version 5  *****************
 * User: Sommar       Date: 08-01-06   Time: 18:56
 * Updated in $/Perl/OlleDB
 * All the switch(datatype) for parameters and column in TVPs are now in
 * common code, and not duplicated in senddata and tableparam.
 *
 * *****************  Version 4  *****************
 * User: Sommar       Date: 08-01-05   Time: 21:26
 * Updated in $/Perl/OlleDB
 * Moving the creation of the session pointer broke AutoConnect. The code
 * for AutoConnect is now in the connect module and be called from
 * executebatch or definetablecolumn.
 *
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-01-05   Time: 20:47
 * Updated in $/Perl/OlleDB
 * Handle parameter property for table parameters to specify columns to be
 * sent by default.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-05   Time: 0:27
 * Updated in $/Perl/OlleDB
 * Added support for table-valued parameters, and various cleanup in
 * conjunction with that.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:40
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/

#include "CommonInclude.h"
#include "handleattributes.h"
#include "convenience.h"
#include "datatypemap.h"
#include "init.h"
#include "internaldata.h"
#include "errcheck.h"
#include "connect.h"
#include "utils.h"
#include "datetime.h"
#include "tableparam.h"
#include "senddata.h"


//------------------------------------------------------------------
// Conversion-from-SV routines. These routines converts an SV to the
// desired SQL Server type. For most types the conversion is implicit
// from the data type of the Perl variable.
// Note that SV_to_BSTR is in the beginning of the file, as this is a
// generally used routine.
//------------------------------------------------------------------

// This is a helper routine, which uses DataConvert to convert a Perl
// String, which can be either an 8-bit string or a UTF8-string.
static HRESULT  SVstr_to_sqlvalue (SV   * sv,
                                   DBTYPE sqltype,
                                   void * sqlvalue,
                                   BYTE   precision = NULL,
                                   BYTE   scale     = NULL)
{
   HRESULT ret;

   assert(SvPOK(sv));
   if (SvUTF8(sv)) {
      DBLENGTH bytelen;
      BSTR bstr = SV_to_BSTR(sv, &bytelen);
      ret = data_convert_ptr->DataConvert(
            DBTYPE_WSTR, sqltype, bytelen, NULL,
            bstr, sqlvalue, NULL, DBSTATUS_S_OK, NULL,
            precision, scale, 0);
      SysFreeString(bstr);
   }
   else {
      STRLEN strlen;
      char * str = SvPV(sv, strlen);
      ret = data_convert_ptr->DataConvert(
            DBTYPE_STR, sqltype, strlen, NULL,
            str, sqlvalue, NULL, DBSTATUS_S_OK, NULL,
            precision, scale, 0);
   }

   return ret;
}


BOOL SV_to_bigint (SV      * sv,
                   LONG64  &bigintval)
{
   HRESULT ret;

   if (SvPOK(sv)) {
      ret = SVstr_to_sqlvalue(sv, DBTYPE_I8, &bigintval);
   }
   else if (SvNOK(sv)) {
      double dbl = SvNV(sv);
      ret = data_convert_ptr->DataConvert(
            DBTYPE_R8, DBTYPE_I8, sizeof(double), NULL,
            &dbl, &bigintval, NULL, DBSTATUS_S_OK, NULL,
            0, 0, 0);
   }
   else {
   // It could be an integer or a reference, whatever we handle as int.
      bigintval = SvIV(sv);
      ret = S_OK;
   }

   return SUCCEEDED(ret);
}

BOOL SV_to_binary (SV        * sv,
                   bin_options optBinaryAsStr,
                   BOOL        istimestamp,
                   BYTE      * &binaryval,
                   DBLENGTH    &value_len)
{
    BOOL     retval;
    STRLEN   perl_len;
    char   * perl_ptr = (char *) SvPV(sv, perl_len);

    if (optBinaryAsStr != bin_binary) {
       HRESULT  ret;

       // Note that we don't here consider the possibility that the string
       // may be a UTF-8 string. It should really only include 0-9 and
       // A-F plus any leading 0x. Digits from other scripts are not
       // considered.

       if (_strnicmp(perl_ptr, "0x", 2) == 0) {
          perl_ptr += 2;
          perl_len -= 2;
       }

       value_len = perl_len / 2;
       New(902, binaryval, value_len, BYTE);
       ret = data_convert_ptr->DataConvert(
             DBTYPE_STR, DBTYPE_BYTES, perl_len, NULL,
             perl_ptr, binaryval, value_len, DBSTATUS_S_OK, NULL,
             NULL, NULL, 0);
       retval = SUCCEEDED(ret);
    }
    else {
       value_len = perl_len;
       New(902, binaryval, value_len, BYTE);
       memcpy(binaryval, perl_ptr, value_len);
       retval = TRUE;
    }

    // If this is a timestamp value, and the input value gave us a value
    // less than 8 bytes, we must reallocate and pad, since timestamp is
    // is fixed-length and else we would send random garbage.
    if (istimestamp && value_len < 8) {
       BYTE *tmp;
       New(902, tmp, 8, BYTE);
       memset(tmp, 0, sizeof(BYTE) * 8);
       memcpy(tmp, binaryval, value_len);
       value_len = 8;
       Safefree(binaryval);
       binaryval = tmp;
    }

    return retval;
}

BOOL SV_to_char (SV       * sv,
                 UINT       DB_codepage,
                 char     * &charval,
                 DBLENGTH   &value_len)
{
   // We have to convert the data from one code page to another, but
   // only do this if needed.
   if (SvUTF8(sv) && DB_codepage == CP_UTF8 ||
       ! SvUTF8(sv) && DB_codepage == GetACP()) {
      // Just copy the string to our own buffer
      STRLEN strlen;
      char * perl_str = SvPV(sv, strlen);
      value_len = strlen;
      New(902, charval, strlen + 1, char);
      memcpy(charval, perl_str, strlen);
   }
   else {
      // First convert it to UTF-16 (because that is what Windows offers).
      // and then to the target code page.
      BSTR bstr = SV_to_BSTR(sv);
      STRLEN charlen;
      charval = BSTR_to_char(bstr, SysStringLen(bstr), DB_codepage, 
                             &charlen);
      value_len = charlen;
      SysFreeString(bstr);
   }

   return TRUE;
}

// This is a helper routine to SV_to_XML, also called from enterparameter.
// It extracts the encoding for an XML string, and deduces whether it is a
// 16/32-bit encoding, UTF-8 or a 8-bit charset. It also returns the position
// where the encoding name appears, or -1 if there isn't any.
typedef enum xmlcharsettypes {eightbit, utf8, sixteen} xmlcharsettypes;

static void get_xmlencoding (SV              * sv,
                             xmlcharsettypes &xmlcharsettype,
                             int             &charsetpos)
{
   char   encoding[20];
   int    scanret;
   char * str;

   if (! my_sv_is_defined(sv)) {
      xmlcharsettype = utf8;
      charsetpos    = -1;
      return;
   }
   str = SvPV_nolen(sv);
   // If there is an encoding, it must come in the prolog which must be at
   // the very first in the file. This is heaviliy regimented by the XML
   // standard. sscanf comes in handy here.
   scanret = sscanf_s(str, "<?xml version = \"1.0\" encoding = \"%19[^\"]\"",
                      encoding, 20);

   // scanret == 1 => we found an encoding string.
   if (scanret == 1) {
      // Get the position.
      char *tmp = strstr(str, encoding);
      charsetpos = (int) (tmp - str);

      // Then normalise to lowercase.
      _strlwr_s(encoding, 20);

      // Then compare to various known encodings.
      if (strstr(encoding, "utf-8") == encoding) {
         xmlcharsettype = utf8;
      }
      else if (strstr(encoding, "ucs-2") == encoding ||
              strstr(encoding, "utf-16") == encoding) {
         xmlcharsettype = sixteen;
      }
      else {
         // All other encodings are assumed to be 8-bit.
         xmlcharsettype = eightbit;
      }
   }
   else {
      // If there was no encoding, then it has to be UTF-8.
      xmlcharsettype = utf8;
      charsetpos     = -1;
   }
}


BOOL SV_to_XML (SV        * sv,
                UINT        DB_codepage,
                BOOL        &is_8bit,
                char      * &xmlchar,
                BSTR        &xmlbstr,
                DBLENGTH    &value_len)
{
   xmlcharsettypes   charsettype;
   int               dummy;
   BOOL              retval;

   // Get the character-set type.
   get_xmlencoding(sv, charsettype, dummy);

   // And then handle the string accordingly.
   switch (charsettype) {
      case eightbit :
         retval = SV_to_char(sv, DB_codepage, xmlchar, value_len);
         //value_len *= 2;
         is_8bit = TRUE;
         xmlbstr = NULL;
         break;

      case utf8 : {
         // Force string to be UTF-8.
         STRLEN strlen;
         char   * perl_str = SvPVutf8(sv, strlen);
         value_len = strlen;
         New(902, xmlchar, strlen + 1, char);
         memcpy(xmlchar, perl_str, strlen);
         is_8bit = true;
         xmlbstr = NULL;
         retval = TRUE;
         break;
      }

      case sixteen : {
         // Convert to BSTR and force insert of a BOM.
         xmlbstr = SV_to_BSTR(sv, &value_len, TRUE);
         xmlchar = NULL;
         is_8bit = FALSE;
         retval = TRUE;
         break;
      }
      default :
         croak ("Entirely unexpected value for charsettype %d", charsettype);
         break;
   }
   return retval;
}


BOOL SV_to_decimal(SV        * sv,
                   BYTE        precision,
                   BYTE        scale,
                   DB_NUMERIC &decimalval)
{
   HRESULT  ret;

   if (SvPOK(sv)) {
      ret = SVstr_to_sqlvalue(sv, DBTYPE_NUMERIC, &decimalval,
                              precision, scale);
   }
   else {
      double dbl = SvNV(sv);
      ret = data_convert_ptr->DataConvert(
            DBTYPE_R8, DBTYPE_NUMERIC, sizeof(double), NULL,
            &dbl, &decimalval, NULL, DBSTATUS_S_OK, NULL,
            precision, scale, 0);
   }
   return SUCCEEDED(ret);
}

BOOL SV_to_GUID (SV       * sv,
                 GUID       &guidval)
{
   if (SvPOK(sv)) {
      HRESULT ret;
      STRLEN strlen;
      char * perl_str = SvPV(sv, strlen);

      if (strlen == 36) {
         // This could be a GUID without braces, so we add them.
         char guidstr[39];
         sprintf_s(guidstr, 39, "{%s}", perl_str);
         ret = data_convert_ptr->DataConvert(
               DBTYPE_STR, DBTYPE_GUID, 38, NULL,
               guidstr, &guidval, NULL, DBSTATUS_S_OK, NULL,
               NULL, NULL, 0);
      }
      else {
         ret = SVstr_to_sqlvalue(sv, DBTYPE_GUID, &guidval);
      }
      return SUCCEEDED(ret);
   }
   else {
      // It would be useless even to try...
      return FALSE;
   }
}

extern BOOL SV_to_money(SV * sv,
                        CY  &moneyval)
{
   HRESULT  ret;

   if (SvPOK(sv)) {
      ret = SVstr_to_sqlvalue(sv, DBTYPE_CY, &moneyval);
   }
   else {
      double dbl = SvNV(sv);
      ret = data_convert_ptr->DataConvert(
            DBTYPE_R8, DBTYPE_CY, sizeof(double), NULL,
            &dbl, &moneyval, sizeof(CY), DBSTATUS_S_OK, NULL,
            NULL, NULL, 0);
   }
   return SUCCEEDED(ret);
}

BOOL SV_to_ssvariant (SV          * sv,
                      SSVARIANT     &variant,
                      SV          * olle_ptr,
                      provider_enum provider,
                      void        * &save_str,
                      BSTR          &save_bstr)
{
    UINT DB_codepage = OptCurrentCodepage(olle_ptr);

    save_str = NULL;
    save_bstr = NULL;
    memset(&variant, 0, sizeof(SSVARIANT));
    variant.vt = VT_SS_NULL;

    // If the SV is a reference to a hash, it may be a datetime value, so
    // we try this first. SS_to_ssvariant_datetime will return true if the
    // reference is something completely different, so we can fall through
    // and interpret the reference as a string. Only if it looks as a 
    // datetime hash with illegal value, we get FALSE back.
    if (SvROK(sv)) {
       BOOL ret = SV_to_ssvariant_datetime(sv, variant, olle_ptr, provider);
       if (! ret) return FALSE;
       if (variant.vt != VT_SS_NULL) return TRUE;
    }

    if (SvIOK(sv)) {
#ifdef USE_64_BIT_INT
       // On 64-bit, we make a choice between int and bigint.
       LONG64 val = SvIV(sv);
       if (val < LONG_MIN || val > LONG_MAX) {
          variant.vt = VT_SS_I8;
          variant.llBigIntVal = val;
       }
       else {
          variant.vt = VT_SS_I4;
          variant.lIntVal = (LONG) val;
       }
#else
       // On 32-bit, we can only handle int, and larger values will go as floats.
       variant.vt = VT_SS_I4;
       variant.lIntVal = SvIV(sv);
#endif
    }
    else if (SvNOK(sv)) {
       variant.vt = VT_SS_R8;
       variant.dblFloatVal = SvNV(sv);
    }
    else if (DB_codepage != CP_UTF8 &&
            (SvUTF8(sv) || DB_codepage != GetACP())) {
       // We probably have a string (but it would be a references or
       // whatever). If database collation is UTF8. we always pass
       // the value as varchar. Else we send nvarchar, if the UTF8
       // bit is set, of the codeages are different.
       DBLENGTH bytelen;
       BSTR     bstr = SV_to_BSTR(sv, &bytelen);

       if (bytelen > 8000) bytelen = 8000;
       variant.vt = VT_SS_WVARSTRING;
       variant.NCharVal.sActualLength = (SHORT) bytelen;
       variant.NCharVal.sMaxLength = (SHORT) bytelen;
       variant.NCharVal.pwchNCharVal = bstr;
       save_bstr = bstr;
    }
    else {
       // Send as varchar.
       DBLENGTH strlen;
       char * str;
       SV_to_char(sv, DB_codepage, str, strlen);
       if (strlen > 8000) strlen = 8000;
       str[strlen] = '\0';

       variant.vt = VT_SS_VARSTRING;
       variant.CharVal.pchCharVal =  str;
       variant.CharVal.sActualLength = (SHORT) strlen;
       variant.CharVal.sMaxLength = (SHORT) strlen;
       save_str = str;
    }

    return TRUE;
}

// This is a different SV_to_xxx thing. For UDT and XML, there may be
// parameter properties to add to the parameter record.
static void add_param_props (SV        * olle_ptr,
                             paramdata * param,
                             SV        * typeinfo)
{
    // Drop out if there is no typeinfo.
    if (! my_sv_is_defined(typeinfo)) {
       return;
    }

    SV * server   = newSV(sv_len(typeinfo));
    SV * database = newSV(sv_len(typeinfo));
    SV * schema   = newSV(sv_len(typeinfo));
    SV * object   = newSV(sv_len(typeinfo));
    int  ix = 0;
    DBPROPID  dbpropid;
    DBPROPID  schemapropid;
    DBPROPID  objectpropid;

    // First extract components from typeinfo.
    if (! parsename(olle_ptr, typeinfo, 0, server, database, schema, object)) {
       return;
    }

    // If there was a server, cry foul.
    if (sv_len(server) > 0) {
       BSTR typeinfo_str = SV_to_BSTR(typeinfo);
       olledb_message(olle_ptr, -1, -1, 16,
                      L"Type name/XML schema '%s' includes a server component.\n",
                      typeinfo_str);
       SysFreeString(typeinfo_str);
       SvREFCNT_dec(server);
       SvREFCNT_dec(database);
       SvREFCNT_dec(schema);
       SvREFCNT_dec(object);
       return;
    }

    // Find out how many components we have.
    if (sv_len(database) > 0) param->param_props_cnt++;
    if (sv_len(schema) > 0) param->param_props_cnt++;
    if (sv_len(object) > 0) param->param_props_cnt++;

    // If there was nothing, just drop out.
    if (param->param_props_cnt == 0)
        return;

    // Set up property ids
    switch (param->datatype) {
        case DBTYPE_UDT :
             dbpropid     = SSPROP_PARAM_UDT_CATALOGNAME;
             schemapropid = SSPROP_PARAM_UDT_SCHEMANAME;
             objectpropid = SSPROP_PARAM_UDT_NAME;
             break;

        case DBTYPE_XML :
             dbpropid     = SSPROP_PARAM_XML_SCHEMACOLLECTION_CATALOGNAME;
             schemapropid = SSPROP_PARAM_XML_SCHEMACOLLECTION_SCHEMANAME;
             objectpropid = SSPROP_PARAM_XML_SCHEMACOLLECTIONNAME;
             break;

        case DBTYPE_TABLE :
             dbpropid     = SSPROP_PARAM_TYPE_CATALOGNAME;
             schemapropid = SSPROP_PARAM_TYPE_SCHEMANAME;
             objectpropid = SSPROP_PARAM_TYPE_TYPENAME;
             break;

         default :
             olle_croak(olle_ptr,
                        "Internal error: Unexpected value %d for data type in add_param_props",
                        param->datatype);
    }


    // Now we can allocate as many properties as need
    New(902, param->param_props, param->param_props_cnt, DBPROP);

    // Store database if any.
    if (sv_len(database) > 0) {
       param->param_props[ix].dwPropertyID = dbpropid;
       param->param_props[ix].colid = DB_NULLID;
       param->param_props[ix].dwOptions = DBPROPOPTIONS_REQUIRED;
       VariantInit(&(param->param_props[ix].vValue));
       param->param_props[ix].vValue.vt = VT_BSTR;
       param->param_props[ix].vValue.bstrVal = SV_to_BSTR(database);
       ix++;
    }

    // And schema if any.
    if (sv_len(schema) > 0) {
       param->param_props[ix].dwPropertyID = schemapropid;
       param->param_props[ix].colid = DB_NULLID;
       param->param_props[ix].dwOptions = DBPROPOPTIONS_REQUIRED;
       VariantInit(&(param->param_props[ix].vValue));
       param->param_props[ix].vValue.vt = VT_BSTR;
       param->param_props[ix].vValue.bstrVal = SV_to_BSTR(schema);
       ix++;
    }

    // And the type name.
    if (sv_len(object) > 0) {
       param->param_props[ix].dwPropertyID = objectpropid;
       param->param_props[ix].colid = DB_NULLID;
       param->param_props[ix].dwOptions = DBPROPOPTIONS_REQUIRED;
       VariantInit(&(param->param_props[ix].vValue));
       param->param_props[ix].vValue.vt = VT_BSTR;
       param->param_props[ix].vValue.bstrVal = SV_to_BSTR(object);
    }

    // We must clean up our SVs to not leak memory.
    SvREFCNT_dec(server);
    SvREFCNT_dec(database);
    SvREFCNT_dec(schema);
    SvREFCNT_dec(object);
}

//--------------------------------------------------------------------------
// This routine sets up a binding for a parameter or a column in a table-
// valued parameter. The latter does not use DBPARAMBINDINFO, but will
// have to copy to a column desciption.
//-------------------------------------------------------------------------
void complete_binding (DBTYPE           datatype,
                       const char     * nameoftype,
                       DBLENGTH         maxlen,
                       SV             * sv_precision,
                       SV             * sv_scale,
                       size_t          &size_buffer,
                       DBBINDING       * binding,
                       DBPARAMBINDINFO * param_info)
{
   switch (datatype) {
      case DBTYPE_BOOL :
         param_info->ulParamSize = sizeof(BOOL);
         size_buffer += sizeof(BOOL);
         break;

      case DBTYPE_UI1 :
         param_info->ulParamSize = 1;
         size_buffer += 1;
         break;

      case DBTYPE_I2 :
         param_info->ulParamSize = 2;
         size_buffer += 2;
         break;

      case DBTYPE_I4 :
         param_info->ulParamSize = 4;
         size_buffer += 4;
         break;

      case DBTYPE_I8 :
         param_info->ulParamSize = 8;
         size_buffer += 8;
         break;

      case DBTYPE_R4 :
         param_info->ulParamSize = 4;
         size_buffer += 4;
         break;

      case DBTYPE_R8 :
         param_info->ulParamSize = 8;
         size_buffer += 8;
         break;

      case DBTYPE_NUMERIC : {
            BYTE precision = (my_sv_is_defined(sv_precision) ?
                             (BYTE) SvIV(sv_precision) : 18);
            BYTE scale     = (my_sv_is_defined(sv_scale) ?
                             (BYTE) SvIV(sv_scale) : 0);
            param_info->ulParamSize = sizeof(DB_NUMERIC);
            param_info->bPrecision = precision;
            param_info->bScale     = scale;
            binding->bPrecision = precision;
            binding->bScale     = scale;
            size_buffer += sizeof(DB_NUMERIC);
         }
         break;

      case DBTYPE_CY :
         param_info->ulParamSize = sizeof(CY);
         size_buffer += sizeof(CY);
         break;

      case DBTYPE_DBDATE :
         param_info->ulParamSize = sizeof(DBDATE);
         size_buffer += sizeof(DBDATE);
         break;

      case DBTYPE_DBTIME2 : {
            BYTE scale     = (my_sv_is_defined(sv_scale) ?
                              (BYTE) SvIV(sv_scale) : 7);
            BYTE precision = (scale == 0 ? 8 : scale + 9);
            param_info->ulParamSize = sizeof(DBTIME2);
            param_info->bPrecision = precision;
            param_info->bScale     = scale;
            binding->bPrecision = precision;
            binding->bScale     = scale;
            size_buffer += sizeof(DBTIME2);
         }
         break;

      case DBTYPE_DBTIMESTAMP : {
            BYTE scale     = (my_sv_is_defined(sv_scale) ?
                              (BYTE) SvIV(sv_scale) : 7);
            BYTE precision = (scale == 0 ? 19 : scale + 20);
            param_info->ulParamSize = sizeof(DBTIMESTAMP);
            size_buffer += sizeof(DBTIMESTAMP);
            if (strcmp(nameoftype, "smalldatetime") == 0) {
               precision = 16;
               scale = 0;
            }
            else if (strcmp(nameoftype, "datetime") == 0) {
               precision = 23;
               scale     = 3;
            }
            param_info->bPrecision = precision;
            param_info->bScale     = scale;
            binding->bPrecision    = precision;
            binding->bScale        = scale;
         }
         break;

      case DBTYPE_DBTIMESTAMPOFFSET : {
            BYTE scale     = (my_sv_is_defined(sv_scale) ?
                              (BYTE) SvIV(sv_scale) : 7);
            BYTE precision = (scale == 0 ? 26 : scale + 27);
            param_info->ulParamSize = sizeof(DBTIMESTAMPOFFSET);
            size_buffer += sizeof(DBTIMESTAMPOFFSET);
            param_info->bPrecision = precision;
            param_info->bScale     = scale;
            binding->bPrecision    = precision;
            binding->bScale        = scale;
         }
         break;

      case DBTYPE_GUID :
         param_info->ulParamSize = sizeof(GUID);
         size_buffer += sizeof(GUID);
         break;

      case DBTYPE_UDT   :
         // Here we should not use the name of the type sent in.
         param_info->pwszDataSourceType = SysAllocString(L"DBTYPE_UDT");
         // Fall-through, since save the type info UDT is just like binary or
         // any other type passed by reference
      case DBTYPE_BYTES :
      case DBTYPE_STR   :
      case DBTYPE_WSTR  :
      case DBTYPE_XML   :
         param_info->ulParamSize = maxlen;
         binding->wType |= DBTYPE_BYREF;
         size_buffer += sizeof(BYTE *);
         binding->dwPart   |= DBPART_LENGTH;
         binding->obLength  = size_buffer;
         size_buffer += sizeof(DBLENGTH);
         break;

      case DBTYPE_SQLVARIANT :
         param_info->ulParamSize = sizeof(SSVARIANT);
         size_buffer += sizeof(SSVARIANT);
         break;

      case DBTYPE_TABLE :
         croak("Internal error: DBTYPE_TABLE should never be passed to setup_binding.\n");
         break;

      default :
         // If we come here, this is an internal error in the XS module.
         warn ("Param handling for type %s not implemented yet", nameoftype);
   }
}

//-------------------------------------------------------------------
// perl_to_sqlvalue - Takes an SV and returns a value for sending to
// SQL Server in a valueunion struct. Used by enterparameter and
// inserttableparam. Returns FALSE if conversion failed.
//-------------------------------------------------------------------
BOOL perl_to_sqlvalue(SV         * olle_ptr,
                      SV         * sv_value,
                      DBTYPE       typeind,
                      WCHAR      * param_name,
                      WCHAR      * nameoftype,
                      DBBINDING  * binding,
                      DBLENGTH     maxlen,
                      valueunion  &sqlvalue,
                      DBLENGTH    &value_len,
                      void      * &save_ptr,
                      BSTR        &save_bstr)
{
   BOOL           value_OK = TRUE;
   internaldata * mydata = get_internaldata(olle_ptr);

   switch(typeind) {
      case DBTYPE_BOOL :
         sqlvalue.bit = SvTRUE(sv_value);
         break;

      case DBTYPE_UI1 :
         sqlvalue.tinyint = (BYTE) SvIV(sv_value);
         break;

      case DBTYPE_I2 :
         sqlvalue.smallint = (SHORT) SvIV(sv_value);
         break;

      case DBTYPE_I4 :
         sqlvalue.intval = (LONG) SvIV(sv_value);
         break;

      case DBTYPE_I8 :
         value_OK = SV_to_bigint(sv_value, sqlvalue.bigint);
         break;

      case DBTYPE_R4 :
         sqlvalue.real = (FLOAT) SvNV(sv_value);
         break;

      case DBTYPE_R8 :
         sqlvalue.floatval = SvNV(sv_value);
         break;

      case DBTYPE_NUMERIC :
         value_OK = SV_to_decimal(sv_value, binding->bPrecision,
                                  binding->bScale, sqlvalue.decimal);
         break;

      case DBTYPE_CY :
         value_OK = SV_to_money(sv_value, sqlvalue.money);
         break;

      case DBTYPE_DBDATE :
         value_OK = SV_to_date(sv_value, sqlvalue.date, olle_ptr);
         break;

      case DBTYPE_DBTIME2 :
         value_OK = SV_to_time(sv_value, binding->bScale, sqlvalue.time,
                               olle_ptr);
         break;

      case DBTYPE_DBTIMESTAMP :
         {
            int firstyear = 1;
            int lastyear  = 9999;
            if (wcscmp(nameoftype, L"smalldatetime") == 0) {
               firstyear = 1900;
               lastyear  = 2079;
            }
            else if (wcscmp(nameoftype, L"datetime") == 0) {
               firstyear = 1753;
            }
            value_OK = SV_to_datetime(sv_value, binding->bScale,
                                      sqlvalue.datetime, olle_ptr,
                                      firstyear, lastyear);
         }
         break;

      case DBTYPE_DBTIMESTAMPOFFSET :
         value_OK = SV_to_datetimeoffset(sv_value, binding->bScale,
                                         OptTZOffset(olle_ptr),
                                         sqlvalue.dtoffset, olle_ptr);
         break;

      case DBTYPE_GUID :
         value_OK = SV_to_GUID(sv_value, sqlvalue.guid);
         break;

      case DBTYPE_STR :
         {  char * value_ptr;
            value_OK = SV_to_char(sv_value, OptCurrentCodepage(olle_ptr),
                                  value_ptr, value_len);
            if (value_OK) {
               // If the value is overlong, just silently truncate it.
               if (value_len > maxlen) {
                   value_len = maxlen;
               }
               sqlvalue.byrefptr = save_ptr = (void *) value_ptr;
            }
         }
         break;

      case DBTYPE_XML :
         {  char * value8_ptr = NULL;
            BSTR   value_bstr = NULL;
            BOOL   is_8bit;
            value_OK = SV_to_XML(sv_value, OptCurrentCodepage(olle_ptr),
                               is_8bit, value8_ptr, value_bstr, value_len);
            if (value_OK) {
               if (is_8bit) {
                  sqlvalue.byrefptr = save_ptr = (void *) value8_ptr;
               }
               else {
                  save_bstr = value_bstr;
                  sqlvalue.byrefptr = (void *) value_bstr;
               }
            }
         }
         break;

      case DBTYPE_WSTR :
         {  BSTR value_ptr = SV_to_BSTR(sv_value);
            STRLEN strlen = SysStringLen(value_ptr);
            sqlvalue.byrefptr = (void *) value_ptr;
            save_bstr = value_ptr;
            value_len = 2 * (strlen <= maxlen ? strlen : maxlen);
         }
         break;

      case DBTYPE_UDT   :
      case DBTYPE_BYTES :
         {  BYTE * value_ptr;
            BOOL   istimestamp = (wcscmp(nameoftype, L"timestamp") == 0 ||
                                  wcscmp(nameoftype, L"rowversion") == 0);
            value_OK = SV_to_binary(sv_value, OptBinaryAsStr(olle_ptr),
                                    istimestamp, value_ptr, value_len);
            if (value_OK) {
               if (value_len > maxlen) {
                  value_len = maxlen;
               }
               save_ptr = (void *) value_ptr;
               sqlvalue.byrefptr = (void  *) value_ptr;
            }
         }
         break;

      case DBTYPE_SQLVARIANT :
         value_OK = SV_to_ssvariant(sv_value, sqlvalue.sql_variant, olle_ptr,
                                    mydata->provider, save_ptr, save_bstr);
         break;

      case DBTYPE_TABLE :
         olle_croak(olle_ptr,
                    "Internal error: DBTYPE_TABLE should never appear in perl_to_sqlvalue.\n");
         break;

      default :
         olle_croak (olle_ptr,
                     "Internal error: unexpected type indicator %d passed to perl_to_sqlvalue",
                     binding->wType);
         break;
   }

   if (! value_OK) {
      // There was a conversion error. Issue an error message through the
      // message handler.
      BSTR     stringrep = SV_to_BSTR(sv_value);
      WCHAR  * value_name = (param_name != NULL ? param_name : L"");
      WCHAR  * creature = (binding->eParamIO == DBPARAMIO_NOTPARAM ?
                            L"column" : L"parameter");

      olledb_message(olle_ptr, -1, 1, 10,
                     L"Could not convert Perl value '%s' to type %s for %s '%s'.",
                     stringrep, nameoftype, creature, value_name);

      SysFreeString(stringrep);
      return FALSE;
   }

   return value_OK;
}


//--------------------------------------------------------------------
// $X->initbatch.
//--------------------------------------------------------------------
int initbatch(SV   * olle_ptr,
              SV   * sv_cmdtext,
              BOOL isnestedquery)
{
    internaldata  * mydata = get_internaldata(olle_ptr);

    if (! sv_cmdtext) {
       olle_croak(olle_ptr, "Parameter sv_cmdtext to submitcmd missing.");
    }

    // There must be no pending command, as then a command is still progress.
    if (mydata->pending_cmd != NULL) {
        olle_croak(olle_ptr, "Cannot init a new batch, when previous batch has not been processed");
    }

    // This is the point where we set SQL Server version and get codepage
    // for the current database. We go to the Perl code, which may call 
    // as again. 
    if (! isnestedquery) {
       // Make sure that we have the datasrc pointers set up.
       if (! setup_datasrc(olle_ptr)) {
          return FALSE;
       }

       // When we call the Perl code, this may lead to a nested
       // query. Set this flag now.
       mydata->isnestedquery = TRUE;

       // Set up for the Perl callback.
       dSP;
       ENTER;
       SAVETMPS;
       PUSHMARK(SP);
       EXTEND(SP, 2);
       PUSHs(olle_ptr);
       PUTBACK;
       call_method("get_db_codepage", G_DISCARD);

       FREETMPS;
       LEAVE;

       // And clear the nested-query flag.
       mydata->isnestedquery = FALSE;
    }

    // Save the command. If the command text is blank or the empty string,
    // we set the command text to one blank, to avoid error emssages.
    if (my_sv_is_defined(sv_cmdtext) && SvCUR(sv_cmdtext) > 0) {
       mydata->pending_cmd = SV_to_BSTR(sv_cmdtext);
    }
    else {
       mydata->pending_cmd = SysAllocString(L" ");
    }
    return TRUE;
}

//------------------------------------------------------------------------
// $X->enterparameter
//------------------------------------------------------------------------
int enterparameter(SV   * olle_ptr,
                   SV   * sv_nameoftype,
                   SV   * sv_maxlen,
                   SV   * paramname,
                   BOOL   isinput,
                   BOOL   isoutput,
                   SV   * sv_value,
                   SV   * sv_precision,
                   SV   * sv_scale,
                   SV   * typeinfo)
{
   internaldata    * mydata = get_internaldata(olle_ptr);
   DBLENGTH          maxlen;
   char            * nameoftype;
   BSTR              bstr_nameoftype;
   paramdata       * this_param;
   DBBINDING       * binding;     // Shortcut to this_param->binding.
   DBPARAMBINDINFO * param_info;  // Shortcut to this_param->param_info.
   BOOL              value_OK = TRUE;


   // Check that we're in the state where we're accepting parameters.
   if (mydata->pending_cmd == NULL) {
      olle_croak(olle_ptr, "Cannot call enterparameter now. There is no pending command. Call initbatch first");
   }

   if (mydata->cmdtext_ptr != NULL) {
      olle_croak(olle_ptr, "Cannot call enterparameter now. There are unprocessed result sets. Call cancelbatch first");
   }

   // Type name is mandatory.
   if (! my_sv_is_defined(sv_nameoftype)) {
      olle_croak(olle_ptr, "You must pass a legal type name to enterparameter. Cannot pass undef");
   }
   nameoftype = SvPV_nolen(sv_nameoftype);
   if (strcmp(nameoftype, "rowversion") != 0) {
      bstr_nameoftype = SV_to_BSTR(sv_nameoftype);
   }
   else {
   // No provider currently handles the name rowversion, although they should.
      nameoftype = "timestamp";
      bstr_nameoftype = SysAllocString(L"timestamp");
   }

   // Get maxlen.
   if (my_sv_is_defined(sv_maxlen)) {
      maxlen = SvUV(sv_maxlen);
   }
   else {
      maxlen = 0;
   }

   // Allocate space for this parameter.
   New(902, this_param, 1, paramdata);
   memset(this_param, 0, sizeof(paramdata));

   // Link in to the parameter list and increase parameter count.
   this_param->next = NULL;
   if (mydata->paramlast == NULL) {
      mydata->paramfirst = this_param;
      mydata->paramlast  = this_param;
      mydata->no_of_params = 1;
   }
   else {
      mydata->paramlast->next = this_param;
      mydata->paramlast = this_param;
      mydata->no_of_params++;
   }

   // Find the data type.
   this_param->datatype = lookup_type_map(nameoftype);

   // If type is unknown, but back out so caller define all his parameters,
   // and find all his errors.
   if (this_param->datatype == DBTYPE_EMPTY) {
      olledb_message(olle_ptr, -1, 1, 10,
                     L"Unknown data type '%s' for parameter '%S'.",
                     bstr_nameoftype, SvPV_nolen(paramname));
      mydata->all_params_OK = FALSE;
      return TRUE;
   }

   // input/output maps to flags.
   this_param->isinput = isinput;
   this_param->isoutput = isoutput;

   // Is value NULL or not?
   this_param->isnull = (! isinput || ! my_sv_is_defined(sv_value));

   // Increment number of out parameters if necessary.
   if (isoutput) {
      mydata->no_of_out_params++;
   }

   // Set shortcuts to make code somewhat less verbose.
   binding    = &(this_param->binding);
   param_info = &(this_param->param_info);

   // Here we handle fallbacks and similar for data types added in SQL 2005
   // and later and not supported by earlier providers.
   if (this_param->datatype == DBTYPE_UDT) {
       if (maxlen != ~0) {
       // Regular UDT
          if (mydata->provider < provider_sqlncli) {
             this_param->datatype = DBTYPE_BYTES;
             param_info->pwszDataSourceType = SysAllocString(L"varbinary");
          }
       }
       else {
       // Large UDT, this requires SQLNLI10 for full support.
          if (mydata->provider == provider_sqlncli) {
             this_param->datatype = DBTYPE_BYTES;
             param_info->pwszDataSourceType = SysAllocString(L"varbinary");
          }
          else if (mydata->provider == provider_sqloledb) {
          // This does not work at all with SQLOLEDB, so emit a message.
             olledb_message(olle_ptr, -1, 1, 16,
                            L"Alas, you cannot pass large UDT values with SQLOLEDB");
             mydata->all_params_OK = FALSE;
             return FALSE;
          }
       }
   }
   else if (this_param->datatype == DBTYPE_XML &&
            mydata->provider == provider_sqloledb) {
      // And different fallback depending on encoding of the XML document.
      xmlcharsettypes charsettype;
      int             charsetpos;

      get_xmlencoding(sv_value, charsettype, charsetpos);

      if (charsettype == eightbit) {
         // If there is an explicit 8-bit encoding, we must use varchar,
         // to avoid "unable to switch the encoding".
         this_param->datatype = DBTYPE_STR;
         param_info->pwszDataSourceType = SysAllocString(L"varchar");
      }
      else {
         this_param->datatype = DBTYPE_WSTR;
         param_info->pwszDataSourceType = SysAllocString(L"nvarchar");

         // Uh-uh, if there is an explicit utf-8 encoding, this will not
         // work out. So...
         if (charsetpos > 0 && charsettype == utf8) {
            // We replace the encoding with ucs-2, because that is what we
            // we actually will send.
            char * str = SvPV_nolen(sv_value);
            str[charsetpos]     = 'u';
            str[charsetpos + 1] = 'c';
            str[charsetpos + 2] = 's';
            str[charsetpos + 3] = '-';
            str[charsetpos + 4] = '2';
         }
     }
   }
   else if (mydata->provider < provider_sqlncli10 &&
            (this_param->datatype == DBTYPE_DBDATE ||
             this_param->datatype == DBTYPE_DBTIME2 ||
             this_param->datatype == DBTYPE_DBTIMESTAMPOFFSET ||
             strcmp(nameoftype, "datetime2") == 0)) {
       // The new date/time datatypes. Use nvarchar as fallback, and thus
       // support only ISO strings for input format.
      param_info->pwszDataSourceType = SysAllocString(L"nvarchar");
      this_param->datatype = DBTYPE_WSTR;
      maxlen = 34;
   }

   // Set up the bindings and parameter information for this parameter.
   if (my_sv_is_defined(paramname)) {
      param_info->pwszName = SV_to_BSTR(paramname);
   }
   else {
      param_info->pwszName = NULL;
   }
   param_info->dwFlags = (isinput  ? DBPARAMFLAGS_ISINPUT : 0) |
                         (isoutput ? DBPARAMFLAGS_ISOUTPUT : 0);
   param_info->bPrecision = 0;
   param_info->bScale     = 0;

   // Binding.
   binding->iOrdinal   = mydata->no_of_params;
   binding->dwMemOwner = DBMEMOWNER_CLIENTOWNED;
   binding->pTypeInfo  = NULL;
   binding->pObject    = NULL;
   binding->pBindExt   = NULL;
   binding->dwFlags    = 0;
   binding->eParamIO   = (isinput  ? DBPARAMIO_INPUT : 0) |
                         (isoutput ? DBPARAMIO_OUTPUT : 0);
   binding->cbMaxLen   = 0;   // For those where it's ignored.
   binding->wType      = this_param->datatype;   // Some will get a BYREF added.
   binding->obLength   = 0;

   // We always bind status and value.
   binding->dwPart    = DBPART_VALUE | DBPART_STATUS;
   binding->obStatus  = mydata->size_param_buffer;
   mydata->size_param_buffer += sizeof(DBSTATUS);
   binding->obValue   = mydata->size_param_buffer;

   // Complete the binding with the data-type specfic stuff.
   if (this_param->datatype != DBTYPE_TABLE) {
      complete_binding(this_param->datatype, nameoftype, maxlen,
                       sv_precision, sv_scale,
                       mydata->size_param_buffer, binding, param_info);
   }
   else {
      // DBTYPE_TABLE is very special, and not handled by complete_binding,
      // which is shared with definetablecolumn.
      param_info->pwszDataSourceType = SysAllocString(L"DBTYPE_TABLE");
      param_info->ulParamSize = ~0;
      mydata->size_param_buffer += sizeof(IRowsetChange *);
      New(902, this_param->bindobject, 1, DBOBJECT);
      memset(this_param->bindobject, 0, sizeof(DBOBJECT));
      this_param->bindobject->iid = IID_IRowsetChange;
      binding->pObject = this_param->bindobject;
      // At this point we don't want any value.
      if (! this_param->isnull) {
         olle_croak(olle_ptr, "For table parameters you must leave the value parameter undef");
      }
      // But normally caller supplies the values with inserttablecolumn, once
      // the table is defined. However, if the type name is missing, this is
      // means "empty table" which we indicate as isnull for the being.
      if (maxlen > 0) {
         this_param->isnull = FALSE;
         value_OK = setup_tableparam(olle_ptr, paramname, this_param, (ULONG) maxlen,
                                     typeinfo);
      }
   }

   // For some types we should add extra type information.
   if (this_param->datatype == DBTYPE_UDT ||
       this_param->datatype == DBTYPE_XML ||
       this_param->datatype == DBTYPE_TABLE) {
       // The caller may have supplied the name of a built-in UDT. In this
       // case, this is type information.
       if (this_param->datatype == DBTYPE_UDT &&
           strcmp(nameoftype, "UDT") != 0) {
           typeinfo = sv_nameoftype;
       }
       add_param_props(olle_ptr, this_param, typeinfo);
   }


   if (! this_param->isnull && this_param->datatype != DBTYPE_TABLE) {
      // Convert the perl value to an SQL value, and save it. Also save
      // pointers to references value separately, so we can free them up.
      value_OK = perl_to_sqlvalue(olle_ptr, sv_value, this_param->datatype,
                                  param_info->pwszName, bstr_nameoftype,
                                  binding, maxlen,
                                  this_param->value, this_param->value_len,
                                  this_param->buffer_ptr, this_param->bstr);
   }

   mydata->all_params_OK &= value_OK;

   // We also need to fill in the data type as a string if we have not
   // done this before.
   if (param_info->pwszDataSourceType == NULL) {
      param_info->pwszDataSourceType = bstr_nameoftype;
   }
   else {
      SysFreeString(bstr_nameoftype);
   }

   return value_OK;
}


//------------------------------------------------------------------
// Writes a parameter/column value to the buffer at the specified
// offset.
//--------------------------------------------------------------------
void write_to_databuffer(SV        * olle_ptr,
                        BYTE       * buffer,
                        DBBYTEOFFSET offset,
                        DBTYPE       typeind,
                        valueunion   value)
{
   void  *  buffer_ptr = &(buffer[offset]);

   switch (typeind) {
      case DBTYPE_BOOL :
         * (BOOL *) buffer_ptr = value.bit;
         break;

      case DBTYPE_UI1 :
         * (unsigned char *) buffer_ptr = value.tinyint;
         break;

      case DBTYPE_I2 :
         * (short *) buffer_ptr = value.smallint;
         break;

      case DBTYPE_I4 :
         * (LONG32 *) buffer_ptr = value.intval;
         break;

      case DBTYPE_I8 :
         * (LONG64 *) buffer_ptr = value.bigint;
         break;

      case DBTYPE_R4 :
         * (float *) buffer_ptr = value.real;
         break;

      case DBTYPE_R8 :
         * (double *) buffer_ptr = value.floatval;
         break;

      case DBTYPE_NUMERIC :
         * (DB_NUMERIC *) buffer_ptr = value.decimal;
         break;

      case DBTYPE_CY :
         * (CY *) buffer_ptr = value.money;
         break;

      case DBTYPE_DBDATE :
         * (DBDATE *) buffer_ptr = value.date;
         break;

      case DBTYPE_DBTIME2 :
         * (DBTIME2 *) buffer_ptr = value.time;
         break;

      case DBTYPE_DBTIMESTAMP :
         * (DBTIMESTAMP *) buffer_ptr = value.datetime;
         break;

      case DBTYPE_DBTIMESTAMPOFFSET :
         * (DBTIMESTAMPOFFSET *) buffer_ptr = value.dtoffset;
         break;

      case DBTYPE_GUID :
         * (GUID *) buffer_ptr = value.guid;
         break;

      case DBTYPE_WSTR :
      case DBTYPE_XML :
      case DBTYPE_STR :
      case DBTYPE_UDT   :
      case DBTYPE_BYTES :
         * (void **) buffer_ptr = value.byrefptr;
         break;

      case DBTYPE_SQLVARIANT :
         * (SSVARIANT *) buffer_ptr = value.sql_variant;
         break;

      case DBTYPE_TABLE :
         // First check that the table has been defined.
         if (value.table->rowset_ptr != NULL) {
            * (IRowsetChange **) buffer_ptr = value.table->rowset_ptr;
         }
         else {
             olle_croak(olle_ptr,
                    "Cannot execute batch: %d column(s) left to define for table-valued parameter",
                     value.table->cols_undefined);
         }
         break;

      default :
         olle_croak(olle_ptr, "Internal error: unhandled type %d", typeind);
         break;
   }
}

// Retrieves a key value from the QH hash. The value must be defined, and
// a string value must not be the empty string.
static SV  * get_QN_hash(HV * hv,
                         const char * key)
{
   SV  ** svp;
   SV   * sv = NULL;
   SV   * ret = NULL;

   svp = hv_fetch(hv, key, (int) strlen(key), 0);
   if (svp != NULL) {
       sv = *svp;
   }
   if (my_sv_is_defined(sv)) {
      if (SvPOK(sv) && SvCUR(sv) >= 1) {
         ret = sv;
      }
      else if (! SvPOK(sv)) {
         ret = sv;
      }
   }

   return ret;
}

//-------------------------------------------------------------------
// set_rowset_properties, this is a subroutine to executebatch.
//-------------------------------------------------------------------
static void set_rowset_properties (SV           * olle_ptr,
                                   internaldata * mydata)
{
    IV                   optCommandTimeout = OptCommandTimeout(olle_ptr);
    HV                 * optQN = OptQueryNotification(olle_ptr);
    ICommandProperties * property_ptr;
    DBPROP               property[3];
    int                  no_of_props = 0;
    DBPROPSET            property_set[2];
    int                  no_of_propsets = 0;
    HRESULT              ret;

    if (optCommandTimeout > 0) {
       // There are a lot of properties in DBPROPSET_ROWSET, but we only care
       // about this single one.
       property[0].dwPropertyID = DBPROP_COMMANDTIMEOUT;
       property[0].dwOptions    = DBPROPOPTIONS_REQUIRED;
       property[0].colid        = DB_NULLID;
       VariantInit(&property[0].vValue);
       property[0].vValue.vt    = VT_I4;
       property[0].vValue.lVal  = (LONG) optCommandTimeout;

       property_set[0].guidPropertySet = DBPROPSET_ROWSET;
       property_set[0].cProperties     = 1;
       property_set[0].rgProperties    = property;

       no_of_propsets++;
    }

    // Check for query notification - but not if we run the nested
    // query to get the codepage.
    if (optQN && ! mydata->isnestedquery) {
       SV   * sv_service;
       SV   * sv_message;
       SV   * sv_timeout;

       no_of_props = 0;

       // First, see if there is a service. Only if there is a service we
       // will submit any query notification at all.
       sv_service = get_QN_hash(optQN, "Service");
       if (sv_service != NULL) {
          if (mydata->provider >= provider_sqlncli) {
             property[no_of_props].dwPropertyID = SSPROP_QP_NOTIFICATION_OPTIONS;
             property[no_of_props].dwOptions    = DBPROPOPTIONS_REQUIRED;
             property[no_of_props].colid        = DB_NULLID;
             VariantInit(&property[no_of_props].vValue);
             property[no_of_props].vValue.vt    = VT_BSTR;
             property[no_of_props].vValue.bstrVal  = SV_to_BSTR(sv_service);
             no_of_props++;
          }
          else if (PL_dowarn) {
             olledb_message(olle_ptr, -1, 1, 10,
                            L"QueryNotification option ignored when provider is SQLOLEDB.");
             sv_service = NULL;
          }
       }
       else if (PL_dowarn && SvTRUE(hv_scalar(optQN))) {
          // If there were other elements in the hash, the user has messed up.
          olledb_message(olle_ptr, -1, 1, 10,
                         L"The QueryNotification property had elements, but no Service element. No notification was submitted.");
       }

       // We must add a message, so if the user did not provide one, we will.
       sv_message = get_QN_hash(optQN, "Message");
       if (sv_service != NULL) {
          property[no_of_props].dwPropertyID = SSPROP_QP_NOTIFICATION_MSGTEXT;
          property[no_of_props].dwOptions    = DBPROPOPTIONS_REQUIRED;
          property[no_of_props].colid        = DB_NULLID;
          VariantInit(&property[no_of_props].vValue);
          property[no_of_props].vValue.vt    = VT_BSTR;
          property[no_of_props].vValue.bstrVal  =
              (sv_message != NULL ? SV_to_BSTR(sv_message) :
                             SysAllocString(L"Query notification set by Win32::SqlServer"));
          no_of_props++;
       }

       // The timeout on the other hand is optional.
       sv_timeout = get_QN_hash(optQN, "Timeout");
       if (sv_service != NULL && sv_timeout != NULL) {
          property[no_of_props].dwPropertyID = SSPROP_QP_NOTIFICATION_TIMEOUT;
          property[no_of_props].dwOptions    = DBPROPOPTIONS_REQUIRED;
          property[no_of_props].colid        = DB_NULLID;
          VariantInit(&property[no_of_props].vValue);
          property[no_of_props].vValue.vt    = VT_UI4;
          property[no_of_props].vValue.ulVal  = (ULONG) SvIV(sv_timeout);
          no_of_props++;
       }


       // Wipe out the hash.
       hv_clear(optQN);

       if (no_of_props > 0) {
          property_set[no_of_propsets].guidPropertySet = DBPROPSET_SQLSERVERROWSET;
          property_set[no_of_propsets].cProperties     = no_of_props;
          property_set[no_of_propsets].rgProperties    = property;

          no_of_propsets++;
       }
    }

    if (no_of_propsets > 0) {
       // Get a property pointer.
       ret = mydata->cmdtext_ptr->QueryInterface(IID_ICommandProperties,
                                                (void **) &property_ptr);
       check_for_errors(olle_ptr, "cmdtext_ptr->QueryInterface to create Property object", ret);

       ret = property_ptr->SetProperties(no_of_propsets, property_set);
       check_for_errors(NULL, "property_ptr->SetProperties for rowset props", ret);

       property_ptr->Release();
    }

    // We must free up memory allocated to the BSTRs in the QN propset.
    if (optQN) {
       for (int i = 0; i < no_of_props; i++) {
          VariantClear(&property[no_of_props].vValue);
       }
    }
}


//-------------------------------------------------------------------
// $X->executebatch.
//-------------------------------------------------------------------
int executebatch(SV   *olle_ptr,
                 SV   *sv_rows_affected)
{
    internaldata       * mydata = get_internaldata(olle_ptr);
    BOOL                 has_params = (mydata->no_of_params > 0);
    HRESULT              ret;
    paramdata          * current_param;
    DBPARAMBINDINFO    * cur_param_info;
    DBBINDING          * cur_binding;
    DB_UPARAMS         * param_ordinals;
    DBORDINAL            param_ix = 0;
    DBBYTEOFFSET         value_offset;
    DBBYTEOFFSET         len_offset;
    DBBYTEOFFSET         status_offset;
    BOOL                 final_retval = TRUE;
    ISessionProperties * sess_property_ptr;
    DBPROP               property[1];
    DBPROPSET            property_set[1];
    DBROWCOUNT           rows_affected;
    DBPARAMS             param_parameter;        // Parameter to cmdtext->Execute.
    SSPARAMPROPS       * ss_param_props = NULL;  // SQL-server specific parameter properies.
    DB_UPARAMS           ss_param_props_cnt = 0;

    // There must be no sesssion_ptr, this indicates that a previous command
    // has not been completely processed.
    if (mydata->cmdtext_ptr != NULL) {
       olle_croak(olle_ptr, "Cannot submit a new batch, when previous batch has not been processed");
    }

    // And check that we have a pending command to execute.
    if (mydata->pending_cmd == NULL) {
       olle_croak(olle_ptr, "There is no pending command to execute. Call initbatch first");
    }

    // Make sure that we have datasrc and session pointers set up.
    if (! setup_session(olle_ptr)) {
       return FALSE;
    }

    // If any input parameter failed, to convert, we are not letting you by.
    if (! mydata->all_params_OK) {
        olledb_message(olle_ptr, -1, 1, 16,
                       L"One or more parameters were not convertible. Cannot execute query.");
        free_batch_data(mydata);
        return FALSE;
    }

    // Commands with parameters require a whole lot more of works than
    // those with out.
    if (has_params) {
       // Allocate space for OLE DB's parameter structures and the parameter
       // buffer.
       New(902, mydata->param_info, mydata->no_of_params, DBPARAMBINDINFO);
       New(902, mydata->param_bindings, mydata->no_of_params, DBBINDING);
       New(902, param_ordinals, mydata->no_of_params, DB_UPARAMS);
       if (mydata->provider >= provider_sqlncli) {
          New(902, ss_param_props, mydata->no_of_params, SSPARAMPROPS);
       }

       // Allocate the parameter buffer and initiate it.
       New(902, mydata->param_buffer, mydata->size_param_buffer, BYTE);
       memset(mydata->param_buffer, 0, mydata->size_param_buffer);

       // Iterate over the list to copy the binding and parambindinfo structs,
       // set ordinals and and fill in values to the paramdata buffer.
       current_param  = mydata->paramfirst;
       cur_param_info = mydata->param_info;
       cur_binding    = mydata->param_bindings;
       while (current_param != NULL) {
          // Parameter ordinal.
          param_ordinals[param_ix] = param_ix + 1;

          // Copy structures
          cur_binding[param_ix]    = current_param->binding;
          cur_param_info[param_ix] = current_param->param_info;

          // Get offsets to use.
          value_offset  = current_param->binding.obValue;
          len_offset    = current_param->binding.obLength;
          status_offset = current_param->binding.obStatus;

          // And then fill in the parameter buffer, which is more work.
          if (current_param->isinput) {
             // Write status.
             DBSTATUS * status =
                 (DBSTATUS *) (&mydata->param_buffer[status_offset]);
             if (! current_param->isnull) {
               * status = DBSTATUS_S_OK;
             }
             else if (current_param->datatype == DBTYPE_TABLE) {
               * status = DBSTATUS_S_DEFAULT;
             }
             else {
                * status = DBSTATUS_S_ISNULL;
             }

             if (! current_param->isnull) {
             // If not NULL, we need to write input value.
                DBLENGTH * len_ptr = NULL;
                if (current_param->binding.dwPart & DBPART_LENGTH) {
                   len_ptr = (DBLENGTH *) (&mydata->param_buffer[len_offset]);
                   * len_ptr = current_param->value_len;
                }

                write_to_databuffer(olle_ptr, mydata->param_buffer,
                                    value_offset, current_param->datatype,
                                    current_param->value);

             }
             /* Good debug,
             wprintf(L"Param_name = %s, status = %d, value = %d.\n",
                  current_param->param_info.pwszName,
                  current_param->binding.obStatus,
                  current_param->binding.obValue);
            */

          }

          // Add parameter properties. These are not available with SQLOLEDB.
          if (current_param->param_props_cnt > 0 &&
              mydata->provider >= provider_sqlncli) {
              DBPROPSET  * propset;
              New(902, propset, 2 * current_param->param_props_cnt, DBPROPSET);
              propset->rgProperties = current_param->param_props;
              propset->cProperties = current_param->param_props_cnt;
              propset->guidPropertySet = DBPROPSET_SQLSERVERPARAMETER;
              ss_param_props[ss_param_props_cnt].rgPropertySets = propset;
              ss_param_props[ss_param_props_cnt].cPropertySets = 1;
              ss_param_props[ss_param_props_cnt].iOrdinal =
                  param_ordinals[param_ix];

              // If it's a table parameter with default values, there's
              // one more property.
              if (current_param->datatype == DBTYPE_TABLE &&
                  ! current_param->isnull &&
                  current_param->value.table->no_of_usedefault > 0) {
                  propset[1].rgProperties =
                       &(current_param->value.table->defcolprop);
                  propset[1].cProperties = 1;
                  propset[1].guidPropertySet = DBPROPSET_SQLSERVERPARAMETER;
                  ss_param_props[ss_param_props_cnt].cPropertySets++;
              }

              ss_param_props_cnt++;
          }

          // Move to next.
          current_param = current_param->next;
          param_ix++;
       }

       // Must allocate space for bindstatus.
       New(902, mydata->param_bind_status, mydata->no_of_params, DBBINDSTATUS);
    }   // if has_params

    // We need a property object for the session
    ret = mydata->session_ptr->QueryInterface(IID_ISessionProperties,
                                             (void **) &sess_property_ptr);
    check_for_errors(olle_ptr, "session_ptr->QueryInterface to create Property object", ret);

    // We always want the SQL Server-native representation of variant data.
    property[0].dwPropertyID   = SSPROP_ALLOWNATIVEVARIANT;
    property[0].dwOptions = DBPROPOPTIONS_REQUIRED;
    property[0].colid     = DB_NULLID;
    VariantInit(&property[0].vValue);
    property[0].vValue.vt      = VT_BOOL;
    property[0].vValue.boolVal = VARIANT_TRUE;

    property_set[0].guidPropertySet = DBPROPSET_SQLSERVERSESSION;
    property_set[0].cProperties     = 1;
    property_set[0].rgProperties    = property;

    ret = sess_property_ptr->SetProperties(1, property_set);
    check_for_errors(NULL, "property_ptr->SetProperties for ssvariant prop", ret);

    sess_property_ptr->Release();

    // Command-text interface.
    ret = mydata->session_ptr->CreateCommand(NULL, IID_ICommandText,
                                         (IUnknown **)  &(mydata->cmdtext_ptr));
    check_for_errors(olle_ptr, "session_ptr->CreateCommand for command-text object", ret);

    // Set rowset properties from Win32::SqlServer options.
    set_rowset_properties(olle_ptr, mydata);

    // Set the command text.
    ret = mydata->cmdtext_ptr->SetCommandText(DBGUID_SQL, mydata->pending_cmd);
    check_for_errors(olle_ptr, "cmdtext_ptr->SetCommandText", ret);

    // Again, extra stuff for commands with parameters
    if (has_params) {
       // Command-with-parameter interface
       ret = mydata->cmdtext_ptr->QueryInterface(IID_ICommandWithParameters,
                                             (void **) &(mydata->paramcmd_ptr));
       check_for_errors(olle_ptr, "cmdtext_ptr->QueryInterface for ICommandWithParameters", ret);

       // Set parameter info. Here we permit execution to proceed in case of
       // errors, as it could be user errors like using the xml datatype with
       // SQLEOLEDB.
       ret = mydata->paramcmd_ptr->SetParameterInfo(mydata->no_of_params,
                                                    param_ordinals,
                                                    mydata->param_info);
       check_for_errors(olle_ptr, "paramcmd_ptr->SetParameterInfo", ret,
                        FALSE);

       if (SUCCEEDED(ret) && ss_param_props_cnt > 0) {
          ret = mydata->cmdtext_ptr->QueryInterface(IID_ISSCommandWithParameters,
                                       (void **) &(mydata->ss_paramcmd_ptr));
          check_for_errors(olle_ptr, "paramcmd_ptr->QueryInterface for ISSCommandWithParameters", ret);
          ret = mydata->ss_paramcmd_ptr->SetParameterProperties(
                                  ss_param_props_cnt, ss_param_props);
          check_for_errors(olle_ptr, "ss_paramcmd_ptr->SetParameterProperties", ret);
       }

       if (SUCCEEDED(ret)) {
          // Get accessor interface.
          ret = mydata->paramcmd_ptr->QueryInterface(IID_IAccessor,
                                             (void **) &(mydata->paramaccess_ptr));
          check_for_errors(olle_ptr, "paramcmd->QueryInterace for IAccessor", ret);

          // And get the accessor itself.
          ret = mydata->paramaccess_ptr->CreateAccessor(
                DBACCESSOR_PARAMETERDATA, mydata->no_of_params,
                mydata->param_bindings, mydata->size_param_buffer,
                &(mydata->param_accessor), mydata->param_bind_status);
          check_for_errors(olle_ptr, "paramacces_ptr->CreateAccessor", ret);

          param_parameter.pData = mydata->param_buffer;
          param_parameter.cParamSets = 1;
          param_parameter.hAccessor = mydata->param_accessor;
       }
    }

	if (SUCCEEDED(ret)) {
       // Now execute the command. Again, proceed on all errors, so we get by
       // the famous "multi-step errors".
       ret = mydata->cmdtext_ptr->Execute(NULL, IID_IMultipleResults,
                                          (has_params ? &param_parameter : NULL),
                                          &rows_affected,
                                          (IUnknown **) &(mydata->results_ptr));
       check_for_errors(olle_ptr, "cmdtext_ptr->Execute", ret, FALSE);
    }

    // check_for_errors returns if the call fails, because one or
    // more parameter could not convert. We should not croak on this,
    // but we do cancel the batch.
    if (FAILED(ret)) {
       final_retval = FALSE;
       free_batch_data(mydata);
    }

    // Return rows_affected if required.
    if (sv_rows_affected != NULL) {
        sv_setiv(sv_rows_affected, rows_affected);
    }

    // Some cleaning up.
    if (has_params) {
       Safefree(param_ordinals);
    }

    if (ss_param_props != NULL) {
       for (DB_UPARAMS ix = 0; ix < ss_param_props_cnt; ix++) {
          Safefree(ss_param_props[ix].rgPropertySets);
       }
       Safefree(ss_param_props);
    }

    return final_retval;
}
