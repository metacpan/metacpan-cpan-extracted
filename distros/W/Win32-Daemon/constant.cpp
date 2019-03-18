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

/* needed for compatibility with perls 5.14 and older */
#ifndef newCONSTSUB_flags
#define newCONSTSUB_flags(stash, name, len, flags, sv) newCONSTSUB((stash), (name), (sv))
#endif

#define DO_CONST_IV(c) \
    newCONSTSUB_flags(stash, #c, strlen(#c), 0, newSViv(c)); \
    av_push(export_av, newSVpvs(#c));

#define DO_CONST_PV_NAME(name, value) \
    newCONSTSUB_flags(stash, name, strlen(name), 0, newSVpvn(value, strlen(value))); \
    av_push(export_av, newSVpvn(name, strlen(name)));

// SC_GROUP_IDENTIFIER is a char constant, we need to make it a string
// before we pass it to DO_CONST_PV()
static const char sc_group_identifier_str[] = {SC_GROUP_IDENTIFIER, 0};

void ExportConstants(pTHX)
{
    HV *stash = gv_stashpv("Win32::Daemon", GV_ADD);
    AV *export_av = get_av("Win32::Daemon::EXPORT_XS", TRUE);

    DO_CONST_IV(SERVICE_NOT_READY);
    DO_CONST_IV(SERVICE_STOPPED);
    DO_CONST_IV(SERVICE_RUNNING);
    DO_CONST_IV(SERVICE_PAUSED);
    DO_CONST_IV(SERVICE_START_PENDING);
    DO_CONST_IV(SERVICE_STOP_PENDING);
    DO_CONST_IV(SERVICE_CONTINUE_PENDING);
    DO_CONST_IV(SERVICE_PAUSE_PENDING);

    DO_CONST_IV(SERVICE_CONTROL_NONE);
    DO_CONST_IV(SERVICE_CONTROL_STOP);
    DO_CONST_IV(SERVICE_CONTROL_PAUSE);
    DO_CONST_IV(SERVICE_CONTROL_CONTINUE);
    DO_CONST_IV(SERVICE_CONTROL_INTERROGATE);
    DO_CONST_IV(SERVICE_CONTROL_SHUTDOWN);
    DO_CONST_IV(SERVICE_CONTROL_PARAMCHANGE);
    DO_CONST_IV(SERVICE_CONTROL_NETBINDADD);
    DO_CONST_IV(SERVICE_CONTROL_NETBINDREMOVE);
    DO_CONST_IV(SERVICE_CONTROL_NETBINDENABLE);
    DO_CONST_IV(SERVICE_CONTROL_NETBINDDISABLE);
    DO_CONST_IV(SERVICE_CONTROL_DEVICEEVENT);
    DO_CONST_IV(SERVICE_CONTROL_HARDWAREPROFILECHANGE);
    DO_CONST_IV(SERVICE_CONTROL_POWEREVENT);
    DO_CONST_IV(SERVICE_CONTROL_SESSIONCHANGE);
    DO_CONST_IV(SERVICE_CONTROL_USER_DEFINED);
    DO_CONST_IV(SERVICE_CONTROL_RUNNING);
    DO_CONST_IV(SERVICE_CONTROL_TIMER);
    DO_CONST_IV(SERVICE_CONTROL_START);

#ifdef SERVICE_CONTROL_PRESHUTDOWN
    DO_CONST_IV(SERVICE_CONTROL_PRESHUTDOWN);
#endif

    //  Service bits available to a script
    DO_CONST_IV(USER_SERVICE_BITS_1);
    DO_CONST_IV(USER_SERVICE_BITS_2);
    DO_CONST_IV(USER_SERVICE_BITS_3);
    DO_CONST_IV(USER_SERVICE_BITS_4);
    DO_CONST_IV(USER_SERVICE_BITS_5);
    DO_CONST_IV(USER_SERVICE_BITS_6);
    DO_CONST_IV(USER_SERVICE_BITS_7);
    DO_CONST_IV(USER_SERVICE_BITS_8);
    DO_CONST_IV(USER_SERVICE_BITS_9);
    DO_CONST_IV(USER_SERVICE_BITS_10);

    //  Define Service Types
    DO_CONST_IV(SERVICE_WIN32_OWN_PROCESS);
    DO_CONST_IV(SERVICE_WIN32_SHARE_PROCESS);
    DO_CONST_IV(SERVICE_KERNEL_DRIVER);
    DO_CONST_IV(SERVICE_FILE_SYSTEM_DRIVER);
    DO_CONST_IV(SERVICE_INTERACTIVE_PROCESS);

    //    Define control acceptance constants
    DO_CONST_IV(SERVICE_ACCEPT_STOP);
    DO_CONST_IV(SERVICE_ACCEPT_PAUSE_CONTINUE);
    DO_CONST_IV(SERVICE_ACCEPT_SHUTDOWN);
    DO_CONST_IV(SERVICE_ACCEPT_PARAMCHANGE);
    DO_CONST_IV(SERVICE_ACCEPT_NETBINDCHANGE);

#ifdef SERVICE_ACCEPT_HARDWAREPROFILECHANGE
    DO_CONST_IV(SERVICE_ACCEPT_HARDWAREPROFILECHANGE);
#endif // SERVICE_ACCEPT_HARDWAREPROFILECHANGE

#ifdef SERVICE_ACCEPT_POWEREVENT
    DO_CONST_IV(SERVICE_ACCEPT_POWEREVENT);
#endif // SERVICE_ACCEPT_POWEREVENT

#ifdef SERVICE_ACCEPT_SESSIONCHANGE
    DO_CONST_IV(SERVICE_ACCEPT_SESSIONCHANGE);
#endif // SERVICE_ACCEPT_SESSIONCHANGE

    //  Define Start Types
    DO_CONST_IV(SERVICE_BOOT_START);
    DO_CONST_IV(SERVICE_SYSTEM_START);
    DO_CONST_IV(SERVICE_AUTO_START);
    DO_CONST_IV(SERVICE_DEMAND_START);
    DO_CONST_IV(SERVICE_DISABLED);

    //  Define Error Controls
    DO_CONST_IV(SERVICE_ERROR_NORMAL);
    DO_CONST_IV(SERVICE_ERROR_SEVERE);
    DO_CONST_IV(SERVICE_ERROR_CRITICAL);

    // Define the Group Identifier (prepend this value to the name of a dependent group)
    DO_CONST_PV_NAME("SC_GROUP_IDENTIFIER", sc_group_identifier_str);

    // Define the state's default error
    DO_CONST_IV(NO_ERROR);
};

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
