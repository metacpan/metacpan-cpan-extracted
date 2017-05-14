#define WIN32_LEAN_AND_MEAN


#ifndef __TERMSERV_CPP
#define __TERMSERV_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <wtsapi32.h>


#include "termserv.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

#define WTSAPI_DLL	"wtsapi32.dll"

// closes a WTS handle
#define CleanWTSHandle(handle) \
	{ if(handle) { WTSCloseServerCall(handle); handle = NULL; } }

#define CleanWTSHandleOnErr(handle) \
	{ if(error && handle) { WTSCloseServerCall(handle); handle = NULL; } }

#define CleanWTSHandleOnCond(handle, cond) \
	{ if(cond && handle) { WTSCloseServerCall(handle); handle = NULL; } }

// function prototypes exported by wtsapi32.dll
typedef BOOL (WINAPI *WTSEnumerateServersFunc)(PSTR domain, DWORD reserved, 
																							 DWORD version,
																							 PWTS_SERVER_INFO *serverInfo, 
																							 PDWORD count);

typedef HANDLE (WINAPI *WTSOpenServerFunc)(PSTR server);

typedef void (WINAPI *WTSCloseServerFunc)(HANDLE hServer);

typedef BOOL (WINAPI *WTSEnumerateSessionsFunc)(HANDLE hServer, DWORD reserved, 
																								DWORD version, 
																								PWTS_SESSION_INFO *sessionInfo,
																								PDWORD count);

typedef BOOL (WINAPI *WTSEnumerateProcessesFunc)(HANDLE hServer, DWORD reserved,
																								 DWORD version, 
																								 PWTS_PROCESS_INFO *processInfo,
																								 PDWORD count);

typedef BOOL (WINAPI *WTSTerminateProcessFunc)(HANDLE hServer, DWORD processId,
																							 DWORD exitCode);

typedef BOOL (WINAPI *WTSQuerySessionInformationFunc)(HANDLE hServer, DWORD sessionId,   
																											WTS_INFO_CLASS wtsInfoClass,
																											PSTR *buffer, PDWORD bytesReturned);

typedef BOOL (WINAPI *WTSQueryUserConfigFunc)(PSTR serverName, PSTR userName,
																							WTS_CONFIG_CLASS wtsConfigClass,
																							PSTR *buffer,	PDWORD bytesReturned);

typedef BOOL (WINAPI *WTSSetUserConfigFunc)(PSTR serverName, PSTR userName,
																						WTS_CONFIG_CLASS wtsConfigClass,
																						PSTR buffer, DWORD dataLength);

typedef BOOL (WINAPI *WTSSendMessageFunc)(HANDLE hServer, DWORD sessionId, PSTR title, 
																					DWORD titleLength, PSTR message, 
																					DWORD messageLength, DWORD style, 
																					DWORD timeout, PDWORD response, BOOL wait);

typedef BOOL (WINAPI *WTSDisconnectSessionFunc)(HANDLE hServer, DWORD sessionId, BOOL wait);

typedef BOOL (WINAPI *WTSLogoffSessionFunc)(HANDLE hServer, DWORD sessionId, BOOL wait);

typedef BOOL (WINAPI *WTSShutdownSystemFunc)(HANDLE hServer, DWORD shutdownFlag);

typedef BOOL (WINAPI *WTSWaitSystemEventFunc)(HANDLE hServer, DWORD eventMask, 
																							PDWORD eventFlags);

typedef void (WINAPI *WTSFreeMemoryFunc)(PVOID buffer);

// NT5 only
typedef HANDLE (WINAPI *WTSVirtualChannelOpenFunc)(HANDLE hServer, DWORD sessionId, 
																									 PSTR virtualName);

typedef BOOL (WINAPI *WTSVirtualChannelCloseFunc)(HANDLE hChannel);

typedef BOOL (WINAPI *WTSVirtualChannelReadFunc)(HANDLE hChannel, ULONG timeout,
																								 PSTR buffer, ULONG bufferSize,
																								 PULONG bytesRead);

typedef BOOL (WINAPI *WTSVirtualChannelWriteFunc)(HANDLE hChannel, PSTR buffer, 
																									ULONG length, 
																									PULONG bytesWritten);

