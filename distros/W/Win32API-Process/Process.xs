#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Psapi.h>

#undef XS_VERSION
#define XS_VERSION "0.01"

#ifndef DEBUG_WIN32API_PROCESS
# define Debug(list) /*Nothing*/
#else
# define Debug(list) PrintLastError list
# include <stdarg.h>
	static void PrintLastError(const char* fmt, ...)
	{
		va_list args;
		static char* env = getenv("DEBUG_WIN32API_PROCESS");
		DWORD err = GetLastError();

		if(env == 0 || *env == 0)
			return;

		va_start(args, fmt);
		vfprintf(stderr, smt, args);
		va_end(args);

		SetLastError(err);
	}
#endif /* DEBUG_WIN32API_PROCESS */

#include "buffers.h"	/* Include this after DEBUGGING setup finished */

static DWORD dwLastError = ERROR_SUCCESS;

static void AssignLastError(DWORD dwError)
{
	dwLastError = dwError;
}

static void RememberLastError(BOOL bStatus)
{
	if (!bStatus)
		dwLastError = GetLastError();
}

MODULE = Win32API::Process		PACKAGE = Win32API::Process		

BOOL
CloseProcess(IN hProcess)
		HANDLE hProcess
	CODE:
		RETVAL = CloseHandle(hProcess);
		RememberLastError(RETVAL);
	OUTPUT:
		RETVAL

DWORD
GetLastProcessError()
	CODE:
		RETVAL = dwLastError;
	OUTPUT:
		RETVAL

HANDLE
OpenProcess(IN dwDesiredAccess, IN bInheritHandle, IN dwProcessId)
		DWORD dwDesiredAccess
		BOOL bInheritHandle
		DWORD dwProcessId
	CODE:
		RETVAL = OpenProcess(dwDesiredAccess, bInheritHandle, dwProcessId);
		RememberLastError(RETVAL != 0);
	OUTPUT:
		RETVAL

NO_OUTPUT void
SetLastProcessError(dwError)
		DWORD dwError
	CODE:
		AssignLastError(dwError);

BOOL
TerminateProcess(IN hProcess, IN uExitCode)
		HANDLE hProcess
		UINT uExitCode
	CODE:
		RETVAL = TerminateProcess(hProcess, uExitCode);
		RememberLastError(RETVAL);
	OUTPUT:
		RETVAL
