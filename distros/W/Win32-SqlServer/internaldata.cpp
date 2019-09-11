/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/internaldata.cpp 14    19-07-19 22:00 Sommar $

  This file holds routines setting up the internaldata struct, and
  also release memory allocated in it.

  Copyright (c) 2004-2019   Erland Sommarskog

  $History: internaldata.cpp $
 * 
 * *****************  Version 14  *****************
 * User: Sommar       Date: 19-07-19   Time: 22:00
 * Updated in $/Perl/OlleDB
 * Removed the olddbtranslate option from internaldata, and entirely
 * deprecated setting the AutoTranslate option to make sure that it always
 * is false. When clearing options when ProviderString is set, we don't
 * clear AutoTranslate.
 * 
 * *****************  Version 13  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:31
 * Updated in $/Perl/OlleDB
 * New elements in internaldata for SQL version,  currentDB and more for
 * UTF-8 support.
 * 
 * *****************  Version 12  *****************
 * User: Sommar       Date: 16-07-11   Time: 22:24
 * Updated in $/Perl/OlleDB
 * Changed data types of ULONG for no_of_cols and no_of_defaults to avoid
 * compilation warnings.
 * 
 * *****************  Version 11  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:52
 * Updated in $/Perl/OlleDB
 * Updated Copyright note.
 * 
 * *****************  Version 10  *****************
 * User: Sommar       Date: 12-08-15   Time: 21:26
 * Updated in $/Perl/OlleDB
 * Change the check for not set by SQLOLEDB to only check options set by
 * SQLOLEDB 2.6.
 * 
 * *****************  Version 9  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:26
 * Updated in $/Perl/OlleDB
 * Fix warnings about unsafe comparisons revealed by /W3.
 * 
 * *****************  Version 8  *****************
 * User: Sommar       Date: 09-07-26   Time: 12:44
 * Updated in $/Perl/OlleDB
 * Determining whether an SV is defined through my_sv_is_defined to as
 * SvOK may return false, unless we first do SvGETMAGIC. This proved to be
 * an issue when using table-valued parameters with threads::shared.
 *
 * *****************  Version 7  *****************
 * User: Sommar       Date: 09-04-25   Time: 22:29
 * Updated in $/Perl/OlleDB
 * setupinternaldata was incorrectly defined to return int, which botched
 * the pointer once address was > 7FFFFFFF.
 *
 * *****************  Version 6  *****************
 * User: Sommar       Date: 08-03-23   Time: 23:29
 * Updated in $/Perl/OlleDB
 * New field for table parameters: bindix, as we don't bind columns that
 * vae default.
 *
 * *****************  Version 5  *****************
 * User: Sommar       Date: 08-02-10   Time: 23:17
 * Updated in $/Perl/OlleDB
 * Clean up column properties in table parameters.
 *
 * *****************  Version 4  *****************
 * User: Sommar       Date: 08-01-06   Time: 23:33
 * Updated in $/Perl/OlleDB
 * Replaced all unsafe CRT functions with their safe replacements in VC8.
 * olledb_message now takes a va_list as argument, so we pass it
 * parameterised strings and don't have to litter the rest of the code
 * with that.
 *
 * *****************  Version 3  *****************
 * User: Sommar       Date: 08-01-05   Time: 20:43
 * Updated in $/Perl/OlleDB
 * Added more fields to the tableparam struct: buffers for saving
 * pointers, and support for defining columns to be sent as default.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-05   Time: 0:25
 * Updated in $/Perl/OlleDB
 * Support for table-valued parameters added.
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

