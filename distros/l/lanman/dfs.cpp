#define WIN32_LEAN_AND_MEAN


#ifndef __DFS_CPP
#define __DFS_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <lmdfs.h>

 
#include "dfs.h"
#include "addloader.h"
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
// adds a new dfs directory
//
// param:  entryPath - directory in the dfs root to use as junction to 
//										 server\share
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//				 comment	 - optional comment
//				 flags		 - optional flags (DFS_ADD_VOLUME or DFS_RESTORE_VOLUME)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items >= 3 && items <= 5)
	{
		PWSTR entryPath = NULL;
		PWSTR server = NULL;
		PWSTR share = NULL;
		PWSTR comment = NULL;
		DWORD flags = items == 5 ? SvIV(ST(4)) : 0;

		__try
		{
			// change dfsroot, server, share and comment to unicode
			entryPath = ServerAsUnicode(SvPV(ST(0), PL_na));
			server = S2W(SvPV(ST(1), PL_na));
			share = S2W(SvPV(ST(2), PL_na));
			comment = items >=  4 ? S2W(SvPV(ST(3), PL_na)) : NULL;
		
			LastError(NetDfsAdd(entryPath, server, share, comment, flags));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(entryPath);
		FreeStr(server);
		FreeStr(share);
		FreeStr(comment);
	} // if(items >= 3 && items <= 5)
	else
		croak("Usage: Win32::Lanman::NetDfsAdd($entrypath, $server, $share[, $comment[, $flags]])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all dfs information on a dfs server
//
// param:  server	- dfs server name
//         dfs		- array to store the information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *dfs = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(dfs, ST(1)))
	{
		// change server, group and comment to unicode
		PWSTR server = NULL;
		PDFS_INFO_3 info = NULL;

		__try
		{
			// change server, group and comment to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear array
			AV_CLEAR(dfs);

			DWORD numEntries = 0, handle = 0;

			LastError(NetDfsEnum(server, 3, -1, (PBYTE*)&info, &numEntries, &handle));

			for(DWORD count = 0; count < numEntries; count++)
			{
				// store members of dfs struct
				HV *properties = NewHV;
					
				// store path, comment and state
				H_STORE_WSTR(properties, "entrypath", info[count].EntryPath);
				H_STORE_WSTR(properties, "comment", info[count].Comment);
				H_STORE_INT(properties, "state", info[count].State);

				// store storages
				if(info[count].NumberOfStorages)
				{
					// storages are stored in an array reference
					AV *storage = NewAV;

					for(DWORD cnt = 0; cnt < info[count].NumberOfStorages; cnt++)
					{
						HV *storageItem = NewHV;

						H_STORE_WSTR(storageItem, "servername", info[count].Storage[cnt].ServerName);
						H_STORE_WSTR(storageItem, "sharename", info[count].Storage[cnt].ShareName);
						H_STORE_INT(storageItem, "state", info[count].Storage[cnt].State);

						// store the new entry
						A_STORE_REF(storage, storageItem);

						// decrement reference count
						SvREFCNT_dec(storageItem);
					}
					
					H_STORE_REF(properties, "storage", storage);

					// decrement reference count
					SvREFCNT_dec(storage);
				}

				// store the new entry
				A_STORE_REF(dfs, properties);

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
		FreeStr(server);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetDfsEnum($server, \\@dfs)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets information about a dfs
//
// param:  entryPath - directory in the dfs root
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//         dfs			 - hash to store the information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; if you 
//				 interested in information about a specific storage, specify
//				 the server and share name; if you want information about all 
//				 storages in a volume, leave server and share empty
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *dfs = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(dfs, ST(3)))
	{
		PWSTR entryPath = NULL;
		PWSTR server = NULL;
		PWSTR share = NULL;
		PDFS_INFO_3 info = NULL;

		__try
		{
			// change dfsroot, server and share to unicode
			entryPath = S2W(SvPV(ST(0), PL_na));
			server = ServerAsUnicode(SvPV(ST(1), PL_na));
			share = S2W(SvPV(ST(2), PL_na));

			// clear hash
			HV_CLEAR(dfs);

			if(!LastError(NetDfsGetInfo(entryPath, server, share, 3, (PBYTE*)&info)))
			{
				// store members of dfs struct
				H_STORE_WSTR(dfs, "entrypath", info->EntryPath);
				H_STORE_WSTR(dfs, "comment", info->Comment);
				H_STORE_INT(dfs, "state", info->State);

				// store storages
				if(info->NumberOfStorages)
				{
					// storages are stored in an array reference
					AV *storage = NewAV;

					for(DWORD count = 0; count < info->NumberOfStorages; count++)
					{
						HV *storageItem = NewHV;

						H_STORE_WSTR(storageItem, "servername", info->Storage[count].ServerName);
						H_STORE_WSTR(storageItem, "sharename", info->Storage[count].ShareName);
						H_STORE_INT(storageItem, "state", info->Storage[count].State);

						// push the new entry
						A_STORE_REF(storage, storageItem);

						// decrement reference count
						SvREFCNT_dec(storageItem);
					}

					H_STORE_REF(dfs, "storage", storage);

					// decrement reference count
					SvREFCNT_dec(storage);
				}
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(info);
		FreeStr(entryPath);
		FreeStr(server);
		FreeStr(share);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetDfsGetInfo($entrypath, $server, $share, \\%%dfs)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes a volume or storage space from the dfs directory; when applied to the
// latest storage in a volume, removes the volume from the dfs
//
// param:  entryPath - directory in the dfs root used as junction to 
//										 server\share
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemove)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR entryPath = NULL;
		PWSTR server = NULL;
		PWSTR share = NULL;

		__try
		{
			// change dfsroot, server and share to unicode
			entryPath = S2W(SvPV(ST(0), PL_na));
			
			// in contrast with the msdn documentation, the call fails if the server name begins with 
			// two backslashes; this seems to be a bug, so we need to avoid the backslashes in the
			// server name
			//server = ServerAsUnicode(SvPV(ST(1), PL_na));
			server = ServerAsUnicodeWithoutBackslashes(SvPV(ST(1), PL_na));
			share = S2W(SvPV(ST(2), PL_na));
			
			LastError(NetDfsRemove(entryPath, server, share));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(entryPath);
		FreeStr(server);
		FreeStr(share);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetDfsRemove($entrypath, $server, $share)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets information about a dfs
//
// param:  entryPath - directory in the dfs root
//				 server		 - computer name exporting the storage
//         share     - share name exporting the storage
//         dfs			 - hash to set the information 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; if you 
//				 interested to set information about a specific storage, specify
//				 the server and share name; if you set want information about all 
//				 storages in a volume, leave server and share empty; currently, 
//				 you can only set the comment
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *dfs = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(dfs, ST(3)))
	{
		// change dfsroot, server and share to unicode
		PWSTR entryPath = NULL;
		PWSTR server = NULL;
		PWSTR share = NULL;

		DFS_INFO_100 info = { NULL };

		__try
		{
			// change dfsroot, server and share to unicode
			entryPath = S2W(SvPV(ST(0), PL_na));
			server = ServerAsUnicode(SvPV(ST(1), PL_na));
			share = S2W(SvPV(ST(2), PL_na));

			info.Comment = H_FETCH_WSTR(dfs, "comment");
			
			if(info.Comment && *info.Comment)
				LastError(NetDfsSetInfo(entryPath, server, share, 100, (PBYTE)&info));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(entryPath);
		FreeStr(server);
		FreeStr(share);
		FreeStr(info.Comment);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetDfsSetInfo($entrypath, $server, $share, \\%%dfs)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// renames a dfs directory
//
// param:  oldEntryPath - current dfs directory
//				 newEntryPath - new dfs directory name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; it seems this
//				 call is not supported in NT4 (you will get error code 50)
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRename)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *dfs = NULL;

	if(items == 2)
	{
		// change dfsroot, server and share to unicode
		PWSTR oldEntryPath = NULL;
		PWSTR newEntryPath = NULL;

		__try
		{
			// change dfsroot, server and share to unicode
			oldEntryPath = S2W(SvPV(ST(0), PL_na));
			newEntryPath = S2W(SvPV(ST(1), PL_na));

			LastError(NetDfsRename(oldEntryPath, newEntryPath));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(oldEntryPath);
		FreeStr(newEntryPath);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetDfsRename($oldentrypath, $newentrypath)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// moves a dfs volume
//
// param:  oldEntryPath - current dfs directory
//				 newEntryPath - new dfs directory name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; it seems this
//				 call is not supported in NT4 (you will get error code 50)
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsMove)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *dfs = NULL;

	if(items == 2)
	{
		// change dfsroot, server and share to unicode
		PWSTR oldEntryPath = NULL;
		PWSTR newEntryPath = NULL;

		__try
		{
			// change dfsroot, server and share to unicode
			oldEntryPath = S2W(SvPV(ST(0), PL_na));
			newEntryPath = S2W(SvPV(ST(1), PL_na));

			LastError(NetDfsMove(oldEntryPath, newEntryPath));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(oldEntryPath);
		FreeStr(newEntryPath);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetDfsMove($oldentrypath, $newentrypath)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// creates the root of a new domain-based Dfs implementation; if the root 
// already exists, the function adds (joins) the specified server and share 
// to the root
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that will host the root
//				 ftDfs			- name of the dfs root to create or join
//				 comment		- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAddFtRoot)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3 || items == 4)
	{
		PWSTR server = NULL, root = NULL, ftDfs = NULL, comment = NULL;

		__try
		{
			// change server, root, dfs name and comment to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			root = S2W(SvPV(ST(1), PL_na));
			ftDfs = S2W(SvPV(ST(2), PL_na));
			comment = items == 4 ? S2W(SvPV(ST(3), PL_na)) : NULL;

			// return the library error if the library isn't loaded correctly
			if(!NetDfsAddFtRootCall)
				RaiseFalseError(NetApi32LibError);

			// create the dfs root
			LastError(NetDfsAddFtRootCall(server, root, ftDfs, comment, 0));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(root);
		CleanPtr(ftDfs);
		CleanPtr(comment);
	} // if(items == 3 || ...)
	else
		croak("Usage: Win32::Lanman::NetDfsAddFtRoot($server, $rootshare, $ftdfs [, "
																								"$comment])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes the server and share at the root of a domain-based dfs
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that hosts the root
//				 ftdfs			- name of the domain based dfs root
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemoveFtRoot)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR server = NULL, root = NULL, ftDfs = NULL;

		__try
		{
			// change server, root and ftDfs to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			root = S2W(SvPV(ST(1), PL_na));
			ftDfs = S2W(SvPV(ST(2), PL_na));

			// return the library error if the library isn't loaded correctly
			if(!NetDfsRemoveFtRootCall)
				RaiseFalseError(NetApi32LibError);

			// remove the dfs root
			LastError(NetDfsRemoveFtRootCall(server, root, ftDfs, 0));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(root);
		CleanPtr(ftDfs);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetDfsRemoveFtRoot($server, $rootshare, $ftdfs)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes the specified server and share from a domain-based dfs root, even if 
// the server is offline
//
// param:  domain			- domain name
//				 server			- computer to execute the command
//				 rootshare	- name of the share that hosts the root
//				 ftdfs			- name of the domain based dfs root
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemoveFtRootForced)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 4)
	{
		PWSTR domain = NULL, server = NULL, root = NULL, ftDfs = NULL;

		__try
		{
			// change domain, server, root and ftDfs to unicode
			domain = S2W(SvPV(ST(0), PL_na));
			server = ServerAsUnicode(SvPV(ST(1), PL_na));
			root = S2W(SvPV(ST(2), PL_na));
			ftDfs = S2W(SvPV(ST(3), PL_na));

			// return the library error if the library isn't loaded correctly
			if(!NetDfsRemoveFtRootForcedCall)
				RaiseFalseError(NetApi32LibError);

			// remove the dfs root
			LastError(NetDfsRemoveFtRootForcedCall(domain, server, root, ftDfs, 0));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(domain);
		CleanPtr(server);
		CleanPtr(root);
		CleanPtr(ftDfs);
	} // if(items == 4)
	else
		croak("Usage: Win32::Lanman::NetDfsRemoveFtRootForced($domain, $server, $rootshare, $ftdfs)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// creates the root for a new stand-alone dfs implementation
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that will host the root
//				 comment		- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAddStdRoot)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PWSTR server = NULL, root = NULL, comment = NULL;

		__try
		{
			// change server, root and comment to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			root = S2W(SvPV(ST(1), PL_na));
			comment = items == 3 ? S2W(SvPV(ST(2), PL_na)) : NULL;

			// return the library error if the library isn't loaded correctly
			if(!NetDfsAddStdRootCall)
				RaiseFalseError(NetApi32LibError);

			// create the dfs root
			LastError(NetDfsAddStdRootCall(server, root, comment, 0));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(root);
		CleanPtr(comment);
	} // if(items == 2 || ...)
	else
		croak("Usage: Win32::Lanman::NetDfsAddStdRoot($server, $rootshare [, $comment])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// creates the root for a new stand-alone dfs implementation allowing an 
// offline share to host the Dfs root
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that will host the root
//				 store			- path to the share that will host the new dfs root
//				 comment		- comment associated with the dfs link
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsAddStdRootForced)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3 || items == 4)
	{
		PWSTR server = NULL, root = NULL, store = NULL, comment = NULL;

		__try
		{
			// change server, root, store and comment to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			root = S2W(SvPV(ST(1), PL_na));
			store = S2W(SvPV(ST(2), PL_na));
			comment = items == 3 ? S2W(SvPV(ST(2), PL_na)) : NULL;

			// return the library error if the library isn't loaded correctly
			if(!NetDfsAddStdRootForcedCall)
				RaiseFalseError(NetApi32LibError);

			// create the dfs root
			LastError(NetDfsAddStdRootForcedCall(server, root, comment, store));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(root);
		CleanPtr(store);
		CleanPtr(comment);
	} // if(items == 3 || ...)
	else
		croak("Usage: Win32::Lanman::NetDfsAddStdRootForced($server, $rootshare, $store [, "
																											 "$comment])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes the server and share at the root of a stand-alone dfs
//
// param:  server			- computer to execute the command
//				 rootshare	- name of the share that hosts the root
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsRemoveStdRoot)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, root = NULL;

		__try
		{
			// change server and root to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			root = S2W(SvPV(ST(1), PL_na));

			// return the library error if the library isn't loaded correctly
			if(!NetDfsRemoveStdRootCall)
				RaiseFalseError(NetApi32LibError);

			// remove the dfs root
			LastError(NetDfsRemoveStdRootCall(server, root, 0));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(root);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetDfsRemoveStdRoot($server, $rootshare)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// restarts the dfs service
//
// param:  server		- computer to execute the command
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsManagerInitialize)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 1)
	{
		PWSTR server = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// return the library error if the library isn't loaded correctly
			if(!NetDfsManagerInitializeCall)
				RaiseFalseError(NetApi32LibError);

			// restart the dfs service
			LastError(NetDfsManagerInitializeCall(server, 0));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::NetDfsManagerInitialize($server)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a dfs link in the named Dfs root
//
// param:  entrypath	- unc path of a dfs link in a dfs root (dfs\share\link or
//											domain\dfs\link)
//				 server			- optional name of the host server that the link 
//											references
//				 share			- optional share name on the host server that the link 
//											references
//				 info				- retrieves the client information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsGetClientInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(info, ST(3)))
	{
		PWSTR path = NULL, server = NULL, share = NULL;
		PDFS_INFO_4 clientInfo = NULL;

		__try
		{
			// change server to unicode
			path = ServerAsUnicode(SvPV(ST(0), PL_na));
			server = ServerAsUnicode(SvPV(ST(1), PL_na));
			share = S2W(SvPV(ST(2), PL_na));

			// clear hash
			HV_CLEAR(info);

			// return the library error if the library isn't loaded correctly
			if(!NetDfsGetClientInfoCall)
				RaiseFalseError(NetApi32LibError);

			// get client info
			LastError(NetDfsGetClientInfoCall(path, server, share, 4, (PBYTE*)&clientInfo));

			// store infos
			if(!LastError())
			{
				H_STORE_WSTR(info, "entrypath", clientInfo->EntryPath);
				H_STORE_WSTR(info, "comment", clientInfo->Comment);
				H_STORE_INT(info, "state", clientInfo->State);
				H_STORE_INT(info, "timeout", clientInfo->Timeout);
				H_STORE_PTR(info, "guid", &clientInfo->Guid, sizeof(GUID));

				AV *storages = NewAV;

				for(DWORD count = 0; count < clientInfo->NumberOfStorages; count++)
				{
					HV *properties = NewHV;

					H_STORE_INT(properties, "state", clientInfo->Storage[count].State);
					H_STORE_WSTR(properties, "servername", clientInfo->Storage[count].ServerName);
					H_STORE_WSTR(properties, "sharename", clientInfo->Storage[count].ShareName);

					A_STORE_REF(storages, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}

				H_STORE_REF(info, "storage", storages);

				// decrement reference count
				SvREFCNT_dec(storages);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(path);
		CleanPtr(server);
		CleanPtr(share);
		CleanNetBuf(clientInfo);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetDfsGetClientInfo($entrypath, $server, $share, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// associates information with a dfs link in the named dfs root
//
// param:  entrypath	- unc path of a dfs link in a dfs root (dfs\share\link or
//											domain\dfs\link)
//				 server			- optional name of the host server that the link 
//											references
//				 share			- optional share name on the host server that the link 
//											references
//				 info				- contains the information to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsSetClientInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(info, ST(3)))
	{
		PWSTR path = NULL, server = NULL, share = NULL;
		DFS_INFO_101 info101 = { 0 };
		DFS_INFO_102 info102 = { 0 };

		__try
		{
			// change server to unicode
			path = ServerAsUnicode(SvPV(ST(0), PL_na));
			server = ServerAsUnicode(SvPV(ST(1), PL_na));
			share = S2W(SvPV(ST(2), PL_na));

			// return the library error if the library isn't loaded correctly
			if(!NetDfsSetClientInfoCall)
				RaiseFalseError(NetApi32LibError);

			// set client info
			if(H_EXISTS(info, "state"))
			{
				info101.State = H_FETCH_INT(info, "state");
				
				LastError(NetDfsSetClientInfoCall(path, server, share, 101, (PBYTE)&info101));
			}

			if(!LastError() && H_EXISTS(info, "timeout"))
			{
				info102.Timeout = H_FETCH_INT(info, "timeout");
				
				LastError(NetDfsSetClientInfoCall(path, server, share, 102, (PBYTE)&info102));
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(path);
		CleanPtr(server);
		CleanPtr(share);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetDfsSetClientInfo($entrypath, $server, $share, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about the dfs domain controller
//
// param:  server	- computer to execute the command
//				 info		- retrieves the information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetDfsGetDcAddress)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PWSTR server = NULL, ipAddress = NULL;
		BOOLEAN isRoot = FALSE;
		DWORD timeout = 0;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear hash
			HV_CLEAR(info);

			// return the library error if the library isn't loaded correctly
			if(!NetDfsGetDcAddressCall)
				RaiseFalseError(NetApi32LibError);

			// get dc info
			LastError(NetDfsGetDcAddressCall(server, &ipAddress, &isRoot, &timeout));

			if(!LastError())
			{
				H_STORE_WSTR(info, "ipaddress", ipAddress);
				H_STORE_INT(info, "isroot", isRoot);
				H_STORE_INT(info, "timeout", timeout);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanNetBuf(ipAddress);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetDfsGetDcAddress($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}

