/* 
 * Win32::Monitoring::WindowPing - 
 *    Access to window status information on Win32 systems
 *
 * Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.
 * 
 * Win32::Monitoring::WindowPing is free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.
 *
 * $Id: WindowPing.xs 152 2008-08-25 14:16:30Z rplessl $ 
 */

#define __MSVCRT_VERSION__ 0x601
#define WINVER 0x0500

#include <windows.h>
#include <winuser.h>

#include <memory.h>
#include <psapi.h>

#define ALIVE       1
#define TIMEOUT     2
#define NOTAWINDOW  3
#define OTHERERROR  4

#define returnMultiByteString(uString,String,stringLen) \
    if (uString == NULL) { \
        XSRETURN_NO; \
    } \
    stringLen = WideCharToMultiByte(CP_ACP, 0, uString, -1, String, 0, NULL, NULL); \
    if(stringLen) { \
        String = (LPSTR) malloc(stringLen); \
        if(WideCharToMultiByte(CP_ACP, 0, uString, -1, String, stringLen, NULL, NULL)) { \
            XST_mPV(0, (char *) String); \
            free(String); \
            free(uString); \
            XSRETURN(1); \
        } else { \
            free(String); \
            free(uString); \
            XSRETURN_NO; \
        } \
    } else { \
        free(uString); \
        XSRETURN_NO; \
    }


/*
     More information about handling the active window is documented here:
     http://msdn.microsoft.com/en-us/library/ms632604(VS.85).aspx
*/

HWND _GetActiveWindow()
{
    GUITHREADINFO guiinfo;
    HWND ActiveWindowHandle;

    guiinfo.cbSize = sizeof(GUITHREADINFO);

    ActiveWindowHandle = NULL;

    GetGUIThreadInfo(0,&guiinfo);
    if (guiinfo.hwndActive != NULL){
        ActiveWindowHandle = guiinfo.hwndActive;
    }
    return ActiveWindowHandle;
}

int _PingWindow( HWND ActiveWindowHandle, int timeoutSecs )
{
    DWORD ProcessId;
    DWORD dwResult;

    ProcessId = 0;
    dwResult = 0; 

    if ( IsWindow( ActiveWindowHandle ) ) {
        if (! SendMessageTimeout( ActiveWindowHandle, WM_NULL, 0, 0, SMTO_BLOCK, timeoutSecs, &dwResult ) ) {
            // SentMessageTimeout can fail for other reasons, 
            // if it's not a timeout we exit try again later
            if (ERROR_TIMEOUT != GetLastError()) {
                return OTHERERROR;
            }
            return TIMEOUT;
        }
        else {
            return ALIVE;
        }
    }
    else {
        return NOTAWINDOW;
    }
}

DWORD _GetProcessIdForWindow( HWND ActiveWindowHandle ) 
{
    DWORD ProcessId;
    ProcessId = 0;
    GetWindowThreadProcessId(ActiveWindowHandle, &ProcessId);
    return ProcessId;
}


#include "EXTERN.h"
#include "perl.h"  
#include "XSUB.h"  
#include "ppport.h"

MODULE = Win32::Monitoring::WindowPing		PACKAGE = Win32::Monitoring::WindowPing

HWND
GetActiveWindow()
    CODE:
    {
        RETVAL = _GetActiveWindow();
    }
    OUTPUT:
        RETVAL


int      
PingWindow(ActiveWindowHandle,timeoutSecs)
    HWND ActiveWindowHandle
    int timeoutSecs      
    CODE:
    {
        RETVAL = _PingWindow(ActiveWindowHandle,timeoutSecs);
    }
    OUTPUT:
        RETVAL


void
GetWindowCaption(ActiveWindowHandle)
    HWND ActiveWindowHandle
PREINIT:
    LPWSTR windowCaption = NULL;
    LPSTR String = NULL;
    int maxChars;
    int hasCaption;
    int stringLen;
PPCODE:
    maxChars = 100;
    hasCaption = 0;
    while( IsWindow( ActiveWindowHandle ) )
    {
        if ( GetWindowLong( ActiveWindowHandle, GWL_STYLE ) & WS_CAPTION ) {
            windowCaption = (LPWSTR) malloc(maxChars * 2);
            if ( GetWindowTextW( ActiveWindowHandle, windowCaption, maxChars ) ) {
                 break;
            }
        }
        ActiveWindowHandle = GetParent( ActiveWindowHandle );
    }
    returnMultiByteString( windowCaption, String, stringLen );

DWORD
GetProcessIdForWindow(ActiveWindowHandle)
    HWND ActiveWindowHandle
    CODE:
    {
        RETVAL = _GetProcessIdForWindow(ActiveWindowHandle);
    }
    OUTPUT:
        RETVAL


void
GetNameForProcessId(ProcessId)
    DWORD ProcessId
PREINIT:
    HANDLE hProcess;
    LPWSTR szModName = NULL;
    LPSTR String = NULL;  
    int stringLen;
PPCODE:
    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
                           FALSE, ProcessId);
    if( ! hProcess ) {
        //printf("Can't open process %ld (error %ld)", ProcessId, GetLastError());
        XSRETURN_NO;
    }
    /* What is the name of the executable? */
    szModName = (LPWSTR) malloc(MAX_PATH * 2);
    if (! GetModuleBaseNameW( hProcess, NULL, szModName, MAX_PATH ) ) {
        //printf("Can't get ModuleBasename %ld (error %ld)", ProcessId, GetLastError());
        CloseHandle(hProcess);
        XSRETURN_NO;
    }
    CloseHandle(hProcess);
    returnMultiByteString( szModName, String, stringLen );
