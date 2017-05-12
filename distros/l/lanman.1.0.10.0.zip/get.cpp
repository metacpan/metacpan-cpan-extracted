#define WIN32_LEAN_AND_MEAN


#ifndef __GET_CPP
#define __GET_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "get.h"
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
// returns information about the expected performance of a connection used to 
// access a network resource
//
// param:  netresource - netresource struct
//         info				 - info to return
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_MultinetGetConnectionPerformance)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *resource = NULL;
	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(resource, ST(0)) && CHK_ASSIGN_HREF(info, ST(1)))
	{
		__try
		{
			// set netresource values
			NETRESOURCE netResource =
			{
				H_FETCH_INT(resource, "scope"),
				H_FETCH_INT(resource, "type"),
				H_FETCH_INT(resource, "displaytype"),
				H_FETCH_INT(resource, "usage"),
				H_FETCH_STR(resource, "localname"),
				H_FETCH_STR(resource, "remotename"),
				H_FETCH_STR(resource, "comment"),
				H_FETCH_STR(resource, "provider")
			};

			NETCONNECTINFOSTRUCT connectionInfo;

			// clear hash
			HV_CLEAR(info);

			// clean memory and set struct size
			memset(&connectionInfo, 0, sizeof(connectionInfo));
			connectionInfo.cbStructure = sizeof(connectionInfo);

			if(!LastError(MultinetGetConnectionPerformance(&netResource, &connectionInfo)))
			{
				H_STORE_INT(info, "flags", connectionInfo.dwFlags);
				H_STORE_INT(info, "speed", connectionInfo.dwSpeed);
				H_STORE_INT(info, "delay", connectionInfo.dwDelay);
				H_STORE_INT(info, "optdatasize", connectionInfo.dwOptDataSize);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::MultinetGetConnectionPerformance(\\%%netresource, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// returns the name of a domain controller in a specified domain
//
// param:  server - computer to execute the command
//         domain	-	domain name to get a domain controller for
//				 dcname	- string to store domain controller name 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetAnyDCName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *dcName = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(dcName, ST(2)))
	{
		PWSTR server = NULL, domain = NULL, name = NULL;

		__try
		{
			// change server and domain to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domain = S2W(SvPV(ST(1), PL_na));

			// clear scalar
			SV_CLEAR(dcName);

			if(!LastError(NetGetAnyDCName(server, domain, (PBYTE*)&name)))
				S_STORE_WSTR(dcName, name);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(domain);
		CleanNetBuf(name);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetGetAnyDCName($server, $domain, \\$dcname)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// returns the name of the primary domain controller 
//
// param:  server  - computer to execute the command
//         domain	 - domain name to get a domain controller for
//				 pdcname - string to store domain controller name 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetDCName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *pdcName = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(pdcName, ST(2)))
	{
		PWSTR server = NULL, domain = NULL, name = NULL;

		__try
		{
			// change server and domain to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domain = S2W(SvPV(ST(1), PL_na));

			// clear scalar
			SV_CLEAR(pdcName);

			if(!LastError(NetGetDCName(server, domain, (PBYTE*)&name)))
				S_STORE_WSTR(pdcName, name);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(domain);
		CleanNetBuf(name);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetGetDCName($server, $domain, \\$pdcname)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the index of the first display information entry whose name begins with 
// a specified string or alphabetically follows the string
//
// param:  server - computer to execute the command
//				 level  - requested information type 
//								  (1 - user, 2 - computer accounts, 3 - groups)
//				 prefix	- contains the prefix for which to search
//         domain	-	domain name to get a domain controller for
//				 index  - receives the index of the entry
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetDisplayInformationIndex)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *infIndex = NULL;

	if(items == 4 && CHK_ASSIGN_SREF(infIndex, ST(3)))
	{
		PWSTR server = NULL, prefix = NULL;

		__try
		{
			// change server and prefix to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			prefix = S2W(SvPV(ST(2), PL_na));
			
			DWORD level = SvIV(ST(1));
			DWORD index = 0;

			// clear scalar
			SV_CLEAR(infIndex);

			if(!LastError(NetGetDisplayInformationIndex(server, level, prefix, &index)))
				S_STORE_INT(infIndex, index);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(prefix);
	} // if(items == 4)
	else
		croak("Usage: Win32::Lanman::NetGetDisplayInformationIndex($server, $level, $prefix, \\$index)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// returns user, computer, or global group account information
//
// param:  server  - computer to execute the command
//				 level   - requested information type 
//									 (1 - user, 2 - computer accounts, 3 - groups)
//         index	 - index of the first entry for which to retrieve information
//				 entries - maximum number of entries for which to get information
//				 info		 - hash to store information 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetQueryDisplayInformation)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *info = NULL;

	if(items == 5 && CHK_ASSIGN_AREF(info, ST(4)))
	{
		PWSTR server = NULL;
		PVOID query = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			DWORD level = SvIV(ST(1));
			DWORD index = SvIV(ST(2));
			DWORD entries = SvIV(ST(3));

			// clear array
			AV_CLEAR(info);

			DWORD maxCount = 0;
			
			LastError(NetQueryDisplayInformation(server, level, index, entries, 
																					 0xffffffff, &maxCount, &query));

			if(LastError() == NERR_Success || LastError() == ERROR_MORE_DATA)
			{
				LastError(0);

				switch(level)
				{
					case 1:
						{
							PNET_DISPLAY_USER user = (PNET_DISPLAY_USER)query;
							
							for(DWORD count = 0; count < maxCount; count++)
							{
								HV *properties = NewHV;

								H_STORE_WSTR(properties, "name", user[count].usri1_name);
								H_STORE_WSTR(properties, "comment", user[count].usri1_comment);
								H_STORE_INT(properties, "flags", user[count].usri1_flags);
								H_STORE_WSTR(properties, "full_name", user[count].usri1_full_name);
								H_STORE_INT(properties, "user_id", user[count].usri1_user_id);
								H_STORE_INT(properties, "next_index", user[count].usri1_next_index);

								A_STORE_REF(info, properties);

								// decrement reference count
								SvREFCNT_dec(properties);
							}
						}
						break;

					case 2:
						{
							PNET_DISPLAY_MACHINE machine = (PNET_DISPLAY_MACHINE)query;

							for(DWORD count = 0; count < maxCount; count++)
							{
								HV *properties = NewHV;

								H_STORE_WSTR(properties, "name", machine[count].usri2_name);
								H_STORE_WSTR(properties, "comment", machine[count].usri2_comment);
								H_STORE_INT(properties, "flags", machine[count].usri2_flags);
								H_STORE_INT(properties, "user_id", machine[count].usri2_user_id);
								H_STORE_INT(properties, "next_index", machine[count].usri2_next_index);

								A_STORE_REF(info, properties);

								// decrement reference count
								SvREFCNT_dec(properties);
							}
						}
						break;
					
					case 3:
						{
							PNET_DISPLAY_GROUP group = (PNET_DISPLAY_GROUP)query;

							for(DWORD count = 0; count < maxCount; count++)
							{
								HV *properties = NewHV;

								H_STORE_WSTR(properties, "name", group[count].grpi3_name);
								H_STORE_WSTR(properties, "comment", group[count].grpi3_comment);
								H_STORE_INT(properties, "group_id", group[count].grpi3_group_id);
								H_STORE_INT(properties, "attributes", group[count].grpi3_attributes);
								H_STORE_INT(properties, "next_index", group[count].grpi3_next_index);

								A_STORE_REF(info, properties);

								// decrement reference count
								SvREFCNT_dec(properties);
							}
						}
						break;
				} // switch(level)
			} // if(LastError() == NERR_Success || LastError() == ERROR_MORE_DATA)
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		CleanNetBuf(query);
	} // if(items == 4)
	else
		croak("Usage: Win32::Lanman::NetQueryDisplayInformation($server, $level, $index, $entries, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


