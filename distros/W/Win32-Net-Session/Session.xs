#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <windows.h> 
#include <stdio.h>
#include <stdlib.h>
#include "Lm.h"

#ifndef UNICODE
#define UNICODE
#endif

#define MAXLEN 256

char temp[5000];
char tmp[5000];

void 
ZeroString(void)
{
	ZeroMemory(temp,5000);
	ZeroMemory(tmp, 5000);
}

DWORD 
GetLevel(int level)
{
	switch(level)
	{
		case 0:
			return (DWORD)0;
		case 1:
			return (DWORD)1;
		case 2:
			return (DWORD)2;
		case 3:
			return (DWORD)10;
		case 4:
			return (DWORD)502;
		default:
		{
			croak("Wrong Level given! Exit now!\n");
			return 1000;
		}
	}
}
void GetUserFlag(char* t, DWORD flag)
{
	if(flag == SESS_GUEST)
		sprintf(t, "%s", "guest account");
	else if(flag == SESS_NOENCRYPTION)
		sprintf(t, "%s", "not using password encryption");
	else 
		sprintf(t, "%s", "not known");
}

void
store_hv(HV *hv, LPBYTE *buf, DWORD dwLevel)
{
	
	
	if(dwLevel == 0)
	{
		LPSESSION_INFO_0 pSi0 = (LPSESSION_INFO_0)buf;
		
		
		if(hv_store(hv, "EntryCount", strlen("EntryCount"),newSViv(1),0)==NULL)
			croak("Cant store in Hash (Count)\n");
		ZeroString();
		sprintf(temp, "%S", pSi0->sesi0_cname);
		//printf("The Client: %S\n", pSi0->sesi0_cname);
		strcpy(tmp, "ClientName");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
	}
	if(dwLevel == 1)
	{
		LPSESSION_INFO_1 pSi1 = (LPSESSION_INFO_1)buf;
		
		if(hv_store(hv, "EntryCount", strlen("EntryCount"),newSViv(6),0)==NULL)
			croak("Cant store in Hash (Count)\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi1->sesi1_cname);
		strcpy(tmp, "ClientName");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi1->sesi1_username);
		strcpy(tmp, "User");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%d", pSi1->sesi1_num_opens);
		strcpy(tmp, "Opened");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%d", pSi1->sesi1_time);
		strcpy(tmp, "Time");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		sprintf(temp, "%d", pSi1->sesi1_idle_time);
		strcpy(tmp, "IdleTime");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		GetUserFlag(temp, pSi1->sesi1_user_flags);

		strcpy(tmp, "UserFlags");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
	}
	if(dwLevel == 2)
	{
		LPSESSION_INFO_2 pSi2 = (LPSESSION_INFO_2)buf;
		
		if(hv_store(hv, "EntryCount", strlen("EntryCount"),newSViv(6),0)==NULL)
			croak("Cant store in Hash (Count)\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi2->sesi2_cname);
		strcpy(tmp, "ClientName");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi2->sesi2_username);
		strcpy(tmp, "User");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%d", pSi2->sesi2_num_opens);
		strcpy(tmp, "Opened");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%d", pSi2->sesi2_time);
		strcpy(tmp, "Time");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		sprintf(temp, "%d", pSi2->sesi2_idle_time);
		strcpy(tmp, "IdleTime");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		GetUserFlag(temp, pSi2->sesi2_user_flags);

		strcpy(tmp, "UserFlags");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		sprintf(temp, "%S", pSi2->sesi2_cltype_name);
		strcpy(tmp, "ClType Name");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash (ClType Name)\n");
		
	}
	if(dwLevel == 10)
	{
		LPSESSION_INFO_10 pSi10 = (LPSESSION_INFO_10)buf;
	
		if(hv_store(hv, "EntryCount", strlen("EntryCount"),newSViv(4),0)==NULL)
			croak("Cant store in Hash (Count)\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi10->sesi10_cname);
		strcpy(tmp, "ClientName");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi10->sesi10_username);
		strcpy(tmp, "User");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
	
		ZeroString();
		sprintf(temp, "%d", pSi10->sesi10_time);
		strcpy(tmp, "Time");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		sprintf(temp, "%d", pSi10->sesi10_idle_time);
		strcpy(tmp, "IdleTime");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
	}
	if(dwLevel == 502)
	{
		LPSESSION_INFO_502 pSi502 = (LPSESSION_INFO_502)buf;
		
		if(hv_store(hv, "EntryCount", strlen("EntryCount"),newSViv(8),0)==NULL)
			croak("Cant store in Hash (Count)\n");

		ZeroString();
		sprintf(temp, "%S", pSi502->sesi502_cname);
		strcpy(tmp, "ClientName");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%S", pSi502->sesi502_username);
		strcpy(tmp, "User");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%d", pSi502->sesi502_num_opens);
		strcpy(tmp, "Opened");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
		
		ZeroString();
		sprintf(temp, "%d", pSi502->sesi502_time);
		strcpy(tmp, "Time");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		sprintf(temp, "%d", pSi502->sesi502_idle_time);
		strcpy(tmp, "IdleTime");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		GetUserFlag(temp, pSi502->sesi502_user_flags);

		strcpy(tmp, "UserFlags");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");

		ZeroString();
		sprintf(temp, "%S", pSi502->sesi502_cltype_name);
		strcpy(tmp, "ClType Name");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash (ClType Name)\n");

		ZeroString();
		sprintf(temp, "%S", pSi502->sesi502_transport);
		strcpy(tmp, "TransportName");
		if(hv_store(hv, tmp ,(U32)strlen(tmp), newSVpv(temp,0), 0)==NULL)
			croak("Cant store in Hash\n");
	}
}

