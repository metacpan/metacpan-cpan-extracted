
#define _DNS_H_

#include <windows.h>
#include <winsock.h>
#include <stdio.h>
#include <tchar.h>
#include <string.h>

//#include "NTSECAPI.H"

#include "dns.h"
#include "adminmisc.h"
		/*	=======================================================================
			DNS Code
		*/
char *DupString(char *szString){
	char *szNew = 0;
	if (szString){
		if (szNew = new char [strlen(szString) + 1]){
			strcpy(szNew, szString);
		}
	}
	return szNew;
}

char *ResolveSiteName(char *szHost){
	char		szTemp[200];
	char		*szName = 0;
	char		*szIP = 0;
	int			iType = IP;
  	PHOSTENT	pHostEntTemp;
	struct in_addr		*iaTemp = 0;
	u_long		ulIPAddress;
	sDNS		*DNS = 0;

	if (iWinsockActive){	
			//	Are we dealing with an IP or a Name?
		if (_strspnp(szHost, "1234567890.")){
			szName = szHost;
			iType = NAME;
		}else{
			szIP = szHost;
			iType = IP;
		}
		if (iEnableDNSCache){
			if (DNS = CheckDNSCache((iType == NAME)? szName:szIP)){
				szHost = ((iType == NAME)? DNS->szIP:DNS->szName);
			}else{
				szHost = 0;
			}
		}
		if (! DNS){
			if (szIP){
				ulIPAddress = inet_addr(szIP);
				if (pHostEntTemp = gethostbyaddr((char *)&ulIPAddress, 4, PF_INET)){
					strcpy(szTemp, pHostEntTemp->h_name);
					szName = szTemp;
				}
			}else{
				if (pHostEntTemp = gethostbyname((const char *) szName)){	
					iaTemp = (struct in_addr *) (pHostEntTemp->h_addr_list[0]);
					strcpy(szTemp, inet_ntoa(iaTemp[0]));
					szIP = szTemp;
				}
			}
			if (DNS = AddDNSCache(szName, szIP)){
				szHost = ((iType == NAME)? DNS->szIP:DNS->szName);
			}
		}
	}else{
		szHost = 0;
	}
	return szHost;
}

int RemoveCache(int	iEntry, int iFlag){
		//	If the IP is the same memory block as Name, dismiss Name
	if (sDNSCache[iEntry]->szIP == sDNSCache[iEntry]->szName){
		sDNSCache[iEntry]->szName = 0;
	}
		//	Free the IP memory block
	if (sDNSCache[iEntry]->szIP){
		delete sDNSCache[iEntry]->szIP;
		sDNSCache[iEntry]->szIP = 0;
	}
		//	Free the Name memory block
	if (sDNSCache[iEntry]->szName){
		delete sDNSCache[iEntry]->szName;
		sDNSCache[iEntry]->szName = 0;
	}
		//	Free the DNS structure memory block
	if (sDNSCache[iEntry]){
		delete sDNSCache[iEntry];
		sDNSCache[iEntry] = 0;
	}
		//	If specified, reallocate the memory size of the sDNSCache
	if (iFlag){
		if (iDNSCacheCount){
			int	iTemp, iTemp2 = 0;
			sDNS **sTemp;
			if (sTemp = new sDNS* [iDNSCacheCount]){
				for (iTemp = 0; iTemp2 < iDNSCacheCount; iTemp++){
					if (iTemp == iEntry){
						iTemp2++;
					}
					sTemp[iTemp] = sDNSCache[iTemp2];
					iTemp2++;
				}
				delete [] sDNSCache;
				sDNSCache = sTemp;
				sTemp = 0;
			}
		}else{
			sDNSCache = 0;
		}
	}
	if (--iDNSCacheCount < 0){
		iDNSCacheCount = 0;		
	}
	return 1;
}

int ResetDNSCache(){
	int	iTemp;
	if (sDNSCache){
		for (iTemp = 0; iTemp < iDNSCacheCount; iTemp++){
			RemoveCache(iTemp, 0);
		}
		delete [] sDNSCache;
		sDNSCache = 0;
	}
	return 1;
}

sDNS *CheckDNSCache(char *szHost){
	int iTemp;
	int	iType = IP;
	char	*szTemp = 0;

	if (! sDNSCache){
		return 0;
	}
		//	If it is not an IP then set iType flag to 0
	if (_strspnp(szHost, "1234567890.")){
		iType = NAME;
	}
	for (iTemp = 0; iTemp < iDNSCacheCount; iTemp++){
		if (szTemp = (iType == IP)? sDNSCache[iTemp]->szIP:sDNSCache[iTemp]->szName){
			if (stricmp(szHost, (const char *) szTemp) == 0){
				sDNSCache[iTemp]->lLastUse = ++lDNSCacheTime;
				return sDNSCache[iTemp];
			}
		}
	}
	return 0;
}

sDNS *AddDNSCache(char *szName, char *szIP){
	int	iEntry;

	if (!szName && !szIP){
		return 0;
	}
	if (iDNSCacheCount < iDNSCacheLimit){
		sDNS	**sTemp;
		sDNS	*sNewDNS;

		iEntry = iDNSCacheCount;
		if (sNewDNS = new sDNS){
			sNewDNS->szIP = 0;
			sNewDNS->szName = 0;
			sNewDNS->lLastUse = 0;
		
				//	Allocate room for the array and move it over
			if (sTemp = new sDNS* [iDNSCacheCount + 1]){
				if (sDNSCache){
					memcpy(sTemp, sDNSCache, sizeof(sDNS*) * iDNSCacheCount);
					delete [] sDNSCache;
				}
				sDNSCache = sTemp;
				sTemp = 0;
				sDNSCache[iDNSCacheCount] = sNewDNS;
				iDNSCacheCount++;
			}
		}else{
			return 0;
		}
	}else{
		int	iTemp;
		if (! sDNSCache){
			return 0;
		}

		iEntry = 0;
			//	Let's find the oldest cache entry and replace it
		for (iTemp = 0; iTemp < iDNSCacheLimit; iTemp++){
			if (sDNSCache[iTemp]->lLastUse < sDNSCache[iEntry]->lLastUse){
				iEntry = iTemp;
			}
		}
			//	Since we are going to simply replace the entry we will not force
			//	the reallocation of the list's memory.
		RemoveCache(iEntry, 0);
			//	Now we must allocate a new DNS memory block.
		if (sDNSCache[iEntry] = new sDNS){
			sDNSCache[iEntry]->szIP = 0;
			sDNSCache[iEntry]->szName = 0;
		}else{
			return 0;
		}
	}
	if (!sDNSCache[iEntry]){
		return 0;
	}
	sDNSCache[iEntry]->szIP = DupString(szIP);
	sDNSCache[iEntry]->szName = DupString(szName);
	if (!szName){
		sDNSCache[iEntry]->szName = 0;
	}
	if (!szIP){
		sDNSCache[iEntry]->szIP = 0;
	}
	sDNSCache[iEntry]->lLastUse = lDNSCacheTime++;
	return sDNSCache[iEntry];
}	

