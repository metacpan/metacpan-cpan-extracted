//////////////////////////////////////////////////////////////////////////////
//
//  Daemon.cpp
//  Win32::Daemon Perl extension main source file
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


// Enable Win32::Daemon callback support
#define ENABLE_CALLBACKS

// Enable MS Visual Studio 2005's secure stdlib
// The _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES macro defined with a value of 1
// will swap out a secured version of stdlib functions. These perform buffer overrun
// checking and such.
//	define _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES	1

//	As an alternative you can keep the depricated function calls and block out any
//	security warnings by defining the _CRT_SECURE_NO_DEPRECATE macro.
#define _CRT_SECURE_NO_DEPRECATE



#define WIN32_LEAN_AND_MEAN

#ifdef __BORLANDC__
typedef wchar_t wctype_t; /* in tchar.h, but unavailable unless _UNICODE */
#endif

#include <windows.h>
#include <tchar.h>
#include <wtypes.h>
#include <stdio.h>      //  Gurusamy's right, Borland is brain damaged!
#include <math.h>       //  Gurusamy's right, MS is brain damaged!
#include <time.h>

//  Use headers that define the security stuff
#include <lmaccess.h>
#include <lmserver.h>
#include <lmapibuf.h>
#include <LMERR.H>      //  For the NERR_Succes macro

#include "XS_Win32Perl.h"
//	#include <preWin32Perl.h>
//	#include <Win32Perl.h>

#include "constant.h"
#include "CWinStation.hpp"
#include "ServiceThread.hpp"

#ifdef ENABLE_CALLBACKS
	#include "CCallbackList.hpp"
	#include "CCallbackTimer.hpp"
#endif // ENABLE_CALLBACKS
#include "daemon.h"

#define SET_SERVICE_BITS_LIBRARY    TEXT( "AdvApi32.dll" )
#define SET_SERVICE_BITS_FUNCTION   TEXT( "SetServiceBits" )


/*----------------------- M I S C   F U N C T I O N S -------------------*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int My_SetServiceBits( SERVICE_STATUS_HANDLE hService, DWORD dwServiceBits, BOOL bSetBitsOn, BOOL bUpdateImmediately )
{
    int iResult = 0;
    HINSTANCE hInstance;
    DWORD dwMask = USER_SERVICE_BITS_MASK;      // Default mask. These bits are not reserved by MS. We can use these w/o problems w/MS products.

    hInstance = LoadLibrary( SET_SERVICE_BITS_LIBRARY );
    if( NULL != hInstance )
    {
        typedef BOOL (CALLBACK *fSetServiceBits) ( SERVICE_STATUS_HANDLE hServiceGoo, DWORD dwBits, BOOL bBitsOn, BOOL bUpdate );
        fSetServiceBits pSetServiceBits = NULL;
        pSetServiceBits= (fSetServiceBits) GetProcAddress( hInstance, SET_SERVICE_BITS_FUNCTION );
        if( NULL != pSetServiceBits )
        {
            // Note:
            // We clear all user defined bits before applying our bits. If this sucks
            // then use something like Win32::Lanman. We only want to track our bits
            // and not mess with others.

            //  First clear all user defined bits...
            // My_SetServiceBits() will mask out the user bits from the passed in DWORD.
            (*pSetServiceBits)( ghService, 0xFFFFFFFF, FALSE, FALSE );

            // Mask those lovely bits!
            dwServiceBits &= dwMask;
            iResult = (*pSetServiceBits)( hService, dwServiceBits, bSetBitsOn, bUpdateImmediately );
        }
    }

    return( iResult );
}

BOOL GetProcessSid( HANDLE hProcess, SID *pSid, DWORD dwSidBufferSize )
{
    BOOL fResult = FALSE;
    HANDLE hToken = NULL;

    if( ( NULL == pSid ) || ( sizeof( SID ) > dwSidBufferSize ) )
    {
        return( FALSE );
    }

    // Manually get the process token since we need it for more than just
    // calling into SetPrivilege()...
    if( OpenProcessToken(
            hProcess,
            TOKEN_ADJUST_PRIVILEGES
            | TOKEN_QUERY
            | TOKEN_QUERY_SOURCE,
            &hToken ) )
    {
        // Now that you have the token for this process, you want to set
        // the SE_DEBUG_NAME privilege.

// TODO:
// We may want to not do this here. Only if we show the
// service. Otherwise this may give us too many privileges that
// we may not want to have

        SetPrivilege( hToken, SE_DEBUG_NAME, TRUE );

        // Determine the SID for the current process. We need
        // to give this SID permissions to access the
        // desktop object...
        fResult =  GetSidFromToken( hToken, pSid, dwSidBufferSize );
        CloseHandle( hToken );
    }
    return( fResult );
}


////////////////////////////////////////////////////////////////////////////
//  ResetCallbackTimer()
//  Stops or changes the callback timer.
//  Passing in nothing simply stops/starts the timer (depending upon the state)
//  Passing in 0 stops the timer.
//  Passing in any positive value starts the timer and sets that value as callback timeout.
//  
//	Default pass in value is -1 (if nothing is specified).
//
/*
BOOL ResetCallbackTimer( UINT uintTimeoutValue )
{
    //
    // If the callback timer is active then kill it
    //
    if( 0 != gpuintCallbackTimerID )
    {
        KillTimer( NULL, gpuintCallbackTimerID );
        gpuintCallbackTimerID = 0;
        if( -1 == uintTimeoutValue )
        {
            return( TRUE );
        }
    }

    //
    //  Are we changing the value? A 0 means to simply stop
    //  the timer. Otherwise change the timeout value...
    //
    if( 0 == uintTimeoutValue ) return( TRUE );

    if( 0 <= (int) uintTimeoutValue )
    {
        guintCallbackTimer = uintTimeoutValue;
    }
        
    if( 0 != guintCallbackTimer )
    {
        gpuintCallbackTimerID = SetTimer( NULL, CALLBACK_RUNNING_TIMER, guintCallbackTimer, (TIMERPROC) NULL );
    }
    
    return( TRUE );
}
*/

////////////////////////////////////////////////////////////////////////////
//  Fill in a SID buffer from the specified token
BOOL GetSidFromToken( HANDLE hToken, SID *pSid, DWORD dwSidBufferSize )
{
    BOOL fResult = FALSE;

    if( NULL != hToken )
    {
        PTOKEN_USER  pTokenUserStruct = NULL;
        DWORD dwLength = 0;

        if( FALSE == GetTokenInformation(
                hToken,
                TokenUser,
                pTokenUserStruct,
                0,
                &dwLength ) )
        {
            pTokenUserStruct = (PTOKEN_USER) new BYTE [ dwLength ];
            if( NULL != pTokenUserStruct )
            {
                ZeroMemory( pTokenUserStruct, dwLength );
                if( GetTokenInformation(
                        hToken,
                        TokenUser,
                        pTokenUserStruct,
                        dwLength,
                        &dwLength ) )
                {
                    if( FALSE != IsValidSid( pTokenUserStruct->User.Sid ) )
                    {
                        DWORD dwSidLength;

                        dwSidLength = GetLengthSid( pTokenUserStruct->User.Sid );
                        if( dwSidLength <= dwSidBufferSize )
                        {
                            fResult = CopySid( dwSidLength, pSid, pTokenUserStruct->User.Sid );
                        }
                    }
                }
                delete [] pTokenUserStruct;
            }
        }
    }
    return( fResult );
}

////////////////////////////////////////////////////////////////////////////
// The SetPrivilege function will accept a handle to a token, a
// privilege, and a flag to either enable/disable that privilege. The
// function will attempt to perform the desired action upon the token
// returning TRUE if it succeeded, or FALSE if it failed.
BOOL SetPrivilege( HANDLE hToken, const char *pszPrivilege, BOOL bSetFlag )
{
    TOKEN_PRIVILEGES structPriv, structPrevPriv;
    LUID Luid;
    DWORD dwStructSize = sizeof( structPrevPriv );
    BOOL fResult = FALSE;
    BOOL fCloseToken = FALSE;

    // If no token is specified assume that the process token is desired.
    if( 0 == hToken )
    {    
        OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_ADJUST_PRIVILEGES
            | TOKEN_QUERY
            | TOKEN_QUERY_SOURCE,
            &hToken );
        fCloseToken = TRUE;
    }
    if( 0 != hToken )
    {
        ZeroMemory( &structPrevPriv, sizeof( structPrevPriv ) );
        ZeroMemory( &structPriv, sizeof( structPriv ) );

        // Grab the LUID for the request privilege.
        if( LookupPrivilegeValue( "", pszPrivilege, &Luid ) )
        {
            // Set up basic information for a call.
            // You want to retrieve the current privileges
            // of the token under concern before you can modify them.
            structPriv.PrivilegeCount = 1;
            structPriv.Privileges[0].Luid = Luid;
            structPriv.Privileges[0].Attributes = ( bSetFlag )? SE_PRIVILEGE_ENABLED : 0;


            // You need to acquire the current privileges first
            fResult = ( FALSE != AdjustTokenPrivileges(
                                    hToken,
                                    0,
                                    &structPriv,
                                    sizeof( structPriv ),
                                    &structPrevPriv,
                                    &dwStructSize ) );
        }
        if( FALSE != fCloseToken )
        {
            CloseHandle( hToken );
        }
    }
    return( fResult );
}

////////////////////////////////////////////////////////////////////////////
//  Fill the specified text buffer with the text representation of the
//  specified SID.
//  NOTE: The buffer must have enough memory to represent the SID.
void TextFromSid( LPTSTR pszBuffer, SID *pSid )
{
    TCHAR szTemp[ 100 ];
    int iCount;
    PUCHAR puCount;

    SID_IDENTIFIER_AUTHORITY *pSia;

    if( FALSE == IsValidSid( pSid ) )
    {
        return;
    }

    pSia = GetSidIdentifierAuthority( pSid );

    //  Create the string version of the SID
    //  We begin by S (for SID) - the revision level - the authority
    //  identifier. Note that we are assuming that the Authority ID is in
    //  the sixth element (element #5 starting at 0) in Authority Identifier
    //  structure. Currently as of this writing SID strings do not display
    //  the other values in the pSiz strucutre. They are normally something
    //  like: {0,0,0,0,0,5} where the last byte contains a value and the others
    //  are zero.
    iCount = wsprintf( pszBuffer, TEXT( "S-%d-%d" ), pSid->Revision, (DWORD) pSia->Value[5] );
    puCount = GetSidSubAuthorityCount( pSid );
    for( DWORD dwTemp = 0; dwTemp < *puCount; dwTemp++ )
    {
        wsprintf( szTemp, TEXT( "-%d" ), (DWORD) *( GetSidSubAuthority( pSid, dwTemp ) ) );
        _tcscat( pszBuffer, szTemp );
    }
}

