#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0500
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Windows.h"
#include <tchar.h>
#include "Sddl.h"

#define INITIAL_SIZE 512


static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

void CleanUp(HANDLE hprocess, HANDLE hdlToken)
{
	if(hprocess)
		CloseHandle(hprocess);
	if(hdlToken)
		CloseHandle(hdlToken);
}


BOOL ConvertSid(PSID pSid, LPTSTR szUser, LPTSTR szDomain, LPTSTR szError)
   {

      SID_NAME_USE snu;
      DWORD cchUser = INITIAL_SIZE-1;
      
 
      //
      // test if SID passed in is valid
      //
      if(!IsValidSid(pSid)) return FALSE;
      if(LookupAccountSid(NULL, pSid, szUser, &cchUser, szDomain, &cchUser, &snu)==0)
      {
		FormatMessage( 
    		FORMAT_MESSAGE_ALLOCATE_BUFFER | 
    		FORMAT_MESSAGE_FROM_SYSTEM | 
    		FORMAT_MESSAGE_IGNORE_INSERTS,
    		NULL,
    		GetLastError(),
    		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    		szError,
    		0,
    		NULL );
      	return FALSE;
      }
      return TRUE;

   }


MODULE = Win32::Process::User		PACKAGE = Win32::Process::User


SV*
_GetUserByPid(sv_PID,domain,pError)
	SV* sv_PID
	char *domain
	SV* pError
	PREINIT:
		DWORD PPID;
		TOKEN_USER* pUserInfo;
		TCHAR       szUser[INITIAL_SIZE];
		TCHAR       szDomain[INITIAL_SIZE];
		TCHAR	    szError[INITIAL_SIZE];
		TCHAR 	    temp[INITIAL_SIZE];
		LPVOID 	    lpMsgBuf;
		HANDLE hprocess=0;
		HANDLE hdlToken=0;
		DWORD cbBuffer=0;
		DWORD cbRequired;
		HV* info;
	CODE:
	{
		
		info=newHV();
		pUserInfo=NULL;
		ZeroMemory(szUser, (sizeof(szUser)/sizeof(TCHAR)));
		ZeroMemory(szError, (sizeof(szError)/sizeof(TCHAR)));
		ZeroMemory(szDomain, (sizeof(szError)/sizeof(TCHAR)));
		PPID = (DWORD)SvIV(sv_PID);
		hprocess = OpenProcess(PROCESS_QUERY_INFORMATION , FALSE, PPID);
		if(hprocess != NULL)
		{
			if(OpenProcessToken(hprocess,TOKEN_READ | TOKEN_QUERY, &hdlToken)!=0)
			{
				cbBuffer = 0;
				if(!GetTokenInformation(hdlToken,TokenUser,NULL,cbBuffer,&cbRequired)) {
					if (GetLastError() == ERROR_INSUFFICIENT_BUFFER){
            					pUserInfo = (TOKEN_USER *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, cbRequired);
            					if (pUserInfo == NULL)
            					{
            						wsprintf(temp, "Can not allocate memory to pUserInfo");
            						sv_setpv(pError, temp);
               						RETVAL=newRV(newSViv(-1));
               					}
						cbBuffer = cbRequired;
						cbRequired = 0;
						if(!GetTokenInformation(hdlToken,TokenUser,(LPVOID)pUserInfo,cbBuffer,&cbRequired))
						{
							FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(LPTSTR) &lpMsgBuf,0,NULL );
							wsprintf(temp, "GetTokenInformation() failed: %s", (LPTSTR)lpMsgBuf);
							sv_setpv(pError, temp);
							RETVAL=newRV(newSViv(-1));
						}
						// Get the username for the Process
						if(!ConvertSid((pUserInfo->User).Sid, szUser,szDomain, szError))
						{
							CleanUp(hprocess,hdlToken);
							sv_setpv(pError, szError);
							RETVAL=newRV(newSViv(-1));
						}
					} else
					{
						
						FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(LPTSTR) &lpMsgBuf,0,NULL );
						CleanUp(hprocess,hdlToken);
						wsprintf(temp, "GetLastError returns: %s", (LPTSTR)lpMsgBuf);
						sv_setpv(pError, temp);
						RETVAL=newRV(newSViv(-1));
					}
				} else {
					CleanUp(hprocess,hdlToken);
					sv_setpv(pError, "GetTokenInformation(): unknown error.");
					RETVAL=newRV(newSViv(-1));
				}
				
			} else {
				FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR) &lpMsgBuf,0,NULL );
				CleanUp(hprocess,hdlToken);
				//printf("GetLastError returns: %s\n", (LPCTSTR)lpMsgBuf);
				wsprintf(temp, "ProcessToken could not be opened: %s", (LPTSTR)lpMsgBuf);
				sv_setpv(pError, temp);
				RETVAL=newRV(newSViv(-1));
			}
		} else {
			FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(LPTSTR) &lpMsgBuf,0,NULL );
			CleanUp(hprocess,hdlToken);
			//printf("GetLastError returns: %s\n", (LPCTSTR)lpMsgBuf);
			wsprintf(temp, "Process could not be opened: %s", (LPTSTR)lpMsgBuf);
			sv_setpv(pError, temp);
			RETVAL=newRV(newSViv(-1));
		}
		if (!HeapFree(GetProcessHeap(), 0, (LPVOID)pUserInfo))
		{
         		sv_setpv(pError, "HeapFree() failed.");
			RETVAL=newRV(newSViv(-1));
         	} else {
			CleanUp(hprocess,hdlToken);
			hv_store(info,"Name", strlen("Name"),newSVpv(szUser,0), 0);
			hv_store(info,"Domain", strlen("Domain"),newSVpv(szDomain,0), 0);
			RETVAL = newRV_noinc((SV*) info);
		}
	}	// End CODE
	OUTPUT:
	RETVAL
	pError

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

