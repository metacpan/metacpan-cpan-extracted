#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <wininet.h>

MODULE = Win32::INET		PACKAGE = Win32::INET		

SV *
GetUrlCacheFile(char *url)
CODE:
	LPINTERNET_CACHE_ENTRY_INFO lpCacheEntryInfo;	
	DWORD dwEntrySize;
	GetUrlCacheEntryInfo(url, NULL, &dwEntrySize);
	if(GetLastError() == ERROR_INSUFFICIENT_BUFFER) { 
		lpCacheEntryInfo = (LPINTERNET_CACHE_ENTRY_INFO)malloc(dwEntrySize);
		BOOL ret = GetUrlCacheEntryInfo(url, lpCacheEntryInfo, &dwEntrySize);
		if(ret) {
			RETVAL = newSVpv(lpCacheEntryInfo->lpszLocalFileName, 0);
		}else{
			RETVAL = newSVpv("", 0);
		}
		free(lpCacheEntryInfo);
	}else{
		RETVAL = newSVpv("", 0);
	}
OUTPUT:
	RETVAL