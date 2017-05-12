/* Copyright 2000-2004, Phill Wolf.  See README. */

/* Win32::ActAcc (Active Accessibility) C-extension source file */

// Inproc Active Accessibility event handler for Win32::ActAcc

// Design rules:

//    No C runtime library usage (it could conflict with the app-under-test)

#pragma warning(disable: 4514) // unreferenced inline function has been removed
#pragma warning(disable: 4201) // nonstandard extension used : nameless struct/union
#define STRICT

#include <wtypes.h>
#include <winerror.h>
#include <winuser.h>
#include <commctrl.h>
#include <winable.h>

#define ActAccEM_LINKAGE __declspec(dllexport)

#include "AAEvtMon.h"
#include "ActAccEL.h"

HINSTANCE g_hinstDll = NULL;

// We don't want to require ANY runtime library support.
#pragma check_stack(off)
#pragma intrinsic(memset)
#pragma intrinsic(memcpy)
#pragma intrinsic(strcpy)
#pragma intrinsic(strlen)
#pragma warning(disable:4127)

BOOL WINAPI DllMain(HINSTANCE hinstDll, DWORD fdwReason, LPVOID /*fImpLoad*/)
{
    switch (fdwReason) 
    {
    case DLL_PROCESS_ATTACH:
        g_hinstDll = hinstDll;
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

// Increment with wrap-around. 
int incAndWrap(int a, const int lim, const int increment =1)
{
	a += increment;
	while (lim<=a)
		a -= lim;
	return a;
}

// called only when buffer is locked
void logEvent(DWORD event, HWND hwnd, LONG idObject, LONG idChild, DWORD dwmsEventTime, HWINEVENTHOOK hWinEventHook)
{
	pEvBuf->cumulativeCounter++;

	int cached_wc = pEvBuf->wc;

	pEvBuf->ae[cached_wc].event = event;
	pEvBuf->ae[cached_wc].hwnd = hwnd;
	pEvBuf->ae[cached_wc].idObject = idObject;
	pEvBuf->ae[cached_wc].idChild = idChild;
	pEvBuf->ae[cached_wc].dwmsEventTime = dwmsEventTime;
	pEvBuf->ae[cached_wc].hWinEventHook = hWinEventHook;

	pEvBuf->wc = incAndWrap(pEvBuf->wc, BUF_CAPY_IN_EVENTS);
}

extern "C" {
	ActAccEM_LINKAGE VOID CALLBACK WinEventProc(
	  HWINEVENTHOOK hWinEventHook,
	  DWORD event,
	  HWND hwnd,
	  LONG idObject,
	  LONG idChild,
	  DWORD dwEventThread,
	  DWORD dwmsEventTime
	);
};

//http://msdn.microsoft.com/library/default.asp?URL=/library/psdk/msaa/msaaccrf_9x9q.htm
VOID CALLBACK WinEventProc(
  HWINEVENTHOOK hWinEventHook,
  DWORD event,
  HWND hwnd,
  LONG idObject,
  LONG idChild,
  DWORD, // dwEventThread
  DWORD dwmsEventTime
)
{
	// First time, obtain handle to shared mutex.
	if (!oriented)
	{
		orient();
	}

	// Grab mutex. Log event. Release mutex.
	if (live)
	{
		if (WAIT_OBJECT_0 == WaitForSingleObject(hMx, AAEvtMon_PATIENCE_ms))
		{
			logEvent(event, hwnd, idObject, idChild, dwmsEventTime, hWinEventHook);
			ReleaseMutex(hMx);
		}
	}
}

