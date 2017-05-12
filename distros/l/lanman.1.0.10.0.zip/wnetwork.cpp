#define WIN32_LEAN_AND_MEAN


#ifndef __WNETWORK_CPP
#define __WNETWORK_CPP
#endif


#include <windows.h>
#include <objbase.h>


#include "wnetwork.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////


#define CleanNetEnum(handle) { if(handle) {	WNetCloseEnum(handle); handle = NULL; } }

		
///////////////////////////////////////////////////////////////////////////////
//
// globals
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

XS(XS_NT__Lanman_WNetAddConnection)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *connInfo = NULL;

	if(items == 1 && CHK_ASSIGN_HREF(connInfo, ST(0)))
	{
		NETRESOURCE netResource;
		PSTR userName = NULL, password = NULL;
		HWND hWndOwner = NULL;
		int flags = 0;

		__try
		{
			memset(&netResource, 0, sizeof(netResource));

			// retrieve members
			netResource.dwType = H_FETCH_INT(connInfo, "type");
			netResource.lpLocalName = H_FETCH_STR(connInfo, "localname");
			netResource.lpRemoteName = H_FETCH_STR(connInfo, "remotename");
			netResource.lpProvider = H_FETCH_STR(connInfo, "provider");
			userName = H_FETCH_STR(connInfo, "username");
			password = H_FETCH_STR(connInfo, "password");
			flags = H_FETCH_INT(connInfo, "flags");

			if(H_EXISTS(connInfo, "hwndowner"))
			{
				hWndOwner = (HWND)H_FETCH_INT(connInfo, "hwndowner");

				// create connection
				LastError(WNetAddConnection3(hWndOwner, &netResource, password, userName, flags));
			}
			else
				// create connection
				LastError(WNetAddConnection2(&netResource, password, userName, flags));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up

	} // if(items == 1 && ...)
	else
		croak("Usage: Win32::Lanman::WNetAddConnection(\\%%useinfo)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetCancelConnection)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items >= 1 && items <= 3)
	{
		PSTR connection = NULL;
		int flags = 0;
		int forceCancel = 0;

		__try
		{
			// retrieve connection, flag and force flag
			connection = SvPV(ST(0), PL_na);
			flags = items >= 2 ? SvIV(ST(1)): 0;
			forceCancel = items == 3 ? SvIV(ST(2)): 0;

			// cancel connection
			LastError(WNetCancelConnection2(connection, flags, forceCancel));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
	} // if(items >= 1 && items <= 3)
	else
		croak("Usage: Win32::Lanman::WNetCancelConnection($conn [, $flags [, $forcecancel] ])\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetEnumResource)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *startInfo = NULL;
	AV *resInfo = NULL;

	if(items == 5 && CHK_ASSIGN_AREF(resInfo, ST(4)))
	{
		int enumScope = 0, enumType = 0, enumUsage = 0, entriesCount = -1;

		HANDLE hEnumRes = NULL;
		NETRESOURCE *netResource = NULL, *resources = NULL;
		DWORD resourcesSize = 0;

		__try
		{
			// clear array
			AV_CLEAR(resInfo);

			enumScope = SvIV(ST(0));
			enumType = SvIV(ST(1));
			enumUsage = SvIV(ST(2));

			if(CHK_ASSIGN_HREF(startInfo, ST(3)))
			{
				netResource = (NETRESOURCE*)NewMem(sizeof(NETRESOURCE));

				netResource->dwScope = H_FETCH_INT(startInfo, "scope");
				netResource->dwType = H_FETCH_INT(startInfo, "type");
				netResource->dwDisplayType = H_FETCH_INT(startInfo, "displaytype");
				netResource->dwUsage = H_FETCH_INT(startInfo, "usage");
				netResource->lpLocalName = H_FETCH_STR(startInfo, "localname");
				netResource->lpRemoteName = H_FETCH_STR(startInfo, "remotename");
				netResource->lpComment = H_FETCH_STR(startInfo, "comment");
				netResource->lpProvider = H_FETCH_STR(startInfo, "provider");
			}

			// alloc memory
			resources = (NETRESOURCE*)NewMem(resourcesSize = 0x4000);

			// open resource
			if(!LastError(WNetOpenEnum(enumScope, enumType, enumUsage, netResource, &hEnumRes)))
			{
				// retrieve resource data
				if((error = WNetEnumResource(hEnumRes, (PDWORD)&entriesCount, resources,
																		 &resourcesSize)) != ERROR_NO_MORE_ITEMS)
					LastError(error);

				for(int count = 0; count < entriesCount; count++)
				{
					// store resource properties
					HV *properties = NewHV;

					H_STORE_INT(properties, "scope", resources[count].dwScope);
					H_STORE_INT(properties, "type", resources[count].dwType);
					H_STORE_INT(properties, "displaytype", resources[count].dwDisplayType);
					H_STORE_INT(properties, "usage", resources[count].dwUsage);
					H_STORE_STR(properties, "localname", resources[count].lpLocalName);
					H_STORE_STR(properties, "remotename", resources[count].lpRemoteName);
					H_STORE_STR(properties, "comment", resources[count].lpComment);
					H_STORE_STR(properties, "provider", resources[count].lpProvider);

					A_STORE_REF(resInfo, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetEnum(hEnumRes);
		CleanPtr(netResource);
		CleanPtr(resources);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::WNetEnumResource($scope, $type, $usage, \\%%startinfo, "
																									"\\@resinfo)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetConnectionDialog)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items <= 1)
	{
		CONNECTDLGSTRUCT connDialog;
		NETRESOURCE netResource;

		__try
		{
			// set stucture content
			memset(&connDialog, 0, sizeof(connDialog));
			memset(&netResource, 0, sizeof(netResource));

			connDialog.cbStructure = sizeof(connDialog);
			connDialog.lpConnRes = &netResource;

			netResource.dwType = RESOURCETYPE_DISK;

			// fill optional elements
			if(CHK_ASSIGN_HREF(info, ST(0)))
			{
				connDialog.hwndOwner = (HWND)H_FETCH_INT(info, "owner");
				connDialog.dwFlags = H_FETCH_INT(info, "flags");
				netResource.lpRemoteName = H_FETCH_STR(info, "remotename");
			}

			// establish connection
			if(!LastError(WNetConnectionDialog1(&connDialog)))
				if(CHK_ASSIGN_HREF(info, ST(0)))
					H_STORE_INT(info, "devnum", connDialog.dwDevNum);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
	} // if(items <= 1)
	else
		croak("Usage: Win32::Lanman::WNetConnectionDialog([ \\%%info ])\n");

	RETURNRESULT(LastError() == 0);
}

///////////////////////////////////////////////////////////////////////////////
//
// starts a browsing dialog box for disconnecting from network resources
//
// param:  info	- specifies options for the dialog box
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WNetDisconnectDialog)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items <= 1)
	{
		DISCDLGSTRUCT disconnDialog;

		__try
		{
			// set stucture content
			memset(&disconnDialog, 0, sizeof(disconnDialog));

			disconnDialog.cbStructure = sizeof(disconnDialog);

			// fill optional elements
			if(CHK_ASSIGN_HREF(info, ST(0)))
			{
				disconnDialog.hwndOwner = (HWND)H_FETCH_INT(info, "owner");
				disconnDialog.lpLocalName = H_FETCH_STR(info, "localname");
				disconnDialog.lpRemoteName = H_FETCH_STR(info, "remotename");
				disconnDialog.dwFlags = H_FETCH_INT(info, "flags");
			}

			// cancel connection
			if(disconnDialog.lpLocalName || disconnDialog.lpRemoteName || disconnDialog.dwFlags)
				LastError(WNetDisconnectDialog1(&disconnDialog));
			else
				LastError(WNetDisconnectDialog(disconnDialog.hwndOwner, RESOURCETYPE_DISK));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
	} // if(items <= 1)
	else
		croak("Usage: Win32::Lanman::WNetDisconnectDialog([ \\%%info ])\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetConnection)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *remote = NULL;

	if(items == 2 && CHK_ASSIGN_SREF(remote, ST(1)))
	{
		PSTR localName = SvPV(ST(0), PL_na);
		PSTR remoteName = NULL;
		DWORD remoteNameSize = 0;

		__try
		{
			// clear scalar
			SV_CLEAR(remote);

			// alloc memory (64 bytes should be enought in most cases)
			remoteName = NewMem(remoteNameSize = 64);

			if((error = WNetGetConnection(localName, remoteName, &remoteNameSize)) == ERROR_MORE_DATA)
			{
				// realloc memory
				remoteName = NewMem(remoteName, remoteNameSize, 1);
			
				// try again
				error = WNetGetConnection(localName, remoteName, &remoteNameSize);
			}

			// store remote name
			if(!LastError(error))
				S_STORE_STR(remote, remoteName);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
		CleanPtr(remoteName);

	} // if(items == 2 && CHK_ASSIGN_SREF(remote, ST(1)))
	else
		croak("Usage: Win32::Lanman::WNetGetConnection($local, \\$remote)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetNetworkInformation)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PSTR provider = SvPV(ST(0), PL_na);
		NETINFOSTRUCT netInfo;

		__try
		{
			// clear hash
			HV_CLEAR(info);

			memset(&netInfo, 0, sizeof(netInfo));
			
			netInfo.cbStructure = sizeof(netInfo);

			// get network information
			if(!LastError(WNetGetNetworkInformation(provider, &netInfo)))
			{
				// store infos
				H_STORE_INT(info, "providerversion", netInfo.dwProviderVersion);
				H_STORE_INT(info, "status", netInfo.dwStatus);
				H_STORE_INT(info, "characteristics", netInfo.dwCharacteristics);
				H_STORE_INT(info, "handle", netInfo.dwHandle);
				H_STORE_INT(info, "nettype", ((DWORD)netInfo.wNetType) << 16);
				H_STORE_INT(info, "printers", netInfo.dwPrinters);
				H_STORE_INT(info, "drives", netInfo.dwDrives);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
	} // if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	else
		croak("Usage: Win32::Lanman::WNetGetNetworkInformation($provider, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetProviderName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *provider = NULL;

	if(items == 2 && CHK_ASSIGN_SREF(provider, ST(1)))
	{
		DWORD type = SvIV(ST(0));
		PSTR providerName = NULL;
		DWORD providerNameSize = 0;

		__try
		{
			// clear scalar
			SV_CLEAR(provider);

			// alloc memory (64 bytes should be enought in most cases)
			providerName = NewMem(providerNameSize = 64);

			if((error = WNetGetProviderName(type, providerName, &providerNameSize)) == ERROR_MORE_DATA)
			{
				// realloc memory
				providerName = NewMem(providerName, providerNameSize, 1);
			
				// try again
				error = WNetGetProviderName(type, providerName, &providerNameSize);
			}

			// store provider name
			if(!LastError(error))
				S_STORE_STR(provider, providerName);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
		CleanPtr(providerName);
	} // if(items == 2 && ... )
	else
		croak("Usage: Win32::Lanman::WNetGetProviderName($type, \\$provider)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetResourceInformation)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *resource = NULL;
	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(resource, ST(0)) && CHK_ASSIGN_HREF(info, ST(1)))
	{
		NETRESOURCE netResource, *infoResource = NULL;
		DWORD infoResourceSize = 0;
		PSTR system = NULL;

		__try
		{
			// clear hash
			HV_CLEAR(info);

			memset(&netResource, 0, sizeof(netResource));
			
			netResource.dwType = H_FETCH_INT(resource, "type");
			netResource.lpRemoteName = H_FETCH_STR(resource, "remotename");
			netResource.lpProvider = H_FETCH_STR(resource, "provider");

			// alloc memory (512 bytes should be enought in most cases)
			infoResource = (NETRESOURCE*)NewMem(infoResourceSize = 512);

			if((error = WNetGetResourceInformation(&netResource, infoResource, 
																						 &infoResourceSize, &system)) == ERROR_MORE_DATA)
			{
				infoResource = (NETRESOURCE*)NewMem(infoResource, infoResourceSize, 1);

				error = WNetGetResourceInformation(&netResource, infoResource, &infoResourceSize, &system);
			}

			if(!LastError(error))
			{
				// store date
				H_STORE_INT(info, "scope", infoResource->dwScope);
				H_STORE_INT(info, "type", infoResource->dwType);
				H_STORE_INT(info, "displaytype", infoResource->dwDisplayType);
				H_STORE_INT(info, "usage", infoResource->dwUsage);
				H_STORE_STR(info, "localname", infoResource->lpLocalName);
				H_STORE_STR(info, "remotename", infoResource->lpRemoteName);
				H_STORE_STR(info, "provider", infoResource->lpProvider);
				if(system)
					H_STORE_STR(info, "remainingpath", system);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
		CleanPtr(infoResource);
	} // if(items == 2 && ... )
	else
		croak("Usage: Win32::Lanman::WNetGetResourceInformation(\\%%resource, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetResourceParent)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *resource = NULL;
	HV *parent = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(resource, ST(0)) && CHK_ASSIGN_HREF(parent, ST(1)))
	{
		NETRESOURCE netResource, *parentResource = NULL;
		DWORD parentResourceSize = 0;

		__try
		{
			// clear hash
			HV_CLEAR(parent);

			memset(&netResource, 0, sizeof(netResource));
			
			netResource.dwType = H_FETCH_INT(resource, "type");
			netResource.lpRemoteName = H_FETCH_STR(resource, "remotename");
			netResource.lpProvider = H_FETCH_STR(resource, "provider");

			// alloc memory (512 bytes should be enought in most cases)
			parentResource = (NETRESOURCE*)NewMem(parentResourceSize = 512);

			if((error = WNetGetResourceParent(&netResource, parentResource, 
																				&parentResourceSize)) == ERROR_MORE_DATA)
			{
				parentResource = (NETRESOURCE*)NewMem(parentResource, parentResourceSize, 1);

				error = WNetGetResourceParent(&netResource, parentResource, &parentResourceSize);
			}

			if(!LastError(error))
			{
				// store date
				H_STORE_INT(parent, "scope", parentResource->dwScope);
				H_STORE_INT(parent, "type", parentResource->dwType);
				H_STORE_INT(parent, "displaytype", parentResource->dwDisplayType);
				H_STORE_INT(parent, "usage", parentResource->dwUsage);
				H_STORE_STR(parent, "localname", parentResource->lpLocalName);
				H_STORE_STR(parent, "remotename", parentResource->lpRemoteName);
				H_STORE_STR(parent, "provider", parentResource->lpProvider);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
		CleanPtr(parentResource);
	} // if(items == 2 && ... )
	else
		croak("Usage: Win32::Lanman::WNetGetResourceParent(\\%%resource, \\%%parent)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetUniversalName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PSTR localPath = NULL;
		REMOTE_NAME_INFO *infoBuffer = NULL;
		DWORD infoBufferSize = 0;
	
		__try
		{
			// clear hash
			HV_CLEAR(info);

			localPath = SvPV(ST(0), PL_na);

			// alloc memory (512 bytes should be enought in most cases)
			infoBuffer = (REMOTE_NAME_INFO*)NewMem(infoBufferSize = 512);
	
			if((error = WNetGetUniversalName(localPath, REMOTE_NAME_INFO_LEVEL, infoBuffer, 
																			 &infoBufferSize)) == ERROR_MORE_DATA)
			{
				infoBuffer = (REMOTE_NAME_INFO*)NewMem(infoBuffer, infoBufferSize, 1);

				error = WNetGetUniversalName(localPath, REMOTE_NAME_INFO_LEVEL, infoBuffer,
																		 &infoBufferSize);
			}

			if(!LastError(error))
			{
				// store date
				H_STORE_STR(info, "universalname", infoBuffer->lpUniversalName);
				H_STORE_STR(info, "connectionname", infoBuffer->lpConnectionName);
				H_STORE_STR(info, "remainingpath", infoBuffer->lpRemainingPath);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
		CleanPtr(infoBuffer);
	} // if(items == 1 && ... )
	else
		croak("Usage: Win32::Lanman::WNetGetUniversalName($localname, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetGetUser)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *user = NULL;

	if(items == 2 && CHK_ASSIGN_SREF(user, ST(1)))
	{
		PSTR resource = SvPV(ST(0), PL_na);
		PSTR userName = NULL;
		DWORD userNameSize = 0;

		__try
		{
			// clear scalar
			SV_CLEAR(user);

			// alloc memory (64 bytes should be enought in most cases)
			userName = NewMem(userNameSize = 64);

			if((error = WNetGetUser(resource, userName, &userNameSize)) == ERROR_MORE_DATA)
			{
				// realloc memory
				userName = NewMem(userName, userNameSize, 0);
			
				// try again
				error = WNetGetUser(resource, userName, &userNameSize);
			}

			// store provider name
			if(!LastError(error))
				S_STORE_STR(user, userName);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		// clean up
		CleanPtr(userName);
	} // if(items == 2 && ... )
	else
		croak("Usage: Win32::Lanman::WNetGetUser($resource, \\$user)\n");

	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_WNetUseConnection)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *resInfo = NULL, *connInfo = NULL;

	if(items >= 1 && items <= 2 && CHK_ASSIGN_HREF(resInfo, ST(0)) && 
		 (items == 1 || CHK_ASSIGN_HREF(connInfo, ST(1))))
	{
		HWND hWndOwner = NULL;
		NETRESOURCE netResource;
		PSTR userName = NULL, password = NULL;
		char accessName[MAX_PATH] = "";
		DWORD accessNameSize = sizeof(accessName), flags = 0, resultFlags = 0;

		__try
		{
			// clear hash
			HV_CLEAR(connInfo);

			memset(&netResource, 0, sizeof(netResource));

			hWndOwner = (HWND)H_FETCH_INT(resInfo, "owner");
			netResource.dwType = H_FETCH_INT(resInfo, "type");
			netResource.lpLocalName = H_FETCH_STR(resInfo, "localname");
			netResource.lpRemoteName = H_FETCH_STR(resInfo, "remotename");
			netResource.lpProvider = H_FETCH_STR(resInfo, "provider");
			userName = H_FETCH_STR(resInfo, "username");
			password = H_FETCH_STR(resInfo, "password");
			flags = H_FETCH_INT(resInfo, "flags");

			// establish a connection
			if(!LastError(WNetUseConnection(hWndOwner, &netResource, userName, password, flags,
																			accessName, &accessNameSize, &resultFlags)))
				// store results
				if(connInfo)
				{
					H_STORE_STR(connInfo, "devicename", accessName);
					H_STORE_INT(connInfo, "devicetype", resultFlags);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
	} // if(items >= 1 && items <= 2 && ...)
	else
		croak("Usage: Win32::Lanman::WNetUseConnection(\\%%resource [, \\%%useinfo ])\n");

	RETURNRESULT(LastError() == 0);
}