// Dumps the contents of a property array in case of an error
void dump_properties(DBPROP init_properties[MAX_INIT_PROPERTIES],
                     BOOL   props_debug)
{
  BOOL too_old_sqloledb = FALSE;

  for (int i = 0; gbl_init_props[i].propset_enum != not_in_use; i++) {
       if (! props_debug &&
           init_properties[i].dwStatus == DBPROPSTATUS_OK)
           continue;

       char * ststxt;
       switch (init_properties[i].dwStatus) {
          case DBPROPSTATUS_OK :
               ststxt = "DBPROPSTATUS_OK"; break;
          case DBPROPSTATUS_BADCOLUMN :
               ststxt = "DBPROPSTATUS_BADCOLUMN"; break;
          case DBPROPSTATUS_BADOPTION :
               ststxt = "DBPROPSTATUS_BADOPTION"; break;
          case DBPROPSTATUS_BADVALUE :
               ststxt = "DBPROPSTATUS_BADVALUE"; break;
          case DBPROPSTATUS_CONFLICTING :
               ststxt = "DBPROPSTATUS_CONFLICTING"; break;
          case DBPROPSTATUS_NOTALLSETTABLE :
               ststxt = "DBPROPSTATUS_NOTALLSETTABLE"; break;
          case DBPROPSTATUS_NOTAVAILABLE :
               ststxt = "DBPROPSTATUS_NOTAVAILABLE"; break;
          case DBPROPSTATUS_NOTSET :
               ststxt = "DBPROPSTATUS_NOTSET"; break;
          case DBPROPSTATUS_NOTSETTABLE :
               ststxt = "DBPROPSTATUS_NOTSETTABLE"; break;
          case DBPROPSTATUS_NOTSUPPORTED :
               ststxt = "DBPROPSTATUS_NOTSUPPORTED"; break;
          case -1 :
               ststxt = "(not set by OLE DB provider)";
               too_old_sqloledb |= gbl_init_props[i].is_sqloledb;
               break;
       }
       PerlIO_printf(PerlIO_stderr(), "Property '%s', Status: %s, Value: ",
                      gbl_init_props[i].name, ststxt);
       if (init_properties[i].vValue.vt == VT_EMPTY) {
           PerlIO_printf(PerlIO_stderr(), "VT_EMPTY");
       }
       else {
          switch (gbl_init_props[i].datatype) {
             case VT_BOOL :
                PerlIO_printf(PerlIO_stderr(), "%d",
                              init_properties[i].vValue.boolVal);
                break;

             case VT_I2 :
                PerlIO_printf(PerlIO_stderr(), "%d",
                              init_properties[i].vValue.iVal);
                break;

             case VT_I4 :
                PerlIO_printf(PerlIO_stderr(), "%d",
                              init_properties[i].vValue.lVal);
                break;

             case VT_BSTR : {
                char * str = BSTR_to_char(init_properties[i].vValue.bstrVal);
                PerlIO_printf(PerlIO_stderr(), "'%s'", str);
                Safefree(str);
                break;
            }

            default :
                PerlIO_printf(PerlIO_stderr(), "UNKNOWN DATATYPE");
                break;
           }
       }

       PerlIO_printf(PerlIO_stderr(), ".\n");
   }

   if (too_old_sqloledb) {
      warn("The fact that status for one or more properties were not set by\n");
      warn("by the OLE DB provider, indicates that you are running an unsupported\n");
      warn("version of SQLOLEDB. To use Win32::SqlServer you must have at least\n");
      croak("version 2.6 of the MDAC, or you must use SQL Native Client\n");
   }
}

