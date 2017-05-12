/* *********************************************************************
 * Win32::Monitoring::DllInject - 
 *    Injects code into Win32 programs to overload functions
 * *********************************************************************
 * HookedFunctions.c: Template and example for injecting DLL
 * *********************************************************************
 * Based on code by Parag Paithankar  
 * http://www.codeproject.com/KB/system/api_monitoring_unleashed.aspx 
 * *********************************************************************
 * Authors: Tobias Oetiker
 *          Roman Plessl
 *
 * Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.
 * 
 * Win32::Monitoring::DllInject is free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.
 *
 * $Id: WindowPing.xs 127 2008-08-13 09:09:45Z rplessl $ 
 *
 * **********************************************************************
 */

#define __MSVCRT_VERSION__ 0x601
#define WINVER 0x0500 

#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <stdlib.h>
#include <shlobj.h>
#include <imagehlp.h>

/* include this for time measurements */
#define TIMESTAMP

/* include this for debugging with message boxes */
//#define VERBOSE


/* *** MAILSLOT FOR COMMUNICATION *** */
#define __MAILSLOT__ _TEXT("\\\\.\\mailslot\\F9AD51D8-428A-11DD-9E14-7E7256D89593")

/* remarks to the define myllu:

   myllu is a 'fix' for the 'not correctly' processing of unsigned long long
   in msvcr.dll. this should be added/fixed in msvcr80.dll, but I have not
   tested this. The linux printf llu is I64u according to:

     http://msdn.microsoft.com/en-us/library/tcxf1dw6.aspx

   You can test the behaviour of your system by building and running the
   test_llu.exe

     make test_llu.exe
     test_llu.exe
   
*/
/* *** Redefines for Visual C Compiler *** */
#ifdef _MSC_VER

#define myLPCWSTR  LPCSTR
#define myLLU      L"%I64u"

#else 

#define myLPCWSTR  LPCWSTR
#define myLLU      L"%I64u"

#endif

/* *** GLOBAL VARIABLES *** */
myLPCWSTR SlotName = __MAILSLOT__;
DWORD CurrentProcessID;  

/* *** TIMESTAMP HANDLING *** */

#ifdef TIMESTAMP
#include <sys/types.h>
#include <sys/timeb.h>
#include <time.h>

typedef unsigned long long   longtime_t;

longtime_t timems (void){
     struct __timeb64 timebuffer;
     _ftime64( &timebuffer );
     return ((longtime_t)timebuffer.time * 1000 + (longtime_t)timebuffer.millitm);
}

#endif


/* *** FUNCTIONS *** */
BOOL WriteSlot( HANDLE hSlot, LPCWSTR lpszMessage )
{
   static HANDLE s_hSlot = INVALID_HANDLE_VALUE;
   /* call once with hSlot set to the real handle
      to initialize WriteSlot */   

   if (hSlot != INVALID_HANDLE_VALUE){
       s_hSlot = hSlot;
   }

   if (s_hSlot != INVALID_HANDLE_VALUE){
       DWORD cbWritten; 
#ifdef VERBOSE
#ifdef _MSC_VER
       MessageBoxW(NULL, lpszMessage, _TEXT(L"Message"), MB_OK | MB_ICONINFORMATION);
#else
       MessageBox(NULL, lpszMessage, _TEXT("Message"), MB_OK | MB_ICONINFORMATION);
#endif
#endif
       return WriteFile(s_hSlot, 
                        lpszMessage, 
                        (DWORD) (wcslen(lpszMessage)+1)*sizeof(WCHAR),
                        &cbWritten, 
                        (LPOVERLAPPED) NULL); 
   }
   return 0;
}

