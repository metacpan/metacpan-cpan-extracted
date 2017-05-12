/* Copyright 2000-2004, Phill Wolf.  See README.  -*-Mode: c;-*- */

/* Win32::ActAcc (Active Accessibility) C-extension source file */

#pragma warning(disable: 4514) // unreferenced inline function has been removed
#pragma warning(disable: 4201) // nonstandard extension used : nameless struct/union
#define STRICT

#include <wtypes.h>
#include <winerror.h>
#include <winuser.h>
#include <commctrl.h>
#include <winable.h>

#include "AAEvtMon.h"
#include "ActAccEL.h"

// We don't want to require ANY runtime library support.
// We're going to be installed into the address space of any/all applications.
#pragma check_stack(off)
#pragma intrinsic(memset)
#pragma intrinsic(memcpy)
#pragma intrinsic(strcpy)
#pragma intrinsic(strlen)
#pragma warning(disable:4127)

bool oriented = false; // false until orient(); guarantees we initialize once
bool live = false; // true if we've initialized pEvBuf
HANDLE hMx = 0; // mutex guarding simultaneous access to event buffer
HANDLE hFM = 0;
struct aaevbuf * pEvBuf = 0;

// Opens named mutex named by lpName, if it exists.
// If the open fails, then, attempts to create the named mutex.
// Caller should check GetLastError if returns NULL.
HANDLE OpenOrCreateMutex(char *lpName)
{
  HANDLE rv = OpenMutex(MUTEX_ALL_ACCESS, FALSE, lpName);
  if (!rv)
	rv = CreateMutex(NULL, FALSE, lpName);
  return rv;
}

HANDLE OpenOrCreateFileMapping(char *lpName)
{
  HANDLE rv = OpenFileMapping(FILE_MAP_ALL_ACCESS, FALSE, lpName);
  if (!rv)
	rv = CreateFileMapping(
                           (HANDLE)0xffffffff, 
                           NULL, 
                           PAGE_READWRITE, 
                           0, sizeof(struct aaevbuf), 
                           AAEvtMon_MAP);
  return rv;
}

// Opens-or-creates the mutex and the shared-memory buffer.
// Caller may use GetLastError to check on the success.
// Sets the "oriented" flag upon success or failure
// (since there's no point in trying it again).
void orient()
{
  hMx = OpenOrCreateMutex(AAEvtMon_MUTEX);
  if (hMx)
	{
      hFM = OpenOrCreateFileMapping(AAEvtMon_MAP);
      if (hFM)
		{
          pEvBuf = (struct aaevbuf *) MapViewOfFile(
                                                    hFM, 
                                                    FILE_MAP_WRITE|FILE_MAP_READ, 
                                                    0, 0, 
                                                    sizeof(struct aaevbuf));
          if (pEvBuf)
			{
              live = true;
			}
          else
			{
              DWORD preserve = GetLastError();
              CloseHandle(hMx);
              hMx = 0;
              CloseHandle(hFM);
              hFM = 0;
              SetLastError(preserve);
			}
		}
      else
		{
          DWORD preserve = GetLastError();
          CloseHandle(hMx);
          hMx = 0;
          SetLastError(preserve);
		}
	}
  oriented = true; // regardless whether it worked.
}

long emGetCounter()
{
  int rv = -1; // pessimistic

  // First time, obtain handle to shared mutex.
  if (!oriented)
	{
      orient();
	}

  // Grab mutex. Copy result from shared buffer. Release mutex.
  if (live)
	{
      if (WAIT_OBJECT_0 == WaitForSingleObject(hMx, AAEvtMon_PATIENCE_ms))
		{
          rv = pEvBuf->cumulativeCounter;
          ReleaseMutex(hMx);
		}
	}

  return rv;
}

bool emLock()
{
  bool rv = false;

  // First time, obtain handle to shared mutex.
  if (!oriented)
	{
      orient();
	}

  // Grab mutex. Log event. Release mutex.
  if (live)
	{
      if (WAIT_OBJECT_0 == WaitForSingleObject(hMx, AAEvtMon_PATIENCE_ms))
        rv = true;
	}

  return rv;
}

// Unlock the mutex. If GetLastError was nonzero,
// preserve it rather than obliterating it with the error code
// if any resulting from the mutex release.
void emUnlock()
{
  DWORD preserve = GetLastError();
  ReleaseMutex(hMx);
  if (preserve)
    SetLastError(preserve);
}

// call only when locked readCursorQume is cumulative - not relative
// to start of buffer. It does not wrap.
void emGetEventPtr(const long readCursorQume, 
                   const int max, int *actual, 
                   struct aaevt **pp)
{
  // pessimistic
  *actual = 0;
  *pp = 0;

  // Translate cumulative readCursor to relative.
  int readCursor = readCursorQume % BUF_CAPY_IN_EVENTS;

  // Ordinarily, the max block size is BUF_CAPY_IN_EVENTS - readCursor.
  int eventsInReadableBlock = BUF_CAPY_IN_EVENTS - readCursor;

  // But readCursorQume may never exceed cumulativeCounter.
  if (eventsInReadableBlock > (pEvBuf->cumulativeCounter - readCursorQume))
    eventsInReadableBlock = pEvBuf->cumulativeCounter - readCursorQume;

  // And impose the user's ceiling, if lower.
  *actual = (max < eventsInReadableBlock) ? max : eventsInReadableBlock;

  *pp = pEvBuf->ae + readCursor;
}

// call only when locked.
// returns readCursor that will (at the moment) have nothing to read.
long emSynch()
{
  return pEvBuf->cumulativeCounter;
}
