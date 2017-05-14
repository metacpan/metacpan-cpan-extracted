#ifndef __SHARE_H
#define __SHARE_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// creates a share
//
// param:  server    - computer to execute the command
//         shareinfo - info about the share
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetShareAdd);


///////////////////////////////////////////////////////////////////////////////
//
// checks the existance of a share
//
// param:  server - computer to execute the command
//         device - device name
//				 type   - gets the device type
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetShareCheck);


///////////////////////////////////////////////////////////////////////////////
//
// deletes a share
//
// param:  server - computer to execute the command
//         device - device name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetShareDel);


///////////////////////////////////////////////////////////////////////////////
//
// enums all shares on a server
//
// param:  server - computer to execute the command
//         info   - info about the shares
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetShareEnum);


///////////////////////////////////////////////////////////////////////////////
//
// gets information about a share
//
// param:  server - computer to execute the command
//         share  - share name
//				 info   - info about the share
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetShareGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// sets share information
//
// param:  server - computer to execute the command
//         share  - share name
//				 info   - info about the share
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetShareSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// lists all connections made to a shared resource on the server or all 
// connections established from a particular computer
//
// param:  server							- computer to execute the command
//         share_or_computer  - share name or computer name
//				 info								- info about the connections
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetConnectionEnum);


#endif //#ifndef __SHARE_H
