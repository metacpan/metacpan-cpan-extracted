#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <TlHelp32.h>

#undef XS_VERSION
#define XS_VERSION "0.02"

#ifndef DEBUG_WIN32API_TOOLHELP
# define Debug(list) /*Nothing*/
#else
# define Debug(list) PrintLastError list
# include <stdarg.h>
	static void PrintLastError(const char* fmt, ...)
	{
		va_list args;
		static char* env = getenv("DEBUG_WIN32API_TOOLHELP");
		DWORD err = GetLastError();

		if(env == 0 || *env == 0)
			return;

		va_start(args, fmt);
		vfprintf(stderr, smt, args);
		va_end(args);

		SetLastError(err);
	}
#endif /* DEBUG_WIN32API_TOOLHELP */

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

MODULE = Win32API::ToolHelp		PACKAGE = Win32API::ToolHelp		

BOOL
CloseToolhelp32Snapshot(IN hSnapshot)
		HANDLE hSnapshot
	CODE:
		RETVAL = CloseHandle(hSnapshot);
		RememberLastError(RETVAL);
	OUTPUT:
		RETVAL

HANDLE
CreateToolhelp32Snapshot(IN dwFlags, IN th32ProcessID)
		DWORD dwFlags
		DWORD th32ProcessID
	CODE:
		RETVAL = CreateToolhelp32Snapshot(dwFlags, th32ProcessID);
		RememberLastError(RETVAL != INVALID_HANDLE_VALUE);
	OUTPUT:
		RETVAL

DWORD
GetLastToolHelpError()
	CODE:
		RETVAL = dwLastError;
	OUTPUT:
		RETVAL

BOOL
Heap32First(OUT he, IN th32ProcessID, IN th32HeapID)
		HEAPENTRY32 he
		DWORD th32ProcessID
		ULONG_PTR th32HeapID
	CODE:
		he.dwSize = sizeof(he);
		RETVAL = Heap32First(&he, th32ProcessID, th32HeapID);
		RememberLastError(RETVAL);
	OUTPUT:
		he
		RETVAL

BOOL
Heap32ListFirst(IN hSnapshot, OUT hl)
		HANDLE hSnapshot
		HEAPLIST32 hl
	CODE:
		hl.dwSize = sizeof(hl);
		RETVAL = Heap32ListFirst(hSnapshot, &hl);
		RememberLastError(RETVAL);
	OUTPUT:
		hl
		RETVAL

BOOL
Heap32ListNext(IN hSnapshot, OUT hl)
		HANDLE hSnapshot
		HEAPLIST32 hl
	CODE:
		hl.dwSize = sizeof(hl);
		RETVAL = Heap32ListNext(hSnapshot, &hl);
		RememberLastError(RETVAL);
	OUTPUT:
		hl
		RETVAL

BOOL
Heap32Next(IN_OUT he)
		HEAPENTRY32 he
	CODE:
		RETVAL = Heap32Next(&he);
		RememberLastError(RETVAL);
	OUTPUT:
		he
		RETVAL

BOOL
Module32FirstA(IN hSnapshot, OUT me)
		HANDLE hSnapshot
		MODULEENTRY32 me
	CODE:
		me.dwSize = sizeof(me);
		RETVAL = Module32First(hSnapshot, &me);
		RememberLastError(RETVAL);
	OUTPUT:
		me
		RETVAL

BOOL
Module32FirstW(IN hSnapshot, OUT me)
		HANDLE hSnapshot
		MODULEENTRY32W me
	CODE:
		me.dwSize = sizeof(me);
		RETVAL = Module32FirstW(hSnapshot, &me);
		RememberLastError(RETVAL);
	OUTPUT:
		me
		RETVAL

BOOL
Module32NextA(IN hSnapshot, OUT me)
		HANDLE hSnapshot
		MODULEENTRY32 me
	CODE:
		me.dwSize = sizeof(me);
		RETVAL = Module32Next(hSnapshot, &me);
		RememberLastError(RETVAL);
	OUTPUT:
		me
		RETVAL

