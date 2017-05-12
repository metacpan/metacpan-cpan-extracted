/* MessageLoop.xs
 *
 *  (c) 2013 Michael Roberts. All rights reserved.
 *
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the README file.
 *
 *  This is all just cut down from Win32::OLE, so some of it
 *  probably isn't needed. But if it ain't broke, I'm not going to fix it.
 */

// #define _DEBUG

#define register /* be gone */

#define MY_VERSION "Win32::MessageLoop(" XS_VERSION ")"

#include <math.h>	/* this hack gets around VC-5.0 brainmelt */
#define _WIN32_DCOM
#include <windows.h>

#ifdef _DEBUG
#   include <crtdbg.h>
#   define DEBUGBREAK _CrtDbgBreak()
#else
#   define DEBUGBREAK
#endif

// MingW is missing these 2 macros
#ifndef V_RECORD
#   ifdef NONAMELESSUNION
#       define V_RECORDINFO(X) ((X)->__VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pRecInfo)
#       define V_RECORD(X)     ((X)->__VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pvRecord)
#   else
#       define V_RECORDINFO(X) ((X)->pRecInfo)
#       define V_RECORD(X)     ((X)->pvRecord)
#   endif
#endif

extern "C" {
#ifndef GUIDKIND_DEFAULT_SOURCE_DISP_IID
#   define GUIDKIND_DEFAULT_SOURCE_DISP_IID 1
#endif

#ifdef __CYGWIN__
#   undef WIN32			/* don't use with Cygwin & Perl */
#   include <netdb.h>
#   include <sys/socket.h>
#   include <unistd.h>

#   ifndef strrev
#     define strrev my_strrev

static char *
my_strrev(char *str)
{
    char *left = str;
    char *right = left + strlen(left) - 1;
    while (left < right) {
        char temp = *left;
        *left++ = *right;
        *right-- = temp;
    }
    return str;
}

#   endif /* strrev */
#endif

#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"

#undef WORD
typedef unsigned short WORD;

#ifndef _WIN64
#  define DWORD_PTR	DWORD
#endif

#ifndef _DEBUG
#   define DBG(a)
#else
#   define DBG(a)  MyDebug a
void
MyDebug(const char *pat, ...)
{
    DWORD thread = GetCurrentThreadId();
    void *context = PERL_GET_CONTEXT;
    char szBuffer[512];
    char *szMessage = szBuffer + sprintf(szBuffer, "[%d:%p] ", thread, context);
    va_list args;
    va_start(args, pat);
    vsprintf(szMessage, pat, args);
    OutputDebugString(szBuffer);
    va_end(args);
}
#endif


//------------------------------------------------------------------------


inline void
SpinMessageLoop(void)
{
    MSG msg;

    DBG(("SpinMessageLoop\n"));
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
	TranslateMessage(&msg);
	DispatchMessage(&msg);
    }

}   /* SpinMessageLoop */

UINT_PTR timer;
inline void
MyTimerProc(HWND     hwnd, 
            UINT     uMsg, 
            UINT_PTR idEvent, 
            DWORD    dwTime)
{
	if (timer) {
		KillTimer(hwnd, idEvent);
		timer = 0;
	}
	PostThreadMessage(GetCurrentThreadId(), WM_USER, 0, 0);
}

inline void
MessageLoop(UINT timeout)
{
	MSG message;

    if (timeout) {
    	timer = SetTimer (NULL, 0, timeout, &MyTimerProc);
    }
	DBG(("MessageLoop\n"));
	while (GetMessage(&message, NULL, 0, 0)) {
	    if (message.hwnd == NULL && message.message == WM_USER)
		break;
	    TranslateMessage(&message);
	    DispatchMessage(&message);
	}

}


}   /* extern "C" */

/*##########################################################################*/

MODULE = Win32::MessageLoop		PACKAGE = Win32::MessageLoop

PROTOTYPES: DISABLE

void
SpinMessageLoop()
PPCODE:
{
	SpinMessageLoop();
    XSRETURN_EMPTY;
}

void
MessageLoop(...)
PPCODE:
{
    HV *stash = gv_stashsv(ST(0), TRUE);

    UINT timeout = 0;
    if (items > 1) {
    	timeout = SvUV(ST(1));
    }
	MessageLoop(timeout);	
    XSRETURN_EMPTY;
}

void
QuitMessageLoop(...)
PPCODE:
{
	PostThreadMessage(GetCurrentThreadId(), WM_USER, 0, 0);
    XSRETURN_EMPTY;
}

