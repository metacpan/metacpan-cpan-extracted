/* Copyright 2000-raw2, Phill Wolf.  See README. */

/* Win32::ActAcc (Active Accessibility) C-extension source file */

#ifndef INCL_AAEVTMON_H
#define INCL_AAEVTMON_H

// The implementation (in ActAccEM.dll) needs ActAccEM_LINKAGE defined as __declspec(dllexport).
// For clients, e.g., the Perl process, we need the definition as __declspec(dllimport).
#ifndef ActAccEM_LINKAGE
#define ActAccEM_LINKAGE __declspec(dllimport)
#endif

// Names of shared kernel objects
#define AAEvtMon_MUTEX "Win32::ActAcc::AAEvtMon_MUTEX"
#define AAEvtMon_MAP "Win32::ActAcc::AAEvtMon_MAP2"

// Timeout waiting for a kernel object.
#define AAEvtMon_PATIENCE_ms (2000)

// Info the circular buffer saves for each event
struct aaevt
{
	DWORD event;
	HWND hwnd;
	LONG idObject;
	LONG idChild;
	DWORD dwmsEventTime;
    HWINEVENTHOOK hWinEventHook;
};

#define BUF_CAPY_IN_EVENTS (5000) // arbitrary

// Note to programmer:
// Once any Win32::ActAcc process has created
// a memory block for aaevbuf, you'll have to shut
// down and restart Windows 
// (or change the memory block's name) 
// if you change the size/layout
// of the memory block. 
struct aaevbuf
{
	long cumulativeCounter; 
	int wc; // writing cursor
	struct aaevt ae[BUF_CAPY_IN_EVENTS];
};

#endif
