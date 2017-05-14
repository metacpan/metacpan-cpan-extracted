#define WIN32_LEAN_AND_MEAN


#ifndef __DS_CPP
#define __DS_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "ds.h"
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
// retrieves a list of organizational units in which a computer account can be 
// created
//
// param:  server		- computer to execute the command
//				 domain		- domain name for which to retrieve the list of OUs 
//				 account	- account name to use when connecting to the domain contr.
//				 password	- accounts password
//				 OUs			- receives the list of joinable OUs
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetJoinableOUs)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *orgUnits = NULL;

	if(items == 5 && CHK_ASSIGN_AREF(orgUnits, ST(4)))
	{
		PWSTR server = NULL, domain = NULL, account = NULL, password = NULL;
		PWSTR *oUs = NULL;
		DWORD oUsCount = 0;

		__try
		{
			// change server, domain, account and password to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domain = S2W(SvPV(ST(1), PL_na));
			account = S2W(SvPV(ST(2), PL_na));
			password = S2W(SvPV(ST(3), PL_na));

			// clear array
			AV_CLEAR(orgUnits);
			
			// return the library error if the library isn't loaded correctly
			if(!NetGetJoinableOUsCall)
				RaiseFalseError(NetApi32LibError);

			// get the joinable OUs
			if(!LastError(NetGetJoinableOUsCall(server, domain, account, password, &oUsCount, &oUs)))
				for(DWORD count = 0; count < oUsCount; count++)
				{
					// store OUs
					A_STORE_WSTR(orgUnits, oUs[count]);
				}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(oUs);
		CleanPtr(server);
		CleanPtr(domain);
		CleanPtr(account);
		CleanPtr(password);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::NetGetJoinableOUs($server, $domain, $account, "
																									 "$password, \\@OUs)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves join status information for the specified computer
//
// param:  server	- computer to execute the command
//				 info		- receives the join information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetJoinInformation)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(info, ST(1)))
	{
		PWSTR server = NULL, buffer = NULL;
		NETSETUP_JOIN_STATUS type;

		__try
		{
			// change server, domain, account and password to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear hash
			HV_CLEAR(info);
			
			// return the library error if the library isn't loaded correctly
			if(!NetGetJoinInformationCall)
				RaiseFalseError(NetApi32LibError);

			// get the join info
			if(!LastError(NetGetJoinInformationCall(server, &buffer, &type)))
			{
				// store infos
				H_STORE_WSTR(info, "name", buffer);
				H_STORE_INT(info, "type", type);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(buffer);
		CleanPtr(server);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetGetJoinInformation($server, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// joins a computer to a workgroup or domain 
//
// param:  server			- computer to execute the command
//				 domain			- domain or workgroup name
//				 accountOU	- computer account OU
//				 account		- account name to use when connecting to the domain contr.
//				 password		- accounts password
//				 options		- join options
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetJoinDomain)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 5 || items == 6)
	{
		PWSTR server = NULL, domain = NULL, accountOU = NULL, account = NULL, 
					password = NULL;
		DWORD options = 0;

		__try
		{
			// change server, domain, accountOU, account and password to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domain = S2W(SvPV(ST(1), PL_na));
			accountOU = S2W(SvPV(ST(2), PL_na));
			account = S2W(SvPV(ST(3), PL_na));
			password = S2W(SvPV(ST(4), PL_na));
			options = items == 6 ? SvIV(ST(5)) : 0;
	
			// return the library error if the library isn't loaded correctly
			if(!NetJoinDomainCall)
				RaiseFalseError(NetApi32LibError);

			// join to the domain
			LastError(NetJoinDomainCall(server, domain, accountOU, account, password, options));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(domain);
		CleanPtr(accountOU);
		CleanPtr(account);
		CleanPtr(password);
	} // if(items == 5 || items == 6)
	else
		croak("Usage: Win32::Lanman::NetJoinDomain($server, $domain, $accountOU, "
																							 "$account, $password [, $options])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// changes the name of a computer in a domain 
//
// param:  server					- computer to execute the command
//				 newMachineName	- new computer name
//				 account				- account name to use when connecting to the domain 
//													controller
//				 password				- accounts password
//				 options				- rename options
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetRenameMachineInDomain)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 4 || items == 5)
	{
		PWSTR server = NULL, newMachineName = NULL, account = NULL, password = NULL;
		DWORD options = 0;

		__try
		{
			// change server, account and password to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			newMachineName = S2W(SvPV(ST(1), PL_na));
			account = S2W(SvPV(ST(2), PL_na));
			password = S2W(SvPV(ST(3), PL_na));
			options = items == 5 ? SvIV(ST(4)) : 0;
	
			// return the library error if the library isn't loaded correctly
			if(!NetRenameMachineInDomainCall)
				RaiseFalseError(NetApi32LibError);

			// renames the machine name
			if(LastError(NetRenameMachineInDomainCall(server, newMachineName, account, 
																								password, options)))
				RaiseFalseError(LastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(newMachineName);
		CleanPtr(account);
		CleanPtr(password);
	} // if(items == 4 || items == 5)
	else
		croak("Usage: Win32::Lanman::NetRenameMachineInDomain($server, $newMachineName, "
																													"$account, $password "
																													"[, $options])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// unjoins a computer from a workgroup or domain 
//
// param:  server			- computer to execute the command
//				 account		- account name to use when connecting to the domain contr.
//				 password		- accounts password
//				 options		- unjoin options
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUnjoinDomain)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3 || items == 4)
	{
		PWSTR server = NULL, account = NULL, password = NULL;
		DWORD options = 0;

		__try
		{
			// change server, account and password to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			account = S2W(SvPV(ST(1), PL_na));
			password = S2W(SvPV(ST(2), PL_na));
			options = items == 4 ? SvIV(ST(3)) : NETSETUP_ACCT_DELETE;
	
			// return the library error if the library isn't loaded correctly
			if(!NetUnjoinDomainCall)
				RaiseFalseError(NetApi32LibError);

			// unjoin from the domain
			LastError(NetUnjoinDomainCall(server, account, password, options));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(account);
		CleanPtr(password);
	} // if(items == 3 || items == 4)
	else
		croak("Usage: Win32::Lanman::NetUnjoinDomain($server, $account, $password "
																								 "[, $options])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// verifies the validity of a computer name, workgroup name, or domain name
//
// param:  server		- computer to execute the command
//				 name			- name to validate
//				 account	- account name to use when connecting to the domain contr.
//				 password	- accounts password
//				 type			- validation type
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetValidateName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 4 || items == 5)
	{
		PWSTR server = NULL, name = NULL, account = NULL, password = NULL;
		NETSETUP_NAME_TYPE type;

		__try
		{
			// change server, account and password to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			name = S2W(SvPV(ST(1), PL_na));
			account = S2W(SvPV(ST(2), PL_na));
			password = S2W(SvPV(ST(3), PL_na));
			type = items == 5 ? (NETSETUP_NAME_TYPE)SvIV(ST(4)) : NetSetupUnknown ;
	
			// return the library error if the library isn't loaded correctly
			if(!NetValidateNameCall)
				RaiseFalseError(NetApi32LibError);

			// validates the name
			if(LastError(NetValidateNameCall(server, name, account, password, type)))
				RaiseFalseError(LastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(name);
		CleanPtr(account);
		CleanPtr(password);
	} // if(items == 5)
	else
		croak("Usage: Win32::Lanman::NetValidateName($server, $name, $account, "
																								 "$password [, $type])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enables to receive a notification when the name of the current domain 
// changes; when the domain name changes, the specified eventHandle is set 
// to the signaled state
//
// param:  eventHandle	- receives the enent handle
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetRegisterDomainNameChangeNotification)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *eventHandle = NULL;

	if(items == 1 && CHK_ASSIGN_SREF(eventHandle, ST(0)))
	{
		HANDLE hNotificationHandle = NULL;

		__try
		{
			// clear handle
			SV_CLEAR(eventHandle);

			// return the library error if the library isn't loaded correctly
			if(!NetRegisterDomainNameChangeNotificationCall)
				RaiseFalseError(NetApi32LibError);

			// get the notification handle and store infos
			if(!LastError(NetRegisterDomainNameChangeNotificationCall(&hNotificationHandle)))
				S_STORE_INT(eventHandle, (int)hNotificationHandle);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up

	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::NetRegisterDomainNameChangeNotification(\\$handle)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// ends a domain name change notification started by the 
// NetRegisterDomainNameChangeNotification function
//
// param:  eventHandle	- notification handle
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetUnregisterDomainNameChangeNotification)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 1)
	{
		HANDLE hNotificationHandle = NULL;

		__try
		{
			hNotificationHandle = (HANDLE)SvIV(ST(0));

			// return the library error if the library isn't loaded correctly
			if(!NetUnregisterDomainNameChangeNotificationCall)
				RaiseFalseError(NetApi32LibError);

			// unregister the notification handle
			LastError(NetRegisterDomainNameChangeNotificationCall(&hNotificationHandle));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up

	} // if(items == 1)
	else
		croak("Usage: Win32::Lanman::NetUnregisterDomainNameChangeNotification($handle)\n");
	
	RETURNRESULT(LastError() == 0);
}
