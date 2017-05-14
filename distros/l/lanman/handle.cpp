#define WIN32_LEAN_AND_MEAN


#ifndef __HANDLE_CPP
#define __HANDLE_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <lmchdev.h>


#include "handle.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// globals
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

typedef NET_API_STATUS (NET_API_FUNCTION *NetHandleGetInfoFunc)(HANDLE handle, 
																																DWORD level, 
																																PBYTE *bufptr);

/*
XS(XS_NT__Lanman_NetHandleGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		__try
		{
			HANDLE handle = (HANDLE)SvIV(ST(0));

			// clear hash
			HV_CLEAR(info);

			PHANDLE_INFO_1 handleInfo = NULL;
			DWORD handleInfoSize = sizeof(handleInfo);

			HINSTANCE hLib = LoadLibrary("netapi.dll");

			NetHandleGetInfoFunc NetHandleGetInfoCall = 
				(NetHandleGetInfoFunc)GetProcAddress(hLib, "NETHANDLEGETINFO");

		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetHandleGetInfo($handle, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}
*/
/*
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

XS(XS_NT__Lanman_NetHandleSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PHANDLE_INFO_1 handleInfo = NULL;

		__try
		{
			HANDLE handle = (HANDLE)SvIV(ST(0));

			// clear hash
			HV_CLEAR(info);

			DWORD handleInfoSize = sizeof(handleInfo);
			
			if(!LastError(NetHandleGetInfo(handle, 1, (PBYTE*)&handleInfo)))
			{
				H_STORE_INT(info, "chartime", handleInfo->hdli1_chartime);
				H_STORE_INT(info, "charcount", handleInfo->hdli1_charcount);
			}
			
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		NetApiBufferFree(handleInfo);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetHandleGetInfo($handle, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}
*/