//////////////////////////////////////////////////////////////////////////////
//
//  Constant.cpp
//  Win32::Daemon Perl extension constants source file
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

#ifdef __BORLANDC__
typedef wchar_t wctype_t; /* in tchar.h, but unavailable unless _UNICODE */
#endif
 
#include <windows.h>
#include <tchar.h>
#include <wtypes.h>
#include <stdio.h>      //  Gurusamy's right, Borland is brain damaged!
#include <math.h>       //  Gurusamy's right, MS is brain damaged!

#include <winspool.h>
#include <LMACCESS.H>
#include <LM.H>
#include <LMAUDIT.H>
#include <LMERR.H>
#include <LMERRLOG.H>

#include "constant.h" 

static DWORD gdwConstTotal = 0;
static ConstantStruct gsConst[] =
{
    { TEXT( "SERVICE_CONTROL_USER_DEFINED" ),   (LPVOID) (SERVICE_CONTROL_USER_DEFINED),    Numeric },

	{ TEXT( "SERVICE_NOT_READY" ),              (LPVOID) (SERVICE_NOT_READY),               Numeric },
    { TEXT( "SERVICE_STOPPED" ),                (LPVOID) (SERVICE_STOPPED),                 Numeric },
    { TEXT( "SERVICE_RUNNING" ),                (LPVOID) (SERVICE_RUNNING),                 Numeric },
    { TEXT( "SERVICE_PAUSED" ),                 (LPVOID) (SERVICE_PAUSED),                  Numeric },
    { TEXT( "SERVICE_START_PENDING" ),          (LPVOID) (SERVICE_START_PENDING),           Numeric },
    { TEXT( "SERVICE_STOP_PENDING" ),           (LPVOID) (SERVICE_STOP_PENDING),            Numeric },
    { TEXT( "SERVICE_CONTINUE_PENDING" ),       (LPVOID) (SERVICE_CONTINUE_PENDING),        Numeric },
    { TEXT( "SERVICE_PAUSE_PENDING" ),          (LPVOID) (SERVICE_PAUSE_PENDING),           Numeric },

    { TEXT( "SERVICE_CONTROL_NONE" ),			(LPVOID) (SERVICE_CONTROL_NONE),			Numeric },
    { TEXT( "SERVICE_CONTROL_STOP" ),			(LPVOID) (SERVICE_CONTROL_STOP),			Numeric },
    { TEXT( "SERVICE_CONTROL_PAUSE" ),	        (LPVOID) (SERVICE_CONTROL_PAUSE),			Numeric },
	{ TEXT( "SERVICE_CONTROL_CONTINUE" ),       (LPVOID) (SERVICE_CONTROL_CONTINUE),        Numeric },
    { TEXT( "SERVICE_CONTROL_INTERROGATE" ),    (LPVOID) (SERVICE_CONTROL_INTERROGATE),     Numeric },
    { TEXT( "SERVICE_CONTROL_SHUTDOWN" ),       (LPVOID) (SERVICE_CONTROL_SHUTDOWN),        Numeric },
    { TEXT( "SERVICE_CONTROL_PARAMCHANGE" ),    (LPVOID) (SERVICE_CONTROL_PARAMCHANGE),     Numeric },
    { TEXT( "SERVICE_CONTROL_NETBINDADD" ),     (LPVOID) (SERVICE_CONTROL_NETBINDADD),      Numeric },
    { TEXT( "SERVICE_CONTROL_NETBINDREMOVE" ),  (LPVOID) (SERVICE_CONTROL_NETBINDREMOVE),   Numeric },
    { TEXT( "SERVICE_CONTROL_NETBINDENABLE" ),  (LPVOID) (SERVICE_CONTROL_NETBINDENABLE),   Numeric },
    { TEXT( "SERVICE_CONTROL_NETBINDDISABLE" ), (LPVOID) (SERVICE_CONTROL_NETBINDDISABLE),  Numeric },
    { TEXT( "SERVICE_CONTROL_DEVICEEVENT" ),    (LPVOID) (SERVICE_CONTROL_DEVICEEVENT),     Numeric },
    { TEXT( "SERVICE_CONTROL_HARDWAREPROFILECHANGE" ), (LPVOID) (SERVICE_CONTROL_HARDWAREPROFILECHANGE), Numeric },
    { TEXT( "SERVICE_CONTROL_POWEREVENT" ),     (LPVOID) (SERVICE_CONTROL_POWEREVENT),      Numeric },
    { TEXT( "SERVICE_CONTROL_SESSIONCHANGE" ),  (LPVOID) (SERVICE_CONTROL_SESSIONCHANGE),   Numeric },
    { TEXT( "SERVICE_CONTROL_USER_DEFINED" ),   (LPVOID) (SERVICE_CONTROL_USER_DEFINED),    Numeric },
    { TEXT( "SERVICE_CONTROL_RUNNING" ),        (LPVOID) (SERVICE_CONTROL_RUNNING),         Numeric },
	{ TEXT( "SERVICE_CONTROL_TIMER" ),         	(LPVOID) (SERVICE_CONTROL_TIMER),         	Numeric },
	{ TEXT( "SERVICE_CONTROL_START" ),			(LPVOID) (SERVICE_CONTROL_START),			Numeric },

#ifdef SERVICE_CONTROL_PRESHUTDOWN
	{ TEXT( "SERVICE_CONTROL_PRESHUTDOWN"),		(LPVOID) (SERVICE_CONTROL_PRESHUTDOWN),		Numeric },
#endif

    //  Service bits available to a script
    { TEXT( "USER_SERVICE_BITS_1" ),            (LPVOID) (USER_SERVICE_BITS_1),             Numeric },
    { TEXT( "USER_SERVICE_BITS_2" ),            (LPVOID) (USER_SERVICE_BITS_2),             Numeric },
    { TEXT( "USER_SERVICE_BITS_3" ),            (LPVOID) (USER_SERVICE_BITS_3),             Numeric },
    { TEXT( "USER_SERVICE_BITS_4" ),            (LPVOID) (USER_SERVICE_BITS_4),             Numeric },
    { TEXT( "USER_SERVICE_BITS_5" ),            (LPVOID) (USER_SERVICE_BITS_5),             Numeric },
    { TEXT( "USER_SERVICE_BITS_6" ),            (LPVOID) (USER_SERVICE_BITS_6),             Numeric },
    { TEXT( "USER_SERVICE_BITS_7" ),            (LPVOID) (USER_SERVICE_BITS_7),             Numeric },
    { TEXT( "USER_SERVICE_BITS_8" ),            (LPVOID) (USER_SERVICE_BITS_8),             Numeric },
    { TEXT( "USER_SERVICE_BITS_9" ),            (LPVOID) (USER_SERVICE_BITS_9),             Numeric },
    { TEXT( "USER_SERVICE_BITS_10" ),           (LPVOID) (USER_SERVICE_BITS_10),            Numeric },

    //  Define Service Types
    { TEXT( "SERVICE_WIN32_OWN_PROCESS" ),      (LPVOID) (SERVICE_WIN32_OWN_PROCESS),       Numeric },
    { TEXT( "SERVICE_WIN32_SHARE_PROCESS" ),    (LPVOID) (SERVICE_WIN32_SHARE_PROCESS),     Numeric },
    { TEXT( "SERVICE_KERNEL_DRIVER" ),          (LPVOID) (SERVICE_KERNEL_DRIVER),           Numeric },
    { TEXT( "SERVICE_FILE_SYSTEM_DRIVER" ),     (LPVOID) (SERVICE_FILE_SYSTEM_DRIVER),      Numeric },
    { TEXT( "SERVICE_INTERACTIVE_PROCESS" ),    (LPVOID) (SERVICE_INTERACTIVE_PROCESS ),    Numeric },

	//	Define control acceptance constants
	{ TEXT( "SERVICE_ACCEPT_STOP" ),			(LPVOID) (SERVICE_ACCEPT_STOP),             Numeric },
	{ TEXT( "SERVICE_ACCEPT_PAUSE_CONTINUE" ),  (LPVOID) (SERVICE_ACCEPT_PAUSE_CONTINUE),   Numeric },
	{ TEXT( "SERVICE_ACCEPT_SHUTDOWN" ),		(LPVOID) (SERVICE_ACCEPT_SHUTDOWN),         Numeric },
    { TEXT( "SERVICE_ACCEPT_PARAMCHANGE" ),     (LPVOID) (SERVICE_ACCEPT_PARAMCHANGE),      Numeric },
    { TEXT( "SERVICE_ACCEPT_NETBINDCHANGE" ),   (LPVOID) (SERVICE_ACCEPT_NETBINDCHANGE),    Numeric },   
    
#ifdef SERVICE_ACCEPT_HARDWAREPROFILECHANGE
    { TEXT( "SERVICE_ACCEPT_HARDWAREPROFILECHANGE" ), (LPVOID) (SERVICE_ACCEPT_HARDWAREPROFILECHANGE),    Numeric },   
#endif // SERVICE_ACCEPT_HARDWAREPROFILECHANGE

#ifdef SERVICE_ACCEPT_POWEREVENT
    { TEXT( "SERVICE_ACCEPT_POWEREVENT" ),      (LPVOID) (SERVICE_ACCEPT_POWEREVENT),    Numeric },   
#endif // SERVICE_ACCEPT_POWEREVENT

#ifdef SERVICE_ACCEPT_SESSIONCHANGE
    { TEXT( "SERVICE_ACCEPT_SESSIONCHANGE" ),   (LPVOID) (SERVICE_ACCEPT_SESSIONCHANGE),    Numeric },   
#endif // SERVICE_ACCEPT_SESSIONCHANGE
    
    
 
    //  Define Start Types
    { TEXT( "SERVICE_BOOT_START" ),             (LPVOID) (SERVICE_BOOT_START),              Numeric },
    { TEXT( "SERVICE_SYSTEM_START" ),           (LPVOID) (SERVICE_SYSTEM_START),            Numeric },
    { TEXT( "SERVICE_AUTO_START" ),             (LPVOID) (SERVICE_AUTO_START),              Numeric },
    { TEXT( "SERVICE_DEMAND_START" ),           (LPVOID) (SERVICE_DEMAND_START),            Numeric },
    { TEXT( "SERVICE_DISABLED" ),               (LPVOID) (SERVICE_DISABLED),                Numeric },

    //  Define Error Controls
    { TEXT( "SERVICE_DISABLED" ),               (LPVOID) (SERVICE_DISABLED),                Numeric },
    { TEXT( "SERVICE_ERROR_NORMAL" ),           (LPVOID) (SERVICE_ERROR_NORMAL),            Numeric },
    { TEXT( "SERVICE_ERROR_SEVERE" ),           (LPVOID) (SERVICE_ERROR_SEVERE),            Numeric },
    { TEXT( "SERVICE_ERROR_CRITICAL" ),         (LPVOID) (SERVICE_ERROR_CRITICAL),          Numeric },

	// Define the Group Identifier (prepend this value to the name of a dependent group)
	{ TEXT( "SC_GROUP_IDENTIFIER" ),          	(LPVOID) (SC_GROUP_IDENTIFIER),          	String  },

    // Define the state's default error
    { TEXT( "NO_ERROR" ),                       (LPVOID) (NO_ERROR),                        Numeric },
    
    // Terminating structure. Leave this here!
    { NULL,                                     (LPVOID) NULL,                              Numeric }
};

