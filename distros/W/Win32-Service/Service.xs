/*
 * Service.xs
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define RETURNRESULT(x)		if ((x)){ XST_mYES(0); }\
                     		else { XST_mNO(0); }\
                     		XSRETURN(1)
#define SETIV(index,value) sv_setiv(ST(index), value)
#define SETPV(index,string) sv_setpv(ST(index), string)

/* constant function for exporting NT definitions. */

static long
constant(char *name)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
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
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	if (strEQ(name, "SERVICE_WIN32_OWN_PROCESS"))
#ifdef SERVICE_WIN32_OWN_PROCESS
		return SERVICE_WIN32_OWN_PROCESS;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_WIN32_SHARE_PROCESS"))
#ifdef SERVICE_WIN32_SHARE_PROCESS
		return SERVICE_WIN32_SHARE_PROCESS;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_KERNEL_DRIVER"))
#ifdef SERVICE_KERNEL_DRIVER
		return SERVICE_KERNEL_DRIVER;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_FILE_SYSTEM_DRIVER"))
#ifdef SERVICE_FILE_SYSTEM_DRIVER
		return SERVICE_FILE_SYSTEM_DRIVER;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_INTERACTIVE_PROCESS"))
#ifdef SERVICE_INTERACTIVE_PROCESS
		return SERVICE_INTERACTIVE_PROCESS;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_STOPPED"))
#ifdef SERVICE_STOPPED
		return SERVICE_STOPPED;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_START_PENDING"))
#ifdef SERVICE_START_PENDING
		return SERVICE_START_PENDING;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_STOP_PENDING"))
#ifdef SERVICE_STOP_PENDING
		return SERVICE_STOP_PENDING;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_RUNNING"))
#ifdef SERVICE_RUNNING
		return SERVICE_RUNNING;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_CONTINUE_PENDING"))
#ifdef SERVICE_CONTINUE_PENDING
		return SERVICE_CONTINUE_PENDING;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_PAUSE_PENDING"))
#ifdef SERVICE_PAUSE_PENDING
		return SERVICE_PAUSE_PENDING;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_PAUSED"))
#ifdef SERVICE_PAUSED
		return SERVICE_PAUSED;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_ACCEPT_STOP"))
#ifdef SERVICE_ACCEPT_STOP
		return SERVICE_ACCEPT_STOP;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_ACCEPT_PAUSE_CONTINUE"))
#ifdef SERVICE_ACCEPT_PAUSE_CONTINUE
		return SERVICE_ACCEPT_PAUSE_CONTINUE;
#else
		goto not_there;
#endif	
	if (strEQ(name, "SERVICE_ACCEPT_SHUTDOWN"))
#ifdef SERVICE_ACCEPT_SHUTDOWN
		return SERVICE_ACCEPT_SHUTDOWN;
#else
		goto not_there;
#endif	
	break;
    case 'T':
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

MODULE = Win32::Service		PACKAGE = Win32::Service

PROTOTYPES: DISABLE

long
constant(name)
	char *name
    CODE:
	RETVAL = constant(name);
    OUTPUT:
	RETVAL


bool
StartService(lpHostName, lpServiceName)
    	char *lpHostName
	char *lpServiceName
    CODE:
	{
	    SC_HANDLE hSCManager, hSCService;
	    RETVAL = FALSE;
	    if (lpHostName && *lpHostName == '\0')
		lpHostName = NULL;
	    if (lpServiceName && *lpServiceName != '\0') {
                hSCManager = OpenSCManagerA(lpHostName, NULL, SC_MANAGER_CONNECT);

		if (hSCManager != NULL)	{
                    hSCService = OpenServiceA(hSCManager, lpServiceName, SERVICE_START);
		    if (hSCService != NULL)  {
			RETVAL = StartService(hSCService, 0, NULL);
			CloseServiceHandle(hSCService);
		    }
		    CloseServiceHandle(hSCManager);
		}
	    }
	}
    OUTPUT:
	RETVAL


