#define PERL_NO_GET_CONTEXT     /* increase efficiency, decrease dll size (~5+%); URLref: http://perldoc.perl.org/perlguts.html#How-multiple-interpreters-and-concurrency-are-supported */
#include "EXTERN.h"
/*
 ##// disable MSVC warning for redefinition of ENOTSOCK [ C:\Perl\lib\CORE\sys/socket.h(32) : warning C4005: 'ENOTSOCK' : macro redefinition ; C:\Program Files\Microsoft Visual Studio 10.0\VC\INCLUDE\errno.h(120) : see previous definition of 'ENOTSOCK' ]
 ##// ToDO: enter this as defect report for MSVC / ActiveState Perl combination
*/
#ifdef _MSC_VER
#pragma warning ( disable : 4005 )
#endif
#include "perl.h"
#include "XSUB.h"

#include "tlhelp32.h"

MODULE = Win32::CommandLine    PACKAGE = Win32::CommandLine

PROTOTYPES: ENABLE

SV *
_wrap_GetCommandLine ()
    CODE:
        RETVAL = newSVpv( GetCommandLine(), 0 );
    OUTPUT:
        RETVAL

HANDLE
_wrap_CreateToolhelp32Snapshot ( dwFlags, th32ProcessID )
    DWORD dwFlags
    DWORD th32ProcessID
    CODE:
        RETVAL = CreateToolhelp32Snapshot( dwFlags, th32ProcessID );
    OUTPUT:
        RETVAL

bool
_wrap_Process32First ( hSnapshot, lppe )
    HANDLE hSnapshot
    PROCESSENTRY32 * lppe
    CODE:
        RETVAL = Process32First( hSnapshot, lppe );
    OUTPUT:
        RETVAL

bool
_wrap_Process32Next ( hSnapshot, lppe )
    HANDLE hSnapshot
    PROCESSENTRY32 * lppe
    CODE:
        RETVAL = Process32Next( hSnapshot, lppe );
    OUTPUT:
        RETVAL

bool
_wrap_CloseHandle ( hObject )
    HANDLE hObject
    CODE:
        RETVAL = CloseHandle( hObject );
    OUTPUT:
        RETVAL

 ##// Pass useful CONSTANTS back to perl

int
_const_MAX_PATH ()
    CODE:
        RETVAL = MAX_PATH;
    OUTPUT:
        RETVAL

HANDLE
_const_INVALID_HANDLE_VALUE ()
    CODE:
        RETVAL = INVALID_HANDLE_VALUE;
    OUTPUT:
        RETVAL

DWORD
_const_TH32CS_SNAPPROCESS ()
    CODE:
        RETVAL = TH32CS_SNAPPROCESS;
    OUTPUT:
        RETVAL

 ##// Pass useful sizes back to Perl (for testing) */

unsigned int
_info_SIZEOF_HANDLE ()
    CODE:
        RETVAL = sizeof(HANDLE);
    OUTPUT:
        RETVAL

unsigned int
_info_SIZEOF_DWORD ()
    CODE:
        RETVAL = sizeof(DWORD);
    OUTPUT:
        RETVAL

 #// Pass PROCESSENTRY32 structure info back to Perl

 ## URLref: http://perldoc.perl.org/perlpacktut.html#The-Alignment-Pit [http://www.webcitation.org/5xnxXRZYV @2011-04-08.2046] :: macro technique to develope aligned pack template from C structure
 ## URLref: PROCESSENTRY32 Structure [http://msdn.microsoft.com/en-us/library/ms684839%28VS.85%29.aspx ; http://www.webcitation.org/5xo33lF5p @2011-04-08.2210]
 ## [from "tlhelp32.h"]
 ## typedef struct tagXPROCESSENTRY32 {
 ##     DWORD dwSize;
 ##     DWORD cntUsage;                     # no longer used (always set to 0)
 ##     DWORD th32ProcessID;
 ##     ULONG_PTR th32DefaultHeapID;        # no longer used (always set to 0)
 ##     DWORD th32ModuleID;                 # no longer used (always set to 0)
 ##     DWORD cntThreads;
 ##     DWORD th32ParentProcessID;
 ##     LONG pcPriClassBase;
 ##     DWORD dwFlags;                      # no longer used (always set to 0)
 ##     TCHAR szExeFile[MAX_PATH];
 ## } PROCESSENTRY32;

SV *
_info_PROCESSENTRY32 ()
    INIT:
        AV * results;
        AV * row;
        results = newAV();
    CODE:
        row = newAV();
        av_push(row, newSVpv( "PROCESSENTRY32", 0 ));
        av_push(row, newSVnv( sizeof(PROCESSENTRY32) ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "dwSize", 0 ));
        av_push(row, newSVpv( "DWORD", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, dwSize) ));
        av_push(row, newSVpv( "L!", 0 ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "cntUsage", 0 ));
        av_push(row, newSVpv( "DWORD", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, cntUsage) ));
        av_push(row, newSVpv( "L!", 0 ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "th32ProcessID", 0 ) );
        av_push(row, newSVpv( "DWORD", 0 ) );
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32ProcessID) ));
        av_push(row, newSVpv( "L!", 0 ) );
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "th32DefaultHeapID", 0 ));
        av_push(row, newSVpv( "ULONG_PTR", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32DefaultHeapID) ));
        av_push(row, newSVpv( "P", 0 ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "th32ModuleID", 0 ));
        av_push(row, newSVpv( "DWORD", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32ModuleID) ));
        av_push(row, newSVpv( "L!", 0 ));
        av_push(results, newRV_inc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "cntThreads", 0 ));
        av_push(row, newSVpv( "DWORD", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, cntThreads) ));
        av_push(row, newSVpv( "L!", 0 ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "th32ParentProcessID", 0 ));
        av_push(row, newSVpv( "DWORD", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32ParentProcessID) ));
        av_push(row, newSVpv( "L!", 0 ));
        av_push(results, newRV_inc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "pcPriClassBase", 0 ));
        av_push(row, newSVpv( "LONG", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, pcPriClassBase) ));
        av_push(row, newSVpv( "l!", 0 ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "dwFlags", 0 ));
        av_push(row, newSVpv( "DWORD", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, dwFlags) ));
        av_push(row, newSVpv( "L!", 0 ));
        av_push(results, newRV_noinc((SV *)row));

        row = newAV();
        av_push(row, newSVpv( "szExeFile", 0 ));
        av_push(row, newSVpv( "TCHAR[]", 0 ));
        av_push(row, newSVnv( offsetof(PROCESSENTRY32, szExeFile) ));
        av_push(row, newSVpv( "Z", 0 ));
        av_push(row, newSVnv( MAX_PATH ));
        av_push(results, newRV_noinc((SV *)row));

        RETVAL = newRV_noinc((SV *)results);
    OUTPUT:
        RETVAL
