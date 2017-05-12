//////////////////////////////////////////////////////////////////////////////
//
//  CCallbackTimer.hpp
//  Win32::Daemon Perl extension callback timer class header file
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

#ifndef _CCALLBACKTIMER_H_
#define _CCALLBACKTIMER_H_

class CCallbackTimer
{
	public:
		CCallbackTimer();
		~CCallbackTimer();

		BOOL Stop();
		BOOL Start();
        BOOL QueryState();
		UINT GetMessageID();
		UINT SetMessageID( UINT iNewMessageID );
		int GetTimerValue();
		int SetTimerValue( int iNewTimerValue );
		int operator=( const int iRightHandValue );
		
	private:
		UINT m_TimerValue;
		UINT_PTR m_TimerID;
		UINT m_MessageID;
};

#endif // _CCALLBACKTIMER_H_

