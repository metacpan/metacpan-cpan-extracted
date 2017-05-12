#ifndef __TERMSERV_H
#define __TERMSERV_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// initializes the terminal server api dll (wtsapi32.dll)
//
// param:  
//
// return: success - 1 
//         failure - 0 
//
// note:   if the dll isn't loaded successfully or if a function could not be
//				 resolved, all other function pointers will be set to null and the
//				 result is a 0; call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

int InitWTSDll();


///////////////////////////////////////////////////////////////////////////////
//
// unloads the terminal server api dll (wtsapi32.dll)
//
// param:  
//
// return: success - 1 (returns always 1)
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

int ReleaseWTSDll();


///////////////////////////////////////////////////////////////////////////////
//
// gets the terminal server user properties
//
// param:  server	- computer to execute the command
//				 user		- user name
//				 config - information to retrieve
//				 info		- hash to store infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSQueryUserConfig);


///////////////////////////////////////////////////////////////////////////////
//
// sets the terminal server user properties
//
// param:  server	- computer to execute the command
//				 user		- user name
//				 info		- properties to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSSetUserConfig);


///////////////////////////////////////////////////////////////////////////////
//
// opens an handle to a terminal server
//
// param:  server	- terminal server name
//				 handle	- gets the handle
//
// return: success - 1 
//         failure - 0 
//
// note:   it's neccessary to close the handle with WTSCloseServer if the work
//				 with the handle is finished; if your application runs on the 
//				 terminal server, WTSOpenServer it's not neccessary, you can use 
//				 WTS_CURRENT_SERVER_HANDLE instead; call GetLastError() to get the 
//				 error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSOpenServer);


///////////////////////////////////////////////////////////////////////////////
//
// closes an handle to a terminal server
//
// param:  handle	- handle to the terminal server
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSCloseServer);


///////////////////////////////////////////////////////////////////////////////
//
// enumerates terminal servers in a domain
//
// param:  domain  - domain name
//				 servers - gets the server infos
//
// return: success - 1
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSEnumerateServers);


///////////////////////////////////////////////////////////////////////////////
//
// enumerates sessions on a terminal server
//
// param:  server		- terminal server name
//				 sessions - gets the session infos
//
// return: success - 1
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSEnumerateSessions);


///////////////////////////////////////////////////////////////////////////////
//
// enumerates processes on a terminal server
//
// param:  server		 - terminal server name
//				 processes - gets the processes infos
//
// return: success - 1
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSEnumerateProcesses);


///////////////////////////////////////////////////////////////////////////////
//
// terminates a process a terminal server
//
// param:  server	  - terminal server name
//				 process  - process id
//				 exitcode - process' exit code; optional - default 0
//
// return: success - 1
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSTerminateProcess);


///////////////////////////////////////////////////////////////////////////////
//
// returns information about the specified session on a terminal server
//
// param:  server	   - terminal server name
//				 sessionId - session id
//				 infoClass - information type to retrieve
//				 info			 - gets the session information
//
// return: success - 1
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSQuerySessionInformation);


///////////////////////////////////////////////////////////////////////////////
//
// displays a message box on the client desktop of a terminal server session
//
// param:  server		 - computer to execute the command
//				 sessionId - session id
//				 title		 - message box title
//				 message	 - message to display
//				 style		 - message box style (see MessageBox constants in the 
//										 Win32-Api), optional - default MB_OK
//				 timeout   - specifies the time, in seconds, that the function waits 
//										 for the user's response; optional - default 0
//				 response	 - gets the function result; optional
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSSendMessage);


///////////////////////////////////////////////////////////////////////////////
//
// disconnects the logged on user from the specified terminal server session 
// without closing the session
//
// param:  server		 - computer to execute the command
//				 sessionId - session id
//				 wait			 - indicates whether the operation is synchronous; 
//										 optional - default asynchonous
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSDisconnectSession);


///////////////////////////////////////////////////////////////////////////////
//
// logs off the specified terminal server session 
//
// param:  server		 - computer to execute the command
//				 sessionId - session id
//				 wait			 - indicates whether the operation is synchronous; 
//										 optional - default asynchonous
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSLogoffSession);


///////////////////////////////////////////////////////////////////////////////
//
// shuts down the specified terminal server
//
// param:  server	- computer to shut down
//				 flag		- shutdown flag; optional - default 0
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSShutdownSystem);


///////////////////////////////////////////////////////////////////////////////
//
// waits for a terminal server event before returning to the caller
//
// param:  server	- computer to shut down
//				 mask		- bit mask that specifies the set of events to wait for
//				 flags	- receives the event(s) occured
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSWaitSystemEvent);



#endif //#ifndef __TERMSERV_H
