#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <windows.h>
#include <tlhelp32.h>


int debug=0;

char *ToLower(char *string)
{
      char *s;

      if (string)
      {
            for (s = string; *s; ++s)
                  *s = tolower(*s);
      }
      return string;
}

void printError(char* msg, DWORD *err )
{
*err = GetLastError();
FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM |
	FORMAT_MESSAGE_IGNORE_INSERTS,
	NULL,
        *err,
        0,
        msg,
        512,
        NULL );

}

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

MODULE = Win32::Process::List		PACKAGE = Win32::Process::List		


void
Setdebug(deb)
	int deb
	PPCODE:
		debug=deb;

int
ProcessAliveP(pid,perror)
	int pid
	SV* perror
	PREINIT:
		HANDLE hProcessSnap;
		PROCESSENTRY32 pe32;
		//DWORD dwPriorityClass;
    		DWORD err;
		char   wszMsgBuff[512];
	CODE:
	{
	        SetLastError(0);
	        RETVAL=0;
    		hProcessSnap = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
    		if( hProcessSnap == INVALID_HANDLE_VALUE )
		{
			printError(wszMsgBuff, &err );
			sv_upgrade(perror,SVt_PVIV);
			sv_setpvn(perror, (char*)wszMsgBuff, strlen(wszMsgBuff));
			sv_setiv(perror,(IV) err);
			SvPOK_on(perror);
			XPUSHs(sv_2mortal(newSViv(-1)));
			RETVAL=-1;
		}
		pe32.dwSize = sizeof( PROCESSENTRY32 );
		if( !Process32First( hProcessSnap, &pe32 ) )
		{
			printError(wszMsgBuff,&err );
			sv_upgrade(perror,SVt_PVIV);
			sv_setpvn(perror, (char*)wszMsgBuff, strlen(wszMsgBuff));
			sv_setiv(perror,(IV) err);
			SvPOK_on(perror);
			XPUSHs(sv_2mortal(newSViv(-1)));
			CloseHandle( hProcessSnap );
			RETVAL=-1;
		}
		do
		{
			  	//sprintf(temp, "%d", pe32.th32ProcessID);
			  	if(debug==1) {
			  		printf("Temp: %s\n",pe32.szExeFile);
			  	}
			  	//printf("%s\n", ToLower(pe32.szExeFile));
			  	if(pid ==  pe32.th32ProcessID) { RETVAL=1; }
		} while( Process32Next( hProcessSnap, &pe32 ) );
		CloseHandle( hProcessSnap );
		
	}
	OUTPUT:
		RETVAL
		perror

int
ProcessAliveN(name,perror)
	char *name
	SV* perror
	PREINIT:
		HANDLE hProcessSnap;
		PROCESSENTRY32 pe32;
		//DWORD dwPriorityClass;
    		DWORD err;
		char   wszMsgBuff[512];
	CODE:
	{
	        SetLastError(0);
	        RETVAL=0;
    		hProcessSnap = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
    		if( hProcessSnap == INVALID_HANDLE_VALUE )
		{
			printError(wszMsgBuff, &err );
			sv_upgrade(perror,SVt_PVIV);
			sv_setpvn(perror, (char*)wszMsgBuff, strlen(wszMsgBuff));
			sv_setiv(perror,(IV) err);
			SvPOK_on(perror);
			XPUSHs(sv_2mortal(newSViv(-1)));
			RETVAL=-1;
		}
		pe32.dwSize = sizeof( PROCESSENTRY32 );
		if( !Process32First( hProcessSnap, &pe32 ) )
		{
			printError(wszMsgBuff,&err );
			sv_upgrade(perror,SVt_PVIV);
			sv_setpvn(perror, (char*)wszMsgBuff, strlen(wszMsgBuff));
			sv_setiv(perror,(IV) err);
			SvPOK_on(perror);
			XPUSHs(sv_2mortal(newSViv(-1)));
			CloseHandle( hProcessSnap );
			RETVAL=-1;
		}
		do
		{
			  	//sprintf(temp, "%d", pe32.th32ProcessID);
			  	if(debug==1) {
			  		printf("Temp: %s\n",pe32.szExeFile);
			  	}
			  	//printf("%s\n", ToLower(pe32.szExeFile));
			  	if(strEQ(ToLower(name), ToLower(pe32.szExeFile))) { RETVAL=1; }
		} while( Process32Next( hProcessSnap, &pe32 ) );
		CloseHandle( hProcessSnap );
		
	}
	OUTPUT:
		RETVAL
		perror


SV * 
ListProcesses(perror)
	SV* perror
	PREINIT:
		HANDLE hProcessSnap;
		PROCESSENTRY32 pe32;
		//DWORD dwPriorityClass;
    		DWORD err;
		HV * rh;
		char   wszMsgBuff[512];
		char   temp[512];
    CODE:
        SetLastError(0);
    	rh = newHV();
    	hProcessSnap = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
    	if( hProcessSnap == INVALID_HANDLE_VALUE )
	{
		printError(wszMsgBuff, &err );
		sv_upgrade(perror,SVt_PVIV);
		sv_setpvn(perror, (char*)wszMsgBuff, strlen(wszMsgBuff));
		sv_setiv(perror,(IV) err);
		SvPOK_on(perror);
		XPUSHs(sv_2mortal(newSViv(-1)));
	} else
	{
		pe32.dwSize = sizeof( PROCESSENTRY32 );
		if( !Process32First( hProcessSnap, &pe32 ) )
		{
			printError(wszMsgBuff,&err );
			sv_upgrade(perror,SVt_PVIV);
			sv_setpvn(perror, (char*)wszMsgBuff, strlen(wszMsgBuff));
			sv_setiv(perror,(IV) err);
			SvPOK_on(perror);
			XPUSHs(sv_2mortal(newSViv(-1)));
			CloseHandle( hProcessSnap );
		} else
		{
			  do
			  {
			  	sprintf(temp, "%d", pe32.th32ProcessID);
			  	if(debug==1) {
			  		printf("Temp: %s\n",pe32.szExeFile);
			  	}
			  	
			  	if(hv_store(rh,temp,strlen(temp),newSVpv(pe32.szExeFile, strlen(pe32.szExeFile)), 0)==NULL)
			  	//if(hv_store(rh,pe32.szExeFile,strlen(pe32.szExeFile),newSVuv(pe32.th32ProcessID), 0)==NULL)
			  	{
			  		printf("can not store %s in hash!\n", pe32.szExeFile);
			  		
			  	}
			  } while( Process32Next( hProcessSnap, &pe32 ) );
			CloseHandle( hProcessSnap );
		}
		

	}
	
    	RETVAL = newRV_noinc((SV *)rh);
	OUTPUT:
		RETVAL
		perror
	

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

