#ifndef __DS_H
#define __DS_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

#ifndef NetSetupDnsMachine
#define NetSetupDnsMachine	(NetSetupNonExistentDomain + 1)
#endif


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
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

XS(XS_NT__Lanman_NetGetJoinableOUs);

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

XS(XS_NT__Lanman_NetGetJoinInformation);

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

XS(XS_NT__Lanman_NetJoinDomain);

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

XS(XS_NT__Lanman_NetRenameMachineInDomain);

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

XS(XS_NT__Lanman_NetUnjoinDomain);

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

XS(XS_NT__Lanman_NetValidateName);

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

XS(XS_NT__Lanman_NetRegisterDomainNameChangeNotification);

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

XS(XS_NT__Lanman_NetUnregisterDomainNameChangeNotification);


#endif //#ifndef __DS_H

