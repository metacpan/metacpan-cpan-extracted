/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/tableparam.cpp 17    19-07-08 22:28 Sommar $

  Implements all support for table parameters.

  Copyright (c) 2004-2019   Erland Sommarskog

  $History: tableparam.cpp $
 * 
 * *****************  Version 17  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:28
 * Updated in $/Perl/OlleDB
 * The SQL version is now in mydata.
 * 
 * *****************  Version 16  *****************
 * User: Sommar       Date: 16-07-11   Time: 22:24
 * Updated in $/Perl/OlleDB
 * Changed data types of ULONG for no_of_cols and no_of_defaults to avoid
 * compilation warnings.
 * 
 * *****************  Version 15  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:52
 * Updated in $/Perl/OlleDB
 * Updated Copyright note.
 * 
 * *****************  Version 14  *****************
 * User: Sommar       Date: 12-08-08   Time: 23:21
 * Updated in $/Perl/OlleDB
 * parsename now has a return value.
 * 
 * *****************  Version 13  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:30
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64.
 * 
 * *****************  Version 12  *****************
 * User: Sommar       Date: 09-07-27   Time: 12:31
 * Updated in $/Perl/OlleDB
 * There was a 64-bit bug when saving the table definition into the hash
 * table. Changed for loop to while to remove compiler warning.
 *
 * *****************  Version 11  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:45
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared. Also
 * had to moify how the hash is traversed. hv_iterinit does not returns
 * the number of keys for tied hashes and the like.
 *
 * *****************  Version 10  *****************
 * User: Sommar       Date: 08-04-28   Time: 23:15
 * Updated in $/Perl/OlleDB
 * maxlen was incorrectly ULONG or UINT when it should have been DBLENGTH.
 *
 * *****************  Version 9  *****************
 * User: Sommar       Date: 08-03-23   Time: 23:45
 * Updated in $/Perl/OlleDB
 * 1) Don't bind columns with usedefault = 1.
 * 2) Warn user when hash key has column with default.
 * 3) Handle non-existing parameter types with a clear error message.
 *
 * *****************  Version 8  *****************
 * User: Sommar       Date: 08-03-21   Time: 17:44
 * Updated in $/Perl/OlleDB
 * Return was missing in the case the server or provider version was
 * wrong.
 *
 * *****************  Version 7  *****************
 * User: Sommar       Date: 08-02-24   Time: 16:10
 * Updated in $/Perl/OlleDB
 * Need to quote name of table column.
 *
 * *****************  Version 6  *****************
 * User: Sommar       Date: 08-02-10   Time: 23:18
 * Updated in $/Perl/OlleDB
 * Handle column properties for UDT and XML columns.
 *
 * *****************  Version 5  *****************
 * User: Sommar       Date: 08-01-06   Time: 23:33
 * Updated in $/Perl/OlleDB
 * Replaced all unsafe CRT functions with their safe replacements in VC8.
 * olledb_message now takes a va_list as argument, so we pass it
 * parameterised strings and don't have to litter the rest of the code
 * with that.
 *
 * *****************  Version 4  *****************
 * User: Sommar       Date: 08-01-06   Time: 18:56
 * Updated in $/Perl/OlleDB
 * All the switch(datatype) for parameters and column in TVPs are now in
 * common code, and not duplicated in senddata and tableparam.
 *
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-01-05   Time: 21:26
 * Updated in $/Perl/OlleDB
 * Moving the creation of the session pointer broke AutoConnect. The code
 * for AutoConnect is now in the connect module and be called from
 * executebatch or definetablecolumn.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-05   Time: 20:50
 * Updated in $/Perl/OlleDB
 * The areas for saved pointers are now in the tableparam struct and
 * created when the row buffer is created. Added support for defining that
 * the default value should be used for a column.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 08-01-05   Time: 0:28
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/

#include "CommonInclude.h"
#include "handleattributes.h"
#include "convenience.h"
#include "datatypemap.h"
#include "init.h"
#include "utils.h"
#include "internaldata.h"
#include "connect.h"
#include "errcheck.h"
#include "datetime.h"
#include "senddata.h"

