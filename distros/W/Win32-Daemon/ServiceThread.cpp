//////////////////////////////////////////////////////////////////////////////
//
//  ServiceThread.cpp
//  Win32::Daemon Perl extension service manager thread source file
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

#define WIN32_LEAN_AND_MEAN

// Enable MS Visual Studio 2005's secure stdlib
// The _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES macro defined with a value of 1
// will swap out a secured version of stdlib functions. These perform buffer overrun
// checking and such.
//	define _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES	1

//	As an alternative you can keep the depricated function calls and block out any
//	security warnings by defining the _CRT_SECURE_NO_DEPRECATE macro.
#define _CRT_SECURE_NO_DEPRECATE

#include <windows.h>
#include <lmaccess.h>   //  Service stuff
#include <lmserver.h>   //  Service stuff
#include <lmapibuf.h>
#include <LMERR.H>      //  For the NERR_Succes macro

#include <stdio.h> // REmove. ONly used for sprintf for debugging.

#include "constant.h"
#include "CWinStation.hpp"
#include "ServiceThread.hpp"

// #include <crtdbg.h>

static SERVICE_TABLE_ENTRY gpServiceTable[] =
{
    {
        (char*)TEXT( "GROWL!" ), ServiceMain
    },
    {
        NULL,   NULL
    }
};


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ServiceMain()
//  Called by the Service Manager.
VOID WINAPI ServiceMain( DWORD dwArgs, LPTSTR *ppszArgs)
{
    HWND hWnd = NULL;
    LPCTSTR pszServiceName = ppszArgs[0];
    
	//
	//	Record this ServiceMain's thread ID for other threads to use.
	//
	gServiceMainThreadID = GetCurrentThreadId();

    ALERT( "ServiceMain: function started. Passed inn Name is...\n" );
    ALERT( pszServiceName );
    ALERT( "ServiceMain: About to call RegisterServiceCtrlHandler()...\n" );

// Test to see if we can cause the message loop to start queuing...
SetTimeoutTimer( 10 );
    
    CleanStatusStruct( &gServiceStatus );
    gServiceStatus.dwCurrentState = SERVICE_START_PENDING;
        
    ghService = RegisterServiceCtrlHandler( pszServiceName, ServiceHandler );
    if( 0 != ghService )
    {
        ALERT( "ServiceMain: Just came out of RegisterServiceCtrlHandler()" );

        // If the state has not yet changed then push start everything...
        if( 0 == gdwState )
        {
            gdwState = SERVICE_START_PENDING;
            //
            //  If we are in callback mode then make sure to 
            //  start by posting a SERVICE_START_PENDING message
            //  (even though one does not exist in the Win32 API)
            //  so the script has a chance to start.
            //
            if( FALSE != gfCallbackMode )
            {
                //
                //  Call the service handler indicating that the "fake" 
                //  SERVICE_CONTROL_START event has been received.
                //
                ServiceHandler( SERVICE_CONTROL_START );
            }
        }

        {
            char szBuffer[256];
            sprintf( szBuffer, "ServiceMain: About to call My_SetServiceBits with gdwServiceBits=0x%08x", gdwServiceBits );
            ALERT( szBuffer );
        }

        if( 0 != gdwServiceBits )
        {
            My_SetServiceBits( ghService, gdwServiceBits, TRUE, TRUE );
        }
        ALERT( "ServiceMain: Entering message loop" );

        // Call a Win32 User level function to create a message queue
        GetDesktopWindow();
        GetWindow( NULL, GW_HWNDFIRST );
        
        if( 1 )
        {
            MSG Message;
            BOOL fContinueProcessing = TRUE;

            while( TRUE == fContinueProcessing )
            { 
                ALERT( "ServiceMain: Just enetered the message loop" );

                try
                {
                    fContinueProcessing = (BOOL) GetMessage( &Message, (HWND) NULL, 0, 0 );
#ifdef _DEBUG
					TCHAR szBuffer[256];
					wsprintf( szBuffer, "Got message: 0x%08x", Message.message );
					ALERT( szBuffer );
#endif // _DEBUG
                }
                catch (...)
                {
                    ALERT( "ServiceMain: Ouch!!! We caught an exception!" );
                }


                switch( Message.message )
                {

                case WM_USER_SET_TIMER:
                    ALERT( "ServiceMain: Setting timer" );
                    ghTimer = ::SetTimer( NULL, SERVICE_THREAD_TIMER_ID, (UINT)Message.wParam * DEFAULT_HANDLER_TIMEOUT_SCALE, (TIMERPROC)TimerHandler );
                    break;

				case WM_QUIT:
					fContinueProcessing = FALSE;
					break;

				case WM_QUERYENDSESSION:
                case WM_ENDSESSION:
                case WM_TIMER:
                    ALERT( "ServiceMain: HandlerTimeoutTimer due to WM_TIMER." );     
                    KillTimer();
                    gdwState = gdwTimeoutState;
                    UpdateServiceStatus( gdwTimeoutState );
				
                default:
                    ALERT( "ServiceMain: Dispatching message." );
                    TranslateMessage( &Message ); 
					//
					//	Calling DispatchMessage() is probably foolish since
					//	there is no window associated with this thread. 
					//	Per MSDN: messages that are not associated with a window cannot be dispatched by the DispatchMessage function
                    DispatchMessage( &Message ); 
                }
            } 
        }
        ALERT( "ServiceMain: Just left the message loop." );
        UpdateServiceStatus( gdwState );    

    }
    else
    {   
        gdwState = SERVICE_STOPPED;
#ifdef _DEBUG
        TCHAR szBuffer[ 100 ];
        wsprintf( szBuffer, TEXT( "ServiceMain: ERROR! 0x08x" ), GetLastError() );
        ALERT( szBuffer );
#endif // _DEBUG
    }

    ALERT( "ServiceMain: Shutting down ServiceMain()!" );
    return;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
VOID WINAPI ServiceHandler( DWORD dwControl )
{
    const char *pszCommand = SERVICE_CONTROL_STRING_EMPTY;
    DWORD dwState = gdwState;
    BOOL fUseTimer = FALSE;
#ifdef _DEBUG
    TCHAR szBuffer[ 256 ];
  
#endif // _DEBUG

    ALERT( "ServiceHandler: Incoming service control message..." );

    switch( dwControl )
    {
    case SERVICE_CONTROL_START:
        pszCommand = SERVICE_CONTROL_STRING_START;
        // This control message requires that we change the state...
		dwState = SERVICE_START_PENDING;
        fUseTimer = TRUE;
        gdwTimeoutState = SERVICE_RUNNING;
        break;


    case SERVICE_CONTROL_STOP:
        pszCommand = SERVICE_CONTROL_STRING_STOP;
        // This control message requires that we change the state...
		dwState = SERVICE_STOP_PENDING;
        fUseTimer = TRUE;
        gdwTimeoutState = SERVICE_STOPPED;
        break;
    
    case SERVICE_CONTROL_PAUSE:
        pszCommand = SERVICE_CONTROL_STRING_PAUSE;
        // This control message requires that we change the state...
		// ...but if we are already paused then don't
		if( SERVICE_PAUSED != gdwState )
		{
			dwState = SERVICE_PAUSE_PENDING;
		}

        fUseTimer = TRUE;
        gdwTimeoutState = SERVICE_PAUSED;
        break;    
    
    case SERVICE_CONTROL_CONTINUE:
        pszCommand = SERVICE_CONTROL_STRING_CONTINUE;
		// This control message requires that we change the state...
		// ...but only if we are already paused.
		if( SERVICE_PAUSED == gdwState )
		{
			dwState = SERVICE_CONTINUE_PENDING;
		}
        fUseTimer = TRUE;
        gdwTimeoutState = SERVICE_RUNNING;
        break;    
    
    case SERVICE_CONTROL_SHUTDOWN:
        pszCommand = SERVICE_CONTROL_STRING_SHUTDOWN;
        //	No dwState value for this control message
        //  No gdwTimeoutState for this state
        break;    

    ///////////////////////////////////////////////////////////////
    // Start nonstates (these are commands)
    // Fix by Thomas Kratz [Thomas.Kratz@lrp.de]
	// Control command messages have not associated state
	// so don't set the dwState
    case SERVICE_CONTROL_INTERROGATE:
        pszCommand = SERVICE_CONTROL_STRING_INTERROGATE;
		gdwLastControlMessage = dwControl;
		//	No dwState value for this control message
        //  No gdwTimoutState for this state
        break;    
    

    //  Win2k control codes...
    case SERVICE_CONTROL_PARAMCHANGE:
        pszCommand = SERVICE_CONTROL_STRING_PARAMCHANGE;
		//	No dwState value for this control message
        break;    

    case SERVICE_CONTROL_NETBINDADD:
        pszCommand = SERVICE_CONTROL_STRING_NETBINDADD;
		//	No dwState value for this control message
        break;    

    case SERVICE_CONTROL_NETBINDREMOVE:
        pszCommand = SERVICE_CONTROL_STRING_NETBINDREMOVE;
		//	No dwState value for this control message
        break;    

    case SERVICE_CONTROL_NETBINDENABLE:
        pszCommand = SERVICE_CONTROL_STRING_NETBINDENABLE;
		//	No dwState value for this control message
        break;    

    case SERVICE_CONTROL_NETBINDDISABLE:
        pszCommand = SERVICE_CONTROL_STRING_NETBINDDISABLE;
		//	No dwState value for this control message
        break;    

#ifdef SERVICE_CONTROL_PRESHUTDOWN 
	case SERVICE_CONTROL_PRESHUTDOWN :
		pszCommand = SERVICE_CONTROL_STRING_PRESHUTDOWN ;
		//	No dwState value for this control message
        break;
#endif

    //  User defined control codes...there are 128 of them
    case SERVICE_CONTROL_USER_DEFINED:
    case SERVICE_CONTROL_USER_DEFINED + 0x01:
    case SERVICE_CONTROL_USER_DEFINED + 0x4f:
		//	No dwState value for this control message
        break;

    default:
        pszCommand = SERVICE_CONTROL_STRING_DEFAULT;
        //	No dwState value for this control message
        break;    
    }
	
	// Set the last control message to what was received. Some control messages
	// result in a state change but we should always report the message.
	gdwLastControlMessage = dwControl;

#ifdef _DEBUG
    wsprintf( szBuffer, "ServiceHandler: Received message => %s (0x%0x)\n", pszCommand, dwControl );
    ALERT( szBuffer );
#endif // _DEBUG

//	TODO:
//	We should set an alarm to for some configurable timeout value so that
//	in case the perl script does not process the request we will change
//	the state automatically	

    if( FALSE != fUseTimer )
    {
        SetTimeoutTimer( gdwHandlerTimeout );
    }
    
	//
	//	Update the service status with the dwState. If there were
	//	control messages that warrant a state change then do it
	//	otherwise dwState was set (at beginning of this function)
	//	to be the same as the current state.
	//
    UpdateServiceStatus( dwState );

    //
	//	This code is only used when in callback mode...
	//	Post a daemon state change message to the main Win32::Daemon
	//	thread so that it knows to callback into Perl.
	//
    if( FALSE != gfCallbackMode )
    {
        ALERT( "ServiceHandler: Posting message to main thread for callbacks\n" );

		//
		//	Post to the main thread that we have a state change. 
		//
		//	Make sure to post the dwControl value (not dwState). This control value
		//	maps directly to callback index values!
		//
        PostThreadMessage( gMainThreadId, WM_DAEMON_STATE_CHANGE, (WORD) dwControl, 0 ); 
    }
} 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void SetTimeoutTimer( DWORD dwTimeout )
{
    KillTimer();

	// TODO:
	//	Make sure this code works. We are posting the set timer message to the service main thread...NOT 
	//	the service thread.
	PostThreadMessage( (DWORD) gServiceMainThreadID, WM_USER_SET_TIMER, (WPARAM) dwTimeout * DEFAULT_HANDLER_TIMEOUT_SCALE, (LPARAM) NULL );


#ifdef _DEBUG
    TCHAR szBuffer[ 256 ];
    wsprintf( szBuffer, "Setting timer will value of %d. Timer # is %d", gdwHandlerTimeout, ghTimer );
    ALERT( szBuffer );
#endif // _DEBUG
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void CleanStatusStruct( SERVICE_STATUS *pServiceStatus )
{
    if( NULL != pServiceStatus )
    {
        ZeroMemory( pServiceStatus, sizeof( SERVICE_STATUS ) );
        pServiceStatus->dwServiceType = gdwServiceType;
		pServiceStatus->dwControlsAccepted = gdwControlsAccepted;
        pServiceStatus->dwWin32ExitCode = NO_ERROR;
        pServiceStatus->dwServiceSpecificExitCode  = 0x00000000;
    }
}           

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
VOID CALLBACK TimerHandler( HWND hWnd, UINT uMsg, UINT uEventId, DWORD dwSystemTime )
{
    ALERT( "HandlerTimeoutTimer callback called." );
    KillTimer();
    gdwState = gdwTimeoutState;
    UpdateServiceStatus( gdwTimeoutState );
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BOOL KillTimer()
{
    BOOL fResult = FALSE;

    if( ghTimer )
    {
        ALERT( "Killing timer due to a new pending command" );
        fResult = ::KillTimer( NULL, ghTimer );
        ghTimer = 0;
    }
    return( fResult );
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BOOL UpdateServiceStatus( DWORD dwState, DWORD dwWaitHint, DWORD dwError )
{
    BOOL fResult = FALSE;
    SERVICE_STATUS Status;
    CleanStatusStruct( &Status );
    gdwState = Status.dwCurrentState = dwState;

	KillTimer();

#ifdef _DEBUG
    TCHAR szBuffer[ 256];
    wsprintf( szBuffer, "UpdateServiceStatus: Updating service status to 0x%08x with hint of 0x%04x\n", gdwState, dwWaitHint );
    ALERT( szBuffer );
#endif // _DEBUG

    Status.dwWaitHint = dwWaitHint;

    // If no error was specified then we must use the last error used.
    if( 0xFFFFFFFF == dwError )
    {
        dwError = gdwServiceErrorState;
    }
    else
    {
        gdwServiceErrorState = dwError;
    }
    if( NO_ERROR == dwError )
    {
        Status.dwWin32ExitCode  = NO_ERROR;
        Status.dwServiceSpecificExitCode = 0;
    }
    else
    {
        Status.dwWin32ExitCode  = ERROR_SERVICE_SPECIFIC_ERROR;
        Status.dwServiceSpecificExitCode = dwError;
    }

    fResult = SetServiceStatus( ghService, &Status );
#ifdef _DEBUG
    if( fResult )
    {
        ALERT( "UpdateServiceStatus: update was successful" );
    }
    else
    {
        ALERT( "UpdateServiceStatus: update failed" );
    }
#endif

    return( fResult );
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DWORD WINAPI ServiceThread( LPVOID pVoid )
{   
    DWORD dwResult = 0;

    ALERT( "ServiceThread: Starting. Calling StartServiceCtrlDispatcher()..." );

    if( FALSE != StartServiceCtrlDispatcher( (LPSERVICE_TABLE_ENTRY) gpServiceTable ) )
    {
        //  Successful
        dwResult = 1;
    }
    else
    {
        dwResult = 0;   
    }

    ALERT( "ServiceThread: Finished with StartServiceCtrlDispatcher()" );

    UpdateServiceStatus( SERVICE_STOPPED );

    ALERT( "ServiceThraed: ENDING THE SERVICE THREAD!!!!!!!!!!" );
    return( dwResult );
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/*

  HISTORY
  
    20020605 rothd
        - Modified: UpdateServiceStatus() function to accept a 3rd parameter (dwError). 
                    This allows the calling code to report a service error.


	20070102 rothd
		- Cleaned up a bit.
		- Added WM_QUIT message to the ServiceMain function. Now the Perl StopService() will 
		  post this message to shut down the service thread.
	    - Fixed bug where messages were posted to wrong thread.

	20080321 rothd
		-Added support for SERVICE_CONTROL_PRESHUTDOWN.
*/
