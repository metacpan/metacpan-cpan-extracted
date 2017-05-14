#define WIN32_LEAN_AND_MEAN


#ifndef __USE_CPP
#define __USE_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "use.h"
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
// establishes a connection between a local or NULL device name and a shared 
// resource by redirecting the local or NULL (UNC) device name to the shared 
// resource
//
// param:  useinfo - info to establish a connection
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *useInfo = NULL;

	if(items == 1 && CHK_ASSIGN_HREF(useInfo, ST(0)))
	{
		USE_INFO_2 info;

		memset(&info, 0, sizeof(info));

		__try
		{
			// store members
			info.ui2_local = (PSTR)H_FETCH_WSTR(useInfo, "local");
			info.ui2_remote = (PSTR)H_FETCH_WSTR(useInfo, "remote");
			info.ui2_password = (PSTR)H_FETCH_WSTR(useInfo, "password");
			info.ui2_asg_type = H_FETCH_INT(useInfo, "asg_type");
			info.ui2_usecount = H_FETCH_INT(useInfo, "usecount");
			info.ui2_username = (PSTR)H_FETCH_WSTR(useInfo, "username");
			info.ui2_domainname = (PSTR)H_FETCH_WSTR(useInfo, "domainname");

			// create connection
			LastError(NetUseAdd(NULL, 2, (PBYTE)&info, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(info.ui2_local);
		FreeStr(info.ui2_remote);
		FreeStr(info.ui2_password);
		FreeStr(info.ui2_username);
		FreeStr(info.ui2_domainname);
	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::NetUseAdd(\\%%useinfo)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// deletes a connection to a shared resource
//
// param:  usename  - connection name to delete
//				 forcedel - forces a disconnect if there are still opens
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 1 || items ==2)
	{
		PWSTR useName = NULL;

		__try
		{
			// change useName to unicode
			useName = S2W(SvPV(ST(0), PL_na));
			
			DWORD force = items == 2 ? SvIV(ST(1)) : USE_NOFORCE;

			// delete connection
			LastError(NetUseDel(NULL, (PSTR)useName, force));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(useName);
	} // if(items == 1 || items == 2)
	else
		croak("Usage: Win32::Lanman::NetUseDel($usename [, $forcedel])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all connections to a shared resource
//
// param:  info  - array to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *useInfo = NULL;

	if(items == 1 && CHK_ASSIGN_AREF(useInfo, ST(0)))
	{
		PUSE_INFO_2 info = NULL;

		__try
		{
			// clear array
			AV_CLEAR(useInfo);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			// enum connections
			if(!LastError(NetUseEnum(NULL, 2, (PBYTE*)&info, 0xffffffff, &entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store share properties
					HV *properties = NewHV;

					H_STORE_WSTR(properties, "local", (PWSTR)info[count].ui2_local);
					H_STORE_WSTR(properties, "remote", (PWSTR)info[count].ui2_remote);
					H_STORE_WSTR(properties, "password", (PWSTR)info[count].ui2_password);
					H_STORE_INT(properties, "status", info[count].ui2_status);
					H_STORE_INT(properties, "asg_type", info[count].ui2_asg_type);
					H_STORE_INT(properties, "refcount", info[count].ui2_refcount);
					H_STORE_INT(properties, "usecount", info[count].ui2_usecount);
					H_STORE_WSTR(properties, "username", (PWSTR)info[count].ui2_username);
					H_STORE_WSTR(properties, "domainname", (PWSTR)info[count].ui2_domainname);

					A_STORE_REF(useInfo, properties);

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
		CleanNetBuf(info);
	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::NetUseEnum(\\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets information about a connection to a shared resource
//
// param:  usename - connection name to get information for
//				 info		 - hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUseGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *useInfo = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(useInfo, ST(1)))
	{
		PWSTR useName = NULL;
		PUSE_INFO_2 info = NULL;

		__try
		{
			// change useName to unicode
			useName = S2W(SvPV(ST(0), PL_na));

			// clear array
			HV_CLEAR(useInfo);

			// enum connections
			if(!LastError(NetUseGetInfo(NULL, (PSTR)useName, 2, (PBYTE*)&info)))
			{
				// store information
				H_STORE_WSTR(useInfo, "local", (PWSTR)info->ui2_local);
				H_STORE_WSTR(useInfo, "remote", (PWSTR)info->ui2_remote);
				H_STORE_WSTR(useInfo, "password", (PWSTR)info->ui2_password);
				H_STORE_INT(useInfo, "status", info->ui2_status);
				H_STORE_INT(useInfo, "asg_type", info->ui2_asg_type);
				H_STORE_INT(useInfo, "refcount", info->ui2_refcount);
				H_STORE_INT(useInfo, "usecount", info->ui2_usecount);
				H_STORE_WSTR(useInfo, "username", (PWSTR)info->ui2_username);
				H_STORE_WSTR(useInfo, "domainname", (PWSTR)info->ui2_domainname);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(useName);
		CleanNetBuf(info);
	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::NetUseGetInfo($usename, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


