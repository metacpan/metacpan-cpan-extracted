#ifndef __GET_H
#define __GET_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// returns information about the expected performance of a connection used to 
// access a network resource
//
// param:  netresource - netresource struct
//         info				 - info to return
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_MultinetGetConnectionPerformance);


///////////////////////////////////////////////////////////////////////////////
//
// returns the name of a domain controller in a specified domain
//
// param:  server - computer to execute the command
//         domain	-	domain name to get a domain controller for
//				 dcname	- string to store domain controller name 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetAnyDCName);


///////////////////////////////////////////////////////////////////////////////
//
// returns the name of the primary domain controller 
//
// param:  server  - computer to execute the command
//         domain	 - domain name to get a domain controller for
//				 pdcname - string to store domain controller name 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetDCName);


///////////////////////////////////////////////////////////////////////////////
//
// gets the index of the first display information entry whose name begins with 
// a specified string or alphabetically follows the string
//
// param:  server - computer to execute the command
//				 level  - requested information type 
//								  (1 - user, 2 - computer accounts, 3 - groups)
//				 prefix	- contains the prefix for which to search
//         domain	-	domain name to get a domain controller for
//				 index  - receives the index of the entry
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGetDisplayInformationIndex);


///////////////////////////////////////////////////////////////////////////////
//
// returns user, computer, or global group account information
//
// param:  server  - computer to execute the command
//				 level   - requested information type 
//									 (1 - user, 2 - computer accounts, 3 - groups)
//         index	 - index of the first entry for which to retrieve information
//				 entries - maximum number of entries for which to get information
//				 info		 - hash to store information 
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetQueryDisplayInformation);



#endif //#ifndef __GET_H
