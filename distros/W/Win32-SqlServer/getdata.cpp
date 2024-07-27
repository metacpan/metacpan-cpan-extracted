/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/getdata.cpp 12    24-07-15 21:15 Sommar $

  Implements the routines for getting data and metadata from SQL Server:
  nextresultset, getcolumninfo, nextrow, getoutputparams. Includes routines
  to Server data types to Perl values, save datetime data; those are in
  datetime.cpp.

  Copyright (c) 2004-2024   Erland Sommarskog

  $History: getdata.cpp $
 * 
 * *****************  Version 12  *****************
 * User: Sommar       Date: 24-07-15   Time: 21:15
 * Updated in $/Perl/OlleDB
 * Updated year for copyright.
 * 
 * *****************  Version 11  *****************
 * User: Sommar       Date: 24-07-15   Time: 20:56
 * Updated in $/Perl/OlleDB
 * Reverted to the old behaviour for variant data, since the changes in
 * MSOLEDBSQL 18.4 apparently was a bug which they fixed in 18.6.3/19.1.0.
 * 
 * *****************  Version 10  *****************
 * User: Sommar       Date: 21-07-03   Time: 23:18
 * Updated in $/Perl/OlleDB
 * Starting with MSOLEDBSQL 18.4 varchar data for sql_variant always comes
 * back in the ANSI code page.
 * 
 * *****************  Version 9  *****************
 * User: Sommar       Date: 19-07-09   Time: 16:53
 * Updated in $/Perl/OlleDB
 * Reduce the number of warnings in 32-bit compiles a little.
 * 
 * *****************  Version 8  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:39
 * Updated in $/Perl/OlleDB
 * Added support  for UTF-8 (or more precisely any mix or collation).
 * (var)char columns are now bound as DBTYPE_WSTR so that we can always
 * retrieve without data loss. 
 * 
 * *****************  Version 7  *****************
 * User: Sommar       Date: 16-07-11   Time: 22:21
 * Updated in $/Perl/OlleDB
 * Modifications to avoid warnings with VS2015.
 * 
 * *****************  Version 6  *****************
 * User: Sommar       Date: 15-05-24   Time: 21:06
 * Updated in $/Perl/OlleDB
 * Replaced check on _WIN64 with USE_64_BIT_INT, so that it works with
 * 64-integers on 32-bit Perl.
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:24
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64.
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 11-07-29   Time: 23:27
 * Updated in $/Perl/OlleDB
 * Fixed bug that caused sql_variant with empty varchar strings to be
 * returned incorrectly.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-01-07   Time: 0:22
 * Updated in $/Perl/OlleDB
 * Fixed bug that cause handling of duplicate column names to stop
 * working.
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
#include "datetime.h"
#include "getdata.h"




