#ifndef __SESSION_H
#define __SESSION_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// ends a session between a server and a workstation
//
// param:  server - computer to execute the command
//				 client - computer name of the client to disconnect
//				 user   - name of the user whose session is to be terminated
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetSessionDel);


///////////////////////////////////////////////////////////////////////////////
//
// provides information about all current sessions
//
// param:  server - computer to execute the command
//				 client - computer name of the client to enum
//				 user   - name of the user to enum
//				 info		- array to store session info
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetSessionEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a session established 
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

XS(XS_NT__Lanman_NetSessionGetInfo);



#endif //#ifndef __SESSION_H
