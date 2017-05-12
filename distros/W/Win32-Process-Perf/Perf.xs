// PerfMon.xs
//       +==========================================================+
//       |                                                          |
//       |                        PerfMon.xs                        |
//       |                     ---------------                      |
//       |                                                          |
//       | Copyright (c) 2004 Glen Small. All rights reserved. 	    |
//       |   This program is free software; you can redistribute    |
//       | it and/or modify it under the same terms as Perl itself. |
//       |                                                          |
//       +==========================================================+
//
//
//	Use under GNU General Public License or Larry Wall's "Artistic License"
//
//Check the README.TXT file that comes with this package for details about
//	it's history.
//
// Changes made by Reinhard Pagitsch Copyright (c) August 2004:
// Function: add_counter() to can use process name.
// 
// Changes made by Reinhard Pagitsch Copyright (c) September 2004:
// Added: 
// Function CPU_Time()
// 


#define WIN32_LEAN_AND_MEAN

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "windows.h"
#include "PDH.h"
#include "PDHMSG.h"
#include "perf.h"
#include <stdio.h>
#include <tchar.h>
#include <Sddl.h>

#define INITIAL_SIZE 512


PDH_STATUS PPdhEnumObjects(LPCTSTR szMachineName, LPTSTR mszObjectList)
{
	DWORD pcchBufferLength=10000;
	PDH_STATUS stat = PdhEnumObjectsH(H_REALTIME_DATASOURCE,szMachineName,mszObjectList,&pcchBufferLength,PERF_DETAIL_WIZARD, TRUE);
	printf("The Len: %d %s %s\n",pcchBufferLength, szMachineName,mszObjectList);
	if(stat != ERROR_SUCCESS)
		return stat;
	return pcchBufferLength;

}

void CleanUp(HANDLE hprocess, HANDLE hdlToken)
{
	if(hprocess)
		CloseHandle(hprocess);
	if(hdlToken)
		CloseHandle(hdlToken);
}

