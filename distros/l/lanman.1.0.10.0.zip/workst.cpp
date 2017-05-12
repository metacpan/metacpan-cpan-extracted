#define WIN32_LEAN_AND_MEAN


#ifndef __WORKST_CPP
#define __WORKST_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "workst.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


#define IF_H_EXISTS_INT_NET_WKSTA_SET_INFO(key, level) \
	if(H_EXISTS(workstInfo, key))	\
	{ WKSTA_INFO_##level info##level = { H_FETCH_INT(workstInfo, key)	}; \
		if(error = NetWkstaSetInfo((PSTR)server, level, (PBYTE)&info##level, NULL)) \
			RaiseFalseError(error); }


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
//
// returns information about the configuration elements for a workstation
//
// param:  server   - computer to execute the command
//				 info			- hash to store workstation information
//				 fullinfo - if not null, extended ínformation will be retrieved
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *workstInfo = NULL;

	if((items == 2 || items == 3) && CHK_ASSIGN_HREF(workstInfo, ST(1)))
	{
		PWSTR server = NULL;
		PWKSTA_INFO_101 info101 = NULL;
		PWKSTA_INFO_102 info102 = NULL;
		PWKSTA_INFO_502 info502 = NULL;
		PWKSTA_INFO_1027 info1027 = NULL;
		PWKSTA_INFO_1028 info1028 = NULL;
		PWKSTA_INFO_1032 info1032 = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			int getFullInfo = items == 3 ? SvIV(ST(2)) : 0;

			// clean hash
			HV_CLEAR(workstInfo);
		
			if(!LastError(NetWkstaGetInfo((PSTR)server, 102, (PBYTE*)&info102)))
			{
				// store server properties
				H_STORE_INT(workstInfo, "platform_id", info102->wki102_platform_id);
				H_STORE_WSTR(workstInfo, "computername", (PWSTR)info102->wki102_computername);
				H_STORE_WSTR(workstInfo, "langroup", (PWSTR)info102->wki102_langroup);
				H_STORE_INT(workstInfo, "ver_major", info102->wki102_ver_major);
				H_STORE_INT(workstInfo, "ver_minor", info102->wki102_ver_minor);
				H_STORE_WSTR(workstInfo, "lanroot", (PWSTR)info102->wki102_lanroot);
				H_STORE_INT(workstInfo, "logged_on_users", info102->wki102_logged_on_users);

				if(getFullInfo && !LastError(NetWkstaGetInfo((PSTR)server, 502, 
																												 (PBYTE*)&info502)))
				{
					// store extended server properties
					H_STORE_INT(workstInfo, "char_wait", info502->wki502_char_wait);
					H_STORE_INT(workstInfo, "collection_time", info502->wki502_collection_time);
					H_STORE_INT(workstInfo, "maximum_collection_count", info502->wki502_maximum_collection_count);
					H_STORE_INT(workstInfo, "keep_conn", info502->wki502_keep_conn);
					H_STORE_INT(workstInfo, "max_cmds", info502->wki502_max_cmds);
					H_STORE_INT(workstInfo, "sess_timeout", info502->wki502_sess_timeout);
					H_STORE_INT(workstInfo, "siz_char_buf", info502->wki502_siz_char_buf);
					H_STORE_INT(workstInfo, "max_threads", info502->wki502_max_threads);
					H_STORE_INT(workstInfo, "lock_quota", info502->wki502_lock_quota);
					H_STORE_INT(workstInfo, "lock_increment", info502->wki502_lock_increment);
					H_STORE_INT(workstInfo, "lock_maximum", info502->wki502_lock_maximum);
					H_STORE_INT(workstInfo, "pipe_increment", info502->wki502_pipe_increment);
					H_STORE_INT(workstInfo, "pipe_maximum", info502->wki502_pipe_maximum);
					H_STORE_INT(workstInfo, "cache_file_timeout", info502->wki502_cache_file_timeout);
					H_STORE_INT(workstInfo, "dormant_file_limit", info502->wki502_dormant_file_limit);
					H_STORE_INT(workstInfo, "read_ahead_throughput", info502->wki502_read_ahead_throughput);
					H_STORE_INT(workstInfo, "num_mailslot_buffers", info502->wki502_num_mailslot_buffers);
					H_STORE_INT(workstInfo, "num_srv_announce_buffers", info502->wki502_num_srv_announce_buffers);
					H_STORE_INT(workstInfo, "max_illegal_datagram_events", info502->wki502_max_illegal_datagram_events);
					H_STORE_INT(workstInfo, "illegal_datagram_event_reset_frequency", info502->wki502_illegal_datagram_event_reset_frequency);
					H_STORE_INT(workstInfo, "log_election_packets", info502->wki502_log_election_packets);
					H_STORE_INT(workstInfo, "use_opportunistic_locking", info502->wki502_use_opportunistic_locking);
					H_STORE_INT(workstInfo, "use_unlock_behind", info502->wki502_use_unlock_behind);
					H_STORE_INT(workstInfo, "use_close_behind", info502->wki502_use_close_behind);
					H_STORE_INT(workstInfo, "buf_named_pipes", info502->wki502_buf_named_pipes);
					H_STORE_INT(workstInfo, "use_lock_read_unlock", info502->wki502_use_lock_read_unlock);
					H_STORE_INT(workstInfo, "utilize_nt_caching", info502->wki502_utilize_nt_caching);
					H_STORE_INT(workstInfo, "use_raw_read", info502->wki502_use_raw_read);
					H_STORE_INT(workstInfo, "use_raw_write", info502->wki502_use_raw_write);
					H_STORE_INT(workstInfo, "use_write_raw_data", info502->wki502_use_write_raw_data);
					H_STORE_INT(workstInfo, "use_encryption", info502->wki502_use_encryption);
					H_STORE_INT(workstInfo, "buf_files_deny_write", info502->wki502_buf_files_deny_write);
					H_STORE_INT(workstInfo, "buf_read_only_files", info502->wki502_buf_read_only_files);
					H_STORE_INT(workstInfo, "force_core_create_mode", info502->wki502_force_core_create_mode);
					H_STORE_INT(workstInfo, "use_512_byte_max_transfer", info502->wki502_use_512_byte_max_transfer);
				}
			}
			else
				if(!LastError(NetServerGetInfo((PSTR)server, 101, (PBYTE*)&info101)))
				{
					// store server properties
					H_STORE_INT(workstInfo, "platform_id", info101->wki101_platform_id);
					H_STORE_WSTR(workstInfo, "computername", (PWSTR)info101->wki101_computername);
					
					// it seems, there is a bug in call NetWkstaGetInfo at level 101;
					// info101->wki101_langroup contains an invalid pointer
					// H_STORE_WSTR(workstInfo, "langroup", (PWSTR)info101->wki101_langroup);

					H_STORE_INT(workstInfo, "ver_major", info101->wki101_ver_major);
					H_STORE_INT(workstInfo, "ver_minor", info101->wki101_ver_minor);
					H_STORE_WSTR(workstInfo, "lanroot", (PWSTR)info101->wki101_lanroot);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanNetBuf(info101);
		CleanNetBuf(info102);
		CleanNetBuf(info502);
		CleanNetBuf(info1027);
		CleanNetBuf(info1028);
		CleanNetBuf(info1032);
	} // if((items == 2 || items == 3) && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaGetInfo($server, \\%%info, [$fullinfo])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// configures a workstation
//
// param:  server		- computer to execute the command
//				 info			- hash to set server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *workstInfo = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(workstInfo, ST(1)))
	{
		PWSTR server = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("char_wait", 1010);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("collection_time", 1011);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("maximum_collection_count", 1012);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("keep_conn", 1013);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("sess_timeout", 1018);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("siz_char_buf", 1023);
			
			// only supported in lanmanager 2.x
			// IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("errlog_sz", 1027);
			// IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("print_buf_time", 1028);
			// IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("wrk_heuristics", 1032);
			
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("max_threads", 1033);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("lock_quota", 1041);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("lock_increment", 1042);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("lock_maximum", 1043);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("pipe_increment", 1044);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("pipe_maximum", 1045);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("dormant_file_limit", 1046);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("cache_file_timeout", 1047);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_opportunistic_locking", 1048);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_unlock_behind", 1049);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_close_behind", 1050);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("buf_named_pipes", 1051);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_lock_read_unlock", 1052);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("utilize_nt_caching", 1053);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_raw_read", 1054);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_raw_write", 1055);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_write_raw_data", 1056);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_encryption", 1057);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("buf_files_deny_write", 1058);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("buf_read_only_files", 1059);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("force_core_create_mode", 1060);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("use_512_byte_max_transfer", 1061);
			IF_H_EXISTS_INT_NET_WKSTA_SET_INFO("read_ahead_throughput", 1062);

			// setting WKSTA_INFO_102 not supported in WinNT, only MS knows why
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
	} // if((items == 2 || items == 3) && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaSetInfo($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// binds (or connects) the redirector to the transport
