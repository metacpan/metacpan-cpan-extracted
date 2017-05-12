#define WIN32_LEAN_AND_MEAN


#ifndef __POLICY_CPP
#define __POLICY_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <ntsecapi.h>


#include "policy.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

#ifndef POLICY_MACHINE_PASSWORD_INFO
typedef struct _POLICY_MACHINE_PASSWORD_INFO
{
	LARGE_INTEGER PasswordChangeInterval;
} POLICY_MACHINE_PASSWORD_INFO, *PPOLICY_MACHINE_PASSWORD_INFO;
#endif


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// initializes a lsa string with an unicode string
//
// param:  lsaStr - pointer to the lsa string
//         str    - unicode string
//
// return: nothing
//
///////////////////////////////////////////////////////////////////////////////

void InitLsaString(PLSA_UNICODE_STRING lsaStr, PWSTR str)
{
	if(lsaStr)
	{
		lsaStr->Buffer = str;
		lsaStr->Length = str ? wcslen(str) * sizeof(WCHAR) : 0;
		lsaStr->MaximumLength = str ? (wcslen(str) + 1) * sizeof(WCHAR) : 0;
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// opens the policy and returns a handle to the policy
//
// param:  server    - computer to open the policy
//         access    - desired access
//         hPolicy   - pointer to a policy handle
//         lastError - pointer to an error value
//
// return: success - 1 
//         failure - 0 (error code in lastError)
//
///////////////////////////////////////////////////////////////////////////////

BOOL OpenPolicy(PWSTR server, DWORD access, PLSA_HANDLE hPolicy, PDWORD lastError)
{
  LSA_OBJECT_ATTRIBUTES objectAttr;
  LSA_UNICODE_STRING lsaServer;
	
	// set the policy handle to null; don't force a LsaClose
	*hPolicy = NULL;
	memset(&objectAttr, 0, sizeof(objectAttr));
  InitLsaString(&lsaServer, server);
  
  return !(*lastError = 
						LsaNtStatusToWinError(LsaOpenPolicy(&lsaServer, &objectAttr, 
																								access, hPolicy))) ? TRUE : FALSE;
}


///////////////////////////////////////////////////////////////////////////////
//
// grants a privilege to an account 
//
// param:  hPolicy   - policy handle
//         privilege - privilege name
//         sid       - sid of the account
//         lastError - pointer to an error value
//
// return: success - 1 
//         failure - 0 (error code in lastError)
//
///////////////////////////////////////////////////////////////////////////////

BOOL AddPrivilegeToAccount(LSA_HANDLE hPolicy, PWSTR privilege, PSID sid, 
													 PDWORD lastError)
{
  LSA_UNICODE_STRING lsaPrivilege;

  InitLsaString(&lsaPrivilege, privilege);

  return !(*lastError = 
						LsaNtStatusToWinError(LsaAddAccountRights(hPolicy, sid,	&lsaPrivilege, 1)));
}


///////////////////////////////////////////////////////////////////////////////
//
// revokes a privilege from an account 
//
// param:  hPolicy   - policy handle
//         privilege - privilege name
//         sid       - sid of the account
//         lastError - pointer to an error value
//
// return: success - 1 
//         failure - 0 (error code in lastError)
//
///////////////////////////////////////////////////////////////////////////////

BOOL RevokePrivilegeFromAccount(LSA_HANDLE hPolicy, PWSTR privilege, PSID sid, 
																PDWORD lastError)
{
  LSA_UNICODE_STRING lsaPrivilege;

  InitLsaString(&lsaPrivilege, privilege);

  return !(*lastError = 
						LsaNtStatusToWinError(LsaRemoveAccountRights(hPolicy, sid,	FALSE,
																												 &lsaPrivilege, 1)));
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the sid from an account
//
// param:  server    - computer to execute the command
//         account   - account name
//         sid       - pointer to a sid
//         lastError - pointer to an error value
//
// return: success - 1 
//         failure - 0 (error code in lastError)
//
// note:   sid must be deallocated if the call was successfully
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetAccountSid(PSTR server, PSTR account, PSID *sid, PDWORD lastError)
{
	ErrorAndResult;

	PSTR domain = NULL;
	DWORD sidLen = 0, domainLen = 0;
	SID_NAME_USE sidUse = SidTypeUnknown;

	__try
	{
		// first get the memory needed
		LookupAccountName(server, account, *sid = NULL, &sidLen, domain, &domainLen, 
											&sidUse);

		// if the account exist, last error must be ERROR_INSUFFICIENT_BUFFER
		if(GetLastError() != ERROR_INSUFFICIENT_BUFFER)
			RaiseFalse();

		// alloc memory
		*sid = (PSTR)NewMem(sidLen);
		domain = (PSTR)NewMem(domainLen);

		// check memory allocation
		if(!*sid || !domain)
			RaiseFalseError(NOT_ENOUGTH_MEMORY_ERROR);

		// now get the sid
		if(!LookupAccountName(server, account, *sid, &sidLen, domain, &domainLen, &sidUse))
			RaiseFalse();
	}
	__except(GetExceptionCode() != 0)
	{
		SetErrorVar();
	}

	// forget domain name
	CleanPtr(domain);

	// on error deallocate memory
	if(error)
		CleanPtr(*sid);

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the account from a sid
//
// param:  server    - computer to execute the command
//         sid       - sid
//         account   - pointer to account name
//         lastError - pointer to an error value
//
// return: success - 1 
//         failure - 0 (error code in lastError)
//
// note:   account must be deallocated if the call was successfully
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetSidAccount(PSTR server, PSID sid, PSTR *domainAndAccount, PDWORD lastError)
{
	ErrorAndResult;

	PSTR account = NULL, domain = NULL;
	DWORD accountLen = 0, domainLen = 0;
	SID_NAME_USE sidUse = SidTypeUnknown;

	__try
	{
		// first get the memory needed
		LookupAccountSid(server, sid, account = NULL, &accountLen, domain, &domainLen, 
										 &sidUse);

		// if the account exist, last error must be ERROR_INSUFFICIENT_BUFFER
		if(GetLastError() != ERROR_INSUFFICIENT_BUFFER)
			RaiseFalse();

		// alloc memory
		account = (PSTR)NewMem(accountLen);
		domain = (PSTR)NewMem(domainLen);

		*domainAndAccount = (PSTR)NewMem(domainLen + accountLen);

		// check memory allocation
		if(!account || !domain || !*domainAndAccount)
			RaiseFalseError(NOT_ENOUGTH_MEMORY_ERROR);

		// now get the sid
		if(!LookupAccountSid(server, sid, account, &accountLen, domain, &domainLen, &sidUse))
			RaiseFalse();

		// save the result
		wsprintf(*domainAndAccount, "%s%s%s", domain ? domain : "", domain && *domain ? "\\" : "", 
																				  account);
	}
	__except(GetExceptionCode() != 0)
	{
		SetErrorVar();
	}

	// forget domain and account name
	CleanPtr(domain);
	CleanPtr(account);

	// on error deallocate memory
	if(error)
		CleanPtr(*domainAndAccount);


	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// grants a privilege to an array of accounts
//
// param:  server    - computer to execute the command
//         privilege - privilege name
//         accounts  - array of accounts
//
// return: success - 1 
//         failure - 0 
//
// note:   function aborts on the first error; call GetLastError() to get the 
//         error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GrantPrivilegeToAccount)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *accounts = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(accounts, ST(2)))
	{
		PWSTR server = NULL, privilege = NULL;
		PSID sid = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			privilege = S2W(SvPV(ST(1), PL_na));
			
			PSTR account = NULL;
 
			// first try open policy ...
			if(OpenPolicy(server, POLICY_ALL_ACCESS, &hPolicy, &error))
			{
				for(int count = 0; count <= AV_LEN(accounts); count++)
				{
					// ... now grant privilege to each account
					account = A_FETCH_STR(accounts, count);

					// get account sid and grant privilege
					if(!GetAccountSid(SvPV(ST(0), PL_na), account, &sid, &error) ||
						 !AddPrivilegeToAccount(hPolicy, privilege, sid, &error))
					{
						LastError(error);
						break;
					}

					// clear memory
					CleanPtr(account);
					CleanPtr(sid);
				}
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// close policy
		CleanLsaHandle(hPolicy);

		// clear memory
		CleanPtr(sid);
		FreeStr(server);
		FreeStr(privilege);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::GrantPrivilegeToAccount($server, $privilege, "
					"\\@accounts)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// revokes a privilege from an array of accounts
//
// param:  server    - computer to execute the command
//         privilege - privilege name
//         accounts  - array of accounts
//
// return: success - 1 
//         failure - 0 
//
// note:   function aborts on the first error; call GetLastError() to get the 
//         error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_RevokePrivilegeFromAccount)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *accounts = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(accounts, ST(2)))
	{
		PWSTR server = NULL, privilege = NULL;
		PSID sid = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			privilege = S2W(SvPV(ST(1), PL_na));

			PSTR account = NULL;

			// first try open policy ...
			if(OpenPolicy(server, POLICY_ALL_ACCESS, &hPolicy, &error))
				for(int count = 0; count <= AV_LEN(accounts); count++)
				{
					// ... now revoke privilege from each account
					account = A_FETCH_STR(accounts, count);

					// get account sid and revoke privilege
					if(!GetAccountSid(SvPV(ST(0), PL_na), account, &sid, &error) ||
						 !RevokePrivilegeFromAccount(hPolicy, privilege, sid, &error))
					{
						LastError(error);
						break;
					}

					// clear memory
					CleanPtr(account);
					CleanPtr(sid);
				}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanLsaHandle(hPolicy);
		CleanPtr(sid);
		FreeStr(server);
		FreeStr(privilege);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::RevokePrivilegeFromAccount($server, $privilege, "
					"\\@accounts)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums account privileges
//
// param:  server     - computer to execute the command
//         account    - account to enum privileges
//         privileges - array of granted privileges 
//
// return: success - 1 
//         failure - 0 
//
// note:   function aborts on the first error; call GetLastError() to get the 
//         error code on failure; if the account has not granted any 
//				 privileges, the error code is 2; this is not an error, it's by
//				 design
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_EnumAccountPrivileges)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *privileges = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(privileges, ST(2)))
	{
		PWSTR server = NULL, privilege = NULL;
		PSID sid = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_UNICODE_STRING lsaPrivileges = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSTR account = SvPV(ST(1), PL_na);
			DWORD numPrivileges = 0;

			// clear array
			AV_CLEAR(privileges);

			// first try open policy and get accounts sid ...
			if(OpenPolicy(server, POLICY_EXECUTE, &hPolicy, &error) &&
				 GetAccountSid(SvPV(ST(0), PL_na), account, &sid, &error) &&
				 !(error = LsaNtStatusToWinError(LsaEnumerateAccountRights(hPolicy, sid,
																																	 &lsaPrivileges, 
																																	 &numPrivileges))))
				for(DWORD count = 0; count < numPrivileges; count++)
				{
					privilege = 
						(PWSTR)NewMem(sizeof(WCHAR) * ((lsaPrivileges[count].Length >> 1) + 1));

					wcsncpy(privilege, lsaPrivileges[count].Buffer, lsaPrivileges[count].Length >> 1);
					privilege[lsaPrivileges[count].Length >> 1] = 0;
					
					// store privilege
					A_STORE_WSTR(privileges, privilege);
					
					// clean up
					CleanPtr(privilege);
				}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// close policy
		CleanLsaHandle(hPolicy);

		// clear memory
		CleanLsaPtr(lsaPrivileges);
		CleanPtr(sid);
		FreeStr(server);
		CleanPtr(privilege);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::EnumAccountPrivileges($server, $account, "
					"\\@privileges)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all accounts granted a privilege
//
// param:  server    - computer to execute the command
//         privilege - privilege to enum the accounts for
//         accounts  - array of granted accounts
//
// return: success - 1 
//         failure - 0 
//
// note:   function aborts on the first error; call GetLastError() to get the 
//         error code on failure; if the privilege is not granted to any 
//				 account, the error code is 259; this is not an error, it's by
//				 design
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_EnumPrivilegeAccounts)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *accounts = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(accounts, ST(2)))
	{
		PWSTR server = NULL, privilege = NULL;
		PSTR account = NULL;
		LSA_HANDLE hPolicy = NULL;
		LSA_UNICODE_STRING lsaPrivilege;
		PLSA_ENUMERATION_INFORMATION sids = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			privilege = S2W(SvPV(ST(1), PL_na));

			DWORD numSids = 0;

			// clear array
			AV_CLEAR(accounts);

			InitLsaString(&lsaPrivilege, privilege);

			// first try open policy and then get accounts
			if(OpenPolicy(server, POLICY_EXECUTE, &hPolicy, &error) &&
				 !(error = LsaNtStatusToWinError(
										 LsaEnumerateAccountsWithUserRight(hPolicy, &lsaPrivilege, 
																											 (PVOID*)&sids, &numSids))))
				for(DWORD count = 0; count < numSids; count++)
				{
					if(GetSidAccount(SvPV(ST(0), PL_na), sids[count].Sid, &account, &error))
						// store accounts
						A_STORE_STR(accounts, account);
					else
						A_STORE_STR(accounts, "");

					CleanPtr(account);
				}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// close policy
		CleanLsaHandle(hPolicy);

		// clear memory
		CleanLsaPtr(sids);
		CleanPtr(account);
		FreeStr(privilege);
		FreeStr(server);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::EnumPrivilegeAccounts($server, $privilege, "
					"\\@accounts)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// queries information about policy settings
//
// param:  server   - computer to execute the command
//				 infotype - requested information type
//				 info			- pointer to get the information
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaQueryInformationPolicy)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PVOID infoBuffer = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			POLICY_INFORMATION_CLASS infoType = (POLICY_INFORMATION_CLASS)SvIV(ST(1));
			DWORD access = 0;

			// determine access needed
			switch(infoType)
			{
				case PolicyAuditLogInformation:
				case PolicyAuditEventsInformation:
				case PolicyAuditFullQueryInformation:
					access = POLICY_VIEW_AUDIT_INFORMATION;
					break;

				case PolicyPrimaryDomainInformation:
				case PolicyAccountDomainInformation:
				case PolicyLsaServerRoleInformation:
				case PolicyReplicaSourceInformation:
				case PolicyDefaultQuotaInformation:
				case PolicyDnsDomainInformation:
					access = POLICY_VIEW_LOCAL_INFORMATION;
					break;

				// this call crashes the lsass service on the target machine
				//case PolicyMachinePasswordInformation:
				//	access = POLICY_AUDIT_LOG_ADMIN;
				//	break;

				case PolicyPdAccountInformation:
					access = POLICY_GET_PRIVATE_INFORMATION;
					break;
			}	

			// clear hash
			HV_CLEAR(info);

			// first try open policy
			if(OpenPolicy(server, access, &hPolicy, &error) &&
				 !(error = LsaNtStatusToWinError(
										LsaQueryInformationPolicy(hPolicy, infoType, &infoBuffer))))
			{
				switch(infoType)
				{
					case PolicyAuditLogInformation:
					{
						char longBuffer[32];

						H_STORE_INT(info, "auditlogpercentfull", 
												((PPOLICY_AUDIT_LOG_INFO)infoBuffer)->AuditLogPercentFull);
						H_STORE_INT(info, "maximumlogsize", 
												((PPOLICY_AUDIT_LOG_INFO)infoBuffer)->MaximumLogSize);
						sprintf(longBuffer, "%I64u", ((PPOLICY_AUDIT_LOG_INFO)infoBuffer)->AuditRetentionPeriod);
						H_STORE_STR(info, "auditretentionperiod", longBuffer);
						H_STORE_INT(info, "auditlogfullshutdowninprogress", 
												((PPOLICY_AUDIT_LOG_INFO)infoBuffer)->AuditLogFullShutdownInProgress);
						sprintf(longBuffer, "%I64u", ((PPOLICY_AUDIT_LOG_INFO)infoBuffer)->TimeToShutdown);
						H_STORE_STR(info, "timetoshutdown", longBuffer);
						H_STORE_INT(info, "nextauditrecordid", 
												((PPOLICY_AUDIT_LOG_INFO)infoBuffer)->NextAuditRecordId);
						break;
					}

					case PolicyAuditEventsInformation:
						H_STORE_INT(info, "auditingmode", 
												((PPOLICY_AUDIT_EVENTS_INFO)infoBuffer)->AuditingMode);
						if(((PPOLICY_AUDIT_EVENTS_INFO)infoBuffer)->MaximumAuditEventCount > 0)
						{
							PPOLICY_AUDIT_EVENTS_INFO auditEvents = (PPOLICY_AUDIT_EVENTS_INFO)infoBuffer;
							
							AV *options = NewAV;
							
							for(DWORD count = 0; count < auditEvents->MaximumAuditEventCount; count++)
								A_STORE_INT(options, auditEvents->EventAuditingOptions[count]);
						
							H_STORE_REF(info, "eventauditingoptions", options);

							// decrement reference count
							SvREFCNT_dec(options);
						}
						H_STORE_INT(info, "maximumauditeventcount", 
												((PPOLICY_AUDIT_EVENTS_INFO)infoBuffer)->MaximumAuditEventCount);
						break;
					
					case PolicyPrimaryDomainInformation:
					{
						PPOLICY_PRIMARY_DOMAIN_INFO primDomain = 
							(PPOLICY_PRIMARY_DOMAIN_INFO)infoBuffer;

						if(primDomain->Name.Buffer)
							H_STORE_WSTR(info, "name", primDomain->Name.Buffer);
						
						if(primDomain->Sid && IsValidSid(primDomain->Sid))
							H_STORE_PTR(info, "sid", primDomain->Sid, GetLengthSid(primDomain->Sid));
						break;
					}

					case PolicyPdAccountInformation:
					{
						// it doesn't work; the name is always empty
						PPOLICY_PD_ACCOUNT_INFO pdAccount = (PPOLICY_PD_ACCOUNT_INFO)infoBuffer;

						if(pdAccount)
							H_STORE_WSTR(info, "name", pdAccount->Name.Buffer);
						break;
					}
					
					case PolicyAccountDomainInformation:
					{
						PPOLICY_ACCOUNT_DOMAIN_INFO accDomain = 
							(PPOLICY_ACCOUNT_DOMAIN_INFO)infoBuffer;

						if(accDomain->DomainName.Buffer)
							H_STORE_WSTR(info, "domainname", accDomain->DomainName.Buffer);

						if(accDomain->DomainSid && IsValidSid(accDomain->DomainSid))
							H_STORE_PTR(info, "domainsid", accDomain->DomainSid,
													GetLengthSid(accDomain->DomainSid));
						break;
					}

					case PolicyLsaServerRoleInformation:
						H_STORE_INT(info, "serverrole", 
												((PPOLICY_LSA_SERVER_ROLE_INFO)infoBuffer)->LsaServerRole);
						break;
					
					case PolicyReplicaSourceInformation:
					{
						PPOLICY_REPLICA_SOURCE_INFO replSource = 
							(PPOLICY_REPLICA_SOURCE_INFO)infoBuffer;

						if(replSource)
						{
							H_STORE_WSTR(info, "replicasource", replSource->ReplicaSource.Buffer);
							H_STORE_WSTR(info, "replicaaccountname", 
													 replSource->ReplicaAccountName.Buffer);
						}
						break;
					}
					
					case PolicyDefaultQuotaInformation:
					{
						char longBuffer[32];
						PPOLICY_DEFAULT_QUOTA_INFO defQuota =
							(PPOLICY_DEFAULT_QUOTA_INFO)infoBuffer;

						if(defQuota)
						{
							H_STORE_INT(info, "pagedpoollimit", defQuota->QuotaLimits.PagedPoolLimit);
							H_STORE_INT(info, "nonpagedpoollimit", 
													defQuota->QuotaLimits.NonPagedPoolLimit);
							H_STORE_INT(info, "minimumworkingsetsize", 
													defQuota->QuotaLimits.MinimumWorkingSetSize);
							H_STORE_INT(info, "maximumworkingsetsize", 
													defQuota->QuotaLimits.MaximumWorkingSetSize);
							H_STORE_INT(info, "pagefilelimit", defQuota->QuotaLimits.PagefileLimit);
							sprintf(longBuffer, "%I64u", defQuota->QuotaLimits.TimeLimit);
							H_STORE_STR(info, "timelimit", longBuffer);
						}
						break;
					}
					
					case PolicyAuditFullQueryInformation:
						H_STORE_INT(info, "shutdownonfull", 
												((PPOLICY_AUDIT_FULL_QUERY_INFO)infoBuffer)->ShutDownOnFull);
						H_STORE_INT(info, "logisfull", 
												((PPOLICY_AUDIT_FULL_QUERY_INFO)infoBuffer)->LogIsFull);
						break;
					
					case PolicyDnsDomainInformation:
					{
						// supported by windows 2000 and later
						PPOLICY_DNS_DOMAIN_INFO dnsDomain = (PPOLICY_DNS_DOMAIN_INFO)infoBuffer;

						if(dnsDomain)
						{
							H_STORE_WSTR(info, "name", dnsDomain->Name.Buffer);
							H_STORE_WSTR(info, "dnsdomainname", dnsDomain->DnsDomainName.Buffer);
							H_STORE_WSTR(info, "dnsforestname", dnsDomain->DnsForestName.Buffer);
							H_STORE_PTR(info, "domainguid", &dnsDomain->DomainGuid, sizeof(GUID));
							H_STORE_PTR(info, "sid", dnsDomain->Sid, GetLengthSid(dnsDomain->Sid));
						}
						break;
					}

					// this call crashes the lsass service on the target machine
					/*
					case PolicyMachinePasswordInformation:
					{
						PPOLICY_MACHINE_PASSWORD_INFO machPassword =	
							(PPOLICY_MACHINE_PASSWORD_INFO)infoBuffer;
						char longBuffer[32];

						sprintf(longBuffer, "%I64u", machPassword->PasswordChangeInterval);
						H_STORE_STR(info, "passwordchangeinterval", longBuffer);

						break;
					}
					*/
				}
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(infoBuffer);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaQueryInformationPolicy($server, $infotype, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// set policy settings
//
// param:  server   - computer to execute the command
//				 infotype - information type to set
//				 info			- information to set
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaSetInformationPolicy)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_HREF(info, ST(2)))
	{
		PWSTR server = NULL;
		PVOID infoBuffer = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			POLICY_INFORMATION_CLASS infoType = (POLICY_INFORMATION_CLASS)SvIV(ST(1));
			DWORD access = 0;

			// determine access needed
			switch(infoType)
			{
				case PolicyAuditEventsInformation:
				{
					// get the array pointer
					AV *options = H_FETCH_RARRAY(info, "eventauditingoptions");
					
					// calculate the array size
					DWORD numOptions = options ? AV_LEN(options) + 1 : 0;
					
					// the working structure
					PPOLICY_AUDIT_EVENTS_INFO inf = 
						(PPOLICY_AUDIT_EVENTS_INFO)
							NewMem(sizeof(POLICY_AUDIT_EVENTS_INFO) + numOptions  * sizeof(DWORD));

					// set elemets
					inf->AuditingMode = H_FETCH_INT(info, "auditingmode");
					inf->MaximumAuditEventCount = numOptions;

					// copy array elements
					inf->EventAuditingOptions = 
						(PPOLICY_AUDIT_EVENT_OPTIONS)((PSTR)inf + sizeof(POLICY_AUDIT_EVENTS_INFO));

					for(DWORD count = 0; count < numOptions; count++)
						inf->EventAuditingOptions[count] = A_FETCH_INT(options, count);

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_SET_AUDIT_REQUIREMENTS;
					break;
				}

				case PolicyPrimaryDomainInformation:
				{
					// get name and sid, calculate size
					PSTR name = H_FETCH_STR(info, "name");
					PSID sid = H_FETCH_STR(info, "sid");
					DWORD nameSize = name ? strlen(name) + 1 : 0, 
								sidSize = sid ? GetLengthSid(sid) : 0;
					
					// the working structure
					PPOLICY_PRIMARY_DOMAIN_INFO inf = 
						(PPOLICY_PRIMARY_DOMAIN_INFO)
							NewMem(sizeof(POLICY_PRIMARY_DOMAIN_INFO) + nameSize * sizeof(WCHAR) + sidSize);

					if(name)
					{
						inf->Name.MaximumLength = (USHORT)nameSize * sizeof(WCHAR);
						inf->Name.Length = inf->Name.MaximumLength - sizeof(WCHAR);
						inf->Name.Buffer = 
							(PWSTR)((PSTR)inf + sizeof(LSA_UNICODE_STRING) + sizeof(PSID));
						MBTWC(name, inf->Name.Buffer, nameSize * sizeof(WCHAR));
					}
					else
					{
						inf->Name.Length = inf->Name.MaximumLength = 0;
						inf->Name.Buffer = NULL;
					}

					if(sid)
						memcpy(inf->Sid = (PSTR)inf + sizeof(LSA_UNICODE_STRING) + 
																sizeof(PSID) + inf->Name.MaximumLength, 
									 sid, sidSize);
					else
						inf->Sid = NULL;

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_TRUST_ADMIN;
					break;
				}

				case PolicyAccountDomainInformation:
				{
					// get name and sid, calculate size
					PSTR name = H_FETCH_STR(info, "domainname");
					PSID sid = H_FETCH_STR(info, "domainsid");
					DWORD nameSize = name ? strlen(name) + 1 : 0, 
								sidSize = sid ? GetLengthSid(sid) : 0;
					
					// the working structure
					PPOLICY_ACCOUNT_DOMAIN_INFO inf = 
						(PPOLICY_ACCOUNT_DOMAIN_INFO)
							NewMem(sizeof(POLICY_ACCOUNT_DOMAIN_INFO) + nameSize * sizeof(WCHAR) + sidSize);

					if(name)
					{
						inf->DomainName.MaximumLength = (USHORT)nameSize * sizeof(WCHAR);
						inf->DomainName.Length = inf->DomainName.MaximumLength - sizeof(WCHAR);
						inf->DomainName.Buffer = 
							(PWSTR)((PSTR)inf + sizeof(LSA_UNICODE_STRING) + sizeof(PSID));
						MBTWC(name, inf->DomainName.Buffer, nameSize * sizeof(WCHAR));
					}
					else
					{
						inf->DomainName.Length = inf->DomainName.MaximumLength = 0;
						inf->DomainName.Buffer = NULL;
					}

					if(sid)
						memcpy(inf->DomainSid = (PSTR)inf + sizeof(LSA_UNICODE_STRING) + 
																		sizeof(PSID) + inf->DomainName.MaximumLength, 
									 sid, sidSize);
					else
						inf->DomainSid = NULL;

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_TRUST_ADMIN;
					break;
				}

				case PolicyLsaServerRoleInformation:
				{
					PPOLICY_LSA_SERVER_ROLE_INFO inf = 
						(PPOLICY_LSA_SERVER_ROLE_INFO)NewMem(sizeof(POLICY_LSA_SERVER_ROLE_INFO));
					
					inf->LsaServerRole = (POLICY_LSA_SERVER_ROLE)H_FETCH_INT(info, "serverrole");

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_SERVER_ADMIN;
					break;
				}

				case PolicyReplicaSourceInformation:
				{
					// get source and account, calculate size
					PSTR source = H_FETCH_STR(info, "replicasource");
					PSTR account = H_FETCH_STR(info, "replicaaccountname");
					DWORD sourceSize = source ? strlen(source) + 1 : 0, 
								accountSize = account ? strlen(account) + 1 : 0;
				
					// the working structure
					PPOLICY_REPLICA_SOURCE_INFO inf = 
						(PPOLICY_REPLICA_SOURCE_INFO)
							NewMem(sizeof(POLICY_REPLICA_SOURCE_INFO) + sourceSize * sizeof(WCHAR) + 
										 accountSize * sizeof(WCHAR));

					if(source)
					{
						inf->ReplicaSource.MaximumLength = (USHORT)sourceSize * sizeof(WCHAR);
						inf->ReplicaSource.Length = inf->ReplicaSource.MaximumLength - sizeof(WCHAR);
						inf->ReplicaSource.Buffer = 
							(PWSTR)((PSTR)inf + sizeof(POLICY_REPLICA_SOURCE_INFO));
						MBTWC(source, inf->ReplicaSource.Buffer, sourceSize * sizeof(WCHAR));
					}
					else
					{
						inf->ReplicaSource.Length = inf->ReplicaSource.MaximumLength = 0;
						inf->ReplicaSource.Buffer = NULL;
					}

					if(account)
					{
						inf->ReplicaAccountName.MaximumLength = (USHORT)accountSize * sizeof(WCHAR);
						inf->ReplicaAccountName.Length = 
							inf->ReplicaAccountName.MaximumLength - sizeof(WCHAR);
						
						if(inf->ReplicaSource.Buffer)
							inf->ReplicaAccountName.Buffer = 
								(PWSTR)((PSTR)inf->ReplicaSource.Buffer + 
												inf->ReplicaSource.MaximumLength);
						else
							inf->ReplicaAccountName.Buffer = 
								(PWSTR)((PSTR)inf + sizeof(POLICY_REPLICA_SOURCE_INFO));
						
						MBTWC(account, inf->ReplicaAccountName.Buffer, accountSize * sizeof(WCHAR));
					}
					else
					{
						inf->ReplicaAccountName.Length = inf->ReplicaAccountName.MaximumLength = 0;
						inf->ReplicaAccountName.Buffer = NULL;
					}

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_SERVER_ADMIN;
					break;
				}

				case PolicyDefaultQuotaInformation:
				{
					PPOLICY_DEFAULT_QUOTA_INFO inf = 
						(PPOLICY_DEFAULT_QUOTA_INFO)NewMem(sizeof(POLICY_DEFAULT_QUOTA_INFO));

					inf->QuotaLimits.PagedPoolLimit = H_FETCH_INT(info, "pagedpoollimit");
					inf->QuotaLimits.NonPagedPoolLimit = H_FETCH_INT(info, "nonpagedpoollimit");
					inf->QuotaLimits.MinimumWorkingSetSize = 
						H_FETCH_INT(info, "minimumworkingsetsize");
					inf->QuotaLimits.MaximumWorkingSetSize = 
						H_FETCH_INT(info, "maximumworkingsetsize");
					inf->QuotaLimits.PagefileLimit = H_FETCH_INT(info, "pagefilelimit");

					PSTR timeLimit = H_FETCH_STR(info, "timelimit");
					if(timeLimit)
						sscanf(timeLimit, "%I64u", &inf->QuotaLimits.TimeLimit);
					else
						inf->QuotaLimits.TimeLimit.QuadPart = 0;

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_SET_DEFAULT_QUOTA_LIMITS;
					break;
				}

				case PolicyAuditFullSetInformation:
				{
					PPOLICY_AUDIT_FULL_SET_INFO inf = 
						(PPOLICY_AUDIT_FULL_SET_INFO)NewMem(sizeof(POLICY_AUDIT_FULL_SET_INFO));

					inf->ShutDownOnFull = H_FETCH_INT(info, "shutdownonfull");
					
					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_AUDIT_LOG_ADMIN;
					break;
				}

				case PolicyDnsDomainInformation:
				{
					// get source and account, calculate size
					PSTR name = H_FETCH_STR(info, "name");
					PSTR dnsDomainName = H_FETCH_STR(info, "dnsdomainname");
					PSTR dnsForestName = H_FETCH_STR(info, "dnsforestname");
					GUID *guid = (GUID*)H_FETCH_STR(info, "guid");
					PSID sid = (PSID)H_FETCH_STR(info, "sid");
					DWORD nameSize = name ? strlen(name) + 1 : 0, 
								dnsDomainNameSize = dnsDomainName ? strlen(dnsDomainName) + 1 : 0,
								dnsForestNameSize = dnsForestName ? strlen(dnsForestName) + 1 : 0,
								guidSize = guid ? __min(H_FETCH_SIZE(info, "guid"), sizeof(GUID)) : 0,
								sidSize = sid ? GetLengthSid(sid) : 0;

					PPOLICY_DNS_DOMAIN_INFO inf = 
						(PPOLICY_DNS_DOMAIN_INFO)NewMem(sizeof(POLICY_DNS_DOMAIN_INFO) +
																						nameSize * sizeof(WCHAR) +
																						dnsDomainNameSize * sizeof(WCHAR) +
																						dnsForestNameSize * sizeof(WCHAR) +
																						sidSize);

					PSTR copyPtr = (PSTR)inf + sizeof(POLICY_DNS_DOMAIN_INFO);

					memset(&inf->DomainGuid, 0, sizeof(GUID));
					if(guid)
						memcpy(&inf->DomainGuid, guid, guidSize);

					if(name)
					{
						inf->Name.MaximumLength = (USHORT)nameSize * sizeof(WCHAR);
						inf->Name.Length = inf->Name.MaximumLength - sizeof(WCHAR);
						inf->Name.Buffer = (PWSTR)copyPtr;
						copyPtr += inf->Name.MaximumLength;
						MBTWC(name, inf->Name.Buffer, nameSize * sizeof(WCHAR));
					}
					else
					{
						inf->Name.Length = inf->Name.MaximumLength = 0;
						inf->Name.Buffer = NULL;
					}

					if(dnsDomainName)
					{
						inf->DnsDomainName.MaximumLength = (USHORT)dnsDomainNameSize * sizeof(WCHAR);
						inf->DnsDomainName.Length = inf->DnsDomainName.MaximumLength - sizeof(WCHAR);
						inf->DnsDomainName.Buffer = (PWSTR)copyPtr;
						copyPtr += inf->DnsDomainName.MaximumLength;
						MBTWC(dnsDomainName, inf->DnsDomainName.Buffer, dnsDomainNameSize * sizeof(WCHAR));
					}
					else
					{
						inf->DnsDomainName.Length = inf->DnsDomainName.MaximumLength = 0;
						inf->DnsDomainName.Buffer = NULL;
					}

					if(dnsForestName)
					{
						inf->DnsForestName.MaximumLength = (USHORT)dnsForestNameSize * sizeof(WCHAR);
						inf->DnsForestName.Length = inf->DnsForestName.MaximumLength - sizeof(WCHAR);
						inf->DnsForestName.Buffer = (PWSTR)copyPtr;
						copyPtr += inf->DnsForestName.MaximumLength;
						MBTWC(dnsForestName, inf->DnsForestName.Buffer, dnsForestNameSize * sizeof(WCHAR));
					}
					else
					{
						inf->DnsForestName.Length = inf->DnsForestName.MaximumLength = 0;
						inf->DnsForestName.Buffer = NULL;
					}

					if(sid)
						memcpy(inf->Sid = (PSID)copyPtr, sid, sidSize);
					else
						inf->Sid = NULL;

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_TRUST_ADMIN;
					break;
				}

				// this call does not work, you'll always get an eror code 1733
				/*
				case PolicyMachinePasswordInformation:
				{
					PPOLICY_MACHINE_PASSWORD_INFO inf =	
						(PPOLICY_MACHINE_PASSWORD_INFO)NewMem(sizeof(POLICY_MACHINE_PASSWORD_INFO));
					PSTR passwordChangeInterval = H_FETCH_STR(info, "passwordchangeinterval");

					if(passwordChangeInterval)
						sscanf(passwordChangeInterval, "%I64u", &inf->PasswordChangeInterval);
					else
						inf->PasswordChangeInterval.QuadPart = 0;

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_AUDIT_LOG_ADMIN;
					break;
				}
				*/
			}	

			// first try open policy
			if(!OpenPolicy(server, access, &hPolicy, &error) ||
				 (error = LsaNtStatusToWinError(
										LsaSetInformationPolicy(hPolicy, infoType, infoBuffer))))
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(infoBuffer);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaSetInformationPolicy($server, $infotype, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enumerates all trusted domains
//
// param:  server  - computer to execute the command
//				 domains - array to get the domains
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaEnumerateTrustedDomains)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *trustedDomains = NULL;

	// check argument type
	if(items == 2 && CHK_ASSIGN_AREF(trustedDomains, ST(1)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_TRUST_INFORMATION domains = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			LSA_ENUMERATION_HANDLE context = NULL;
			DWORD numDomains = 0;

			AV_CLEAR(trustedDomains);

			// first try open policy
			if(OpenPolicy(server, POLICY_VIEW_LOCAL_INFORMATION, &hPolicy, &error))
			{
				error = LsaEnumerateTrustedDomains(hPolicy, &context, (PVOID*)&domains, 
																					 0xffffffff, &numDomains);
				
				if(!(error = LsaNtStatusToWinError(error)) || error == ERROR_NO_MORE_ITEMS)
					for(DWORD count = 0; count < numDomains; count++)
					{
						HV *prop = NewHV;

						if(domains[count].Name.Buffer)
							H_STORE_WSTR(prop, "name", domains[count].Name.Buffer);

						if(domains[count].Sid)
							H_STORE_PTR(prop, "sid", domains[count].Sid, GetLengthSid(domains[count].Sid));

						A_STORE_REF(trustedDomains, prop);

						// decrement reference count
						SvREFCNT_dec(prop);

					} // for(DWORD count = 0; count < numDomains; count++)
				else
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(domains);
	} // if(items == 2 && ...
	else
		croak("Usage: Win32::Lanman::LsaEnumerateTrustedDomains($server, \\@domains)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// looks up for account names
//
// param:  server  - computer to execute the command
//				 info    - gets the sids and other information
//
// return: success - 1 
//         failure - 0 
//
// note:   there will no error generated, if not all accounts could be resolved;
//				 the use flag will be set to SidTypeUnknown (8) if the account 
//				 couldn't be resolved
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaLookupNames)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *accounts = NULL;
	AV *info = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(accounts, ST(1)) && CHK_ASSIGN_AREF(info, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_UNICODE_STRING names = NULL;
		PLSA_REFERENCED_DOMAIN_LIST refDomains = NULL;
		PLSA_TRANSLATED_SID transSids = NULL;
		PSID sid = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			AV_CLEAR(info);

			// first try open policy
			if(OpenPolicy(server, POLICY_LOOKUP_NAMES, &hPolicy, &error))
			{
				DWORD numAccounts = AV_LEN(accounts) + 1;
				PSTR name = NULL, copyPtr = NULL;

				for(DWORD count = 0, size = 0; count < numAccounts; count++)
					if(name = A_FETCH_STR(accounts, count))
						size += sizeof(LSA_UNICODE_STRING) + (strlen(name) + 1) * sizeof(WCHAR);

				names = (PLSA_UNICODE_STRING)NewMem(size);
				copyPtr = (PSTR)names + sizeof(LSA_UNICODE_STRING) * numAccounts;

				for(count = 0; count < numAccounts; count++)
					if(name = A_FETCH_STR(accounts, count))
					{
						DWORD nameSize = (strlen(name) + 1) * sizeof(WCHAR);

						names[count].MaximumLength = (USHORT)nameSize;
						names[count].Length = names[count].MaximumLength - sizeof(WCHAR);
						MBTWC(name, names[count].Buffer = (PWSTR)copyPtr, nameSize);
						copyPtr += nameSize;
					}

				error = LsaLookupNames(hPolicy, numAccounts, names, &refDomains, &transSids);
				
				if(!(error = LsaNtStatusToWinError(error)) || error == ERROR_SOME_NOT_MAPPED)
				{
					error = 0;

					for(count = 0; count < numAccounts; count++)
					{
						HV *prop = NewHV;

						// store members
						H_STORE_INT(prop, "use", transSids[count].Use);

						if(transSids[count].Use != SidTypeDomain && 
							 transSids[count].Use != SidTypeInvalid &&
							 transSids[count].Use != SidTypeUnknown)
							H_STORE_INT(prop, "relativeid", transSids[count].RelativeId);

						if(transSids[count].Use != SidTypeInvalid &&
							 transSids[count].Use != SidTypeUnknown &&
							 transSids[count].DomainIndex >= 0 && 
							 transSids[count].DomainIndex < (int)refDomains->Entries)
						{
							PLSA_TRUST_INFORMATION domainInfo = 
								refDomains->Domains + transSids[count].DomainIndex;

							if(domainInfo->Name.Buffer)
								H_STORE_WSTR(prop, "domain", domainInfo->Name.Buffer);

							if(domainInfo->Sid && IsValidSid(domainInfo->Sid))
							{
								DWORD sidLen = GetLengthSid(domainInfo->Sid);

								H_STORE_PTR(prop, "domainsid", domainInfo->Sid, sidLen);
								
								// build the user sid quickly from the domain sid and the rid;
								// as first allec memory (one subauthority more than the domain)
								sid = (PSID)NewMem(sidLen + sizeof(DWORD));

								// copy the domain sid
								CopySid(sidLen, sid, domainInfo->Sid);

								// increment the subauthority count
								((PBYTE)sid)[1]++;

								// append the rid
								*(PDWORD)((PSTR)sid + sidLen) = transSids[count].RelativeId;

								H_STORE_PTR(prop, "sid", sid, sidLen + sizeof(DWORD));
								CleanPtr(sid);
							}
						}

						A_STORE_REF(info, prop);

						// decrement reference count
						SvREFCNT_dec(prop);
					} // for(DWORD count = 0; count < numDomains; count++)
				} // if(!(error = LsaNtStatusToWinError(error)) || error == ERROR_SOME_NOT_MAPPED)
				else
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(refDomains);
		CleanLsaPtr(transSids);
		CleanPtr(names);
		CleanPtr(sid);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaLookupNames($server, \\@accounts, \\@info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// looks up for account names
//
// param:  server  - computer to execute the command
//				 info    - gets the sids and other information
//
// return: success - 1 
//         failure - 0 
//
// note:   there will no error generated, if not all accounts could be resolved;
//				 the use flag will be set to SidTypeUnknown (8) if the account 
//				 couldn't be resolved
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaLookupNamesEx)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *accounts = NULL;
	AV *info = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(accounts, ST(1)) && CHK_ASSIGN_AREF(info, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_UNICODE_STRING names = NULL;
		PLSA_REFERENCED_DOMAIN_LIST refDomains = NULL;
		PLSA_TRANSLATED_SID transSids = NULL;
		PSID sid = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			AV_CLEAR(info);

			// first try open policy
			if(OpenPolicy(server, POLICY_LOOKUP_NAMES, &hPolicy, &error))
			{
				DWORD numAccounts = AV_LEN(accounts) + 1;
				PSTR name = NULL, copyPtr = NULL;

				for(DWORD count = 0, size = 0; count < numAccounts; count++)
					if(name = A_FETCH_STR(accounts, count))
						size += sizeof(LSA_UNICODE_STRING) + (strlen(name) + 1) * sizeof(WCHAR);

				names = (PLSA_UNICODE_STRING)NewMem(size);
				copyPtr = (PSTR)names + sizeof(LSA_UNICODE_STRING) * numAccounts;

				for(count = 0; count < numAccounts; count++)
					if(name = A_FETCH_STR(accounts, count))
					{
						DWORD nameSize = (strlen(name) + 1) * sizeof(WCHAR);

						names[count].MaximumLength = (USHORT)nameSize;
						names[count].Length = names[count].MaximumLength - sizeof(WCHAR);
						MBTWC(name, names[count].Buffer = (PWSTR)copyPtr, nameSize);
						copyPtr += nameSize;
					}

				error = LsaLookupNames(hPolicy, numAccounts, names, &refDomains, &transSids);
				
				if(!(error = LsaNtStatusToWinError(error)) || error == ERROR_SOME_NOT_MAPPED)
				{
					error = 0;

					for(count = 0; count < numAccounts; count++)
					{
						HV *prop = NewHV;

						// store members
						H_STORE_INT(prop, "use", transSids[count].Use);

						if(transSids[count].Use != SidTypeDomain && 
							 transSids[count].Use != SidTypeInvalid &&
							 transSids[count].Use != SidTypeUnknown)
							H_STORE_INT(prop, "relativeid", transSids[count].RelativeId);

						if(transSids[count].Use != SidTypeInvalid &&
							 transSids[count].Use != SidTypeUnknown &&
							 transSids[count].DomainIndex >= 0 && 
							 transSids[count].DomainIndex < (int)refDomains->Entries)
						{
							PLSA_TRUST_INFORMATION domainInfo = 
								refDomains->Domains + transSids[count].DomainIndex;

							if(domainInfo->Name.Buffer)
								H_STORE_WSTR(prop, "domain", domainInfo->Name.Buffer);

							if(domainInfo->Sid && IsValidSid(domainInfo->Sid))
							{
								DWORD sidLen = GetLengthSid(domainInfo->Sid);

								H_STORE_PTR(prop, "domainsid", domainInfo->Sid, sidLen);
								
								// build the user sid quickly from the domain sid and the rid;
								// as first allec memory (one subauthority more than the domain)
								sid = (PSID)NewMem(sidLen + sizeof(DWORD));

								// copy the domain sid
								CopySid(sidLen, sid, domainInfo->Sid);

								// increment the subauthority count
								((PBYTE)sid)[1]++;

								// append the rid
								*(PDWORD)((PSTR)sid + sidLen) = transSids[count].RelativeId;

								H_STORE_PTR(prop, "sid", sid, sidLen + sizeof(DWORD));
								CleanPtr(sid);
							}
						}

						A_STORE_REF(info, prop);

						// decrement reference count
						SvREFCNT_dec(prop);
					} // for(DWORD count = 0; count < numDomains; count++)
				} // if(!(error = LsaNtStatusToWinError(error)) || error == ERROR_SOME_NOT_MAPPED)
				else
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(refDomains);
		CleanLsaPtr(transSids);
		CleanPtr(names);
		CleanPtr(sid);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaLookupNamesEx($server, \\@accounts, \\@info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// looks up for account sids
//
// param:  server  - computer to execute the command
//				 info    - gets the accounts and other information
//
// return: success - 1 
//         failure - 0 
//
// note:   there will no error generated, if not all sids could be resolved;
//				 the use flag will be set to SidTypeInvalid (7) or SidTypeUnknown (8) 
//				 if the sid couldn't be resolved
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaLookupSids)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *sids = NULL;
	AV *info = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(sids, ST(1)) && CHK_ASSIGN_AREF(info, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PSID *sidArray = NULL;
		PLSA_TRANSLATED_NAME names = NULL;
		PLSA_REFERENCED_DOMAIN_LIST refDomains = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			AV_CLEAR(info);

			// first try open policy
			if(OpenPolicy(server, POLICY_LOOKUP_NAMES, &hPolicy, &error))
			{
				DWORD numSids = AV_LEN(sids) + 1;
				PSID sid = NULL;
				PSTR copyPtr = NULL;

				for(DWORD count = 0, size = 0; count < numSids; count++)
					if(sid = A_FETCH_STR(sids, count))
						size += sizeof(PSID) + A_FETCH_SLEN(sids, count);

				sidArray = (PSID*)NewMem(size);
				copyPtr = (PSTR)sidArray + sizeof(PSID) * numSids;

				for(count = 0; count < numSids; count++)
					if(sid = A_FETCH_STR(sids, count))
					{
						DWORD sidLen = A_FETCH_SLEN(sids, count);

						memcpy(sidArray[count] = (PSID*)copyPtr, sid, sidLen);
						copyPtr += sidLen;
					}

				error = LsaLookupSids(hPolicy, numSids, sidArray, &refDomains, &names);
				
				if(!(error = LsaNtStatusToWinError(error)) || error == ERROR_SOME_NOT_MAPPED)
					for(count = 0; count < numSids; count++)
					{
						HV *prop = NewHV;

						// store members
						H_STORE_INT(prop, "use", names[count].Use);

						if(names[count].Use != SidTypeDomain && 
							 names[count].Use != SidTypeInvalid &&
							 names[count].Use != SidTypeUnknown)
							H_STORE_WNSTR(prop, "name", names[count].Name.Buffer, 
														names[count].Name.Length / sizeof(WCHAR) + 1);

						if(names[count].Use != SidTypeInvalid &&
							 names[count].Use != SidTypeUnknown &&
							 names[count].Use != SidTypeWellKnownGroup &&
							 names[count].DomainIndex >= 0 && 
							 names[count].DomainIndex < (int)refDomains->Entries)
						{

							PLSA_TRUST_INFORMATION domainInfo = 
								refDomains->Domains + names[count].DomainIndex;

							if(domainInfo->Name.Buffer)
								H_STORE_WSTR(prop, "domain", domainInfo->Name.Buffer);

							if(domainInfo->Sid && IsValidSid(domainInfo->Sid))
							{
								DWORD sidLen = GetLengthSid(domainInfo->Sid);

								H_STORE_PTR(prop, "domainsid", domainInfo->Sid, sidLen);
							}
						}

						A_STORE_REF(info, prop);

						// decrement reference count
						SvREFCNT_dec(prop);
					} // for(DWORD count = 0; count < numDomains; count++)
				else
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(sidArray);
		CleanLsaPtr(refDomains);
		CleanLsaPtr(names);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaLookupSids($server, \\@sids, \\@info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all sids granted a privilege
//
// param:  server    - computer to execute the command
//         privilege - privilege to enum the accounts for
//         sids      - array of sids granted the privilege
//
// return: success - 1 
//         failure - 0 
//
// note:   function aborts on the first error; call GetLastError() to get the 
//         error code on failure; if the privilege is not granted to any 
//				 account, the error code is 259; this is not an error, it's by
//				 design
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaEnumerateAccountsWithUserRight)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *sidArray = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(sidArray, ST(2)))
	{
		PWSTR server = NULL, privilege = NULL;
		LSA_HANDLE hPolicy = NULL;
		LSA_UNICODE_STRING lsaPrivilege = {0, 0, NULL};
		PLSA_ENUMERATION_INFORMATION sids = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			privilege = S2W(SvPV(ST(1), PL_na));

			DWORD numSids = 0;

			// clear array
			AV_CLEAR(sidArray);

			if(privilege && *privilege)
				InitLsaString(&lsaPrivilege, privilege);

			// first try open policy and then get accounts
			if(OpenPolicy(server, POLICY_EXECUTE, &hPolicy, &error) &&
				 !(error = LsaNtStatusToWinError(
										 LsaEnumerateAccountsWithUserRight(hPolicy, &lsaPrivilege, 
																											 (PVOID*)&sids, &numSids))))
				for(DWORD count = 0; count < numSids; count++)
					if(IsValidSid(sids[count].Sid))
						A_STORE_PTR(sidArray, sids[count].Sid, GetLengthSid(sids[count].Sid));
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(sids);
		FreeStr(privilege);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaEnumerateAccountsWithUserRight($server, $privilege, \\@sids)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enums all privileges granted to a sid
//
// param:  server     - computer to execute the command
//				 sid        - sid to enum the privileges for
//         privileges - array of privileges
//
// return: success - 1 
//         failure - 0 
//
// note:   function aborts on the first error; call GetLastError() to get the 
//         error code on failure; if the account has not granted any 
//				 privileges, the error code is 2; this is not an error, it's by
//				 design
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaEnumerateAccountRights)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *privileges = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(privileges, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_UNICODE_STRING lsaPrivileges = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSID sid = SvPV(ST(1), PL_na);
			DWORD numPrivileges = 0;

			// clear array
			AV_CLEAR(privileges);

			// first try open policy and get accounts sid ...
			if(OpenPolicy(server, POLICY_EXECUTE, &hPolicy, &error) &&
				 !(error = LsaNtStatusToWinError(LsaEnumerateAccountRights(hPolicy, sid,
																																	 &lsaPrivileges, 
																																	 &numPrivileges))))
				for(DWORD count = 0; count < numPrivileges; count++)
					// store privilege
					if(lsaPrivileges[count].Buffer)
						A_STORE_WNSTR(privileges, lsaPrivileges[count].Buffer, 
													lsaPrivileges[count].Length / sizeof(WCHAR) + 1);
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(lsaPrivileges);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaEnumerateAccountRights($server, $sid, \\@privileges)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// grants some privileges to a sid
//
// param:  server     - computer to execute the command
//				 sid        - sid to grant the privileges for
//         privileges - array of privilege names
//
// return: success - 1 
//         failure - 0 
//
// note:   the LsaAddAccountRights call creates a new account if the sid
//				 does not belong to a account
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaAddAccountRights)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *privileges = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_AREF(privileges, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_UNICODE_STRING privs = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSID sid = SvPV(ST(1), PL_na);

			// first try open policy ...
			if(OpenPolicy(server, POLICY_LOOKUP_NAMES | POLICY_CREATE_ACCOUNT, &hPolicy, &error))
			{
				DWORD numPrivs = AV_LEN(privileges) + 1;
				PSTR privName = NULL, copyPtr = NULL;

				// get size needed
				for(DWORD count = 0, size = 0; count < numPrivs; count++)
					if(privName = A_FETCH_STR(privileges, count))
						size += sizeof(LSA_UNICODE_STRING) + (strlen(privName) + 1) * sizeof(WCHAR);

				// alloc size and set the copy pointer behind the lsa array
				privs = (PLSA_UNICODE_STRING)NewMem(size);
				copyPtr = (PSTR)privs + sizeof(LSA_UNICODE_STRING) * numPrivs;

				// copy the values
				for(count = 0; count < numPrivs; count++)
					if(privName = A_FETCH_STR(privileges, count))
					{
						privs[count].Length = strlen(privName) * sizeof(WCHAR);
						privs[count].MaximumLength = privs[count].Length + sizeof(WCHAR);
						privs[count].Buffer = (PWCHAR)copyPtr;
						MBTWC(privName, privs[count].Buffer, privs[count].MaximumLength);
						copyPtr += privs[count].MaximumLength;
					}

				// grant privileges
				error = LsaAddAccountRights(hPolicy, sid,	privs, numPrivs);

				if(error = LsaNtStatusToWinError(error))
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(privs);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaAddAccountRights($server, $sid, \\@privileges)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// removes some privileges from a sid
//
// param:  server     - computer to execute the command
//				 sid        - sid to remove the privileges for
//         privileges - array of privilege names
//				 all				- if true, all privileges will be removed
//
// return: success - 1 
//         failure - 0 
//
// note:   if the optional all parameter ist true, all privileges will be 
//				 removed; in this case the privileges parameter has no meaning
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaRemoveAccountRights)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	AV *privileges = NULL;

	// check argument type
	if((items == 3 || items == 4) && CHK_ASSIGN_AREF(privileges, ST(2)))
	{
		PWSTR server = NULL;
		LSA_HANDLE hPolicy = NULL;
		PLSA_UNICODE_STRING privs = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSID sid = SvPV(ST(1), PL_na);
			BOOL delAllPrivs = items == 4 ? SvIV(ST(3)) : 0;

			// first try open policy ...
			if(OpenPolicy(server, POLICY_LOOKUP_NAMES | POLICY_CREATE_ACCOUNT, &hPolicy, &error))
			{
				DWORD numPrivs = AV_LEN(privileges) + 1;
				PSTR privName = NULL, copyPtr = NULL;

				if(!delAllPrivs)
				{
					// get size needed
					for(DWORD count = 0, size = 0; count < numPrivs; count++)
						if(privName = A_FETCH_STR(privileges, count))
							size += sizeof(LSA_UNICODE_STRING) + (strlen(privName) + 1) * sizeof(WCHAR);

					// alloc size and set the copy pointer behind the lsa array
					privs = (PLSA_UNICODE_STRING)NewMem(size);
					copyPtr = (PSTR)privs + sizeof(LSA_UNICODE_STRING) * numPrivs;

					// copy the values
					for(count = 0; count < numPrivs; count++)
						if(privName = A_FETCH_STR(privileges, count))
						{
							privs[count].Length = strlen(privName) * sizeof(WCHAR);
							privs[count].MaximumLength = privs[count].Length + sizeof(WCHAR);
							privs[count].Buffer = (PWCHAR)copyPtr;
							MBTWC(privName, privs[count].Buffer, privs[count].MaximumLength);
							copyPtr += privs[count].MaximumLength;
						}
				}

				// grant privileges
				error = LsaRemoveAccountRights(hPolicy, sid, delAllPrivs, privs, numPrivs);

				if(error = LsaNtStatusToWinError(error))
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(privs);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaRemoveAccountRights($server, $sid, \\@privileges, [$all])\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about trusted domains
//
// param:  server    - computer to execute the command
//				 domainsid - sid of trusted domain (obtained by LsaLookupNames)
//         infotype  - type of information to retrieve
//				 info			 - infomation to get
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaQueryTrustedDomainInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);
	
	HV *info = NULL;

	// check argument type
	if(items == 4 && CHK_ASSIGN_HREF(info, ST(3)))
	{
		PWSTR server = NULL;
		PVOID infoBuffer = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSID sid = SvPV(ST(1), PL_na);
			TRUSTED_INFORMATION_CLASS infoType = (TRUSTED_INFORMATION_CLASS)SvIV(ST(2));
			DWORD access = 0;

			switch(infoType)
			{
				case TrustedDomainNameInformation:
				case TrustedPosixOffsetInformation:
					access = POLICY_VIEW_LOCAL_INFORMATION;
					break;

				case TrustedPasswordInformation:
					access = POLICY_GET_PRIVATE_INFORMATION;
					break;

				/*
				// this call is not supported by nt 4; you'll get always an error 1
				case TrustedControllersInformation:
					access = POLICY_VIEW_LOCAL_INFORMATION;
					break;
				*/		
			
				/*
				// this call is not supported by nt 4; you'll get always an error 87
				case TrustedDomainInformationBasic:
					access = POLICY_VIEW_LOCAL_INFORMATION;
					break;
				*/
					
				/*
				// this call is not supported by nt 4; you'll get always an error 5
				case TrustedDomainInformationEx:
					access = POLICY_ALL_ACCESS;
					break;
				*/

				/*
				// this call is not supported by nt 4; you'll get always an error 5
				case TrustedDomainAuthInformation:
					access = POLICY_VIEW_LOCAL_INFORMATION;
					access = POLICY_ALL_ACCESS;
					break;
				*/

				/*
				// this call is not supported by nt 4; you'll get always an error 87
				case TrustedDomainFullInformation:
					access = POLICY_VIEW_LOCAL_INFORMATION;
					break;
				*/
			}

			// first try open policy ...
			if(OpenPolicy(server, access, &hPolicy, &error))
			{
				// grant privileges
				error = LsaQueryTrustedDomainInfo(hPolicy, sid, infoType,	&infoBuffer);

				if(error = LsaNtStatusToWinError(error))
					LastError(error);
				else
					switch(infoType)
					{
						case TrustedDomainNameInformation:
						{
							PTRUSTED_DOMAIN_NAME_INFO inf = 
								(PTRUSTED_DOMAIN_NAME_INFO)infoBuffer;

							H_STORE_WSTR(info, "name", inf->Name.Buffer);
							break;
						}

						/*
						// this call is not supported by nt 4; you'll get always an error 1
						case TrustedControllersInformation:
						{
							PTRUSTED_CONTROLLERS_INFO inf = 
								(PTRUSTED_CONTROLLERS_INFO)infoBuffer;

							AV *names = NewAV;

							for(DWORD count = 0; count < inf->Entries; count++)
								A_STORE_WSTR(names, inf->Names[count].Buffer);

							H_STORE_REF(info, "names", names);

								// decrement reference count
							SvREFCNT_dec(names);

							break;
						}
						*/

						case TrustedPosixOffsetInformation:
						{
							PTRUSTED_POSIX_OFFSET_INFO inf = 
								(PTRUSTED_POSIX_OFFSET_INFO)infoBuffer;

							H_STORE_INT(info, "offset", inf->Offset);
							break;
						}

						case TrustedPasswordInformation:
						{
							PTRUSTED_PASSWORD_INFO inf = 
								(PTRUSTED_PASSWORD_INFO)infoBuffer;

							H_STORE_PTR(info, "password", inf->Password.Buffer, inf->Password.Length);
							H_STORE_PTR(info, "oldpassword", inf->OldPassword.Buffer, 
													inf->OldPassword.Length);
							break;
						}

						/*
						// this call is not supported by nt 4; you'll get always an error 5
						case TrustedDomainInformationEx:
						{
							PTRUSTED_DOMAIN_INFORMATION_EX inf =
								(PTRUSTED_DOMAIN_INFORMATION_EX)infoBuffer;

							H_STORE_WSTR(info, "name", inf->Name.Buffer);
							H_STORE_WSTR(info, "flatname", inf->FlatName.Buffer);
							H_STORE_PTR(info, "sid", inf->Sid, GetLengthSid(inf->Sid));
							H_STORE_INT(info, "trustdirection", inf->TrustDirection);
							H_STORE_INT(info, "trusttype", inf->TrustType);
							H_STORE_INT(info, "trustattributes", inf->TrustAttributes);
							break;
						}
						*/

						/*
						// this call is not supported by nt 4; you'll get always an error 87
						case TrustedDomainInformationBasic:
						{
							PTRUSTED_DOMAIN_INFORMATION_BASIC inf = 
								(PTRUSTED_DOMAIN_INFORMATION_BASIC)infoBuffer;

							H_STORE_WSTR(info, "name", inf->Name.Buffer);
							H_STORE_PTR(info, "sid", inf->Sid, GetLengthSid(inf->Sid));
							break;
						}
						*/

						/*
						// this call is not supported by nt 4; you'll get always an error 5
						case TrustedDomainAuthInformation:
						{
							PTRUSTED_DOMAIN_AUTH_INFORMATION inf = 
								(PTRUSTED_DOMAIN_AUTH_INFORMATION)infoBuffer;

							AV *incInfo = NewAV;

							for(DWORD count = 0; count < inf->IncomingAuthInfos; count++)
							{
								HV *autInfo = NewHV;
								char longBuffer[32];

								sprintf(longBuffer, "%I64u", 
												inf->IncomingAuthenticationInformation[count].LastUpdateTime);
								H_STORE_STR(autInfo, "lastupdatetime", longBuffer);
								H_STORE_INT(autInfo, "authtype", 
														inf->IncomingAuthenticationInformation[count].AuthType);
								H_STORE_PTR(autInfo, "authinfo", 
														inf->IncomingAuthenticationInformation[count].AuthInfo,
														inf->IncomingAuthenticationInformation[count].AuthInfoLength);

								A_STORE_REF(incInfo, autInfo);

								// decrement reference count
								SvREFCNT_dec(autInfo);
							}

							H_STORE_REF(info, "incomingauthenticationinformation", incInfo);

							// decrement reference count
							SvREFCNT_dec(incInfo);


							AV *incPrevInfo = NewAV;

							for(count = 0; count < inf->IncomingAuthInfos; count++)
							{
								HV *autInfo = NewHV;
								char longBuffer[32];

								sprintf(longBuffer, "%I64u", 
												inf->IncomingAuthenticationInformation[count].LastUpdateTime);
								H_STORE_STR(autInfo, "lastupdatetime", longBuffer);
								H_STORE_INT(autInfo, "authtype", 
														inf->IncomingAuthenticationInformation[count].AuthType);
								H_STORE_PTR(autInfo, "authinfo", 
														inf->IncomingAuthenticationInformation[count].AuthInfo,
														inf->IncomingAuthenticationInformation[count].AuthInfoLength);

								A_STORE_REF(incPrevInfo, autInfo);

								// decrement reference count
								SvREFCNT_dec(autInfo);
							}

							H_STORE_REF(info, "incomingpreviousauthenticationinformation", incPrevInfo);

							// decrement reference count
							SvREFCNT_dec(incPrevInfo);

							AV *outInfo = NewAV;

							for(count = 0; count < inf->OutgoingAuthInfos; count++)
							{
								HV *autInfo = NewHV;
								char longBuffer[32];

								sprintf(longBuffer, "%I64u", 
												inf->IncomingAuthenticationInformation[count].LastUpdateTime);
								H_STORE_STR(autInfo, "lastupdatetime", longBuffer);
								H_STORE_INT(autInfo, "authtype", 
														inf->IncomingAuthenticationInformation[count].AuthType);
								H_STORE_PTR(autInfo, "authinfo", 
														inf->IncomingAuthenticationInformation[count].AuthInfo,
														inf->IncomingAuthenticationInformation[count].AuthInfoLength);

								A_STORE_REF(outInfo, autInfo);

								// decrement reference count
								SvREFCNT_dec(autInfo);
							}

							H_STORE_REF(info, "outgoingauthenticationinformation", outInfo);

							// decrement reference count
							SvREFCNT_dec(outInfo);

							AV *outPrevInfo = NewAV;

							for(count = 0; count < inf->OutgoingAuthInfos; count++)
							{
								HV *autInfo = NewHV;
								char longBuffer[32];

								sprintf(longBuffer, "%I64u", 
												inf->IncomingAuthenticationInformation[count].LastUpdateTime);
								H_STORE_STR(autInfo, "lastupdatetime", longBuffer);
								H_STORE_INT(autInfo, "authtype", 
														inf->IncomingAuthenticationInformation[count].AuthType);
								H_STORE_PTR(autInfo, "authinfo", 
														inf->IncomingAuthenticationInformation[count].AuthInfo,
														inf->IncomingAuthenticationInformation[count].AuthInfoLength);

								A_STORE_REF(outPrevInfo, autInfo);

								// decrement reference count
								SvREFCNT_dec(autInfo);
							}

							H_STORE_REF(info, "outgoingpreviousauthenticationinformation", outPrevInfo);

							// decrement reference count
							SvREFCNT_dec(outPrevInfo);

							break;
						}
						*/

						/*
						// this call is not supported by nt 4; you'll get always an error 5
						case TrustedDomainFullInformation:
						{
							PTRUSTED_DOMAIN_FULL_INFORMATION inf = 
								(PTRUSTED_DOMAIN_FULL_INFORMATION)infoBuffer;

							break;
						}
						*/
					}
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanLsaPtr(infoBuffer);
	} // if(items == 4 && ...
	else
		croak("Usage: Win32::Lanman::LsaQueryTrustedDomainInfo($server, $domainsid, $infotype, "
					"\\%%info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// set domain settings
//
// param:  server			- computer to execute the command
//				 domainsid	- domain sid
//				 infotype		- information type to set
//				 info				- information to set
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaSetTrustedDomainInformation)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *info = NULL;

	// check argument type
	if(items == 4 && CHK_ASSIGN_HREF(info, ST(3)))
	{
		PWSTR server = NULL;
		PSID domainSid = 0;
		PVOID infoBuffer = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			domainSid = (PSID)SvPV(ST(1), PL_na);
			TRUSTED_INFORMATION_CLASS infoType = (TRUSTED_INFORMATION_CLASS)SvIV(ST(2));
			DWORD access = 0;

			// determine access needed
			switch(infoType)
			{
				case TrustedDomainNameInformation:
				{
					PSTR name = H_FETCH_STR(info, "name");
					DWORD nameSize = name ? strlen(name) + 1 : 0;

					// the working structure
					PTRUSTED_DOMAIN_NAME_INFO inf = (PTRUSTED_DOMAIN_NAME_INFO)
							NewMem(sizeof(TRUSTED_DOMAIN_NAME_INFO) + nameSize * sizeof(WCHAR));
					inf->Name.MaximumLength = (USHORT)nameSize * sizeof(WCHAR);
					inf->Name.Length = inf->Name.MaximumLength - sizeof(WCHAR);
					inf->Name.Buffer = (PWSTR)((PSTR)&inf->Name + sizeof(LSA_UNICODE_STRING));

					MBTWC(name, inf->Name.Buffer, nameSize * sizeof(WCHAR));

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_TRUST_ADMIN;
					break;
				}

				case TrustedPosixOffsetInformation:
				{
					// the working structure
					PTRUSTED_POSIX_OFFSET_INFO inf = 
						(PTRUSTED_POSIX_OFFSET_INFO)NewMem(sizeof(TRUSTED_POSIX_OFFSET_INFO));

					inf->Offset = H_FETCH_INT(info, "offset");

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = 0;
					break;
				}

				case TrustedPasswordInformation:
				{
					PSTR password = H_FETCH_STR(info, "password");
					DWORD passwordSize = password ? strlen(password) + 1 : 0;
					PSTR oldPassword = H_FETCH_STR(info, "oldpassword");
					DWORD oldPasswordSize = oldPassword ? strlen(oldPassword) + 1 : 0;

					// the working structure
					PTRUSTED_PASSWORD_INFO inf = (PTRUSTED_PASSWORD_INFO)
							NewMem(sizeof(TRUSTED_PASSWORD_INFO) + passwordSize * sizeof(WCHAR) +
										 oldPasswordSize * sizeof(WCHAR));
					inf->Password.MaximumLength = (USHORT)passwordSize * sizeof(WCHAR);
					inf->Password.Length = inf->Password.MaximumLength - sizeof(WCHAR);
					inf->Password.Buffer = (PWSTR)((PSTR)&inf->Password + sizeof(LSA_UNICODE_STRING));

					MBTWC(password, inf->Password.Buffer, passwordSize * sizeof(WCHAR));

					inf->OldPassword.MaximumLength = (USHORT)oldPasswordSize * sizeof(WCHAR);
					inf->OldPassword.Length = 
						__max(inf->OldPassword.MaximumLength, sizeof(WCHAR)) - sizeof(WCHAR);
					if(oldPassword)
					{
						inf->OldPassword.Buffer = 
							(PWSTR)((PSTR)inf->Password.Buffer + inf->Password.MaximumLength);
						MBTWC(oldPassword, inf->OldPassword.Buffer, oldPasswordSize * sizeof(WCHAR));
					}

					// set working structure pointer to common pointer
					infoBuffer = (PVOID)inf;

					// set access needed
					access = POLICY_CREATE_SECRET;
					break;
				}

			} // switch(infoType)

			// first try open policy
			if(OpenPolicy(server, access, &hPolicy, &error))
			{
				error = LsaSetTrustedDomainInformation(hPolicy, domainSid, infoType, infoBuffer);

				if(error = LsaNtStatusToWinError(error))
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(infoBuffer);
	} // if(items == 4 && ...
	else
		croak("Usage: Win32::Lanman::LsaSetTrustedDomainInformation($server, $domainsid, "
																																"$infotype, \\%%info)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves lsa data strings
//
// param:  server	- computer to execute the command
//				 key		- key name
//				 data		- retrieves the data string
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaRetrievePrivateData)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *data = NULL;

	// check argument type
	if(items == 3 && CHK_ASSIGN_SREF(data, ST(2)))
	{
		PWSTR server = NULL;
		PLSA_UNICODE_STRING lsaKey = NULL;
		PLSA_UNICODE_STRING lsaData = NULL;
		PWSTR dataPtr = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// clear hash
			SV_CLEAR(data);

			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSTR key = SvPV(ST(1), PL_na);

			NEW_LSA_STR(lsaKey, key);

			// first try open policy
			if(OpenPolicy(server, POLICY_GET_PRIVATE_INFORMATION, &hPolicy, &error))
			{
				error = LsaRetrievePrivateData(hPolicy, lsaKey, &lsaData);

				if(error = LsaNtStatusToWinError(error))
					LastError(error);
				else
				{
					dataPtr = (PWSTR)NewMem(lsaData->Length + sizeof(WCHAR));
					wcsncpy(dataPtr, lsaData->Buffer, lsaData->Length >> 1);
					S_STORE_WSTR(data, dataPtr);
				}
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}
		
		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(lsaKey);
		CleanLsaPtr(lsaData);
		CleanPtr(dataPtr);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaRetrievePrivateData($server, $key, \\$data)\n");

	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets lsa data strings
//
// param:  server	- computer to execute the command
//				 key		- key name
//				 data		- data string to set
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LsaStorePrivateData)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	// check argument type
	if(items == 3)
	{
		PWSTR server = NULL;
		PLSA_UNICODE_STRING lsaKey = NULL;
		PLSA_UNICODE_STRING lsaData = NULL;
		LSA_HANDLE hPolicy = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			PSTR key = SvPV(ST(1), PL_na), data = SvPV(ST(2), PL_na);
			DWORD keySize = strlen(key) + 1, dataSize = strlen(data) + 1;

			lsaKey = (PLSA_UNICODE_STRING)NewMem(sizeof(LSA_UNICODE_STRING) + keySize * sizeof(WCHAR));
			lsaKey->MaximumLength = (USHORT)keySize * sizeof(WCHAR);
			lsaKey->Length = lsaKey->MaximumLength - sizeof(WCHAR);
			lsaKey->Buffer = (PWSTR)((PSTR)lsaKey + sizeof(LSA_UNICODE_STRING));

			MBTWC(key, lsaKey->Buffer, keySize * sizeof(WCHAR));

			lsaData = (PLSA_UNICODE_STRING)NewMem(sizeof(LSA_UNICODE_STRING) + dataSize * sizeof(WCHAR));
			lsaData->MaximumLength = (USHORT)dataSize * sizeof(WCHAR);
			lsaData->Length = lsaData->MaximumLength - sizeof(WCHAR);
			lsaData->Buffer = (PWSTR)((PSTR)lsaData + sizeof(LSA_UNICODE_STRING));

			MBTWC(data, lsaData->Buffer, dataSize * sizeof(WCHAR));

			// first try open policy
			if(OpenPolicy(server, POLICY_CREATE_SECRET, &hPolicy, &error))
			{
				error = LsaStorePrivateData(hPolicy, lsaKey, lsaData);

				if(error = LsaNtStatusToWinError(error))
					LastError(error);
			}
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanLsaHandle(hPolicy);
		CleanPtr(lsaData);
		CleanPtr(lsaKey);
	} // if(items == 3 && ...
	else
		croak("Usage: Win32::Lanman::LsaStorePrivateData($server, $key, $data)\n");

	RETURNRESULT(LastError() == 0);
}


