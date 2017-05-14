#ifndef __USER_H
#define __USER_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
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

XS(XS_NT__Lanman_NetUserAdd);


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

XS(XS_NT__Lanman_NetUserChangePassword);


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

XS(XS_NT__Lanman_NetUserDel);


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

XS(XS_NT__Lanman_NetUserEnum);


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

XS(XS_NT__Lanman_NetUserGetGroups);


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

XS(XS_NT__Lanman_NetUserGetInfo);


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

XS(XS_NT__Lanman_NetUserGetLocalGroups);


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

XS(XS_NT__Lanman_NetUserSetGroups);


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

XS(XS_NT__Lanman_NetUserSetInfo);


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

XS(XS_NT__Lanman_NetUserSetProp);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves global information for all users and global groups in the security 
// database.
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

XS(XS_NT__Lanman_NetUserModalsGet);


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

XS(XS_NT__Lanman_NetUserModalsSet);

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

XS(XS_NT__Lanman_NetUserCheckPassword);

#endif //#ifndef __USER_H