void SetHook( HMODULE hModuleOfCaller, HMODULE hModule, LPSTR LibraryName, PROC OldFunctionPointer, PROC NewFunctionPointer )
{
    ULONG ulSize;
    PIMAGE_IMPORT_DESCRIPTOR pImportDesc = NULL;
    PSTR pszModName = NULL;
    PIMAGE_THUNK_DATA pThunk = NULL;
    PROC pfnCurrent = NULL;
    PROC* ppfn = NULL;
    BOOL bFound = FALSE;
    DWORD dwOldProtect = 0;

    // track process id of current process cause the same library
    // can be used to inject multiple programs
    CurrentProcessID = GetCurrentProcessId();
    
    if(hModuleOfCaller == hModule)
        return;
    if(hModuleOfCaller == 0)
        return;

    // Get the address of the module's import section
    pImportDesc = (PIMAGE_IMPORT_DESCRIPTOR) ImageDirectoryEntryToData
    (
        hModuleOfCaller, 
        TRUE, 
        IMAGE_DIRECTORY_ENTRY_IMPORT, 
        &ulSize
    );

    // Does this module have an import section ?
    if (pImportDesc == NULL)
        return;

    // Loop through all descriptors and find the 
    // import descriptor containing references to callee's functions
    while (pImportDesc->Name)
    {
        pszModName = (PSTR)((PBYTE) hModuleOfCaller + pImportDesc->Name);
        
        if (strcmp(pszModName, LibraryName) == 0) 
            break; // Found

        pImportDesc++;
    } // while

    if (pImportDesc->Name == 0)
        return;

    //Get caller's IAT 
    pThunk = (PIMAGE_THUNK_DATA)( (PBYTE) hModuleOfCaller + pImportDesc->FirstThunk );

    pfnCurrent = OldFunctionPointer;

    // Replace current function address with new one
    while (pThunk->u1.Function)
    {
        // Get the address of the function address
        ppfn = (PROC*) &pThunk->u1.Function;
        // Is this the function we're looking for?
        bFound = (*ppfn == pfnCurrent);

        if (bFound) 
        {
            MEMORY_BASIC_INFORMATION mbi;
            
            VirtualQuery(ppfn, &mbi, sizeof(MEMORY_BASIC_INFORMATION));

            // In order to provide writable access to this part of the 
            // memory we need to change the memory protection

            if (FALSE == VirtualProtect(mbi.BaseAddress,mbi.RegionSize,PAGE_READWRITE,&mbi.Protect))
                return;

            *ppfn = NULL;
            *ppfn = *NewFunctionPointer;

            // Restore the protection back
            dwOldProtect = 0;

            VirtualProtect(mbi.BaseAddress,mbi.RegionSize,mbi.Protect,&dwOldProtect);
            
            break;
        } // if

        pThunk++;

    } // while
}

PROC EnumAndSetHooks( LPSTR BaseLibraryName, LPSTR BaseFunctionName, PROC NewFunctionPointer, HMODULE hModule, BOOL UnHook, PROC Custom )
{
    HMODULE hMods[1024];
    DWORD cbNeeded;
    unsigned int i;
    typedef BOOL (WINAPI * PFNENUMPROCESSMODULES)
    (
        HANDLE hProcess,
        HMODULE *lphModule,
        DWORD cb,
        LPDWORD lpcbNeeded
    );

    PROC hBaseProc;

    HMODULE hBaseLib = NULL;
    PFNENUMPROCESSMODULES m_pfnEnumProcessModules = NULL;
    HMODULE m_hModPSAPI = NULL;
    HANDLE hProcess = NULL;
   
    hBaseLib = LoadLibraryA(BaseLibraryName);

    if(UnHook)
        hBaseProc = (PROC) Custom;
    else
        hBaseProc = GetProcAddress(hBaseLib, BaseFunctionName);

    m_hModPSAPI = LoadLibraryA("PSAPI.DLL");

    m_pfnEnumProcessModules = (PFNENUMPROCESSMODULES)GetProcAddress(m_hModPSAPI, "EnumProcessModules");

    hProcess = GetCurrentProcess();

    if( m_pfnEnumProcessModules(hProcess, hMods, sizeof(hMods), &cbNeeded)) {
        for ( i = 0; i < (cbNeeded / sizeof(HMODULE)); i++ ) {
            SetHook(hMods[i], hModule, BaseLibraryName, hBaseProc, NewFunctionPointer); 
        }
    }

    return hBaseProc;
}

/* wrapper for return value functions */
#define fnwrap(return_type, function, arg_def, arg_call, arg_monitor) \
        static PROC g_Original ## function = NULL; \
        typedef return_type WINAPI w32apimon_ ## function ## _t arg_def; \
        return_type WINAPI w32apimon_ ## function arg_def { \
            return_type ReturnValue; \
            unsigned long long start; unsigned long long now; \
            WCHAR starttime[24]; WCHAR deltatime[24]; WCHAR processid[8]; WCHAR functionname[50]; WCHAR measurement[300]; \
            start = timems(); \
            w32apimon_ ## function ## _t* fn = (w32apimon_ ## function ## _t*)g_Original  ## function; \
            ReturnValue = (*fn) arg_call; \
            now = timems(); \
            swprintf( starttime,    myLLU,                 start ); \
            swprintf( deltatime,    myLLU,                 (now-start) ); \
            swprintf( processid,    L"%u",                 CurrentProcessID ); \
            swprintf( functionname, L"%S",                 #function ); \
            swprintf( measurement,  L"%s\t%s\t%s\t%s\t%s", starttime, deltatime, processid, functionname, arg_monitor); \
            WriteSlot(INVALID_HANDLE_VALUE,measurement); \
            return ReturnValue; \
        }

