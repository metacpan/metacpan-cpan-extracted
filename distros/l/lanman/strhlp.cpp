#define WIN32_LEAN_AND_MEAN

#ifndef __STRHLP_CPP
#define __STRHLP_CPP
#endif


#include <windows.h>


#include "misc.h"


///////////////////////////////////////////////////////////////////////////////
//
// converts a string to netbios name (\\name)
//
// param:  server	- computer computer name
//
// return: converted string
//
// note:   if there is not enougth memory, an exception will be raised
//
///////////////////////////////////////////////////////////////////////////////

PSTR ServerAsAnsi(PSTR server)
{
	// compute string size
	DWORD serverAnsiSize = lstrlen(server) + 1;

	// if the string is not empty and does't begin with two backslashes,
	// increase the size
	if(server && *server && server[0] != '\\' && server[1] != '\\')
		serverAnsiSize += 2;

	// alloc memory
	PSTR serverAnsi = (PSTR)NewMem(serverAnsiSize), serverAnsiPtr = serverAnsi;

	// if the string is not empty and does't begin with two backslashes,
	// put two backslashes in front of the string
	if(server && *server && server[0] != '\\' && server[1] != '\\')
	{
		lstrcpy(serverAnsiPtr, "\\\\");
		serverAnsiPtr += 2;
	}

	// copy server name
	lstrcpy(serverAnsiPtr, server);

	return serverAnsi;
}

///////////////////////////////////////////////////////////////////////////////
//
// converts a string to netbios name in unicode (\\name)
//
// param:  server	- computer computer name
//
// return: converted string
//
// note:   if there is not enougth memory, an exception will be raised
//
///////////////////////////////////////////////////////////////////////////////

PWSTR ServerAsUnicode(PSTR server)
{
	// compute string size
	DWORD serverUnicodeSize = lstrlen(server) + 1;

	// if the string is not empty and does't begin with two backslashes,
	// increase the size
	if(server && *server && server[0] != '\\' && server[1] != '\\')
		serverUnicodeSize += 2 * sizeof(WCHAR);

	// alloc memory
	PWSTR serverUnicode = (PWSTR)NewMem(serverUnicodeSize * sizeof(WCHAR)), 
				serverUnicodePtr = serverUnicode;

	// if the string is not empty and does't begin with two backslashes,
	// put two backslashes in front of the string
	if(server && *server && server[0] != '\\' && server[1] != '\\')
	{
		wcscpy(serverUnicodePtr, L"\\\\");
		serverUnicodePtr += 2;
		serverUnicodeSize -= 2;
	}

	// copy server name
	MultiByteToWideChar(CP_ACP, 0, server, -1, serverUnicodePtr, serverUnicodeSize);

	return serverUnicode;
}

///////////////////////////////////////////////////////////////////////////////
//
// converts a string to netbios name without leading backslashes
//
// param:  server	- computer computer name
//
// return: converted string
//
// note:   if there is not enougth memory, an exception will be raised
//
///////////////////////////////////////////////////////////////////////////////

PSTR ServerAsAnsiWithoutBackslashes(PSTR server)
{
	// if the servername begins with two backslashes, move the pointer
	if(server && server[0] == '\\' && server[1] == '\\')
		server += 2;

	// compute string size
	DWORD serverAnsiSize = lstrlen(server) + 1;

	// alloc memory
	PSTR serverAnsi = (PSTR)NewMem(serverAnsiSize), serverAnsiPtr = serverAnsi;

	// copy server name
	lstrcpy(serverAnsiPtr, server);

	return serverAnsi;
}

///////////////////////////////////////////////////////////////////////////////
//
// converts a string to netbios name in unicode without leading backslashes
//
// param:  server	- computer computer name
//
// return: converted string
//
// note:   if there is not enougth memory, an exception will be raised
//
///////////////////////////////////////////////////////////////////////////////

PWSTR ServerAsUnicodeWithoutBackslashes(PSTR server)
{
	// if the servername begins with two backslashes, move the pointer
	if(server && server[0] == '\\' && server[1] == '\\')
		server += 2;

	// compute string size
	DWORD serverUnicodeSize = lstrlen(server) + 1;

	// alloc memory
	PWSTR serverUnicode = (PWSTR)NewMem(serverUnicodeSize * sizeof(WCHAR)), 
				serverUnicodePtr = serverUnicode;

	// copy server name
	MultiByteToWideChar(CP_ACP, 0, server, -1, serverUnicodePtr, serverUnicodeSize);

	return serverUnicode;
}
