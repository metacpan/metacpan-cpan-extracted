//////////////////////////////////////////////////////////////////////////////
//
//  Constant.h
//  Win32::Daemon Perl extension constants header file
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

#ifndef _CONSTANT_H_
#define _CONSTANT_H_

#include <winSvc.h>

// #include <crtdbg.h>

enum eConstantType { NotDefined = 0, NotPresent, String, Numeric };

#ifdef _DEBUG
    #define ALERT(x)            {                           \
                                    EnterCriticalSection( &gcsDebugOutput );        \
                                    TCHAR _TEMP_szBuffer[ 256 ];  \
                                    wsprintf( _TEMP_szBuffer, TEXT( "(%04d) %s" ), GetCurrentThreadId(), (x) ); \
                                    LogToFile( _TEMP_szBuffer );      \
                                    LeaveCriticalSection( &gcsDebugOutput );        \
                                }
#else
    #define ALERT(x)
#endif // _DEBUG


#ifndef SERVICE_CONTROL_DEVICEEVENT
#   define SERVICE_CONTROL_DEVICEEVENT            0x0b
#endif
#ifndef SERVICE_CONTROL_HARDWAREPROFILECHANGE
#   define SERVICE_CONTROL_HARDWAREPROFILECHANGE  0x0c
#endif
#ifndef SERVICE_CONTROL_POWEREVENT
#   define SERVICE_CONTROL_POWEREVENT             0x0d
#endif
#ifndef SERVICE_CONTROL_SESSIONCHANGE
#   define SERVICE_CONTROL_SESSIONCHANGE          0x0e
#endif

//	If the SCM has not yet been initialized with the service then the state is SERVICE_NOT_READY
//	Most scripts will never see this.
#define SERVICE_NOT_READY				0x0

//	If there is no control command then this is the used
#define SERVICE_CONTROL_NONE			0xFFFFFFFF

// Define a non-existing control to represent when a service is starting.
#define SERVICE_CONTROL_START			0x1010								//  Our own definition
#define SERVICE_CONTROL_TIMER			0x1020								//	Our own definition
#define SERVICE_CONTROL_USER_DEFINED	0x1030							    //  Our own definition
#define SERVICE_CONTROL_RUNNING			0x1040								//	Use the same value as SERVICE_RUNNING so that callbacks map to the same SERVICE_RUNNING value

//  Default handler timeout before we auto-set the service state (in seconds)
//	This value is for handling event such as pausing.
#define DEFAULT_HANDLER_TIMEOUT_VALUE   5

//  The handler timeout value scale. This is the multiplier for the timeout value.
#define DEFAULT_HANDLER_TIMEOUT_SCALE   1000

//  The default wait hint. When a control state is updated this is the
//  wait hint unless a wait hint value is specified by the script.
#define DEFAULT_WAIT_HINT               0x00

//  The default callback timer value. When in callback mode this is
//  the default value indicating how often to call back into the callback
//  routine.
//  This value is in miliseconds.
#define DEFAULT_CALLBACK_TIMER          5000

eConstantType Constant( LPTSTR pszConstant, LPVOID *ppBuffer );
const char *GetConstantName( DWORD dwIndex );
DWORD GetTotalConstants();
void CountConstants();

typedef struct tagConstStruct
{
    const char *m_Name;
    LPVOID m_pBuffer;
    eConstantType m_eType;
} ConstantStruct;

// What user bits can we use for SetServiceBits?
#define USER_SERVICE_BITS_1     0x00004000 
#define USER_SERVICE_BITS_2     0x00008000 
#define USER_SERVICE_BITS_3     0x00400000 
#define USER_SERVICE_BITS_4     0x00800000 
#define USER_SERVICE_BITS_5     0x01000000 
#define USER_SERVICE_BITS_6     0x02000000 
#define USER_SERVICE_BITS_7     0x04000000 
#define USER_SERVICE_BITS_8     0x08000000 
#define USER_SERVICE_BITS_9     0x10000000 
#define USER_SERVICE_BITS_10    0x20000000
 
#define USER_SERVICE_BITS_MASK  0x3FC0C000

