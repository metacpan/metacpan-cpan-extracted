/* *********************************************************************
 * Win32::Monitoring::DLLInject - 
 *    Injects code into Win32 programs to overload functions
 * *********************************************************************
 * DLLInject.xs: Perl XS code for injecting code into programs and DLLs
 * *********************************************************************
 * Authors: Roman Plessl
 *          Tobias Oetiker
 *
 * Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.
 * 
 * Win32::Monitoring::DLLInject is free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.
 *
 * $Id: DLLInject.xs 203 2009-07-23 09:09:58Z rplessl $ 
 ***********************************************************************
 */

#define __MSVCRT_VERSION__ 0x601
#define WINVER 0x0500 

#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <string.h>

// for error handle
#include <strsafe.h>

// MAILSLOT FOR COMMUNICATION
#define __MAILSLOT__ "\\\\.\\mailslot\\F9AD51D8-428A-11DD-9E14-7E7256D89593"

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
            XSRETURN(1); \
        } else { \
            free(String); \
            XSRETURN_NO; \
        } \
    } else { \
        XSRETURN_NO; \
    }


/*** Global Variables ***/

/*** Helper Functions ***/

void ErrorExit(LPTSTR lpszFunction) 
{ 
    // Retrieve the system error message for the last-error code
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD dw = GetLastError(); 

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    // Display the error message and exit the process
    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, 
        (lstrlen((LPCTSTR)lpMsgBuf)+lstrlen((LPCTSTR)lpszFunction)+40)*sizeof(TCHAR)); 
    StringCchPrintf((LPTSTR)lpDisplayBuf, 
        LocalSize(lpDisplayBuf) / sizeof(TCHAR),
        TEXT("%s failed with error %d: %s"), 
        lpszFunction, dw, lpMsgBuf); 
    MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("Error"), MB_OK); 

    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
    ExitProcess(dw); 
}


LPWSTR
_PerlStrToWinStr(LPSTR string)
{
    LPWSTR uString = NULL;
    int uStringLen;

    uStringLen = MultiByteToWideChar(CP_ACP, 0, string, -1, uString, 0);
    if(uStringLen) {
        uString = (LPWSTR) malloc(uStringLen * 2);
        if(MultiByteToWideChar(CP_ACP, 0, string, -1, uString, uStringLen)) {          
            return uString;
            // free(uString);
        } else {
            free(uString);
            return NULL;
        }
    } else {
        return NULL;
    }
}


LPSTR
_WinStrToPerlStr(LPWSTR uString)
{          
    LPSTR string = NULL;
    int stringLen;

    stringLen = WideCharToMultiByte(CP_ACP, 0, uString, -1, string, 0, NULL, NULL);
    if(stringLen) {
        string = (LPSTR) malloc(stringLen);
        if(WideCharToMultiByte(CP_ACP, 0, uString, -1, string, stringLen, NULL, NULL)) {
            return string;
            // free(string);
         } else {
            free(string);
            return NULL;
        }
    } else {
        return NULL;
    }
}