void
getError(NET_API_STATUS nStatus)
{
	switch(nStatus)
	{
		case NERR_InvalidComputer:
			croak("Invalid Computer\n");
			break;
		case NERR_Success:
			break;
		case ERROR_ACCESS_DENIED:
			croak("Access denied\n");
			break;
		case ERROR_INVALID_PARAMETER:
			croak("Invalid Parameter\n");
			break;
		case ERROR_NOT_ENOUGH_MEMORY:
			croak("Not enough Memory\n");
			break;
		case NERR_ClientNameNotFound:
			croak("Client Name not found\n");
			break;
		case NERR_UserNotFound:
			croak("User Not Found\n");
			break;
		case ERROR_INSUFFICIENT_BUFFER:
			croak("ERROR_INSUFFICIENT_BUFFER\n");
			break;
		case ERROR_INVALID_FLAGS:
			croak("ERROR_INVALID_FLAGS\n");
			break;
		case ERROR_NO_UNICODE_TRANSLATION:
			croak("NO_UNICODE_TRANSLATION\n");
			break;
		default:
			croak("unknown Error: %i\n", nStatus);
			break;
	}
}




MODULE = Win32::Net::Session		PACKAGE = Win32::Net::Session

SV* 
GetSessionInfos(servername, clientname, username, level, readed, perror)
		char* servername
		char* clientname
		char* username
		int level
		SV* readed
		SV* perror
	PREINIT:
		DWORD dwLevel;
		HV* ServerInfo;
		HV* Session;
		int size;
		int ret;
	CODE:
	{
		
		LPBYTE* bufptr = NULL;
		LPBYTE* pTmpBuf;
		//PARAM parm;
		DWORD i = 0;
		char   wszMsgBuff[512];
		NET_API_STATUS nStatus = 0;
		DWORD dwPrefMaxLen = MAX_PREFERRED_LENGTH;
	   	DWORD dwEntriesRead = 0;
   		DWORD dwTotalEntries = 0;
   		DWORD dwResumeHandle = 0;
   		DWORD dwTotalCount = 0;
		LPSESSION_INFO_0 pSi0 = NULL;
		LPSESSION_INFO_1 pSi1 = NULL;
		LPSESSION_INFO_2 pSi2 = NULL;
		LPSESSION_INFO_10 pSi10 = NULL;
		LPSESSION_INFO_502 pSi502 = NULL;
		//wchar_t ServerName[MAXLEN] = { NULL };
		//wchar_t ClientName[MAXLEN] = { NULL };
   		//wchar_t UserName[MAXLEN] = { NULL };
		wchar_t *ServerName = NULL;
		wchar_t *ClientName = NULL;
   		wchar_t *UserName = NULL;
		ServerInfo = newHV();
		Session = newHV();
		
		
   		if(strcmp(servername, "NULL") != 0)
		{
			size = MultiByteToWideChar(CP_OEMCP, 0, servername, -1, ServerName, 0);
			ServerName=(wchar_t*)GlobalAlloc(GMEM_ZEROINIT, size);
			ret = MultiByteToWideChar(CP_OEMCP, 0, servername, -1, ServerName, size);
			if(ret == 0)
				getError(GetLastError());
		}	
		if(strcmp(clientname, "NULL") != 0) {
			size = MultiByteToWideChar(CP_OEMCP, 0, clientname, -1, ClientName, 0);
			ClientName=(wchar_t*)GlobalAlloc(GMEM_ZEROINIT, size);
			ret = MultiByteToWideChar(CP_OEMCP, 0, clientname, -1, ClientName, size);
			if(ret == 0)
				getError(GetLastError());
		}
		if(strcmp(username, "NULL") != 0)
		{
			size = MultiByteToWideChar(CP_OEMCP, 0, username, strlen(username)+1, UserName, 0);
			UserName=(wchar_t*)GlobalAlloc(GMEM_ZEROINIT, size);
			ret = MultiByteToWideChar(CP_OEMCP, 0, username, strlen(username)+1, UserName, size);
			if(ret == 0)
				getError(GetLastError());
		}
			
		dwLevel = GetLevel(level);
		
		
		do {
			if(dwLevel == 0) {
				nStatus  = NetSessionEnum(ServerName, ClientName, UserName, dwLevel, (LPBYTE*)&pSi0, dwPrefMaxLen, &dwEntriesRead, &dwTotalEntries, &dwResumeHandle);
				bufptr = (LPBYTE*)&pSi0;
			}
			if(dwLevel == 1) {
				nStatus  = NetSessionEnum((LPWSTR)ServerName, (LPWSTR)ClientName, (LPWSTR)UserName, dwLevel, (LPBYTE*)&pSi1, dwPrefMaxLen, &dwEntriesRead, &dwTotalEntries, &dwResumeHandle);
				bufptr = (LPBYTE*)pSi1;
			}
			if(dwLevel == 2) {
				nStatus  = NetSessionEnum((LPWSTR)ServerName, (LPWSTR)ClientName, (LPWSTR)UserName, dwLevel, (LPBYTE*)&pSi2, dwPrefMaxLen, &dwEntriesRead, &dwTotalEntries, &dwResumeHandle);
				bufptr = (LPBYTE*)pSi2;
			}
			if(dwLevel == 10) {
				nStatus  = NetSessionEnum((LPWSTR)ServerName, (LPWSTR)ClientName, (LPWSTR)UserName, dwLevel, (LPBYTE*)&pSi10, dwPrefMaxLen, &dwEntriesRead, &dwTotalEntries, &dwResumeHandle);
				bufptr = (LPBYTE*)pSi10;
			}
			if(dwLevel == 502) {
				nStatus  = NetSessionEnum((LPWSTR)ServerName, (LPWSTR)ClientName, (LPWSTR)UserName, dwLevel, (LPBYTE*)&pSi502, dwPrefMaxLen, &dwEntriesRead, &dwTotalEntries, &dwResumeHandle);
				bufptr = (LPBYTE*)pSi502;
			}
			getError(nStatus);
			if ((nStatus == NERR_Success) || (nStatus == ERROR_MORE_DATA))
			{

				if ((pTmpBuf = bufptr) != NULL && dwEntriesRead != 0)
				{

					for (i = 0; (i < dwEntriesRead); i++)
				        {
               					assert(pTmpBuf != NULL);

						if (pTmpBuf == NULL)
               					{
               						croak("An access violation has occurred\n");
               					}
						//
               					// Print the retrieved data. 
               					//
						if(dwLevel == 0)
						{
							store_hv(Session, bufptr, dwLevel);
							sprintf(tmp, "%d", i);
							hv_store(ServerInfo, tmp,     strlen(tmp), newRV_noinc((SV*)Session), 0);
							Session = newHV();
							pSi0++;
							bufptr = (LPBYTE*)pSi0;
						}
						if(dwLevel == 1)
						{
							store_hv(Session, bufptr, dwLevel);
							sprintf(tmp, "%d", i);
							hv_store(ServerInfo, tmp,     strlen(tmp), newRV_noinc((SV*)Session), 0);
							Session = newHV();
							pSi1++;
							bufptr = (LPBYTE*)pSi1;
						}
						if(dwLevel == 2)
						{
							store_hv(Session, bufptr, dwLevel);
							sprintf(tmp, "%d", i);
							hv_store(ServerInfo, tmp,     strlen(tmp), newRV_noinc((SV*)Session), 0);
							Session = newHV();
							pSi2++;
							bufptr = (LPBYTE*)pSi2;
						}
						if(dwLevel == 502)
						{
							store_hv(Session, bufptr, dwLevel);
							sprintf(tmp, "%d", i);
							hv_store(ServerInfo, tmp,     strlen(tmp), newRV_noinc((SV*)Session), 0);
							Session = newHV();
							pSi502++;
							bufptr = (LPBYTE*)pSi502;
						}
						if(dwLevel == 10)
						{
							store_hv(Session, bufptr, dwLevel);
							sprintf(tmp, "%d", i);
							hv_store(ServerInfo, tmp,     strlen(tmp), newRV_noinc((SV*)Session), 0);
							Session = newHV();
							pSi10++;
							bufptr = (LPBYTE*)pSi10;
						}
               					pTmpBuf++;
               					dwTotalCount++;
            				}
            				//free(tmp);
            				//free(temp);
         			}

			} else 
			{
				if(dwEntriesRead != 0)
				{
			        	FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM |FORMAT_MESSAGE_IGNORE_INSERTS,NULL,nStatus,0,(LPTSTR)wszMsgBuff,512,NULL );
                      			croak(wszMsgBuff);
                      		} 
			}
			
		      	if (pSi0 != NULL && dwLevel == 0)
		      	{
				NetApiBufferFree(pSi0);
        			pSi0 = NULL;
      			}
		      	if (pSi1 != NULL && dwLevel == 1)
		      	{
				NetApiBufferFree(pSi1);
        			pSi1 = NULL;
      			}
		      	if (pSi2 != NULL && dwLevel == 2)
		      	{
				NetApiBufferFree(pSi2);
        			pSi2 = NULL;
      			}
		      	if (pSi10 != NULL && dwLevel == 10)
		      	{
				NetApiBufferFree(pSi10);
        			pSi10 = NULL;
      			}
		      	if (pSi502 != NULL && dwLevel == 502)
		      	{
				NetApiBufferFree(pSi502);
        			pSi502 = NULL;
      			}
		} while(nStatus == ERROR_MORE_DATA); // end do

		//if(structures[level] != NULL)
		//	NetApiBufferFree(structures[level]);
	      	
	      	if (pSi0 != NULL && dwLevel == 0)
	      	{
			NetApiBufferFree(pSi0);
		}
	      	if (pSi1 != NULL && dwLevel == 1)
	      	{
			NetApiBufferFree(pSi1);
        	}
		if (pSi2 != NULL && dwLevel == 2)
		{
			NetApiBufferFree(pSi2);
        	}
	      	if (pSi10 != NULL && dwLevel == 10)
	      	{
			NetApiBufferFree(pSi10);
		}
		if (pSi502 != NULL && dwLevel == 502)
		{
			NetApiBufferFree(pSi502);
      		}
		sprintf(temp, "%d", dwEntriesRead);
   		sv_setpvn(readed, temp, strlen(temp));
      		if(dwEntriesRead > 0) {
      			RETVAL = newRV_noinc((SV*) ServerInfo);
      		} else if(dwEntriesRead == 0)
      		{
      			RETVAL = newRV_noinc(newSViv(-1));
      		}
      		
	} //CODE
	OUTPUT:
		RETVAL