typedef BOOL (WINAPI *WTSVirtualChannelPurgeInputFunc)(HANDLE hChannel);

typedef BOOL (WINAPI *WTSVirtualChannelPurgeOutputFunc)(HANDLE hChannel);

typedef BOOL (WINAPI *WTSVirtualChannelQueryFunc)(HANDLE hChannel, 
																									WTS_VIRTUAL_CLASS wtsVirtualClass,
																									PVOID *buffer, PDWORD bytesReturned);

// set the loaded function pointers to null
#define	ZERO_WTSLIB_POINTERS									\
	{	WTSEnumerateServersCall = NULL;						\
		WTSOpenServerCall = NULL;									\
		WTSCloseServerCall = NULL;								\
		WTSEnumerateSessionsCall = NULL;					\
		WTSEnumerateProcessesCall = NULL;					\
		WTSTerminateProcessCall = NULL;						\
		WTSQuerySessionInformationCall = NULL;		\
		WTSQueryUserConfigCall = NULL;						\
		WTSSetUserConfigCall = NULL;							\
		WTSSendMessageCall = NULL;								\
		WTSDisconnectSessionCall = NULL;					\
		WTSLogoffSessionCall = NULL;							\
		WTSShutdownSystemCall = NULL;							\
		WTSWaitSystemEventCall = NULL;						\
		WTSFreeMemoryCall = NULL;									\
		/* NT 5 only */														\
		WTSVirtualChannelOpenCall = NULL;					\
		WTSVirtualChannelCloseCall = NULL;				\
		WTSVirtualChannelReadCall = NULL;					\
		WTSVirtualChannelWriteCall = NULL;				\
		WTSVirtualChannelPurgeInputCall = NULL;		\
		WTSVirtualChannelPurgeOutputCall = NULL;	\
		WTSVirtualChannelQueryCall = NULL;				\
	}

// defines a mapping betwwen the config classes and the appr. strings
typedef struct _WTS_CONFIG_CLASS_AND_NAME
{
	WTS_CONFIG_CLASS config;
	PSTR name;
} WTS_CONFIG_CLASS_AND_NAME;

// initialize a WTS_CONFIG_CLASS_AND_NAME array
#define SET_WTS_CONFIG_CLASS_AND_NAME \
	{ \
		{ WTSUserConfigInitialProgram,								"initialprogram" }, \
		{ WTSUserConfigWorkingDirectory,							"workingdirectory" }, \
		{ WTSUserConfigfInheritInitialProgram,				"finheritinitialprogram" }, \
		{ WTSUserConfigfAllowLogonTerminalServer,			"fallowlogonterminalserver" }, \
		{ WTSUserConfigTimeoutSettingsConnections,		"timeoutsettingsconnections" }, \
		{ WTSUserConfigTimeoutSettingsDisconnections,	"timeoutsettingsdisconnections" }, \
		{ WTSUserConfigTimeoutSettingsIdle,						"timeoutsettingsidle" }, \
		{ WTSUserConfigfDeviceClientDrives,						"fdeviceclientdrives" }, \
		{ WTSUserConfigfDeviceClientPrinters,					"fdeviceclientprinters" }, \
		{ WTSUserConfigfDeviceClientDefaultPrinter,		"fdeviceclientdefaultprinter" }, \
		{ WTSUserConfigBrokenTimeoutSettings,					"brokentimeoutsettings" }, \
		{ WTSUserConfigReconnectSettings,							"reconnectsettings" }, \
		{ WTSUserConfigModemCallbackSettings,					"modemcallbacksettings" }, \
		{ WTSUserConfigModemCallbackPhoneNumber,			"modemcallbackphonenumber" }, \
		{ WTSUserConfigShadowingSettings,							"shadowingsettings" }, \
		{ WTSUserConfigTerminalServerProfilePath,			"terminalserverprofilepath" }, \
		{ WTSUserConfigTerminalServerHomeDir,					"terminalserverhomedir" }, \
		{ WTSUserConfigTerminalServerHomeDirDrive,		"terminalserverhomedirdrive" }, \
		{ WTSUserConfigfTerminalServerRemoteHomeDir,	"terminalserverremotehomedir" } \
	};


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////