////////////////////////////////////////////////////////////////////////////
//  Load the user's profile hive into the HKEY_USERS Registry key.
BOOL LoadProfile( SID *pSid )
{
    BOOL fResult = FALSE;
    TCHAR szUserProfilePath[ 1024 ];
    TCHAR szSid[ 64 ];
    HKEY hKey = NULL;
#ifdef DEBUG
    TCHAR szDebugText[ 1024 ];
#endif // DEBUG

    ZeroMemory( szSid, sizeof( szSid ) );
    TextFromSid( szSid, pSid );

    _tcscpy( szUserProfilePath, REG_KEY_USER_LOCAL_PROFILE );
    _tcscat( szUserProfilePath, szSid );

#ifdef DEBUG
    wsprintf( szDebugText, TEXT( "[LoadProfile] Loading profile for %s" ), szSid );
    ALERT( szDebugText );
#endif

    // Check to see if we already have the profile loaded
    if( ERROR_SUCCESS == RegOpenKeyEx( HKEY_USERS,
                                        szSid,
                                        0,
                                        KEY_READ,
                                        &hKey ) )
    {
        RegCloseKey( hKey );
        ALERT( "[LoadProfile] Profile already loaded." );
        return( TRUE );
    }

    // If we got here then the profile is not loaded, let's load it.
    // First open the Registry key where profile info is held
    if( ERROR_SUCCESS == RegOpenKeyEx( HKEY_LOCAL_MACHINE,
                                        szUserProfilePath,
                                        0,
                                        KEY_READ,
                                        &hKey ) )
    {
        TCHAR szCentralPath[ MAX_PATH + 1 ];
        TCHAR szLocalPath[ MAX_PATH + 1 ];
        DWORD dwLength;
        DWORD dwType;
        HANDLE hToken = NULL;

        _tcscpy( szCentralPath, TEXT( "" ) );
        _tcscpy( szLocalPath, TEXT( "" ) );

        // We need to be granted Restore Name privileges. Otherwise
        // we won't be able to load the profile
        if( OpenProcessToken(
                GetCurrentProcess(),
                TOKEN_ADJUST_PRIVILEGES
                | TOKEN_QUERY
                | TOKEN_QUERY_SOURCE,
                &hToken ) )
        {
            // Now that you have the token for this process, you want to set
            // the SE_RESTORE_NAME privilege.
            SetPrivilege( hToken, SE_RESTORE_NAME, TRUE );
        }

        dwLength = sizeof( szCentralPath );
        if( ERROR_SUCCESS == RegQueryValueEx(
                                hKey,
                                REG_VALUE_USER_CENTRAL_PROFILE_PATH,
                                0,
                                &dwType,
                                (LPBYTE) szCentralPath,
                                &dwLength
                                ) )
        {
            // Expand environment variables if needed
            if( REG_EXPAND_SZ == dwType )
            {
                TCHAR szBuffer[ MAX_PATH + 1 ];

                _tcscpy( szBuffer, szCentralPath );
                ExpandEnvironmentStrings( szBuffer, szCentralPath, sizeof( szCentralPath ) );
            }
        }

        dwLength = sizeof( szLocalPath );
        if( ERROR_SUCCESS == RegQueryValueEx(
                                hKey,
                                REG_VALUE_USER_LOCAL_PROFILE_PATH,
                                0,
                                &dwType,
                                (LPBYTE) szLocalPath,
                                &dwLength
                                ) )
        {
            // Expand environment variables if needed
            if( REG_EXPAND_SZ == dwType )
            {
                TCHAR szBuffer[ MAX_PATH + 1 ];

                _tcscpy( szBuffer, szLocalPath );
                ExpandEnvironmentStrings( szBuffer, szLocalPath, sizeof( szLocalPath ) );
            }
        }

        if( 0 != _tcscmp( szCentralPath, TEXT( "" ) ) )
        {
            TCHAR szProfilePath[ MAX_PATH ];

            _tcscpy( szProfilePath, szCentralPath );
            _tcscat( szProfilePath, TEXT( "\\" ) );
            _tcscat( szProfilePath, USER_PROFILE_HIVE_NAME );

            // Try to load the profile. This may fail if the
            // path is a UNC to another machine or for other
            // reasons. RegLoadKey() seems to only load local
            // copies of profiles--possibly to prevent corruption
            // if the net goes down.
            // If this is the case we may want to copy the file
            // over.
            if( ERROR_SUCCESS == RegLoadKey(
                                            HKEY_USERS,
                                            szSid,
                                            szProfilePath
                                            ) )
            {
                fResult = TRUE;
#ifdef DEBUG
                wsprintf( szDebugText, TEXT( "[LoadProfile] Loaded %s" ), szProfilePath );
                ALERT( szDebugText );
#endif
            }
            else if( 0 != _tcscmp( szLocalPath, TEXT( "" ) ) )
            {
                TCHAR szDestination[ MAX_PATH ];

                _tcscpy( szDestination, szLocalPath );

                // determine if it is a file or directory, WinNT 4.0 it is a
                // directory
                // WinNT 3.51 it is a file
                //
                if( FILE_ATTRIBUTE_DIRECTORY == ( GetFileAttributes( szProfilePath )
                                                  & FILE_ATTRIBUTE_DIRECTORY ) )
                {
                    _tcscat( szProfilePath, TEXT( "\\" ) );
                    _tcscat( szProfilePath, USER_PROFILE_HIVE_NAME );
                }


                // Copy the profile hive file from the origin location to the
                // local local cached profile
                CopyFile( szProfilePath, szDestination, TRUE );
#ifdef DEBUG
                wsprintf( szDebugText, TEXT( "[LoadProfile] Copied path from %s to %s" ), szProfilePath, szDestination );
                ALERT( szDebugText );
#endif

            }
        }

        // Were we successful?
        if( ( FALSE == fResult ) && ( 0 != _tcscmp( szLocalPath, TEXT( "" ) ) ) )
        {
            // No, try loading the local path.
            TCHAR szProfilePath[ MAX_PATH ];

            _tcscpy( szProfilePath, szLocalPath );


            // determine if it is a file or directory, WinNT 4.0 it is a
            // directory
            // WinNT 3.51 it is a file
            //
            if( FILE_ATTRIBUTE_DIRECTORY == ( GetFileAttributes( szProfilePath )
                                              & FILE_ATTRIBUTE_DIRECTORY ) )
            {
                _tcscat( szProfilePath, TEXT( "\\" ) );
                _tcscat( szProfilePath, USER_PROFILE_HIVE_NAME );
            }

            // Try to load the profile.
            if( ERROR_SUCCESS == RegLoadKey(
                                            HKEY_USERS,
                                            szSid,
                                            szProfilePath
                                            ) )
            {
                fResult = TRUE;
#ifdef DEBUG
                wsprintf( szDebugText, TEXT( "[LoadProfile] Loaded %s" ), szProfilePath );
                ALERT( szDebugText );
#endif
            }
        }

        RegCloseKey( hKey );
    }

    return( fResult );
}

//////////////////////////////////////////////////////////////////
//  Store the service's description in the Registry. Win2k does
//  this for you but we need to be backward compatible.
BOOL StoreServiceDescription( LPCTSTR pszMachine, LPCTSTR pszServiceName, LPCTSTR pszDescription )
{
    HKEY hRoot = HKEY_LOCAL_MACHINE;
    HKEY hKey = NULL;
    BOOL fFlag = TRUE;
    BOOL fResult = FALSE;

    if( 0 != _tcscmp( TEXT( "" ), pszMachine ) )
    {
        fFlag = ( ERROR_SUCCESS == RegConnectRegistry( pszMachine, HKEY_LOCAL_MACHINE, &hRoot ) );
    }

    if( TRUE == fFlag )
    {
        TCHAR szBuffer[ 75 ];
        _stprintf( szBuffer, REGISTRY_SERVICE_PATH TEXT( "\\%s" ), pszServiceName );
        if( ERROR_SUCCESS == RegOpenKeyEx( hRoot, szBuffer, 0, KEY_SET_VALUE, &hKey ) )
        {
            DWORD dwSize = (DWORD)_tcslen( pszDescription ) * sizeof( TCHAR );
            fResult = ( ERROR_SUCCESS == RegSetValueEx( hKey, REGISTRY_SERVICE_KEYWORD_DESCRIPTION, 0, REG_SZ, (LPBYTE) pszDescription, dwSize ) );
        }
        RegCloseKey( hKey );
    }

    if( 0 != _tcscmp( TEXT( "" ), pszMachine ) )
    {
        RegCloseKey( hRoot );
    }

    return( fResult );
}


#ifdef ENABLE_CALLBACKS
//////////////////////////////////////////////////////////////////
//  The idea here is that when a state change occurs because the
//	SCM has submitted a command (stop, pause, start, interrogate, etc)
//	we can call this function. If callbacks have been enabled then 
//	this function will execute the Perl callback if a callback routine 
//	has been provided. Otherwise we just pass through.
//  
BOOL ProcessStateChange( pTHX_ DWORD dwCommand, HV* pHvContext )
{
	BOOL fMakeContextHash = FALSE;
	PVOID pSvSubroutine = gCallback.Get( dwCommand );
	
	//
	// The SERVICE_CONTROL_TIMER has replaced SERVICE_RUNNING. Since
	// SERVICE_RUNNING is easily confused with another constant with teh
	// same value we have renamed this SERVICE_CONTROL_RUNNING for clarity.
	// Regardless, SERVICE_CONTROL_RUNNING is being depreciated and replaced
	// with SERVICE_CONTROL_TIMER to better indicate why the callback is 
	// occuring.
	// For legacy purposes:
	//	1) Registering a "running" callback will still work
	//	2) Registering a "timer" callback is preferred instead of "running"
	//	3) Registering both will result in only a "timer" callback
	//
	// Now let's check if this is the timer command AND if the script has
	// registered only the "running" callback...
	if( SERVICE_CONTROL_TIMER == dwCommand )
	{
//
//	Code currently changes 3) to result in "running" for legacy support
//	if code called Callback() passing in only one catchall subroutine reference
//

		PVOID pSvTemp;
		pSvTemp = gCallback.Get( SERVICE_CONTROL_RUNNING );
		if( NULL != pSvTemp )
		{
			pSvSubroutine = pSvTemp;
			dwCommand = SERVICE_CONTROL_RUNNING;
		}

     }	

#ifdef aTHX
    if( NULL == aTHX )
    {
        return( FALSE );
    }
#endif // aTHX
    
	if( NULL == pSvSubroutine )
	{
		return( FALSE );
	}

	ALERT( "ProcessStateChange: checking for context hash..." );
	// If there is no context hash provided then make one...
	if( NULL == pHvContext )
	{
		ALERT( "ProcessStateChange: Creating a new context hash" );
		pHvContext = newHV();
	}
	else
	{
		// If we don't create the context HV then increase its ref count because
		// later we will decrease it. If we created the HV then the decrease will
		// auto destroy it.
		ALERT( "ProcessStateChange: Increasing ref count on existing context hash" );
		SvREFCNT_inc( (SV*) pHvContext );
	}

	 ALERT( "ProcessStateChange: Storing value into context hash" );
	HASH_STORE_IV( pHvContext, KEYWORD_CALLBACK_COMMAND_NAME, dwCommand );

	ALERT( "ProcessStateChange: Checking for a valid subroutine" );
	if( SVt_PVCV == SvTYPE( (SV*) pSvSubroutine ) )
	{
		ALERT( "About to call into a Perl routine..." );
		//	Call into the Perl subroutine
		//  Push onto the stack the hash context
		CallPerlRoutine( aTHX_ (CV*) pSvSubroutine, 
						dwCommand,
						pHvContext );
		ALERT( "Back from calling into a Perl routine..." );
		//	Callback into the subroutine.
		//	The subroutine should look like:
		//
		//	sub EventCallback
		//	{
		//	  my( $Event, $Context ) = @_;
		//		# Process the event
		//		Win32::Daemon::State( $NewState );		
		//	  return;
		//	}
		//
		//	=================== OR ====================
		//	sub EventCallback
		//	{
		//	  my( $Event, $Context ) = @_;
		//		# Process the event
		//	  return( $NewState );
		//	}

	}
	
	// Decrease the context HV reference counter. If we created the HV then it is
	// unloaded at this time. Otherwise we have previously increased the count so
	// this just decreases it back to where it started at the beginning of this
	// routine.
	SvREFCNT_dec( (SV*) pHvContext );
	return( TRUE );
}
#endif // ENABLE_CALLBACKS