// Initialiases the internal OlleDB structure for a table variable, and
// allocates area for the column definitions. Called from enterparameter.
BOOL setup_tableparam(SV        * olle_ptr,
                      SV        * paramname,
                      paramdata * this_param,
                      ULONG       no_of_cols,
                      SV        * tabletypename)
{
   tableparam   * tabledef;
   internaldata * mydata = get_internaldata(olle_ptr);

   // Check that table parameter are supported at all.
   if (mydata->provider < provider_sqlncli10 ||
       mydata->majorsqlversion < 10) {
       olledb_message(olle_ptr, -1, 1, 16,
           L"To use table parameters, you need SQL 2008 and SQL Server Native Client 10 or later.");
       return FALSE;
   }

   // Check that maxlen is legal.
   if (no_of_cols < 1 || no_of_cols > 1024) {
      olle_croak(olle_ptr, "Illegal number of columns (%d) specified for table-valued parameter",
              no_of_cols);
   }

   // Check that we have name for the type.
   if (! my_sv_is_defined(tabletypename)) {
      olle_croak(olle_ptr, "Name of type missing for table-valued parameter");
   }

   // Allocate the table parameter itself and initiate the area.
   New(902, tabledef, 1, tableparam);
   memset(tabledef, 0, sizeof(tableparam));

   tabledef->tabletypename = SV_to_BSTR(tabletypename);
   tabledef->no_of_cols = tabledef->cols_undefined = no_of_cols;
   tabledef->no_of_usedefault = 0;
   tabledef->colnamemap = newHV();
   New(902, tabledef->columns, no_of_cols, DBCOLUMNDESC);
   memset(tabledef->columns, 0, no_of_cols * sizeof(DBCOLUMNDESC));
   New(902, tabledef->colbindings, no_of_cols, DBBINDING);
   memset(tabledef->colbindings, 0, no_of_cols * sizeof(DBBINDING));
   New(902, tabledef->colbindstatus, no_of_cols, DBBINDSTATUS);
   memset(tabledef->colbindstatus, 0, no_of_cols * sizeof(DBBINDSTATUS));
   New(902, tabledef->usedefault, no_of_cols, BOOL);
   memset(tabledef->usedefault, FALSE, no_of_cols * sizeof(BOOL));
   New(902, tabledef->bindix, no_of_cols, UINT);
   memset(tabledef->bindix, ~0, no_of_cols * sizeof(UINT));

   // Set the table definition as the value for the current parameter.
   this_param->value.table = tabledef;

   // If the table parameter has a name, save it into a hash so that the
   // caller can refer to the parameter by name later.
   if (this_param->param_info.pwszName != NULL) {
      if (mydata->tableparams == NULL) {
         mydata->tableparams = newHV();
      }
      SV * sv_tabledef = newSViv((IV) tabledef);
      hv_store_ent(mydata->tableparams, paramname, sv_tabledef, 0);
   }

   return TRUE;
}

