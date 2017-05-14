#define WIN32_LEAN_AND_MEAN


#ifndef __USER_CPP
#define __USER_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "user.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// creates a new user
//
// param:  server - computer to execute the command
//         user   - user name and properties
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *user = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(user, ST(1)))
	{
		PWSTR server = NULL;
		USER_INFO_3 userInfo;
		
		memset(&userInfo, 0, sizeof(userInfo));

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			userInfo.usri3_name = H_FETCH_WSTR(user, "name");
			userInfo.usri3_password = H_FETCH_WSTR(user, "password");
			userInfo.usri3_password_age = 0;
			userInfo.usri3_priv = USER_PRIV_USER;
			userInfo.usri3_home_dir = H_FETCH_WSTR(user, "home_dir");
			userInfo.usri3_comment = H_FETCH_WSTR(user, "comment");
			userInfo.usri3_flags = UF_SCRIPT | H_FETCH_INT(user, "flags");
			userInfo.usri3_script_path = H_FETCH_WSTR(user, "script_path");
			userInfo.usri3_auth_flags = 0;
			userInfo.usri3_full_name = H_FETCH_WSTR(user, "full_name");
			userInfo.usri3_usr_comment = H_FETCH_WSTR(user, "usr_comment");
			userInfo.usri3_parms = H_FETCH_WSTR(user, "parms");
			userInfo.usri3_workstations = H_FETCH_WSTR(user, "workstations");
			userInfo.usri3_last_logon = 0;
			userInfo.usri3_last_logoff = 0;
			userInfo.usri3_acct_expires = H_FETCH_INT(user, "acct_expires");
			userInfo.usri3_max_storage = H_FETCH_INT(user, "max_storage");
			userInfo.usri3_units_per_week = 0; // units_per_week will be assigned below
			userInfo.usri3_logon_hours = NULL; // logon_hours will be assigned below
			userInfo.usri3_bad_pw_count = 0;
			userInfo.usri3_num_logons = 0;
			userInfo.usri3_logon_server = NULL;
			userInfo.usri3_country_code = H_FETCH_INT(user, "country_code");
			userInfo.usri3_code_page = H_FETCH_INT(user, "code_page");
			userInfo.usri3_user_id = 0;
			userInfo.usri3_primary_group_id = DOMAIN_GROUP_RID_USERS;
			userInfo.usri3_profile = H_FETCH_WSTR(user, "profile");
			userInfo.usri3_home_dir_drive = H_FETCH_WSTR(user, "home_dir_drive");
			userInfo.usri3_password_expired = H_FETCH_INT(user, "password_expired");

			if(userInfo.usri3_logon_hours = (PUCHAR)H_FETCH_PTR(user, "logon_hours", 
																													userInfo.usri3_units_per_week))
				userInfo.usri3_units_per_week <<= 3;

			LastError(NetUserAdd(server, 3, (PBYTE)&userInfo, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(userInfo.usri3_name);
		FreeStr(userInfo.usri3_password);
		FreeStr(userInfo.usri3_home_dir);
		FreeStr(userInfo.usri3_comment);
		FreeStr(userInfo.usri3_script_path);
		FreeStr(userInfo.usri3_full_name);
		FreeStr(userInfo.usri3_usr_comment);
		FreeStr(userInfo.usri3_parms);
		FreeStr(userInfo.usri3_workstations);
		FreeStr(userInfo.usri3_profile);
		FreeStr(userInfo.usri3_home_dir_drive);
		
		FreeStr(server);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserAdd($server, \\%%user)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// changes an user's password
//
// param:  domain			 - domain or computer to execute the command
//         user				 - user name
//				 oldpassword - users old password
//				 newpassword - users new password
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserChangePassword)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 4)
	{
		PWSTR domain = NULL, user = NULL, oldPassword = NULL, newPassword = NULL;

		__try
		{
			// change domain, user, oldPassword and newPassword to unicode
			domain = S2W(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));
			oldPassword = S2W(SvPV(ST(2), PL_na));
			newPassword = S2W(SvPV(ST(3), PL_na));

			LastError(NetUserChangePassword(domain, user, oldPassword, newPassword));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(domain);
		FreeStr(user);
		FreeStr(oldPassword);
		FreeStr(newPassword);
	} // if(items == 4)
	else
		croak("Usage: Win32::Lanman::NetUserChangePassword($domain, $user, $oldpassword, $newpassword)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// deletes an user
//
// param:  server			 - computer to execute the command
//         user				 - user name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, user = NULL;

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));

			LastError(NetUserDel(server, user));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		FreeStr(user);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetUserDel($server, $user)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// provides information about all user accounts on a server