DWORD
_DoHook( DWORD ProcessId, LPWSTR szLibFile, BOOL UnHookMode, HMODULE hFreeModule )
{
  
    HANDLE hProcess;
    HANDLE hThread;

    int countchars = 0;    
    
    PWSTR pszLibFileRemote = NULL;
    LPTHREAD_START_ROUTINE pfnThreadRtn = NULL;
    
    // printf("ProcessID: %d\n", ProcessId );
        
    hProcess = OpenProcess(PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE |
                           PROCESS_QUERY_INFORMATION | PROCESS_CREATE_THREAD,
                           FALSE,
                           ProcessId);
    
    if (hProcess == NULL)
    {
        return 0;
    }

    countchars = 1 + wcslen(szLibFile);

    // printf("countchars lenght is:         %d\n", countchars);
    // printf("countchars length (wchar) is: %d\n", countchars*sizeof(WCHAR));
    // printf("string     is:                %S\n", szLibFile);
    // printf("ProcessID:                    %d\n", ProcessId );
        
    if (WaitForInputIdle(hProcess,10000) != 0) 
    {
        return 0;
    }

    pszLibFileRemote = (PWSTR)VirtualAllocEx(hProcess, NULL, countchars*sizeof(WCHAR), MEM_COMMIT, PAGE_READWRITE);

    if (pszLibFileRemote == NULL) 
    {
        return 0;
    }

    if (!WriteProcessMemory(hProcess, (PVOID)pszLibFileRemote, (PVOID)szLibFile, countchars*sizeof(WCHAR), NULL))
    {
        return 0;
    }

    if(UnHookMode) {
        pfnThreadRtn = (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle(TEXT("Kernel32")), "FreeLibrary");
    } else {
        pfnThreadRtn = (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle(TEXT("Kernel32")), "LoadLibraryW");
    }

    if (pfnThreadRtn == NULL) 
    {
        return 0;
    }

    if(UnHookMode) {
        hThread = CreateRemoteThread(hProcess, NULL, 0, pfnThreadRtn, (HMODULE)hFreeModule, 0, NULL);
    } else {  
        hThread = CreateRemoteThread(hProcess, NULL, 0, pfnThreadRtn, (PVOID)pszLibFileRemote, 0, NULL);
    }
    
    if (hThread == NULL) 
    {
        return 0;
    }

    WaitForSingleObject(hThread, INFINITE);

    if (pszLibFileRemote != NULL)
    {
        VirtualFreeEx(hProcess, (PVOID)pszLibFileRemote, 0, MEM_RELEASE);
    }

    if (hThread != NULL)
    {
        CloseHandle(hThread);
    }
    

    if (hProcess != NULL)
    {
        CloseHandle(hProcess);
    }
    
    return 1;
}


// We will require this function to get a module handle of our original module
HMODULE 
_EnumModules( DWORD ProcessId, LPWSTR szLibFile )
{
    HMODULE hMods[1024];
    DWORD cbNeeded;

    unsigned int i;
        
    HANDLE hProcess;
    HMODULE m_hModPSAPI;   

    typedef BOOL (WINAPI * PFNENUMPROCESSMODULES)
    (
        HANDLE hProc,
        HMODULE *lphModule,
        DWORD cb,
        LPDWORD lpcbNeeded
    );

    typedef DWORD (WINAPI * PFNGETMODULEFILENAMEEXW)
    (
        HANDLE hProc,
        HMODULE hModule,
        LPWSTR lpFilename,
        DWORD nSize
    );

    PFNENUMPROCESSMODULES   m_pfnEnumProcessModules;
    PFNGETMODULEFILENAMEEXW m_pfnGetModuleFileNameExW;   

    WCHAR szModName[MAX_PATH];
    
    hProcess = OpenProcess(PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE |
                           PROCESS_QUERY_INFORMATION | PROCESS_CREATE_THREAD,
                           FALSE,
                           ProcessId); 

    if (hProcess == NULL) {      
        return 0;
    }
    
    m_hModPSAPI = LoadLibraryA("PSAPI.DLL");

    m_pfnEnumProcessModules = (PFNENUMPROCESSMODULES)GetProcAddress(m_hModPSAPI, "EnumProcessModules");

    m_pfnGetModuleFileNameExW = (PFNGETMODULEFILENAMEEXW)GetProcAddress(m_hModPSAPI, "GetModuleFileNameExW");

    if( m_pfnEnumProcessModules(hProcess, hMods, sizeof(hMods), &cbNeeded))
    {       
        for ( i = 0; i < (cbNeeded / sizeof(HMODULE)); i++ )
        {
            // Get the full path to the module's file.
            
            if ( m_pfnGetModuleFileNameExW( hProcess, hMods[i], szModName, sizeof(szModName) ) )
            {
                // printf("%S \t (0x%08X)\n", szModName, (unsigned int)hMods[i] );

                // printf("szModName: %S \n",szModName);
                // printf("szLibFile: %S \n",szLibFile);               
                // printf("\n");
                
                if( wcsstr(szModName, szLibFile) != 0)
                {
                    // printf("I'm Injected !!!\n");
                    FreeLibrary(m_hModPSAPI);
                    CloseHandle(hProcess);
                    return hMods[i];
                }
            }
            // else {
            //    printf ("Not Success: %d\n", i);
            // }
        }
    }

    FreeLibrary(m_hModPSAPI);
    CloseHandle(hProcess);

    return 0;
}


