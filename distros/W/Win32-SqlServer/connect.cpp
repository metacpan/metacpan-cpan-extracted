/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/connect.cpp 8     12-09-23 22:52 Sommar $

  Implements the connection routines on Win32::SqlServer.

  Copyright (c) 2004-2012   Erland Sommarskog

  $History: connect.cpp $
 * 
 * *****************  Version 8  *****************
 * User: Sommar       Date: 12-09-23   Time: 22:52
 * Updated in $/Perl/OlleDB
 * Updated Copyright note.
 * 
 * *****************  Version 7  *****************
 * User: Sommar       Date: 12-08-15   Time: 21:28
 * Updated in $/Perl/OlleDB
 * New model for checking the number of properties depending on the
 * provider. New login property ApplicationIntent that requires
 * validation.
 * 
 * *****************  Version 6  *****************
 * User: Sommar       Date: 12-07-20   Time: 23:49
 * Updated in $/Perl/OlleDB
 * Add support for SQLNCLI11.
 * 
 * *****************  Version 5  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:17
 * Updated in $/Perl/OlleDB
 * Suppress warning about data truncation on x64.
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
 * User: Sommar       Date: 08-01-05   Time: 21:26
 * Updated in $/Perl/OlleDB
 * Moving the creation of the session pointer broke AutoConnect. The code
 * for AutoConnect is now in the connect module and be called from
 * executebatch or definetablecolumn.
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
#include "connect.h"


// Connect, called from $X->Connect() and $X->executebatch for autoconnect.
BOOL do_connect (SV    * olle_ptr,
                 BOOL    isautoconnect)
{
    internaldata  * mydata = get_internaldata(olle_ptr);
    HRESULT         ret      = S_OK;
    IDBProperties * property_ptr;
    CLSID         * clsid;
    char          * provider_name;

    switch (mydata->provider) {
       // At this point provider_default should never appear.
       case provider_sqlncli11 :
         clsid = &clsid_sqlncli11;
         provider_name = "SQLNCLI11";
         break;

       case provider_sqlncli10 :
         clsid = &clsid_sqlncli10;
         provider_name = "SQLNCLI10";
         break;

       case provider_sqlncli :
         clsid = &clsid_sqlncli;
         provider_name = "SQLNCLI";
         break;

       case provider_sqloledb :
         clsid = &clsid_sqloledb;
         provider_name = "SQLOLEDB";
         break;

       default :
          croak ("Internal error: Illegal value %d for the provider enum",
                 mydata->provider);
    }
    if (FAILED(ret)) {
       croak("Chosen provider '%s' does not appear to be installed on this machine",
              provider_name);
    }

    ret = data_init_ptr->CreateDBInstance(*clsid,
                         NULL, CLSCTX_INPROC_SERVER,
                         NULL, IID_IDBInitialize,
                         reinterpret_cast<IUnknown **> (&mydata->init_ptr));
    if (FAILED(ret)) {
       croak("Internal error: IDataInitliaze->CreateDBInstance failed: %08X", ret);
    }

    // We need a property object.
    ret = mydata->init_ptr->QueryInterface(IID_IDBProperties,
                                           (void **) &property_ptr);
    if (FAILED(ret)) {
       croak("Internal error: init_ptr->QueryInterface to create Property object failed with hresult %x", ret);
    }

    // Set the number of SSPROPS depending on the provider.
    mydata->init_propsets[ssinit_props].cProperties =  
                                          no_of_ssprops(mydata->provider);

    // Set all dwStatus to -1 for the first two propsets, this helps to
    // detect that some properties were not set, because we're in for an
    // old version of SQLOLEDB.
    for (int p = oleinit_props; p <= ssinit_props; p++) {
       for (UINT i = init_propset_info[p].start;
            i < mydata->init_propsets[p].cProperties +
               init_propset_info[p].start; i++) {
          mydata->init_properties[i].dwStatus = -1;
       }
    }

    ret = property_ptr->SetProperties(2, mydata->init_propsets);
    if (FAILED(ret)) {
       dump_properties(mydata->init_properties, OptPropsDebug(olle_ptr));
       croak("Internal error: property_ptr->SetProperties for initialization props failed with hresult %x", ret);
    }

    // This is the place where we actually log in to SQL Server. We might
    // be reusing a connection from a pool.
    ret = mydata->init_ptr->Initialize();

    // If success, continue with creating data-source object.
    if (SUCCEEDED(ret)) {
       // Set properties for the data source.
       ret = property_ptr->SetProperties(1, &mydata->init_propsets[datasrc_props]);
       check_for_errors(NULL, "property_ptr->SetProperties for data-source props",
                        ret);


       // Get a data source object.
       ret = mydata->init_ptr->QueryInterface(IID_IDBCreateSession,
                                            (void **) &(mydata->datasrc_ptr));
       check_for_errors(olle_ptr, "init_ptr->QueryInterface for data source",
                        ret);
       mydata->isautoconnected = isautoconnect;
    }
    else {
       dump_properties(mydata->init_properties, OptPropsDebug(olle_ptr));
       check_for_errors(olle_ptr, "init_ptr->Initialize", ret);
    }

    // And release the property pointers.
    property_ptr->Release();

    return SUCCEEDED(ret);
}