//
// param:  server	- computer to execute the command
//         filter	- account type filter
//				 info		- array to store infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *userInfo = NULL;

	if(items == 3 &&  CHK_ASSIGN_AREF(userInfo, ST(2)))
	{
		PWSTR server = NULL;
		PUSER_INFO_3 info3 = NULL;
		PUSER_INFO_10 info10 = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			DWORD filter = SvIV(ST(1));

			// clear array
			AV_CLEAR(userInfo);

			DWORD level = 3;
			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			// get all user; if we get an access denied, we can call with level 10 only
			if(LastError(NetUserEnum(server, level, filter, (PBYTE*)&info3, 0xffffffff, 
															 &entries, &total, &handle)) == ERROR_ACCESS_DENIED)
				 LastError(NetUserEnum(server, level = 10, filter, (PBYTE*)&info10, 
															 0xffffffff, &entries, &total, &handle));
			
			if(!LastError())
			{
				for(DWORD count = 0; count < entries; count++)
				{
					// store user properties
					HV *properties = NewHV;

					if(level == 3)
					{
						H_STORE_WSTR(properties, "name", info3[count].usri3_name);
						H_STORE_WSTR(properties, "comment", info3[count].usri3_comment);
						H_STORE_WSTR(properties, "usr_comment", info3[count].usri3_usr_comment);
						H_STORE_WSTR(properties, "full_name", info3[count].usri3_full_name);

						H_STORE_INT(properties, "password_age", info3[count].usri3_password_age);
						H_STORE_INT(properties, "priv", info3[count].usri3_priv);
						H_STORE_WSTR(properties, "home_dir", info3[count].usri3_home_dir);
						H_STORE_INT(properties, "flags", info3[count].usri3_flags);
						H_STORE_WSTR(properties, "script_path", info3[count].usri3_script_path);
						H_STORE_INT(properties, "auth_flags", info3[count].usri3_auth_flags);
						H_STORE_WSTR(properties, "parms", info3[count].usri3_parms);
						H_STORE_WSTR(properties, "workstations", info3[count].usri3_workstations);
						H_STORE_INT(properties, "last_logon", info3[count].usri3_last_logon);
						H_STORE_INT(properties, "last_logoff", info3[count].usri3_last_logoff);
						H_STORE_INT(properties, "acct_expires", info3[count].usri3_acct_expires);
						H_STORE_INT(properties, "max_storage", info3[count].usri3_max_storage);
						H_STORE_INT(properties, "units_per_week", info3[count].usri3_units_per_week);
						
						if(info3[count].usri3_units_per_week && info3[count].usri3_logon_hours)
							H_STORE_PTR(properties, "logon_hours", info3[count].usri3_logon_hours,
													info3[count].usri3_units_per_week >> 3);

						H_STORE_INT(properties, "bad_pw_count", info3[count].usri3_bad_pw_count);
						H_STORE_INT(properties, "num_logons", info3[count].usri3_num_logons);
						H_STORE_WSTR(properties, "logon_server", info3[count].usri3_logon_server);
						H_STORE_INT(properties, "country_code", info3[count].usri3_country_code);
						H_STORE_INT(properties, "code_page", info3[count].usri3_code_page);
						H_STORE_INT(properties, "user_id", info3[count].usri3_user_id);
						H_STORE_INT(properties, "primary_group_id", info3[count].usri3_primary_group_id);
						H_STORE_WSTR(properties, "profile", info3[count].usri3_profile);
						H_STORE_WSTR(properties, "home_dir_drive", info3[count].usri3_home_dir_drive);
						H_STORE_INT(properties, "password_expired", info3[count].usri3_password_expired);
					}
					else
					{
						H_STORE_WSTR(properties, "name", info10[count].usri10_name);
						H_STORE_WSTR(properties, "comment", info10[count].usri10_comment);
						H_STORE_WSTR(properties, "usr_comment", info10[count].usri10_usr_comment);
						H_STORE_WSTR(properties, "full_name", info10[count].usri10_full_name);
					}

					A_STORE_REF(userInfo, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(info3);
		CleanNetBuf(info10);
		FreeStr(server);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserEnum($domain, $filter, \\@user)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves a list of global groups to which a user belongs
//
// param:  server	- computer to execute the command
//         user		- user name to search for in each group account
//				 groups	- array to store infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserGetGroups)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *groups = NULL;

	if(items == 3 &&  CHK_ASSIGN_AREF(groups, ST(2)))
	{
		PWSTR server = NULL, user = NULL;
		PGROUP_USERS_INFO_1 info = NULL;

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));

			// clear array
			AV_CLEAR(groups);

			DWORD entries = 0;
			DWORD total = 0;

			// get all groups
			if(!LastError(NetUserGetGroups(server, user, 1, (PBYTE*)&info, 0xffffffff, &entries, 
																		&total)))
			{
				for(DWORD count = 0; count < entries; count++)
				{
					// store user properties
					HV *properties = NewHV;

					H_STORE_WSTR(properties, "name", info[count].grui1_name);
					H_STORE_INT(properties, "attributes", info[count].grui1_attributes);

					A_STORE_REF(groups, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}
				
				CleanNetBuf(info);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(user);
		CleanNetBuf(info);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserGetGroups($server, $user, \\@groups)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a user account on a server
//
// param:  server	- computer to execute the command
//         user		- user name on which to return information
//				 info		- hash to store infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *userInfo = NULL;

	if(items == 3 &&  CHK_ASSIGN_HREF(userInfo, ST(2)))
	{
		PWSTR server = NULL, user = NULL;
		PUSER_INFO_3 info3 = NULL;
		PUSER_INFO_11 info11 = NULL;

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));

			// clear hash
			HV_CLEAR(userInfo);

			DWORD level = 3;

			// get user info; if we get an access denied, we can call with level 10 only
			if(LastError(NetUserGetInfo(server, user, level, 
																	(PBYTE*)&info3)) == ERROR_ACCESS_DENIED)
				LastError(NetUserGetInfo(server, user, level = 11, (PBYTE*)&info11));
			
			if(!LastError())
			{
				// store user properties

				if(level == 3)
				{
					H_STORE_WSTR(userInfo, "name", info3->usri3_name);
					H_STORE_WSTR(userInfo, "comment", info3->usri3_comment);
					H_STORE_WSTR(userInfo, "usr_comment", info3->usri3_usr_comment);
					H_STORE_WSTR(userInfo, "full_name", info3->usri3_full_name);
					H_STORE_INT(userInfo, "priv", info3->usri3_priv);
					H_STORE_INT(userInfo, "auth_flags", info3->usri3_auth_flags);
					H_STORE_INT(userInfo, "password_age", info3->usri3_password_age);
					H_STORE_WSTR(userInfo, "home_dir", info3->usri3_home_dir);
					H_STORE_PTR(userInfo, "parms", info3->usri3_parms, 
											(wcslen(info3->usri3_parms) + 1) * sizeof(WCHAR));
					H_STORE_INT(userInfo, "last_logon", info3->usri3_last_logon);
					H_STORE_INT(userInfo, "last_logoff", info3->usri3_last_logoff);
					H_STORE_INT(userInfo, "bad_pw_count", info3->usri3_bad_pw_count);
					H_STORE_INT(userInfo, "num_logons", info3->usri3_num_logons);
					H_STORE_WSTR(userInfo, "logon_server", info3->usri3_logon_server);
					H_STORE_INT(userInfo, "country_code", info3->usri3_country_code);
					H_STORE_WSTR(userInfo, "workstations", info3->usri3_workstations);
					H_STORE_INT(userInfo, "max_storage", info3->usri3_max_storage);
					H_STORE_INT(userInfo, "units_per_week", info3->usri3_units_per_week);
					H_STORE_INT(userInfo, "code_page", info3->usri3_code_page);

					if(info3->usri3_units_per_week && info3->usri3_logon_hours)
						H_STORE_PTR(userInfo, "logon_hours", info3->usri3_logon_hours,
												info3->usri3_units_per_week >> 3);

					H_STORE_INT(userInfo, "flags", info3->usri3_flags);
					H_STORE_WSTR(userInfo, "script_path", info3->usri3_script_path);
					H_STORE_INT(userInfo, "acct_expires", info3->usri3_acct_expires);
					H_STORE_INT(userInfo, "user_id", info3->usri3_user_id);
					H_STORE_INT(userInfo, "primary_group_id", info3->usri3_primary_group_id);
					H_STORE_WSTR(userInfo, "profile", info3->usri3_profile);
					H_STORE_WSTR(userInfo, "home_dir_drive", info3->usri3_home_dir_drive);
					H_STORE_INT(userInfo, "password_expired", info3->usri3_password_expired);
				}
				else
				{
					H_STORE_WSTR(userInfo, "name", info11->usri11_name);
					H_STORE_WSTR(userInfo, "comment", info11->usri11_comment);
					H_STORE_WSTR(userInfo, "usr_comment", info11->usri11_usr_comment);
					H_STORE_WSTR(userInfo, "full_name", info11->usri11_full_name);
					H_STORE_INT(userInfo, "priv", info11->usri11_priv);
					H_STORE_INT(userInfo, "auth_flags", info11->usri11_auth_flags);
					H_STORE_INT(userInfo, "password_age", info11->usri11_password_age);
					H_STORE_WSTR(userInfo, "home_dir", info11->usri11_home_dir);
					H_STORE_WSTR(userInfo, "parms", info11->usri11_parms);
					H_STORE_INT(userInfo, "last_logon", info11->usri11_last_logon);
					H_STORE_INT(userInfo, "last_logoff", info11->usri11_last_logoff);
					H_STORE_INT(userInfo, "bad_pw_count", info11->usri11_bad_pw_count);
					H_STORE_INT(userInfo, "num_logons", info11->usri11_num_logons);
					H_STORE_WSTR(userInfo, "logon_server", info11->usri11_logon_server);
					H_STORE_INT(userInfo, "country_code", info11->usri11_country_code);
					H_STORE_WSTR(userInfo, "workstations", info11->usri11_workstations);
					H_STORE_INT(userInfo, "max_storage", info11->usri11_max_storage);
					H_STORE_INT(userInfo, "units_per_week", info11->usri11_units_per_week);
					H_STORE_INT(userInfo, "code_page", info11->usri11_code_page);

					if(info11->usri11_units_per_week && info11->usri11_logon_hours)
						H_STORE_PTR(userInfo, "logon_hours", info11->usri11_logon_hours,
												info11->usri11_units_per_week >> 3);
				}
				
				CleanNetBuf(info3);
				CleanNetBuf(info11);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(user);
		CleanNetBuf(info3);
		CleanNetBuf(info11);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserGetInfo($server, $user, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves a list of local groups to which a user belongs
//
// param:  server	- computer to execute the command
//         user		- user name to search for in each group account
//				 flags	- currently LG_INCLUDE_INDIRECT is allowed
//				 groups	- array to store infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserGetLocalGroups)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *groups = NULL;

	if(items == 4 &&  CHK_ASSIGN_AREF(groups, ST(3)))
	{
		PWSTR server = NULL, user = NULL;
		PLOCALGROUP_USERS_INFO_0 info = NULL;

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));
			
			int flags = SvIV(ST(2));

			// clear array
			AV_CLEAR(groups);

			DWORD entries = 0;
			DWORD total = 0;

			// get all groups
			if(!LastError(NetUserGetLocalGroups(server, user, 0, flags, (PBYTE*)&info, 0xffffffff, 
																					&entries, &total)))
			{
				for(DWORD count = 0; count < entries; count++)
				{
					// store user properties
					HV *properties = NewHV;

					H_STORE_WSTR(properties, "name", info[count].lgrui0_name);

					A_STORE_REF(groups, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}
				
				CleanNetBuf(info);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(user);
		CleanNetBuf(info);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserGetLocalGroups($server, $user, $flags, \\@groups)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets global group memberships for a specified user account
//
// param:  server	- computer to execute the command
//         user		- name of the user for which to set global group memberships
//				 groups	- array with group names
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserSetGroups)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *groups = NULL;

	if(items == 3 &&  CHK_ASSIGN_AREF(groups, ST(2)))
	{
		PWSTR server = NULL, user = NULL;
		PGROUP_USERS_INFO_0 info = NULL;

		int numGroups = AV_LEN(groups) + 1;

		// if there are no members in the array do nothing
		if(numGroups <= 0)
			RETURNRESULT(1);

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));
		
			// store user groups
			info = (PGROUP_USERS_INFO_0)NewMem(sizeof(GROUP_USERS_INFO_0) * numGroups);

			for(int count = 0; count < numGroups; count++)
			{
				info[count].grui0_name = 
					H_FETCH_WSTR(A_FETCH_RHASH(groups, count), "name");
			}

			// set group membership
			LastError(NetUserSetGroups(server, user, 0, (PBYTE)info, numGroups));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		if(info)
			for(int count = 0; count < numGroups; count++)
				CleanPtr(info[count].grui0_name);

		FreeStr(server);
		FreeStr(user);
		CleanPtr(info);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserSetGroups($server, $user, \\@groups)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the parameters of a user account
//
// param:  server	- computer to execute the command
//         user		- user account to set information
//				 info		- hash to set infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, user = NULL;
		USER_INFO_3 userInfo;

		memset(&userInfo, 0, sizeof(userInfo));

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));

			DWORD level = 3, paramError = 0;

			userInfo.usri3_name = H_FETCH_WSTR(info, "name");
			userInfo.usri3_password = H_FETCH_WSTR(info, "password");
			userInfo.usri3_password_age = 0;
			userInfo.usri3_priv = USER_PRIV_USER;
			userInfo.usri3_home_dir = H_FETCH_WSTR(info, "home_dir");
			userInfo.usri3_comment = H_FETCH_WSTR(info, "comment");
			userInfo.usri3_flags = UF_SCRIPT | H_FETCH_INT(info, "flags");
			userInfo.usri3_script_path = H_FETCH_WSTR(info, "script_path");
			userInfo.usri3_auth_flags = 0;
			userInfo.usri3_full_name = H_FETCH_WSTR(info, "full_name");
			userInfo.usri3_usr_comment = H_FETCH_WSTR(info, "usr_comment");
			unsigned parmsSize = H_FETCH_SLEN(info, "parms");
			userInfo.usri3_parms = (PWSTR)H_FETCH_PTR(info, "parms", parmsSize);
			userInfo.usri3_workstations = H_FETCH_WSTR(info, "workstations");
			userInfo.usri3_last_logon = userInfo.usri3_last_logoff = 0;
			userInfo.usri3_acct_expires = H_FETCH_INT(info, "acct_expires");
			userInfo.usri3_max_storage = H_FETCH_INT(info, "max_storage");
			userInfo.usri3_units_per_week = 0; // units_per_week will be assigned below
			userInfo.usri3_logon_hours = NULL; // logon_hours will be assigned below
			userInfo.usri3_bad_pw_count = 0;
			userInfo.usri3_num_logons = 0;
			userInfo.usri3_logon_server = NULL;
			userInfo.usri3_country_code = H_FETCH_INT(info, "country_code");
			userInfo.usri3_code_page = H_FETCH_INT(info, "code_page");
			userInfo.usri3_user_id = 0;
			userInfo.usri3_primary_group_id = H_FETCH_INT(info, "primary_group_id");
			userInfo.usri3_profile = H_FETCH_WSTR(info, "profile");
			userInfo.usri3_home_dir_drive = H_FETCH_WSTR(info, "home_dir_drive");
			userInfo.usri3_password_expired = H_FETCH_INT(info, "password_expired");

			if(userInfo.usri3_logon_hours = (PUCHAR)H_FETCH_PTR(info, "logon_hours", 
																													userInfo.usri3_units_per_week))
				userInfo.usri3_units_per_week <<= 3;

			// set user info; if we get an access denied, we can call with level 2 only
			if(LastError(NetUserSetInfo(server, user, level, (PBYTE)&userInfo, NULL)) == 
					ERROR_ACCESS_DENIED)
			{
				USER_INFO_2 userInfo2;

				memset(&userInfo2, 0, sizeof(userInfo2));
				userInfo2.usri2_usr_comment = userInfo.usri3_usr_comment;
				userInfo2.usri2_parms = userInfo.usri3_parms;
				userInfo2.usri2_country_code = userInfo.usri3_country_code;

				LastError(NetUserSetInfo(server, user, level = 2, (PBYTE)&userInfo2, &paramError));
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(userInfo.usri3_name);
		FreeStr(userInfo.usri3_password);
		FreeStr(userInfo.usri3_home_dir);
		FreeStr(userInfo.usri3_comment);
		FreeStr(userInfo.usri3_script_path);
		FreeStr(userInfo.usri3_full_name);
		FreeStr(userInfo.usri3_usr_comment);
		FreeStr(userInfo.usri3_parms);
		FreeStr(userInfo.usri3_workstations);
		FreeStr(userInfo.usri3_profile);
		FreeStr(userInfo.usri3_home_dir_drive);

		// clean up
		FreeStr(server);
		FreeStr(user);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserSetInfo($server, $user, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets one or more pproperties of a user account
//
// param:  server	- computer to execute the command
//         user		- user account to set information
//				 info		- hash to set infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserSetProp)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL, user = NULL;
		USER_INFO_0 user0 = { NULL };
		USER_INFO_1003 user1003 = { NULL };
		USER_INFO_1006 user1006 = { NULL };
		USER_INFO_1007 user1007 = { NULL };
		USER_INFO_1008 user1008 = { 0 };
		USER_INFO_1009 user1009 = { NULL };
		USER_INFO_1011 user1011 = { NULL };
		USER_INFO_1012 user1012 = { NULL };
		USER_INFO_1014 user1014 = { NULL };
		USER_INFO_1017 user1017 = { 0 };
		USER_INFO_1020 user1020 = { 0, NULL };
		USER_INFO_1024 user1024 = { 0 };
		USER_INFO_1025 user1025 = { 0 };
		USER_INFO_1051 user1051 = { 0 };
		USER_INFO_1052 user1052 = { NULL };
		USER_INFO_1053 user1053 = { NULL };

		__try
		{
			// change server and user to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			user = S2W(SvPV(ST(1), PL_na));

			// sets user properties
			if(H_EXISTS(info, "password")) 
			{
				user1003.usri1003_password = H_FETCH_WSTR(info, "password");
				if(error = LastError(NetUserSetInfo(server, user, 1003, (PBYTE)&user1003, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "home_dir")) 
			{
				user1006.usri1006_home_dir = H_FETCH_WSTR(info, "home_dir");
				if(error = LastError(NetUserSetInfo(server, user, 1006, (PBYTE)&user1006, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "comment")) 
			{
				user1007.usri1007_comment = H_FETCH_WSTR(info, "comment");
				if(error = LastError(NetUserSetInfo(server, user, 1007, (PBYTE)&user1007, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "flags")) 
			{
				user1008.usri1008_flags = H_FETCH_INT(info, "flags");
				if(error = LastError(NetUserSetInfo(server, user, 1008, (PBYTE)&user1008, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "script_path")) 
			{
				user1009.usri1009_script_path = H_FETCH_WSTR(info, "script_path");
				if(error = LastError(NetUserSetInfo(server, user, 1009, (PBYTE)&user1009, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "full_name")) 
			{
				user1011.usri1011_full_name = H_FETCH_WSTR(info, "full_name");
				if(error = LastError(NetUserSetInfo(server, user, 1011, (PBYTE)&user1011, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "usr_comment")) 
			{
				user1012.usri1012_usr_comment = H_FETCH_WSTR(info, "usr_comment");
				if(error = LastError(NetUserSetInfo(server, user, 1012, (PBYTE)&user1012, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "workstations")) 
			{
				user1014.usri1014_workstations = H_FETCH_WSTR(info, "workstations");
				if(error = LastError(NetUserSetInfo(server, user, 1014, (PBYTE)&user1014, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "acct_expires")) 
			{
				user1017.usri1017_acct_expires = H_FETCH_INT(info, "acct_expires");
				if(error = LastError(NetUserSetInfo(server, user, 1017, (PBYTE)&user1017, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "logon_hours")) 
			{
				user1020.usri1020_units_per_week = UNITS_PER_WEEK;
				user1020.usri1020_logon_hours = (PBYTE)H_FETCH_STR(info, "logon_hours");
				if(error = LastError(NetUserSetInfo(server, user, 1020, (PBYTE)&user1020, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "country_code")) 
			{
				user1024.usri1024_country_code = H_FETCH_INT(info, "country_code");
				if(error = LastError(NetUserSetInfo(server, user, 1024, (PBYTE)&user1024, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "code_page")) 
			{
				user1025.usri1025_code_page = H_FETCH_INT(info, "code_page");
				if(error = LastError(NetUserSetInfo(server, user, 1025, (PBYTE)&user1025, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "primary_group_id")) 
			{
				user1051.usri1051_primary_group_id = H_FETCH_INT(info, "primary_group_id");
				if(error = LastError(NetUserSetInfo(server, user, 1051, (PBYTE)&user1051, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "profile")) 
			{
				user1052.usri1052_profile = H_FETCH_WSTR(info, "profile");
				if(error = LastError(NetUserSetInfo(server, user, 1052, (PBYTE)&user1052, NULL)))
					RaiseFalseError(error);
			}

			if(H_EXISTS(info, "home_dir_drive")) 
			{
				user1053.usri1053_home_dir_drive = H_FETCH_WSTR(info, "home_dir_drive");
				if(error = LastError(NetUserSetInfo(server, user, 1053, (PBYTE)&user1053, NULL)))
					RaiseFalseError(error);
			}

			// rename user
			if(H_EXISTS(info, "name")) 
			{
				user0.usri0_name = H_FETCH_WSTR(info, "name");
				if(error = LastError(NetUserSetInfo(server, user, 0, (PBYTE)&user0, NULL)))
					RaiseFalseError(error);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(user0.usri0_name);
		CleanPtr(user1003.usri1003_password);
		CleanPtr(user1006.usri1006_home_dir);
		CleanPtr(user1007.usri1007_comment);
		CleanPtr(user1009.usri1009_script_path);
		CleanPtr(user1011.usri1011_full_name);
		CleanPtr(user1012.usri1012_usr_comment);
		CleanPtr(user1014.usri1014_workstations);
		CleanPtr(user1052.usri1052_profile);
		CleanPtr(server);
		CleanPtr(user);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserSetProp($server, $user, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves global information for all users and global groups in the security 
// database
//
// param:  server	- computer to execute the command
//				 info		- hash to store infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserModalsGet)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *modals = NULL;

	if(items == 2 &&  CHK_ASSIGN_HREF(modals, ST(1)))
	{
		PWSTR server = NULL;
		PUSER_MODALS_INFO_0 info0 = NULL;
		PUSER_MODALS_INFO_1 info1 = NULL;
		PUSER_MODALS_INFO_2 info2 = NULL;
		PUSER_MODALS_INFO_3 info3 = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
		
			// clear hash
			HV_CLEAR(modals);

			// get app. modal information
			if(!LastError())
				LastError(NetUserModalsGet(server, 0, (PBYTE*)&info0));

			if(!LastError())
				LastError(NetUserModalsGet(server, 1, (PBYTE*)&info1));

			if(!LastError())
				LastError(NetUserModalsGet(server, 2, (PBYTE*)&info2));
			
			if(!LastError())
				LastError(NetUserModalsGet(server, 3, (PBYTE*)&info3));
			
			// store infos
			if(!LastError())
			{
				H_STORE_INT(modals, "min_passwd_len", info0->usrmod0_min_passwd_len);
				H_STORE_INT(modals, "max_passwd_age", info0->usrmod0_max_passwd_age);
				H_STORE_INT(modals, "min_passwd_age", info0->usrmod0_min_passwd_age);
				H_STORE_INT(modals, "force_logoff", info0->usrmod0_force_logoff);
				H_STORE_INT(modals, "password_hist_len", info0->usrmod0_password_hist_len);

				H_STORE_INT(modals, "role", info1->usrmod1_role);
				H_STORE_WSTR(modals, "primary", info1->usrmod1_primary);

				H_STORE_WSTR(modals, "domain_name", info2->usrmod2_domain_name);

				if(info2->usrmod2_domain_id && IsValidSid(info2->usrmod2_domain_id))
					H_STORE_PTR(modals, "domain_id", info2->usrmod2_domain_id,
											GetLengthSid(info2->usrmod2_domain_id));

				H_STORE_INT(modals, "lockout_duration", info3->usrmod3_lockout_duration);
				H_STORE_INT(modals, "lockout_observation_window", 
										info3->usrmod3_lockout_observation_window);
				H_STORE_INT(modals, "lockout_threshold", info3->usrmod3_lockout_threshold);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		NetApiBufferFree(info0);
		NetApiBufferFree(info1);
		NetApiBufferFree(info2);
		NetApiBufferFree(info3);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserModalsGet($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets global information for all users and global groups in the security 
// database
//
// param:  server	- computer to execute the command
//				 info		- hash to set infos
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure; you cannot set
//				 information at level 2
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserModalsSet)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *modals = NULL;

	if(items == 2 &&  CHK_ASSIGN_HREF(modals, ST(1)))
	{
		PWSTR server = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// set modal values
			USER_MODALS_INFO_0 info0 = 
			{
				H_FETCH_INT(modals, "min_passwd_len"),
				H_FETCH_INT(modals, "max_passwd_age"),
				H_FETCH_INT(modals, "min_passwd_age"),
				H_FETCH_INT(modals, "force_logoff"),
				H_FETCH_INT(modals, "password_hist_len")
			};
			
			USER_MODALS_INFO_1 info1 =
			{
				H_FETCH_INT(modals, "role"),
				H_FETCH_WSTR(modals, "primary")
			};

			USER_MODALS_INFO_3 info3 = 
			{
				H_FETCH_INT(modals, "lockout_duration"),
				H_FETCH_INT(modals, "lockout_observation_window"),
				H_FETCH_INT(modals, "lockout_threshold")
			};

			// set app. modal information
			if(error = NetUserModalsSet(server, 0, (PBYTE)&info0, NULL))
				RaiseFalseError(error);

			if(error = NetUserModalsSet(server, 1, (PBYTE)&info1, NULL))
				RaiseFalseError(error);

			if(error = NetUserModalsSet(server, 3, (PBYTE)&info3, NULL))
				RaiseFalseError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetUserModalsSet($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}

///////////////////////////////////////////////////////////////////////////////
//
// checks user's password for validity
//
// param:	 domain		- domain or computer to execute the command
//				 user			- user name
//				 password	- users password
//
// return: success - 1
//         failure - 0
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUserCheckPassword)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PSTR domain = NULL, user = NULL, password = NULL;
		HANDLE hToken = NULL;

		__try
		{
			domain = SvPV(ST(0), PL_na);
			user = SvPV(ST(1), PL_na);
			password = SvPV(ST(2), PL_na);

			// try to logon user
			if(!LogonUser(user, domain, password, LOGON32_LOGON_NETWORK, LOGON32_PROVIDER_DEFAULT, 
										&hToken))
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error
			LastError(error ? error : excode);
		}

		// clean up
		CloseHandle(hToken);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NetUserCheckPassword($domain, $user, $password)\n");

	RETURNRESULT(LastError() == 0);
}
