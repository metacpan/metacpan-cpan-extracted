/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/connect.cpp 19    24-07-17 23:06 Sommar $

  Implements the connection routines on Win32::SqlServer.

  Copyright (c) 2004-2024   Erland Sommarskog

  $History: connect.cpp $
 * 
 * *****************  Version 19  *****************
 * User: Sommar       Date: 24-07-17   Time: 23:06
 * Updated in $/Perl/OlleDB
 * Entirely removed AutoTranslate as an option and it is now considered
 * unknown.
 * 
 * *****************  Version 18  *****************
 * User: Sommar       Date: 24-07-15   Time: 23:52
 * Updated in $/Perl/OlleDB
 * Added new login property ServerCertificate which also can be set
 * through SetDefaultForEncryption.
 * 
 * *****************  Version 17  *****************
 * User: Sommar       Date: 22-05-27   Time: 23:59
 * Updated in $/Perl/OlleDB
 * Also except the settings for Trust Server Certificate and Host Name in
 * Certificate when setting the provider string.
 * 
 * *****************  Version 16  *****************
 * User: Sommar       Date: 22-05-27   Time: 21:59
 * Updated in $/Perl/OlleDB
 * The correction of the one-off error was in the wrong place. When
 * setting provider string, don't clear the Encrypt setting, because for
 * some reason it does not have any effect when you list it in the
 * provider string. When comparing property IDs, also include the propset
 * as some properties have the same ids.
 * 
 * *****************  Version 15  *****************
 * User: Sommar       Date: 22-05-18   Time: 22:23
 * Updated in $/Perl/OlleDB
 * Added validation of the values of the Authentication propery. If
 * AccessToken is given, clear IntegratedSecurity.
 * 
 * *****************  Version 14  *****************
 * User: Sommar       Date: 22-05-08   Time: 23:16
 * Updated in $/Perl/OlleDB
 * New OLE DB provider MSOLEDBSQL19. Need special handling of the login
 * property Encrypt, since the data type changed with tne new provider.
 * Fix bug in set_one_property which resulted in the last property in a
 * property set to be ignored.
 * 
 * *****************  Version 13  *****************
 * User: Sommar       Date: 21-07-12   Time: 21:42
 * Updated in $/Perl/OlleDB
 * Since we now have optional login properties, we set them from a copy of
 * the property-set array in internaldata.
 * 
 * *****************  Version 12  *****************
 * User: Sommar       Date: 19-07-19   Time: 22:00
 * Updated in $/Perl/OlleDB
 * Removed the olddbtranslate option from internaldata, and entirely
 * deprecated setting the AutoTranslate option to make sure that it always
 * is false. When clearing options when ProviderString is set, we don't
 * clear AutoTranslate.
 * 
 * *****************  Version 11  *****************
 * User: Sommar       Date: 19-07-17   Time: 13:14
 * Updated in $/Perl/OlleDB
 * Fixed memory leak.
 * 
 * *****************  Version 10  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:36
 * Updated in $/Perl/OlleDB
 * Added function to get SQL version and current database from the Init
 * object and call this on connect. When server is changed, we need to
 * forget SQL Server version, current database and the coepages has. Split
 * setup_sesion into setup_datasrc and setup_session. as the data source
 * is now set up in initbatch.
 * 
 * *****************  Version 9  *****************
 * User: Sommar       Date: 18-04-09   Time: 22:46
 * Updated in $/Perl/OlleDB
 * Add support for the new MSOLEDBSQL provider.
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