/* wrapper for void functions */
#define vfnwrap(function, arg_def, arg_call) \
        static PROC g_Original ## function = NULL; \
        typedef void WINAPI w32apimon_ ## function ## _t arg_def; \
        void WINAPI w32apimon_ ## function arg_def {\
            longtime_t start; longtime_t now; \
            WCHAR starttime[24]; WCHAR deltatime[24]; WCHAR processid[8]; WCHAR functionname[50];  WCHAR measurement[300]; \
            start = timems(); \
            w32apimon_ ## function ## _t* fn = (w32apimon_ ## function ## _t*)g_Original  ## function; \
            (*fn) arg_call; \
            now = timems(); \
            swprintf( starttime,    myLLU,                 start ); \
            swprintf( deltatime,    myLLU,                 (now-start) ); \
            swprintf( processid,    L"%u",                 CurrentProcessID ); \
            swprintf( functionname, L"%S",                 #function ); \
            swprintf( measurement,  L"%s\t%s\t%s\t%s\t%s", starttime, deltatime, processid, functionname); \
            WriteSlot(INVALID_HANDLE_VALUE,measurement);                     

#define hook(dll,function) \
            g_Original ## function = EnumAndSetHooks(#dll, #function, (PROC) w32apimon_ ## function, hModule, FALSE, 0);

#define unhook(dll,function) \
            EnumAndSetHooks(#dll, #function, (PROC) ( g_Original ## function != NULL ? g_Original ## function : GetProcAddress(LoadLibraryA(#dll),#function)), hModule, TRUE, (PROC) w32apimon_ ## function);

/***************************************************************/
/* Here are the declaration for the the replacment functions   */
/* BEGIN replacement functions prototypes                      */
/***************************************************************/
fnwrap(BOOL,SetCurrentDirectoryW,(LPCWSTR lpPathName),(lpPathName),lpPathName)

fnwrap(BOOL,CreateDirectoryW,(LPCWSTR lpPathName, LPSECURITY_ATTRIBUTES lpSecurityAttributes),(lpPathName,lpSecurityAttributes),lpPathName)

vfnwrap(SHAddToRecentDocs,( UINT uFlags, LPCVOID pv),(uFlags,pv))
            if (uFlags & SHARD_PATH){
                    WriteSlot(INVALID_HANDLE_VALUE,pv);
            } else {
                    WCHAR pszPath[MAX_PATH];
                    if (SHGetPathFromIDListW(pv,pszPath)){
                        WriteSlot(INVALID_HANDLE_VALUE,pszPath);
                    }
            }
}            
/***************************************************************/
/* END replacement functions prototypes                        */
/***************************************************************/

BOOL APIENTRY DllMain( HANDLE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    HANDLE hSlot = NULL;
    switch (ul_reason_for_call)
    {
        case DLL_PROCESS_ATTACH:
            hSlot = CreateFile(SlotName, 
                               GENERIC_WRITE, 
                               FILE_SHARE_READ,
                               (LPSECURITY_ATTRIBUTES) NULL, 
                               OPEN_EXISTING, 
                               FILE_ATTRIBUTE_NORMAL, 
                               (HANDLE) NULL); 

/***************************************************************/
/* replacement for these functions in the corresponding DLL    */
/* BEGIN function replacement (hook)                           */
/***************************************************************/

            hook(KERNEL32.dll,SetCurrentDirectoryW)
            hook(KERNEL32.dll,CreateDirectoryW)
            hook(shell32.dll,SHAddToRecentDocs)

/***************************************************************/
/* END function replacement (hook)                             */
/***************************************************************/

#ifdef _MSC_VER
            WriteSlot(hSlot,TEXT(L"Functions Hooked"));            
#else
            WriteSlot(hSlot,TEXT("Functions Hooked"));  
#endif

            break;
        case DLL_PROCESS_DETACH:

/***************************************************************/
/* replacement for these functions in the corresponding DLL    */
/* BEGIN function replacement (unhook)                         */
/***************************************************************/           

            unhook(KERNEL32.dll,SetCurrentDirectoryW)
            unhook(KERNEL32.dll,CreateDirectoryW)
            unhook(shell32.dll,SHAddToRecentDocs)

/***************************************************************/
/* END function replacement (unhook)                           */
/***************************************************************/

#ifdef _MSC_VER
            WriteSlot(hSlot,TEXT(L"Functions UnHooked"));            
#else
            WriteSlot(hSlot,TEXT("Functions UnHooked"));
#endif

            break;
    }
    return TRUE;
}

