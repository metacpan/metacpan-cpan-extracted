//////////////////////////////////////////////////////////////////////////////
//
//  CCallbackTimer.cpp
//  Win32::Daemon Perl extension callback timer class source file
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

#include "CCallbackTimer.hpp"

CCallbackTimer::CCallbackTimer()
{
	m_TimerID = 0;
	m_TimerValue = 0;
	m_MessageID = 0;
}


CCallbackTimer::~CCallbackTimer()
{
	Stop();
}

BOOL CCallbackTimer::Start()
{
	//
	//	Only consider starting if we are already in a stopped
	//	state AND the callback timer value is not 0.
	//
	if( 0 == m_TimerID && 0 < m_TimerValue )
	{
		m_TimerID = ::SetTimer( NULL, m_MessageID, m_TimerValue, (TIMERPROC) NULL );
	}

	return( (BOOL) 0 != m_TimerID );
}

BOOL CCallbackTimer::Stop()
{
	if( m_TimerID )
	{
		if( 0 != ::KillTimer( 0, m_TimerID ) )
		{
			m_TimerID = 0;
		}
	}
	return( (BOOL) 0 == m_TimerID );
}

BOOL CCallbackTimer::QueryState()
{
    return( (BOOL) 0 != m_TimerID );
}

UINT CCallbackTimer::SetMessageID( UINT iNewMessageID )
{
	BOOL fRunningState = QueryState();

	//
	//	Let's only accept positive values. :)
	//
	Stop();
	m_MessageID = iNewMessageID;
	//
	//	Only start again if we were previously in the
	//	started state.
	//
	if( fRunningState )
	{
		Start();
	}

	return(  m_MessageID );
}

UINT CCallbackTimer::GetMessageID()
{
	return( m_MessageID );	
}

int CCallbackTimer::GetTimerValue()
{
	return( (int) m_TimerValue );
}


int CCallbackTimer::SetTimerValue( int iNewTimerValue )
{
	BOOL fRunningState = QueryState();

	//
	//	Let's only accept positive values. :)
	//
	if( -1 < iNewTimerValue )
	{
		Stop();
		m_TimerValue = (UINT)iNewTimerValue;
		//
		//	Only start again if we were previously in the
		//	started state.
		//
		if( fRunningState )
		{
			Start();
		}
	}
	return( (int) m_TimerValue );
}

int CCallbackTimer::operator=( const int iRightHandValue )
{
	if( 0 <= iRightHandValue )
	{
		SetTimerValue( iRightHandValue );
	}
	return( (int) m_TimerValue );
}

