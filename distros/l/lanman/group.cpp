#define WIN32_LEAN_AND_MEAN


#ifndef __GROUP_CPP
#define __GROUP_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "group.h"
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
// creates a new local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//				 comment - optional group comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items >= 2 && items <= 3)
	{
		PWSTR server = NULL, group = NULL, comment = NULL;

		__try
		{
			// change server, group and comment to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));
			comment = items == 3 ? S2W(SvPV(ST(2), PL_na)) : NULL;
			LOCALGROUP_INFO_1 info = {group, comment};

			LastError(NetLocalGroupAdd(server, 1, (PBYTE)&info, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		FreeStr(comment);
	} // if(items >= 2 && items <= 3)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupAdd($server, $group[, $comment])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// adds users sid to a local group
//
// param:  server - computer to execute the command
//         group  - local group name
//         sid		- users sid to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAddMember)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR server = NULL, group = NULL;
		PSID sid = SvPV(ST(2), PL_na);
	
		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			LastError(NetLocalGroupAddMember(server, group, sid));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupAddMember($server, $group, $sid)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// adds users or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAddMembers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *members = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(members, ST(2)))
	{
		int numMembers = AV_LEN(members) + 1;

		// if there are no members in the array do nothing
		if(numMembers <= 0)
			RETURNRESULT(1);

		PLOCALGROUP_MEMBERS_INFO_3 info = NULL;
		PWSTR server = NULL, group = NULL;

		__try
		{
			// store group members
			info = 
				(PLOCALGROUP_MEMBERS_INFO_3)NewMem(sizeof(LOCALGROUP_MEMBERS_INFO_3) * numMembers);

			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			for(int count = 0; count < numMembers; count++)
				info[count].lgrmi3_domainandname = A_FETCH_WSTR(members, count);

			LastError(NetLocalGroupAddMembers(server, group, 3, (PBYTE)info, numMembers));

			for(count = 0; count < numMembers; count++)
				FreeStr(info[count].lgrmi3_domainandname);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(info);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupAddMembers($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// adds users or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAddMembersBySid)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *members = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(members, ST(2)))
	{
		int numMembers = AV_LEN(members) + 1;

		// if there are no members in the array do nothing
		if(numMembers <= 0)
			RETURNRESULT(1);

		PLOCALGROUP_MEMBERS_INFO_0 info = NULL;
		PWSTR server = NULL, group = NULL;

		__try
		{
			// store group members
			info = 
				(PLOCALGROUP_MEMBERS_INFO_0)NewMem(sizeof(LOCALGROUP_MEMBERS_INFO_0) * numMembers);

			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			for(int count = 0; count < numMembers; count++)
				info[count].lgrmi0_sid = A_FETCH_STR(members, count);

			LastError(NetLocalGroupAddMembers(server, group, 0, (PBYTE)info, numMembers));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(info);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupAddMembersBySid($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// deletes a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, group = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			LastError(NetLocalGroupDel(server, group));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupDel($server, $group)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes users sid from a local group
//
// param:  server - computer to execute the command
//         group  - local group name
//         sid		- users sid to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDelMember)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR server = NULL, group = NULL;
		PSID sid = SvPV(ST(2), PL_na);

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			LastError(NetLocalGroupDelMember(server, group, sid));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupDelMember($server, $group, $sid)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes users or global groups from a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDelMembers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *members = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(members, ST(2)))
	{
		int numMembers = AV_LEN(members) + 1;

		// if there are no members in the array do nothing
		if(numMembers <= 0)
			RETURNRESULT(1);

		PLOCALGROUP_MEMBERS_INFO_3 info = NULL;
		PWSTR server = NULL, group = NULL;

		__try
		{
			// store group members
			info = 
				(PLOCALGROUP_MEMBERS_INFO_3)NewMem(sizeof(LOCALGROUP_MEMBERS_INFO_3) * numMembers);

			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			for(int count = 0; count < numMembers; count++)
				info[count].lgrmi3_domainandname = A_FETCH_WSTR(members, count);

			LastError(NetLocalGroupDelMembers(server, group, 3, (PBYTE)info, numMembers));

			for(count = 0; count < numMembers; count++)
				FreeStr(info[count].lgrmi3_domainandname);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(info);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupDelMembers($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes users or global groups from a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDelMembersBySid)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *members = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(members, ST(2)))
	{
		int numMembers = AV_LEN(members) + 1;

		// if there are no members in the array do nothing
		if(numMembers <= 0)
			RETURNRESULT(1);

		PLOCALGROUP_MEMBERS_INFO_0 info = NULL;
		PWSTR server = NULL, group = NULL;

		__try
		{
			// store group members
			info = 
				(PLOCALGROUP_MEMBERS_INFO_0)NewMem(sizeof(LOCALGROUP_MEMBERS_INFO_0) * numMembers);

			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			for(int count = 0; count < numMembers; count++)
				info[count].lgrmi0_sid = A_FETCH_STR(members, count);

			LastError(NetLocalGroupDelMembers(server, group, 0, (PBYTE)info, numMembers));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(info);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupDelMembersBySid($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all local groups
//
// param:  server - computer to execute the command
//         groups - gets all local groups
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *groups = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(groups, ST(1)))
	{
		// change server to unicode
		PWSTR server = NULL;

		PLOCALGROUP_INFO_1 info = NULL;
		DWORD buflen = 0x10000;
		DWORD entries = 0;
		DWORD total = 0;
		DWORD handle = 0;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear array
			AV_CLEAR(groups);

			// sometimes our buffer is to small to hold the info all together, so we have
			// to do it in more than one steps
			for( ; ; )
			{
				// clean buffer if already allocated
				CleanNetBuf(info);

				// get all local groups; if buflen is too small, increment it
				while((error = NetLocalGroupEnum(server, 1, (PBYTE*)&info, buflen, &entries, &total, 
																				 &handle)) == NERR_BufTooSmall &&	
							(!entries || entries != total))
				{
					buflen += 0x4000;

					continue;
				}
				
				if(!error || error == ERROR_MORE_DATA)
				{
					for(DWORD count = 0; count < entries; count++)
					{
						// store group members
						HV *properties = NewHV;

						H_STORE_WSTR(properties, "name", info[count].lgrpi1_name);
						H_STORE_WSTR(properties, "comment", info[count].lgrpi1_comment);

						A_STORE_REF(groups, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}

					// did we got all?
					if(!error || entries == total)
						break;
				}
				else
					RaiseFalseError(error);
			} // for( ; ; )
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
		croak("Usage: Win32::Lanman::NetLocalGroupEnum($server, \\@groups)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the name and comment of a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - gets the group name and comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PLOCALGROUP_INFO_1 grpInfo = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			// clear hash
			HV_CLEAR(info);

			if(!LastError(NetLocalGroupGetInfo(server, group, 1, (PBYTE*)&grpInfo)))
			{
				// store name and comment
				H_STORE_WSTR(info, "name", grpInfo->lgrpi1_name);
				H_STORE_WSTR(info, "comment", grpInfo->lgrpi1_comment);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		CleanNetBuf(grpInfo);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupGetInfo($server, $group, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets all user and global groups from a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//         members - gets all local group members
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupGetMembers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *users = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(users, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PLOCALGROUP_MEMBERS_INFO_2 members = NULL;
		DWORD level = 2;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			// clear array
			AV_CLEAR(users);

			DWORD buflen = 0x10000;
			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			// sometimes our buffer is to small to hold the info all together, so we have
			// to do it in more than one step
			for( ; ; )
			{
				// clean buffer if already allocated
				CleanNetBuf(members);

				// get all group members; if buflen is too small, increment it
				while((error = NetLocalGroupGetMembers(server, group, level, (PBYTE*)&members, 
																							 buflen, &entries, &total, 
																							 &handle)) == NERR_BufTooSmall &&
							(!entries || entries != total))
				{
					buflen += 0x4000;
					continue;
				}

				// try again at level 0 if the goup couldn't be found
				if(error == NERR_GroupNotFound)
					while((error = NetLocalGroupGetMembers(server, group, level = 0, (PBYTE*)&members, 
																								 buflen, &entries, &total, 
																								 &handle)) == NERR_BufTooSmall &&
								(!entries || entries != total))
					{
						buflen += 0x4000;
						continue;
					}

				if(!error || error == ERROR_MORE_DATA)
				{
					for(DWORD count = 0; count < entries; count++)
					{
						// store group members
						HV *properties = NewHV;

						if(level == 2)
						{
							H_STORE_PTR(properties, "sid", members[count].lgrmi2_sid, 
													GetLengthSid(members[count].lgrmi2_sid));
							H_STORE_WSTR(properties, "domainandname", members[count].lgrmi2_domainandname);
							H_STORE_INT(properties, "sidusage", members[count].lgrmi2_sidusage);
						}
						else
							H_STORE_PTR(properties, "sid", ((PLOCALGROUP_MEMBERS_INFO_0)members)[count].lgrmi0_sid, 
													GetLengthSid(((PLOCALGROUP_MEMBERS_INFO_0)members)[count].lgrmi0_sid));

						A_STORE_REF(users, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}

					// did we got all?
					if(!error || entries == total)
						break;
				}
				else
					RaiseFalseError(error);
			} // for( ; ; )
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(members);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupGetMembers($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the name and/or comment of a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - group properties to set (if you specify a name in info,
//									 the group will be renamed)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		LOCALGROUP_INFO_0 grpInfo0 = { NULL };
		LOCALGROUP_INFO_1002 grpInfo1002 = { NULL };

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));
			
			grpInfo0.lgrpi0_name = H_FETCH_WSTR(info, "name");
			grpInfo1002.lgrpi1002_comment = H_FETCH_WSTR(info, "comment");

			if(grpInfo1002.lgrpi1002_comment && *grpInfo1002.lgrpi1002_comment)
				LastError(NetLocalGroupSetInfo(server, group, 1002, (PBYTE)&grpInfo1002, NULL));

			if(!LastError() && grpInfo0.lgrpi0_name && *grpInfo0.lgrpi0_name)
				LastError(NetLocalGroupSetInfo(server, group, 0, (PBYTE)&grpInfo0, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		FreeStr(grpInfo0.lgrpi0_name);
		FreeStr(grpInfo1002.lgrpi1002_comment);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupSetInfo($server, $group, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets user or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//         members - members to set to the local group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupSetMembers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *users = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(users, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PLOCALGROUP_MEMBERS_INFO_3 members = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			int numMembers = AV_LEN(users) + 1;
			members = 
				(PLOCALGROUP_MEMBERS_INFO_3)NewMem(sizeof(LOCALGROUP_MEMBERS_INFO_3) * numMembers);

			for(int count = 0; count < numMembers; count++)
				members[count].lgrmi3_domainandname = A_FETCH_WSTR(users, count);
			
			LastError(NetLocalGroupSetMembers(server, group, 3, (PBYTE)members, numMembers));

			for(count = 0; count < numMembers; count++)
				FreeStr(members[count].lgrmi3_domainandname);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(members);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupSetMembers($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets user or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//         members - members to set to the local group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupSetMembersBySid)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *users = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(users, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PLOCALGROUP_MEMBERS_INFO_0 members = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			int numMembers = AV_LEN(users) + 1;
			members = 
				(PLOCALGROUP_MEMBERS_INFO_0)NewMem(sizeof(LOCALGROUP_MEMBERS_INFO_0) * numMembers);

			for(int count = 0; count < numMembers; count++)
				members[count].lgrmi0_sid = A_FETCH_STR(users, count);
			
			LastError(NetLocalGroupSetMembers(server, group, 0, (PBYTE)members, numMembers));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(members);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetLocalGroupSetMembersBySid($server, $group, \\@members)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// creates a new global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//				 comment - optional group comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items >= 2 && items <= 3)
	{
		PWSTR server = NULL, group = NULL, comment = NULL;
		
		__try
		{
			// change server, group and comment to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));
			comment = items == 3 ? S2W(SvPV(ST(2), PL_na)) : NULL;

			GROUP_INFO_1 info = {group, comment};

			LastError(NetGroupAdd(server, 1, (PBYTE)&info, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		FreeStr(comment);
	} // if(items >= 2 && items <= 3)
	else
		croak("Usage: Win32::Lanman::NetGroupAdd($server, $group[, $comment])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// adds a user to a global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//         user		 - user to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupAddUser)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR server = NULL, group = NULL, user = NULL;

		__try
		{
			// change server, group and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));
			user = S2W(SvPV(ST(2), PL_na));

			LastError(NetGroupAddUser(server, group, user));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		FreeStr(user);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetGroupAddUser($server, $group, $user)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// deletes a global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, group = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			LastError(NetGroupDel(server, group));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetGroupDel($server, $group)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes a user from a global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//         user		 - user to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupDelUser)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PWSTR server = NULL, group = NULL, user = NULL;

		__try
		{
			// change server, group and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));
			user = S2W(SvPV(ST(2), PL_na));

			LastError(NetGroupDelUser(server, group, user));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		FreeStr(user);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetGroupDelUser($server, $group, $user)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all global groups
//
// param:  server - computer to execute the command
//         groups - gets all global groups
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *groups = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(groups, ST(1)))
	{
		// change server to unicode
		PWSTR server = NULL;

		// clear array
		AV_CLEAR(groups);

		PGROUP_INFO_2 info = NULL;
		DWORD buflen = 0x10000;
		DWORD entries = 0;
		DWORD total = 0;
		DWORD handle = 0;

		__try
		{
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// sometimes our buffer is to small to hold the info all together, so we have
			// to do it in more than one steps
			for( ; ; )
			{
				// clean buffer if already allocated
				CleanNetBuf(info);

				// get all global groups; if buflen is too small, increment it
				while((error = NetGroupEnum(server, 2, (PBYTE*)&info, buflen, &entries, &total, 
																		&handle)) == NERR_BufTooSmall &&	
							(!entries || entries != total))
				{
					buflen += 0x4000;
					continue;
				}
				
				if(!error || error == ERROR_MORE_DATA)
				{
					for(DWORD count = 0; count < entries; count++)
					{
						// store group members
						HV *properties = NewHV;

						H_STORE_WSTR(properties, "name", info[count].grpi2_name);
						H_STORE_WSTR(properties, "comment", info[count].grpi2_comment);
						H_STORE_INT(properties, "group_id", info[count].grpi2_group_id);
						H_STORE_INT(properties, "attributes", info[count].grpi2_attributes);

						A_STORE_REF(groups, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}

					// did we got all
					if(!error || entries == total)
						break;
				}
				else
					RaiseFalseError(error);
			} // for( ; ; )
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
		croak("Usage: Win32::Lanman::NetGroupEnum($server, \\@groups)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the name and comment of a global group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - gets the group name and comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PGROUP_INFO_2 grpInfo = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			// clear info
			HV_CLEAR(info);

			if(!LastError(NetGroupGetInfo(server, group, 2, (PBYTE*)&grpInfo)))
			{
				// store name and comment
				H_STORE_WSTR(info, "name", grpInfo->grpi2_name);
				H_STORE_WSTR(info, "comment", grpInfo->grpi2_comment);
				H_STORE_INT(info, "group_id", grpInfo->grpi2_group_id);
				H_STORE_INT(info, "attributes", grpInfo->grpi2_attributes);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		FreeStr(group);
		CleanNetBuf(grpInfo);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetGroupGetInfo($server, $group, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets all users of a global group
//
// param:  server - computer to execute the command
//         group  - group name
//         users  - gets all local group members
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupGetUsers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *users = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(users, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PGROUP_USERS_INFO_1 members = NULL;
		DWORD buflen = 0x10000;
		DWORD entries = 0;
		DWORD total = 0;
		DWORD handle = 0;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			// clear array
			AV_CLEAR(users);

			// sometimes our buffer is to small to hold the info all together, so we have
			// to do it in more than one step
			for( ; ; )
			{
				// clean buffer if already allocated
				CleanNetBuf(members);

				// get all group members; if buflen is too small, increment it
				while((error = NetGroupGetUsers(server, group, 1, (PBYTE*)&members, buflen, 
																				&entries, &total, &handle)) == NERR_BufTooSmall &&
							(!entries || entries != total))
				{
					buflen += 0x4000;
					continue;
				}

				if(!error || error == ERROR_MORE_DATA)
				{
					for(DWORD count = 0; count < entries; count++)
					{
						// store group members
						HV *properties = NewHV;

						H_STORE_WSTR(properties, "name", members[count].grui1_name);
						H_STORE_INT(properties, "attributes", members[count].grui1_attributes);

						A_STORE_REF(users, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}

					// did we got all
					if(!error || entries == total)
						break;
				}
				else
					RaiseFalseError(error);
			} // for( ; ; )
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(members);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetGroupGetUsers($server, $group, \\@users)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the name and/or comment of a global group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - group properties to set (if you specify a name in info,
//									 the group will be renamed)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		GROUP_INFO_0 grpInfo0 = { NULL };
		GROUP_INFO_1002 grpInfo1002 = { NULL };

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			grpInfo0.grpi0_name = H_FETCH_WSTR(info, "name");
			grpInfo1002.grpi1002_comment = H_FETCH_WSTR(info, "comment");

			if(grpInfo1002.grpi1002_comment && *grpInfo1002.grpi1002_comment)
				LastError(NetGroupSetInfo(server, group, 1002, (PBYTE)&grpInfo1002, NULL));

			if(!LastError() && grpInfo0.grpi0_name && *grpInfo0.grpi0_name)
				LastError(NetGroupSetInfo(server, group, 0, (PBYTE)&grpInfo0, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(group);
		FreeStr(grpInfo0.grpi0_name);
		FreeStr(grpInfo1002.grpi1002_comment);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetGroupSetInfo($server, $group, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets users to a global group
//
// param:  server  - computer to execute the command
//         group   - group name
//         users	 - users to set to the global group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupSetUsers)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *users = NULL;

	if(items == 3 && CHK_ASSIGN_AREF(users, ST(2)))
	{
		PWSTR server = NULL, group = NULL;
		PGROUP_USERS_INFO_0 members = NULL;

		__try
		{
			// change server and group to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			group = S2W(SvPV(ST(1), PL_na));

			int numMembers = AV_LEN(users) + 1;
			members = 
				(PGROUP_USERS_INFO_0)NewMem(sizeof(GROUP_USERS_INFO_0) * numMembers);

			for(int count = 0; count < numMembers; count++)
				members[count].grui0_name = A_FETCH_WSTR(users, count);
			
			LastError(NetGroupSetUsers(server, group, 0, (PBYTE)members, numMembers));

			for(count = 0; count < numMembers; count++)
				CleanPtr(members[count].grui0_name);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(members);
		FreeStr(server);
		FreeStr(group);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetGroupSetUsers($server, $group, \\@users)\n");
	
	RETURNRESULT(LastError() == 0);
}