//====================================================================
// Get data from SQL Server. First $X->nextresultset, then getcolumninfo,
// then conversion routines to from SQL Server types to SV, then extract_data,
// a common helper to $X->nextrow and $X->outputparamerers.
//====================================================================
int nextresultset (SV * olle_ptr,
                   SV * sv_rows_affected)
{
    internaldata * mydata = get_internaldata(olle_ptr);
    DBROWCOUNT     rows_affected;
    int            more_results;
    HRESULT        ret;
    IColumnsInfo*  columns_info_ptr  = NULL;
    DBORDINAL      no_of_cols;
    DBBYTEOFFSET   bind_offset = 0;

    // There must not a cmttext_ptr, else there is no command being processed.
    if (mydata->cmdtext_ptr == NULL) {
       olle_croak(olle_ptr, "Cannot call nextresultset without an active command. Call executebatch first");
    }

    // If there are unfetched rows in the previous result set, this is an
    // error.
    if (mydata->rowset_ptr != NULL) {
       olle_croak(olle_ptr, "Cannot call nextresultset with unfetched rows. Call nextrow to get all rows, or call cancelresulset");
    }

    // We are not guaranteed to have a results pointer, but this condition
    // means that there are no more results.
    if (mydata->results_ptr == NULL) {
       more_results = FALSE;
    }
    else {
       // Get next result set. The assumption is here that if we get an
       // SQL error we should continue and give caller what we have. Other
       // errors should lead to a immiedate stop, and we assume that we
       // sooner or later get a DB_S_NORESULT.
       ret = mydata->results_ptr->GetResult(NULL, 0, IID_IRowset, &rows_affected,
                                          (IUnknown **) &(mydata->rowset_ptr));
       check_for_errors(olle_ptr, "results_ptr->GetResults", ret);
       more_results = (ret != DB_S_NORESULT);
    }

    // Do we now have an active result set?
    mydata->have_resultset = more_results;

    // A result set usually comes with a rowset, but it is just a count or
    // a message, it does not.
    if (more_results && mydata->rowset_ptr != NULL) {
       // Get ColumnsInfo interface.
       ret = mydata->rowset_ptr->QueryInterface(IID_IColumnsInfo,
                                                (void **) &columns_info_ptr);
       check_for_errors(olle_ptr,
                        "rowset_ptr->QueryInterface for column info", ret);
       // Get columninfo buffer.
       ret = columns_info_ptr->GetColumnInfo(&no_of_cols,
                                             &(mydata->column_info),
                                             &(mydata->colname_buffer));
       check_for_errors(olle_ptr, "columns_info_ptr->GetColumnInfo", ret);
       mydata->no_of_cols = (ULONG) no_of_cols;
       // Don't need this interface any more.
       columns_info_ptr->Release();

       // We need the col_binding array.
       New(902, mydata->col_bindings, no_of_cols, DBBINDING);
       // Iterate over the columns to set up the bindings.
       for (DBORDINAL j = 0; j < no_of_cols; j++) {
          // TGhere is an issue with UTF8 and SQLOLEDB and varchar > 4000. SQL Server
          // reports this as MAX, i.e. -1(?), but it comes back as 32767. Later this
          // causes GetNextRow to hang. To avoid this, we commit explicit suicide.
          if (mydata->column_info[j].ulColumnSize == 32767 &&
              mydata->provider == provider_sqloledb) {
             // And it has to be croak, and not olle_croak, as sometimes it 
             // hangs when releasing allocated objects.
             croak("For column %d, SQL Server reported a size of %d. This is known to happen with UTF-8 for (var)char > 4000 and SQLOLEDB.\n",
                   j + 1, mydata->column_info[j].ulColumnSize);
          }

          // These fields are the same for all data types.
          mydata->col_bindings[j].iOrdinal  = j+1;
          mydata->col_bindings[j].dwMemOwner = DBMEMOWNER_CLIENTOWNED;
          mydata->col_bindings[j].pTypeInfo = NULL;
          mydata->col_bindings[j].pObject   = NULL;
          mydata->col_bindings[j].pBindExt  = NULL;
          mydata->col_bindings[j].dwFlags   = 0;
          mydata->col_bindings[j].eParamIO  = DBPARAMIO_NOTPARAM;
          mydata->col_bindings[j].cbMaxLen  = 0;   // For those where it ignoreed.
          mydata->col_bindings[j].wType     = mydata->column_info[j].wType; // BYREF may be added later.

          // We always bind status and value.
          mydata->col_bindings[j].dwPart    = DBPART_VALUE | DBPART_STATUS;
          mydata->col_bindings[j].obStatus  = bind_offset;
          bind_offset += sizeof(DBSTATUS);
          mydata->col_bindings[j].obValue   = bind_offset;

          // The rest depends on the data type.
          switch (mydata->column_info[j].wType) {
             case DBTYPE_BOOL :
                bind_offset += sizeof(BOOL);
                break;

             case DBTYPE_UI1 :
                bind_offset += 1;
                break;

             case DBTYPE_I2 :
                bind_offset += 2;
                break;

             case DBTYPE_I4 :
                bind_offset += 4;
                break;

             case DBTYPE_R4 :
                bind_offset += 4;
                break;

             case DBTYPE_R8 :
                bind_offset += 8;
                break;

             case DBTYPE_I8 :
                bind_offset += 8;
                break;

             case DBTYPE_CY :
                bind_offset += sizeof(CY);
                break;

             case DBTYPE_NUMERIC :
                mydata->col_bindings[j].bPrecision =
                    mydata->column_info[j].bPrecision;
                mydata->col_bindings[j].bScale     =
                    mydata->column_info[j].bScale;
                bind_offset += sizeof(DB_NUMERIC);
                break;

             case DBTYPE_GUID :
                bind_offset += sizeof(GUID);
                break;

             case DBTYPE_DBDATE :
                bind_offset += sizeof(DBDATE);
                break;

             case DBTYPE_DBTIME2 :
                mydata->col_bindings[j].bPrecision =
                    mydata->column_info[j].bPrecision;
                mydata->col_bindings[j].bScale     =
                    mydata->column_info[j].bScale;
                bind_offset += sizeof(DBTIME2);
                break;

             case DBTYPE_DBTIMESTAMP :
                mydata->col_bindings[j].bPrecision =
                    mydata->column_info[j].bPrecision;
                mydata->col_bindings[j].bScale     =
                    mydata->column_info[j].bScale;
                bind_offset += sizeof(DBTIMESTAMP);
                break;

             case DBTYPE_DBTIMESTAMPOFFSET :
                mydata->col_bindings[j].bPrecision =
                    mydata->column_info[j].bPrecision;
                mydata->col_bindings[j].bScale     =
                    mydata->column_info[j].bScale;
                bind_offset += sizeof(DBTIMESTAMPOFFSET);
                break;

             case DBTYPE_UDT   :
             case DBTYPE_BYTES :
                mydata->col_bindings[j].wType    |= DBTYPE_BYREF;
                bind_offset += sizeof(BYTE *);
                mydata->col_bindings[j].dwPart   |= DBPART_LENGTH;
                mydata->col_bindings[j].obLength  = bind_offset;
                bind_offset += sizeof(DBLENGTH);
                break;

             case DBTYPE_STR :
             // We actually receive as WSTR to be handle all collations.
                mydata->col_bindings[j].wType    = DBTYPE_WSTR | DBTYPE_BYREF;
                bind_offset += sizeof(WCHAR *);
                mydata->col_bindings[j].dwPart   |= DBPART_LENGTH;
                mydata->col_bindings[j].obLength  = bind_offset;
                bind_offset += sizeof(DBLENGTH);
                break;

             case DBTYPE_SQLVARIANT :
                bind_offset += sizeof(SSVARIANT);
                break;

             case DBTYPE_XML :
                mydata->col_bindings[j].wType    |= DBTYPE_BYREF;
                bind_offset += sizeof(WCHAR *);
                mydata->col_bindings[j].dwPart   |= DBPART_LENGTH;
                mydata->col_bindings[j].obLength  = bind_offset;
                bind_offset += sizeof(DBLENGTH);
                break;

             case DBTYPE_WSTR :
             default          :
                if (mydata->column_info[j].wType != DBTYPE_WSTR) {
                   warn("Warning: Unexpected datatype %d, handled as nvarchar.",
                        mydata->column_info[j].wType);
                   mydata->col_bindings[j].wType = DBTYPE_WSTR;
                   mydata->column_info[j].wType = DBTYPE_WSTR;
                }
                mydata->col_bindings[j].wType     |= DBTYPE_BYREF;
                bind_offset += sizeof(WCHAR *);
                mydata->col_bindings[j].dwPart    |= DBPART_LENGTH;
                mydata->col_bindings[j].obLength   = bind_offset;
                bind_offset += sizeof(DBLENGTH);
                break;
          }
       }

       // Save the final offset and allocate space for data buffer.
       mydata->size_data_buffer = bind_offset;
       New(902, mydata->data_buffer, bind_offset, BYTE);

       // Get the accessor interface.
       ret = mydata->rowset_ptr->QueryInterface(IID_IAccessor,
                                    (void **) &(mydata->rowaccess_ptr));
       check_for_errors(olle_ptr,
                        "rowset_ptr->QueryInterface for row accessor", ret);

       // Must allocate space for DBBINDSTATUS.
       New(902, mydata->col_bind_status, no_of_cols, DBBINDSTATUS);
       ret = mydata->rowaccess_ptr->CreateAccessor(DBACCESSOR_ROWDATA,
                                                   no_of_cols,
                                                   mydata->col_bindings, 0,
                                                   &(mydata->row_accessor),
                                                   mydata->col_bind_status);
       check_for_errors(olle_ptr, "rowaccess_ptr->CreateAccessor", ret);
    }
    else if (! more_results) {
       if (mydata->no_of_out_params == 0) {
          // If there are no output parameters, we can free resources bound
          // the by current batch here and now.
          free_batch_data(mydata);
       }
       else {
         // Else just make output parameters available.
         mydata->params_available = TRUE;
       }
    }

    // Return rows_affected if required.
    if (sv_rows_affected != NULL) {
        sv_setiv(sv_rows_affected, rows_affected);
    }

    return more_results;
}

