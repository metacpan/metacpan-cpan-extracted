//////////////////////////////////////////////////////////////////////////////
//
//  ServiceThread.hpp
//  Win32::Daemon Perl extension service manager thread header file
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

#ifndef _SERVICETHREAD_H_
#define _SERVICETHREAD_H_

#define SERVICE_THREAD_TIMER_ID     0x6502

#define WM_USER_SET_TIMER           WM_USER + 0

///////////////////////////////////////////////////////////////////////////////
// SCM control event and command strings
#define SERVICE_CONTROL_STRING_EMPTY			TEXT( "" )
#define SERVICE_CONTROL_STRING_DEFAULT			TEXT( "DEFAULT" )
#define SERVICE_CONTROL_STRING_START            TEXT( "START" )
#define SERVICE_CONTROL_STRING_STOP				TEXT( "STOP" )
#define SERVICE_CONTROL_STRING_PAUSE			TEXT( "PAUSE" )
#define SERVICE_CONTROL_STRING_CONTINUE			TEXT( "CONTINUE" )
#define SERVICE_CONTROL_STRING_SHUTDOWN			TEXT( "SHUTDOWN" )
#define SERVICE_CONTROL_STRING_INTERROGATE		TEXT( "INTERROGATE" )
#define SERVICE_CONTROL_STRING_PARAMCHANGE		TEXT( "PARAMCHANGE" )
#define	SERVICE_CONTROL_STRING_NETBINDADD		TEXT( "NETBINDADD" )
#define SERVICE_CONTROL_STRING_NETBINDREMOVE	TEXT( "NETBINDREMOVE" )
#define SERVICE_CONTROL_STRING_NETBINDENABLE	TEXT( "NETBINDENABLE" )
#define SERVICE_CONTROL_STRING_NETBINDDISABLE	TEXT( "NETBINDDISABLE" )
#define SERVICE_CONTROL_STRING_DEVICEEVENT      TEXT( "DEVICEEVENT" )
#define SERVICE_CONTROL_STRING_HARDWAREPROFILECHANGE    TEXT( "HARDWAREPROFILECHANGE" )
#define SERVICE_CONTROL_STRING_POWEREVENT       TEXT( "POWEREVENT" )
#define SERVICE_CONTROL_STRING_SESSIONCHANGE    TEXT( "SESSIONCHANGE" )
#define SERVICE_CONTROL_STRING_USER_DEFINED     TEXT( "USER_DEFINED" )
#define SERVICE_CONTROL_STRING_RUNNING          TEXT( "RUNNING" )

#ifdef SERVICE_CONTROL_PRESHUTDOWN
	#define SERVICE_CONTROL_STRING_PRESHUTDOWN		TEXT( "PRESHUTDOWN" )
#endif 



VOID WINAPI ServiceMain( DWORD dwArgs, LPTSTR *ppszArgs);
VOID WINAPI ServiceHandler( DWORD dwControl );
DWORD WINAPI ServiceThread( LPVOID pVoid );
BOOL UpdateServiceStatus( DWORD dwState, DWORD dwWaitHint = DEFAULT_WAIT_HINT, DWORD dwError = 0xFFFFFFFF );
VOID CALLBACK TimerHandler( HWND hWnd, UINT uMsg, UINT uEventId, DWORD dwSystemTime );
void SetTimeoutTimer( DWORD dwTimeout );
void CleanStatusStruct( SERVICE_STATUS *pServiceStatus );

#endif // _SERVICETHREAD_H_
