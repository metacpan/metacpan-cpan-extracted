#ifndef UNICODE
#define UNICODE 1
#endif

#ifndef _UNICODE
#define _UNICODE 1
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define VC_EXTRALEAN
#include <stdio.h>
#include <windows.h> 
#include <lm.h>


MODULE = Win32::RemoteTOD		PACKAGE = Win32::RemoteTOD		


int
GetTOD(hostnamesv,timeinfosv)
	PREINIT:
		LPTIME_OF_DAY_INFO pBuf		= NULL;
		NET_API_STATUS nStatus		= 0;
		LPTSTR pszServerName		= NULL;
		STRLEN hostnamelen		= 0;
		HV *timeinfohv			= newHV();
		char *hostname			= NULL;
		char *pdest			= NULL;
		int i				= 0;
	INPUT:
		SV *hostnamesv;
		SV *timeinfosv;
	CODE:
		hostname = SvPV_nolen(hostnamesv);
		hostnamelen = strlen(hostname);

		while (pdest = strstr(hostname, "\\"))
		  for (i = pdest - hostname; i < hostnamelen; i++)
		    hostname[i] = hostname[i+1];

		pszServerName = malloc( (strlen(hostname)+1) * sizeof(wchar_t));

		if (pszServerName == NULL) {
			RETVAL = ERROR_OUTOFMEMORY;
		} else {
			mbstowcs(pszServerName, hostname, strlen(hostname)+1);

			RETVAL = NetRemoteTOD(pszServerName, (LPBYTE *)&pBuf);
			free(pszServerName);

			if ((RETVAL == NERR_Success) && (pBuf != NULL)) {
				// set hash
				hv_store(timeinfohv, "elapsedt",	8, newSViv(pBuf->tod_elapsedt),	0);
				hv_store(timeinfohv, "msecs",		5, newSViv(pBuf->tod_msecs),	0);
				hv_store(timeinfohv, "hours",		5, newSViv(pBuf->tod_hours),	0);
				hv_store(timeinfohv, "mins",		4, newSViv(pBuf->tod_mins),	0);
				hv_store(timeinfohv, "secs",		4, newSViv(pBuf->tod_secs),	0);
				hv_store(timeinfohv, "hunds",		5, newSViv(pBuf->tod_hunds),	0);
				hv_store(timeinfohv, "timezone",	8, newSViv(pBuf->tod_timezone),	0);
				hv_store(timeinfohv, "tinterval",	9, newSViv(pBuf->tod_tinterval),0);
				hv_store(timeinfohv, "day",		3, newSViv(pBuf->tod_day),	0);
				hv_store(timeinfohv, "month",		5, newSViv(pBuf->tod_month),	0);
				hv_store(timeinfohv, "year",		4, newSViv(pBuf->tod_year),	0);
				hv_store(timeinfohv, "weekday",		7, newSViv(pBuf->tod_weekday),	0);

				sv_setsv(timeinfosv, sv_2mortal(newRV_noinc((SV *)timeinfohv)));
			}
		}
		if (pBuf != NULL) NetApiBufferFree(pBuf);
	OUTPUT:
		timeinfosv
		RETVAL
		
