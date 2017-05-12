#ifndef __DOMAIN_H
#define __DOMAIN_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////

// used to get domain controller names from a domain
typedef struct
{
	DWORD flag;
	PWSTR name;
} NETGETDC_INFO, *PNETGETDC_INFO;


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////

extern "C" DWORD FAR WINAPI I_NetGetDCList(PWCHAR server, PWCHAR domain, PDWORD count, 
																					 PNETGETDC_INFO *controllers);


///////////////////////////////////////////////////////////////////////////////
//
// queries, synchonizes or replicates the sam database between PDC and BDC's
//
// param:  server		- computer to execute the command
//         function - function code to execute
//				 info			- gets the result
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_NetLogonControl);


///////////////////////////////////////////////////////////////////////////////
//
// queries, synchonizes, replicates the sam database between PDC and BDC's; can
// get the logon count, query and rediscover secure channels, notify of new
// transports and finds user in a trusted domain
//
// param:  server		- computer to execute the command
//         function - function code to execute
//				 data			- data needed as input (domain or user name)
//				 info			- gets the result
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_NetLogonControl2);


///////////////////////////////////////////////////////////////////////////////
//
// enumerates all trusted domains
//
// param:  server	 - computer to execute the command
//         domains - gets the domain names
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
// important: if you need to compile this module, please change the function 
//						prototype in lmaccess.h to the following:
//
//						NTSTATUS NET_API_FUNCTION NetEnumerateTrustedDomains(
//					    IN LPWSTR ServerName OPTIONAL, OUT LPWSTR *DomainNames);
//
//						otherwise, the linker would claim an unresolved external symbol
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetEnumerateTrustedDomains);


///////////////////////////////////////////////////////////////////////////////
//
// gets a list of domain controllers in a domain
//
// param:  server		- computer to execute the command
//         function - function code to execute
//				 info			- gets the result
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_I_NetGetDCList);


#endif //#ifndef __DOMAIN_H