// add_column_props is called to handle XML and UDT columns to define
// the type name or schema collection.
static void add_column_props (SV           * olle_ptr,
                              DBCOLUMNDESC * coldesc,
                              SV           * typeinfo)
{
    DBPROPSET * propset;
    int         propscnt = 0;

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
                      L"Type name/XML schema '%s' includes a server compenent.\n",
                      typeinfo_str);
       SysFreeString(typeinfo_str);
       SvREFCNT_dec(server);
       SvREFCNT_dec(database);
       SvREFCNT_dec(schema);
       SvREFCNT_dec(object);
       return;
    }

    // Find out how many components we have.
    if (sv_len(database) > 0) propscnt++;
    if (sv_len(schema) > 0) propscnt++;
    if (sv_len(object) > 0) propscnt++;

    // If there was nothing, just drop out.
    if (propscnt == 0)
        return;

    // Set up property ids
    switch (coldesc->wType) {
        case DBTYPE_UDT :
             dbpropid     = SSPROP_COL_UDT_CATALOGNAME;
             schemapropid = SSPROP_COL_UDT_SCHEMANAME;
             objectpropid = SSPROP_COL_UDT_NAME;
             break;

        case DBTYPE_XML :
             dbpropid     = SSPROP_COL_XML_SCHEMACOLLECTION_CATALOGNAME;
             schemapropid = SSPROP_COL_XML_SCHEMACOLLECTION_SCHEMANAME;
             objectpropid = SSPROP_COL_XML_SCHEMACOLLECTIONNAME;
             break;

         default :
             olle_croak(olle_ptr,
                        "Internal error: Unexpected value %d for data type in add_column_props",
                        coldesc->wType);
    }

    // Set up the property set.
    New(902, propset, 1, DBPROPSET);
    propset->guidPropertySet = DBPROPSET_SQLSERVERCOLUMN;
    propset->cProperties = propscnt;
    New(902, propset->rgProperties, propscnt, DBPROP);

    // Store database if any.
    if (sv_len(database) > 0) {
       propset->rgProperties[ix].dwPropertyID = dbpropid;
       propset->rgProperties[ix].colid = DB_NULLID;
       propset->rgProperties[ix].dwOptions = DBPROPOPTIONS_REQUIRED;
       VariantInit(&(propset->rgProperties[ix].vValue));
       propset->rgProperties[ix].vValue.vt = VT_BSTR;
       propset->rgProperties[ix].vValue.bstrVal = SV_to_BSTR(database);
       ix++;
    }

    // And schema if any.
    if (sv_len(schema) > 0) {
       propset->rgProperties[ix].dwPropertyID = schemapropid;
       propset->rgProperties[ix].colid = DB_NULLID;
       propset->rgProperties[ix].dwOptions = DBPROPOPTIONS_REQUIRED;
       VariantInit(&(propset->rgProperties[ix].vValue));
       propset->rgProperties[ix].vValue.vt = VT_BSTR;
       propset->rgProperties[ix].vValue.bstrVal = SV_to_BSTR(schema);
       ix++;
    }

    // And the type name.
    if (sv_len(object) > 0) {
       propset->rgProperties[ix].dwPropertyID = objectpropid;
       propset->rgProperties[ix].colid = DB_NULLID;
       propset->rgProperties[ix].dwOptions = DBPROPOPTIONS_REQUIRED;
       VariantInit(&(propset->rgProperties[ix].vValue));
       propset->rgProperties[ix].vValue.vt = VT_BSTR;
       propset->rgProperties[ix].vValue.bstrVal = SV_to_BSTR(object);
    }

    // And save the property set.
    coldesc->rgPropertySets = propset;
    coldesc->cPropertySets = 1;

    // We must clean up our SVs to not leak memory.
    SvREFCNT_dec(server);
    SvREFCNT_dec(database);
    SvREFCNT_dec(schema);
    SvREFCNT_dec(object);
}


