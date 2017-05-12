#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#define WINNT				0x11
#define WIN9X				0x12
#define EXITWINDOWS_FAILED		0x13
#define EXITWINDOWS_SUCESS		0x14
#define ADJUST_TOCKEN_SUCESS		0x15
#define ADJUST_TOCKEN_FAILED		0x15
#define ADJUST_PRIVILEGE_FAILED		0x16
#define OPENING_PROCESS_TOKEN_FAILED	0x100


/* WinVer() tells us what version of windows is running, which we need to know before deciding how to shut down */
int WinVer() {
	OSVERSIONINFO osvi;
	BOOL bval;
	osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
		
	bval=GetVersionEx(&osvi);
		
	if(osvi.dwPlatformId==VER_PLATFORM_WIN32_NT)
	{
	  return WINNT;
	}
	else if(osvi.dwPlatformId=VER_PLATFORM_WIN32_WINDOWS)
	{
	  return WIN9X;
	}	
	return 0;
}		


/* AdjustProcessTokenPrivilege() lets us get permission to do a shutdown */
int AdjustProcessTokenPrivilege()
{
	HANDLE hToken; 
	TOKEN_PRIVILEGES tkp; 
 
	if (!OpenProcessToken(GetCurrentProcess(),TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) 
	{
		return OPENING_PROCESS_TOKEN_FAILED;
	}
 
	if(!LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME,&tkp.Privileges[0].Luid))
	{
		return ADJUST_PRIVILEGE_FAILED;
	}
 
	tkp.PrivilegeCount = 1;

	tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED; 
 
	AdjustTokenPrivileges(hToken, FALSE, &tkp, 0,(PTOKEN_PRIVILEGES)NULL, 0); 
 
	if (GetLastError() != ERROR_SUCCESS) 
	{
			return ADJUST_TOCKEN_FAILED;
	}
	

	return ADJUST_TOCKEN_SUCESS;
}


/* ExitWindowsExt() is our actual shutdown code - it's called via our Module functions below */
int ExitWindowsExt(UINT nFlag, DWORD dwType) {
	int iRetval=0;

	switch(WinVer())
	{
	case WINNT:
		{
			if((iRetval=AdjustProcessTokenPrivilege())==ADJUST_TOCKEN_SUCESS)
			{
				return ExitWindowsEx(nFlag,dwType);
			}
			else
			{
				return iRetval;
			}
			break;
		}
	case WIN9X:
		{
			return ExitWindowsEx(nFlag,dwType);
			break;
		}
	}
	return FALSE;
}


MODULE = Win32::ShutDown		PACKAGE = Win32::ShutDown		

##############################################################################################	

=head1 NAME

Win32::ShutDown - a perl extension to let you shutdown and/or restart and/or logoff a Windows PC

=head1 DESCRIPTION

This lets you shut down, restart, or log off (forcefully or normally) from Windows 95, 98, Me, NT4, 2000, and/or XP.

=cut





##############################################################################################	

=head2 ShutDown()

Will shutdown the Machine, after prompting to save

return values will be FALSE in many cases. 
	1.if AdjustProcessTokenPrivilege() failed.
	2.ShutDown failed.

=cut

int ShutDown()
    CODE:
        RETVAL = ExitWindowsExt(EWX_SHUTDOWN,0);
    OUTPUT:
        RETVAL



##############################################################################################	

=head2 Restart()	

Will restart the machine after prompting to save

return values will be FALSE in many cases. 
	1.if AdjustProcessTokenPrivilege() failed.
	2.restart failed.

=cut

int Restart()
    CODE:
        RETVAL = ExitWindowsExt(EWX_REBOOT,0);
    OUTPUT:
        RETVAL



##############################################################################################	

=head2 LogOff()

Will logoff the machine after prompting to save

return values will be FALSE upon failure.

=cut

int LogOff()
    CODE:
        RETVAL = ExitWindows(EWX_LOGOFF,0);
    OUTPUT:
        RETVAL



##############################################################################################	

=head2 SetItAsLastShutDownProcess()

Using to set the Application to reserve last shutdown 
range. This is possible only in NT.

return values will be FALSE if setting  failed.. 

=cut

int SetItAsLastShutDownProcess()
    CODE:
	RETVAL=TRUE;
	if(!SetProcessShutdownParameters(0x100,0)) RETVAL=FALSE;
    OUTPUT:
        RETVAL




##############################################################################################	

=head2 ForceReStart()	

Will restart the Machine forcefully without allowing save

return values will be FALSE in many cases. 
	1.if AdjustProcessTokenPrivilege() failed.
	2.Restart failed.

=cut

int ForceReStart()
    CODE:
        RETVAL = ExitWindowsExt(EWX_REBOOT|EWX_FORCE,0);
    OUTPUT:
        RETVAL



##############################################################################################	

=head2 ForceLogOff(), ForceShutDown()

Will forcefully logoff current user / shut down without allowing a save. 

return values will be FALSE in many cases. 
	1.Logoff failed.

=cut

int ForceLogOff()
    CODE:
        RETVAL = ExitWindowsEx(EWX_LOGOFF|EWX_FORCE,0);
    OUTPUT:
        RETVAL


int ForceShutDown()
    CODE:
        RETVAL = ExitWindowsExt(EWX_SHUTDOWN|EWX_FORCE,0);
    OUTPUT:
        RETVAL


##############################################################################################	


