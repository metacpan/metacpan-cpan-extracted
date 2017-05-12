#include <stdlib.h>		// avoid BCC-5.0 brainmelt
#include <math.h>		// avoid VC-5.0 brainmelt
#include "Process.hpp"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#if defined(__cplusplus)
#   include <stdlib.h>
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.H"

#include "ppport.h"

#ifndef ABOVE_NORMAL_PRIORITY_CLASS
#   define ABOVE_NORMAL_PRIORITY_CLASS       0x00008000
#endif
#ifndef BELOW_NORMAL_PRIORITY_CLASS
#   define BELOW_NORMAL_PRIORITY_CLASS       0x00004000
#endif

static BOOL
Create(cProcess* &cP, char* szAppName, char* szCommLine, DWORD Inherit,
       DWORD CreateFlags, char* szCurrDir)
{
    BOOL bRetVal;
    void *env = NULL;
#ifdef PERL_IMPLICIT_SYS
    env = PerlEnv_get_childenv();
#endif
    cP = NULL;
    try {
	cP = (cProcess*)new cProcess(szAppName,szCommLine,Inherit,CreateFlags,
                                     env,szCurrDir);
        bRetVal = cP->bRetVal;
    }
    catch (...) {
        bRetVal = FALSE;
    }
#ifdef PERL_IMPLICIT_SYS
    PerlEnv_free_childenv(env);
#endif
    return bRetVal;
}

static BOOL
Open_(cProcess * &cP, DWORD pid, DWORD Inherit)
{
    cP = NULL;
    try {
	cP = (cProcess *) new cProcess(pid, Inherit);
    }
    catch (...) {
	return(FALSE);
    }
    return(cP->bRetVal);
}



static double
constant(char* name)
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ABOVE_NORMAL_PRIORITY_CLASS"))
#ifdef ABOVE_NORMAL_PRIORITY_CLASS
	    return ABOVE_NORMAL_PRIORITY_CLASS;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BELOW_NORMAL_PRIORITY_CLASS"))
#ifdef BELOW_NORMAL_PRIORITY_CLASS
	    return BELOW_NORMAL_PRIORITY_CLASS;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "CREATE_DEFAULT_ERROR_MODE"))
#ifdef CREATE_DEFAULT_ERROR_MODE
	    return CREATE_DEFAULT_ERROR_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREATE_NEW_CONSOLE"))
#ifdef CREATE_NEW_CONSOLE
	    return CREATE_NEW_CONSOLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREATE_NEW_PROCESS_GROUP"))
#ifdef CREATE_NEW_PROCESS_GROUP
	    return CREATE_NEW_PROCESS_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREATE_NO_WINDOW"))
#ifdef CREATE_NO_WINDOW
	    return CREATE_NO_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREATE_SEPARATE_WOW_VDM"))
#ifdef CREATE_SEPARATE_WOW_VDM
	    return CREATE_SEPARATE_WOW_VDM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREATE_SUSPENDED"))
#ifdef CREATE_SUSPENDED
	    return CREATE_SUSPENDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREATE_UNICODE_ENVIRONMENT"))
#ifdef CREATE_UNICODE_ENVIRONMENT
	    return CREATE_UNICODE_ENVIRONMENT;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DEBUG_ONLY_THIS_PROCESS"))
#ifdef DEBUG_ONLY_THIS_PROCESS
	    return DEBUG_ONLY_THIS_PROCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DEBUG_PROCESS"))
#ifdef DEBUG_PROCESS
	    return DEBUG_PROCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DETACHED_PROCESS"))
#ifdef DETACHED_PROCESS
	    return DETACHED_PROCESS;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	if (strEQ(name, "HIGH_PRIORITY_CLASS"))
#ifdef HIGH_PRIORITY_CLASS
	    return HIGH_PRIORITY_CLASS;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	if (strEQ(name, "IDLE_PRIORITY_CLASS"))
#ifdef IDLE_PRIORITY_CLASS
	    return IDLE_PRIORITY_CLASS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFINITE"))
#ifdef INFINITE
	    return INFINITE;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	if (strEQ(name, "NORMAL_PRIORITY_CLASS"))
#ifdef NORMAL_PRIORITY_CLASS
	    return NORMAL_PRIORITY_CLASS;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "REALTIME_PRIORITY_CLASS"))
#ifdef REALTIME_PRIORITY_CLASS
	    return REALTIME_PRIORITY_CLASS;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "STILL_ACTIVE"))
#ifdef STILL_ACTIVE
	    return STILL_ACTIVE;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "THREAD_PRIORITY_ABOVE_NORMAL"))
#ifdef THREAD_PRIORITY_ABOVE_NORMAL
	    return THREAD_PRIORITY_ABOVE_NORMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_BELOW_NORMAL"))
