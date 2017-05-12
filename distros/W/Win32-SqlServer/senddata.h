/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/senddata.h 4     11-08-07 23:29 Sommar $

  Implements the routines for sending data and command to SQL Server:
  initbatch, enterparameter and executebatch, including routines to
  convert from Perl variables to SQL Server data types, save datetime
  data; those are in datetime.cpp.

  Copyright (c) 2004-2011   Erland Sommarskog

  $History: senddata.h $
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:29
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-04-28   Time: 23:12
 * Updated in $/Perl/OlleDB
 * maxlen was incorrectly ULONG or UINT when it should have been DBLENGTH.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-06   Time: 18:56
 * Updated in $/Perl/OlleDB
 * All the switch(datatype) for parameters and column in TVPs are now in
 * common code, and not duplicated in senddata and tableparam.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern BOOL SV_to_bigint (SV      * sv,
                          LONG64  &bigintval);


extern BOOL SV_to_binary (SV        * sv,
                          bin_options optBinaryAsStr,
                          BOOL        istimestamp,
                          BYTE      * &binaryval,
                          DBLENGTH    &value_len);

extern BOOL SV_to_char (SV       * sv,
                        char     * &charval,
                        DBLENGTH   &value_len);


extern BOOL SV_to_XML (SV        * sv,
                       BOOL        &is_8bit,
                       char      * &xmlchar,
                       BSTR        &xmlbstr,
                       DBLENGTH    &value_len);

extern BOOL SV_to_decimal(SV        * sv,
                          BYTE        precision,
                          BYTE        scale,
                          DB_NUMERIC &decimalval);

extern BOOL SV_to_GUID (SV       * sv,
                        GUID       &guidval);

extern BOOL SV_to_money(SV * sv,
                        CY  &moneyval);

extern BOOL SV_to_ssvariant (SV          * sv,
                             SSVARIANT     &variant,
                             SV          * olle_ptr,
                             provider_enum provider,
                             void        * &save_str,
                             BSTR          &save_bstr);

extern void complete_binding (DBTYPE           datatype,
                              const char     * nameoftype,
                              DBLENGTH         maxlen,
                              SV             * sv_scale,
                              SV             * sv_precision,
                              size_t          &size_buffer,
                              DBBINDING       * binding,
                              DBPARAMBINDINFO * param_info);

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
                      BSTR        &save_bstr);


void write_to_databuffer(SV           * olle_ptr,
                         BYTE         * buffer,
                         DBBYTEOFFSET   offset,
                         DBTYPE         typeind,
                         valueunion     value);


extern void initbatch(SV * olle_ptr,
                      SV * sv_cmdtext);

extern int enterparameter(SV   * olle_ptr,
                          SV   * sv_nameoftype,
                          SV   * sv_maxlen,
                          SV   * paramname,
                          BOOL   isinput,
                          BOOL   isoutput,
                          SV   * sv_value,
                          SV   * sv_precision,
                          SV   * sv_scale,
                          SV   * typeinfo);

extern int executebatch(SV   *olle_ptr,
                        SV   *sv_rows_affected);