#ifdef ENABLE_CALLBACKS
////////////////////////////////////////////////////////////////////////////
//  CallPerlRoutine()
//  This will callback into a specified Perl subroutine passing in any
//  SVs that are passed into the function.
//  Nothing is returned.
//
//  void CallPerlRoutine( pTHX_ CV* pPerlSubroutine, int iTotalParams, ... )
void CallPerlRoutine( pTHX_ CV* pPerlSubroutine, DWORD dwCommand, HV* pHvContext )
{
    SV *pSv = NULL;
    int iReturnedItems = 0;

	// Make sure that a routine was passed in AND that it is really a code reference
    if( ( NULL == pPerlSubroutine ) || ( SVt_PVCV != SvTYPE( (SV*) pPerlSubroutine ) ) )
    {
        return;
    }

    //  Declare necessary vars...
    dSP;

    //  Begin a new scope...
    ENTER;

    //  Start mortal stack. All mortals after this point will be put onto this stack
    //  which will be freeded up later with FREETMPS
    SAVETMPS;

    //  Remember (or push) the current position of the stack...
    ALERT( "CallPerlRoutine: Pushing parameters onto the perl stack" );
    PUSHMARK( sp );
    XPUSHs( sv_2mortal( newSViv( (IV) dwCommand ) ) );
    XPUSHs( (SV*) newRV_inc( (SV*) pHvContext ) );
    //  Mark the end of arguments on the stack...
    PUTBACK;
    ALERT( "CallPerlRoutine: Done: Pushed parameters onto the perl stack" );

	TCHAR szBuff[ 256 ];
    sprintf( szBuff, "CallPerlRoutine: Calling into Perl for command: 0x%04x.\n", dwCommand );
    ALERT( szBuff );

    ALERT( "CallPerlRoutine: Calling into the perl routine now..." );

	iReturnedItems = perl_call_sv( (SV*) pPerlSubroutine, G_SCALAR );
    
	ALERT( "CallPerlRoutine: ...Back from calling the perl routine." );
    
    //  Begin the process of unwinding the return stack...
    SPAGAIN;

	if( iReturnedItems )
	{
		SV *pSvReturn = POPs;

		//
		//	Check if the return value is an integer
		//
		if( SvIOK( pSvReturn ) )
		{
			//
			//	Any integer return value is a new state value
			//	so update the service's state. Specify waithint value of 0
			//	and error value of 0xFFFFFFFF to use defaults.
			//
                        DWORD dwNewState = (DWORD)SvIV( pSvReturn );
			UpdateServiceStatus( dwNewState, 0, 0xFFFFFFFF );
		}

		//
		//	NOTE: the while() look predecriments iReturnedItems to 
		//	accomodate the new state value taken off of the stack
		//
		while( --iReturnedItems )
		{
			//  Pop an SV off of the return stack...
			POPs;
		}
	}

    //  We are done here so put back the stack pointer...
    PUTBACK;

    //  Unwind and destroy any mortals that are on our temp stack...
    FREETMPS;

    //  Leave our little scope...
    LEAVE;
}
#endif // ENABLE_CALLBACKS


////////////////////////////////////////////////////////////////////////////
//  DispatchThreadMessage()
//  This is called for every message that the thread message queue receives.
//	This is used instead of DispatchMessage() since there is no window available.
//
void DispatchThreadMessage( MSG *pMsg )
{
	// Retrieve the Perl context...
	dTHX;

#ifdef _DEBUG
    TCHAR szBuffer[ 1024 ];
    wsprintf( szBuffer, TEXT( "Servicing Thread Message Queue: Message = 0x%04x; aTHX = 0x%04x." ), pMsg->message, aTHX );
    ALERT( szBuffer );
#endif // _DEBUG

	BOOL fCallbackState = FALSE;

	switch( pMsg->message )
	{
        case WM_DAEMON_STATE_CHANGE:
		// We have a state change!
		// Notice we are using gPerlObject here! Therefore we MUST be in 
		// callback mode!
		//
		//  First reset the timer. Don't pass in any value so that it just
		//  temporarily pauses the timer. The next time you call it without
		//  any params it will start it again. This prevents queuing up 
		//  timeout messages if the callback takes time. 
		ALERT( TEXT( "...processing WM_DAEMON_STATE_CHANGE message\n" ) )
		fCallbackState =  gCallbackTimer.QueryState();
		if( fCallbackState )
		{
			gCallbackTimer.Stop();
		}
		ProcessStateChange( aTHX_ (DWORD) pMsg->wParam, gpHvContext );
		if( fCallbackState )
		{
			gCallbackTimer.Start();
		}
		break;
        
	case WM_TIMER:
		//
		//  You get here when the callback timeout value has been exceeded. This
		//  simply means that it is time to callback into the Perl script to give
		//  the script a chance to process anything it needs to.
		//  The script sees this event as a "SERVICE_RUNNING" event.
		//
			//
		//  First reset the timer. Don't pass in any value so that it just
		//  temporarily pauses the timer. The next time you call it without
		//  any params it will start it again. This prevents queuing up 
		//  timeout messages if the callback takes time. 
		ALERT( TEXT( "...processing WM_TIMER message (heartbeat callback)\n" ) )
		fCallbackState =  gCallbackTimer.QueryState();
		if( fCallbackState )
		{
			gCallbackTimer.Stop();
		}
		ProcessStateChange( aTHX_ (DWORD) SERVICE_CONTROL_TIMER, gpHvContext );
		if( fCallbackState )
		{
			gCallbackTimer.Start();
		}
		break;
		
	default:
		ALERT( "...Default handler has been invoked." );
	
    }
}

////////////////////////////////////////////////////////////////////////////
//  TimerProc()
//  This is called by a Win32 Timer every time the timer's timeout value is
//  reached. This is used to determine when to callback into the Perl script
//  to allow it for processing. When the callback into Perl occurs it does 
//  so indicating the SERVICE_RUNNING state.
//
void CALLBACK TimerProc(
   HWND hWnd,      // handle of CWnd that called SetTimer
   UINT nMsg,      // WM_TIMER
   UINT nIDEvent,   // timer identification
   DWORD dwTime    // system time
)
{
    MSG sMsg;

    ZeroMemory( &sMsg, sizeof( sMsg ) );
    sMsg.hwnd = hWnd;
    sMsg.lParam = 0;
    sMsg.message = WM_TIMER;
//    sMsg.pt = 0;
    sMsg.time = dwTime;
    sMsg.wParam = nIDEvent;

    DispatchThreadMessage( &sMsg );
}


#ifdef _DEBUG
//////////////////////////////////////////////////////////////////
//
//
HANDLE CreateLog( LPCTSTR pszPath )
{
    HANDLE hFile = 0;

    ZeroMemory( gszDebugOutputPath, sizeof( gszDebugOutputPath ) );
    _tcsncpy( gszDebugOutputPath, pszPath, sizeof( gszDebugOutputPath ) - 1 );

    if( 0 != ghLogFile )
    {
        CloseHandle( ghLogFile );
        ghLogFile = 0;
    }

    if( _tcscmp( TEXT( "" ), gszDebugOutputPath ) != 0 )
    {
        ghLogFile = CreateFile( gszDebugOutputPath,
                                GENERIC_READ | GENERIC_WRITE,
                                FILE_SHARE_READ,
                                NULL,
                                CREATE_ALWAYS,
                                FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH,
                                NULL );
        if( 0 == ghLogFile )
        {
            _tcscpy( gszDebugOutputPath, TEXT( "" ) );
        }
    }
    return( ghLogFile );
}
#endif // _DEBUG


