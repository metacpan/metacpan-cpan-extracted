#ifndef __HANDLE_H
#define __HANDLE_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// retrieves handle-specific information for character-device and named-pipe 
// handles
//
// param:  handle - handle to a character device or a named pipe
//         info		- info to return
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetHandleGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// sets handle-specific information for character-device and named-pipe handles
//
// param:  handle - handle to a character device or a named pipe
//         info		- info to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetHandleSetInfo);



#endif //#ifndef __HANDLE_H