// library handle and error
HINSTANCE hWTSLibrary = NULL;
DWORD libraryError = 0;

// function pointers exported by wtsapi32.dll
WTSEnumerateServersFunc WTSEnumerateServersCall = NULL;
WTSOpenServerFunc WTSOpenServerCall = NULL;
WTSCloseServerFunc WTSCloseServerCall = NULL;
WTSEnumerateSessionsFunc WTSEnumerateSessionsCall = NULL;
WTSEnumerateProcessesFunc WTSEnumerateProcessesCall = NULL;
WTSTerminateProcessFunc WTSTerminateProcessCall = NULL;
WTSQuerySessionInformationFunc WTSQuerySessionInformationCall = NULL;
WTSQueryUserConfigFunc WTSQueryUserConfigCall = NULL;
WTSSetUserConfigFunc WTSSetUserConfigCall = NULL;
WTSSendMessageFunc WTSSendMessageCall = NULL;
WTSDisconnectSessionFunc WTSDisconnectSessionCall = NULL;
WTSLogoffSessionFunc WTSLogoffSessionCall = NULL;
WTSShutdownSystemFunc WTSShutdownSystemCall = NULL;
WTSWaitSystemEventFunc WTSWaitSystemEventCall = NULL;
WTSFreeMemoryFunc WTSFreeMemoryCall = NULL;

// NT 5 only
WTSVirtualChannelOpenFunc WTSVirtualChannelOpenCall = NULL;
WTSVirtualChannelCloseFunc WTSVirtualChannelCloseCall = NULL;
WTSVirtualChannelReadFunc WTSVirtualChannelReadCall = NULL;
WTSVirtualChannelWriteFunc WTSVirtualChannelWriteCall = NULL;
WTSVirtualChannelPurgeInputFunc WTSVirtualChannelPurgeInputCall = NULL;
WTSVirtualChannelPurgeOutputFunc WTSVirtualChannelPurgeOutputCall = NULL;
WTSVirtualChannelQueryFunc WTSVirtualChannelQueryCall = NULL;


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

#define LOAD_WTS_FUNC(func, ansistr) \
	(func##Call = (func##Func)GetProcAddress(hWTSLibrary, #func##ansistr))


int InitWTSDll()
{
	ErrorAndResult;

	__try
	{
		// try to load library
		if(!(hWTSLibrary = LoadLibrary(WTSAPI_DLL)))
			RaiseFalse();

#pragma warning(disable : 4003)
		// get function pointers
		if(!LOAD_WTS_FUNC(WTSEnumerateServers, "A"))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSOpenServer, "A"))
			RaiseFalse();
		
		if(!LOAD_WTS_FUNC(WTSCloseServer))
			RaiseFalse();
		
		if(!LOAD_WTS_FUNC(WTSEnumerateSessions, "A"))
			RaiseFalse();
		
		if(!LOAD_WTS_FUNC(WTSEnumerateProcesses, "A"))
			RaiseFalse();
		
		if(!LOAD_WTS_FUNC(WTSTerminateProcess))
			RaiseFalse();
		
		if(!LOAD_WTS_FUNC(WTSQuerySessionInformation, "A"))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSQueryUserConfig, "A"))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSSetUserConfig, "A"))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSSendMessage, "A"))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSDisconnectSession))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSLogoffSession))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSShutdownSystem))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSWaitSystemEvent))
			RaiseFalse();

		if(!LOAD_WTS_FUNC(WTSFreeMemory))
			RaiseFalse();

		// NT 5 only
		LOAD_WTS_FUNC(WTSVirtualChannelOpen);
		LOAD_WTS_FUNC(WTSVirtualChannelClose);
		LOAD_WTS_FUNC(WTSVirtualChannelRead);
		LOAD_WTS_FUNC(WTSVirtualChannelWrite);
		LOAD_WTS_FUNC(WTSVirtualChannelPurgeInput);
		LOAD_WTS_FUNC(WTSVirtualChannelPurgeInput);
		LOAD_WTS_FUNC(WTSVirtualChannelPurgeOutput);
		LOAD_WTS_FUNC(WTSVirtualChannelQuery);