// This is $X->setloginproperty.
void setloginproperty(SV   * olle_ptr,
                      char * prop_name,
                      SV   * prop_value)
{
   internaldata * mydata = get_internaldata(olle_ptr);
   int            ix = 0;

   // If we are connected, and warnings are enabled, emit a warning.
   if (mydata->datasrc_ptr != NULL) {
      olle_croak(olle_ptr, "You cannot set login properties while connected");
   }

   // Check we got a proper prop_name.
   if (prop_name == NULL) {
      croak("Property name must not be NULL.");
   }

   // Look up property name in the global array.
   while (gbl_init_props[ix].propset_enum != not_in_use &&
          _stricmp(prop_name, gbl_init_props[ix].name) != 0) {
      ix++;
   }

   if (gbl_init_props[ix].propset_enum == not_in_use) {
     croak("Unknown property '%s' passed to setloginproperty", prop_name);
   }


   // Some properties affects others.
   if (gbl_init_props[ix].propset_enum == oleinit_props &&
       gbl_init_props[ix].property_id == DBPROP_AUTH_USERID) {
      // If userid is set, we clear Integrated security.
      setloginproperty(olle_ptr, "IntegratedSecurity", &PL_sv_undef);
   }
   else if (gbl_init_props[ix].propset_enum == oleinit_props &&
            gbl_init_props[ix].property_id == DBPROP_INIT_PROVIDERSTRING) {
      // In this case, all other properties should be flushed.
      for (int j = 0; gbl_init_props[j].propset_enum != datasrc_props; j++) {
         VariantClear(&mydata->init_properties[j].vValue);
      }
   }

   // If the server changes, the SQL_version attribute is no longer valid.
   if (gbl_init_props[ix].propset_enum == oleinit_props &&
       (gbl_init_props[ix].property_id == DBPROP_INIT_PROVIDERSTRING ||
        gbl_init_props[ix].property_id == DBPROP_INIT_DATASOURCE ||
        gbl_init_props[ix].property_id == SSPROP_INIT_NETWORKADDRESS)) {
      drop_SQLversion(olle_ptr);
   }

   // The property ApplicationIntent requires validation.
   if (gbl_init_props[ix].propset_enum == ssinit_props &&
       gbl_init_props[ix].property_id == SSPROP_INIT_APPLICATIONINTENT) {
       char * appintent = SvPV_nolen(prop_value);
       if (_stricmp(appintent, "readwrite") != 0 &&
           _stricmp(appintent, "readonly") != 0) {
              croak("Illegal value '%s' passed for the '%s' property",
                    appintent, prop_name);
       }
   }
        

   // First clear the current value and set property to VT_EMPTY.
   VariantClear(&mydata->init_properties[ix].vValue);

   // Then set the value appropriately
   if (my_sv_is_defined(prop_value)) {
      mydata->init_properties[ix].vValue.vt = gbl_init_props[ix].datatype;

      // First handle any specials. Currently there are two.
      if (gbl_init_props[ix].propset_enum == oleinit_props &&
          gbl_init_props[ix].property_id == DBPROP_INIT_OLEDBSERVICES) {
         // For OLE DB Services, we are only using connection pooling.
         mydata->init_properties[ix].vValue.lVal = (SvTRUE(prop_value)
                 ? DBPROPVAL_OS_RESOURCEPOOLING : DBPROPVAL_OS_DISABLEALL);
      }
      else if (gbl_init_props[ix].propset_enum == oleinit_props &&
               gbl_init_props[ix].property_id == DBPROP_AUTH_INTEGRATED) {
         // For integrated security, handle numeric values gently.
         if (SvIOK(prop_value)) {
            if (SvIV(prop_value) != 0) {
                mydata->init_properties[ix].vValue.bstrVal =
                    SysAllocString(L"SSPI");
            }
            else {
               mydata->init_properties[ix].vValue.vt = VT_EMPTY;
             }
         }
         else {
            mydata->init_properties[ix].vValue.bstrVal = SV_to_BSTR(prop_value);
         }
      }
      else {
         switch(gbl_init_props[ix].datatype) {
            case VT_BOOL :
                mydata->init_properties[ix].vValue.boolVal =
                    (SvTRUE(prop_value) ? VARIANT_TRUE : VARIANT_FALSE);
                break;

            case VT_I2 :
                mydata->init_properties[ix].vValue.iVal = (SHORT) SvIV(prop_value);
                break;

            case VT_UI2 :
                mydata->init_properties[ix].vValue.uiVal = (USHORT) SvIV(prop_value);
                break;

            case VT_I4 :
                mydata->init_properties[ix].vValue.lVal = (LONG) SvIV(prop_value);
                break;

            case VT_BSTR :
                mydata->init_properties[ix].vValue.bstrVal = SV_to_BSTR(prop_value);
                break;

            default :
               croak ("Internal error: Unexpected datatype %d when setting property '%s'",
                      gbl_init_props[ix].datatype, prop_name);
          }
       }
   }
}

// Creates the datastc and session objects if needed.
BOOL setup_session(SV * olle_ptr)
{
    internaldata * mydata = get_internaldata(olle_ptr);
    HRESULT        ret;

    if (mydata->datasrc_ptr == NULL) {
       if (OptAutoConnect(olle_ptr)) {
          if (! do_connect(olle_ptr, TRUE)) {
             return FALSE;
          }
       }
       else {
          olle_croak(olle_ptr, "Not connected to SQL Server, nor is AutoConnect set. Cannot execute batch");
       }
    }

   if (mydata->session_ptr == NULL) {
      ret = mydata->datasrc_ptr->CreateSession(NULL, IID_IDBCreateCommand,
                                            (IUnknown **) &(mydata->session_ptr));
      check_for_errors(olle_ptr, "datasrc_ptr->CreateSession for session object", ret);
   }

   return TRUE;
}

void disconnect(SV * olle_ptr)
{
    internaldata * mydata = get_internaldata(olle_ptr);

    free_connection_data(mydata);
}