/* ===============  DLL Specific  Functions  ===================  */
//////////////////////////////////////////////////////////////////
#if defined(__cplusplus)
extern "C"
#endif
BOOL WINAPI DllMain( HINSTANCE  hinstDLL, DWORD fdwReason, LPVOID  lpvReserved )
{
    BOOL    fResult = TRUE;
    DWORD	dwSidBuferSize = MAX_SID_SIZE;

    // Fetch the OS version number...
    ZeroMemory( &gsOSVerInfo, sizeof( gsOSVerInfo ) );
    gsOSVerInfo.dwOSVersionInfoSize = sizeof( OSVERSIONINFO );
    GetVersionEx( &gsOSVerInfo );
    
    switch( fdwReason )
    {
        case DLL_PROCESS_ATTACH:

            ghDLL = hinstDLL;
            CountConstants();

#ifdef ENABLE_CALLBACKS            
            gfCallbackMode = FALSE;
//            gpPerlObject = NULL;
            gpHvContext = NULL;
#endif // ENABLE_CALLBACKS            
  
            gdwLastError = 0;
            gdwServiceErrorState = NO_ERROR;
            ghService = 0;
            ghServiceThread = 0;
            gServiceThreadId = 0;
			gServiceMainThreadID = 0;

#ifdef ENABLE_CALLBACKS
			//
			//	Setup the callback timer
			//
			gCallbackTimer.SetMessageID( CALLBACK_TIMER_ID );
			gCallbackTimer = DEFAULT_CALLBACK_TIMER;
#endif	// ENABLE_CALLBACKS			

			gMainThreadId = GetCurrentThreadId();
			gdwLastControlMessage = SERVICE_CONTROL_NONE;
			gdwTimeoutState = SERVICE_START_PENDING;
			
			gdwControlsAccepted = 0;
			switch( gsOSVerInfo.dwMajorVersion )
			{
				case 6:
					// We have Windows Vista
					//  The following constants only work on Vista and higher:
					//      SERVICE_ACCEPT_PRESHUTDOWN
					//
#ifdef SERVICE_CONTROL_PRESHUTDOWN 					
					gdwControlsAccepted |= SERVICE_ACCEPT_PRESHUTDOWN;
#endif	// SERVICE_CONTROL_PRESHUTDOWN 			

				case 5:
					// We have Windows 2000 or XP
					//  The following constants only work on Win2k and higher:
					//      SERVICE_ACCEPT_PARAMCHANGE
					//      SERVICE_ACCEPT_NETBINDCHANGE
					//
					gdwControlsAccepted |= SERVICE_ACCEPT_PARAMCHANGE  
										   | SERVICE_ACCEPT_NETBINDCHANGE;
										
            	case 4:
				case 3:
				case 2:
				case 1:
				case 0:
					// NT 4.0
					gdwControlsAccepted |= SERVICE_ACCEPT_STOP 
										  | SERVICE_ACCEPT_PAUSE_CONTINUE
										  | SERVICE_ACCEPT_SHUTDOWN;

			}
			gdwServiceType = SERVICE_WIN32_OWN_PROCESS 
                             | SERVICE_INTERACTIVE_PROCESS;
            gdwServiceBits = 0;
            gdwLastError = 0;
            gpSid = NULL;


            // Set the state to 0. This way we know when the service thread actually
            // starts because it will set the state to SERVICE_START_PENDING
            gdwState = 0;
            ZeroMemory( &gServiceStatus, sizeof( gServiceStatus ) );

            if( ! GetModuleFileName( ghDLL, gszModulePath, sizeof( gszModulePath ) ) )
            {
                _tcscpy( gszModulePath, TEXT( "" ) );
            }

#ifdef _DEBUG
            // Init a critical section for debug output. This way multiple threads
            // won't overrun the output code.
            ZeroMemory( &gcsDebugOutput, sizeof( gcsDebugOutput ) );
            InitializeCriticalSection( &gcsDebugOutput );
            
            // Clear out the log file path but DONT create the log. Leave that
            // to the Perl script.
            ZeroMemory( gszDebugOutputPath, sizeof( gszDebugOutputPath ) );

#endif // _DEBUG

            if( NULL != ( gpSid = (SID*) new BYTE [ dwSidBuferSize ] ) )
            {
                // Here we need to get the SID of the user account
                // we are running under
                ZeroMemory( gpSid, dwSidBuferSize );
                if( FALSE != GetProcessSid( GetCurrentProcess(), gpSid, dwSidBuferSize ) )
                {
                    gWindowStation.SetSid( gpSid );
                    LoadProfile( gpSid );
                }
            }
            break;

        case DLL_THREAD_ATTACH:
            giThread++;
            break;

        case DLL_THREAD_DETACH:
            giThread--;
            break;

        case DLL_PROCESS_DETACH:
#ifdef _DEBUG
            DeleteCriticalSection( &gcsDebugOutput );
            if( ghLogFile )
            {
                CloseHandle( ghLogFile );
            }
#endif // _DEBUG
            break;

        default:
            break;
    }
    return ( fResult );
}

/*----------------------- P E R L   F U N C T I O N S -------------------*/
//////////////////////////////////////////////////////////////////

MODULE = Win32::Daemon  PACKAGE = Win32::Daemon

PROTOTYPES: DISABLE

# INCLUDE: \include\XS_RothMacros.xsh

int
Constant( pszName, pSvBuffer )
    LPTSTR	pszName
    SV*		pSvBuffer

	PREINIT:
	eConstantType eResult;
	LPVOID	pBuffer = NULL;

	CODE:
		eResult = Constant( pszName, &pBuffer );
		switch( eResult )
		{
			case String:
				sv_setpv( pSvBuffer, (LPTSTR) pBuffer );
				break;

			case Numeric:
				sv_setiv( pSvBuffer, (IV) pBuffer );
				break;
		}

		//  Return the result type.
		RETVAL = eResult;
	
	OUTPUT:
		RETVAL
		pSvBuffer

int
RegisterCallbacks( pSv )
	SV*	pSv

	CODE:
	{
		//////////////////////////////////////////////////////////////////
		//  This Perl routine must pass in either a code reference or a
		//  hash reference with callback code references for each event. 
		//
		RETVAL = TRUE;
#ifndef ENABLE_CALLBACKS
	croak( "RegisterCallbacks() is not supported in this build. Define the ENABLE_CALLBACKS macro and recompile\n" );
#else
		if( 1 != items )
		{
			croak( "Usage: " EXTENSION "::RegisterCallbacks( $SubRef | $HashRef )\n" );			
		}
		
		//
		// If we have a reference then de-ref it
		//
		if( SvROK( pSv ) )
		{
			pSv = SvRV( pSv );
		}

		// Check for a subroutine reference
		if( SVt_PVCV == SvTYPE( pSv ) )
		{
			//
			// Passed in a subroutine reference so go ahead and set this routine
			// as the *default* routine for all callbacks
			//
			SET_CALLBACK( CALLBACK_TIMER,          pSv );
			SET_CALLBACK( CALLBACK_START,          pSv );

			SET_CALLBACK( CALLBACK_STOP,           pSv );
			SET_CALLBACK( CALLBACK_PAUSE,          pSv );
			SET_CALLBACK( CALLBACK_CONTINUE,       pSv );
			SET_CALLBACK( CALLBACK_INTERROGATE,    pSv );
			SET_CALLBACK( CALLBACK_SHUTDOWN,       pSv );
			SET_CALLBACK( CALLBACK_PARAMCHANGE,    pSv );
			SET_CALLBACK( CALLBACK_NETBINDADD,     pSv );
			SET_CALLBACK( CALLBACK_NETBINDREMOVE,  pSv );
			SET_CALLBACK( CALLBACK_NETBINDENABLE,  pSv );
			SET_CALLBACK( CALLBACK_NETBINDDISABLE, pSv );
			SET_CALLBACK( CALLBACK_DEVICEEVENT,    pSv );
			SET_CALLBACK( CALLBACK_HARDWAREPROFILECHANGE,    pSv );
			SET_CALLBACK( CALLBACK_POWEREVENT,     pSv );
			SET_CALLBACK( CALLBACK_SESSIONCHANGE,  pSv );
#ifdef SERVICE_CONTROL_PRESHUTDOWN			
			SET_CALLBACK( CALLBACK_PRESHUTDOWN,    pSv );
#endif // SERVICE_CONTROL_PRESHUTDOWN			

			SET_CALLBACK( CALLBACK_USER_DEFINED,   pSv );
			
			//
			//	No longer supporting CALLBACK_RUNNING. It has been replaced by
			//	CALLBACK_TIMER. 
				SET_CALLBACK( CALLBACK_RUNNING,        pSv );
	        
		}
		else if( SVt_PVHV == SvTYPE( pSv ) )
		{
			HV* pHv = (HV*) pSv;
			//
			// We have a hash reference so set each callback routine to the appropriate
			// hash key's callback subroutine...
			//

			//
			//	CALLBACK_RUNNING has been superceeded by CALLBACK_TIMER.
			//	Scripts should only use "timer" instead of "running". However to support
			//	legacy scripts:
			//		1) If running is set then running will be supported
			//		2) If timer is set then the timer callback will occur
			//		3) if both are set then only "running" will occur (this mitigates the
			//		   problem of calling RegisterCallback() with only one callback routine.
			//
			//	*** #3 needs to be reconsidered: We should only use "timer" and encourage 
			//		authors to do the right thing.
			//
			SET_CALLBACK( CALLBACK_RUNNING,		   HASH_GET_SV( pHv, CALLBACK_NAME_RUNNING ) );
			
			SET_CALLBACK( CALLBACK_TIMER,          HASH_GET_SV( pHv, CALLBACK_NAME_TIMER ) );
			SET_CALLBACK( CALLBACK_START,          HASH_GET_SV( pHv, CALLBACK_NAME_START ) );
			SET_CALLBACK( CALLBACK_STOP,           HASH_GET_SV( pHv, CALLBACK_NAME_STOP ) );
			SET_CALLBACK( CALLBACK_PAUSE,          HASH_GET_SV( pHv, CALLBACK_NAME_PAUSE ) );
			SET_CALLBACK( CALLBACK_CONTINUE,       HASH_GET_SV( pHv, CALLBACK_NAME_CONTINUE ) );
			SET_CALLBACK( CALLBACK_INTERROGATE,    HASH_GET_SV( pHv, CALLBACK_NAME_INTERROGATE ) );
			SET_CALLBACK( CALLBACK_SHUTDOWN,       HASH_GET_SV( pHv, CALLBACK_NAME_SHUTDOWN ) );
			SET_CALLBACK( CALLBACK_PARAMCHANGE,    HASH_GET_SV( pHv, CALLBACK_NAME_PARAMCHANGE ) );
			SET_CALLBACK( CALLBACK_NETBINDADD,     HASH_GET_SV( pHv, CALLBACK_NAME_NETBINDADD ) );
			SET_CALLBACK( CALLBACK_NETBINDREMOVE,  HASH_GET_SV( pHv, CALLBACK_NAME_NETBINDREMOVE ) );
			SET_CALLBACK( CALLBACK_NETBINDENABLE,  HASH_GET_SV( pHv, CALLBACK_NAME_NETBINDENABLE ) );
			SET_CALLBACK( CALLBACK_NETBINDDISABLE, HASH_GET_SV( pHv, CALLBACK_NAME_NETBINDDISABLE ) );
			SET_CALLBACK( CALLBACK_DEVICEEVENT,    HASH_GET_SV( pHv, CALLBACK_NAME_DEVICEEVENT ) );
			SET_CALLBACK( CALLBACK_HARDWAREPROFILECHANGE,    HASH_GET_SV( pHv, CALLBACK_NAME_HARDWAREPROFILECHANGE ) );
			SET_CALLBACK( CALLBACK_POWEREVENT,     HASH_GET_SV( pHv, CALLBACK_NAME_POWEREVENT ) );
			SET_CALLBACK( CALLBACK_SESSIONCHANGE,  HASH_GET_SV( pHv, CALLBACK_NAME_SESSIONCHANGE ) );
#ifdef SERVICE_CONTROL_PRESHUTDOWN			
			SET_CALLBACK( CALLBACK_PRESHUTDOWN,    HASH_GET_SV( pHv, CALLBACK_NAME_PRESHUTDOWN ) );
#endif // SERVICE_CONTROL_PRESHUTDOWN

			SET_CALLBACK( CALLBACK_USER_DEFINED,   HASH_GET_SV( pHv, CALLBACK_NAME_USER_DEFINED ) );

			

		}
		else
		{
			// Fail
			RETVAL = FALSE;
		}
#endif // ENABLE_CALLBACKS
	}

	OUTPUT:
		RETVAL