//
// param:  server - computer to execute the command
//				 info		- hash to set transport information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaTransportAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *transportInfo = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(transportInfo, ST(1)))
	{
		PWSTR server = NULL;
		WKSTA_TRANSPORT_INFO_0 info;

		memset(&info, 0, sizeof(info));

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
		
			info.wkti0_quality_of_service = 
				H_FETCH_INT(transportInfo, "quality_of_service");
			info.wkti0_number_of_vcs = H_FETCH_INT(transportInfo, "number_of_vcs");
			info.wkti0_transport_name = 
				(PSTR)H_FETCH_WSTR(transportInfo, "transport_name");
			info.wkti0_transport_address = 
				(PSTR)H_FETCH_WSTR(transportInfo, "transport_address");
			info.wkti0_wan_ish = H_FETCH_INT(transportInfo, "wan_ish");

			LastError(NetWkstaTransportAdd((PSTR)server, 0, (PBYTE)&info, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(info.wkti0_transport_name);
		FreeStr(info.wkti0_transport_address);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaTransportAdd($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// unbinds the transport protocol from the redirector
//
// param:  server		 - computer to execute the command
//				 transport - name of the transport from which to unbind
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaTransportDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *transportInfo = NULL;

	if(items == 3)
	{
		PWSTR server = NULL, transport = NULL;

		__try
		{
			// change server and transport name to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			transport = S2W(SvPV(ST(1), PL_na));

			DWORD forceFlag = SvIV(ST(2));
		
			LastError(NetWkstaTransportDel((PSTR)server, (PSTR)transport, forceFlag));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(transport);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaTransportDel($server, $transport, $force)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// supplies information about transport protocols that are managed by the 
// redirector
//
// param:  server - computer to execute the command
//				 info		- array to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaTransportEnum)  
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *transportInfo = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(transportInfo, ST(1)))
	{
		PWSTR server = NULL;
		PWKSTA_TRANSPORT_INFO_0 info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
		
			// clean array
			AV_CLEAR(transportInfo);
		
			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetWkstaTransportEnum((PSTR)server, 0, (PBYTE*)&info, 0xffffffff, 
																					&entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store server properties
					HV *properties = NewHV;

					H_STORE_INT(properties, "quality_of_service", info[count].wkti0_quality_of_service);
					H_STORE_INT(properties, "number_of_vcs", info[count].wkti0_number_of_vcs);
					H_STORE_WSTR(properties, "transport_name", (PWSTR)info[count].wkti0_transport_name);
					H_STORE_WSTR(properties, "transport_address", (PWSTR)info[count].wkti0_transport_address);
					H_STORE_INT(properties, "wan_ish", info[count].wkti0_wan_ish);

					A_STORE_REF(transportInfo, properties);

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
		CleanNetBuf(info);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaTransportEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// returns information about the currently logged-on user. This function must 
// be called in the context of the logged-on user
//
// param:  info	- hash to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaUserGetInfo)
{
	dXSARGS;

	// reset last error
	LastError(0);

	ErrorAndResult;

	HV *userInfo = NULL;

	if(items == 1 && CHK_ASSIGN_HREF(userInfo, ST(0)))
	{
		PWKSTA_USER_INFO_1 info = NULL;

		__try
		{
			// clean array
			HV_CLEAR(userInfo);

			if(!LastError(NetWkstaUserGetInfo(NULL, 1, (PBYTE*)&info)))
			{
				// store server properties
				H_STORE_WSTR(userInfo, "username", (PWSTR)info->wkui1_username);
				H_STORE_WSTR(userInfo, "logon_domain", (PWSTR)info->wkui1_logon_domain);
				H_STORE_WSTR(userInfo, "oth_domains", (PWSTR)info->wkui1_oth_domains);
				H_STORE_WSTR(userInfo, "logon_server", (PWSTR)info->wkui1_logon_server);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(info);
	} // if(items == 1 && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaUserGetInfo(\\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// returns information about the currently logged-on user. This function must 
// be called in the context of the logged-on user
//
// param:  info	- hash to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaUserSetInfo) 
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *userInfo = NULL;

	if(items == 1 && CHK_ASSIGN_HREF(userInfo, ST(0)))
	{
		WKSTA_USER_INFO_1 info;

		memset(&info, 0, sizeof(info));

		__try
		{
			info.wkui1_username =	(PSTR)H_FETCH_WSTR(userInfo, "username");
			info.wkui1_logon_domain = (PSTR)H_FETCH_WSTR(userInfo, "logon_domain");
			info.wkui1_oth_domains = (PSTR)H_FETCH_WSTR(userInfo, "oth_domains");
			info.wkui1_logon_server = (PSTR)H_FETCH_WSTR(userInfo, "logon_server");

			LastError(NetWkstaUserSetInfo(NULL, 1, (PBYTE)&info, NULL));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(info.wkui1_username);
		FreeStr(info.wkui1_logon_domain);
		FreeStr(info.wkui1_oth_domains);
		FreeStr(info.wkui1_logon_server);
	} // if(items == 1 && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaUserSetInfo(\\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// lists information about all users currently logged on to the workstation 
//
// param:  server - computer to execute the command
//				 info		- array to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetWkstaUserEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *userInfo = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(userInfo, ST(1)))
	{
		PWSTR server = NULL;
		PWKSTA_USER_INFO_1 info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clean array
			AV_CLEAR(userInfo);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetWkstaUserEnum((PSTR)server, 1, (PBYTE*)&info, 0xffffffff, 
																		 &entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store server properties
					HV *properties = NewHV;

					// store server properties
					H_STORE_WSTR(properties, "username", (PWSTR)info[count].wkui1_username);
					H_STORE_WSTR(properties, "logon_domain", (PWSTR)info[count].wkui1_logon_domain);
					H_STORE_WSTR(properties, "oth_domains", (PWSTR)info[count].wkui1_oth_domains);
					H_STORE_WSTR(properties, "logon_server", (PWSTR)info[count].wkui1_logon_server);

					A_STORE_REF(userInfo, properties);

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
		CleanNetBuf(info);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetWkstaUserEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}