#ifdef THREAD_PRIORITY_BELOW_NORMAL
	    return THREAD_PRIORITY_BELOW_NORMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_ERROR_RETURN"))
#ifdef THREAD_PRIORITY_ERROR_RETURN
	    return THREAD_PRIORITY_ERROR_RETURN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_HIGHEST"))
#ifdef THREAD_PRIORITY_HIGHEST
	    return THREAD_PRIORITY_HIGHEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_IDLE"))
#ifdef THREAD_PRIORITY_IDLE
	    return THREAD_PRIORITY_IDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_LOWEST"))
#ifdef THREAD_PRIORITY_LOWEST
	    return THREAD_PRIORITY_LOWEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_NORMAL"))
#ifdef THREAD_PRIORITY_NORMAL
	    return THREAD_PRIORITY_NORMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "THREAD_PRIORITY_TIME_CRITICAL"))
#ifdef THREAD_PRIORITY_TIME_CRITICAL
	    return THREAD_PRIORITY_TIME_CRITICAL;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

#if defined(__cplusplus)
}
#endif


MODULE = Win32::Process		PACKAGE = Win32::Process

PROTOTYPES: DISABLE


BOOL
Create(cP,appname,cmdline,inherit,flags,curdir)
    cProcess *cP = NULL;
    char *appname
    char *cmdline
    BOOL inherit
    DWORD flags
    char *curdir
CODE:
    RETVAL = Create(cP, appname, cmdline, inherit, flags, curdir);
OUTPUT:
    cP
    RETVAL


BOOL
Open(cP,pid,inherit)
    cProcess *cP = NULL;
    DWORD pid
    BOOL inherit
CODE:
    RETVAL = Open_(cP, pid, inherit);
OUTPUT:
    cP
    RETVAL


double
constant(name)
    char *name


BOOL
Kill(cP,exitcode)
    cProcess *cP
    unsigned int exitcode
CODE:
    RETVAL = cP->Kill(exitcode);
OUTPUT:
    RETVAL

BOOL
Suspend(cP)
    cProcess *cP
CODE:
    RETVAL = cP->Suspend();
OUTPUT:
    RETVAL

BOOL
Resume(cP)
    cProcess *cP
CODE:
    RETVAL = cP->Resume();
OUTPUT:
    RETVAL

BOOL
GetPriorityClass(cP,priorityclass)
    cProcess *cP
    DWORD priorityclass = NO_INIT
CODE:
    RETVAL = cP->GetPriorityClass(&priorityclass);
OUTPUT:
    priorityclass
    RETVAL


BOOL
SetPriorityClass(cP,priorityclass)
    cProcess *cP
    DWORD priorityclass
CODE:
    RETVAL = cP->SetPriorityClass(priorityclass);
OUTPUT:
    RETVAL


BOOL
GetProcessAffinityMask(cP,processAffinityMask,systemAffinityMask)
    cProcess *cP
    DWORD_PTR processAffinityMask = NO_INIT
    DWORD_PTR systemAffinityMask = NO_INIT
CODE:
    RETVAL = cP->GetProcessAffinityMask(&processAffinityMask,&systemAffinityMask);
OUTPUT:
    processAffinityMask
    systemAffinityMask
    RETVAL


BOOL
SetProcessAffinityMask(cP,processAffinityMask)
    cProcess *cP
    DWORD processAffinityMask
CODE:
    RETVAL = cP->SetProcessAffinityMask(processAffinityMask);
OUTPUT:
    RETVAL


BOOL
GetExitCode(cP,exitcode)
    cProcess *cP
    DWORD exitcode = NO_INIT
CODE:
    RETVAL = cP->GetExitCode(&exitcode);
OUTPUT:
    exitcode
    RETVAL


void
DESTROY(cP)
    cProcess *cP
CODE:
    delete cP;


BOOL
Wait(cP,timeout)
    cProcess *cP
    DWORD timeout
CODE:
    RETVAL = (cP->Wait(timeout) == WAIT_OBJECT_0);
OUTPUT:
    RETVAL


IV
get_process_handle(cP)
    cProcess *cP
CODE:
    RETVAL = reinterpret_cast<IV>(cP->GetProcessHandle());
OUTPUT:
    RETVAL

DWORD
GetProcessID(cP)
    cProcess *cP
CODE:
    RETVAL = cP->GetProcessID();
OUTPUT:
    RETVAL

BOOL
KillProcess(pid, exitcode)
    DWORD pid
    unsigned int exitcode
CODE:
    {
	HANDLE ph = OpenProcess(PROCESS_ALL_ACCESS, 0, pid);
	if (ph) {
	    RETVAL = TerminateProcess(ph, exitcode);
	    if (RETVAL)
		CloseHandle(ph);
	}
    }
OUTPUT:
    RETVAL

DWORD
GetCurrentProcessID()
CODE:
    RETVAL = GetCurrentProcessId();
OUTPUT:
    RETVAL