//----------------------------------------------------------------------
// Some helper routines for getcolumninfo and nextrow to handle the output
// hash and array.
//------------------------------------------------------------------------
static void allocate_return_areas(internaldata   * mydata,
                                  BOOL             have_hash,
                                  BOOL             have_array,
                                  SV            *  hashref,
                                  SV            *  arrayref,
                                  HV            *  &return_hash,
                                  AV            *  &return_array)
{
    if (have_hash) {
       return_hash = newHV();
       sv_setsv(hashref, sv_2mortal(newRV_noinc((SV*) return_hash)));

       // Allocate an SV per key. Key names are usually the column name, but
       // if there is no name, or dups, we have to do it ourselves. We save
       // the keys in mydata, to allocate them only once per result set.
       if (mydata->column_keys == NULL) {
          New(902, mydata->column_keys, mydata->no_of_cols, SV*);
          memset(mydata->column_keys, 0, mydata->no_of_cols * sizeof(SV*));

          for (DBORDINAL colno = 0; colno < mydata->no_of_cols; colno++) {
            SV * colkey;

            if (wcslen(mydata->column_info[colno].pwszName) > 0) {
               // There is a column name, lets use it.
               colkey = BSTR_to_SV(mydata->column_info[colno].pwszName);
            }
            else {
               // Anonymous column, construct a default name.
               char  tmp[20];
#ifdef WIN64
               sprintf_s(tmp, 20, "Col %lld", colno + 1);
#else
               sprintf_s(tmp, 20, "Col %d", colno + 1);
#endif
               colkey = newSVpv(tmp, strlen(tmp));
            }

            // Check for duplicates and iterate till we have one, but
            // we don't try forever.
            char c = '@';
            while (hv_exists_ent(return_hash, colkey, 0) && c++ <= 'Z') {
               if (PL_dowarn) {
                  warn("Column name '%s' appears twice or more in the result set",
                       SvPV_nolen(colkey));
               }
               SvREFCNT_dec(colkey);
               char  tmp[20];
#ifdef WIN64
               sprintf_s(tmp, 20, "Col %lld%c", colno + 1, c);
#else
               sprintf_s(tmp, 20, "Col %d%c", colno + 1, c);
#endif  
               colkey = newSVpv(tmp, strlen(tmp));
            }

            // Save the key value.
            mydata->column_keys[colno] = colkey;

            // Create a hash entry, so that we can check for name duplicates.
            hv_store_ent(return_hash, colkey, &PL_sv_undef, 0);
          }
       }
    }

    if (have_array) {
       return_array = newAV();
       av_extend(return_array, mydata->no_of_cols);
       sv_setsv(arrayref, sv_2mortal(newRV_noinc((SV*) return_array)));
    }
}


