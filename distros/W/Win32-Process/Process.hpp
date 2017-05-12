/*
    cProcess class definition for the Win32::Process module extension
*/
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#ifndef _WIN64
#  define DWORD_PTR	DWORD
#  define PDWORD_PTR	DWORD*
#endif

typedef BOOL (WINAPI *LPSetProcessAffinityMask)(HANDLE, DWORD);

class cProcess
{
private:

    HANDLE	ph;
    HANDLE	th;
    DWORD	pid;

    LPSetProcessAffinityMask pSetProcessAffinityMask;
    HINSTANCE hLib;

public:

    BOOL    bRetVal;
    cProcess(char* szAppName, char* szCommLine, BOOL Inherit,
	      DWORD CreateFlags, void *env, char* szCurrDir)
    {
	STARTUPINFOA st;
	PROCESS_INFORMATION	procinfo;

	st.lpReserved=NULL;
	st.cb = sizeof( STARTUPINFO );
	st.lpDesktop = NULL;
	st.lpTitle = NULL;
	st.dwFlags = 0;
	st.cbReserved2 = 0;
	st.lpReserved2 = NULL;
	ph = NULL;
	th = NULL;

	bRetVal = CreateProcessA(szAppName,szCommLine,NULL,NULL,
				 Inherit,CreateFlags,env,szCurrDir,
				 &st,&procinfo);

	if (bRetVal) {
	    ph = procinfo.hProcess;
	    th = procinfo.hThread;
	    pid = procinfo.dwProcessId;
	}

	pSetProcessAffinityMask = NULL;
	hLib = LoadLibrary("kernel32.dll");
	if (hLib != NULL)
		pSetProcessAffinityMask = (LPSetProcessAffinityMask)GetProcAddress(hLib, "SetProcessAffinityMask");
    }

    cProcess(DWORD pid_, BOOL Inherit)
    {
	ph      = NULL;
	th      = NULL;
	pid     = 0;
	bRetVal = 0;

	pSetProcessAffinityMask = NULL;
	hLib = LoadLibrary("kernel32.dll");
	if (hLib != NULL)
		pSetProcessAffinityMask = (LPSetProcessAffinityMask)GetProcAddress(hLib, "SetProcessAffinityMask");

	HANDLE ph_ = OpenProcess(PROCESS_DUP_HANDLE        |
				 PROCESS_QUERY_INFORMATION |
				 PROCESS_SET_INFORMATION   |
				 PROCESS_TERMINATE         |
                                 SYNCHRONIZE,
				 Inherit, pid_);
	if (NULL == ph_) {
	    return;
	}
        pid     = pid_;
	ph      = ph_;
	bRetVal = 1;
    }

    ~cProcess()
    {
	CloseHandle( th );
	CloseHandle( ph );
	FreeLibrary( hLib );
    }
    BOOL Kill(UINT uExitCode)
	{ return TerminateProcess( ph, uExitCode ); }
    BOOL Suspend()
	{ return th ? SuspendThread( th ) : 0; }
    BOOL Resume()
	{ return th ? ResumeThread( th ) : 0; }
    BOOL GetPriorityClass( DWORD* pdwPriorityClass )
    {
	(*pdwPriorityClass) = ::GetPriorityClass(ph);
	return ((pdwPriorityClass == 0) ? FALSE : TRUE);
    }
    BOOL SetPriorityClass( DWORD dwPriorityClass )
	{ return ::SetPriorityClass( ph, dwPriorityClass ); }
    BOOL GetProcessAffinityMask( PDWORD_PTR pdwProcessAffinityMask, PDWORD_PTR pdwSystemAffinityMask )
	{ return ::GetProcessAffinityMask( ph, pdwProcessAffinityMask, pdwSystemAffinityMask ); }
    BOOL SetProcessAffinityMask( DWORD dwProcessAffinityMask )
    {
	if(pSetProcessAffinityMask)
	    return pSetProcessAffinityMask( ph, dwProcessAffinityMask );
	return FALSE;
    }
    BOOL GetExitCode( DWORD* pdwExitCode )
	{ return GetExitCodeProcess( ph, pdwExitCode ); }
    DWORD Wait( DWORD TimeOut )
	{ return WaitForSingleObject( ph, TimeOut ); }
    HANDLE GetProcessHandle() const
	{ return ph; }
    DWORD GetProcessID()
	{ return pid; }
};