BOOL
Module32NextW(IN hSnapshot, OUT me)
		HANDLE hSnapshot
		MODULEENTRY32W me
	CODE:
		me.dwSize = sizeof(me);
		RETVAL = Module32NextW(hSnapshot, &me);
		RememberLastError(RETVAL);
	OUTPUT:
		me
		RETVAL

BOOL
Process32FirstA(IN hSnapshot, OUT pe)
		HANDLE hSnapshot
		PROCESSENTRY32 pe
	CODE:
		pe.dwSize = sizeof(pe);
		RETVAL = Process32First(hSnapshot, &pe);
		RememberLastError(RETVAL);
	OUTPUT:
		pe
		RETVAL

BOOL
Process32FirstW(IN hSnapshot, OUT pe)
		HANDLE hSnapshot
		PROCESSENTRY32W pe
	CODE:
		pe.dwSize = sizeof(pe);
		RETVAL = Process32FirstW(hSnapshot, &pe);
		RememberLastError(RETVAL);
	OUTPUT:
		pe
		RETVAL

BOOL
Process32NextA(IN hSnapshot, OUT pe)
		HANDLE hSnapshot
		PROCESSENTRY32 pe
	CODE:
		pe.dwSize = sizeof(pe);
		RETVAL = Process32Next(hSnapshot, &pe);
		RememberLastError(RETVAL);
	OUTPUT:
		pe
		RETVAL

BOOL
Process32NextW(IN hSnapshot, OUT pe)
		HANDLE hSnapshot
		PROCESSENTRY32W pe
	CODE:
		pe.dwSize = sizeof(pe);
		RETVAL = Process32NextW(hSnapshot, &pe);
		RememberLastError(RETVAL);
	OUTPUT:
		pe
		RETVAL

NO_OUTPUT void
SetLastToolHelpError(dwError)
		DWORD dwError
	CODE:
		AssignLastError(dwError);

BOOL
Thread32First(IN hSnapshot, OUT te)
		HANDLE hSnapshot
		THREADENTRY32 te
	CODE:
		te.dwSize = sizeof(te);
		RETVAL = Thread32Next(hSnapshot, &te);
		RememberLastError(RETVAL);
	OUTPUT:
		te
		RETVAL

BOOL
Thread32Next(IN hSnapshot, OUT te)
		HANDLE hSnapshot
		THREADENTRY32 te
	CODE:
		te.dwSize = sizeof(te);
		RETVAL = Thread32Next(hSnapshot, &te);
		RememberLastError(RETVAL);
	OUTPUT:
		te
		RETVAL

BOOL
Toolhelp32ReadProcessMemory(IN th32ProcessID, IN lpBaseAddress, OUT lpBuffer, IN cbRead, ...)
		DWORD th32ProcessID
		LPCVOID lpBaseAddress
		LPVOID lpBuffer
		SIZE_T cbRead;
	INIT:
		SIZE_T lpNumberOfBytesRead;
		SIZE_T len_lpBuffer;
	CODE:
		/*OUT lpNumberOfBytesRead*/
		if (cbRead != 0) {
			lpBuffer = malloc(cbRead);
			RETVAL = Toolhelp32ReadProcessMemory(th32ProcessID, lpBaseAddress, lpBuffer, cbRead, &lpNumberOfBytesRead);
		} else {
			AssignLastError(ERROR_INVALID_PARAMETER);
			RETVAL = FALSE;
		}
		if (!RETVAL)
			len_lpBuffer = 0;
		len_lpBuffer = lpNumberOfBytesRead;
		RememberLastError(RETVAL);
		if (items > 4) {
			if (!null_arg(ST(4)) && !SvREADONLY(ST(4)))
				sv_setuv(ST(4), (UV) lpNumberOfBytesRead);
			SvSETMAGIC(ST(4));
		}
	OUTPUT:
		lpBuffer
		RETVAL