//----------------------------------------------------------------------
// $X->getcolumninfo
//----------------------------------------------------------------------
void getcolumninfo (SV   * olle_ptr,
                    SV   * hashref,
                    SV   * arrayref)
{
    internaldata * mydata = get_internaldata(olle_ptr);
    BOOL           have_hash;
    BOOL           have_array;
    HV           * return_hash;
    AV           * return_array;

     // Check that we have a active result set.
    if (! mydata->have_resultset) {
        olle_croak (olle_ptr, "Call to getcolumninfo without active result set. Call nextresults first");
    }

    // What references did we get?
    have_hash  = (hashref  != NULL && ! SvREADONLY(hashref));
    have_array = (arrayref != NULL && ! SvREADONLY(arrayref));

    // But the result set may be empty and without a rowset ptr. In such
    // case we just drop out.
    if (mydata->rowset_ptr == NULL) {
       if (have_hash) {
          sv_setsv(hashref, &PL_sv_undef);
       }
       if (have_array) {
          sv_setsv(arrayref, &PL_sv_undef);
       }
       return;
    }

    // Create the Perl hash and/or array for returning the data.
    allocate_return_areas(mydata, have_hash, have_array,
                          hashref, arrayref, return_hash, return_array);

    // Iterate over all columns.
    for (ULONG j = 0; j < mydata->no_of_cols; j++) {
        DBCOLUMNINFO * colinfo = &mydata->column_info[j];

        // A hash with information about this column.
        HV * hv = newHV();

        // Position, name, length, precision and scale. Note that we don't
        // create any names here, but blank and dups are accepted.
        SV * sv_colno     = newSViv(j + 1);
        SV * sv_colname   = BSTR_to_SV(colinfo->pwszName);
        SV * sv_maxlength = (colinfo->dwFlags & DBCOLUMNFLAGS_ISLONG ?
                                newSVsv(&PL_sv_undef) :
                                newSViv(colinfo->ulColumnSize));
        SV * sv_precision = colinfo->bPrecision != (BYTE) ~0    ?
                               newSViv(colinfo->bPrecision) :
                               newSVsv(&PL_sv_undef);
        SV * sv_scale     = colinfo->bScale != (BYTE) ~0 ?
                               newSViv(colinfo->bScale) :
                               newSVsv(&PL_sv_undef);
        SV * sv_maybenull =
            newSViv(colinfo->dwFlags & DBCOLUMNFLAGS_MAYBENULL ? 1 : 0);
        SV * sv_readonly =
            newSViv(colinfo->dwFlags &
                    (DBCOLUMNFLAGS_WRITE | DBCOLUMNFLAGS_WRITEUNKNOWN) ?
                     0 : 1);

        // To get the type, we need to run a switch. We store the name in a
        // local variable first.
        char     * datatypestr;
        SV       * sv_datatype  = NULL;

        // Set name and other info depending on data type.
        switch (colinfo->wType) {
           case DBTYPE_BOOL :
              datatypestr = "bit";
              break;

           case DBTYPE_UI1 :
              datatypestr = "tinyint";
              break;

           case DBTYPE_I2 :
              datatypestr = "smallint";
              break;

           case DBTYPE_I4 :
              datatypestr = "int";
              break;

           case DBTYPE_R4 :
              datatypestr = "real";
              break;

           case DBTYPE_R8 :
              datatypestr = "float";
              break;

           case DBTYPE_I8 :
              datatypestr = "bigint";
              break;

           case DBTYPE_CY :
              if (colinfo->bPrecision < 18) {
                 datatypestr = "smallmoney";
              }
              else {
                 datatypestr = "money";
              }
              break;

           case DBTYPE_NUMERIC :
              datatypestr = "decimal";
              break;

           case DBTYPE_GUID :
              datatypestr = "uniqueidentifier";
              break;

           case DBTYPE_DBDATE :
              datatypestr = "date";
              break;

           case DBTYPE_DBTIME2 :
              datatypestr = "time";
              break;

           case DBTYPE_DBTIMESTAMP :
           // This is a little tricky. With SQL Native Client 10, we can't
           // tell the difference between datetime and datetime2, so we
           // assume the latter. But for easlier versions of SQL Server we
           // should not present a data type that does not exist in that version.
              if (colinfo->bPrecision == 16) {
                  datatypestr = "smalldatetime";
              }
              else if (mydata->majorsqlversion >= 10 &&
                       mydata->provider >= provider_sqlncli10) {
                  datatypestr = "datetime2";
              }
              else {
                  datatypestr = "datetime";
              }
              break;

           case DBTYPE_DBTIMESTAMPOFFSET :
              datatypestr = "datetimeoffset";
              break;

           case DBTYPE_UDT   :
              datatypestr = "UDT";
              break;

           case DBTYPE_BYTES :
              if (colinfo->dwFlags & DBCOLUMNFLAGS_ISROWVER) {
                 datatypestr = "timestamp";
              }
              else if (colinfo->dwFlags & DBCOLUMNFLAGS_ISFIXEDLENGTH) {
                 datatypestr = "binary";
              }
              else {
                 datatypestr = "varbinary";
              }
              break;

           case DBTYPE_STR :
              if (colinfo->dwFlags & DBCOLUMNFLAGS_ISFIXEDLENGTH) {
                 datatypestr = "char";
              }
              else {
                 datatypestr = "varchar";
              }
              break;

           case DBTYPE_SQLVARIANT :
              datatypestr = "sql_variant";
              break;

           case DBTYPE_XML :
              datatypestr = "xml";
              break;

           case DBTYPE_WSTR :
              if (colinfo->dwFlags & DBCOLUMNFLAGS_ISFIXEDLENGTH) {
                 datatypestr = "nchar";
              }
              else {
                 datatypestr = "nvarchar";
              }
              break;

           default          :
              datatypestr = "UNKNOWN!";
              break;
        }

        sv_datatype = newSVpvn(datatypestr, strlen(datatypestr));

        // Save keys into the hash.
        hv_store(hv, "Colno",     (I32) strlen("Colno"),     sv_colno, 0);
        hv_store(hv, "Name",      (I32) strlen("Name"),      sv_colname, 0);
        hv_store(hv, "Type",      (I32) strlen("Type"),      sv_datatype, 0);
        hv_store(hv, "Maxlength", (I32) strlen("Maxlength"), sv_maxlength, 0);
        hv_store(hv, "Precision", (I32) strlen("Precision"), sv_precision, 0);
        hv_store(hv, "Scale",     (I32) strlen("Scale"),     sv_scale, 0);
        hv_store(hv, "Maybenull", (I32) strlen("Maybenull"), sv_maybenull, 0);
        hv_store(hv, "Readonly",  (I32) strlen("Readonly"),  sv_readonly, 0);

        // Create a hash reference.
        SV * hvref = newSV(NULL);
        sv_setsv(hvref, sv_2mortal(newRV_noinc((SV *) hv)));

        // And save the reference in the return hash.
        if (have_hash) {
           hv_store_ent(return_hash, mydata->column_keys[j], hvref, 0);
        }

        // And save to the array. Note that if we save in both hash and
        // array, we need to bump the reference count.
        if (have_array) {
           if (have_hash) {
              SvREFCNT_inc(hvref);
           }
           av_store(return_array, j, hvref);
        }
    }
}

//---------------------------------------------------------------------
// Conversion-to-SV routines. These routines convert a non-trivial value
// from SQL Server a suitable SV. In most cases there is an option that
// determines the datatype/format for the Perl value.
//---------------------------------------------------------------------
static SV * bigint_to_SV (LONG64        bigintval,
                          formatoptions opts)
{
#ifdef USE_64_BIT_INT
   // On Win64, we return bigint as any other integer.
   return newSViv (bigintval);
#else
   // On 32-bit, we treat bigint just like we treat decimal.
   if (opts.DecimalAsStr) {
      char str[25];
      sprintf_s(str, 25, "%I64d", bigintval);
      return newSVpv(str, 0);
   }
   else {
      return newSVnv((double) bigintval);
   }
#endif
}

