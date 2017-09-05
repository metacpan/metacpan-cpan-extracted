#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <windows.h>

/*
 * So it begins...
 *
 * - SetErrorMode() was introduced in XP / 2003
 *   we assume you are using at least XP / 2003
 *
 * - GetErrorMode() was introduced in Vista / 2008
 *   but apparently isn't supported by the version
 *   of Strawberry or MSVC++ that I am testing with
 *   (it does work with cygwin 64 that I am using
 *   I didn't try Strawberry 64, maybe it is a 32
 *   bit problem).  It can also be emulated using
 *   SetErrorMode(), although there is a race
 *   condition if you are using threads (including
 *   forking since this is windows).
 *   Thus:
 *     1. if GetErrorMode() is found dynamically
 *        using GetProcAddress() in kernel32.dll
 *        we use that.
 *     2. if not we emulate it using SetErrorMode()
 *     3. if there is an error resolving the symbol
 *        then we also use the GetErrorMode()
 *        emulation.
 *   This way we maintain binary compatability back
 *   To Windows XP / 2003, and we don't have the
 *   race condition for GetErrorMode() when forking
 *   on Vista / 2008 or better.
 *
 * - GetThreadErrorMode() and SetThreadErrorMode()
 *   are considered "safer" since they get/set the 
 *   error mode only on the current thread.  However
 *   they are also only available on Windows 7 and
 *   newer.  So we provode them, once again
 *   dynamically, if they are available.  Since
 *   no emulation is possible we throw a "not
 *   implemented" exception if they are not found.
 *   We still maintain binary compat with XP / 2003.
 */

typedef UINT  (__stdcall *GetErrorMode_t)      (void);
typedef DWORD (__stdcall *GetThreadErrorMode_t)(void);
typedef BOOL  (__stdcall *SetThreadErrorMode_t)(DWORD,LPDWORD);

static UINT __stdcall FallbackGetErrorMode(void)
{
  UINT old;
  old = SetErrorMode(0);
  SetErrorMode(old);
  return old;
}

static GetErrorMode_t       myGetErrorMode       = NULL;
static GetThreadErrorMode_t myGetThreadErrorMode = NULL;
static SetThreadErrorMode_t mySetThreadErrorMode = NULL;

static void
win32_error_mode_boot()
{
  HMODULE mod;
  
  mod = LoadLibrary("kernel32.dll");
  
  if(mod != NULL)
    myGetErrorMode = (GetErrorMode_t) GetProcAddress(mod, "GetErrorMode");

  if(myGetErrorMode == NULL)
    myGetErrorMode = &FallbackGetErrorMode;

  if(mod == NULL)
    return;
  
  myGetThreadErrorMode = (GetThreadErrorMode_t) GetProcAddress(mod, "GetThreadErrorMode");
  mySetThreadErrorMode = (SetThreadErrorMode_t) GetProcAddress(mod, "SetThreadErrorMode");
}

MODULE = Win32::ErrorMode PACKAGE = Win32::ErrorMode

BOOT:
    win32_error_mode_boot();

unsigned int
GetErrorMode()
  CODE:
    RETVAL = myGetErrorMode();
  OUTPUT:
    RETVAL

unsigned int
SetErrorMode(mode)
    unsigned int mode

unsigned int
GetThreadErrorMode()
  CODE:
    if(myGetThreadErrorMode == NULL)
      croak("not implemented");
    RETVAL = myGetThreadErrorMode();
  OUTPUT:
    RETVAL

unsigned int
SetThreadErrorMode(mode)
    unsigned int mode
  PREINIT:
    DWORD old;
    BOOL ok;
  CODE:
    if(mySetThreadErrorMode == NULL)
      croak("not implemented");
    ok = mySetThreadErrorMode(mode, &old);
    if(!ok)
      croak("error setting thread error mode");
    RETVAL = old;
  OUTPUT:
    RETVAL

int
_has_real_GetErrorMode()
  CODE:
    RETVAL = myGetErrorMode != &FallbackGetErrorMode;
  OUTPUT:
    RETVAL

int
_has_thread()
  CODE:
    RETVAL = myGetThreadErrorMode != NULL && mySetThreadErrorMode != NULL;
  OUTPUT:
    RETVAL

