//////////////////////////////////////////////////////////////////////////////
//
//  CCallbackList.cpp
//  Win32::Daemon Perl extension callback list class source file
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

#include "CCallbackList.hpp"

CCallbackList::CCallbackList()
{
	for( int iIndex = 0; iIndex < TOTAL_CALLBACK; iIndex++ )
	{
		m_pSvList[iIndex] = NULL;
	}
    m_dwCount = 0;
}


CCallbackList::~CCallbackList()
{
}

DWORD CCallbackList::GetCallbackIndex( DWORD dwCommand )
{
	DWORD dwIndex = 0xffffffff;

	switch( dwCommand )
	{
		case CALLBACK_RUNNING:
            // This has been deprecated and replaced with CALLBACK_TIMER
			// We only support it for legacy purposes.
			// The main Daemon.xs code attempts to map this to CALLBACK_TIMER
			dwIndex = CALLBACK_RUNNING_INDEX;
			break;

		case CALLBACK_USER_DEFINED:
			dwIndex = CALLBACK_USERDEFINED_INDEX;
			break;

		case CALLBACK_TIMER:
			dwIndex = CALLBACK_TIMER_INDEX;
			break;

		case CALLBACK_START:
			dwIndex = CALLBACK_START_INDEX;
			break;

		case CALLBACK_STOP:
			dwIndex = CALLBACK_STOP_INDEX;
			break;

		case CALLBACK_PAUSE:
			dwIndex = CALLBACK_PAUSE_INDEX;
			break;
					
		case CALLBACK_CONTINUE:
			dwIndex = CALLBACK_CONTINUE_INDEX;
			break;
				
		case CALLBACK_INTERROGATE:
			dwIndex = CALLBACK_INTERROGATE_INDEX;
			break;
			
		case CALLBACK_SHUTDOWN:
			dwIndex = CALLBACK_SHUTDOWN_INDEX;
			break;
				
		case CALLBACK_PARAMCHANGE:
			dwIndex = CALLBACK_PARAMCHANGE_INDEX;
			break;
			
		case CALLBACK_NETBINDADD:
			dwIndex = CALLBACK_NETBINDADD_INDEX;
			break;
				
		case CALLBACK_NETBINDREMOVE:
			dwIndex = CALLBACK_NETBINDREMOVE_INDEX;
			break;
			
		case CALLBACK_NETBINDENABLE:
			dwIndex = CALLBACK_NETBINDENABLE_INDEX;
			break;
			
		case CALLBACK_NETBINDDISABLE:
			dwIndex = CALLBACK_NETBINDDISABLE_INDEX;
			break;
			
		case CALLBACK_DEVICEEVENT:
			dwIndex = CALLBACK_DEVICEEVENT_INDEX;
			break;
			
		case CALLBACK_HARDWAREPROFILECHANGE:
			dwIndex = CALLBACK_HARDWAREPROFILECHANGE_INDEX;
			break;
  
		case CALLBACK_POWEREVENT:
			dwIndex = CALLBACK_POWEREVENT_INDEX;
			break;
				
		case CALLBACK_SESSIONCHANGE:
			dwIndex = CALLBACK_SESSIONCHANGE_INDEX;
			break;

#ifdef SERVICE_CONTROL_PRESHUTDOWN
		case CALLBACK_PRESHUTDOWN:
			dwIndex = CALLBACK_PRESHUTDOWN_INDEX;
			break;
#endif	//	#ifdef SERVICE_CONTROL_PRESHUTDOWN

		default: 
			dwIndex = 0xFFFFFFFF;
	}
	return( dwIndex );
}

BOOL CCallbackList::Set( DWORD dwCommand, PVOID pCallbackRoutine )
{
	BOOL fResult = FALSE;
	DWORD dwCallbackIndex = GetCallbackIndex( dwCommand );

	if( 0xFFFFFFFF == dwCallbackIndex ) return( FALSE );

	if( 0 <= dwCallbackIndex && TOTAL_CALLBACK > dwCallbackIndex )
	{
        if( NULL == m_pSvList[ dwCallbackIndex ] && NULL != pCallbackRoutine )
        {
            m_dwCount++;
            if( TOTAL_CALLBACK < m_dwCount )
            {
                m_dwCount = TOTAL_CALLBACK;
            }
        }
        else if( NULL != m_pSvList[ dwCallbackIndex ] && NULL == pCallbackRoutine )
        {
            m_dwCount--;
            if( 0 < (long) m_dwCount )
            {
                m_dwCount = 0;
            }
        }

		m_pSvList[ dwCallbackIndex ] = pCallbackRoutine;
		fResult = TRUE;
	}
	return( fResult );
}

PVOID CCallbackList::Get( DWORD dwCommand )
{
	PVOID pResult = NULL;
	DWORD dwCallbackIndex = GetCallbackIndex( dwCommand );

	if( 0xFFFFFFFF == dwCallbackIndex ) return( NULL );

	if( 0 <= dwCallbackIndex && TOTAL_CALLBACK > dwCallbackIndex )
	{
		pResult = m_pSvList[ dwCallbackIndex ];
	}
	return( pResult );
}

DWORD CCallbackList::GetCount()
{
    return( m_dwCount );
}