HANDLE WINAPI 
_MakeMailSlot( LPSTR lpszSlotName ) 
{ 
    HANDLE hMailSlot;

    // printf("Mailslot name: %s\n", lpszSlotName);
        
    hMailSlot = CreateMailslot(__MAILSLOT__, 
                               0,                             // no maximum message size 
                               MAILSLOT_WAIT_FOREVER,         // no time-out for operations 
                               (LPSECURITY_ATTRIBUTES) NULL); // default security
 
    if (hMailSlot == INVALID_HANDLE_VALUE) 
    { 
        // printf("CreateMailslot failed with %d\n", (int)GetLastError());
        return NULL;
    } 

    // printf("hMailSlot: (0x%08X)\n", hMailSlot);

    return hMailSlot; 
}


BOOL 
_ValidMailSlot( HANDLE hSlot ) 
{ 
    DWORD  cbMessage, cMessage; 
    BOOL   fResult; 

    cbMessage = 0;
    cMessage  = 0;

    fResult = GetMailslotInfo( hSlot, // mailslot handle 
        (LPDWORD) NULL,               // no maximum message size 
        &cbMessage,                   // size of next message 
        &cMessage,                    // number of messages 
        (LPDWORD) NULL);   

    // printf("cMessage:  %li\n", cMessage);
    // printf("cbMessage: %li\n", cbMessage);
    // printf("fResult:   %i\n", fResult);
    
    if (!fResult) 
    { 
            // printf("GetMailslotInfo failed with %d.\n", (int)GetLastError()); 
            return FALSE; 
    }

    return TRUE;
}
    
DWORD 
_StatMailSlot( HANDLE hSlot )
{
    DWORD  cbMessage, cMessage;
    BOOL   fResult; 
 
    cbMessage = 0;
    cMessage  = 0;

    fResult = GetMailslotInfo( hSlot, // mailslot handle 
        (LPDWORD) NULL,               // no maximum message size 
        &cbMessage,                   // size of next message 
        &cMessage,                    // number of messages 
        (LPDWORD) NULL);              // no read time-out

    if (cbMessage == MAILSLOT_NO_MESSAGE) 
    { 
         return 0; 
    } 

    return cMessage;
}


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = Win32::Monitoring::DLLInject           PACKAGE = Win32::Monitoring::DLLInject

SV*
init(DLLInjectPid,szDLLInjectLibFilePerlStr)
    DWORD DLLInjectPid; 
    LPSTR szDLLInjectLibFilePerlStr; 
PREINIT:
    LPSTR DLLInjectMailSlot;
    LPWSTR szDLLInjectLibFile; 
    HANDLE hDLLInjectMailSlot = NULL;
    HMODULE hDLLInjectModule = NULL;
    int HookSucess = 0;
PPCODE:
    // create mailslot 
    DLLInjectMailSlot = __MAILSLOT__;
    hDLLInjectMailSlot = _MakeMailSlot(DLLInjectMailSlot);
    // convert perl string to windows string
    szDLLInjectLibFile = _PerlStrToWinStr(szDLLInjectLibFilePerlStr);
    // hook function
    HookSucess = _DoHook(DLLInjectPid, szDLLInjectLibFile, FALSE, 0);
    if ( HookSucess == 1) {
        hDLLInjectModule = _EnumModules(DLLInjectPid, szDLLInjectLibFile);
    }
    EXTEND(sp,3);
    PUSHs( sv_2mortal( newSViv( PTR2IV(hDLLInjectMailSlot) ) ) ); // it's just a ptr
    PUSHs( sv_2mortal( newSViv( PTR2IV(hDLLInjectModule) ) ) );   // it's just a ptr       
    PUSHs( sv_2mortal( newSViv( HookSucess ) ) );


