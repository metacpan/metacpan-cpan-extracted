//////////////////////////////////////////////////////////////////////////////
//
//  CCallbackList.hpp
//  Win32::Daemon Perl extension callback list class header file
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

#ifndef _CCALLBACKLIST_H_
#define _CCALLBACKLIST_H_

#include "CONSTANT.h"

//  Define a unique value to identify the callback "running"
//  timer. This is the ID we pass into CCallbackTimer class to manage
//	the Win32 timer.
#define CALLBACK_TIMER_ID				0x0101

#define	CALLBACK_TIMER					SERVICE_CONTROL_TIMER				 //	 Our own definition
#define CALLBACK_START					SERVICE_CONTROL_START                //  Our own definition
#define CALLBACK_STOP					SERVICE_CONTROL_STOP                   
#define CALLBACK_PAUSE					SERVICE_CONTROL_PAUSE                  
#define CALLBACK_CONTINUE				SERVICE_CONTROL_CONTINUE               
#define CALLBACK_INTERROGATE			SERVICE_CONTROL_INTERROGATE            
#define CALLBACK_SHUTDOWN				SERVICE_CONTROL_SHUTDOWN               
#define CALLBACK_PARAMCHANGE			SERVICE_CONTROL_PARAMCHANGE            
#define CALLBACK_NETBINDADD				SERVICE_CONTROL_NETBINDADD             
#define CALLBACK_NETBINDREMOVE			SERVICE_CONTROL_NETBINDREMOVE          
#define CALLBACK_NETBINDENABLE			SERVICE_CONTROL_NETBINDENABLE          
#define CALLBACK_NETBINDDISABLE			SERVICE_CONTROL_NETBINDDISABLE         
#define CALLBACK_DEVICEEVENT			SERVICE_CONTROL_DEVICEEVENT            
#define CALLBACK_HARDWAREPROFILECHANGE  SERVICE_CONTROL_HARDWAREPROFILECHANGE  
#define CALLBACK_POWEREVENT				SERVICE_CONTROL_POWEREVENT             
#define CALLBACK_SESSIONCHANGE			SERVICE_CONTROL_SESSIONCHANGE   
#ifdef SERVICE_CONTROL_PRESHUTDOWN
	#define CALLBACK_PRESHUTDOWN			SERVICE_CONTROL_PRESHUTDOWN
#endif	//	SERVICE_CONTROL_PRESHUTDOWN

#define	CALLBACK_TIMER_INDEX					0x00
#define CALLBACK_START_INDEX					0x01
#define CALLBACK_STOP_INDEX						0x02
#define CALLBACK_PAUSE_INDEX					0x03
#define CALLBACK_CONTINUE_INDEX					0x04
#define CALLBACK_INTERROGATE_INDEX				0x05
#define CALLBACK_SHUTDOWN_INDEX					0x06
#define CALLBACK_PARAMCHANGE_INDEX				0x07
#define CALLBACK_NETBINDADD_INDEX				0x08
#define CALLBACK_NETBINDREMOVE_INDEX			0x09
#define CALLBACK_NETBINDENABLE_INDEX			0x0a
#define CALLBACK_NETBINDDISABLE_INDEX			0x0b
#define CALLBACK_DEVICEEVENT_INDEX				0x0c
#define CALLBACK_HARDWAREPROFILECHANGE_INDEX	0x0d
#define CALLBACK_POWEREVENT_INDEX				0x0e
#define CALLBACK_SESSIONCHANGE_INDEX			0x0f
#define CALLBACK_PRESHUTDOWN_INDEX				0x10
#define CALLBACK_USERDEFINED_INDEX				0x11
#define CALLBACK_RUNNING_INDEX					0x12
//	Next one is the total (non zero based index) of callback entries.
//	This is used to create an array to hold all of these callback 
//	pointers.
#define	TOTAL_CALLBACK							0x13

#define CALLBACK_USER_DEFINED					SERVICE_CONTROL_USER_DEFINED   //  Our own definition
#define CALLBACK_RUNNING						SERVICE_CONTROL_RUNNING        //  Our own definition


// Control callback function names
#define CALLBACK_NAME_TIMER					TEXT( "timer" )
#define CALLBACK_NAME_START                 TEXT( "start" )
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
#define CALLBACK_NAME_DEVICEEVENT	        TEXT( "device_event" )
#define CALLBACK_NAME_HARDWAREPROFILECHANGE TEXT( "hardware_profile_change" )
#define CALLBACK_NAME_POWEREVENT            TEXT( "power_event" )
#define CALLBACK_NAME_SESSIONCHANGE         TEXT( "session_change" ) 
#ifdef SERVICE_CONTROL_PRESHUTDOWN
	#define CALLBACK_NAME_PRESHUTDOWN		TEXT( "preshutdown" )
#endif	//	SERVICE_CONTROL_PRESHUTDOWN

// Control callback function names for misc stuff...
#define CALLBACK_NAME_USER_DEFINED			TEXT( "user_defined" )
#define CALLBACK_NAME_RUNNING               TEXT( "running" )


class CCallbackList
{
	public:
		CCallbackList();
		~CCallbackList();

		PVOID Get( DWORD dwCommand );
		BOOL Set( DWORD dwCommand, PVOID pCallbackRoutine );
        DWORD GetCount();
		
	private:
		DWORD GetCallbackIndex( DWORD dwCommand );
		
		PVOID m_pSvList[TOTAL_CALLBACK];
        DWORD m_dwCount;

};

#endif	//	_CCALLBACKLIST_H_