//------------------------------------------------------------------------
// definetablecolumn, exposed in the mid-level interface.
int definetablecolumn(SV * olle_ptr,
                      SV * tblname,
                      SV * colname,
                      SV * sv_nameoftype,
                      SV * sv_maxlen,
                      SV * sv_precision,
                      SV * sv_scale,
                      SV * usedefault,
                      SV * typeinfo)
{
   internaldata    * mydata = get_internaldata(olle_ptr);
   tableparam      * tbldef;
   char            * nameoftype;
   DBLENGTH          maxlen;
   int               colno;
   int               colix;
   int               bindix;
   DBTYPE            typeind;
   DBCOLUMNDESC    * coldesc;
   DBPARAMBINDINFO   param_info;
   DBBINDING       * binding;

   // Check that we're in the state where we're accepting parameters at all.
   if (mydata->pending_cmd == NULL) {
      olle_croak(olle_ptr, "Cannot call definetablecolumn now. There is no pending command. Call initbatch first");
   }

   if (mydata->cmdtext_ptr != NULL) {
      olle_croak(olle_ptr, "Cannot call definetablecolumn now. There are unprocessed result sets. Call cancelbatch first");
   }

   // See if we have a table parameter to work with. The caller can specify
   // a name, or undef to work the the most recently added parameter.
   if (my_sv_is_defined(tblname)) {
      HE * he = hv_fetch_ent(mydata->tableparams, tblname, 0, 0);
      if (he == NULL) {
         olle_croak(olle_ptr, "Attempt to define column for parameter %s, but this is not a table-valued parameter",
                    SvPV_nolen(tblname));
      }
      tbldef = (tableparam *) SvIV(HeVAL(he));
   }
   else if (mydata->paramlast && mydata->paramlast->value.table != NULL) {
      tbldef = mydata->paramlast->value.table;
   }
   else {
      olle_croak(olle_ptr, "Cannot define table column without a parameter name now. Most recently entered parameter is not a table");
   }

   // Check that there are still colunms left to define.
   if (tbldef->cols_undefined == 0) {
      olle_croak(olle_ptr, "All columns have alredy been defined for table-valued parameter");
   }

   // Check we did get a column name
   if (! my_sv_is_defined(colname)) {
      olle_croak(olle_ptr, "No column name specified for column definition");
   }

   // And a type name.
   if (! my_sv_is_defined(sv_nameoftype)) {
      olle_croak(olle_ptr, "You must pass a legal type name to definetablecolumn. Cannot pass undef");
   }
   nameoftype = SvPV_nolen(sv_nameoftype);

   // Translate the type name to a type indicator. However, we will
   // pass (var)char as WSTR to support UTF-8.
   typeind = lookup_type_map(nameoftype);

   // It must be a legal type.
   if (typeind == DBTYPE_EMPTY || typeind == DBTYPE_TABLE) {
      olledb_message(olle_ptr, -1, 1, 16,
                     L"Illegal data type '%S' for column %d in table type '%s'.",
                     nameoftype, tbldef->no_of_cols - tbldef->cols_undefined + 1,
                     tbldef->tabletypename);
      return FALSE;
   }


   // Get maxlen.
   if (my_sv_is_defined(sv_maxlen)) {
      maxlen = SvUV(sv_maxlen);
   }
   else {
      maxlen = 0;
   }

   // So which column in order is this? For the bindings, we need to reduce
   // the index for the number of default columns, because we don't bind these.
   colno = tbldef->no_of_cols - tbldef->cols_undefined + 1;
   colix = colno - 1;
   bindix = colix - tbldef->no_of_usedefault;

   // Is this a default column?
   if (SvTRUE(usedefault)) {
      tbldef->usedefault[colix] = TRUE;
      tbldef->no_of_usedefault++;
   }
   else {
      // If not, save the index for the binding.
      tbldef->bindix[colix] = bindix;
   }

   // Store column number in the column-name map.
   hv_store_ent(tbldef->colnamemap, colname, newSViv(colno), 0);

   // Get some pointers for short notiation. If we are to use a default for
   // for this column, the binding information will be over-written by
   // the next column (if there is one), but that's alright, because we
   // will not use it, only the column description. There will be some
   // holes in the row buffer, but who cares?
   coldesc = &(tbldef->columns[colix]);
   binding = &(tbldef->colbindings[bindix]);

   // Fill up the column description for CreateTable.
   coldesc->dbcid.eKind = DBKIND_NAME;
   coldesc->dbcid.uName.pwszName = SV_to_BSTR(colname);
   quotename(coldesc->dbcid.uName.pwszName);
   coldesc->wType = typeind;

   // Column bindings, all that is the same for all types.
   binding->iOrdinal   = colno;
   binding->dwMemOwner = DBMEMOWNER_CLIENTOWNED;
   binding->eParamIO   = DBPARAMIO_NOTPARAM;
   binding->wType      = typeind;    // BYREF may be added later.
   binding->dwPart     = DBPART_VALUE | DBPART_STATUS;
   binding->obStatus   = tbldef->size_row_buffer;
   tbldef->size_row_buffer += sizeof(DBSTATUS);
   binding->obValue    = tbldef->size_row_buffer;

   // For the type-specfic stuff we use complete_binding. This works with a
   // DBPARAMBINDINFO struct, and not a coldesc.
   memset(&param_info, 0, sizeof(DBPARAMBINDINFO));
   complete_binding(typeind, nameoftype, maxlen, sv_precision, sv_scale,
                    tbldef->size_row_buffer, binding, &param_info);
   coldesc->ulColumnSize = param_info.ulParamSize;
   coldesc->pwszTypeName = param_info.pwszDataSourceType;
   coldesc->bPrecision   = param_info.bPrecision;
   coldesc->bScale       = param_info.bScale;

   if (coldesc->wType == DBTYPE_UDT || coldesc->wType == DBTYPE_XML) {
      add_column_props(olle_ptr, coldesc, typeinfo);
   }


   // And if we did not fill in this one, fill it now.
   if (coldesc->pwszTypeName == NULL) {
      coldesc->pwszTypeName = SV_to_BSTR(sv_nameoftype);
   }

   // Decremenet number of undefined columns, and leave if there are more
   // to defined.
   if (--tbldef->cols_undefined > 0) {
      return TRUE;
   }

   // All columns are now defined. Go on and create the table and the rowset.
   // We need a session to be able to this.
   if (!setup_session(olle_ptr)) {
      return FALSE;
   }

   // First we need a table ID.
   DBID    TableID;
   HRESULT ret;

   TableID.uGuid.guid = CLSID_ROWSET_TVP;
   TableID.eKind = DBKIND_GUID_NAME;
   TableID.uName.pwszName = tbldef->tabletypename;

   // Get interface for ITableDefinitionWithConstraints.
   ret = mydata->session_ptr->QueryInterface(
           IID_ITableDefinitionWithConstraints, (void **) &(tbldef->tabledef_ptr));
   check_for_errors(olle_ptr, "session_ptr->QueryInterface to create ITableDefinitionWithConstraints object", ret);

   // Now we can create the table.
   ret = tbldef->tabledef_ptr->CreateTableWithConstraints(
         NULL, &TableID, tbldef->no_of_cols, tbldef->columns, 0, NULL,
         IID_IRowsetChange, 0, NULL, NULL, (IUnknown **) &(tbldef->rowset_ptr));
   check_for_errors(olle_ptr, "tabledef_ptr->CreateTableWithConstraints", ret);

   // Ramp up for an accessor. The accessor should only include the
   // colunms with usedefault = 0.
   ret = tbldef->rowset_ptr->QueryInterface(IID_IAccessor,
                                            (void **) &(tbldef->accessor_ptr));
   check_for_errors(olle_ptr, "tbldef->rowset_ptr->QueryInterface to create row accessor", ret);

   ret = tbldef->accessor_ptr->CreateAccessor(
                   DBACCESSOR_ROWDATA,
                   tbldef->no_of_cols - tbldef->no_of_usedefault,
                   tbldef->colbindings, tbldef->size_row_buffer,
                   &(tbldef->rowaccessor), tbldef->colbindstatus);
   check_for_errors(olle_ptr, "tbldef->accessor->CreateAccessor to create rowacessor", ret);

   // If there are any columns for which we are to pass default, set up a
   // parameter property for this for later use in executbatch.
   if (tbldef->no_of_usedefault > 0) {
      SAFEARRAYBOUND  bound = {tbldef->no_of_usedefault, 0};
      SAFEARRAY    * safearr = SafeArrayCreate(VT_UI2, 1, &bound);
      long           arr_ix = 0;
      for (ULONG ix = 0; ix < tbldef->no_of_cols; ix++) {
         if (tbldef->usedefault[ix]) {
            ULONG colno = ix + 1;
            ret = SafeArrayPutElement(safearr, &arr_ix, &colno);
            check_for_errors(olle_ptr, "SafeArrayPutElement", ret);
            arr_ix++;
         }
      }

      tbldef->defcolprop.dwPropertyID = SSPROP_PARAM_TABLE_DEFAULT_COLUMNS;
      tbldef->defcolprop.colid = DB_NULLID;
      tbldef->defcolprop.dwOptions = DBPROPOPTIONS_REQUIRED;
      VariantInit(&(tbldef->defcolprop.vValue));
      tbldef->defcolprop.vValue.vt = VT_UI2 | VT_ARRAY;
      tbldef->defcolprop.vValue.parray = safearr;
   }

   // And allocate the row buffer.
   New(902, tbldef->row_buffer, tbldef->size_row_buffer, BYTE);

   // And the buffers for saved pointers.
   New(902, tbldef->save_ptrs, tbldef->no_of_cols, void *);
   New(902, tbldef->save_bstrs, tbldef->no_of_cols, BSTR);

   return TRUE;
}

