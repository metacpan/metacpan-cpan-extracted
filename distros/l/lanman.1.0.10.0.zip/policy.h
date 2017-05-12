#ifndef __POLICY_H
#define __POLICY_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

#ifndef PolicyMachinePasswordInformation
#define PolicyMachinePasswordInformation (PolicyDnsDomainInformation + 1)
#endif


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////

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

XS(XS_NT__Lanman_GrantPrivilegeToAccount);

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

XS(XS_NT__Lanman_RevokePrivilegeFromAccount);

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

XS(XS_NT__Lanman_EnumAccountPrivileges);

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

XS(XS_NT__Lanman_EnumPrivilegeAccounts);

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

XS(XS_NT__Lanman_LsaQueryInformationPolicy);

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

XS(XS_NT__Lanman_LsaSetInformationPolicy);

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

XS(XS_NT__Lanman_LsaEnumerateTrustedDomains);

///////////////////////////////////////////////////////////////////////////////
//
// looks up for account sids
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

XS(XS_NT__Lanman_LsaLookupNames);

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

XS(XS_NT__Lanman_LsaLookupNamesEx);

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

XS(XS_NT__Lanman_LsaLookupSids);

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

XS(XS_NT__Lanman_LsaEnumerateAccountsWithUserRight);

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

XS(XS_NT__Lanman_LsaEnumerateAccountRights);

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

XS(XS_NT__Lanman_LsaAddAccountRights);

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

XS(XS_NT__Lanman_LsaRemoveAccountRights);

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

XS(XS_NT__Lanman_LsaQueryTrustedDomainInfo);

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

XS(XS_NT__Lanman_LsaSetTrustedDomainInformation);

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

XS(XS_NT__Lanman_LsaRetrievePrivateData);

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

XS(XS_NT__Lanman_LsaStorePrivateData);

#endif //#ifndef __POLICY_H
