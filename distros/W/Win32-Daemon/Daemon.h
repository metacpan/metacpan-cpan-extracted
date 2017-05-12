//////////////////////////////////////////////////////////////////////////////
//
//  Daemon.h
//  Win32::Daemon Perl extension main header file
//
//  Copyright (c) 1998-2008 Dave Roth
//  Courtesy of Roth Consulting
//  http://www.roth.net/
//
//  This file may be copied or modified only under the terms of either 
//  the Artistic License or the GNU General Public License, which may 
//  be found in the Perl 5.0 source kit.
//
//  2008.03.24  :Date
//  20080324    :Version
//////////////////////////////////////////////////////////////////////////////

//	#include "Win32Perl.h"
 
#ifndef _DAEMON_H
#   define _DAEMON_H 

#   ifndef WIN32
#       ifdef _WIN32
#           define WIN32   
#       endif // _WIN32  
#   endif // WIN32  
  
///////////////////////////////////////////////////////////////////////////////////////////
//  Begin resource compiler macro block

    //  Include the version information...
    #include "version.h"

    #define EXTENSION_NAME          "Daemon"

    #define EXTENSION_PARENT_NAMESPACE      "Win32"
    #define EXTENSION               EXTENSION_PARENT_NAMESPACE "::" EXTENSION_NAME
    
    #define EXTENSION_FILE_NAME     EXTENSION_NAME

    #define EXTENSION_VERSION       VERSION
    #define EXTENSION_AUTHOR        "Dave Roth <rothd@roth.net>"

    #define COPYRIGHT_YEAR          "2000-2008"
    #define COPYRIGHT_NOTICE        "Copyright (c) " COPYRIGHT_YEAR

    #define COMPANY_NAME            "Roth Consulting\r\nhttp://www.roth.net/consult"

    #define VERSION_TYPE            "Beta"
//  End resource compiler macro block
///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//  These are members that will be defined in the blessed Perl Object.
//  These are only intended to be used by this extension (and maybe it's
//  brethern). I would not suggest other applications rely on this since it
//  may change.
#define KEYWORD_SERVICE_NAME            TEXT( "name" )
#define KEYWORD_SERVICE_DISPLAY_NAME    TEXT( "display" )
#define KEYWORD_SERVICE_BINARY_PATH     TEXT( "path" )
#define KEYWORD_SERVICE_ACCOUNT_UID     TEXT( "user" )
#define KEYWORD_SERVICE_ACCOUNT_PWD     TEXT( "password" )
#define KEYWORD_SERVICE_PARAMETERS      TEXT( "parameters" )
#define KEYWORD_SERVICE_MACHINE         TEXT( "machine" )
#define KEYWORD_SERVICE_TYPE            TEXT( "service_type" )
#define KEYWORD_SERVICE_START_TYPE      TEXT( "start_type" )
#define KEYWORD_SERVICE_ERROR_CONTROL   TEXT( "error_control" )
#define KEYWORD_SERVICE_LOAD_ORDER      TEXT( "load_order" )
#define KEYWORD_SERVICE_TAG_ID          TEXT( "tag_id" )
#define KEYWORD_SERVICE_DEPENDENCIES    TEXT( "dependencies" )
#define KEYWORD_SERVICE_DESCRIPTION     TEXT( "description" )

#define KEYWORD_CALLBACK_COMMAND_NAME	TEXT( "command" )


///////////////////////////////////////////////////////////////////////////////
//  Keywords used in anonymous hash for State()
#define KEYWORD_STATE_STATE             TEXT( "state" )
#define KEYWORD_STATE_WAIT_HINT         TEXT( "wait_hint" )
#define KEYWORD_STATE_ERROR             TEXT( "error" )


///////////////////////////////////////////////////////////////////////////////
// Registry based keywords
#define REGISTRY_SERVICE_PATH                   TEXT( "System\\CurrentControlSet\\Services" )
#define REGISTRY_SERVICE_KEYWORD_DESCRIPTION    TEXT( "Description" )

///////////////////////////////////////////////////////////////////////////////
// Location of where to find local user's profiles
#define REG_KEY_USER_LOCAL_PROFILE          TEXT( "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\" )
#define REG_VALUE_USER_CENTRAL_PROFILE_PATH TEXT( "CentralProfile" )
#define REG_VALUE_USER_LOCAL_PROFILE_PATH   TEXT( "ProfileImagePath" )

///////////////////////////////////////////////////////////////////////////////
// File name of user's profile and delta in hive form
#define USER_PROFILE_HIVE_NAME              TEXT( "NTUser.dat" )
#define USER_PROFILE_HIVE_LOG_NAME          TEXT( "NTUser.log" )

///////////////////////////////////////////////////////////////////////////////
// If DEBUG is defined where does debug information get dumped to?
#define DEBUG_OUTPUT_FILE		TEXT( "\\\\.\\pipe\\syslog" )
#define DEBUG_OUTPUT_FILE_ALT	TEXT( "c:\\temp\\Win32-Daemon-debug.log" )