// Internal routine that is called from inserttableparam to write one
// column value to the buffer.
static BOOL value_to_rowbuffer(SV           * olle_ptr,
                               SV           * sv_value,
                               DBCOLUMNDESC * coldesc,
                               DBBINDING    * binding,
                               BYTE         * row_buffer,
                               void         * &save_ptr,
                               BSTR          &save_bstr)
{
   internaldata * mydata = get_internaldata(olle_ptr);
   BOOL value_OK = TRUE;
   DBLENGTH      value_len;
   DBSTATUS    * status_ptr = (DBSTATUS *) &(row_buffer[binding->obStatus]);
   DBLENGTH    * length_ptr = (DBLENGTH *) &(row_buffer[binding->obLength]);
   valueunion    colvalue;

   // Check for NULL for an easy way out.
   if (! my_sv_is_defined(sv_value)) {
      * status_ptr = DBSTATUS_S_ISNULL;
      return TRUE;
   }

   * status_ptr = DBSTATUS_S_OK;

   // Convert the value from Perl to SQL Server. Method depends on data type.
   value_OK = perl_to_sqlvalue(olle_ptr, sv_value, coldesc->wType,
                               coldesc->dbcid.uName.pwszName,
                               coldesc->pwszTypeName, binding,
                               coldesc->ulColumnSize,
                               colvalue, value_len, save_ptr, save_bstr);

   // And write it to the row buffer, if all is OK.
   if (value_OK) {
      write_to_databuffer(olle_ptr, row_buffer, binding->obValue, coldesc->wType,
                          colvalue);

      // Write the length if needed.
      if (binding->dwPart & DBPART_LENGTH) {
         * length_ptr = value_len;
      }
   }

   return value_OK;
}

