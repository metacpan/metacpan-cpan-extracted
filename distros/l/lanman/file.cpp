#define WIN32_LEAN_AND_MEAN


#ifndef __FILE_CPP
#define __FILE_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "file.h"
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
// supplies information about some or all open files on a server
//
// param:  server - computer to execute the command
//				 path		- base path to get information from
//         user   - user name filter
//				 info		- array to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetFileEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *fileInfo = NULL;

	if(items == 4 && CHK_ASSIGN_AREF(fileInfo, ST(3)))
	{
		PWSTR server = NULL, path = NULL, user = NULL;
		PFILE_INFO_3 info = NULL;

		__try
		{
			// change server, path and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			path = S2W(SvPV(ST(1), PL_na));
			user = S2W(SvPV(ST(2), PL_na));

			// clear array
			AV_CLEAR(fileInfo);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetFileEnum((PSTR)server, (PSTR)path, (PSTR)user, 3, 
																(PBYTE*)&info, 0xffffffff, &entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store file properties
					HV *properties = NewHV;

					H_STORE_INT(properties, "id", info[count].fi3_id);
					H_STORE_INT(properties, "permissions", info[count].fi3_permissions);
					H_STORE_INT(properties, "num_locks", info[count].fi3_num_locks);
					H_STORE_WSTR(properties, "pathname", (PWSTR)info[count].fi3_pathname);
					H_STORE_WSTR(properties, "username", (PWSTR)info[count].fi3_username);
					
					A_STORE_REF(fileInfo, properties);

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
		FreeStr(path);
		FreeStr(user);
		CleanNetBuf(info);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetFileEnum($server, $basepath, $user, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a particular opening of a server resource
//
// param:  server - computer to execute the command
//				 fileid	- a file id supplied by NetFileEnum
//				 info		- hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetFileGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *fileInfo = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(fileInfo, ST(2)))
	{
		PWSTR server = NULL;
		PFILE_INFO_3 info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			
			DWORD id = SvIV(ST(1));

			// clear hash
			HV_CLEAR(fileInfo);

			if(!LastError(NetFileGetInfo((PSTR)server, id, 3, (PBYTE*)&info)))
			{
				// store file properties
				H_STORE_INT(fileInfo, "id", info->fi3_id);
				H_STORE_INT(fileInfo, "permissions", info->fi3_permissions);
				H_STORE_INT(fileInfo, "num_locks", info->fi3_num_locks);
				H_STORE_WSTR(fileInfo, "pathname", (PWSTR)info->fi3_pathname);
				H_STORE_WSTR(fileInfo, "username", (PWSTR)info->fi3_username);
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
		croak("Usage: Win32::Lanman::NetFileGetInfo($server, $fileid, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// closes a file handle on a server
//
// param:  server - computer to execute the command
//				 fileid	- a file id supplied by NetFileEnum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetFileClose)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			
			DWORD id = SvIV(ST(1));

			LastError(NetFileClose((PSTR)server, id));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetFileClose($server, $fileid)\n");
	
	RETURNRESULT(LastError() == 0);
}


