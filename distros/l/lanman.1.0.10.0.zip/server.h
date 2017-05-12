#ifndef __SERVER_H
#define __SERVER_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// retrieves a list of disk drives on a server
//
// param:  server - computer to execute the command
//				 info		- array to store disk names
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerDiskEnum);


///////////////////////////////////////////////////////////////////////////////
//
// lists all servers of the specified type that are visible in the specified 
// domain
//
// param:  server - computer to execute the command
//				 domain - domain name to enum servers
//				 type		- server types to enum
//				 info		- array to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about the specified server
//
// param:  server		- computer to execute the command
//				 info			- hash to store server information
//				 fullinfo - if not null, extended ínformation will be retrieved
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// sets a server’s operating parameters
//
// param:  server		- computer to execute the command
//				 info			- hash to set server information
//				 fullinfo - if not null, extended ínformation will be set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// binds the server to the transport
//
// param:  server - computer to execute the command
//				 info		- hash to set server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerTransportAdd);


///////////////////////////////////////////////////////////////////////////////
//
// unbinds (or disconnects) the transport protocol from the server
//
// param:  server - computer to execute the command
//				 info		- hash to set server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerTransportDel);


///////////////////////////////////////////////////////////////////////////////
//
// supplies information about transports that are managed by the server
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

XS(XS_NT__Lanman_NetServerTransportEnum);


#endif //#ifndef __SERVER_H