// This routine returns the current database SQL Version as returned by 
// the initializion object. It is called from do_connect but also 
// initbatch, since the the database could have changed.
void get_sqlversion_and_dbname (SV * olle_ptr) {
    internaldata       * mydata = get_internaldata(olle_ptr);
    IDBProperties      * property_ptr;
    HRESULT              ret;
    ULONG                no_of_prop_sets;
    DBPROPSET          * property_sets;
    DBPROPIDSET          propertysetids[2];
    DBPROPID             datasrcpropid[1];
    DBPROPID             datasrcinfopropid[1];
    BSTR                 bstr;


    ret = mydata->init_ptr->QueryInterface(IID_IDBProperties,
                                           (void **) &property_ptr);
    if (FAILED(ret)) {
       croak("Internal error: init_ptr->QueryInterface to create Property object failed with hresult %x", ret);
    }

    propertysetids[0].guidPropertySet = DBPROPSET_DATASOURCEINFO;
    propertysetids[0].cPropertyIDs = 1;
    propertysetids[0].rgPropertyIDs = datasrcinfopropid;
    datasrcinfopropid[0] = DBPROP_DBMSVER;

    propertysetids[1].guidPropertySet = DBPROPSET_DATASOURCE;
    propertysetids[1].cPropertyIDs = 1;
    propertysetids[1].rgPropertyIDs = datasrcpropid;
    datasrcpropid[0] = DBPROP_CURRENTCATALOG;

    ret = property_ptr->GetProperties(2, propertysetids, &no_of_prop_sets, 
                                      &property_sets);
    if (FAILED(ret)) {
       croak("Internal error: property_ptr->GetProperties failed with hresult %x", ret);
    }

    // Get the SQL version. First the numeric version as a number.
    bstr = property_sets[0].rgProperties->vValue.bstrVal;
    swscanf_s(bstr, L"%d", &(mydata->majorsqlversion)); 
    if (mydata->majorsqlversion < 8) {
       olle_croak(olle_ptr, "Win32::SqlServer does not support connections version older than SQL 2000.\n");
    }

    // Decrease the refcnt for this SV, since we will create a new one.
    SvREFCNT_dec(mydata->SQL_version);

    // For the string value, we don't want any leading zero.
    if (bstr[0] == L'0') {
       mydata->SQL_version = BSTR_to_SV(bstr + 1);
    }
    else {
       mydata->SQL_version = BSTR_to_SV(bstr);
    }
    SysFreeString(bstr);

    // Get the current database.
    SvREFCNT_dec(mydata->CurrentDB);
    bstr = property_sets[1].rgProperties->vValue.bstrVal;
    mydata->CurrentDB = BSTR_to_SV(bstr);
    SysFreeString(bstr);

    
    OLE_malloc_ptr->Free(property_sets[0].rgProperties);
    OLE_malloc_ptr->Free(property_sets[1].rgProperties);
    OLE_malloc_ptr->Free(property_sets);
    property_ptr->Release();
}

