#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Psapi.h>

#ifndef DEBUG_WIN32API_PROCESSSTATUS
# define Debug(list) /*Nothing*/
#else
# define Debug(list) PrintLastError list
# include <stdarg.h>
	static void PrintLastError(const char* fmt, ...)
	{
		va_list args;
		static char* env = getenv("DEBUG_WIN32API_PROCESSSTATUS");
		DWORD err = GetLastError();

		if(env == 0 || *env == 0)
			return;

		va_start(args, fmt);
		vfprintf(stderr, smt, args);
		va_end(args);

		SetLastError(err);
	}
#endif /* DEBUG_WIN32API_PROCESSSTATUS */

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

MODULE = Win32API::ProcessStatus		PACKAGE = Win32API::ProcessStatus		

DWORD
GetLastProcessStatusError()
	CODE:
		RETVAL = dwLastError;
	OUTPUT:
		RETVAL

BOOL
EnumProcesses(OUT lpidProcess, ...)
		DWORD* lpidProcess
	INIT:
		DWORD cb = items > 1 ? (null_arg(ST(1)) ? 0 : (DWORD) SvUV(ST(1))) : 0;
		DWORD len_lpidProcess;
	CODE:
		/*IN cb, OUT len_lpidProcess*/
		if (cb == 0) cb = 1024 * sizeof(DWORD);
		lpidProcess = (DWORD*) malloc(cb * sizeof(*lpidProcess));
		RETVAL = EnumProcesses(lpidProcess, cb, &len_lpidProcess);
		if (!RETVAL)
			len_lpidProcess = 0;
		RememberLastError(RETVAL);
		if (items > 2) {
			if (!null_arg(ST(2)) && !SvREADONLY(ST(2)))
				sv_setuv(ST(2), (UV) len_lpidProcess);
			SvSETMAGIC(ST(2));
		}
	OUTPUT:
		lpidProcess
		RETVAL

BOOL
EnumProcessModules(IN hProcess, OUT lphModule, ...)
		HANDLE hProcess
		HMODULE* lphModule
	INIT:
		DWORD cb = items > 2 ? (null_arg(ST(2)) ? 0 : (DWORD) SvUV(ST(2))) : 0;
		DWORD len_lphModule;
	CODE:
		/*IN cb, OUT len_lphModule*/
		if (cb == 0) cb = 1024 * sizeof(HMODULE);
		lphModule = (HMODULE*) malloc(cb * sizeof(*lphModule));
		RETVAL = EnumProcessModules(hProcess, lphModule, cb, &len_lphModule);
		if (!RETVAL)
			len_lphModule = 0;
		RememberLastError(RETVAL);
		if (items > 3) {
			if (!null_arg(ST(3)) && !SvREADONLY(ST(3)))
				sv_setuv(ST(3), (UV) len_lphModule);
			SvSETMAGIC(ST(3));
		}
	OUTPUT:
		lphModule
		RETVAL

DWORD
GetModuleBaseNameA(IN hProcess, IN hModule, OUT lpBaseName, ...)
		HANDLE hProcess
		HMODULE hModule
		CHAR* lpBaseName
	INIT:
		DWORD nSize = items > 3 ? (null_arg(ST(3)) ? 0 : (DWORD) SvUV(ST(3))) : 0;
	CODE:
		/*IN nSize*/
		if (nSize == 0) nSize = MAX_PATH;
		lpBaseName = (CHAR*) malloc(nSize);
		RETVAL = GetModuleBaseNameA(hProcess, hModule, lpBaseName, nSize);
		RememberLastError(RETVAL != 0);
	OUTPUT:
		lpBaseName
		RETVAL

DWORD
GetModuleBaseNameW(IN hProcess, IN hModule, OUT lpBaseName, ...)
		HANDLE hProcess
		HMODULE hModule
		WCHAR* lpBaseName
	INIT:
		DWORD nSize = items > 3 ? (null_arg(ST(3)) ? 0 : (DWORD) SvUV(ST(3))) : 0;
	CODE:
		/*IN nSize*/
		if (nSize == 0) nSize = MAX_PATH;
		lpBaseName = (WCHAR*) malloc(nSize * sizeof(WCHAR));
		RETVAL = GetModuleBaseNameW(hProcess, hModule, lpBaseName, nSize);
		RememberLastError(RETVAL != 0);
	OUTPUT:
		lpBaseName
		RETVAL

DWORD
GetModuleFileNameExA(IN hProcess, IN hModule, OUT lpFilename, ...)
		HANDLE hProcess
		HMODULE hModule
		CHAR* lpFilename
	INIT:
		DWORD nSize = items > 3 ? (null_arg(ST(3)) ? 0 : (DWORD) SvUV(ST(3))) : 0;
	CODE:
		/*IN nSize*/
		if (nSize == 0) nSize = MAX_PATH;
		lpFilename = (CHAR*) malloc(nSize);
		RETVAL = GetModuleFileNameExA(hProcess, hModule, lpFilename, nSize);
		RememberLastError(RETVAL != 0);
	OUTPUT:
		lpFilename
		RETVAL

DWORD
GetModuleFileNameExW(IN hProcess, IN hModule, OUT lpFilename, ...)
		HANDLE hProcess
		HMODULE hModule
		WCHAR* lpFilename
	INIT:
		DWORD nSize = items > 3 ? (null_arg(ST(3)) ? 0 : (DWORD) SvUV(ST(3))) : 0;
	CODE:
		/*IN nSize*/
		if (nSize == 0) nSize = MAX_PATH;
		lpFilename = (WCHAR*) malloc(nSize * sizeof(WCHAR));
		RETVAL = GetModuleFileNameExW(hProcess, hModule, lpFilename, nSize);
		RememberLastError(RETVAL != 0);
	OUTPUT:
		lpFilename
		RETVAL

BOOL
GetModuleInformation(IN hProcess, IN hModule, OUT lpmodinfo)
		HANDLE hProcess
		HMODULE hModule
		MODULEINFO lpmodinfo
	CODE:
		RETVAL = GetModuleInformation(hProcess, hModule, &lpmodinfo, sizeof(lpmodinfo));
		RememberLastError(RETVAL);
	OUTPUT:
		lpmodinfo
		RETVAL

NO_OUTPUT void
SetLastProcessStatusError(dwError)
		DWORD dwError
	CODE:
		AssignLastError(dwError);
