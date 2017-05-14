/*******************************************************************************
 *    Author      : Lionel VICTOR <lionel.victor@unforgettable.com>
 *                                <lionel.victor@free.fr>
 *    Compiler    : gcc, Visual C++
 *    Target      : unix, Windows
 *
 *    Description : Perl wrapper to the PCSC API
 *    
 *    Copyright (C) 2001 - Lionel VICTOR
 *    Copyright (c) 2003-2010 - Ludovic ROUSSEAU
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 *    02111-1307 USA
 *
 ******************************************************************************/

 /* $Id: PCSCperl.h,v 1.22 2010-10-27 08:04:20 rousseau Exp $ */

/******************************************************************************
*    Contains basic definitions for a Perl wrapper to PCSC-lite. The code
* here is meant to be portable to most Unices. It should as well compile
* under Microsoft Windows without modifications.
*    Most macros in this file help portability.
******************************************************************************/

#ifndef PCSC_PERL
#define PCSC_PERL

#ifdef WIN32
#  include <windows.h>
#  include <winscard.h>
#  define LOAD_LIB()      LoadLibrary("winscard.dll")
#  define CLOSE_LIB       FreeLibrary
#  define DLL_HANDLE      HINSTANCE
#  define GET_FCT         GetProcAddress
/* The following defines are only set with PCSClite, we have to
 * declare them for use under WIN32
 */
#  define MAX_ATR_SIZE    33
#  define MAX_BUFFER_SIZE 264

#else /* WIN32 */

/*   WIN32 entry points are called with the WINAPI convention
 * the following hack is to handle this shit
 */
#define WINAPI

#ifdef  __APPLE__
#include <PCSC/wintypes.h>
#include <PCSC/winscard.h>
#define LPCTSTR LPCSTR
#include <CoreFoundation/CFBundle.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFURL.h>
#include <stdio.h>
#define DLL_HANDLE CFBundleRef
DLL_HANDLE LOAD_LIB() 
{   CFStringRef bundlePath; 
    CFURLRef bundleURL;
    CFBundleRef bundle;

    bundlePath = CFStringCreateWithCString(NULL, 
                            "/System/Library/Frameworks/PCSC.framework",
                                           kCFStringEncodingMacRoman);
    if (bundlePath == NULL) 
    {
	return NULL;
    }
    bundleURL = CFURLCreateWithFileSystemPath(NULL, bundlePath,
                                              kCFURLPOSIXPathStyle, TRUE);
    CFRelease(bundlePath);
    if (bundleURL == NULL) 
    {
	return NULL;
    } 
     
    bundle = CFBundleCreate(NULL, bundleURL);
    CFRelease(bundleURL);
    if (bundle == NULL) 
    {
	return NULL;
    }

 
    if (!CFBundleLoadExecutable(bundle))
    {
	CFRelease(bundle);
	return NULL;
    }
    return bundle;
}

void*  GET_FCT(CFBundleRef bundle, char *fct_name)         
{
    CFStringRef cfName;      
    void * fct_addr=NULL;
    cfName = CFStringCreateWithCString(NULL, fct_name,
                                       kCFStringEncodingMacRoman); 
    if (cfName == NULL)
    {
        return NULL;
    }
    fct_addr = CFBundleGetFunctionPointerForName(bundle, cfName);
    CFRelease(cfName);
    return fct_addr;
}

#else

/* other Unixes */
#  include <dlfcn.h>
#  include <pcsclite.h>
#  define LOAD_LIB()      dlopen("libpcsclite.so.1", RTLD_LAZY)
#  define CLOSE_LIB(x)    dlclose(x)
#  define DLL_HANDLE      void*
#  define GET_FCT         dlsym
#define LPCTSTR LPCSTR
#define LPTSTR LPSTR

#endif /* __APPLE__ */

#endif /* WIN32 */

/* extended APDU supported? (pcsc-lite >= 1.3.2 only) */
#ifndef MAX_BUFFER_SIZE_EXTENDED
#define MAX_BUFFER_SIZE_EXTENDED MAX_BUFFER_SIZE
#endif

/* Definitine fuctions imported from the PCSC library and used by the stub */
typedef LONG (WINAPI *TSCardEstablishContext) ( DWORD, LPCVOID, LPCVOID, LPSCARDCONTEXT );
typedef LONG (WINAPI *TSCardReleaseContext)   ( SCARDCONTEXT );
typedef LONG (WINAPI *TSCardListReaders)      ( SCARDCONTEXT, LPCTSTR, LPTSTR, LPDWORD );
typedef LONG (WINAPI *TSCardConnect)          ( SCARDCONTEXT, LPCTSTR, DWORD, DWORD, LPSCARDHANDLE, LPDWORD );
typedef LONG (WINAPI *TSCardReconnect)        ( SCARDHANDLE, DWORD, DWORD, DWORD, LPDWORD );  
typedef LONG (WINAPI *TSCardDisconnect)       ( SCARDHANDLE, DWORD );
typedef LONG (WINAPI *TSCardBeginTransaction) ( SCARDHANDLE );
typedef LONG (WINAPI *TSCardEndTransaction)   ( SCARDHANDLE, DWORD );
typedef LONG (WINAPI *TSCardTransmit)         ( SCARDHANDLE, LPCSCARD_IO_REQUEST, LPCBYTE, DWORD, LPSCARD_IO_REQUEST, LPBYTE, LPDWORD ); 
typedef LONG (WINAPI *TSCardControl)          ( SCARDHANDLE, DWORD, LPCBYTE, DWORD, LPBYTE, DWORD, LPDWORD );
typedef LONG (WINAPI *TSCardStatus)           ( SCARDHANDLE, LPTSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD );
typedef LONG (WINAPI *TSCardGetStatusChange)  ( SCARDHANDLE, DWORD, SCARD_READERSTATE *, DWORD );
typedef LONG (WINAPI *TSCardCancel)           ( SCARDCONTEXT );

/* these functions are not used */
/*
LONG SCardListReaderGroups( SCARDCONTEXT, LPSTR, LPDWORD );
*/

/* Declares a variable for any imported variable */
/* static LPSCARD_IO_REQUEST gpioSCardT0Pci;
static LPSCARD_IO_REQUEST gpioSCardT1Pci;
static LPSCARD_IO_REQUEST gpioSCardRawPci; */

/* Declares a variable for any imported function */
static TSCardEstablishContext hEstablishContext = NULL;
static TSCardReleaseContext   hReleaseContext   = NULL;
static TSCardListReaders      hListReaders      = NULL;
static TSCardConnect          hConnect          = NULL;
static TSCardReconnect        hReconnect        = NULL;
static TSCardDisconnect       hDisconnect       = NULL;
static TSCardBeginTransaction hBeginTransaction = NULL;
static TSCardEndTransaction   hEndTransaction   = NULL;
static TSCardTransmit         hTransmit         = NULL;
static TSCardControl          hControl          = NULL;
static TSCardStatus           hStatus           = NULL;
static TSCardGetStatusChange  hGetStatusChange  = NULL;
static TSCardCancel           hCancel           = NULL;

/* Also declares some static variables */
static DLL_HANDLE ghDll       = NULL;
static LONG       gnLastError = SCARD_S_SUCCESS;

/* these functions are not used */
/*
TSCardListReaderGroups hListReaderGroups = NULL;
*/

#define SCARD_P_ALREADY_CONNECTED 0x22200001
#define SCARD_P_NOT_CONNECTED     0x22200002

#endif

/* End of File */