bool
StopService(lpHostName, lpServiceName)
    	char *lpHostName
	char *lpServiceName
    CODE:
	{
	    SERVICE_STATUS serviceStatus;
	    SC_HANDLE hSCManager, hSCService;
	    RETVAL = FALSE;
	    if (lpHostName && *lpHostName == '\0')
		lpHostName = NULL;
	    if (lpServiceName && *lpServiceName != '\0') {
                hSCManager = OpenSCManagerA(lpHostName, NULL, SC_MANAGER_CONNECT);

		if (hSCManager != NULL)	{
                    hSCService = OpenServiceA(hSCManager, lpServiceName, SERVICE_STOP);
		    if (hSCService != NULL) {
			RETVAL = ControlService(hSCService, SERVICE_CONTROL_STOP,
						&serviceStatus);
			CloseServiceHandle(hSCService);
		    }
		    CloseServiceHandle(hSCManager);
		}
	    }
	}
    OUTPUT:
	RETVAL

bool
GetStatus(lpHostName,lpServiceName,status)
    	char *lpHostName
	char *lpServiceName
	SV *status
    CODE:
	{
	    SERVICE_STATUS serviceStatus;
	    SC_HANDLE hSCManager, hSCService;

	    RETVAL = FALSE;
	    if (!(status && SvROK(status) &&
		  (status = SvRV(status)) && SvTYPE(status) == SVt_PVHV))
		croak("third arg must be a HASHREF");
	    
	    if (lpHostName && *lpHostName == '\0')
		lpHostName = NULL;
	    if (lpServiceName && *lpServiceName != '\0') {
                hSCManager = OpenSCManagerA(lpHostName, NULL, SC_MANAGER_CONNECT);

		if (hSCManager != NULL)	{
                    hSCService = OpenServiceA(hSCManager, lpServiceName, SERVICE_INTERROGATE);

		    if (hSCService != NULL) {
			RETVAL = ControlService(hSCService, SERVICE_CONTROL_INTERROGATE,
						&serviceStatus);
			if (!RETVAL && GetLastError() == ERROR_SERVICE_NOT_ACTIVE) {
			    Zero(&serviceStatus, 1, SERVICE_STATUS);
			    serviceStatus.dwCurrentState = SERVICE_STOPPED;
			    RETVAL = TRUE;
			}
			CloseServiceHandle(hSCService);
		    }
		    CloseServiceHandle(hSCManager);
		    if (RETVAL) {
			SV *sv;
			sv = newSViv(serviceStatus.dwServiceType);
			hv_store((HV*)status, "ServiceType", (I32)strlen("ServiceType"), sv, 0);
			
			sv = newSViv(serviceStatus.dwCurrentState);
			hv_store((HV*)status, "CurrentState", (I32)strlen("CurrentState"), sv, 0);
			
			sv = newSViv(serviceStatus.dwControlsAccepted);
			hv_store((HV*)status, "ControlsAccepted", (I32)strlen("ControlsAccepted"), sv, 0);
			
			sv = newSViv(serviceStatus.dwWin32ExitCode);
			hv_store((HV*)status, "Win32ExitCode", (I32)strlen("Win32ExitCode"), sv, 0);
			
			sv = newSViv(serviceStatus.dwServiceSpecificExitCode);
			hv_store((HV*)status, "ServiceSpecificExitCode", (I32)strlen("ServiceSpecificExitCode"), sv, 0);
			
			sv = newSViv(serviceStatus.dwCheckPoint);
			hv_store((HV*)status, "CheckPoint", (I32)strlen("CheckPoint"), sv, 0);
			
			sv = newSViv(serviceStatus.dwWaitHint);
			hv_store((HV*)status, "WaitHint", (I32)strlen("WaitHint"), sv, 0);
		    }
		}
	    }
	}
    OUTPUT:
	RETVAL