UV
StartService( ... )

	PREINIT:
		UINT uintCallbackTimerValue = DEFAULT_CALLBACK_TIMER;

	CODE:
	{
		if( 2 < items )
		{
			croak( "Usage: " EXTENSION "::StartService( [ \\%Context [, $CallbackTimer] ] )\n" );
		}

		//    BeginServiceThread()
		ALERT( "Daemon::StartService: About to start the service thread..." );

		if( 0 == ghServiceThread )
		{
			//
			// Call a Win32 User level function to create a thread based message queue
			// This is needed since there are no other windows already created therefore
			// no message queue already exists.
			// NOTE that we are doing this BEFORE we create the service thread. This is so
			// that we can catch any message posted by the service thread even before we
			// are ready to handle them.
			//
			GetDesktopWindow();
			GetWindow( NULL, GW_HWNDFIRST );

			//
			//	Create a service thread which will result in the SCM creating yet another
			//	thread which ServiceMain() will run on.
			//
			ghServiceThread = CreateThread( NULL, 0, ServiceThread, 0, 0, &gServiceThreadId );

			ALERT( "Daemon::StartService: Thread has been created (falling back to perl)." );
#ifdef ENABLE_CALLBACKS
			//
			// If a context hash was passed in then store it for callback use
			//
			if( items )
			{
				if( 1 < items )
				{
					// Get the callback timer value...
                                        uintCallbackTimerValue = (int)SvIV( ST( 1 ) );
				}

				SV *pSv = ST( 0 );

				//
				// Do we have a reference?
				//
				if( SvROK( pSv ) )
				{
					// 
					// Yep. Let's dereference the reference....
					pSv = SvRV( pSv );
				}

				//
				// Now, do we have a hash? If so then store it.
				//
				if( SVt_PVHV == SvTYPE( pSv ) )
				{
					gpHvContext = (HV*) pSv;
				}
			}

			// If we have provided callbacks then enter a message loop calling the callbacks
			// whenever we receive a message to do so...
			if( 0 < gCallback.GetCount() )
			{
				//
				// Start the thread based message loop. Notice that we are relying on 
				// a *thread* message loop and now a window message loop. Any posting must
				// be made to the thread using PostThreadMessage() function.
				//
				MSG msg;
				BOOL fRet = FALSE;

				//
				// Store the main perl object into a global so that we can access it
				// when we need to callback...
				//
   				//	UPDATE: We no longer are using gpPerlObject. Instead reference the
				//	aTHX macro.
				//	gpPerlObject = aTHX;

	    		
				//
				// Set the global flag indicating that we are now in callback mode...
				//
				gfCallbackMode = TRUE;

				ALERT( "ENTERING the callback thread message loop." );
	            
				//
				//	Update the callback timer value.
				//
				gCallbackTimer = uintCallbackTimerValue;
				
				//
				//	If we have set the callback timer to a valid time
				//	then we need to start it. Don't worry about checking
				//	for it's current state. The CCallbackTimer class manages
				//	all of that.
				//
				gCallbackTimer.Start();
				

				while( FALSE != gfCallbackMode && ( 0 != ( fRet = GetMessage( &msg, NULL, 0, 0 ) ) ) )
				{ 
					if( -1 == fRet )
					{
						ALERT( "Callback Thread Message Loop: GetMessage() returned -1. Aborting..." );
						// handle the error and possibly exit
						break;
					}
					else
					{
						TranslateMessage( &msg ); 
						//
						// No DispatchMessage() here since we are only dealing with
						// thread messages
						//
						// DispatchMessage( &msg ); 
						DispatchThreadMessage( &msg );
					}
				}
				
				//
				//	We are leaving the callback routine so stop any of the 
				//	timer based callbacks.
				//
				gCallbackTimer.Stop(); 

			}
#endif // ENABLE_CALLBACKS
		}

		RETVAL = PTR2UV(ghServiceThread);
	}
	
	OUTPUT:
		RETVAL


int
CallbackTimer( ... )

	CODE:
	{
		if( 1 < items )
		{
			croak( "Usage: " EXTENSION "::CallbackTimer( [ $CallbackTimer ] )\n" );
		}

		if( items )
		{
			//
			//	Set the callback timer
			//
                        gCallbackTimer = (int)SvIV( ST( 0 ) );
			
			//
			//	If we were already stopped then we need to manually start
			//	the timer now that it has been reset with a new value.
			//	If the timer value has been set with 0 then it has already
			//	stopped and trying to start again will do nothing.
			//
			gCallbackTimer.Start();
		}

		//
		//	Return the callback timer value
		//
		RETVAL = (int) gCallbackTimer.GetTimerValue();
	}

	OUTPUT:
		RETVAL

int
StopService()	

	PREINIT:
		DWORD dwTermStatus;
		BOOL fResult = FALSE;
	
	CODE:
	{
		DWORD dwPostCount = 5;
		while( 0 < dwPostCount-- && PostThreadMessage( gServiceMainThreadID, WM_QUIT, 0, 0 ) )
		{
			//
			//	Oops. Do NOT use "sleep(xxx)" instead of Win32's "Sleep(xxx)". The
			//	case sensitive "S" will call the wrong sleep() function; where the
			//	time is not in milliseconds but in seconds!!!
			//
			Sleep( 100 );
		}

		if( FALSE != GetExitCodeThread( ghServiceThread, &dwTermStatus ) )
		{
			if( STILL_ACTIVE == dwTermStatus )
			{
				UpdateServiceStatus( SERVICE_STOP_PENDING );
				Sleep( 1000 );
				GetExitCodeThread( ghServiceThread, &dwTermStatus );
				if( STILL_ACTIVE == dwTermStatus )
				{
					TerminateThread( ghServiceThread, 0 );
				}
			}
			UpdateServiceStatus( SERVICE_STOPPED );
			fResult = TRUE;
		}

		//
		// If we were in callback mode then unset the mode...
		//
		gfCallbackMode = FALSE;

		RETVAL = (int) fResult;
	}

	OUTPUT:
		RETVAL


LPTSTR
GetVersion()

	CODE:
	{
		RETVAL = (LPTSTR) VERSION_STRING;
	}

	OUTPUT:
		RETVAL


int
CreateService( pSvServiceInfo )
	SV*	pSvServiceInfo

	PREINIT:
		HV	*pHv = NULL;
		BOOL fResult = FALSE;

	CODE:
	{
		//////////////////////////////////////////////////////////////////
		//  NOTE: dwServiceType does not include the SERVICE_INTERACTIVE_PROCESS 
		//        flag since this will prevent a assigning a userid other than
		//        LocalSystem.
		if( 1 != items )
		{
			croak( "Usage: " EXTENSION "::CreateService( \\%ServiceInfo )\n" );
		}

		if( NULL != ( pHv = EXTRACT_HV( pSvServiceInfo ) ) )
		{
			TCHAR szBuffer[ MAX_PATH * 2 ];
			TCHAR szBinaryPath[ MAX_PATH ];     
			TCHAR szDependencies[ MAX_SERVICE_DEPENDENCY_BUFFER_SIZE ]; 
			const char *pszDepend =      szDependencies;
			const char *pszMachine =     HASH_GET_PV( pHv, KEYWORD_SERVICE_MACHINE );
			const char *pszServiceName = HASH_GET_PV( pHv, KEYWORD_SERVICE_NAME );
			const char *pszDisplayName = HASH_GET_PV( pHv, KEYWORD_SERVICE_DISPLAY_NAME );
			const char *pszUser =        HASH_GET_PV( pHv, KEYWORD_SERVICE_ACCOUNT_UID );
			const char *pszPwd =         HASH_GET_PV( pHv, KEYWORD_SERVICE_ACCOUNT_PWD );
			const char *pszBinaryPath =  HASH_GET_PV( pHv, KEYWORD_SERVICE_BINARY_PATH );
			const char *pszParameters =  HASH_GET_PV( pHv, KEYWORD_SERVICE_PARAMETERS );
			const char *pszDescription = HASH_GET_PV( pHv, KEYWORD_SERVICE_DESCRIPTION );
			const char *pszLoadOrder = NULL;
			DWORD  dwTag = 0;
			DWORD dwAccess = SERVICE_ALL_ACCESS;
			DWORD dwServiceType = SERVICE_WIN32_OWN_PROCESS;
			DWORD dwStartType = SERVICE_AUTO_START;
			DWORD dwErrorControl = SERVICE_ERROR_IGNORE;

			ZeroMemory( szDependencies, sizeof( szDependencies ) );
			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_DEPENDENCIES ) )
			{
				AV *pAv = NULL;
				if( NULL != ( pAv = HASH_GET_AV( pHv, KEYWORD_SERVICE_DEPENDENCIES ) ) )
				{
					LPTSTR pszBuffer = szDependencies;
					// av_len() returns -1 if no entries. Otherwise it returns the 
					// largest index number in the array.
					DWORD dwCount = av_len( pAv ) + 1;
					for( DWORD dwIndex = 0; dwIndex < dwCount; dwIndex++ )
					{
						_tcscpy( pszBuffer, ARRAY_GET_PV( pAv, dwIndex ) );
						pszBuffer = &szDependencies[ _tcslen( pszBuffer ) + 1 ];
					}
					// Add the final terminating null (string must be double null terminated)
					pszBuffer[0] = '\0';
				}
			}

			//  Only pad the pszBinaryPath with double quotes IF there are none already AND
			//  there are spaces in the path
			if( ( _tcschr( pszBinaryPath, ' ' ) && ( 0 != _tcsncmp( pszBinaryPath, TEXT( "\"" ), 1 ) ) ) )
			{
				_tcscpy( szBinaryPath, TEXT( "\"" ) );
				_tcscat( szBinaryPath, pszBinaryPath );
				_tcscat( szBinaryPath, TEXT( "\"" ) );
				pszBinaryPath = szBinaryPath;
			}

			//  Parameters are attached to the end of the binary path
			if( 0 != _tcscmp( TEXT( "" ), pszParameters ) )
			{
				_tcscpy( szBuffer, pszBinaryPath );
				_tcscat( szBuffer, TEXT( " " ) );
				_tcscat( szBuffer, pszParameters );
				pszBinaryPath = szBuffer;
			}

			if( ( 0 == _tcscmp( TEXT( "" ), pszUser ) )
				|| ( 0 == _tcsicmp( TEXT( "localsystem" ), pszUser ) ) )
			{
				pszUser = NULL;
				pszPwd = NULL;
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_TYPE ) )
			{
                                dwServiceType = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_TYPE );
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_START_TYPE ) )
			{
                                dwStartType = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_START_TYPE );
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_ERROR_CONTROL ) )
			{
                                dwErrorControl = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_ERROR_CONTROL );
			}

			OPEN_SERVICE_CONTROL_MANAGER( pszMachine )
				SC_HANDLE hService = CreateService( hSc,
													pszServiceName,
													pszDisplayName,
													dwAccess,
													dwServiceType,
													dwStartType,
													dwErrorControl,
													pszBinaryPath,
													pszLoadOrder,
													NULL,
													pszDepend,
													pszUser,
													pszPwd );
				if( NULL != hService )
				{
					fResult = TRUE;
					StoreServiceDescription( pszMachine, pszServiceName, pszDescription );
					CloseServiceHandle( hService );
				}
				else
				{
					gdwLastError = GetLastError();
				}
			CLOSE_SERVICE_CONTROL_MANAGER
		}

		RETVAL = ( 0 != fResult );
	}

	OUTPUT:
		RETVAL


