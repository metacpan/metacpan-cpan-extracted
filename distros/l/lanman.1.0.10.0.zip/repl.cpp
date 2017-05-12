#define WIN32_LEAN_AND_MEAN


#ifndef __REPL_CPP
#define __REPL_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "repl.h"
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
// registers an existing directory in the export path to be replicated
//
// param:  server - computer to export the directory
//         info   - replication directory info to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PWSTR server = NULL;
		REPL_EDIR_INFO_1 replInfo = { NULL, 0, 0 };

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			replInfo.rped1_dirname = H_FETCH_WSTR(info, "dirname");
			replInfo.rped1_extent = H_FETCH_INT(info, "extent");
			replInfo.rped1_integrity = H_FETCH_INT(info, "integrity");

			LastError(NetReplExportDirAdd(server, 1, (PBYTE)&replInfo, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(replInfo.rped1_dirname);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirAdd($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes registration of a replicated directory
//
// param:  server		 - computer which exports the directory
//         directory - replication directory to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, directory = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			LastError(NetReplExportDirDel(server, directory));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirDel($server, $directory)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// lists the replicated directories in the export path
//
// param:  server			 - export computer
//         directories - directory array to enum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *directories = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(directories, ST(1)))
	{
		PWSTR server = NULL;
		PREPL_EDIR_INFO_2 replInfo = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear array
			AV_CLEAR(directories);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetReplExportDirEnum(server, 2, (PBYTE*)&replInfo, 0xffffffff,
																				 &entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store directory properties
					HV *properties = NewHV;

					H_STORE_WSTR(properties, "dirname", replInfo[count].rped2_dirname);
					H_STORE_INT(properties, "integrity", replInfo[count].rped2_integrity);
					H_STORE_INT(properties, "extent", replInfo[count].rped2_extent);
					H_STORE_INT(properties, "lockcount", replInfo[count].rped2_lockcount);
					H_STORE_INT(properties, "locktime", replInfo[count].rped2_locktime);

					A_STORE_REF(directories, properties);

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
		CleanNetBuf(replInfo);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirEnum($server, \\@directories)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves the control information of a replicated directory
//
// param:  server		 - export computer
//         directory - directory name
//				 info			 - hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, directory = NULL;
		PREPL_EDIR_INFO_2 replInfo = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			// clear hash
			HV_CLEAR(info);

			if(!LastError(NetReplExportDirGetInfo(server, directory, 2, (PBYTE*)&replInfo)))
			{
				// store directory properties
				H_STORE_WSTR(info, "dirname", replInfo->rped2_dirname);
				H_STORE_INT(info, "integrity", replInfo->rped2_integrity);
				H_STORE_INT(info, "extent", replInfo->rped2_extent);
				H_STORE_INT(info, "lockcount", replInfo->rped2_lockcount);
				H_STORE_INT(info, "locktime", replInfo->rped2_locktime);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
		CleanNetBuf(replInfo);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirGetInfo($server, $directory, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// locks a replicated directory 
//
// param:  server		 - export computer
//         directory - directory to add a lock
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirLock)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, directory = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			LastError(NetReplExportDirLock(server, directory));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirLock($server, $directory)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// modifies the control information of a replicated directory
//
// param:  server		 - export computer
//         directory - directory to add a lock
//				 info			 - info to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, directory = NULL;
		REPL_EDIR_INFO_1 replInfo = { NULL, 0, 0 };

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			replInfo.rped1_dirname = H_FETCH_WSTR(info, "dirname");
			replInfo.rped1_extent = H_FETCH_INT(info, "extent");
			replInfo.rped1_integrity = H_FETCH_INT(info, "integrity");

			LastError(NetReplExportDirSetInfo(server, directory, 1, (PBYTE)&replInfo, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
		FreeStr(replInfo.rped1_dirname);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirSetInfo($server, $directory, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// unlocks a replicated directory 
//
// param:  server			 - export computer
//         directory	 - directory to remove a lock
//				 forceUnlock - forces to set the lock counter to zero
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirUnlock)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PWSTR server = NULL, directory = NULL;
		
		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));
			
			DWORD forceUnlock = items == 3 ? SvIV(ST(2)) : REPL_UNLOCK_NOFORCE;

			LastError(NetReplExportDirUnlock(server, directory, forceUnlock));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		FreeStr(directory);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetReplExportDirUnlock($server, $directory, [$forceUnlock])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves configuration information for the Replicator service
//
// param:  server - computer to execute the command
//         info	  - hash to get information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PWSTR server = NULL;
		PREPL_INFO_0 replInfo = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
		
			// clear hash
			HV_CLEAR(info);

			if(!LastError(NetReplGetInfo(server, 0, (PBYTE*)&replInfo)))
			{
				// store directory properties
				H_STORE_INT(info, "role", replInfo->rp0_role);
				H_STORE_WSTR(info, "exportpath", replInfo->rp0_exportpath);
				H_STORE_WSTR(info, "exportlist", replInfo->rp0_exportlist);
				H_STORE_WSTR(info, "importpath", replInfo->rp0_importpath);
				H_STORE_WSTR(info, "importlist", replInfo->rp0_importlist);
				H_STORE_WSTR(info, "logonusername", replInfo->rp0_logonusername);
				H_STORE_INT(info, "interval", replInfo->rp0_interval);
				H_STORE_INT(info, "pulse", replInfo->rp0_pulse);
				H_STORE_INT(info, "guardtime", replInfo->rp0_guardtime);
				H_STORE_INT(info, "random", replInfo->rp0_random);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(replInfo);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplGetInfo($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// registers an existing directory in the import path to be replicated
//
// param:  server		 - computer to import the directory
//         directory - replication directory to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL;
		REPL_IDIR_INFO_0 replInfo = {	NULL };

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			replInfo.rpid0_dirname = S_FETCH_WSTR(ST(1));

			LastError(NetReplImportDirAdd(server, 0, (PBYTE)&replInfo, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(replInfo.rpid0_dirname);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplImportDirAdd($server, $directory)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes registration of a replicated directory
//
// param:  server		 - computer which imports the directory
//         directory - replication directory to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, directory = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			LastError(NetReplImportDirDel(server, directory));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetReplImportDirDel($server, $directory)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// lists the replicated directories in the import path
//
// param:  server			 - import computer
//         directories - directory array to enum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *directories = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(directories, ST(1)))
	{
		PWSTR server = NULL;
		PREPL_IDIR_INFO_1 replInfo = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear array
			AV_CLEAR(directories);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetReplImportDirEnum(server, 1, (PBYTE*)&replInfo, 0xffffffff,
																				 &entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store directory properties
					HV *properties = NewHV;

					H_STORE_WSTR(properties, "dirname", replInfo[count].rpid1_dirname);
					H_STORE_INT(properties, "state", replInfo[count].rpid1_state);
					H_STORE_WSTR(properties, "mastername", replInfo[count].rpid1_mastername);
					H_STORE_INT(properties, "last_update_time", replInfo[count].rpid1_last_update_time);
					H_STORE_INT(properties, "lockcount", replInfo[count].rpid1_lockcount);
					H_STORE_INT(properties, "locktime", replInfo[count].rpid1_locktime);

					A_STORE_REF(directories, properties);

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
		CleanNetBuf(replInfo);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplImportDirEnum($server, \\@directories)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves the control information of a replicated directory
//
// param:  server		 - import computer
//         directory - directory name
//				 info			 - hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, directory = NULL;
		PREPL_IDIR_INFO_1 replInfo = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			// clear hash
			HV_CLEAR(info);

			if(!LastError(NetReplImportDirGetInfo(server, directory, 1, (PBYTE*)&replInfo)))
			{
				// store directory properties
				H_STORE_WSTR(info, "dirname", replInfo->rpid1_dirname);
				H_STORE_INT(info, "state", replInfo->rpid1_state);
				H_STORE_WSTR(info, "mastername", replInfo->rpid1_mastername);
				H_STORE_INT(info, "last_update_time", replInfo->rpid1_last_update_time);
				H_STORE_INT(info, "lockcount", replInfo->rpid1_lockcount);
				H_STORE_INT(info, "locktime", replInfo->rpid1_locktime);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
		CleanNetBuf(replInfo);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplImportDirGetInfo($server, $directory, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// locks a replicated directory 
//
// param:  server		 - import computer
//         directory - directory to add a lock
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirLock)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, directory = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));

			LastError(NetReplImportDirLock(server, directory));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetReplImportDirLock($server, $directory)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// unlocks a replicated directory 
//
// param:  server			 - import computer
//         directory	 - directory to remove a lock
//				 forceUnlock - forces to set the lock counter to zero
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirUnlock)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PWSTR server = NULL, directory = NULL;

		__try
		{
			// change server and directory to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			directory = S2W(SvPV(ST(1), PL_na));
			
			DWORD forceUnlock = items == 3 ? SvIV(ST(2)) : REPL_UNLOCK_NOFORCE;

			LastError(NetReplImportDirUnlock(server, directory, forceUnlock));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(directory);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetReplImportDirUnlock($server, $directory, [$forceUnlock])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// modifies the Replicator service configuration information
//
// param:  server - computer to execute the command
//         info	  - hash to get information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PWSTR server = NULL;
		REPL_INFO_0 replInfo = { 0, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0 };

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			replInfo.rp0_role =	H_FETCH_INT(info, "role");
			replInfo.rp0_exportpath = H_FETCH_WSTR(info, "exportpath");
			replInfo.rp0_exportlist = H_FETCH_WSTR(info, "exportlist");
			replInfo.rp0_importpath = H_FETCH_WSTR(info, "importpath");
			replInfo.rp0_importlist = H_FETCH_WSTR(info, "importlist");
			replInfo.rp0_logonusername = H_FETCH_WSTR(info, "logonusername");
			replInfo.rp0_interval = H_FETCH_INT(info, "interval");
			replInfo.rp0_pulse = H_FETCH_INT(info, "pulse");
			replInfo.rp0_guardtime = H_FETCH_INT(info, "guardtime");
			replInfo.rp0_random = H_FETCH_INT(info, "random");

			LastError(NetReplSetInfo(server, 0, (PBYTE)&replInfo, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(replInfo.rp0_exportpath);
		FreeStr(replInfo.rp0_exportlist);
		FreeStr(replInfo.rp0_importpath);
		FreeStr(replInfo.rp0_importlist);
		FreeStr(replInfo.rp0_logonusername);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetReplSetInfo($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}