static SV * binary_to_SV (BYTE         * binaryval,
                          DBLENGTH      len,
                          formatoptions opts)
{
   SV   * perl_value;

   if (opts.BinaryAsStr != bin_binary) {
       DBLENGTH         strlen;
       char           * strsans0x;
       char           * str0x;
       DBSTATUS         strstatus;
       HRESULT          ret;

       New(902, strsans0x, 2 * len + 1, char);

       ret = data_convert_ptr->DataConvert(
             DBTYPE_BYTES, DBTYPE_STR, len, &strlen,
             binaryval, strsans0x, 2 * len + 1, DBSTATUS_S_OK, &strstatus,
             NULL, NULL, 0);
       check_convert_errors("Convert binary-to-str", strstatus, ret);

       if (opts.BinaryAsStr == bin_string0x) {
          New(902, str0x, strlen + 3, char);
          sprintf_s(str0x, strlen + 3, "0x%s", strsans0x);
          perl_value = newSVpvn(str0x, strlen + 2);
          Safefree(str0x);
       }
       else {
          perl_value = newSVpvn(strsans0x, strlen);
       }
       Safefree(strsans0x);
   }
   else {
       perl_value = newSVpvn((char *) binaryval, len);
   }

   return perl_value;
}

static SV * bit_to_SV (VARIANT_BOOL bitval)
{
   return newSViv(bitval == 0 ? 0 : 1);
}

static SV * decimal_to_SV (DB_NUMERIC    decimalval,
                           formatoptions opts)
{
   DBLENGTH       sstrlen;
   char           str[50];
   DBSTATUS       status;
   HRESULT        ret;

   if (opts.DecimalAsStr) {
      ret = data_convert_ptr->DataConvert(
            DBTYPE_NUMERIC, DBTYPE_STR, sizeof(DB_NUMERIC), &sstrlen,
            &decimalval, &str, 50, DBSTATUS_S_OK, &status, NULL, NULL, 0);
      check_convert_errors("Convert decimal-to-str", status, ret);

      return newSVpvn(str, sstrlen);
   }
   else {
      double dbl;

      ret = data_convert_ptr->DataConvert(
           DBTYPE_NUMERIC, DBTYPE_R8, sizeof(DB_NUMERIC), NULL,
           &decimalval, &dbl, NULL, DBSTATUS_S_OK, &status, NULL, NULL, 0);
      check_convert_errors("Convert decimal-to-float", status, ret);

      return newSVnv(dbl);
   }
}


static SV * GUID_to_SV (GUID    guid)
{
    DBLENGTH  strlen;
    char      str[40];
    DBSTATUS  strstatus;
    HRESULT   ret;

    ret = data_convert_ptr->DataConvert(DBTYPE_GUID, DBTYPE_STR, sizeof(GUID),
                                        &strlen, &guid, &str, 40,
                                        DBSTATUS_S_OK, &strstatus,
                                        NULL, NULL, 0);
    check_convert_errors ("Convert GUID to STR", strstatus, ret);

    return newSVpvn(str, strlen);
}


static SV * money_to_SV (CY            moneyval,
                         formatoptions opts)
{
    DBLENGTH       sstrlen;
    char           str[50];
    DBSTATUS       status;
    HRESULT        ret;

    if (opts.DecimalAsStr) {
       ret = data_convert_ptr->DataConvert(
             DBTYPE_CY, DBTYPE_STR, sizeof(CY), &sstrlen,
             &moneyval, &str, 50, DBSTATUS_S_OK, &status, NULL, NULL, 0);
       check_convert_errors("Convert money-to-str", status, ret);

       return newSVpvn(str, sstrlen);
    }
    else {
       double dbl;

       ret = data_convert_ptr->DataConvert(
            DBTYPE_CY, DBTYPE_R8, sizeof(CY), NULL,
            &moneyval, &dbl, NULL, DBSTATUS_S_OK, &status, NULL, NULL, 0);
       check_convert_errors("Convert money-to-float", status, ret);

       return newSVnv(dbl);
    }
}