eConstantType Constant( LPTSTR pszConstant, LPVOID *ppBuffer )
{
    eConstantType eResult = NotDefined;
    DWORD dwIndex = 0;

    while( NULL != gsConst[ dwIndex ].m_Name )
    {
        if( NULL == gsConst[ dwIndex ].m_Name )
        {
            break;
        }

        if( *pszConstant == *gsConst[ dwIndex ].m_Name )
        {
            int iResult = _tcsicmp( gsConst[ dwIndex ].m_Name, pszConstant );
            if( 0 == iResult )
            {
				eResult = gsConst[ dwIndex ].m_eType;
				if( eResult == String )
				{
					//	If this is a string we need to transfer
					//	the *string pointer* not just the value
					//	stored in the pointer.
					*ppBuffer = (LPVOID) &gsConst[ dwIndex ].m_pBuffer;
				}
				else
				{
					*ppBuffer = gsConst[ dwIndex ].m_pBuffer;
				}

                break;
            }
            /*
                //  This code segment is commented out so that we don't run into 
                //  the problem of a constant being out of alpha order hence not
                //  resolving.
            else if( 0 < iResult )
            {
                    //  We have passed the spot where this constant
                    //  *should* have been if it were in alpha order
                break;
            }
            */
        }
        dwIndex++;
    }
    return( eResult );
}