bool	
PauseService(lpHostName,lpServiceName)
    	char *lpHostName
	char *lpServiceName
    CODE:
	{
	    SERVICE_STATUS serviceStatus;
	    SC_HANDLE hSCManager, hSCService;
	    RETVAL = FALSE;
	    if (lpHostName && *lpHostName == '\0')
		lpHostName = NULL;
	    if (lpServiceName && *lpServiceName != '\0') {
                hSCManager = OpenSCManagerA(lpHostName, NULL, SC_MANAGER_CONNECT);

		if (hSCManager != NULL)	{
                    hSCService = OpenServiceA(hSCManager, lpServiceName, SERVICE_PAUSE_CONTINUE);

		    if (hSCService != NULL) {
			RETVAL = ControlService(hSCService, SERVICE_CONTROL_PAUSE, &serviceStatus);
			CloseServiceHandle(hSCService);
		    }
		    CloseServiceHandle(hSCManager);
		}
	    }
	}
    OUTPUT:
	RETVAL

bool
ResumeService(lpHostName,lpServiceName)
    	char *lpHostName
	char *lpServiceName
    CODE:
	{
	    SERVICE_STATUS serviceStatus;
	    SC_HANDLE hSCManager, hSCService;
	    RETVAL = FALSE;
	    if (lpHostName && *lpHostName == '\0')
		lpHostName = NULL;
	    if (lpServiceName && *lpServiceName != '\0') {
                hSCManager = OpenSCManagerA(lpHostName, NULL, SC_MANAGER_CONNECT);

		if (hSCManager != NULL)	{
                    hSCService = OpenServiceA(hSCManager, lpServiceName, SERVICE_PAUSE_CONTINUE);
		    if (hSCService != NULL) {
			RETVAL = ControlService(hSCService, SERVICE_CONTROL_CONTINUE,
						&serviceStatus);
			CloseServiceHandle(hSCService);
		    }
		    CloseServiceHandle(hSCManager);
		}
	    }
	}
    OUTPUT:
	RETVAL

bool
GetServices(lpHostName, hv)
    	char *lpHostName
	SV *hv
    CODE:
	{
	    DWORD dwBytesNeeded, dwServicesReturned, dwResumeHandle, dwIndex;
	    ENUM_SERVICE_STATUSA essA[1000];
	    char szService[MAX_PATH+1];
	    char szDisplay[MAX_PATH+1];
	    LPSTR lpDisplayName, lpServiceName;
	    SC_HANDLE hSCManager;
	    SV *sv;

	    RETVAL = FALSE;
	    if (!(hv && SvROK(hv) &&
		  (hv = SvRV(hv)) && SvTYPE(hv) == SVt_PVHV))
		croak("second argument must be a HASHREF");

	    if (lpHostName && *lpHostName == '\0')
		lpHostName = NULL;

            hSCManager = OpenSCManagerA(lpHostName, NULL, SC_MANAGER_CONNECT|SC_MANAGER_ENUMERATE_SERVICE);
	    if (hSCManager != NULL) {
		dwResumeHandle = 0;
		dwBytesNeeded = 0;
		dwServicesReturned = 0;
		while (EnumServicesStatusA(hSCManager, SERVICE_WIN32,
                                           SERVICE_ACTIVE | SERVICE_INACTIVE,
                                           essA, sizeof(essA), &dwBytesNeeded,
                                           &dwServicesReturned,
                                           &dwResumeHandle) == TRUE
		       || GetLastError() == ERROR_MORE_DATA)
		{
		    lpServiceName = szService;
		    lpDisplayName = szDisplay;
		    for (dwIndex = 0; dwIndex < dwServicesReturned; ++dwIndex) {
                        lpServiceName = essA[dwIndex].lpServiceName;
                        lpDisplayName = essA[dwIndex].lpDisplayName;

			sv = newSVpv(lpServiceName, 0);
			hv_store((HV*)hv, lpDisplayName,
				 (I32)strlen(lpDisplayName), sv, 0);
		    }
		    if (dwResumeHandle == 0) {
			RETVAL = TRUE;
			break;
		    }
		}
		CloseServiceHandle(hSCManager);
	    }
	}
    OUTPUT:
	RETVAL



