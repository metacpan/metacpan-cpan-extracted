#define WIN32_LEAN_AND_MEAN


#ifndef __SERVER_CPP
#define __SERVER_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <lmserver.h>


#include "server.h"
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
// retrieves a list of disk drives on a server
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

XS(XS_NT__Lanman_NetServerDiskEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *serverInfo = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(serverInfo, ST(1)))
	{
		PWSTR server = NULL;
		PWSTR info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clean array
			AV_CLEAR(serverInfo);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetServerDiskEnum((PSTR)server, 0, (PBYTE*)&info, 0xffffffff, 
																			&entries, &total, &handle)))
			{
				PWSTR drivePtr = info;

				for(DWORD count = 0; count < entries; count++)
				{
					// store disk names
					A_STORE_WSTR(serverInfo, drivePtr);

					drivePtr += wcslen(drivePtr) + 1;
				}
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
		croak("Usage: Win32::Lanman::NetServerDiskEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// lists all servers of the specified type that are visible in the specified 
// domain
//
// param:  server - computer to execute the command
//				 domain - domain name to enum servers
//				 type		- server types to enum
//				 info		- array to store server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *serverInfo = NULL;

	if(items == 4 && CHK_ASSIGN_AREF(serverInfo, ST(3)))
	{
		PWSTR server = NULL, domain = NULL;
		PSERVER_INFO_101 info = NULL;

		__try
		{
			// change server and domain to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domain = S2W(SvPV(ST(1), PL_na));
			
			DWORD type = SvIV(ST(2));

			// clean array
			AV_CLEAR(serverInfo);
		
			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetServerEnum((PSTR)server, 101, (PBYTE*)&info, 0xffffffff, 
																	&entries, &total, type, (PSTR)domain, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store server properties
					HV *properties = NewHV;

					H_STORE_INT(properties, "platform_id", info[count].sv101_platform_id);
					H_STORE_WSTR(properties, "name", (PWSTR)info[count].sv101_name);
					H_STORE_INT(properties, "version_major", info[count].sv101_version_major);
					H_STORE_INT(properties, "version_minor", info[count].sv101_version_minor);
					H_STORE_INT(properties, "type", info[count].sv101_type);
					H_STORE_WSTR(properties, "comment", (PWSTR)info[count].sv101_comment);

					A_STORE_REF(serverInfo, properties);

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
		FreeStr(domain);
		CleanNetBuf(info);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::NetServerEnum($server, $domain, $type, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}

 
///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about the specified server
//
// param:  server		- computer to execute the command
//				 info			- hash to store server information
//				 fullinfo - if not null, extended ínformation will be retrieved
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *serverInfo = NULL;

	if((items == 2 || items == 3) && CHK_ASSIGN_HREF(serverInfo, ST(1)))
	{
		PWSTR server = NULL;
		PSERVER_INFO_101 info101 = NULL;
		PSERVER_INFO_102 info102 = NULL;
		PSERVER_INFO_503 info503 = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			int getFullInfo = items == 3 ? SvIV(ST(2)) : 0;

			// clean hash
			HV_CLEAR(serverInfo);
		
			if(!LastError(NetServerGetInfo((PSTR)server, 102, (PBYTE*)&info102)))
			{
				// store server properties
				H_STORE_INT(serverInfo, "platform_id", info102->sv102_platform_id);
				H_STORE_WSTR(serverInfo, "name", (PWSTR)info102->sv102_name);
				H_STORE_INT(serverInfo, "version_major", info102->sv102_version_major);
				H_STORE_INT(serverInfo, "version_minor", info102->sv102_version_minor);
				H_STORE_INT(serverInfo, "type", info102->sv102_type);
				H_STORE_WSTR(serverInfo, "comment", (PWSTR)info102->sv102_comment);
				H_STORE_INT(serverInfo, "users", info102->sv102_users);
				H_STORE_INT(serverInfo, "disc", info102->sv102_disc);
				H_STORE_INT(serverInfo, "hidden", info102->sv102_hidden);
				H_STORE_INT(serverInfo, "announce", info102->sv102_announce);
				H_STORE_INT(serverInfo, "anndelta", info102->sv102_anndelta);
				H_STORE_INT(serverInfo, "licenses", info102->sv102_licenses);
				H_STORE_WSTR(serverInfo, "userpath", (PWSTR)info102->sv102_userpath);

				if(getFullInfo && !LastError(NetServerGetInfo((PSTR)server, 503, 
																											(PBYTE*)&info503)))
				{
					// store extended server properties; if the server is not NT, LastError() and
					// info503 is null
					if(info503)
					{
						H_STORE_INT(serverInfo, "sessopens", info503->sv503_sessopens);
						H_STORE_INT(serverInfo, "sessvcs", info503->sv503_sessvcs);
						H_STORE_INT(serverInfo, "opensearch", info503->sv503_opensearch);
						H_STORE_INT(serverInfo, "sizreqbuf", info503->sv503_sizreqbuf);
						H_STORE_INT(serverInfo, "initworkitems", info503->sv503_initworkitems);
						H_STORE_INT(serverInfo, "maxworkitems", info503->sv503_maxworkitems);
						H_STORE_INT(serverInfo, "rawworkitems", info503->sv503_rawworkitems);
						H_STORE_INT(serverInfo, "irpstacksize", info503->sv503_irpstacksize);
						H_STORE_INT(serverInfo, "maxrawbuflen", info503->sv503_maxrawbuflen);
						H_STORE_INT(serverInfo, "sessusers", info503->sv503_sessusers);
						H_STORE_INT(serverInfo, "sessconns", info503->sv503_sessconns);
						H_STORE_INT(serverInfo, "maxpagedmemoryusage", info503->sv503_maxpagedmemoryusage);
						H_STORE_INT(serverInfo, "maxnonpagedmemoryusage", info503->sv503_maxnonpagedmemoryusage);
						H_STORE_INT(serverInfo, "enablesoftcompat", info503->sv503_enablesoftcompat);
						H_STORE_INT(serverInfo, "enableforcedlogoff", info503->sv503_enableforcedlogoff);
						H_STORE_INT(serverInfo, "timesource", info503->sv503_timesource);
						H_STORE_INT(serverInfo, "acceptdownlevelapis", info503->sv503_acceptdownlevelapis);
						H_STORE_INT(serverInfo, "lmannounce", info503->sv503_lmannounce);
						H_STORE_WSTR(serverInfo, "domain", (PWSTR)info503->sv503_domain);
						H_STORE_INT(serverInfo, "maxcopyreadlen", info503->sv503_maxcopyreadlen);
						H_STORE_INT(serverInfo, "maxcopywritelen", info503->sv503_maxcopywritelen);
						H_STORE_INT(serverInfo, "minkeepsearch", info503->sv503_minkeepsearch);
						H_STORE_INT(serverInfo, "maxkeepsearch", info503->sv503_maxkeepsearch);
						H_STORE_INT(serverInfo, "minkeepcomplsearch", info503->sv503_minkeepcomplsearch);
						H_STORE_INT(serverInfo, "maxkeepcomplsearch", info503->sv503_maxkeepcomplsearch);
						H_STORE_INT(serverInfo, "threadcountadd", info503->sv503_threadcountadd);
						H_STORE_INT(serverInfo, "numblockthreads", info503->sv503_numblockthreads);
						H_STORE_INT(serverInfo, "scavtimeout", info503->sv503_scavtimeout);
						H_STORE_INT(serverInfo, "minrcvqueue", info503->sv503_minrcvqueue);
						H_STORE_INT(serverInfo, "minfreeworkitems", info503->sv503_minfreeworkitems);
						H_STORE_INT(serverInfo, "xactmemsize", info503->sv503_xactmemsize);
						H_STORE_INT(serverInfo, "threadpriority", info503->sv503_threadpriority);
						H_STORE_INT(serverInfo, "maxmpxct", info503->sv503_maxmpxct);
						H_STORE_INT(serverInfo, "oplockbreakwait", info503->sv503_oplockbreakwait);
						H_STORE_INT(serverInfo, "oplockbreakresponsewait", info503->sv503_oplockbreakresponsewait);
						H_STORE_INT(serverInfo, "enableoplocks", info503->sv503_enableoplocks);
						H_STORE_INT(serverInfo, "enableoplockforceclose", info503->sv503_enableoplockforceclose);
						H_STORE_INT(serverInfo, "enablefcbopens", info503->sv503_enablefcbopens);
						H_STORE_INT(serverInfo, "enableraw", info503->sv503_enableraw);
						H_STORE_INT(serverInfo, "enablesharednetdrives", info503->sv503_enablesharednetdrives);
						H_STORE_INT(serverInfo, "minfreeconnections", info503->sv503_minfreeconnections);
						H_STORE_INT(serverInfo, "maxfreeconnections", info503->sv503_maxfreeconnections);
					} // if(info503)
				} // if(getFullInfo && ...)
			} // if(!LastError(NetServerGetInfo(...))
			else
				if(LastError() == ERROR_ACCESS_DENIED && 
					 !LastError(NetServerGetInfo((PSTR)server, 101, (PBYTE*)&info101)))
				{
					// store server properties
					H_STORE_INT(serverInfo, "platform_id", info101->sv101_platform_id);
					H_STORE_WSTR(serverInfo, "name", (PWSTR)info101->sv101_name);
					H_STORE_INT(serverInfo, "version_major", info101->sv101_version_major);
					H_STORE_INT(serverInfo, "version_minor", info101->sv101_version_minor);
					H_STORE_INT(serverInfo, "type", info101->sv101_type);
					H_STORE_WSTR(serverInfo, "comment", (PWSTR)info101->sv101_comment);
				}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(info101);
		CleanNetBuf(info102);
		CleanNetBuf(info503);
	} // if((items == 2 || items == 3) && ...)
	else
		croak("Usage: Win32::Lanman::NetServerGetInfo($server, \\%%info, [$fullinfo])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets a server’s operating parameters
//
// param:  server		- computer to execute the command
//				 info			- hash to set server information
//				 fullinfo - if not null, extended ínformation will be set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerSetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *serverInfo = NULL;

	if((items == 2 || items == 3) && CHK_ASSIGN_HREF(serverInfo, ST(1)))
	{
		PWSTR server = S2W(SvPV(ST(0), PL_na));
		SERVER_INFO_102 info102;

		memset(&info102, 0, sizeof(info102));

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			int setFullInfo = items == 3 ? SvIV(ST(2)) : 0;
		
			info102.sv102_platform_id = H_FETCH_INT(serverInfo, "platform_id");
			info102.sv102_name = (PSTR)H_FETCH_WSTR(serverInfo, "name");
			info102.sv102_version_major = H_FETCH_INT(serverInfo, "version_major");
			info102.sv102_version_minor = H_FETCH_INT(serverInfo, "version_minor");
			info102.sv102_type = H_FETCH_INT(serverInfo, "type");
			info102.sv102_comment = (PSTR)H_FETCH_WSTR(serverInfo, "comment");
			info102.sv102_users = H_FETCH_INT(serverInfo, "users");
			info102.sv102_disc = H_FETCH_INT(serverInfo, "disc");
			info102.sv102_hidden = H_FETCH_INT(serverInfo, "hidden");
			info102.sv102_announce = H_FETCH_INT(serverInfo, "announce");
			info102.sv102_anndelta = H_FETCH_INT(serverInfo, "anndelta");
			info102.sv102_licenses = H_FETCH_INT(serverInfo, "licenses");
			info102.sv102_userpath = (PSTR)H_FETCH_WSTR(serverInfo, "userpath");

			if(!LastError(NetServerSetInfo((PSTR)server, 102, (PBYTE)&info102, NULL)) && 
				 setFullInfo)
			{
				SERVER_INFO_503 info503 =
				{
					H_FETCH_INT(serverInfo, "sessopens"),
					H_FETCH_INT(serverInfo, "sessvcs"),
					H_FETCH_INT(serverInfo, "opensearch"),
					H_FETCH_INT(serverInfo, "sizreqbuf"),
					H_FETCH_INT(serverInfo, "initworkitems"),
					H_FETCH_INT(serverInfo, "maxworkitems"),
					H_FETCH_INT(serverInfo, "rawworkitems"),
					H_FETCH_INT(serverInfo, "irpstacksize"),
					H_FETCH_INT(serverInfo, "maxrawbuflen"),
					H_FETCH_INT(serverInfo, "sessusers"),
					H_FETCH_INT(serverInfo, "sessconns"),
					H_FETCH_INT(serverInfo, "maxpagedmemoryusage"),
					H_FETCH_INT(serverInfo, "maxnonpagedmemoryusage"),
					H_FETCH_INT(serverInfo, "enablesoftcompat"),
					H_FETCH_INT(serverInfo, "enableforcedlogoff"),
					H_FETCH_INT(serverInfo, "timesource"),
					H_FETCH_INT(serverInfo, "acceptdownlevelapis"),
					H_FETCH_INT(serverInfo, "lmannounce"),
					(PSTR)H_FETCH_WSTR(serverInfo, "domain"),
					H_FETCH_INT(serverInfo, "maxcopyreadlen"),
					H_FETCH_INT(serverInfo, "maxcopywritelen"),
					H_FETCH_INT(serverInfo, "minkeepsearch"),
					H_FETCH_INT(serverInfo, "maxkeepsearch"),
					H_FETCH_INT(serverInfo, "minkeepcomplsearch"),
					H_FETCH_INT(serverInfo, "maxkeepcomplsearch"),
					H_FETCH_INT(serverInfo, "threadcountadd"),
					H_FETCH_INT(serverInfo, "numblockthreads"),
					H_FETCH_INT(serverInfo, "scavtimeout"),
					H_FETCH_INT(serverInfo, "minrcvqueue"),
					H_FETCH_INT(serverInfo, "minfreeworkitems"),
					H_FETCH_INT(serverInfo, "xactmemsize"),
					H_FETCH_INT(serverInfo, "threadpriority"),
					H_FETCH_INT(serverInfo, "maxmpxct"),
					H_FETCH_INT(serverInfo, "oplockbreakwait"),
					H_FETCH_INT(serverInfo, "oplockbreakresponsewait"),
					H_FETCH_INT(serverInfo, "enableoplocks"),
					H_FETCH_INT(serverInfo, "enableoplockforceclose"),
					H_FETCH_INT(serverInfo, "enablefcbopens"),
					H_FETCH_INT(serverInfo, "enableraw"),
					H_FETCH_INT(serverInfo, "enablesharednetdrives"),
					H_FETCH_INT(serverInfo, "minfreeconnections"),
					H_FETCH_INT(serverInfo, "maxfreeconnections")
				};
			
				LastError(NetServerSetInfo((PSTR)server, 503, (PBYTE)&info503, NULL));

				FreeStr(info503.sv503_domain);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(info102.sv102_name);
		FreeStr(info102.sv102_comment);
		FreeStr(info102.sv102_userpath);
	} // if((items == 2 || items == 3) && ...)
	else
		croak("Usage: Win32::Lanman::NetServerSetInfo($server, \\%%info, [$fullinfo])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// binds the server to the transport
//
// param:  server - computer to execute the command
//				 info		- hash to set server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerTransportAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *transportInfo = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(transportInfo, ST(1)))
	{
		PWSTR server = NULL;
		SERVER_TRANSPORT_INFO_0 info = { 0, NULL, NULL, 0, NULL };

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
		
			info.svti0_numberofvcs = H_FETCH_INT(transportInfo, "numberofvcs");
			info.svti0_transportname = (PSTR)H_FETCH_WSTR(transportInfo, "transportname");
			info.svti0_transportaddress = (PBYTE)H_FETCH_STR(transportInfo, "transportaddress");
			info.svti0_transportaddresslength = H_FETCH_INT(transportInfo, "transportaddresslength");
			info.svti0_networkaddress = (PSTR)H_FETCH_WSTR(transportInfo, "networkaddress");

			LastError(NetServerTransportAdd((PSTR)server, 0, (PBYTE)&info));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(info.svti0_transportname);
		FreeStr(info.svti0_networkaddress);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetServerTransportAdd($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// unbinds (or disconnects) the transport protocol from the server
//
// param:  server - computer to execute the command
//				 info		- hash to set server information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetServerTransportDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *transportInfo = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(transportInfo, ST(1)))
	{
		PWSTR server = NULL;
		SERVER_TRANSPORT_INFO_0 info = { 0, NULL, NULL, 0, NULL };

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			info.svti0_numberofvcs = H_FETCH_INT(transportInfo, "numberofvcs");
			info.svti0_transportname = (PSTR)H_FETCH_WSTR(transportInfo, "transportname");
			info.svti0_transportaddress = (PBYTE)H_FETCH_STR(transportInfo, "transportaddress");
			info.svti0_transportaddresslength = H_FETCH_INT(transportInfo, "transportaddresslength");
			info.svti0_networkaddress = (PSTR)H_FETCH_WSTR(transportInfo, "networkaddress");
			
			LastError(NetServerTransportDel((PSTR)server, 0, (PBYTE)&info));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(info.svti0_transportname);
		FreeStr(info.svti0_networkaddress);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetServerTransportDel($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// supplies information about transports that are managed by the server
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

XS(XS_NT__Lanman_NetServerTransportEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *transportInfo = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(transportInfo, ST(1)))
	{
		PWSTR server = NULL;
		PSERVER_TRANSPORT_INFO_1 info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
		
			// clean array
			AV_CLEAR(transportInfo);
		
			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetServerTransportEnum((PSTR)server, 1, (PBYTE*)&info, 0xffffffff, 
																					 &entries, &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store server properties
					HV *properties = NewHV;

					H_STORE_INT(properties, "numberofvcs", info[count].svti1_numberofvcs);
					H_STORE_WSTR(properties, "transportname", (PWSTR)info[count].svti1_transportname);
					H_STORE_PTR(properties, "transportaddress", info[count].svti1_transportaddress,
											info[count].svti1_transportaddresslength);
					H_STORE_INT(properties, "transportaddresslength", info[count].svti1_transportaddresslength);
					H_STORE_WSTR(properties, "networkaddress", (PWSTR)info[count].svti1_networkaddress);
					H_STORE_WSTR(properties, "domain", (PWSTR)info[count].svti1_domain);

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
		croak("Usage: Win32::Lanman::NetServerTransportEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}
