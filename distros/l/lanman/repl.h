#ifndef __REPL_H
#define __REPL_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// registers an existing directory in the export path to be replicated
//
// param:  server - computer to export the directory
//         info   - replication directory info to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirAdd);


///////////////////////////////////////////////////////////////////////////////
//
// removes registration of a replicated directory
//
// param:  server		 - computer which exports the directory
//         directory - replication directory to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirDel);


///////////////////////////////////////////////////////////////////////////////
//
// lists the replicated directories in the export path
//
// param:  server			 - export computer
//         directories - directory array to enum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves the control information of a replicated directory
//
// param:  server		 - export computer
//         directory - directory name
//				 info			 - hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// locks a replicated directory 
//
// param:  server		 - export computer
//         directory - directory to add a lock
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirLock);


///////////////////////////////////////////////////////////////////////////////
//
// modifies the control information of a replicated directory
//
// param:  server		 - export computer
//         directory - directory to add a lock
//				 info			 - info to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirSetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// unlocks a replicated directory 
//
// param:  server			 - export computer
//         directory	 - directory to remove a lock
//				 forceUnlock - forces to set the lock counter to zero
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplExportDirUnlock);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves configuration information for the Replicator service
//
// param:  server - computer to execute the command
//         info	  - hash to get information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// registers an existing directory in the import path to be replicated
//
// param:  server		 - computer to import the directory
//         directory - replication directory to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirAdd);


///////////////////////////////////////////////////////////////////////////////
//
// removes registration of a replicated directory
//
// param:  server		 - computer which imports the directory
//         directory - replication directory to remove
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirDel);


///////////////////////////////////////////////////////////////////////////////
//
// lists the replicated directories in the import path
//
// param:  server			 - import computer
//         directories - directory array to enum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves the control information of a replicated directory
//
// param:  server		 - import computer
//         directory - directory name
//				 info			 - hash to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirGetInfo);


///////////////////////////////////////////////////////////////////////////////
//
// locks a replicated directory 
//
// param:  server		 - import computer
//         directory - directory to add a lock
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirLock);


///////////////////////////////////////////////////////////////////////////////
//
// unlocks a replicated directory 
//
// param:  server			 - import computer
//         directory	 - directory to remove a lock
//				 forceUnlock - forces to set the lock counter to zero
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplImportDirUnlock);


///////////////////////////////////////////////////////////////////////////////
//
// modifies the Replicator service configuration information
//
// param:  server - computer to execute the command
//         info	  - hash to get information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetReplSetInfo);
 

#endif //#ifndef __REPL_H
