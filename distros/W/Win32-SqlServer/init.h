/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/init.h 4     12-08-15 21:27 Sommar $

  This file holds code associated with module and object initialitaion.
  This file also declares global variables that exist through the lifetime
  of the DLL. They are constants that are set up once and then never changed.

  The header file also define some enums related to initialisation.


  Copyright (c) 2004-2008   Erland Sommarskog

  $History: init.h $
 * 
 * *****************  Version 4  *****************
 * User: Sommar       Date: 12-08-15   Time: 21:27
 * Updated in $/Perl/OlleDB
 * One new login property for SQL 2012 and two new for SQL 2008. Now track
 * the number of properties per version of  the OLE DB provider.
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 12-07-20   Time: 23:50
 * Updated in $/Perl/OlleDB
 * Add support for SQLNCLI11.
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
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


// Definitions of all possible providers as an enum.
typedef enum provider_enum {
    provider_default, provider_sqloledb, provider_sqlncli, 
    provider_sqlncli10, provider_sqlncli11
} provider_enum;

// And here is global variables for the classids for the possible providers.
extern CLSID  clsid_sqloledb;
extern CLSID  clsid_sqlncli;
extern CLSID  clsid_sqlncli10;
extern CLSID  clsid_sqlncli11;


// This is stuff for init properties. When the module starts up, we set up a
// static array, and then is read-only.
typedef enum init_propsets
    {not_in_use = -1, oleinit_props = 0, ssinit_props = 1, datasrc_props = 2}
init_propsets;
#define NO_OF_INIT_PROPSETS 3


#define INIT_PROPNAME_LEN 50
typedef struct {
   char             name[INIT_PROPNAME_LEN];  // Name of prop exposed to user.
   init_propsets    propset_enum;    // In which property set property belongs.
   BOOL             is_sqloledb;     // This is a property that SQLOLEDB 2.6 supports.
   DBPROPID         property_id;    // ID for property in OLE DB.
   VARTYPE          datatype;       // Datatype of the property.
   VARIANT          default_value;  // Default value for the property.
} init_property;
#define MAX_INIT_PROPERTIES 50


extern init_property gbl_init_props[MAX_INIT_PROPERTIES];

// This array holds where each property set starts in gbl_init_props;
typedef struct {
   int start;
   int no_of_props;
} propset_info_struct;
extern propset_info_struct init_propset_info[NO_OF_INIT_PROPSETS];


// Returns the number of properties in the SSPROP structure for the 
// given provider.
extern int no_of_ssprops(provider_enum);

// Global pointer to OLE DB Services. Set once when we intialize, and
// never released.
extern IDataInitialize * data_init_ptr;

// Global pointer the OLE DB conversion library.
extern IDataConvert    * data_convert_ptr;

// Global pointer to the IMalloc interface. Most of the time when we allocate
// memory, we rely on the Perl methods. However, there are situations when
// we must free memory allocated by SQLOLEDB. Same here, we create once, as
// the COM implementation is touted as thread-safe.
extern IMalloc*   OLE_malloc_ptr;


// Invoked by the BOOT section in the XS code.
extern void initialize();

// This routine returns the default provider, which is highest version of
// SQL Native Client/SQLOLEDB that is installed.
extern provider_enum default_provider(void);