// Sets the property for one property set. We have it all set up in mydata - 
// almost. Some property may have status -1, meaning that we should not set
// set them, so we copy to local variables.
void set_one_property_set (SV            * olle_ptr,
                           IDBProperties * property_ptr,
                           init_propsets   init_propset ) 
{
   internaldata * mydata = get_internaldata(olle_ptr);
   DBPROPSET      propset;
   DBPROP         properties[MAX_INIT_PROPERTIES];
   ULONG          prop_ix = 0;


   // Initialise the property set.
   propset.rgProperties    = properties;
   propset.cProperties     = 0;
   propset.guidPropertySet = mydata->init_propsets[init_propset].guidPropertySet;

   // Then copy the *defined* properties to the DBPROP array.
   for (UINT i = init_propset_info[init_propset].start;
        i < mydata->init_propsets[init_propset].cProperties +
             init_propset_info[init_propset].start; i++) {
      if (mydata->init_properties[i].dwStatus == DBPROPSTATUS_OK) {
         DBPROP  &prop = properties[prop_ix++];
         prop.dwPropertyID = mydata->init_properties[i].dwPropertyID;
         prop.dwOptions    = DBPROPOPTIONS_REQUIRED;
         prop.colid        = DB_NULLID;
         prop.dwStatus     = DBPROPSTATUS_OK;
         VariantInit(&prop.vValue);
         if (prop.dwPropertyID == SSPROP_INIT_ENCRYPT &&
             mydata->provider < provider_msoledbsql19) {
             // The special case. This property changed type in MSOLEDBSQL19, so 
             // for earlier versions, we need to use the older type.
             prop.vValue.vt = VT_BOOL;
             if (_wcsicmp(mydata->init_properties[i].vValue.bstrVal, 
                          L"Optional") == 0) {
                 prop.vValue.boolVal = FALSE;
             }
             else {
                 prop.vValue.boolVal = 0xFFFF;
             }
         }
         else {
            VariantCopy(&prop.vValue, &mydata->init_properties[i].vValue);
         }
      }
   }

   // If any properties were copied, we can set them now.
   if (prop_ix > 0) {
      propset.cProperties = prop_ix;
      HRESULT ret = property_ptr->SetProperties(1, &propset);
      if (FAILED(ret)) {
         dump_properties(properties, init_propset, propset.cProperties);
         croak("Internal error: property_ptr->SetProperties for initialization propset %d failed with hresult %x", init_propset, ret);
      }
   }
}

                     


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
       case provider_msoledbsql19 :
         clsid = &clsid_msoledbsql19;
         provider_name = "MSOLEDBSQL19";
         break;

       case provider_msoledbsql :
         clsid = &clsid_msoledbsql;
         provider_name = "MSOLEDBSQL";
         break;

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

    // Set the properties for the initialisation sets.
    set_one_property_set(olle_ptr, property_ptr, oleinit_props);
    set_one_property_set(olle_ptr, property_ptr, ssinit_props);

    // This is the place where we actually log in to SQL Server. We might
    // be reusing a connection from a pool.
    ret = mydata->init_ptr->Initialize();

    // If success, continue with creating data-source object.
    if (SUCCEEDED(ret)) {
       // Set properties for the data source.
       set_one_property_set(olle_ptr, property_ptr, datasrc_props);

       // Get a data source object.
       ret = mydata->init_ptr->QueryInterface(IID_IDBCreateSession,
                                            (void **) &(mydata->datasrc_ptr));
       check_for_errors(olle_ptr, "init_ptr->QueryInterface for data source",
                        ret);
       mydata->isautoconnected = isautoconnect;
    }
    else {
       check_for_errors(olle_ptr, "init_ptr->Initialize", ret);
    }

    // And release the property pointers.
    property_ptr->Release();

    // Make sure that SQL_version and current db is set.
    if (SUCCEEDED(ret)) {
       get_sqlversion_and_dbname (olle_ptr);
    }

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

   // AutoTranslate is not settable, and we pretend that it does not exist.
   if (gbl_init_props[ix].propset_enum == ssinit_props &&
       gbl_init_props[ix].property_id == SSPROP_INIT_AUTOTRANSLATE) {
     croak("Unknown property 'AutoTranslate' passed to setloginproperty");
   }


   // Some properties affects others.
   if (gbl_init_props[ix].propset_enum == oleinit_props &&
         gbl_init_props[ix].property_id == DBPROP_AUTH_USERID ||
         gbl_init_props[ix].property_id == SSPROP_AUTH_MODE   ||
         gbl_init_props[ix].property_id == SSPROP_AUTH_ACCESS_TOKEN) {
      // If userid is set, we clear Integrated security.
      setloginproperty(olle_ptr, "IntegratedSecurity", &PL_sv_undef);
   }
   else if (gbl_init_props[ix].propset_enum == oleinit_props &&
            gbl_init_props[ix].property_id == DBPROP_INIT_PROVIDERSTRING) {
      // In this case, all other properties should be ignored, except for
      // AUTOTRANSLATE, since we over rule its default.
      // We also except the Encrypt option, since for some reason it does not seem to work
      // in the provider string, so we want the setting through SetDefaultForEncryption to prevail.
      for (int j = 0; gbl_init_props[j].propset_enum != datasrc_props; j++) {
         if (! (gbl_init_props[j].propset_enum == ssinit_props &&
                   (mydata->init_properties[j].dwPropertyID == SSPROP_INIT_AUTOTRANSLATE ||
                    mydata->init_properties[j].dwPropertyID == SSPROP_INIT_ENCRYPT ||
                    mydata->init_properties[j].dwPropertyID == SSPROP_INIT_TRUST_SERVER_CERTIFICATE ||
                    mydata->init_properties[j].dwPropertyID == SSPROP_INIT_HOST_NAME_CERTIFICATE ||
                    mydata->init_properties[j].dwPropertyID == SSPROP_INIT_SERVER_CERTIFICATE))) {
            VariantClear(&mydata->init_properties[j].vValue);
         }
      }
   }

   // If the server changes, there are some attributes that are no
   // longer valid.
   if (gbl_init_props[ix].propset_enum == oleinit_props &&
       (gbl_init_props[ix].property_id == DBPROP_INIT_PROVIDERSTRING ||
        gbl_init_props[ix].property_id == DBPROP_INIT_DATASOURCE ||
        gbl_init_props[ix].property_id == SSPROP_INIT_NETWORKADDRESS)) {
      free_sqlver_currentdb(mydata);
      ClearCodepages(olle_ptr);
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
    
   // So does the Authentication property.
   if (gbl_init_props[ix].propset_enum == ssinit_props &&
       gbl_init_props[ix].property_id == SSPROP_AUTH_MODE) {
       char * authmode = SvPV_nolen(prop_value);
       if (_stricmp(authmode, "SqlPassword") != 0                     &&
           _stricmp(authmode, "ActiveDirectoryIntegrated") != 0       &&
           _stricmp(authmode, "ActiveDirectoryPassword") != 0         &&
           _stricmp(authmode, "ActiveDirectoryInteractive") != 0      &&
           _stricmp(authmode, "ActiveDirectoryServicePrincipal") != 0 &&
           _stricmp(authmode, "ActiveDirectoryMSI") != 0) {
              croak("Illegal value '%s' passed for the '%s' property",
                    authmode, prop_name);
       }
   }
        

   // First mark that the property has been set explicitly.
   mydata->init_properties[ix].dwStatus = DBPROPSTATUS_OK;
   
   // clear the current value and set property to VT_EMPTY.
   VariantClear(&mydata->init_properties[ix].vValue);

   // Then set the value appropriately
   if (my_sv_is_defined(prop_value)) {
      mydata->init_properties[ix].vValue.vt = gbl_init_props[ix].datatype;

      // First handle any specials. Currently there are three.
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
      else if (gbl_init_props[ix].propset_enum == ssinit_props &&
               gbl_init_props[ix].property_id == SSPROP_INIT_ENCRYPT) {
         if (SvIOK(prop_value)) {
             mydata->init_properties[ix].vValue.bstrVal = 
                 SysAllocString(SvTRUE(prop_value) ? L"Mandatory" : L"Optional");
         }
         else {
            char * encryptopt = SvPV_nolen(prop_value);
            if (_stricmp(encryptopt, "no") == 0 ||
                _stricmp(encryptopt, "false") == 0 ||
                _stricmp(encryptopt, "optional") == 0) {
               mydata->init_properties[ix].vValue.bstrVal = 
                     SysAllocString(L"Optional");
            }
            else if (_stricmp(encryptopt, "yes") == 0 ||
                     _stricmp(encryptopt, "true") == 0 ||
                     _stricmp(encryptopt, "mandatory") == 0) {
               mydata->init_properties[ix].vValue.bstrVal = 
                     SysAllocString(L"Mandatory");
            }
            else if (_stricmp(encryptopt, "strict") == 0) {
               mydata->init_properties[ix].vValue.bstrVal = 
                     SysAllocString(L"Strict");
            }
            else {
               croak("Illegal value '%s' passed for the '%s' property",
                     encryptopt, prop_name);
            }
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
BOOL setup_datasrc(SV * olle_ptr)
{
   internaldata * mydata = get_internaldata(olle_ptr);

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
   else {
      // Refresh SQL version and database (the latter can have changed).
      get_sqlversion_and_dbname (olle_ptr);
   }   

   return TRUE;
}

// Creates the session object if needed.
BOOL setup_session(SV * olle_ptr)
{
   internaldata * mydata = get_internaldata(olle_ptr);
   HRESULT        ret;

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