BOOL ConvertSid(PSID pSid, LPTSTR szUser, LPTSTR szError)
   {

      DWORD cchUser = INITIAL_SIZE;
      TCHAR szDomain[INITIAL_SIZE];
      DWORD cchDomain = INITIAL_SIZE;
      SID_NAME_USE snu;
      ZeroMemory(szDomain, (sizeof(szDomain)/sizeof(TCHAR)));

      //
      // test if SID passed in is valid
      //
      if(!IsValidSid(pSid)) return FALSE;
      if(LookupAccountSid(NULL, pSid, szUser, &cchUser, szDomain, &cchDomain, &snu)==0)
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

/* int GetLanguageInfo(LPSTR *lpLCData, int length, LCID Locale)
{
	LCTYPE LCType=LOCALE_NOUSEROVERRIDE |LOCALE_USE_CP_ACP;
	return GetLocaleInfo(
  Locale,      // locale identifier
  LCTYPE LCType,    // information type
  lpLCData,  // information buffer
  length       // size of buffer
);
} */

MODULE = Win32::Process::Perf		PACKAGE = Win32::Process::Perf



void
open_query()

	PREINIT:

		PDH_STATUS stat;
		HQUERY	hQwy;

	PPCODE:

		stat = PdhOpenQuery(NULL, 0, &hQwy);


		if(stat != ERROR_SUCCESS)
		{
			XPUSHs(sv_2mortal(newSViv(-1)));
		}
		else
		{
			XPUSHs(sv_2mortal(newSViv((long)hQwy)));
		}




void
CleanUp(objQuery)
	SV* objQuery

	PREINIT:
		PDH_STATUS stat;
		HQUERY	pObj;
	PPCODE:

		pObj = (HQUERY)SvIV(objQuery);
		stat = PdhCloseQuery(pObj);


void
add_counter(PName, ObjectName, CounterName, machine, pQwy, pError)
	SV* PName
	SV* ObjectName
	SV* CounterName
	SV* machine
	SV* pQwy
	SV* pError

	PREINIT:

		DWORD dwSize;
		DWORD dwGlen;
		HCOUNTER cnt;
		HQUERY hQwy;
		char str[512];
		PDH_STATUS	stat;
		STRLEN len1;
		STRLEN len2;
		STRLEN len3;
		STRLEN len4;

	PPCODE:

		hQwy = (HQUERY)SvIV(pQwy);

		dwGlen = 0;
		dwSize = 256;

		len1 = sv_len(ObjectName);
		len2 = sv_len(CounterName);
		len3 = sv_len(PName);
		len4 = sv_len(machine);
		if(!SvPOK(ObjectName))
		{
			croak("No process given");
		}
		if(!SvPOK(CounterName))
		{
			croak("No counter given");
		}
		
		sprintf(str,"\\\\%s\\%s(%s)\\%s", SvPV(machine,len4),SvPV(PName,len3), SvPV(ObjectName,len1),SvPV(CounterName,len2));
		//printf("%s\n", str);
		stat = PdhAddCounter(hQwy, (LPTSTR)str, dwGlen, &cnt);
			switch(stat)
			{
				case ERROR_SUCCESS:

					XPUSHs(sv_2mortal(newSViv((long)cnt)));
					break;

				case PDH_CSTATUS_BAD_COUNTERNAME:

					sv_setpv(pError, "The counter name path string could not be parsed or interpreted.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_COUNTER:

					sv_setpv(pError, "The specified counter was not found.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_COUNTERNAME:

					sv_setpv(pError, "An empty counter name path string was passed in.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_MACHINE:

					sv_setpv(pError, "A computer entry could not be created.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_OBJECT:

					sv_setpv(pError, "The specified object could not be found.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_FUNCTION_NOT_FOUND:

					sv_setpv(pError, "The calculation function for this counter could not be determined.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_INVALID_ARGUMENT:

					sv_setpv(pError, "One or more arguments are invalid.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_INVALID_HANDLE:

					sv_setpv(pError, "The query handle is not valid.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_MEMORY_ALLOCATION_FAILURE:

					sv_setpv(pError, "A memory buffer could not be allocated.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				default:

					sv_setpv(pError, "Failed to add the counter - don't know why");
					XPUSHs(sv_2mortal(newSViv(-1)));
		}
		





void
collect_data(pQwy, pError)
	SV* pQwy
	SV* pError

	PREINIT:
		HQUERY hQwy;
		PDH_STATUS stat;
	PPCODE:
		hQwy = (HQUERY)SvIV(pQwy);
		stat = PdhCollectQueryData(hQwy);

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSViv(0)));
				break;

			case PDH_INVALID_HANDLE:

				sv_setpv(pError, "The query handle is not valid.");
				XPUSHs(sv_2mortal(newSViv(-1)));
				break;

			case PDH_NO_DATA:

				sv_setpv(pError, "The query does not currently have any counters.");
				XPUSHs(sv_2mortal(newSViv(-1)));
				break;

			default:

				sv_setpv(pError, "Collect Data Failed - I don't know why");
				XPUSHs(sv_2mortal(newSViv(-1)));
				break;

		}

void
collect_counter_value(pQwy, pCounter, pError)
	SV* pQwy
	SV* pCounter
	SV* pError

	PREINIT:

		HQUERY hQwy;
		HCOUNTER hCnt;
		PDH_STATUS stat;
		PDH_FMT_COUNTERVALUE val;
		DWORD dwType;

	PPCODE:

		hQwy = (HQUERY)SvIV(pQwy);
		hCnt = (HCOUNTER)SvIV(pCounter);

		stat = PdhGetFormattedCounterValue(hCnt, PDH_FMT_LONG | PDH_FMT_NOSCALE , &dwType, &val);
		

		switch(stat)
		{
			case ERROR_SUCCESS:
				if(val.CStatus == PDH_CSTATUS_VALID_DATA)
					XPUSHs(sv_2mortal(newSViv(val.longValue)));
				else {
					sv_setpv(pError, "PDH_Cstatus is not PDH_CSTATUS_VALID_DATA.");
					XPUSHs(sv_2mortal(newSViv(-1)));
				}

				break;

			case PDH_INVALID_ARGUMENT:

				sv_setpv(pError, "An argument is not correct or is incorrectly formatted.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_DATA:

				sv_setpv(pError, "The specified counter does not contain valid data or a successful status code.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_HANDLE:

				sv_setpv(pError, "The counter handle is not valid.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "Failed to get the counter value - I don't know why.");
				XPUSHs(sv_2mortal(newSViv(-1)));

		}


void
list_objects(pBox, pError)
	SV*	pBox
	SV* pError

	PREINIT:

		DWORD dwSize;
		PDH_STATUS stat;
		char* szBuffer;
		char* szBox;
		STRLEN len;

	PPCODE:

		len = sv_len(pBox);
		szBox = SvPV(pBox, len);

		stat = PdhEnumObjects(NULL, szBox, NULL, &dwSize, PERF_DETAIL_EXPERT, 0);

		Newz(0, szBuffer, (int)dwSize, char);

		stat = PdhEnumObjects(NULL, szBox, szBuffer, &dwSize, PERF_DETAIL_EXPERT, 0);

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSVpv(szBuffer, 0)));

				break;

			case PDH_MORE_DATA:

				printf("There are more entries available to return than there is room in the buffer\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INSUFFICIENT_BUFFER:

				sv_setpv(pError, "The buffer provided is not large enough to contain any data.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_INVALID_ARGUMENT:

				sv_setpv(pError, "A required argument is invalid or a reserved argument is not NULL.\n");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "I have no idea what went wrong\n");
				XPUSHs(sv_2mortal(newSViv(-1)));
		}

		Safefree(szBuffer);

void
connect_to_box(pBox, pError)
	SV* pBox
	SV* pError

	PREINIT:

		PDH_STATUS stat;
		char* szBox;
		STRLEN len;

	PPCODE:

		len = sv_len(pBox);
		szBox = SvPV(pBox, len);

		stat = PdhConnectMachine(szBox);

		switch(stat)
		{
			case ERROR_SUCCESS:

				XPUSHs(sv_2mortal(newSViv(0)));

				break;

			case PDH_CSTATUS_NO_MACHINE:

				sv_setpv(pError, "Unable to connect to the specified machine");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			case PDH_MEMORY_ALLOCATION_FAILURE:

				sv_setpv(pError, "Unable to allocate a dynamic memory block due to too many applications running on the system or an insufficient memory paging file.");
				XPUSHs(sv_2mortal(newSViv(-1)));

				break;

			default:

				sv_setpv(pError, "ERROR: Don't really know what happened though !");
				XPUSHs(sv_2mortal(newSViv(-1)));
		}

void 
explain_counter(pObject, pCounter, pInstance, pQwy, pError)
	SV* pObject
	SV* pCounter
	SV* pInstance
	SV* pQwy
	SV* pError

	PREINIT:

		PDH_COUNTER_PATH_ELEMENTS	GStruct;
		PDH_COUNTER_INFO* cntInfo;
		DWORD dwSize;
		DWORD dwSize1;
		DWORD dwGlen;
		HCOUNTER cnt;
		HQUERY hQwy;
		char str[256];
		PDH_STATUS	stat;
		STRLEN len1;
		STRLEN len2;
		STRLEN len3;

	PPCODE:

		hQwy = (HQUERY)SvIV(pQwy);

		dwGlen = 1;
		dwSize = 256;
		cntInfo = NULL;

		len1 = sv_len(pObject);
		len2 = sv_len(pCounter);

		if(SvNIOK(pInstance))
		{
			GStruct.szInstanceName = NULL;
		}
		else
		{
			len3 = sv_len(pInstance);
			GStruct.szInstanceName = SvPV(pInstance, len3);
		}

		GStruct.szObjectName = SvPV(pObject, len1);
		GStruct.szCounterName = SvPV(pCounter, len2);
		GStruct.szMachineName = NULL;
		GStruct.szParentInstance = NULL;
		GStruct.dwInstanceIndex = 0;

		stat = PdhMakeCounterPath(&GStruct, (char*)str, &dwSize, NULL);

		if(stat != ERROR_SUCCESS)
		{
			sv_setpv(pError, "Path to that counter isn't valid");
			XPUSHs(sv_2mortal(newSViv(-1)));
		}
		else
		{
			switch(stat)
			{
				case ERROR_SUCCESS:

					stat = PdhGetCounterInfo(&cnt, 1, &dwSize1, cntInfo);

					New(0, cntInfo, (int)dwSize1, PDH_COUNTER_INFO);

					stat = PdhGetCounterInfo(&cnt, 1, &dwSize1, cntInfo);

					if(stat ==  ERROR_SUCCESS)
					{
						XPUSHs(sv_2mortal(newSVpv(cntInfo->szExplainText, 0)));

						Safefree(cntInfo);
					}
					else
					{
						sv_setpv(pError, "Failed to get the explain text for this counter");
						XPUSHs(sv_2mortal(newSViv(-1)));
					}

					break;

				case PDH_CSTATUS_BAD_COUNTERNAME:

					sv_setpv(pError, "The counter name path string could not be parsed or interpreted.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_COUNTER:

					sv_setpv(pError, "The specified counter was not found.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_COUNTERNAME:

					sv_setpv(pError, "An empty counter name path string was passed in.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_MACHINE:

					sv_setpv(pError, "A computer entry could not be created.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_CSTATUS_NO_OBJECT:

					sv_setpv(pError, "The specified object could not be found.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_FUNCTION_NOT_FOUND:

					sv_setpv(pError, "The calculation function for this counter could not be determined.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_INVALID_ARGUMENT:

					sv_setpv(pError, "One or more arguments are invalid.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_INVALID_HANDLE:

					sv_setpv(pError, "The query handle is not valid.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				case PDH_MEMORY_ALLOCATION_FAILURE:

					sv_setpv(pError, "A memory buffer could not be allocated.");
					XPUSHs(sv_2mortal(newSViv(-1)));

					break;

				default:

					sv_setpv(pError, "Failed to add the counter - don't know why");
					XPUSHs(sv_2mortal(newSViv(-1)));
			}
		}


void
GetProcessUser(sv_PID,pError)
	SV* sv_PID
	SV* pError

	PREINIT:
		HANDLE hprocess = 0;
		HANDLE hdlToken = 0;
		DWORD PPID;
		DWORD cbBuffer;
		DWORD cbRequired;
		TOKEN_USER* pUserInfo = NULL;
		TCHAR       szUser[INITIAL_SIZE];
		TCHAR	    szError[INITIAL_SIZE];
		TCHAR 	    temp[INITIAL_SIZE];
		LPVOID lpMsgBuf;
	PPCODE:
	{
		ZeroMemory(szUser, (sizeof(szUser)/sizeof(TCHAR)));
		ZeroMemory(szError, (sizeof(szError)/sizeof(TCHAR)));
		PPID = (DWORD)SvIV(sv_PID);
		hprocess = OpenProcess(PROCESS_QUERY_INFORMATION, 1, PPID);
		if(hprocess != NULL)
		{
			if(OpenProcessToken(hprocess,TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hdlToken)!=0)
			{
				cbBuffer = 0;
				if(!GetTokenInformation(hdlToken,TokenUser,NULL,cbBuffer,&cbRequired)) {
					if (GetLastError() == ERROR_INSUFFICIENT_BUFFER){
            					pUserInfo = (TOKEN_USER *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, cbRequired);
            					if (pUserInfo == NULL)
            					{
            						wsprintf(temp, "Can not allocate memory to pUserInfo");
            						sv_setpv(pError, temp);
               						XSRETURN(-1);
               					}
						cbBuffer = cbRequired;
						cbRequired = 0;
						if(!GetTokenInformation(hdlToken,TokenUser,(LPVOID)pUserInfo,cbBuffer,&cbRequired))
						{
							FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(LPTSTR) &lpMsgBuf,0,NULL );
							wsprintf(temp, "GetTokenInformation() failed: %s", (LPTSTR)lpMsgBuf);
							sv_setpv(pError, temp);
							XSRETURN(-1);
						}
						// Get the username for the Process
						if(!ConvertSid((pUserInfo->User).Sid, szUser, szError))
						{
							CleanUp(hprocess,hdlToken);
							sv_setpv(pError, szError);
							XSRETURN(-1);
						}
					} else
					{
						
						FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(LPTSTR) &lpMsgBuf,0,NULL );
						CleanUp(hprocess,hdlToken);
						wsprintf(temp, "GetLastError returns: %s", (LPTSTR)lpMsgBuf);
						sv_setpv(pError, temp);
						XSRETURN(-1);
					}
				} else {
					CleanUp(hprocess,hdlToken);
					sv_setpv(pError, "GetTokenInformation(): unknown error.");
					XSRETURN(-1);
				}
				
			} else {
				FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR) &lpMsgBuf,0,NULL );
				CleanUp(hprocess,hdlToken);
				//printf("GetLastError returns: %s\n", (LPCTSTR)lpMsgBuf);
				wsprintf(temp, "ProcessToken could not be opened: %s", (LPTSTR)lpMsgBuf);
				sv_setpv(pError, temp);
				XPUSHs(sv_2mortal(newSViv(-1)));
			}
		} else {
			FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(LPTSTR) &lpMsgBuf,0,NULL );
			CleanUp(hprocess,hdlToken);
			//printf("GetLastError returns: %s\n", (LPCTSTR)lpMsgBuf);
			wsprintf(temp, "Process could not be opened: %s", (LPTSTR)lpMsgBuf);
			sv_setpv(pError, temp);
			XPUSHs(sv_2mortal(newSViv(-1)));
		}
		if (!HeapFree(GetProcessHeap(), 0, (LPVOID)pUserInfo))
		{
         		sv_setpv(pError, "HeapFree() failed.");
			XSRETURN(-1);
         	}
		CleanUp(hprocess,hdlToken);
		XPUSHs(sv_2mortal(newSVpv((char *)szUser, strlen(szUser))));
	}	// End PPCODE


void
OSIsSupported(pError)
		SV* pError
	PREINIT:
		OSVERSIONINFOEX osvi;
		BOOL bOsVersionInfoEx;
		int supported;
	PPCODE:
	{
		supported=-1;
		ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));
   		osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
		if( !(bOsVersionInfoEx = GetVersionEx ((OSVERSIONINFO *) &osvi)) )
   		{
      			osvi.dwOSVersionInfoSize = sizeof (OSVERSIONINFO);
			if (! GetVersionEx ( (OSVERSIONINFO *) &osvi) ) 
			{
				sv_setpv(pError, "Can not get OS Version!");
				XSRETURN(-1);
			}
   		}
   		switch (osvi.dwPlatformId)
		{
			case VER_PLATFORM_WIN32_NT:
				if((osvi.dwMajorVersion == 5 && osvi.dwMinorVersion == 2) ||  (osvi.dwMajorVersion == 5 && osvi.dwMinorVersion == 1 ) || ( osvi.dwMajorVersion == 5 && osvi.dwMinorVersion == 0 ) || (osvi.dwMajorVersion == 4 && osvi.dwMinorVersion == 0))
					supported = 1;
				break;
			
			default:
				supported = -1;
				sv_setpv(pError, "OS not supported.");
				break;
		}
		XPUSHs(sv_2mortal(newSViv(supported)));
   	}

void
CPU_Time(sv_PID,pError)
		SV* sv_PID
		SV* pError
	PREINIT:
		HANDLE hprocess;
		FILETIME CreationTime;
		FILETIME ExitTime;
		FILETIME KernelTime;
		FILETIME UserTime;
		SYSTEMTIME SystemTime;
		int retcode;
		//long min;
		//long hour;
		//long sec;
		long seconds = 0;
		int err=0;
		//char   wszMsgBuff[512];
		DWORD PID; 
	PPCODE:
			PID = (DWORD)SvIV(sv_PID);
			SetLastError(0);
			if((hprocess = OpenProcess(PROCESS_QUERY_INFORMATION, 0, PID)) != NULL)
			{
				retcode = GetProcessTimes(hprocess,&CreationTime,&ExitTime,&KernelTime,&UserTime);
				if(retcode) {
					retcode = FileTimeToSystemTime(&KernelTime, &SystemTime);
					seconds = (long)SystemTime.wSecond + ((long)SystemTime.wMinute*60) + ((long)SystemTime.wHour*3600);	//Cpu time?
					retcode = FileTimeToSystemTime(&UserTime, &SystemTime);
					seconds = seconds + ((long)SystemTime.wSecond + ((long)SystemTime.wMinute*60) + ((long)SystemTime.wHour*3600));
					CloseHandle(hprocess);
					XPUSHs(sv_2mortal(newSViv(seconds)));
				} else {
					sv_setpv(pError, "Process coud not be opened.");
					XPUSHs(sv_2mortal(newSViv(-1)));
				}
			} else {
				err = GetLastError();
				sv_setpv(pError, "Process coud not be opened.");
				XPUSHs(sv_2mortal(newSViv(-1)));
			}
			

void
_GetLanguage(Locale)
		int Locale
	PREINIT:
	//TCHAR data[60];
	LANGID SID;
	LANGID UID;
	LANGID LID;
	LCID ID;
	PPCODE:
	{
		SID = GetSystemDefaultLangID();
		UID = GetUserDefaultLangID();
		ID=GetUserDefaultLCID();
		//printf("GetUserDefaultLCID: %X GetSystemDefaultLCID: %X\n", ID, GetSystemDefaultLCID());
		
		if(SID != UID)
			LID = SID;
		else
			LID = UID;
		//printf("The LangID: %X SID: %X UID %X\n", LID, SID, UID);
		//XPUSHs(sv_2mortal(newSVpv((char *)data, strlen(data))));
		XPUSHs(sv_2mortal(newSViv(LID)));
	}


void
_PdhEnumObjects(szMachineName, mszObjectList)
		SV* szMachineName
		SV* mszObjectList
	PREINIT:
		char *machine;
		char objectList[10000];
		STRLEN len1;
		//STRLEN len2;
		PDH_STATUS ret=0;
	PPCODE:
	{
		len1 = sv_len(szMachineName);
		machine=SvPV(szMachineName,len1);
		printf("The machine: %s\n", machine);
		ret=PPdhEnumObjects(machine,(LPTSTR)objectList);
		printf("Return code: %d\n", ret);
	}