static SV * ssvariant_to_SV(SV          * olle_ptr,
                            SSVARIANT     ssvar,
                            formatoptions opts)
{
   SV * perl_value;

   switch (ssvar.vt) {
      case VT_SS_EMPTY :
      case VT_SS_NULL  :
         perl_value = newSVsv(&PL_sv_undef);
         break;

      case VT_SS_UI1 :
         perl_value = newSViv(ssvar.bTinyIntVal);
         break;

      case VT_SS_I2 :
         perl_value = newSViv(ssvar.sShortIntVal);
         break;

      case VT_SS_I4 :
         perl_value = newSViv(ssvar.lIntVal);
         break;

      case VT_SS_I8 :
         perl_value = bigint_to_SV(ssvar.llBigIntVal, opts);
         break;

      case VT_SS_R4 :
         perl_value = newSVnv(ssvar.fltRealVal);
         break;

      case VT_SS_R8 :
         perl_value = newSVnv(ssvar.dblFloatVal);
         break;

      case VT_SS_MONEY :
      case VT_SS_SMALLMONEY :
         perl_value = money_to_SV(ssvar.cyMoneyVal, opts);
         break;

       case VT_SS_WSTRING    :
       case VT_SS_WVARSTRING :
          perl_value = BSTR_to_SV(ssvar.NCharVal.pwchNCharVal,
                                  ssvar.NCharVal.sActualLength / 2);
          OLE_malloc_ptr->Free(ssvar.NCharVal.pwchNCharVal);
          if (ssvar.NCharVal.pwchReserved != NULL) {
             OLE_malloc_ptr->Free(ssvar.NCharVal.pwchReserved);
          }
          break;

       case VT_SS_STRING    :
       case VT_SS_VARSTRING : {
             UINT codepage = OptCurrentCodepage(olle_ptr);
             if (codepage == GetACP() && codepage != CP_UTF8) {
                perl_value = newSVpvn(ssvar.CharVal.pchCharVal,
                                      ssvar.CharVal.sActualLength);
             }
             else {
                perl_value = char_to_UTF8_SV(ssvar.CharVal.pchCharVal,
                                             ssvar.CharVal.sActualLength,
                                             codepage);
             }
             OLE_malloc_ptr->Free(ssvar.CharVal.pchCharVal);
             if (ssvar.NCharVal.pwchReserved != NULL) {
                OLE_malloc_ptr->Free(ssvar.NCharVal.pwchReserved);
             }
          }
          break;

       case VT_SS_BIT  :
          perl_value = bit_to_SV(ssvar.fBitVal);
          break;

       case VT_SS_GUID : {
          GUID guid;
          memcpy(&guid, ssvar.rgbGuidVal, 16);
          perl_value = GUID_to_SV(guid);
          break;
       }

       case VT_SS_NUMERIC :
       case VT_SS_DECIMAL :
          perl_value = decimal_to_SV(ssvar.numNumericVal, opts);
          break;

       case VT_SS_DATE :
          perl_value = date_to_SV(olle_ptr, ssvar.dDateVal, opts);
          break;

       case VT_SS_TIME2     :
          perl_value = time_to_SV(olle_ptr, ssvar.Time2Val.tTime2Val, opts,
                                  (ssvar.Time2Val.bScale == 0 ? 8 :
                                   ssvar.Time2Val.bScale + 9),
                                   ssvar.Time2Val.bScale);
          break;

       case VT_SS_DATETIME      :
          perl_value = datetime_to_SV(olle_ptr, ssvar.tsDateTimeVal,
                                      opts, 23, 3);
          break;

       case VT_SS_DATETIME2     :
          perl_value = datetime_to_SV(olle_ptr, ssvar.DateTimeVal.tsDateTimeVal,
                                      opts,
                                      (ssvar.DateTimeVal.bScale == 0 ? 19 :
                                       ssvar.DateTimeVal.bScale + 20),
                                       ssvar.DateTimeVal.bScale);
          break;

       case VT_SS_SMALLDATETIME :
          perl_value = datetime_to_SV(olle_ptr, ssvar.tsDateTimeVal,
                                      opts, 16, 0);
          break;

       case VT_SS_DATETIMEOFFSET   :
          perl_value = datetimeoffset_to_SV(
                                  olle_ptr,
                                  ssvar.DateTimeOffsetVal.tsoDateTimeOffsetVal,
                                  opts,
                                  (ssvar.DateTimeOffsetVal.bScale == 0 ? 26 :
                                   ssvar.DateTimeOffsetVal.bScale + 27),
                                  ssvar.DateTimeOffsetVal.bScale);
          break;


       case VT_SS_BINARY    :
       case VT_SS_VARBINARY :
          perl_value = binary_to_SV(ssvar.BinaryVal.prgbBinaryVal,
                                    ssvar.BinaryVal.sActualLength, opts);
          OLE_malloc_ptr->Free(ssvar.BinaryVal.prgbBinaryVal);
          break;

       default : {
          char str[50];
          sprintf_s(str, 50, "Unsupported value for SSVARIANT.vt: %d", ssvar.vt);
          perl_value = newSVpv(str, 0);
          break;
       }
   }

   return perl_value;
}