int
DeleteService( ... )

	PREINIT:
		HV *pHv = NULL;
		BOOL fResult = FALSE;
		const char *pszServiceName = NULL;
		const char *pszMachine = TEXT( "" );
		DWORD dwIndex = 0;

	CODE:
	{
		if( ( 1 > items ) || ( 2 < items ) )
		{
			croak( "Usage: " EXTENSION "::DeleteService( [$Machine,] $ServiceName )\n" );
		}

		if( 2 == items )
		{
			pszMachine = SvPV_nolen( ST( dwIndex ) );
			dwIndex++;
		}

		if( NULL != ( pszServiceName = SvPV_nolen( ST( dwIndex ) ) ) )
		{
	        
			OPEN_SERVICE_CONTROL_MANAGER( pszMachine )
				SC_HANDLE hService = OpenService( hSc,
													pszServiceName,
													DELETE );
				if( NULL != hService )
				{
					if( FALSE == ( fResult = DeleteService( hService ) ) )
					{
						gdwLastError = GetLastError();    
					}
					CloseServiceHandle( hService );
				}
				else
				{
					gdwLastError = GetLastError();
				}
			CLOSE_SERVICE_CONTROL_MANAGER
		}
		RETVAL = ( 0 != fResult );
	}

	OUTPUT:
		RETVAL


int
ConfigureService( pSvServiceInfo )
	SV	*pSvServiceInfo

	PREINIT:
		HV *pHv = NULL;
		BOOL fResult = FALSE;

	CODE:
	{
		if( 1 != items )
		{
			croak( "Usage: " EXTENSION "::ConfigureService( \\%ServiceInfo )\n" );
		}

		if( NULL != ( pHv = EXTRACT_HV( pSvServiceInfo ) ) )
		{
			TCHAR szBuffer[ MAX_PATH * 2 ];
			TCHAR szBinaryPath[ MAX_PATH ];
			TCHAR szDependencies[ MAX_SERVICE_DEPENDENCY_BUFFER_SIZE ];
			const char *pszMachine = HASH_GET_PV( pHv, KEYWORD_SERVICE_MACHINE );
			const char *pszServiceName = NULL;
			const char *pszDisplayName = NULL;
			const char *pszUser =        NULL;
			const char *pszPwd =         NULL;
			const char *pszBinaryPath =  NULL;
			const char *pszParameters =  NULL;
			const char *pszLoadOrder =   NULL;
			const char *pszDepend =      NULL;
			const char *pszDescription = NULL;
			DWORD  dwTagId =        0;
			DWORD  *pdwTagId =      NULL;
			DWORD dwAccess =        SERVICE_ALL_ACCESS;
			DWORD dwServiceType =   SERVICE_NO_CHANGE;
			DWORD dwStartType =     SERVICE_NO_CHANGE;
			DWORD dwErrorControl =  SERVICE_NO_CHANGE;

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_NAME ) )
			{
				pszServiceName = HASH_GET_PV( pHv, KEYWORD_SERVICE_NAME );

			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_DISPLAY_NAME ) )
			{
				pszDisplayName = HASH_GET_PV( pHv, KEYWORD_SERVICE_DISPLAY_NAME );

			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_ACCOUNT_UID ) )
			{
				pszUser = HASH_GET_PV( pHv, KEYWORD_SERVICE_ACCOUNT_UID );

			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_ACCOUNT_PWD ) )
			{
				pszPwd = HASH_GET_PV( pHv, KEYWORD_SERVICE_ACCOUNT_PWD );

			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_DEPENDENCIES ) )
			{
				pszDepend = HASH_GET_PV( pHv, KEYWORD_SERVICE_DEPENDENCIES );
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_DESCRIPTION ) )
			{
				pszDescription = HASH_GET_PV( pHv, KEYWORD_SERVICE_DESCRIPTION );
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_BINARY_PATH ) )
			{
				pszBinaryPath = HASH_GET_PV( pHv, KEYWORD_SERVICE_BINARY_PATH );
				if( ( _tcschr( pszBinaryPath, ' ' ) && ( 0 != _tcsncmp( pszBinaryPath, TEXT( "\\" ), 1 ) ) ) )
				{
					_tcscpy( szBinaryPath, "\"" );
					_tcscat( szBinaryPath, pszBinaryPath );
					_tcscat( szBinaryPath, "\"" );
					pszBinaryPath = szBinaryPath;
				}
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_PARAMETERS ) )
			{
				//  Add 2 for double quote marks...
				//  TCHAR szPathBuffer[ MAX_PATH + 2 ];

				// TODO:
				// We should query the real path if pszBinaryPath == NULL!!!
				if( NULL != pszBinaryPath )
/*
				// If NULL == pszBinaryPath then we should go out and get the binary path
				// and strip out any padding " chars
				{
					// Go and find the binary path...
					GetBinaryPath( pszMachine, pszServiceName, szPathBuffer, sizeof( szPathBuffer ) );
					pszBinaryPath = szPathBuffer;
				}
*/
				pszParameters = HASH_GET_PV( pHv, KEYWORD_SERVICE_PARAMETERS );

				//  Parameters are attached to the end of the binary path
				if( 0 != _tcscmp( TEXT( "" ), pszParameters ) )
				{
					_tcscpy( szBuffer, pszBinaryPath );
					_tcscat( szBuffer, TEXT( " " ) );
					_tcscat( szBuffer, pszParameters );
					pszBinaryPath = szBuffer;
				}
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_DEPENDENCIES ) )
			{
				AV *pAv = NULL;
				if( NULL != ( pAv = HASH_GET_AV( pHv, KEYWORD_SERVICE_DEPENDENCIES ) ) )
				{
					LPTSTR pszBuffer = szDependencies;
					pszDepend = szDependencies;
					// av_len() returns -1 if no entries. Otherwise it returns the 
					// largest index number in the array.
					DWORD dwCount = av_len( pAv ) + 1;
					for( DWORD dwIndex = 0; dwIndex < dwCount; dwIndex++ )
					{
						_tcscpy( pszBuffer, ARRAY_GET_PV( pAv, dwIndex ) );
						pszBuffer = &szDependencies[ _tcslen( pszBuffer ) + 1 ];
					}
					// Add the final terminating null (string must be double null terminated)
					pszBuffer[0] = '\0';
				}
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_TAG_ID ) )
			{
                                dwTagId = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_TAG_ID );
				pdwTagId = &dwTagId;
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_TYPE ) )
			{
                                dwServiceType = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_TYPE );
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_START_TYPE ) )
			{
                                dwStartType = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_START_TYPE );
			}

			if( HASH_KEY_EXISTS( pHv, KEYWORD_SERVICE_ERROR_CONTROL ) )
			{
                                dwErrorControl = (DWORD)HASH_GET_IV( pHv, KEYWORD_SERVICE_ERROR_CONTROL );
			}

			OPEN_SERVICE_CONTROL_MANAGER( pszMachine )
				SC_HANDLE hService = OpenService( hSc, pszServiceName, SERVICE_CHANGE_CONFIG );
				if( NULL != hService )
				{
					fResult = ChangeServiceConfig(  hService,
													dwServiceType,
													dwStartType,
													dwErrorControl,
													pszBinaryPath,
													pszLoadOrder,
													pdwTagId,
													pszDepend,
													pszUser,
													pszPwd,
													pszDisplayName );
					if( ( TRUE == fResult ) && ( NULL != pszDescription ) )
					{
						StoreServiceDescription( pszMachine, pszServiceName, pszDescription );
					}
	                
					if( FALSE == fResult )
					{
						gdwLastError = GetLastError();
					}
					CloseServiceHandle( hService );
				}
				else
				{
					gdwLastError = GetLastError();
				}
			CLOSE_SERVICE_CONTROL_MANAGER
		}
		RETVAL = ( 0 != fResult );
	}

	OUTPUT:
		RETVAL