const char *GetConstantName( DWORD dwIndex )
{
    const char *pszBuffer = NULL;
    if( gdwConstTotal > dwIndex )
    {
        pszBuffer = gsConst[ dwIndex ].m_Name;
    }
    return( pszBuffer );
}

DWORD GetTotalConstants()
{
    return( gdwConstTotal );
}

void CountConstants()
{
   gdwConstTotal = 0;
   while( NULL != gsConst[ gdwConstTotal++ ].m_Name ){};  
}

void LogToFile( LPTSTR pszMessage )
{
    if( ghLogFile )
    {
        DWORD dwWritten = 0;
        DWORD dwBufferSize = 0;
        TCHAR szBuffer[ 256 ];
        SYSTEMTIME Time;
        GetLocalTime( &Time );
        wsprintf( szBuffer, TEXT( "\n[%04d.%02d.%02d %d:%02d:%02d] %s" ), 
                Time.wYear,
                Time.wMonth,
                Time.wDay,
                Time.wHour,
                Time.wMinute,
                Time.wSecond,
                (LPTSTR) pszMessage ); 

        dwBufferSize = lstrlen( szBuffer );
        WriteFile( ghLogFile, 
                    (LPCVOID) (szBuffer),
                    dwBufferSize, 
                    &dwWritten, 
                    NULL );
        
    }
}


/*
HISTORY

   20020605 rothd
    - Added the NO_ERROR constant.


	20080321 rothd
		-Added SERVICE_CONTROL_PRESHUTDOWN.
		-Added SERVICE_CONTROL_TIMER
		-Added SERVICE_CONTROL_START
		-Fixed constant look up to properly manage strings
*/