//-----------------------------------------------------------------------
// This routine converts a column/parameter value from the the data buffer
// with help of the binding information into an SV. This one is called both
// from nextrow and getoutputparameters.
//------------------------------------------------------------------------
static void extract_data(SV           * olle_ptr,
                         formatoptions  opts,
                         BOOL           is_param,
                         BSTR           valuename,
                         DBTYPE         datatype,
                         DBBINDING      binding,
                         DBBINDSTATUS   bind_status,
                         BYTE         * data_buffer,
                         SV           * &perl_value)
{

    DBSTATUS       value_status = *((DBSTATUS *) &data_buffer[binding.obStatus]);
    DBBYTEOFFSET   value_offset = binding.obValue;
    DBLENGTH       value_len = 0;

    if (binding.dwPart & DBPART_LENGTH) {
       value_len = * ((DBBYTEOFFSET *) &data_buffer[binding.obLength]);
    }

    /* {
                    char * str =  * ((char **) &data_buffer[value_offset]);
                    wprintf(L"datatype = %d, datastr_ptr = %x '%s'\n", datatype, str, valuename);
    } */

    switch (value_status) {
       case DBSTATUS_S_ISNULL :
            perl_value = newSVsv(&PL_sv_undef);
            break;

       case DBSTATUS_S_TRUNCATED : {
            char * tmp = BSTR_to_char(valuename);
            warn("Value of column/parameter '%s' was truncated.", tmp);
            Safefree(tmp);
       }
            // fall-through.
       case DBSTATUS_S_OK :
          switch (datatype) {
             case DBTYPE_BOOL      : {
                BOOL value = * ((BOOL *) &data_buffer[value_offset]);
                perl_value = bit_to_SV(value);
                break;
             }

             case DBTYPE_UI1       : {
                unsigned char value =
                     * ((unsigned char *) &data_buffer[value_offset]);
                perl_value = newSViv(value);
                break;
             }

             case DBTYPE_I2        : {
                short value = * ((short *) &data_buffer[value_offset]);
                perl_value = newSViv(value);
                break;
             }

             case DBTYPE_I4        :  {
                INT32 value = * ((INT32 *) &data_buffer[value_offset]);
                perl_value = newSViv(value);
                break;
             }

             case DBTYPE_R4       : {
                float value = * ((float *) &data_buffer[value_offset]);
                perl_value = newSVnv(value);
                break;
             }

             case DBTYPE_R8       : {
                double value = * ((double *) &data_buffer[value_offset]);
                perl_value = newSVnv(value);
                break;
             }

             case DBTYPE_I8       : {
                LONG64 value = * ((LONG64 *) &data_buffer[value_offset]);
                perl_value = bigint_to_SV(value, opts);
                break;
             }

             case DBTYPE_CY       : {
                CY value = * ((CY *) &data_buffer[value_offset]);
                perl_value = money_to_SV(value, opts);
                break;
             }

             case DBTYPE_NUMERIC  : {
                DB_NUMERIC value = * ((DB_NUMERIC *) &data_buffer[value_offset]);
                perl_value = decimal_to_SV(value, opts);
                break;
             }

             case DBTYPE_DBDATE : {
                DBDATE value = * ((DBDATE *) &data_buffer[value_offset]);
                perl_value = date_to_SV(olle_ptr, value, opts);
                break;
             }

             case DBTYPE_DBTIME2 : {
                DBTIME2 value = * ((DBTIME2 *) &data_buffer[value_offset]);
                perl_value = time_to_SV(olle_ptr, value, opts,
                                        binding.bPrecision, binding.bScale);
                break;
             }

             case DBTYPE_DBTIMESTAMP : {
                DBTIMESTAMP value = * ((DBTIMESTAMP *) &data_buffer[value_offset]);
                perl_value = datetime_to_SV(olle_ptr, value, opts,
                                            binding.bPrecision, binding.bScale);
                break;
             }

             case DBTYPE_DBTIMESTAMPOFFSET : {
                DBTIMESTAMPOFFSET value =
                     * ((DBTIMESTAMPOFFSET *) &data_buffer[value_offset]);
                perl_value = datetimeoffset_to_SV(olle_ptr, value, opts,
                                            binding.bPrecision, binding.bScale);
                break;
             }

             case DBTYPE_GUID : {
                GUID value = * ((GUID *) &data_buffer[value_offset]);
                perl_value = GUID_to_SV(value);
                break;
             }

             case DBTYPE_SQLVARIANT  : {
                SSVARIANT ssvar = * ((SSVARIANT *) &data_buffer[value_offset]);
                perl_value = ssvariant_to_SV(olle_ptr, ssvar, opts);
                break;
             }

             case DBTYPE_UDT   :
             case DBTYPE_BYTES : {
                BYTE ** byteptr =  ((BYTE **) &data_buffer[value_offset]);
                perl_value = binary_to_SV(* byteptr, value_len, opts);
                OLE_malloc_ptr->Free(* byteptr);
                * byteptr = NULL; // Clear entry in buffer, since ptr no longer valid.
                break;
             }

             case DBTYPE_STR   : {
                 // (var)char is handled different depending on it is a column or
                 // or parameter. This permits to handle any column collaton.
                 if (! is_param) {
                    // Columns were boud as DBTYPE_WSTR, so we convert the Unicode
                    // string to an SV.
                    WCHAR ** strptr =  ((WCHAR **) &data_buffer[value_offset]);
                    perl_value = BSTR_to_SV(* strptr, (I32) (value_len / 2));
                    OLE_malloc_ptr->Free(* strptr);
                    * strptr = NULL;
                 }
                 else {
                    // Parameters on the other hand are bound as DBTYPE_STE.
                    // It depends on the codepage how we handle them. Since they
                    // are variables, they always have the database collation.
                    char ** strptr =  ((char **) &data_buffer[value_offset]);
                    UINT codepage = OptCurrentCodepage(olle_ptr);

                    // If the codepage agrees with the ANSI code page of the 
                    // client (and it is not UTF-8), we can use the bytes as-is.
                    if (codepage == GetACP() && codepage != CP_UTF8) {
                       perl_value = newSVpvn(* strptr, value_len);
                    }
                    else { 
                       // Convert the string to UTF8.
                       perl_value = char_to_UTF8_SV(*strptr, value_len, codepage);
                   }

                   OLE_malloc_ptr->Free(* strptr);
                   * strptr = NULL;
                }
                break;
             }

             case DBTYPE_XML   : {
                // For XML there is BOM, that we should ignore.
                WCHAR ** strptr =  ((WCHAR **) &data_buffer[value_offset]);
                WCHAR * xmlptr =  * strptr;
                perl_value = BSTR_to_SV(xmlptr + 1, (I32) (value_len / 2) - 1);
                OLE_malloc_ptr->Free(* strptr);
                * strptr = NULL;
                break;
             }

             case DBTYPE_WSTR  : {
                WCHAR ** strptr =  ((WCHAR **) &data_buffer[value_offset]);
                perl_value = BSTR_to_SV(* strptr, (I32) (value_len / 2));
                OLE_malloc_ptr->Free(* strptr);
                * strptr = NULL;
                break;
             }

             default :
                olle_croak(olle_ptr, "Internal error: Unexpected data type %d in extract_data", datatype);
                break;
          }
          break;

       case DBSTATUS_E_UNAVAILABLE :
       // This may happen with a parameter value, if the command fails,
       // in which case we just set undef. This "should not happen" with a
       // column, so for a column we should croak on this. Whence the
       // funky placement of break for a half fall-through.
          if (is_param) {
              perl_value = newSVsv(&PL_sv_undef);
              break;
          }

       default : {
          char  msg[2000];
          char  * tmp = BSTR_to_char(valuename);
          sprintf_s(msg, 2000, "Extraction of param/col '%s'", tmp);
          Safefree(tmp);
          check_convert_errors(msg, value_status, bind_status, S_OK);
       }
   }
}

