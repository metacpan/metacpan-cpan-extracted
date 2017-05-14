#ifndef __WNETWORK_H
#define __WNETWORK_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// makes a connection to a network resource 
//
// param:  connInfo	- hash with the connection info
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetAddConnection);

///////////////////////////////////////////////////////////////////////////////
//
// cancels an existing network connection
//
// param:  conn					- connection to remove
//				 flags				-	connection type (must be CONNECT_UPDATE_PROFILE or 0)
//				 forcecancel	- enforces the disconnect even if there are open files
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetCancelConnection);

///////////////////////////////////////////////////////////////////////////////
//
// enumerates network resources
//
// param:  scope			- connection scope
//				 type				- connection type
//				 usage			- connection usage
//				 startinfo	- location to start from
//				 resinfo		- retrieves the resource infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetEnumResource);

///////////////////////////////////////////////////////////////////////////////
//
// starts a browsing dialog box for connecting to network resources
//
// param:  info	- specifies options for the dialog box
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetConnectionDialog);

///////////////////////////////////////////////////////////////////////////////
//
// starts a browsing dialog box for disconnecting from network resources
//
// param:  hwnd		- owner window for the dialog box
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetDisconnectDialog);

///////////////////////////////////////////////////////////////////////////////
//
// retrieves the name of the network resource associated with a local device
//
// param:  local	- local name
//				 remote	- retrieves the remote name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetConnection);

///////////////////////////////////////////////////////////////////////////////
//
// returns extended information about a specific network provider
//
// param:  provider	- provider name
//				 info			- retrieves the network infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetNetworkInformation);

///////////////////////////////////////////////////////////////////////////////
//
// obtains the provider name for a specific type of network
//
// param:  type			- network type
//				 provider	- retrieves the provider name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetProviderName);

///////////////////////////////////////////////////////////////////////////////
//
// provided with a remote path to a network resource, the function identifies 
// the network provider that owns the resource and obtains information about 
// the type of the resource
//
// param:  resource - resource information to get the info for
//				 info			- retrieves the info
//				 
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetResourceInformation);

///////////////////////////////////////////////////////////////////////////////
//
// returns the parent of a network resource in the network browse hierarchy
//
// param:  resouce	- resource information to get the parent for
//				 parent		- retrieves the parent
//				 
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetResourceParent);

///////////////////////////////////////////////////////////////////////////////
//
// returns information that contains a more universal form of a local name
//
// param:  localpath	- local resource name
//				 info				- retrieves the unc path info
//				 
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetUniversalName);

///////////////////////////////////////////////////////////////////////////////
//
// retrieves the current default user name, or the user name used to establish 
// a network connection
//
// param:  resource	- network resource
//				 user			- retrieves the user name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetGetUser);

///////////////////////////////////////////////////////////////////////////////
//
// makes a connection to a network resource
//
// param:  resource	- hash with info about the connection
//				 connInfo	- receives the connection info
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetUseConnection);

#endif //#ifndef __WNETWORK_H
