#ifndef __TIMEOFD_H
#define __TIMEOFD_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// returns the time of day information from a specified server
//
// param:  server - computer to get the time from
//         info   - time information to return
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetRemoteTOD);


///////////////////////////////////////////////////////////////////////////////
//
// queries the redirector to retrieve the optional features the remote system 
// supports
//
// param:  server			- computer to get the info from
//         wanted			- options to receive from the remote system
//				 supported	- options supported by the remote system
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetRemoteComputerSupports);


#endif //#ifndef __TIMEOFD_H
