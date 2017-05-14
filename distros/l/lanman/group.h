#ifndef __GROUP_H
#define __GROUP_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// creates a new local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//				 comment - optional group comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAdd);


///////////////////////////////////////////////////////////////////////////////
//
// adds users or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAddMembersBySid);


///////////////////////////////////////////////////////////////////////////////
//
// adds users sid to a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAddMember);


///////////////////////////////////////////////////////////////////////////////
//
// adds users or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupAddMembers);


///////////////////////////////////////////////////////////////////////////////
//
// deletes a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDel);


///////////////////////////////////////////////////////////////////////////////
//
// removes users sid from a local group
//
// param:  server - computer to execute the command
//         group  - local group name
//         sid		- user or global groups to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDelMember);


///////////////////////////////////////////////////////////////////////////////
//
// removes users or global groups from a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDelMembers);


///////////////////////////////////////////////////////////////////////////////
//
// removes users or global groups from a local group
//
// param:  server  - computer to execute the command
//         group   - local group name
//         members - user or global groups to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupDelMembersBySid);


///////////////////////////////////////////////////////////////////////////////
//
// enums all local groups
//
// param:  server - computer to execute the command
//         groups - gets all local groups
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupEnum);


///////////////////////////////////////////////////////////////////////////////
//
// gets the name and comment of a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - gets the group name and comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// gets all user and global groups from a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//         members - gets all local group members
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupGetMembers);


///////////////////////////////////////////////////////////////////////////////
//
// sets user or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//         members - members to set to the local group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupSetMembersBySid);


///////////////////////////////////////////////////////////////////////////////
//
// sets the name and/or comment of a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - group properties to set (if you specify a name in info,
//									 the group will be renamed)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// sets user or global groups to a local group
//
// param:  server  - computer to execute the command
//         group   - group name
//         members - members to set to the local group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetLocalGroupSetMembers);


///////////////////////////////////////////////////////////////////////////////
//
// creates a new global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//				 comment - optional group comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupAdd);


///////////////////////////////////////////////////////////////////////////////
//
// adds a user to a global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//         user		 - user to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupAddUser);


///////////////////////////////////////////////////////////////////////////////
//
// deletes a global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupDel);


///////////////////////////////////////////////////////////////////////////////
//
// removes a user from a global group
//
// param:  server  - computer to execute the command
//         group   - global group name
//         user		 - user to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupDelUser);


///////////////////////////////////////////////////////////////////////////////
//
// enums all global groups
//
// param:  server - computer to execute the command
//         groups - gets all global groups
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupEnum);


///////////////////////////////////////////////////////////////////////////////
//
// gets the name and comment of a global group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - gets the group name and comment
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// gets all users of a global group
//
// param:  server - computer to execute the command
//         group  - global group name
//         users  - gets all local group members
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupGetUsers);


///////////////////////////////////////////////////////////////////////////////
//
// sets the name and/or comment of a global group
//
// param:  server  - computer to execute the command
//         group   - group name
//				 info		 - group properties to set (if you specify a name in info,
//									 the group will be renamed)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// sets users to a global group
//
// param:  server  - computer to execute the command
//         group   - group name
//         users	 - users to set to the global group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetGroupSetUsers);



#endif //#ifndef __GROUP_H

