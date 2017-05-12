#define WIN32_LEAN_AND_MEAN


#ifndef __DOMAIN_CPP
#define __DOMAIN_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <lmaccess.h>


#include "domain.h"
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
// queries, synchonizes or replicates the sam database between PDC and BDC's
//
// param:  server		- computer to execute the command
//         function - function code to execute
//				 info			- gets the result
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_NetLogonControl)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *domainInfo = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(domainInfo, ST(2)))
	{
		PWSTR server = NULL;
		PNETLOGON_INFO_1 info = NULL;
		
		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			DWORD function = SvIV(ST(1));

			// clean hash
			HV_CLEAR(domainInfo);

			if(!LastError(I_NetLogonControl(server, function, 1, (PBYTE*)&info)))
			{
				H_STORE_INT(domainInfo, "flags", info->netlog1_flags);
				H_STORE_INT(domainInfo, "pdc_connection_status", 
										info->netlog1_pdc_connection_status);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(info);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::I_NetLogonControl($server, $function, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// queries, synchonizes, replicates the sam database between PDC and BDC's; can
// get the logon count, query and rediscover secure channels, notify of new
// transports and finds user in a trusted domain
//
// param:  server		- computer to execute the command
//         function - function code to execute
//				 data			- data needed as input (domain or user name)
//				 info			- gets the result
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_NetLogonControl2)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *domainInfo = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(domainInfo, ST(3)))
	{
		PNETLOGON_INFO_1 info = NULL;
		PWSTR server = NULL;
		PSTR data = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			DWORD function = SvIV(ST(1));
			DWORD level = 0;

			// clean hash
			HV_CLEAR(domainInfo);

			// set data and call level
			switch(function)
			{
				case NETLOGON_CONTROL_QUERY:
					level = 3;
					break;

				case NETLOGON_CONTROL_REPLICATE:
				case NETLOGON_CONTROL_SYNCHRONIZE:
				case NETLOGON_CONTROL_PDC_REPLICATE:
				case NETLOGON_CONTROL_TRANSPORT_NOTIFY:
					level = 1;
					break;

				case NETLOGON_CONTROL_REDISCOVER:
				case NETLOGON_CONTROL_TC_QUERY:
					data = (PSTR)S2W(SvPV(ST(2), PL_na));
					level = 2;
					break;

				case NETLOGON_CONTROL_FIND_USER:
					data = (PSTR)S2W(SvPV(ST(2), PL_na));
					level = 4;
					break;
			}

			if(!LastError(I_NetLogonControl2(server, function, level, (PBYTE)&data, (PBYTE*)&info)))
				// get data on success
				switch(function)
				{
					case NETLOGON_CONTROL_QUERY:
						H_STORE_INT(domainInfo, "flags", 
												((PNETLOGON_INFO_3)info)->netlog3_flags);
						H_STORE_INT(domainInfo, "logon_attempts", 
												((PNETLOGON_INFO_3)info)->netlog3_logon_attempts);
						break;

					case NETLOGON_CONTROL_REPLICATE:
					case NETLOGON_CONTROL_SYNCHRONIZE:
					case NETLOGON_CONTROL_PDC_REPLICATE:
					case NETLOGON_CONTROL_TRANSPORT_NOTIFY:
						H_STORE_INT(domainInfo, "flags", 
												((PNETLOGON_INFO_1)info)->netlog1_flags);
						H_STORE_INT(domainInfo, "pdc_connection_status", 
												((PNETLOGON_INFO_1)info)->netlog1_pdc_connection_status);
						break;

					case NETLOGON_CONTROL_REDISCOVER:
					case NETLOGON_CONTROL_TC_QUERY:
						H_STORE_INT(domainInfo, "flags", 
												((PNETLOGON_INFO_2)info)->netlog2_flags);
						H_STORE_INT(domainInfo, "pdc_connection_status", 
												((PNETLOGON_INFO_2)info)->netlog2_pdc_connection_status);
						H_STORE_WSTR(domainInfo, "trusted_dc_name", 
												 ((PNETLOGON_INFO_2)info)->netlog2_trusted_dc_name);
						break;

					case NETLOGON_CONTROL_FIND_USER:
						H_STORE_WSTR(domainInfo, "trusted_dc_name", 
												 ((PNETLOGON_INFO_4)info)->netlog4_trusted_dc_name);
						H_STORE_WSTR(domainInfo, "trusted_domain_name", 
												 ((PNETLOGON_INFO_4)info)->netlog4_trusted_domain_name);
						break;

				}
		} // __try
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(data);
		CleanNetBuf(info);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::I_NetLogonControl2($server, $function, $data, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enumerates all trusted domains
//
// param:  server	 - computer to execute the command
//         domains - gets the domain names
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
// important: if you need to compile this module, please change the function 
//						prototype in lmaccess.h to the following:
//
//						NTSTATUS NET_API_FUNCTION NetEnumerateTrustedDomains(
//					    IN LPWSTR ServerName OPTIONAL, OUT LPWSTR *DomainNames);
//
//						otherwise, the linker would claim an unresolved external symbol;
//						that's not neccessary if you use the plafform sdk from october
//						1999 or later
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetEnumerateTrustedDomains)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *domains = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(domains, ST(1)))
	{
		PWSTR server = NULL;
		PWSTR info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			AV_CLEAR(domains);

			if(!LastError(NetEnumerateTrustedDomains(server, &info)))
				for(PWSTR infoPtr = info; infoPtr && *infoPtr; infoPtr += wcslen(infoPtr) + 1)
					A_STORE_WSTR(domains, infoPtr);
			else
				LastError(LastError() & 0xffff);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(info);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetEnumerateTrustedDomains($server, \\@domains)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets a list of domain controllers in a domain
//
// param:  server			 - computer to execute the command
//         domain			 - domain name
//				 controllers - array to store the dc names
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_NetGetDCList)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *contrList = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(contrList, ST(2)))
	{
		PWSTR server = NULL;
		PWSTR domain = NULL;
		PNETGETDC_INFO contr = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domain = S2W(SvPV(ST(1), PL_na));
			DWORD contrCount = 0;

			PSTR info = NULL;

			// clean hash
			AV_CLEAR(contrList);

				// get dc's from a domain
			if(!LastError(I_NetGetDCList(server, domain, &contrCount, &contr)))
				for(DWORD count = 0; count < contrCount; count++)
					A_STORE_WSTR(contrList, contr[count].name);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(domain);
		CleanNetBuf(contr);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::I_NetGetDCList($server, $domain, \\@controllers)\n");
	
	RETURNRESULT(LastError() == 0);
}
