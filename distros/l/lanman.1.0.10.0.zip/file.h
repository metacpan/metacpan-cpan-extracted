#ifndef __FILE_H
#define __FILE_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// supplies information about some or all open files on a server
//
// param:  server - computer to execute the command
//				 path		- base path to get information from
//         user   - user name filter
//				 info		- array to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetFileEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a particular opening of a server resource
//
// param:  server - computer to execute the command
//				 fileid	- a file id supplied by NetFileEnum
//				 info		- hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetFileGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// closes a file handle on a server
//
// param:  server - computer to execute the command
//				 fileid	- a file id supplied by NetFileEnum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetFileClose);


#endif //#ifndef __FILE_H
