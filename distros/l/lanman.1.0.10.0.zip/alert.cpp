#define WIN32_LEAN_AND_MEAN


#ifndef __ALERT_CPP
#define __ALERT_CPP
#endif


#include <windows.h>
#include <time.h>
#include <lm.h>


#include "alert.h"
#include "wstring.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// 
//
// param:  
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetAlertRaise)
{
	dXSARGS;

	// reset last error
	LastError(0);

	if(1)
	{
	} 
	else
		croak("Usage: Win32::Lanman::NetRaiseAlert()\n");
	
	RETURNRESULT(LastError() == 0);
}