int
QueryServiceConfig( pSvServiceInfo )
	SV *pSvServiceInfo

	PREINIT:
		HV *pHv = NULL;
		BOOL fResult = FALSE;

	CODE:
	{
		//////////////////////////////////////////////////////////////////
		//  Note:  This returns the service configuration for the *next*
		//         time that the service will run. lIf you modify the
		//         configuration while the service is still running then
		//         a call to this function will not return the current
		//         configuration but the configuration that will be
		//         used next time the service is run.    
		if( 1 != items )
		{
			croak( "Usage: " EXTENSION "::QueryServiceConfig( \\%ServiceInfo )\n" );
		}

		if( NULL != ( pHv = EXTRACT_HV( pSvServiceInfo) ) )
		{
			TCHAR szServiceName[ 256 ];
			TCHAR szMachineName[ 256 ];
			const char *pszServiceName = HASH_GET_PV( pHv, KEYWORD_SERVICE_NAME );
			const char *pszMachineName = HASH_GET_PV( pHv, KEYWORD_SERVICE_MACHINE );

			// Copy the service name to a local buffer so we can clear out the
			// hash...
			// The HASH_GET_PV() macro never returns NULL, instead it returns ""
			_tcscpy( szServiceName, pszServiceName );
			pszServiceName = szServiceName;

			// Copy the machine name to a local buffer so we can clear out the
			// hash...
			// ...if no machine key was specified HASH_GET_PV() will return "" 
			// (not a NULL). Later we will call OpenSCManager() passing in this value
			// which is interpretted as the local machine.
			_tcscpy( szMachineName, pszMachineName );
			pszMachineName = szMachineName;

			hv_clear( pHv );

			OPEN_SERVICE_CONTROL_MANAGER_READ( pszMachineName )
				SC_HANDLE hService = OpenService( hSc, pszServiceName, SERVICE_QUERY_CONFIG );
				if( NULL != hService )
				{
					DWORD dwBufferSize = 0;
					fResult = QueryServiceConfig( hService, NULL, 0, &dwBufferSize );
					if( ERROR_INSUFFICIENT_BUFFER == GetLastError() )
					{
						LPQUERY_SERVICE_CONFIG pServiceConfig = NULL;
						pServiceConfig = (LPQUERY_SERVICE_CONFIG) new BYTE [ dwBufferSize ];
						if( NULL != pServiceConfig )
						{
							ZeroMemory( pServiceConfig, dwBufferSize );
							fResult = QueryServiceConfig( hService, pServiceConfig, dwBufferSize, &dwBufferSize );
							if( FALSE != fResult )
							{
								AV *pAv = newAV();

								HASH_STORE_IV( pHv, KEYWORD_SERVICE_TYPE, pServiceConfig->dwServiceType );
								HASH_STORE_IV( pHv, KEYWORD_SERVICE_START_TYPE, pServiceConfig->dwStartType );
								HASH_STORE_IV( pHv, KEYWORD_SERVICE_ERROR_CONTROL, pServiceConfig->dwErrorControl );
								HASH_STORE_PV( pHv, KEYWORD_SERVICE_BINARY_PATH, pServiceConfig->lpBinaryPathName );
								HASH_STORE_PV( pHv, KEYWORD_SERVICE_LOAD_ORDER, pServiceConfig->lpLoadOrderGroup );
								HASH_STORE_PV( pHv, KEYWORD_SERVICE_DISPLAY_NAME, pServiceConfig->lpDisplayName );
								HASH_STORE_PV( pHv, KEYWORD_SERVICE_ACCOUNT_UID, pServiceConfig->lpServiceStartName );
								HASH_STORE_PV( pHv, KEYWORD_SERVICE_NAME, pszServiceName );
								HASH_STORE_PV( pHv, KEYWORD_SERVICE_MACHINE, pszMachineName );

								if( NULL != pAv )
								{
									LPTSTR pszBuffer = pServiceConfig->lpDependencies;

									while( '\0' != pszBuffer[0] )
									{
										ARRAY_PUSH_PV( pAv, pszBuffer );
										pszBuffer = &pszBuffer[ _tcslen( pszBuffer ) + 1 ];
									}
									HASH_STORE_AV( pHv, KEYWORD_SERVICE_DEPENDENCIES, pAv );
								}

								// Get the service Description...
								{
									HKEY hRoot = HKEY_LOCAL_MACHINE;
									HKEY hKey = NULL;
									BOOL fFlag = TRUE;
	            
									if( 0 != _tcscmp( TEXT( "" ), pszMachineName ) )
									{
										fFlag = ( ERROR_SUCCESS == RegConnectRegistry( pszMachineName, HKEY_LOCAL_MACHINE, &hRoot ) );
									}

									if( TRUE == fFlag )
									{
										TCHAR szBuffer[ 75 ];
										_stprintf( szBuffer, REGISTRY_SERVICE_PATH TEXT( "\\%s" ), pszServiceName );
										if( ERROR_SUCCESS == RegOpenKeyEx( hRoot, szBuffer, 0, KEY_QUERY_VALUE, &hKey ) )
										{
											TCHAR szDescription[ 1024 ];
											DWORD dwType, dwSize;
											if( ( ERROR_SUCCESS == RegQueryValueEx( hKey, REGISTRY_SERVICE_KEYWORD_DESCRIPTION, 0, &dwType, (LPBYTE) szDescription, &dwSize )
												&& ( REG_SZ == dwType ) ) )
											{
												HASH_STORE_PV( pHv, KEYWORD_SERVICE_DESCRIPTION, szDescription );                    
											}
										}
										RegCloseKey( hKey );
									}
	                
									if( 0 != _tcscmp( TEXT( "" ), pszMachineName ) )
									{
										RegCloseKey( hRoot );
									}
	                    
								}

							}
							else
							{
								gdwLastError = GetLastError();
							}
							delete [] (BYTE*) pServiceConfig;
						}
					}
					else
					{
						gdwLastError = GetLastError();
					}
					CloseServiceHandle( hService );
				}
				else
				{
					gdwLastError = GetLastError();
				}
			CLOSE_SERVICE_CONTROL_MANAGER
		}
		RETVAL = ( 0 != fResult );
	}

	OUTPUT:
		RETVAL


int
SetServiceBits( dwBits = 0, ... )
	DWORD dwBits	

	PREINIT:
		BOOL fResult = FALSE;
		SERVICE_STATUS_HANDLE hService = ghService;

	CODE:
	{
		if( ( 1 > items ) || ( 2 < items ) )
		{
			croak( "Usage: SetServiceBits( $Value, [$hServiceHandle] )\n" );
		}

		if( 2 == items )
		{
			hService = (SERVICE_STATUS_HANDLE) SvIV( ST( 1 ) );
		}

		if( 0 != hService )
		{

			// SetServiceBits() for some reason will not link. The link lib
			// is AdvApi32.dll which is in the link list but alas it errors out.
			// So we need to fix this later. For now we hack...load the dll, get the
			// proc then call it.

			//  Now set our bits...
			fResult = My_SetServiceBits( (SERVICE_STATUS_HANDLE) ghService, (DWORD) dwBits,(BOOL) TRUE, (BOOL) TRUE );
		}
		else
		{
			// Set the gdwServiceBits so that when the service is formally running
			// it will set the bits.
			gdwServiceBits = dwBits;
			fResult = 1;
		}
		RETVAL = (int) fResult;
	}

	OUTPUT:
		RETVAL


DWORD
GetLastError()

	CODE:
	{
		RETVAL = gdwLastError;
	}

	OUTPUT:
		RETVAL



DWORD
State( ... )

	PREINIT:
	
	CODE:
	{
		if( 2 < items )
		{
			croak( "Usage: State( [$State [, $WaitHint ] || \\%Hash ] )\n" );
		}

		if( 0 != gdwState )
		{

			if( items )
			{
				SV *pSv = ST( 0 );
				HV *pHv = NULL;
				DWORD dwState = gdwState;
				DWORD dwWaitHint = DEFAULT_WAIT_HINT;
				DWORD dwError = NO_ERROR;

				if( NULL != ( pHv = EXTRACT_HV( pSv ) ) )
				{
					if( HASH_KEY_EXISTS( pHv, KEYWORD_STATE_STATE ) )
					{
                                                dwState     = (DWORD)HASH_GET_IV( pHv, KEYWORD_STATE_STATE );
					}
					if( HASH_KEY_EXISTS( pHv, KEYWORD_STATE_WAIT_HINT ) )
					{
                                                dwWaitHint  = (DWORD)HASH_GET_IV( pHv, KEYWORD_STATE_WAIT_HINT );
					}
					if( HASH_KEY_EXISTS( pHv, KEYWORD_STATE_ERROR ) )
					{
                                                dwError     = (DWORD)HASH_GET_IV( pHv, KEYWORD_STATE_ERROR );
					}
				}
				else
				{
                                        dwState = (DWORD)SvIV( pSv );
					if( 2 == items )
					{
						// Assume that the hint was in milliseconds
                                                dwWaitHint = (DWORD)SvIV( ST( 1 ) );
					}
				}
				
				UpdateServiceStatus( dwState, dwWaitHint, dwError );
			}
		}
		RETVAL = gdwState;
	}
	
	OUTPUT:
		RETVAL



DWORD
QueryLastMessage( ... )

	CODE:
	{
		if( 1 < items )
		{
			croak( "Usage: QueryLastMessage( [$fResetMessage] )\n" );
		}

		if( ( 1 == items ) && ( 0 != SvIV( ST( 0 ) ) ) )
		{
			gdwLastControlMessage = SERVICE_CONTROL_NONE;
		}

		RETVAL = gdwLastControlMessage;
	}

	OUTPUT:
		RETVAL



BOOL
ShowService( pszWindowStation = TEXT( "Winsta0" ), ... )
	char *pszWindowStation

	PREINIT:
		BOOL fResult;
		const char *pszDesktop = TEXT( "Default" );

	CODE:
	{
		if( 3 < items )
		{
			croak( "Usage: ShowService( $WindowStationName, [$DesktopName] )\n" );
		}

		if( 1 < items )
		{
			pszDesktop = (LPTSTR) SvPV_nolen( ST( 0 ) );
		}

		// Free your mind...and the current console. :)
		// Do it before the winstation/desktop switch otherwise if you free it later you will
		// see a brief flash of a console.
		FreeConsole();

		ALERT( "ShowService: About to call gWindowStation.Set()\n" );
		fResult = gWindowStation.Set( pszWindowStation, pszDesktop );
#ifdef _DEBUG
		TCHAR szBuffer[256];
		wsprintf( szBuffer,
				  TEXT( "ShowService: Setting window station %s\\%s resulted in %d" ),
				  pszWindowStation,
				  pszDesktop,
				  fResult );
		ALERT( szBuffer );
#endif

		// Allocate a new console for output.
		AllocConsole();

		RETVAL = (BOOL) fResult;
	}

	OUTPUT:
		RETVAL


BOOL
HideService()

	CODE:
	{
		RETVAL = (BOOL) gWindowStation.Set( TEXT( "Service-x0-3e7$" ), TEXT( "Default" ) );
	}

	OUTPUT:
		RETVAL


BOOL
RestoreService()

	CODE:	
	{
		RETVAL = (BOOL) gWindowStation.Restore();
	}

	OUTPUT:
		RETVAL



DWORD
Timeout( ... )

	CODE:
	{
		if( 1 < items )
		{
			croak( TEXT( "Usage: " EXTENSION "::Timeout( [$Timeout] )\n" ) );
		}

		if( items )
		{
                        gdwHandlerTimeout = (DWORD)SvIV( ST( 0 ) );
		}
		RETVAL = gdwHandlerTimeout;
	}

	OUTPUT:
		RETVAL



UV
GetServiceHandle()

	CODE:	
	{
		if( items )
		{
			croak( TEXT( "Usage: " EXTENSION "::GetServiceHandle()\n" ) );
		}

		RETVAL = PTR2UV(ghService);
	}

	OUTPUT:
		RETVAL



DWORD
AcceptedControls( ... )

	CODE:	
	{
		if( 1 < items )
		{
			croak( TEXT( "Usage: " EXTENSION "::AcceptedControls( [$NewControls] )\n" ) );
		}

		if( 0 < items )
		{
                        gdwControlsAccepted = (DWORD)SvIV( ST( 0 ) );
		}
		RETVAL = gdwControlsAccepted;
	}

	OUTPUT:
		RETVAL