///////////////////////////////////////////////////////////////////////////////
// What is the largest possible size that the process's sid can
// be?
#define MAX_SID_SIZE                    128

///////////////////////////////////////////////////////////////////////////////
// Misc values
#define	MAX_SERVICE_DEPENDENCY_BUFFER_SIZE	2048
#define	DEFAULT_CALLBACK_TIMER				5000


///////////////////////////////////////////////////////////////////////////////
// Security support values
#define PERL_WIN32_PERMS_EXTENSION      "Win32::Perms"


///////////////////////////////////////////////////////////////////////////////
//  Tools to simplfy common tasks:

#define OPEN_SERVICE_CONTROL_MANAGER( pszMachine )    SC_HANDLE hSc = OpenSCManager( pszMachine, SERVICES_ACTIVE_DATABASE, SC_MANAGER_ALL_ACCESS ); \
                                        if( NULL != hSc )                                                   \
                                        {                                                                   \
                                            SC_LOCK sclLock = LockServiceDatabase( hSc );                   \
                                            if( NULL != sclLock )                                           \
                                            {

#define OPEN_SERVICE_CONTROL_MANAGER_READ( pszMachine )    SC_HANDLE hSc = OpenSCManager( pszMachine, SERVICES_ACTIVE_DATABASE, GENERIC_READ ); \
                                        if( NULL != hSc )                                                   \
                                        {                                                                   \
                                            SC_LOCK sclLock = LockServiceDatabase( hSc );                   \
                                            if( NULL != sclLock )                                           \
                                            {


#define CLOSE_SERVICE_CONTROL_MANAGER           UnlockServiceDatabase( sclLock );                           \
                                            }                                                               \
                                            else                                                            \
                                            {                                                               \
                                                gdwLastError = GetLastError();                              \
                                            }                                                               \
                                            CloseServiceHandle( hSc );                                      \
                                        }


///////////////////////////////////////////////////////////////////////////////
//  Define a method to report exceptions
#ifdef DEBUG
    #define REPORT_EXCEPTION    _tprintf( TEXT( "Error! An Exception has been caught.\n" ) )
#else   //  DEBUG
    #define REPORT_EXCEPTION    
#endif  //  DEBUG


///////////////////////////////////////////////////////////////////////////////
//  
#define SET_CALLBACK(x,y)		        {   \
                                          SV* pSvTEMP = (SV*) (y);                  \
                                          if( NULL != pSvTEMP && SvROK( pSvTEMP ) )                    \
                                          {                                         \
                                                pSvTEMP = SvRV( pSvTEMP );              \
                                          }                                          \
                                          if( NULL == pSvTEMP || SVt_PVCV == SvTYPE( pSvTEMP ) ) gCallback.Set( x, (PVOID) pSvTEMP );   \
                                        }

#if _DEBUG
    TCHAR   gszDebugOutputPath[ MAX_PATH ];
    CRITICAL_SECTION gcsDebugOutput;
#endif // _DEBUG

HINSTANCE   ghDLL = 0;
int     giThread = 0;
int     iTheList = 0;
TCHAR   gszModulePath[ MAX_PATH ];
SERVICE_STATUS_HANDLE ghService = 0;
SERVICE_STATUS gServiceStatus;
SID    *gpSid;
HANDLE  ghServiceThread;
BOOL    gfCallbackMode;
DWORD	gMainThreadId;
DWORD   gServiceThreadId;
DWORD	gServiceMainThreadID;
DWORD   gdwServiceBits;
DWORD   gdwLastError;
DWORD   gdwServiceErrorState = NO_ERROR;
DWORD   gdwState = 0;
DWORD   gdwTimeoutState = SERVICE_START_PENDING;
DWORD	gdwControlsAccepted = SERVICE_ACCEPT_STOP 
                              | SERVICE_ACCEPT_PAUSE_CONTINUE
                              | SERVICE_ACCEPT_SHUTDOWN
                              | SERVICE_ACCEPT_PARAMCHANGE  
                              | SERVICE_ACCEPT_NETBINDCHANGE;

DWORD	gdwServiceType = SERVICE_WIN32_OWN_PROCESS 
                         | SERVICE_INTERACTIVE_PROCESS;
UINT_PTR ghTimer = 0;
DWORD   gdwHandlerTimeout = DEFAULT_HANDLER_TIMEOUT_VALUE;
DWORD   gdwLastControlMessage = SERVICE_START_PENDING;
OSVERSIONINFO gsOSVerInfo;

static  CWinStation gWindowStation;
#ifdef ENABLE_CALLBACKS
	CCallbackList gCallback;
//    pTHX gpPerlObject; 
    HV *gpHvContext;
	CCallbackTimer gCallbackTimer;
#endif // ENABLE_CALLBACKS

HANDLE  ghLogFile = NULL;


#endif // _DAEMON_H

