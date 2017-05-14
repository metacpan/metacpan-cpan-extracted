#define WIN32_LEAN_AND_MEAN


#ifndef __TIMEOFD_CPP
#define __TIMEOFD_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "addloader.h"
#include "timeofd.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// returns the time of day information from a specified server
//
// param:  server - computer to get the time from
//         info   - time information to return
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetRemoteTOD)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PWSTR server = NULL;
		PTIME_OF_DAY_INFO timeInfo = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear hash
			HV_CLEAR(info);

			if(!LastError(NetRemoteTOD(server, (PBYTE*)&timeInfo)))
			{
				H_STORE_INT(info, "elapsedt", timeInfo->tod_elapsedt);
				H_STORE_INT(info, "msecs", timeInfo->tod_msecs);
				H_STORE_INT(info, "hours", timeInfo->tod_hours);
				H_STORE_INT(info, "mins", timeInfo->tod_mins);
				H_STORE_INT(info, "secs", timeInfo->tod_secs);
				H_STORE_INT(info, "hunds", timeInfo->tod_hunds);
				H_STORE_INT(info, "timezone", timeInfo->tod_timezone);
				H_STORE_INT(info, "tinterval", timeInfo->tod_tinterval);
				H_STORE_INT(info, "day", timeInfo->tod_day);
				H_STORE_INT(info, "month", timeInfo->tod_month);
				H_STORE_INT(info, "year", timeInfo->tod_year);
				H_STORE_INT(info, "weekday", timeInfo->tod_weekday);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(timeInfo);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetRemoteTOD($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// queries the redirector to retrieve the optional features the remote system 
// supports
//
// param:  server			- computer to get the info from
//         options		- options to receive from the remote system
//				 supported	- options supported by the remote system
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetRemoteComputerSupports)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *supportedOptions = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(supportedOptions, ST(2)))
	{
		PWSTR server = NULL;
		DWORD wanted = 0, supported = 0;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			wanted = SvIV(ST(1));

			// clear scalar
			SV_CLEAR(supportedOptions);

			// unregister the notification handle
			LastError(NetRemoteComputerSupports(server, wanted, &supported));

			if(LastError())
				S_STORE_INT(supportedOptions, supported);

		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetRemoteComputerSupports($server, $options, \\$supported)\n");
	
	RETURNRESULT(LastError() == 0);
}