// This is purely a debug routine which is available, mainly to check for
// leaks, but is normally not called from anywhere.
void dump_internaldata(internaldata * mydata)
{
   dump_properties(mydata->init_properties, TRUE);

   warn("init_ptr = %x.\n", mydata->init_ptr);
   warn("datasrc_ptr = %x.\n", mydata->datasrc_ptr);
   warn("isautoconnected = %d.\n", mydata->isautoconnected);
   warn("isnestedquery = %d.\n", mydata->isnestedquery);
   warn("SQL_version = %d.\"n", mydata->SQL_version);
   warn("majorsqlversion = %d.\n", mydata->majorsqlversion);
   warn("CurrentDB = %d.\n", mydata->CurrentDB);
   warn("provider = %d.\n", mydata->provider);
   warn("pending_cmd = %d.\n", mydata->pending_cmd);
   warn("paramfirst = %x.\n", mydata->paramfirst);
   warn("paramlast = %x.\n", mydata->paramlast);
   warn("no_of_params = %d.\n", mydata->no_of_params);
   warn("no_of_out_params = %d.\n", mydata->no_of_out_params);
   warn("params_available = %d.\n", mydata->params_available);
   warn("session_ptr = %x.\n", mydata->session_ptr);
   warn("cmdtext_ptr = %x.\n", mydata->cmdtext_ptr);
   warn("paramcmd_ptr = %x.\n", mydata->paramcmd_ptr);
   warn("ss_paramcmd_ptr = %x.\n", mydata->ss_paramcmd_ptr);
   warn("paramaccess_ptr = %x.\n", mydata->paramaccess_ptr);
   warn("all_params_OK = %d.\n", mydata->all_params_OK);
   warn("param_info = %x.\n", mydata->param_info);
   warn("param_bindings = %x.\n", mydata->param_bindings);
   warn("param_buffer = %x.\n", mydata->param_buffer);
   warn("size_param_buffer = %d.\n", mydata->size_param_buffer);
   warn("param_accessor = %d.\n", mydata->param_accessor);
   warn("param_bind_status = %x.\n", mydata->param_bind_status);
   warn("results_ptr = %x.\n", mydata->results_ptr);
   warn("have_resultset = %d.\n", mydata->have_resultset);
   warn("rowset_ptr = %x.\n", mydata->rowset_ptr);
   warn("rowaccess_ptr = %x.\n", mydata->rowaccess_ptr);
   warn("row_accessor = %d.\n", mydata->row_accessor);
   warn("column_keys = %x.\n", mydata->column_keys);
   warn("rowbuffer = %x.\n", mydata->rowbuffer);
   warn("rows_in_buffer = %d.\n", mydata->rows_in_buffer);
   warn("current_rowno = %d.\n", mydata->current_rowno);
   warn("no_of_cols = %d.\n", mydata->no_of_cols);
   warn("column_info = %x.\n", mydata->column_info);
   warn("colname_buffer = %x.\n", mydata->colname_buffer);
   warn("col_bindings = %x.\n", mydata->col_bindings);
   warn("col_bind_status = %x.\n", mydata->col_bind_status);
   warn("data_buffer = %x.\n", mydata->data_buffer);
   warn("size_data_buffer = %d.\n", mydata->size_data_buffer);
}


