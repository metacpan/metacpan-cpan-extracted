#define WIN32_LEAN_AND_MEAN


#ifndef __SESSION_CPP
#define __SESSION_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "session.h"
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
// ends a session between a server and a workstation
//
// param:  server - computer to execute the command
//				 client - computer name of the client to disconnect
//				 user   - name of the user whose session is to be terminated
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetSessionDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR server = NULL, client = NULL, user = NULL;

		__try
		{
			// change server, client and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			client = S2W(SvPV(ST(1), PL_na));
			user = S2W(SvPV(ST(2), PL_na));

			LastError(NetSessionDel((PSTR)server, (PSTR)client, (PSTR)user));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(client);
		FreeStr(user);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetSessionDel($server, $client, $user)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// provides information about all current sessions
//
// param:  server - computer to execute the command
//				 client - computer name of the client to enum
//				 user   - name of the user to enum
//				 info		- array to store session info
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetSessionEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *sessionInfo = NULL;

	if(items == 4 && CHK_ASSIGN_AREF(sessionInfo, ST(3)))
	{
		PWSTR server = NULL, client = NULL, user = NULL;
		PSESSION_INFO_10 info10 = NULL;
		PSESSION_INFO_502 info502 = NULL;

		__try
		{
			// change server, client and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			client = S2W(SvPV(ST(1), PL_na));
			user = S2W(SvPV(ST(2), PL_na));

			// clean array
			AV_CLEAR(sessionInfo);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetSessionEnum((PSTR)server, (PSTR)client, (PSTR)user, 502, 
																	 (PBYTE*)&info502, 0xffffffff, &entries, &total, 
																	 &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store session properties
					HV *properties = NewHV;

					H_STORE_WSTR(properties, "cname", (PWSTR)info502[count].sesi502_cname);
					H_STORE_WSTR(properties, "username", (PWSTR)info502[count].sesi502_username);
					H_STORE_INT(properties, "num_opens", info502[count].sesi502_num_opens);
					H_STORE_INT(properties, "time", info502[count].sesi502_time);
					H_STORE_INT(properties, "idle_time", info502[count].sesi502_idle_time);
					H_STORE_INT(properties, "user_flags", info502[count].sesi502_user_flags);
					H_STORE_WSTR(properties, "cltype_name", (PWSTR)info502[count].sesi502_cltype_name);
					H_STORE_WSTR(properties, "transport", (PWSTR)info502[count].sesi502_transport);
					
					A_STORE_REF(sessionInfo, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}
			else
				if(LastError() == ERROR_ACCESS_DENIED && 
					 !LastError(NetSessionEnum((PSTR)server, (PSTR)client, (PSTR)user, 10, 
																		 (PBYTE*)&info10, 0xffffffff, &entries, &total, 
																		 &handle)))
					for(DWORD count = 0; count < entries; count++)
					{
						// store session properties
						HV *properties = NewHV;

						H_STORE_WSTR(properties, "cname", (PWSTR)info10[count].sesi10_cname);
						H_STORE_WSTR(properties, "username", (PWSTR)info10[count].sesi10_username);
						H_STORE_INT(properties, "time", info10[count].sesi10_time);
						H_STORE_INT(properties, "idle_time", info10[count].sesi10_idle_time);

						A_STORE_REF(sessionInfo, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(client);
		FreeStr(user);
		CleanNetBuf(info10);
		CleanNetBuf(info502);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetSessionEnum($server, $client, $user, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a session established 
//
// param:  server - computer to execute the command
//				 info		- array to store disk names
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetSessionGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *sessionInfo = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(sessionInfo, ST(3)))
	{
		PWSTR server = NULL, client = NULL, user = NULL;
		PSESSION_INFO_10 info10 = NULL;
		PSESSION_INFO_502 info502 = NULL;

		__try
		{
			// change server, client and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			client = S2W(SvPV(ST(1), PL_na));
			user = S2W(SvPV(ST(2), PL_na));

			// clean hash
			HV_CLEAR(sessionInfo);

			if(!LastError(NetSessionGetInfo((PSTR)server, (PSTR)client, (PSTR)user, 502, 
																			(PBYTE*)&info502)))
			{
				// store session properties
				H_STORE_WSTR(sessionInfo, "cname", (PWSTR)info502->sesi502_cname);
				H_STORE_WSTR(sessionInfo, "username", (PWSTR)info502->sesi502_username);
				H_STORE_INT(sessionInfo, "num_opens", info502->sesi502_num_opens);
				H_STORE_INT(sessionInfo, "time", info502->sesi502_time);
				H_STORE_INT(sessionInfo, "idle_time", info502->sesi502_idle_time);
				H_STORE_INT(sessionInfo, "user_flags", info502->sesi502_user_flags);
				H_STORE_WSTR(sessionInfo, "cltype_name", (PWSTR)info502->sesi502_cltype_name);
				H_STORE_WSTR(sessionInfo, "transport", (PWSTR)info502->sesi502_transport);
			}
			else
				if(LastError() == ERROR_ACCESS_DENIED && 
					 !LastError(NetSessionGetInfo((PSTR)server, (PSTR)client, (PSTR)user, 10, 
																				(PBYTE*)&info10)))
				{
					// store session properties
					H_STORE_WSTR(sessionInfo, "cname", (PWSTR)info10->sesi10_cname);
					H_STORE_WSTR(sessionInfo, "username", (PWSTR)info10->sesi10_username);
					H_STORE_INT(sessionInfo, "time", info10->sesi10_time);
					H_STORE_INT(sessionInfo, "idle_time", info10->sesi10_idle_time);
				}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(client);
		FreeStr(user);
		CleanNetBuf(info10);
		CleanNetBuf(info502);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetSessionGetInfo($server, $client, $user, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


