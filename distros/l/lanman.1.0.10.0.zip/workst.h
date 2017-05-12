#ifndef __WORKST_H
#define __WORKST_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
//
// returns information about the configuration elements for a workstation
//
// param:  server   - computer to execute the command
//				 info			- hash to store workstation information
//				 fullinfo - if not null, extended ínformation will be retrieved
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// configures a workstation
//
// param:  server		- computer to execute the command
//				 info			- hash to set server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// binds (or connects) the redirector to the transport
//
// param:  server - computer to execute the command
//				 info		- hash to set transport information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaTransportAdd);


///////////////////////////////////////////////////////////////////////////////
//
// unbinds the transport protocol from the redirector
//
// param:  server		 - computer to execute the command
//				 transport - name of the transport from which to unbind
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaTransportDel);


///////////////////////////////////////////////////////////////////////////////
//
// supplies information about transport protocols that are managed by the 
// redirector
//
// param:  server - computer to execute the command
//				 info		- array to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaTransportEnum);  


///////////////////////////////////////////////////////////////////////////////
//
// returns information about the currently logged-on user. This function must 
// be called in the context of the logged-on user
//
// param:  info	- hash to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaUserGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// returns information about the currently logged-on user. This function must 
// be called in the context of the logged-on user
//
// param:  info	- hash to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaUserSetInfo); 


///////////////////////////////////////////////////////////////////////////////
//
// lists information about all users currently logged on to the workstation 
//
// param:  server - computer to execute the command
//				 info		- array to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaUserEnum);


#endif //#ifndef __WORKST_H