// This routine allocates an internaldata structure and returns the pointer
// as an integer value.
void * setupinternaldata()
{
    internaldata  * mydata;  // Pointer to area for internal data.

    // Create struct for pointers we need to keep between calls, and initiate
    // all pointers to NULL.
    New(902, mydata, 1, internaldata);
    mydata->isautoconnected   = FALSE;
    mydata->isnestedquery     = FALSE;
    mydata->SQL_version       = &PL_sv_undef;
    mydata->majorsqlversion   = 0;
    mydata->CurrentDB         = &PL_sv_undef;
    mydata->provider          = default_provider();
    mydata->init_ptr          = NULL;
    mydata->pending_cmd       = NULL;
    mydata->paramfirst        = NULL;
    mydata->paramlast         = NULL;
    mydata->no_of_params      = 0;
    mydata->no_of_out_params  = 0;
    mydata->params_available  = FALSE;
    mydata->datasrc_ptr       = NULL;
    mydata->session_ptr       = NULL;
    mydata->cmdtext_ptr       = NULL;
    mydata->paramcmd_ptr      = NULL;
    mydata->ss_paramcmd_ptr   = NULL;
    mydata->paramaccess_ptr   = NULL;
    mydata->all_params_OK     = TRUE;
    mydata->param_info        = NULL;
    mydata->param_bindings    = NULL;
    mydata->param_buffer      = NULL;
    mydata->size_param_buffer = 0;
    mydata->param_accessor    = NULL;
    mydata->param_bind_status = NULL;
    mydata->tableparams       = NULL;
    mydata->results_ptr       = NULL;
    mydata->have_resultset    = FALSE;
    mydata->rowset_ptr        = NULL;
    mydata->rowaccess_ptr     = NULL;
    mydata->row_accessor      = NULL;
    mydata->column_keys       = NULL;
    mydata->rowbuffer         = NULL;
    mydata->rows_in_buffer    = 0;
    mydata->current_rowno     = 0;
    mydata->no_of_cols        = NULL;
    mydata->column_info       = NULL;
    mydata->colname_buffer    = NULL;
    mydata->col_bindings      = NULL;
    mydata->col_bind_status   = NULL;
    mydata->data_buffer       = NULL;
    mydata->size_data_buffer  = 0;


    // Set up the init property sets. First the GUIDs.
    mydata->init_propsets[oleinit_props].guidPropertySet =
            DBPROPSET_DBINIT;
    mydata->init_propsets[ssinit_props].guidPropertySet  =
            DBPROPSET_SQLSERVERDBINIT;
    mydata->init_propsets[datasrc_props].guidPropertySet =
            DBPROPSET_DATASOURCE;

    // Then number and pointer to the arrays.
    for (int i = 0; i <= NO_OF_INIT_PROPSETS; i++) {
       mydata->init_propsets[i].cProperties  = init_propset_info[i].no_of_props;
       mydata->init_propsets[i].rgProperties =
           &(mydata->init_properties[init_propset_info[i].start]);
    }

    // Then copy the properties from the global default properties.
    for (int j = 0; gbl_init_props[j].propset_enum != not_in_use; j++) {
       DBPROP  &prop = mydata->init_properties[j];
       prop.dwPropertyID = gbl_init_props[j].property_id;
       prop.dwOptions    = DBPROPOPTIONS_REQUIRED;
       prop.colid        = DB_NULLID;
       prop.dwStatus     = DBPROPSTATUS_OK;
       VariantInit(&prop.vValue);
       VariantCopy(&prop.vValue, &gbl_init_props[j].default_value);
    }

    return (void *) mydata;
}

// Retrieves the internal data pointer in opaque form and reinterprets
// the pointer.
internaldata * get_internaldata(SV * olle_ptr) {
   internaldata * ptr = (internaldata *) OptInternalData(olle_ptr);
   return ptr;
}


// We release pointers a lot, so we have a macro that does it all.
#define free_ole_ptr(oleptr) \
   if (oleptr != NULL) { \
      oleptr->Release(); \
      oleptr = NULL; \
   } \


// This routine frees about allocation for receiving a result. It is
// called by nextrow, when there aer no more rows, or by cancelresultset.
void free_resultset_data(internaldata *mydata) {
   HRESULT ret;

   if (mydata->column_info != NULL) {
      OLE_malloc_ptr->Free(mydata->column_info);
      mydata->column_info = NULL;
   }
   if (mydata->colname_buffer != NULL) {
      OLE_malloc_ptr->Free(mydata->colname_buffer);
      mydata->colname_buffer = NULL;
   }
   if (mydata->col_bindings != NULL) {
      Safefree(mydata->col_bindings);
      mydata->col_bindings = NULL;
   }
   if (mydata->col_bind_status != NULL) {
      Safefree(mydata->col_bind_status);
      mydata->col_bind_status = NULL;
   }
   if (mydata->data_buffer != NULL) {
      Safefree(mydata->data_buffer);
      mydata->data_buffer = NULL;
   }

   if (mydata->rowbuffer != NULL) {
      ret = mydata->rowset_ptr->ReleaseRows(mydata->rows_in_buffer,
                                            mydata->rowbuffer,
                                            NULL, NULL, NULL);
      if (FAILED(ret)) {
         croak("rowset_ptr->ReleaseRows failed with %08X.\n", ret);
      }
      Safefree(mydata->rowbuffer);
      mydata->rowbuffer = NULL;
   }
   mydata->rows_in_buffer = 0;
   mydata->current_rowno = 0;

   if (mydata->row_accessor != NULL) {
      if (mydata->rowaccess_ptr != NULL) {
         mydata->rowaccess_ptr->ReleaseAccessor(mydata->row_accessor, NULL);
      }
      mydata->row_accessor = NULL;
   }

   if (mydata->column_keys != NULL) {
      for (DBORDINAL i = 0; i < mydata->no_of_cols; i++) {
         if (my_sv_is_defined(mydata->column_keys[i])) {
            SvREFCNT_dec(mydata->column_keys[i]);
         }
      }
      Safefree(mydata->column_keys);
      mydata->column_keys = NULL;
   }
   mydata->no_of_cols = 0;

   free_ole_ptr(mydata->rowaccess_ptr);
   free_ole_ptr(mydata->rowset_ptr);
   mydata->have_resultset = FALSE;
}

