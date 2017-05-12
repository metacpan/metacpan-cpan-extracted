#ifndef __USE_H
#define __USE_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// establishes a connection between a local or NULL device name and a shared 
// resource by redirecting the local or NULL (UNC) device name to the shared 
// resource
//
// param:  useinfo - info to establish a connection
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseAdd);


///////////////////////////////////////////////////////////////////////////////
//
// deletes a connection to a shared resource
//
// param:  usename  - connection name to delete
//				 forcedel - forces a disconnect if there are still opens
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseDel);


///////////////////////////////////////////////////////////////////////////////
//
// enums all connections to a shared resource
//
// param:  info  - array to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseEnum);


///////////////////////////////////////////////////////////////////////////////
//
// gets information about a connection to a shared resource
//
// param:  usename - connection name to get information for
//				 info		 - hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseGetInfo);


#endif //#ifndef __USE_H
