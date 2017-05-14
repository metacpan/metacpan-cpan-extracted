#ifndef __MESSAGE_H
#define __MESSAGE_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// sends a message
//
// param:  server	 - computer to execute the command
//				 to			 - name to send the message
//				 from		 - name where the message is from
//				 message - message text
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageBufferSend);


///////////////////////////////////////////////////////////////////////////////
//
// registers a message alias in the message name table
//
// param:  server			 - computer to execute the command
//				 messagename - message name to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameAdd);


///////////////////////////////////////////////////////////////////////////////
//
// deletes a message alias from the table of message aliases
//
// param:  server			 - computer to execute the command
//				 messagename - message name to delete
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameDel);


///////////////////////////////////////////////////////////////////////////////
//
// lists the message aliases that will receive messages
//
// param:  server			 - computer to execute the command
//				 messagename - message name to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a message alias in the message name table
//
// param:  server	- computer to execute the command
//				 info		- message info to enum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameGetInfo);


#endif //#ifndef __MESSAGE_H