//--------------------------------------------------------------------
// $X->nextrow
//--------------------------------------------------------------------
int nextrow (SV   * olle_ptr,
             SV   * hashref,
             SV   * arrayref)
{
    internaldata * mydata = get_internaldata(olle_ptr);
    formatoptions  formatopts = getformatoptions(olle_ptr);
    int            optRowsAtATime = OptRowsAtATime(olle_ptr);
    HRESULT        ret;
    HROW         * row_handle_ptr;
    BOOL           have_hash;
    BOOL           have_array;
    HV           * return_hash;
    AV           * return_array;
    SV           * colvalue;

     // Check that we have a active result set.
    if (! mydata->have_resultset) {
        olle_croak (olle_ptr, "Call to nextrow without active result set. Call nextresults first");
    }

    // But the result set may be empty and with out a rowset ptr.
    if (mydata->rowset_ptr != NULL) {

       // If we have row buffer, try to use it.
       if (mydata->rowbuffer != NULL) {
          // We have one, so move to the next row.
          mydata->current_rowno++;

          // But we may now have exhausted the buffer.
          if (mydata->current_rowno > mydata->rows_in_buffer) {
             ret = mydata->rowset_ptr->ReleaseRows(mydata->rows_in_buffer,
                                                   mydata->rowbuffer,
                                                   NULL, NULL, NULL);
             check_for_errors(olle_ptr, "rowset_ptr->ReleaseRows", ret);
             mydata->current_rowno = 0;
             mydata->rows_in_buffer = 0;
             Safefree(mydata->rowbuffer);
             mydata->rowbuffer = NULL;
          }
       }

       // At this point, if we don't have a row buffer, get the first or
       // next one.
       if (mydata->rowbuffer == NULL) {
          New(902, mydata->rowbuffer, optRowsAtATime, HROW);
          // Get rows to the buffer.
          ret = mydata->rowset_ptr->GetNextRows(NULL, 0, optRowsAtATime,
                                                &(mydata->rows_in_buffer),
                                                &(mydata->rowbuffer));
          check_for_errors(olle_ptr, "rowset_ptr->GetNextRows", ret);
          mydata->current_rowno = 1;
       }

       // Now get a pointer, to the current row in the buffer.
       if (mydata->rows_in_buffer > 0) {
          row_handle_ptr = mydata->rowbuffer + (mydata->current_rowno - 1);
       }
       else {
          row_handle_ptr = NULL;
       }
    }
    else {
       row_handle_ptr = NULL;
    }

    // What references did we get?
    have_hash  = (hashref  != NULL && ! SvREADONLY(hashref));
    have_array = (arrayref != NULL && ! SvREADONLY(arrayref));

    if (row_handle_ptr != NULL) {
       // Clear the data buffer to leave room for this row.
       memset(mydata->data_buffer, 0, mydata->size_data_buffer);

       // Get the row data from the rowset.
       ret = mydata->rowset_ptr->GetData(*row_handle_ptr, mydata->row_accessor,
                                         mydata->data_buffer);
       check_for_errors(olle_ptr, "rowset_ptr->GetData", ret);

       // Create the Perl hash and/or array for returning the data.
       allocate_return_areas(mydata, have_hash, have_array,
                             hashref, arrayref, return_hash, return_array);

       // Iterate over all columns.
       for (ULONG j = 0; j < mydata->no_of_cols; j++) {
           // Extract the data into colvalue.
           extract_data(olle_ptr, formatopts, FALSE,
                        mydata->column_info[j].pwszName,
                        mydata->column_info[j].wType,
                        mydata->col_bindings[j],
                        mydata->col_bind_status[j],
                        mydata->data_buffer, colvalue);

           // Save the value in the hash.
           if (have_hash) {
              hv_store_ent(return_hash, mydata->column_keys[j], colvalue, 0);
           }

           // And save to the array. Note that if we save in both hash and
           // array, we need to bump the reference count.
           if (have_array) {
              if (have_hash) {
                 SvREFCNT_inc(colvalue);
              }
              av_store(return_array, j, colvalue);
           }
       }
    }
    else {
       // Last row in result set. Set return references to undef, and free
       // up memory for the result set.
       free_resultset_data(mydata);
       if (have_hash) {
          sv_setsv(hashref, &PL_sv_undef);
       }
       if (have_array) {
          sv_setsv(arrayref, &PL_sv_undef);
       }
   }

   // Set the rerurn value.
   return (row_handle_ptr != NULL ? 1 : 0);
}

//-----------------------------------------------------------------------
// $X->getoutputparams.
//-----------------------------------------------------------------------
void getoutputparams (SV * olle_ptr,
                      SV * hashref,
                      SV * arrayref)
{
    internaldata  * mydata = get_internaldata(olle_ptr);
    formatoptions   formatopts = getformatoptions(olle_ptr);
    paramdata     * current_param;
    ULONG           parno = 0;
    ULONG           outparno = 0;
    BOOL            have_hash;
    BOOL            have_array;
    HV            * return_hash;
    AV            * return_array;
    SV            * parvalue;

    // Check that we have a active result set.
    if (mydata->no_of_out_params == 0) {
        olle_croak (olle_ptr, "Call to getoutputparams for a batch that did not have output parameters");
    }

    if (! mydata->params_available) {
       olle_croak(olle_ptr, "Output parameters are not available at this point. First get all results sets with nextresultset");
    }

    // What references did we get?
    have_hash  = (hashref  != NULL && ! SvREADONLY(hashref));
    have_array = (arrayref != NULL && ! SvREADONLY(arrayref));

    // Create the Perl hash and/or array for returning the data.
    if (have_hash) {
       return_hash = newHV();
       sv_setsv(hashref, sv_2mortal(newRV_noinc((SV*) return_hash)));
    }
    if (have_array) {
       return_array = newAV();
       av_extend(return_array, mydata->no_of_cols);
       sv_setsv(arrayref, sv_2mortal(newRV_noinc((SV*) return_array)));
    }

    // Iterate over all parameters.
    current_param = mydata->paramfirst;
    while (current_param != NULL) {
       parno++;

       // But only output parameters are interesting.
       if (current_param->isoutput) {
          outparno++;

          // Extract the data into paravalue.
          extract_data(olle_ptr, formatopts, TRUE,
                       mydata->param_info[parno - 1].pwszName,
                       current_param->datatype,
                       mydata->param_bindings[parno - 1],
                       mydata->param_bind_status[parno - 1],
                       mydata->param_buffer, parvalue);
          // And save the value in the hash and/or array.
          if (have_hash) {
             // Need to construct a key first. It must be an SV to get
             // UTF-8 right.
             SV * hashkey;
             if (current_param->param_info.pwszName != NULL &&
                 wcslen(current_param->param_info.pwszName) > 0) {
                hashkey = BSTR_to_SV(current_param->param_info.pwszName);
             }
             else {
                char tmp[20];
                sprintf_s(tmp, 20, "Par %d", outparno);
                hashkey = newSVpv(tmp, strlen(tmp));
             }
             hv_store_ent(return_hash, hashkey, parvalue, 0);
             SvREFCNT_dec(hashkey);
          }

          if (have_array) {
             if (have_hash) {
                SvREFCNT_inc(parvalue);
             }
             av_store(return_array, outparno - 1, parvalue);
          }
       }

       // Move to next.
       current_param = current_param->next;
    }

    // The batch is now completely exhausted, so we can free all resources
    // bound to it.
    free_batch_data(mydata);
}

