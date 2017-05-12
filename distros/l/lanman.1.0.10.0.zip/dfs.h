#ifndef __DFS_H
#define __DFS_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// adds a new dfs directory
//
// param:  entryPath - directory in the dfs root to use as junction to 
//										 server\share
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//				 comment	 - optional comment
//				 flags		 - optional flags (DFS_ADD_VOLUME or DFS_RESTORE_VOLUME)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAdd);


///////////////////////////////////////////////////////////////////////////////
//
// enums all dfs information on a dfs server
//
// param:  server	- dfs server name
//         dfs		- array to store the information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsEnum);


///////////////////////////////////////////////////////////////////////////////
//
// gets information about a dfs
//
// param:  entryPath - directory in the dfs root
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//         dfs			 - hash to store the information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; if you 
//				 interested in information about a specific storage, specify
//				 the server and share name; if you want information about all 
//				 storages in a volume, leave server and share empty
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// removes a volume or storage space from the dfs directory; when applied to the
// latest storage in a volume, removes the volume from the dfs
//
// param:  entryPath - directory in the dfs root used as junction to 
//										 server\share
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemove);


///////////////////////////////////////////////////////////////////////////////
//
// sets information about a dfs
//
// param:  entryPath - directory in the dfs root
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//         dfs			 - hash to set the information 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; if you 
//				 interested to set information about a specific storage, specify
//				 the server and share name; if you set want information about all 
//				 storages in a volume, leave server and share empty; currently, 
//				 you can only set the comment
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// renames a dfs directory
//
// param:  oldEntryPath - current dfs directory
//				 newEntryPath - new dfs directory name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; it seems this
//				 call is not supported in NT4 (you will get error code 50)
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRename);


///////////////////////////////////////////////////////////////////////////////
//
// creates the root of a new domain-based Dfs implementation; if the root 
// already exists, the function adds (joins) the specified server and share 
// to the root
//
// param:  server		- computer to execute the command
//				 root			- name of the share that will host the root
//				 ftDfs		- name of the root to create or join
//				 comment	- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsMove);


///////////////////////////////////////////////////////////////////////////////
//
// creates the root of a new domain-based Dfs implementation; if the root 
// already exists, the function adds (joins) the specified server and share 
// to the root
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that will host the root
//				 ftDfs			- name of the dfs root to create or join
//				 comment		- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAddFtRoot);


///////////////////////////////////////////////////////////////////////////////
//
// removes the server and share at the root of a domain-based dfs
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that hosts the root
//				 ftdfs			- name of the domain based dfs root
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemoveFtRoot);


///////////////////////////////////////////////////////////////////////////////
//
// removes the specified server and share from a domain-based dfs root, even if 
// the server is offline
//
// param:  domain			- domain name
//				 server			- computer to execute the command
//				 rootshare	- name of the share that hosts the root
//				 ftdfs			- name of the domain based dfs root
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemoveFtRootForced);


///////////////////////////////////////////////////////////////////////////////
//
// creates the root for a new stand-alone dfs implementation
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that will host the root
//				 comment		- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAddStdRoot);


///////////////////////////////////////////////////////////////////////////////
//
// creates the root for a new stand-alone dfs implementation allowing an 
// offline share to host the Dfs root
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that will host the root
//				 store			- path to the share that will host the new dfs root
//				 comment		- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAddStdRootForced);


///////////////////////////////////////////////////////////////////////////////
//
// removes the server and share at the root of a stand-alone dfs
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that hosts the root
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemoveStdRoot);


///////////////////////////////////////////////////////////////////////////////
//
// restarts the dfs service
//
// param:  server		- computer to execute the command
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsManagerInitialize);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a dfs link in the named Dfs root
//
// param:  entrypath	- unc path of a dfs link in a dfs root (dfs\share\link or
//											domain\dfs\link)
//				 server			- optional name of the host server that the link 
//											references
//				 share			- share name on the host server that the link references
//				 info				- retrieves the client information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsGetClientInfo);


///////////////////////////////////////////////////////////////////////////////
//
// associates information with a dfs link in the named dfs root
//
// param:  entrypath	- unc path of a dfs link in a dfs root (dfs\share\link or
//											domain\dfs\link)
//				 server			- optional name of the host server that the link 
//											references
//				 share			- optional share name on the host server that the link 
//											references
//				 info				- contains the information to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////


XS(XS_NT__Lanman_NetDfsSetClientInfo);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about the dfs domain controller
//
// param:  server	- computer to execute the command
//				 info		- retrieves the information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsGetDcAddress);


#endif //#ifndef __DFS_H