#pragma warning(default : 4003)
	}
	__except(SetExceptCode(excode))
	{
		// set last error 
		LastError(error ? error : excode);

		// set library error
		libraryError = error ? error : excode;

		// unload library if an error occured
		CleanLibrary(hWTSLibrary);

		// reset function pointers
		ZERO_WTSLIB_POINTERS;
	}

	return result;
}


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

int ReleaseWTSDll()
{
	ErrorAndResult;

	// reset function pointers
	ZERO_WTSLIB_POINTERS;

	// unload library
	CleanLibrary(hWTSLibrary);

	return result;
}


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

XS(XS_NT__Lanman_WTSEnumerateServers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *servers = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(servers, ST(1)))
	{
		PWTS_SERVER_INFO serverInfo = NULL;
		DWORD serverInfoCount = 0;

		__try
		{
			// get domain name
			PSTR domain = SvPV(ST(0), PL_na);

			// clear array
			AV_CLEAR(servers);

			// return the library error if the library isn't loaded correctly
			if(!WTSEnumerateServersCall)
				RaiseFalseError(libraryError);

			// enumerate the sessions; if there're no terminal servers the call fails but
			// the GetLastError() returns 0
			if(!WTSEnumerateServersCall(domain, 0, 1, &serverInfo, 
																	&serverInfoCount) && GetLastError())
				RaiseFalse();

			// store the infos
			for(DWORD count = 0; count < serverInfoCount; count++)
			{
				// store server properties
				HV *properties = NewHV;

				H_STORE_STR(properties, "name", serverInfo[count].pServerName);

				A_STORE_REF(servers, properties);

				// decrement reference count
				SvREFCNT_dec(properties);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanWtsBuf(serverInfo);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::WTSEnumerateServers($domain, \\@sessions)\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSOpenServer)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *handle = NULL;

	if(items == 2 && CHK_ASSIGN_SREF(handle, ST(1)))
	{
		PSTR server = NULL;

		__try
		{
			// get server name
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// clear handle
			SV_CLEAR(handle);

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall)
				RaiseFalseError(libraryError);

			// try to get an handle
			HANDLE hWTSServer = WTSOpenServerCall(server);

			if(*server && !hWTSServer)
				RaiseFalse();

			// store the handle
			S_STORE_INT(handle, (int)hWTSServer);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::WTSOpenServer($server, \\$handle)\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSCloseServer)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 1)
	{
		__try
		{
			// get handle
			HANDLE hServer = (HANDLE)SvIV(ST(0));

			// return the library error if the library isn't loaded correctly
			if(!WTSCloseServerCall)
				RaiseFalseError(libraryError);

			// close the handle
			if(hServer != WTS_CURRENT_SERVER_HANDLE)
				WTSCloseServerCall(hServer);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::WTSCloseServer($handle)\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSEnumerateSessions)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *sessions = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(sessions, ST(1)))
	{
		PSTR server = NULL;
		HANDLE hServer = NULL;
		PWTS_SESSION_INFO sessInfo = NULL;
		DWORD sessInfoCount = 0;

		__try
		{
			// get server name
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
		
			// clear array
			AV_CLEAR(sessions);

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSEnumerateSessionsCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// enumerate the sessions
			if(!WTSEnumerateSessionsCall(hServer, 0, 1, &sessInfo, &sessInfoCount))
				RaiseFalse();

			// store the infos
			for(DWORD count = 0; count < sessInfoCount; count++)
			{
				// store session properties
				HV *properties = NewHV;

				H_STORE_INT(properties, "id", sessInfo[count].SessionId);
				H_STORE_STR(properties, "winstationname", sessInfo[count].pWinStationName);
				H_STORE_INT(properties, "state", sessInfo[count].State);

				A_STORE_REF(sessions, properties);

				// decrement reference count
				SvREFCNT_dec(properties);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWtsBuf(sessInfo);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::WTSEnumerateSessions($server, \\@sessions)\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSEnumerateProcesses)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *processes = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(processes, ST(1)))
	{
		PSTR server = NULL;
		HANDLE hServer = NULL;
		PWTS_PROCESS_INFO procInfo = NULL;
		DWORD procInfoCount = 0;

		__try
		{
			// get server name
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
		
			// clear array
			AV_CLEAR(processes);

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSEnumerateProcessesCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// enumerate the sessions
			if(!WTSEnumerateProcessesCall(hServer, 0, 1, &procInfo, &procInfoCount))
				RaiseFalse();

			// store the infos
			for(DWORD count = 0; count < procInfoCount; count++)
			{
				// store processes properties
				HV *properties = NewHV;

				H_STORE_INT(properties, "sessionid", procInfo[count].SessionId);
				H_STORE_INT(properties, "processid", procInfo[count].ProcessId);
				H_STORE_STR(properties, "name", procInfo[count].pProcessName);
				if(procInfo[count].pUserSid && IsValidSid(procInfo[count].pUserSid))
					H_STORE_PTR(properties, "sid", procInfo[count].pUserSid, 
											GetLengthSid(procInfo[count].pUserSid));

				A_STORE_REF(processes, properties);

				// decrement reference count
				SvREFCNT_dec(properties);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWtsBuf(procInfo);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::WTSEnumerateProcesses($server, \\@processes)\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSTerminateProcess)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PSTR server = NULL;
		HANDLE hServer = NULL;
		DWORD processId = 0;
		DWORD exitCode = 0;

		__try
		{
			// get server name, process id and exit code
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			processId = SvIV(ST(1));
			if(items == 3)
				exitCode = SvIV(ST(2));

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSTerminateProcessCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// kill process
			if(!WTSTerminateProcessCall(hServer, processId, exitCode))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 2 || items == 3)
	else
		croak("Usage: Win32::Lanman::WTSTerminateProcess($server, $processid [, $exitcode])\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSQuerySessionInformation)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *infoClass = NULL;
	HV *info = NULL;

	if(items == 4 && CHK_ASSIGN_AREF(infoClass, ST(2)) && CHK_ASSIGN_HREF(info, ST(3)))
	{
		PSTR server = NULL;
		DWORD sessionId = 0;
		HANDLE hServer = NULL;
			
		WTS_INFO_CLASS wtsInfoClass;
		PSTR buffer = NULL;
		DWORD bufferSize = 0;

		__try
		{
			// get server name and session id
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			sessionId = SvIV(ST(1));

			HV_CLEAR(info);

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSQuerySessionInformationCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// walk thru all array elements
			for(int count = 0, numInfoClass = AV_LEN(infoClass) + 1; 
					count < numInfoClass; count++)
			{
				wtsInfoClass = (WTS_INFO_CLASS)A_FETCH_INT(infoClass, count);

				// we cannot call WTSQuerySessionInformation with session id 0 and
				// WTSApplicationName or WTSInitialProgram; why? who knows
				if((wtsInfoClass == WTSApplicationName || wtsInfoClass == WTSInitialProgram) && 
					 !sessionId)
					continue;

				// retrieve session information
				if(!WTSQuerySessionInformationCall(hServer, sessionId, wtsInfoClass, &buffer,
																					 &bufferSize))
				{
					if(!GetLastError())
						continue;

					RaiseFalse();
				}

				// store results
				if(buffer)
					switch(wtsInfoClass)
					{
						case WTSInitialProgram:
							H_STORE_STR(info, "initialprogram", buffer);
							break;

						case WTSApplicationName:
							H_STORE_STR(info, "applicationname", buffer);
							break;

						case WTSWorkingDirectory:
							H_STORE_STR(info, "workingdirectory", buffer);
							break;

						case WTSOEMId:
							H_STORE_STR(info, "oemid", buffer);
							break;

						case WTSSessionId:
							H_STORE_INT(info, "sessionid", *(PULONG)buffer);
							break;

						case WTSUserName:
							H_STORE_STR(info, "username", buffer);
							break;

						case WTSWinStationName:
							H_STORE_STR(info, "winstationname", buffer);
							break;

						case WTSDomainName:
							H_STORE_STR(info, "domainname", buffer);
							break;

						case WTSConnectState:
							H_STORE_INT(info, "connectstate", *(PDWORD)buffer);
							break;

						case WTSClientBuildNumber:
							H_STORE_INT(info, "clientbuildnumber", *(PUSHORT)buffer);
							break;

						case WTSClientName:
							H_STORE_STR(info, "clientname", buffer);
							break;

						case WTSClientDirectory:
							H_STORE_STR(info, "clientdirectory", buffer);
							break;

						case WTSClientProductId:
							H_STORE_INT(info, "clientproductid", *(PUSHORT)buffer);
							break;

						case WTSClientHardwareId:
							H_STORE_INT(info, "clienthardwareid", *(PUSHORT)buffer);
							break;

						case WTSClientAddress:
							H_STORE_PTR(info, "clientaddress", buffer, sizeof(WTS_CLIENT_ADDRESS));
							break;

						case WTSClientDisplay:
							H_STORE_PTR(info, "clientdisplay", buffer, sizeof(WTS_CLIENT_DISPLAY));
							break;
					}

				// clean up
				CleanWtsBuf(buffer);
			} // for(int count ...)
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);

			HV_CLEAR(info);
		}

		// clean up
		CleanPtr(server);
		CleanWtsBuf(buffer);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::WTSQuerySessionInformation($server, $sessionid, "
																														"\\@infoclass, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the terminal server user properties
//
// param:  server	- computer to execute the command
//				 user		- user name
//				 class	- information class to retrieve
//				 config	- hash to store configuration
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_WTSQueryUserConfig)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *confClass = NULL;
	HV *conf = NULL;

	if(items == 4 && CHK_ASSIGN_AREF(confClass, ST(2)) && CHK_ASSIGN_HREF(conf, ST(3)))
	{
		PSTR server = NULL;
		PSTR user = NULL;
		WTS_CONFIG_CLASS config;
		PSTR buffer = NULL;
		DWORD bufferSize = 0;

		__try
		{
			// get server and user name
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			user = SvPV(ST(1), PL_na);

			HV_CLEAR(conf);

			// return the library error if the library isn't loaded correctly
			if(!WTSQueryUserConfigCall)
				RaiseFalseError(libraryError);

			// walk thru all array elements
			for(int count = 0, numConfClass = AV_LEN(confClass) + 1; 
					count < numConfClass; count++)
			{
				config = (WTS_CONFIG_CLASS)A_FETCH_INT(confClass, count);

				// try to get user information
				if(!WTSQueryUserConfigCall(server, user, config, &buffer, &bufferSize))
					RaiseFalse();

				// store results
				switch(config)
				{
					case WTSUserConfigInitialProgram:
						H_STORE_STR(conf, "initialprogram", buffer);
						break;

					case WTSUserConfigWorkingDirectory:
						H_STORE_STR(conf, "workingdirectory", buffer);
						break;

					case WTSUserConfigfInheritInitialProgram:
						H_STORE_INT(conf, "finheritinitialprogram", *(PDWORD)buffer);
						break;

					case WTSUserConfigfAllowLogonTerminalServer:
						H_STORE_INT(conf, "fallowlogonterminalserver", *(PDWORD)buffer);
						break;

					case WTSUserConfigTimeoutSettingsConnections:
						H_STORE_INT(conf, "timeoutsettingsconnections", *(PDWORD)buffer);
						break;

					case WTSUserConfigTimeoutSettingsDisconnections:
						H_STORE_INT(conf, "timeoutsettingsdisconnections", *(PDWORD)buffer);
						break;

					case WTSUserConfigTimeoutSettingsIdle:
						H_STORE_INT(conf, "timeoutsettingsidle", *(PDWORD)buffer);
						break;

					case WTSUserConfigfDeviceClientDrives:
						H_STORE_INT(conf, "fdeviceclientdrives", *(PDWORD)buffer);
						break;

					case WTSUserConfigfDeviceClientPrinters:
						H_STORE_INT(conf, "fdeviceclientprinters", *(PDWORD)buffer);
						break;

					case WTSUserConfigfDeviceClientDefaultPrinter:
						H_STORE_INT(conf, "fdeviceclientdefaultprinter", *(PDWORD)buffer);
						break;

					case WTSUserConfigBrokenTimeoutSettings:
						H_STORE_INT(conf, "brokentimeoutsettings", *(PDWORD)buffer);
						break;

					case WTSUserConfigReconnectSettings:
						H_STORE_INT(conf, "reconnectsettings", *(PDWORD)buffer);
						break;

					case WTSUserConfigModemCallbackSettings:
						H_STORE_INT(conf, "modemcallbacksettings", *(PDWORD)buffer);
						break;

					case WTSUserConfigModemCallbackPhoneNumber:
						H_STORE_STR(conf, "modemcallbackphonenumber", buffer);
						break;

					case WTSUserConfigShadowingSettings:
						H_STORE_INT(conf, "shadowingsettings", *(PDWORD)buffer);
						break;

					case WTSUserConfigTerminalServerProfilePath:
						H_STORE_STR(conf, "terminalserverprofilepath", buffer);
						break;

					case WTSUserConfigTerminalServerHomeDir:
						H_STORE_STR(conf, "terminalserverhomedir", buffer);
						break;

					case WTSUserConfigTerminalServerHomeDirDrive:
						H_STORE_STR(conf, "terminalserverhomedirdrive", buffer);
						break;

					case WTSUserConfigfTerminalServerRemoteHomeDir:
						H_STORE_INT(conf, "terminalserverremotehomedir", *(PDWORD)buffer);
						break;
				}

				// clean up
				CleanWtsBuf(buffer);
			} // for(int count ...)
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);

			HV_CLEAR(conf);
		}

		// clean up
		CleanPtr(server);
		CleanWtsBuf(buffer);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::WTSQueryUserConfig($server, $user, \\@infoclass, \\%%config)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSSetUserConfig)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *config = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(config, ST(2)))
	{
		PSTR server = NULL;
		PSTR user = NULL;
		PSTR buffer = NULL;
		DWORD bufferSize = 0, bufferAsDWORD = 0;
		WTS_CONFIG_CLASS_AND_NAME configs[] = SET_WTS_CONFIG_CLASS_AND_NAME;

		__try
		{
			// get server and user name
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			user = SvPV(ST(1), PL_na);

			// return the library error if the library isn't loaded correctly
			if(!WTSSetUserConfigCall)
				RaiseFalseError(libraryError);

			for(int count = 0; count < sizeof(configs) / sizeof(configs[0]); count++)
				if(H_EXISTS(config, configs[count].name))
				{
					switch(configs[count].config)
					{
						// need a DWORD as parameter
						case WTSUserConfigInitialProgram:
						case WTSUserConfigWorkingDirectory:
						case WTSUserConfigModemCallbackPhoneNumber:
						case WTSUserConfigTerminalServerProfilePath:
						case WTSUserConfigTerminalServerHomeDir:
						case WTSUserConfigTerminalServerHomeDirDrive:
							buffer = H_FETCH_STR(config, configs[count].name);
							bufferSize = strlen(buffer) + 1;
							break;

						case WTSUserConfigfInheritInitialProgram:
						case WTSUserConfigfAllowLogonTerminalServer:
						case WTSUserConfigTimeoutSettingsConnections:
						case WTSUserConfigTimeoutSettingsDisconnections:
						case WTSUserConfigTimeoutSettingsIdle:
						case WTSUserConfigfDeviceClientDrives:
						case WTSUserConfigfDeviceClientPrinters:
						case WTSUserConfigfDeviceClientDefaultPrinter:
						case WTSUserConfigBrokenTimeoutSettings:
						case WTSUserConfigReconnectSettings:
						case WTSUserConfigModemCallbackSettings:
						case WTSUserConfigShadowingSettings:
							bufferAsDWORD = H_FETCH_INT(config, configs[count].name);
							buffer = (PSTR)&bufferAsDWORD;
							bufferSize = sizeof(bufferAsDWORD);
							break;	

						// it seems, we cannot set the WTSUserConfigfTerminalServerRemoteHomeDir
						// property; WTSSetUserConfig returns always error 87
						case WTSUserConfigfTerminalServerRemoteHomeDir:
							continue;

						default:
							continue;
					} // if(H_EXISTS(config, configs[count].name))

					// try to set user information
					if(!WTSSetUserConfigCall(server, user, configs[count].config, buffer, bufferSize))
						RaiseFalse();
				} // for(int count = 0; count < sizeof(configs) / sizeof(configs[0]); count++)
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::WTSSetUserConfig($server, $user, \\%%config)\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSSendMessage)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *response = NULL;

	if(items >= 4 && items <= 7 && (items < 7 || CHK_ASSIGN_SREF(response, ST(6))))
	{
		PSTR server = NULL;
		DWORD sessionId = 0;
		HANDLE hServer = NULL;
		PSTR title = NULL, message = NULL;
		DWORD style = MB_OK, timeout = 0, answer = 0;
			
		__try
		{
			// get server name, session id, title, message, style and timeout
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			sessionId = SvIV(ST(1));
			title = SvPV(ST(2), PL_na);
			message = SvPV(ST(3), PL_na);
			style = items >= 5 ? SvIV(ST(4)) : MB_OK;
			timeout = items >= 6 ? SvIV(ST(5)) : 0;

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSSendMessageCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// send message
			if(!WTSSendMessageCall(hServer, sessionId, title, strlen(title), message, 
														 strlen(message), style, timeout, &answer, timeout))
				RaiseFalse();

			if(items == 7)
				S_STORE_INT(response, answer);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // items >= 4 && items <= 7 && ...)
	else
		croak("Usage: Win32::Lanman::WTSSendMessage($server, $sessionid, $title, $message "
																								"[, $style [, $timeout [, \\$response]]])\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSDisconnectSession)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PSTR server = NULL;
		DWORD sessionId = 0;
		HANDLE hServer = NULL;
		DWORD wait = 0;

		__try
		{
			// get server name, session id and wait flag
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			sessionId = SvIV(ST(1));
			wait = items == 3 ? SvIV(ST(2)) : 0;

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSDisconnectSessionCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// disconnect the session
			if(!WTSDisconnectSessionCall(hServer, sessionId, wait))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 2 || items == 3)
	else
		croak("Usage: Win32::Lanman::WTSDisconnectSession($server, $sessionid [, $wait])\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSLogoffSession)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PSTR server = NULL;
		DWORD sessionId = 0;
		HANDLE hServer = NULL;
		DWORD wait = 0;

		__try
		{
			// get server name, session id and wait flag
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			sessionId = SvIV(ST(1));
			wait = items == 3 ? SvIV(ST(2)) : 0;

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSLogoffSessionCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// log off the session
			if(!WTSLogoffSessionCall(hServer, sessionId, wait))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 2 || items == 3)
	else
		croak("Usage: Win32::Lanman::WTSLogoffSession($server, $sessionid [, $wait])\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSShutdownSystem)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 1 || items == 2)
	{
		PSTR server = NULL;
		DWORD flag = 0;
		HANDLE hServer = NULL;

		__try
		{
			// get server name and flag
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			flag = items == 2 ? SvIV(ST(1)) : 0;

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSShutdownSystemCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// shut down the server
			if(!WTSShutdownSystemCall(hServer, flag))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 1 || items == 2)
	else
		croak("Usage: Win32::Lanman::WTSShutdownSystem($server[, $flag])\n");

	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_WTSWaitSystemEvent)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *flags = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(flags, ST(2)))
	{
		PSTR server = NULL;
		DWORD mask = 0, eventFlags = 0;
		HANDLE hServer = NULL;

		__try
		{
			// get server name and bit mask
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			mask = SvIV(ST(1));

			// return the library error if the library isn't loaded correctly
			if(!WTSOpenServerCall || !WTSWaitSystemEventCall)
				RaiseFalseError(libraryError);

			// open server
			if(server && *server)
			{
				if(!(hServer = WTSOpenServerCall(server)))
					RaiseFalse();
			}
			else
				hServer= WTS_CURRENT_SERVER_HANDLE;

			// wait for event
			if(!WTSWaitSystemEventCall(hServer, mask, &eventFlags))
				RaiseFalse();

			S_STORE_INT(flags, eventFlags);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanWTSHandleOnCond(hServer, hServer != WTS_CURRENT_SERVER_HANDLE);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::WTSWaitSystemEvent($server, $mask, \\$flags)\n");

	RETURNRESULT(LastError() == 0);
}