void free_tableparam_data(tableparam * table) {
   SysFreeString(table->tabletypename);

   hv_clear(table->colnamemap);
   hv_undef(table->colnamemap);
   SvREFCNT_dec(table->colnamemap);
   table->colnamemap = NULL;

   if (table->columns != NULL) {
      for (ULONG i = 0; i < table->no_of_cols; i++) {
         DBCOLUMNDESC * coldesc = &(table->columns[i]);
         SysFreeString(coldesc->pwszTypeName);
         SysFreeString(coldesc->dbcid.uName.pwszName);
         if (coldesc->cPropertySets > 0) {
            for (UINT j = 0; j < coldesc->cPropertySets; j++) {
               for (UINT k = 0; k < coldesc->rgPropertySets[j].cProperties; k++) {
                   VariantClear(&(coldesc->rgPropertySets[j].rgProperties[k].vValue));
               }
               Safefree(coldesc->rgPropertySets[j].rgProperties);
            }
            Safefree(coldesc->rgPropertySets);
         }
      }
      Safefree(table->columns);
   }

  if (table->no_of_usedefault > 0) {
      VariantClear(&(table->defcolprop.vValue));
      table->no_of_usedefault = 0;
   }
   Safefree(table->usedefault);

   if (table->colbindings != NULL) {
      Safefree(table->colbindings);
   }

   if (table->colbindstatus != NULL) {
      Safefree(table->colbindstatus);
   }

   if (table->bindix != NULL) {
      Safefree(table->bindix);
   }

   Safefree(table->row_buffer);
   Safefree(table->save_ptrs);
   Safefree(table->save_bstrs);

   if (table->rowaccessor != NULL && table->accessor_ptr != NULL) {
      table->accessor_ptr->ReleaseAccessor(table->rowaccessor, NULL);
      table->rowaccessor = NULL;
   }

   table->no_of_cols = table->cols_undefined = 0;

   // Here is a funny thing: SQL Native Client will release the rowset
   // interface when the command is executed, in which case it will go
   // away when we release the accessor which is the last reference now.
   // But if the batch was cancelled before excecution, our original
   // reference is still left. So we add a reference to the rowset pointer
   // to get knowledge of where we are.
   LONG refcnt = (table->rowset_ptr != NULL ? table->rowset_ptr->AddRef() : 0);
   free_ole_ptr(table->accessor_ptr);
   while (refcnt-- > 1) table->rowset_ptr->Release();
   table->rowset_ptr = NULL;
   free_ole_ptr(table->tabledef_ptr);
}