/*

// Control callback functions
#define CALLBACK_STOP						SERVICE_CONTROL_STOP
#define CALLBACK_PAUSE						SERVICE_CONTROL_PAUSE
#define CALLBACK_CONTINUE					SERVICE_CONTROL_CONTINUE
#define CALLBACK_INTERROGATE				SERVICE_CONTROL_INTERROGATE
#define CALLBACK_SHUTDOWN					SERVICE_CONTROL_SHUTDOWN
#define CALLBACK_PARAMCHANGE				SERVICE_CONTROL_PARAMCHANGE
#define CALLBACK_NETBINDADD					SERVICE_CONTROL_NETBINDADD
#define CALLBACK_NETBINDREMOVE				SERVICE_CONTROL_NETBINDREMOVE
#define CALLBACK_NETBINDENABLE				SERVICE_CONTROL_NETBINDENABLE
#define CALLBACK_NETBINDDISABLE				SERVICE_CONTROL_NETBINDDISABLE
// Control callback functions for misc stuff...
#define CALLBACK_USER_DEFINED				SERVICE_CONTROL_USER_DEFINED


// Control callback function names
#define CALLBACK_NAME_STOP					TEXT( "stop" )
#define CALLBACK_NAME_PAUSE					TEXT( "pause" )
#define CALLBACK_NAME_CONTINUE				TEXT( "continue" )
#define CALLBACK_NAME_INTERROGATE			TEXT( "interrogate" )
#define CALLBACK_NAME_SHUTDOWN				TEXT( "shutdown" )
#define CALLBACK_NAME_PARAMCHANGE			TEXT( "param_change" )
#define CALLBACK_NAME_NETBINDADD			TEXT( "net_bind_add" )
#define CALLBACK_NAME_NETBINDREMOVE			TEXT( "net_bind_remove" )
#define CALLBACK_NAME_NETBINDENABLE			TEXT( "net_bind_enable" )
#define CALLBACK_NAME_NETBINDDISABLE		TEXT( "net_bind_disable" )
// Control callback function names for misc stuff...
#define CALLBACK_NAME_USER_DEFINED			TEXT( "user_defined" )

*/

#define WM_DAEMON_STATE_CHANGE              0xffff


// external globals available from the daemon.h header

#if _DEBUG
    extern TCHAR   gszDebugOutputPath[ MAX_PATH ];
    extern CRITICAL_SECTION gcsDebugOutput;
#endif // _DEBUG


extern int		 giThread;
extern int		 iTheList;
extern TCHAR     gszModulePath[];
extern HANDLE    ghServiceThread;
extern BOOL      gfCallbackMode;
extern DWORD     gMainThreadId;
extern DWORD     gServiceThreadId;
extern DWORD     gServiceMainThreadID;
extern DWORD     gdwServiceBits;
extern DWORD     gdwLastError;
extern DWORD     gdwServiceErrorState;
extern DWORD     gdwState;
extern DWORD     gdwTimeoutState;
extern DWORD     gdwServiceType;
extern DWORD     gdwControlsAccepted;
extern UINT_PTR  ghTimer;
extern DWORD     gdwHandlerTimeout;
extern DWORD     gdwLastControlMessage;
extern HINSTANCE ghDLL;
extern SERVICE_STATUS_HANDLE ghService;  
extern SERVICE_STATUS gServiceStatus;
extern HANDLE  ghLogFile;

void LogToFile( LPTSTR pszMessage );
BOOL ResetCallbackTimer( UINT uintTimeoutValue = -1 );
BOOL KillTimer();
int My_SetServiceBits( SERVICE_STATUS_HANDLE hService, DWORD dwServiceBits, BOOL bSetBitsOn, BOOL bUpdateImmediately );
BOOL GetProcessSid( HANDLE hProcess, SID *pSid, DWORD dwSidBufferSize );
BOOL GetSidFromToken( HANDLE hToken, SID *pSid, DWORD dwSidBufferSize );
BOOL SetPrivilege( HANDLE hToken, const char *pszPrivilege, BOOL bSetFlag );
void TextFromSid( LPTSTR pszBuffer, SID *pSid );
BOOL LoadProfile( SID *pSid );
BOOL StoreServiceDescription( LPCTSTR pszMachine, LPCTSTR pszServiceName, LPCTSTR pszDescription );
void DispatchThreadMessage( MSG *pMsg );
HANDLE CreateLog( LPCTSTR pszPath );
#ifdef ENABLE_CALLBACKS
    BOOL ProcessStateChange( pTHX_ DWORD dwCommand, HV* pHvContext );
    void CALLBACK TimerProc(   HWND hWnd, UINT nMsg, UINT nIDEvent, DWORD dwTime );
    void CallPerlRoutine( pTHX_ CV* pPerlSubroutine, DWORD dwCommand, HV* pHvContext );
#endif // ENABLE_CALLBACKS

#endif // _CONSTANT_H_