SV*
destroy(DLLInjectPid,szDLLInjectLibFilePerlStr,hDLLInjectMailSlot,hDLLInjectModule)
    DWORD DLLInjectPid; 
    LPSTR szDLLInjectLibFilePerlStr; 
    HANDLE hDLLInjectMailSlot;
    HMODULE hDLLInjectModule;
PREINIT:
    LPWSTR szDLLInjectLibFile;   
    int UnHookSucess = 0;
PPCODE:
    // convert perl string to windows string
    szDLLInjectLibFile = _PerlStrToWinStr(szDLLInjectLibFilePerlStr);
    // unhook function
    if(hDLLInjectModule != NULL)
    {
        UnHookSucess = _DoHook(DLLInjectPid, szDLLInjectLibFile, TRUE, hDLLInjectModule);
    }
    if ( UnHookSucess == 1) {
        hDLLInjectModule = _EnumModules(DLLInjectPid, szDLLInjectLibFile);
    }
    EXTEND(sp,2);
    PUSHs( sv_2mortal( newSViv( PTR2IV(hDLLInjectModule) ) ) );   // it's just a ptr
    PUSHs( sv_2mortal( newSViv( UnHookSucess ) ) );               
    

DWORD 
StatMailslot(hDLLInjectMailSlot)
    HANDLE hDLLInjectMailSlot;    
CODE:
    RETVAL = 0;
    if ( _ValidMailSlot( hDLLInjectMailSlot ) )
    {
            RETVAL =  _StatMailSlot( hDLLInjectMailSlot );
    }
OUTPUT:
    RETVAL


SV*
GetMailslotMessage(hDLLInjectMailSlot)
    HANDLE hDLLInjectMailSlot; 
PREINIT:
    DWORD  cbMessage =0;
    DWORD  cMessage =0;
    DWORD  cbRead =0;
    BOOL   fResult;  
    LPWSTR lpszBuffer = NULL;
    LPSTR  String = NULL;
    int stringLen;
    HANDLE hEvent;
    OVERLAPPED ov;
PPCODE:
    hEvent = CreateEvent(NULL, FALSE, FALSE, TEXT("ExampleSlot"));
    if (! hEvent) {
       XSRETURN_NO;
    }

    ov.Offset     = 0;
    ov.OffsetHigh = 0;
    ov.hEvent     = hEvent;

    // printf ("Begin Message Fetching!\n");
    
    fResult = GetMailslotInfo( hDLLInjectMailSlot, // mailslot handle
                               (LPDWORD) NULL,     // no maximum message size
                               &cbMessage,         // size of next message 
                               &cMessage,          // number of messages
                               (LPDWORD) NULL);    // no read time-out
   
    if (cMessage != 0)  // retrieve all messages
    { 
        // Create a message-number string. 
        //
        // StringCchPrintf((LPTSTR) achID, 
        //     80,
        //     TEXT("\nMessage #%d of %d\n"),
        //     cAllMessages - cMessage + 1,
        //     cAllMessages);

        // Allocate memory for the message.
        lpszBuffer = (LPWSTR) GlobalAlloc(GPTR,cbMessage);
 
        fResult = ReadFile(hDLLInjectMailSlot,
                           lpszBuffer,
                           cbMessage, 
                           &cbRead,
                           &ov); 
 
        // if (!fResult) 
        // { 
        //     printf("ReadFile failed with %d.\n", (int)GetLastError()); 
        // }
        
        // printf("Buffer is: %S\n", lpszBuffer);                                
                                   
        if (fResult) 
        { 
            returnMultiByteString( lpszBuffer, String, stringLen );
        }
        GlobalFree((HGLOBAL) lpszBuffer);
    } 

    CloseHandle(hEvent);
    XSRETURN(1);