BOOL
SetSecurity( pszMachine, pszServiceName, pSvSecurityObject )
	LPTSTR pszMachine
	LPTSTR pszServiceName
	SV	*pSvSecurityObject

	PREINIT:
		SECURITY_DESCRIPTOR *pSD = NULL;
		BOOL fResult = FALSE;

	CODE:
	{
		if( 3 < items )
		{
			croak( TEXT( "Usage: " EXTENSION "::AcceptedControls( $Machine, $ServiceName, $Win32::Perms_Object | $BinarySD )\n" ) );
		}

		if( sv_isobject( (SV*) pSvSecurityObject ) )
		{
			// Is pSD an object (blessed object)?
			LPTSTR pszObjectType = NULL;
			SV *pSvTemp = NULL;

			//  Yep, it's a reference to a blessed object...
			//  This means that pSv is actually a blessed HV*
			pSvTemp = SvRV( (SV*) pSvSecurityObject );
			pszObjectType = HvNAME( SvSTASH( pSvTemp ) );

			if( 0 == _stricmp( pszObjectType, PERL_WIN32_PERMS_EXTENSION  ) )
			{
				dSP;
				int iCount;

				//  We have a Win32::Perms object. So let's call into its GetSD() method
				//  to get a pointer to the absolute Security Descriptor...
	        
				// Save our current position on the stack
				PUSHMARK( SP );
	        
				// Push the Win32::Perms object onto the stack
				XPUSHs( (SV*) pSvSecurityObject );

				//  Go back to the previously stored stack position
				PUTBACK;
	            
				//  Remember the position on the stack so when we free temp vars only up to this point
				//  will be freed
				ENTER;
				SAVETMPS;
	        
				//  Call the method...
				iCount = perl_call_method( (char*) "GetSD", G_SCALAR );

				if( 0 < iCount )
				{
					//  Yahooo! The method returned a value; assume it is a Security Descriptor pointer
					//  so pop it off as a long
					pSD = (SECURITY_DESCRIPTOR*) POPl;
				}

				//  Free all scalars created since the ENTER/SAVETMPS combo
				FREETMPS;
				LEAVE;
			}
		}
		else
		{
			// Okay, first check if we have an absolute security descriptor...
			pSD = (SECURITY_DESCRIPTOR*) SvIV( pSvSecurityObject );
			if( ! IsValidSecurityDescriptor( pSD ) )
			{
				// Hmmm. Okay, let's try a relative security descriptor...
				pSD = (SECURITY_DESCRIPTOR*) SvPV_nolen( pSvSecurityObject );
				if( ! IsValidSecurityDescriptor( pSD ) )
				{
					// Sigh. No, we don't seem to have any security descriptor
					pSD = NULL;
				}
			}
		}
	    
		// If we have a valid Security Descriptor that use it!
		if( NULL != pSD )
		{
			BOOL fACLExists = FALSE;
			BOOL fTempBool = FALSE;
			PACL pTempACL = NULL;
			PSID pSid = NULL;
			DWORD dwFlags = 0;
			DWORD dwOpenFlags = READ_CONTROL | WRITE_DAC;

			if( NULL != pszServiceName )
			{
	        
				if( FALSE != GetSecurityDescriptorSacl( pSD, &fACLExists, &pTempACL, &fTempBool ) )
				{
					dwFlags |= SACL_SECURITY_INFORMATION;
					SetPrivilege( 0, SE_SECURITY_NAME, TRUE);
					dwOpenFlags |= ACCESS_SYSTEM_SECURITY;
				}

				fTempBool = fACLExists = FALSE;
				if( FALSE != GetSecurityDescriptorDacl( pSD, &fACLExists, &pTempACL, &fTempBool ) )
				{
					dwFlags |= DACL_SECURITY_INFORMATION;
					dwOpenFlags |= WRITE_DAC;
				}

	/*  
		//
		//  Don't try to set the owner...this only causes problems such as
		//  permission issues preventing the set from happening...
		//
				fTempBool = fACLExists = FALSE;
				if( FALSE != GetSecurityDescriptorOwner( pSD, &pSid, &fTempBool ) )
				{
					dwFlags |= OWNER_SECURITY_INFORMATION;
					dwOpenFlags |= WRITE_OWNER;
				}
	*/

				OPEN_SERVICE_CONTROL_MANAGER( pszMachine )
				SC_HANDLE hService = OpenService( hSc,
													pszServiceName,
													dwOpenFlags );
				if( NULL != hService )
				{

					// From MSDN...
					// Sets the object's system access control list (SACL). The hService handle must 
					// have ACCESS_SYSTEM_SECURITY access. The proper way to obtain this access is to 
					// enable the SE_SECURITY_NAME privilege in the caller's current access token, open 
					// the handle for ACCESS_SYSTEM_SECURITY access, and then disable the privilege.
					//
					// ...it does not mention if the owner of the service (the process itself) must
					// still do all this. But then again, there is no way to pass in such flags
					// when opening the SCM since we only register for the SCM callback. How odd.
					//

					if( FALSE != SetServiceObjectSecurity( hService, dwFlags, pSD ) )
					{
						fResult = TRUE;
					}
					else
					{
						gdwLastError = GetLastError();
					}

					if( SACL_SECURITY_INFORMATION & dwFlags )
					{
						// Try to disable the privilege since it is no longer needed.
						SetPrivilege( 0, SE_SECURITY_NAME, FALSE );
					}

					CloseServiceHandle( hService );
				}
				else
				{
					gdwLastError = GetLastError();
				}
				CLOSE_SERVICE_CONTROL_MANAGER
			}
		}

		RETVAL = fResult;
	}

	OUTPUT:
		RETVAL


void
GetSecurity( pszMachine, pszServiceName )
    LPTSTR pszMachine
	LPTSTR pszServiceName

	PREINIT:
		SV *pSv = NULL;
		SECURITY_DESCRIPTOR *pSD = NULL;
		BOOL fResult = FALSE;

	CODE:
	{
		//////////////////////////////////////////////////////////////////
		//
		//
		// TEST: p Win32::Daemon::GetSecurity( '', 'TlntSvr' )
		//
		if( 2 != items )
		{
			croak( TEXT( "Usage: " EXTENSION "::GetSecurity( $Machine, $ServiceName )\n" ) );
		}

		if( NULL != pszServiceName )
		{
	        
			// TODO:
			// We should remove this privilege at the end of this function...
			SetPrivilege( 0, SE_SECURITY_NAME, TRUE);

			OPEN_SERVICE_CONTROL_MANAGER( pszMachine )
			SC_HANDLE hService = OpenService( hSc,
												pszServiceName,
												ACCESS_SYSTEM_SECURITY | READ_CONTROL );
			if( NULL != hService )
			{
				DWORD dwBufferSize = 0;
				DWORD dwBytesNeeded = 1024;
				BOOL fContinue = TRUE;
	            
				SetPrivilege( 0, SE_SECURITY_NAME, TRUE);
	            
				do
				{
					fContinue = FALSE;
					if( NULL != pSD )
					{
						delete [] (BYTE*) pSD;
						pSD = NULL;
					}
					pSD = (SECURITY_DESCRIPTOR *) new BYTE[ dwBytesNeeded ];
					if( NULL != pSD )
					{
						dwBufferSize = dwBytesNeeded;
						ZeroMemory( pSD, dwBufferSize );
						if( FALSE == QueryServiceObjectSecurity( 
												hService, 
												DACL_SECURITY_INFORMATION | SACL_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | OWNER_SECURITY_INFORMATION, 
												pSD, 
												dwBufferSize, 
												&dwBytesNeeded ) )
						{
							DWORD dwError = GetLastError();
							if( ERROR_INSUFFICIENT_BUFFER == dwError || 0x000001e7 == dwError )
							{
								fContinue = TRUE;
							}
						}
					}
				} while( TRUE == fContinue );

				if( NULL != pSD )
				{
					pSv = newSVpv( (LPTSTR) pSD, dwBytesNeeded );
					delete [] (BYTE*) pSD;
					pSD = NULL;
				}

				CloseServiceHandle( hService );
			}
			else
			{
				gdwLastError = GetLastError();
			}
			CLOSE_SERVICE_CONTROL_MANAGER
		}

		if( NULL != pSv )
		{
			// Return the scalar...
			//		Original code was: PUSH_NOREF( pSv );
			//		...assuming that no need to make pSv mortal?
			ST(0) = pSv;
		}
		else
		{
			// Return undef
			ST(0) = &PL_sv_undef;
		}
	}

	OUTPUT:



char *
DebugOutputPath( ... )

	CODE:
	{		
		if( 1 < items )
		{
			croak( TEXT( "Usage: " EXTENSION "::DebugOutputPath( [$Path] )\n" ) );
		}
#ifdef _DEBUG
		if( items )
		{
			LPCTSTR pszDebugOutputPath = SvPV_nolen( ST( 0 ) );
			if( NULL != pszDebugOutputPath )
			{
				CreateLog( pszDebugOutputPath );
			}
		}
		
		RETVAL = (LPTSTR) gszDebugOutputPath;
#else	/* ! def _DEBUG */
		RETVAL = TEXT( "" );
#endif	/*	_DEBUG	*/
	}
	OUTPUT:
		RETVAL




DWORD
IsDebugBuild()
	
	CODE:
#ifdef _DEBUG
		RETVAL =  1;
#else
		RETVAL = 0;
#endif
 
	OUTPUT:
		RETVAL	


#	/*
#	HISTORY:
#
#		-20000618
#			-Added:
#				-ConfigureService
#				-QueryServiceConfig
#
#		-20011230 rothd@roth.net
#			- Fixed bug where service doesn't work properly with Windows NT 4. We were 
#			  defaulting by acccepting the SERVICE_ACCEPT_PARAMCHANGE and 
#			  SERVICE_ACCEPT_NETBINDCHANGE controls. However, they were introduced in 
#			  Win2k so NT 4 coughed up blood with them.
#
#		-20010224
#			-Added:
#				-RegisterCallbacks() (and callback support)
#
#		-20011205
#			-Added:
#				-AcceptedControls()
#
#		- 20020605 rothd@roth.net
#			- Added support for reporting service errors. You can now pass in a
#			  hash reference into State(). More details in the POD docs.
#
#		- 20030615 rothd@roth.net
#			- Added callback support (actually finished it!).
#			- Added security support (Set and Get SD).
#				-GetSecurity()
#				-SetSecurity()
#				-IsDebugBuild()
#				-CallbackTimer()			
#		
#		- 20061222 rothd@roth.net
#			- Converted to XS file.
#			- Fixed callback heartbeat: now properly calls back with SERVICE_RUNNING (not SERVICE_CONTROL_RUNNING)
#			- StopService() will post WM_QUIT message to the ServiceMain() thread to shut down the service thread.
#			- Calling into StopService() will auto change the state to STOPPING/STOPPED so you do not need to 
#				explicitly do so (calling State() or a callback returning STOPPING/STOPPED).
#			- Fixed bug where messages were posted to wrong thread.
#
#	*/