// This routine frees up everything with a saved parameter list. Normally
// called before we execute a parameterised command. Also called from
// free_batch_data as a safety precaution.
void free_pending_cmd(internaldata *mydata) {
   if (mydata->pending_cmd != NULL) {
      SysFreeString(mydata->pending_cmd);
      mydata->pending_cmd = NULL;
   }

   while (mydata->paramfirst != NULL) {
      paramdata * tmp;
      tmp = mydata->paramfirst;

      SysFreeString(tmp->param_info.pwszName);
      SysFreeString(tmp->param_info.pwszDataSourceType);

      // buffer_ptr is a saved address to input parameter.
      if (tmp->buffer_ptr != NULL) {
         Safefree(tmp->buffer_ptr);
      }

      // bstr is a saved addres to an nvarchar parameter, different pool than
      // buffer_ptr.
      if (tmp->bstr != NULL) {
         SysFreeString(tmp->bstr);
      }

      // Any parameter properties must be released.
      if (tmp->param_props_cnt > 0) {
         for (int ix = 0; ix < tmp->param_props_cnt; ix++) {
            VariantClear(&tmp->param_props[ix].vValue);
         }
         Safefree(tmp->param_props);
      }

      // If it's table variable, there is a lot more to cleanup
      if (tmp->datatype == DBTYPE_TABLE && tmp->value.table != NULL) {
         free_tableparam_data(tmp->value.table);
         Safefree(tmp->value.table);
      }

      if (tmp->bindobject != NULL) {
         Safefree(tmp->bindobject);
      }

      mydata->paramfirst = tmp->next;
      Safefree(tmp);
   }

   mydata->paramlast = NULL;
}

// This routine is called whenever we need to cancel everything allocated
// for a query batch.
void free_batch_data(internaldata *mydata) {
   // First free eveything associated with a result.
   free_resultset_data(mydata);
   mydata->params_available = FALSE;

   // Pending command.
   free_pending_cmd(mydata);

   // Parameter information.
   if (mydata->param_info != NULL) {
      Safefree(mydata->param_info);
      mydata->param_info = NULL;
   }

   if (mydata->param_bindings != NULL) {
      Safefree(mydata->param_bindings);
      mydata->param_bindings = NULL;
   }

   if (mydata->param_buffer != NULL) {
      Safefree(mydata->param_buffer);
      mydata->param_buffer = NULL;
   }

   mydata->size_param_buffer = 0;
   mydata->no_of_params = 0;
   mydata->no_of_out_params = 0;
   mydata->all_params_OK = TRUE;

   if (mydata->param_accessor != NULL) {
      if (mydata->paramaccess_ptr != NULL) {
         HRESULT ret;
         ret = mydata->paramaccess_ptr->ReleaseAccessor(
                                        mydata->param_accessor, NULL);
         if (FAILED(ret)) {
            croak("paramaccess_ptr->ReleaseAccessor failed with %08X.\n", ret);
         }
      }
      mydata->param_accessor = NULL;
   }

   if (mydata->param_bind_status != NULL) {
      Safefree(mydata->param_bind_status);
      mydata->param_bind_status = NULL;
   }

   if (mydata->tableparams != NULL) {
      hv_clear(mydata->tableparams);
      hv_undef(mydata->tableparams);
      SvREFCNT_dec(mydata->tableparams);
      mydata->tableparams = NULL;
   }

   free_ole_ptr(mydata->results_ptr);
   free_ole_ptr(mydata->paramaccess_ptr);
   free_ole_ptr(mydata->paramcmd_ptr);
   free_ole_ptr(mydata->ss_paramcmd_ptr);
   free_ole_ptr(mydata->cmdtext_ptr);
   free_ole_ptr(mydata->session_ptr);

   // Release the data-source pointer only if auto-connected. And
   // not if it is an internal query
   if (mydata->isautoconnected && ! mydata->isnestedquery) {
      free_ole_ptr(mydata->datasrc_ptr);
      free_ole_ptr(mydata->init_ptr);
   }
}

// Frees it all - called on disconncetion.
void free_connection_data(internaldata  * mydata) {
    free_batch_data(mydata);

    free_ole_ptr(mydata->datasrc_ptr);  // This disconnects - or returns to pool.
    free_ole_ptr(mydata->init_ptr);
}

// Free strings for SQL version and current DB. Called on destroy or
// when the server changes.
void free_sqlver_currentdb(internaldata * mydata) {
    if (my_sv_is_defined(mydata->SQL_version)) {
       SvREFCNT_dec(mydata->SQL_version);
       mydata->SQL_version = &PL_sv_undef;

    }
    mydata->majorsqlversion = 0;

    if (my_sv_is_defined(mydata->CurrentDB)) {
       SvREFCNT_dec(mydata->CurrentDB);
       mydata->CurrentDB = &PL_sv_undef;
    }
}

