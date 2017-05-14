#define WIN32_LEAN_AND_MEAN


#ifndef __BROWSE_CPP
#define __BROWSE_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <lmbrowsr.h>

 
#include "browse.h"
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
// I_BrowserServerEnum is currently not supported because MS does not offered
// any information about
//
// param:  
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_BrowserServerEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *browseInfo = NULL;

/*
	if(items == 5 &&  CHK_ASSIGN_AREF(browseInfo, ST(4)))
	{
		PWSTR server = NULL, transport = NULL, client = NULL, domain = NULL;
		DWORD level = 0, entries = 0, total = 0, handle = 0;
		DWORD type = 0xffffffff;
		PWSTR browse = NULL;

		__try
		{
			// change server, transport, client and domain to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			transport = S2W(SvPV(ST(1), PL_na));
			client = S2W(SvPV(ST(2), PL_na));
			domain = S2W(SvPV(ST(3), PL_na));

			LastError(I_BrowserServerEnum(NULL, transport, NULL, level, (PBYTE*)&browse, 0xffffffff, 
																		&entries, &total, type, NULL, &handle));
			if(!LastError())
			{
				for(DWORD count = 0; count < entries; count++)
				{
					// store user properties
					HV *properties = NewHV;

					A_STORE_REF(browseInfo, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				} // for(DWORD count = 0; count < entries; count++)
			} // if(!LastError())
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(transport);
		FreeStr(client);
		FreeStr(domain);
		CleanNetBuf(browse);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::I_BrowserServerEnum($server, $transport, $client, $domain, \\@info)\n");
*/

	croak("Win32::Lanman::I_BrowserServerEnum() is currently not supported\n");
	
	RETURNRESULT(LastError() == 0);
}