// Implements inserttableparam in the mid-level interface.
int inserttableparam(SV * olle_ptr,
                     SV * tblname,
                     SV * inputref)
{
   internaldata * mydata = get_internaldata(olle_ptr);
   tableparam   * tbldef;
   HV           * input_hv = NULL;
   AV           * input_av = NULL;
   SV          ** svp;
   SV           * sv_value;
   BOOL           value_OK = TRUE;
   UINT           bindix;

   // Check that we're in the state where we're accepting parameters at all.
   if (mydata->pending_cmd == NULL) {
      olle_croak(olle_ptr, "Cannot call inserttableparam now. There is no pending command");
   }

   if (mydata->cmdtext_ptr != NULL) {
      olle_croak(olle_ptr, "Cannot call inserttableparam now. There are unprocessed result sets. Call cancelbatch first");
   }

   // See if we have a table parameter to work with. The caller can specify
   // a name, or undef to work the the most recently added parameter.
   if (my_sv_is_defined(tblname)) {
      HE * he = hv_fetch_ent(mydata->tableparams, tblname, 0, 0);
      if (he == NULL) {
         olle_croak(olle_ptr, "Cannot call inserttableparam for parameter %s; this is not a table-valued parameter",
                    SvPV_nolen(tblname));
      }
      tbldef = (tableparam *) SvIV(HeVAL(he));
   }
   else if (mydata->paramlast && mydata->paramlast->value.table != NULL) {
      tbldef = mydata->paramlast->value.table;
   }
   else {
      olle_croak(olle_ptr, "Cannot call inserttableparam without a parameter name now. Most recently entered parameter is not a table");
   }

   // Check that all columns have been defined
   if (tbldef->rowset_ptr == NULL) {
      olle_croak(olle_ptr, "Cannot call inserttableparam now. All columns have not been defined for table-valued parameter");
   }

   // Determine if the input area is a hash or an array.
   if (my_sv_is_defined(inputref) && SvROK(inputref)) {
      if (strncmp(SvPV_nolen(inputref), "HASH(", 5) == 0) {
         input_hv = (HV *) SvRV(inputref);
      }
      else if (strncmp(SvPV_nolen(inputref), "ARRAY(", 6) == 0) {
         input_av = (AV *) SvRV(inputref);
      }
   }

   // Initiate the row buffer. Set all columns to be NULL, in case caller
   // did not supply all.
   memset(tbldef->row_buffer, 0, tbldef->size_row_buffer);
   for (ULONG i = 0; i < tbldef->no_of_cols; i++) {
       DBBYTEOFFSET offset = tbldef->colbindings[i].obStatus;
       DBSTATUS * status = (DBSTATUS *) (&tbldef->row_buffer[offset]);
       * status = DBSTATUS_S_ISNULL;
   }

   // Clear the buffers with saved pointers.
   memset(tbldef->save_ptrs, 0, tbldef->no_of_cols * sizeof(void *));
   memset(tbldef->save_bstrs, 0, tbldef->no_of_cols * sizeof(BSTR));

   // Now we handle the input area.
   if (input_av != NULL) {
      ULONG arraylen = av_len(input_av) + 1;
      if ((arraylen > tbldef->no_of_cols) & PL_dowarn) {
         olledb_message(olle_ptr, -1, 1, 10,
                        L"Warning: input array for inserttableparam has %d elements, but there are only %d columns in the table definition.",
                        arraylen, tbldef->no_of_cols);
      }

      for (ULONG colix = 0;
                 colix < (arraylen <= tbldef->no_of_cols ?
                          arraylen : tbldef->no_of_cols); colix++) {
        if (tbldef->usedefault[colix]) {
           continue;
        }
        svp = av_fetch(input_av, colix, 0);
        if (svp == NULL) continue;
        sv_value = *svp;

        bindix = tbldef->bindix[colix];

        value_OK &= value_to_rowbuffer(
                    olle_ptr, sv_value, &(tbldef->columns[colix]),
                    &(tbldef->colbindings[bindix]), tbldef->row_buffer,
                    tbldef->save_ptrs[colix], tbldef->save_bstrs[colix]);
      }
   }
   else if (input_hv != NULL) {
      // Iterate over all keys in the hash.
      hv_iterinit(input_hv);
      while (HE * he = hv_iternext(input_hv)) {
         char  *  key;
         I32      keylen;
         SV    ** svp;
         SV    *  sv_colno = NULL;
         int      colix;
         SV    *  sv_value = NULL;

         // Get next key in iteration.
         key = hv_iterkey(he, &keylen);

         // Lookup this key in our colnamemap.
         svp = hv_fetch(tbldef->colnamemap, key, keylen, 0);
         if (svp != NULL) {
            sv_colno = * svp;
         }

         // If we don't know this key value, skip and issue a warning if
         // Perl warnings are enabled.
         if (! my_sv_is_defined(sv_colno)) {
            if (PL_dowarn) {
               olledb_message(olle_ptr, -1, 1, 10,
               "Warning: input hash to inserttableparam includes key '%s', but no such column has been defined for this table parameter.",
               key);
            }
            continue;
         }

         // Get the column index.
         colix = (int) SvIV(sv_colno) - 1;

         // If this is a column with a default, we issue a warning and move on
         // to the next column.
         if (tbldef->usedefault[colix]) {
            if (PL_dowarn) {
               olledb_message(olle_ptr, -1, 1, 10,
               "Warning: input hash to inserttableparam includes key '%s', but this column has been defined with usedefault=1 and the value is ignored.",
               key);
            }
            continue;
         }

         // Get the index in the bindings array. This may be different from
         // colix if there are columns with defaults.
         bindix = tbldef->bindix[colix];

         // And get the value in the input hash.
         sv_value = hv_iterval(input_hv, he);

         // And write the value to the buffer.
         value_OK &= value_to_rowbuffer(
                     olle_ptr, sv_value, &(tbldef->columns[colix]),
                     &(tbldef->colbindings[bindix]), tbldef->row_buffer,
                     tbldef->save_ptrs[colix], tbldef->save_bstrs[colix]);
      }
   }
   else {
      olle_croak(olle_ptr, "Incorrect value for parameter $inputref to inserttableparam. This should be a hash or an array reference");
   }

   // Propagate value_OK out to mydata, so that we know that the batch should
   // not be executed if there was an error.
   mydata->all_params_OK &= value_OK;

   // Write the row to the table if all values were OK. (And all previous
   // values were to. No use writing if we are not to execute the batch.)
   if (mydata->all_params_OK) {
      HRESULT ret;
      ret = tbldef->rowset_ptr->InsertRow(DB_NULL_HCHAPTER, tbldef->rowaccessor,
                                          tbldef->row_buffer, NULL);
      check_for_errors(olle_ptr, "tableparam->rowset_ptr->insert_row", ret);
   }

   // Release all saved pointers.
   for (ULONG ix = 0; ix < tbldef->no_of_cols; ix++) {
      Safefree(tbldef->save_ptrs[ix]);
      SysFreeString(tbldef->save_bstrs[ix]);
   }

   return value_OK;
}


