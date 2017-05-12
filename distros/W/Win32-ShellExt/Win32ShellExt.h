/* -*- c++ -*- // old habits are hard to change ;-)
 *
 *
 * Win32ShellExt.cpp
 *
 * This is the main code for the perl-win32-shellext Shell extension DLL.
 * It embeds the perl interpreter into an extension to the Windows Explorer (also
 * called the Windows Shell). This is never used as an extension per se, but
 * always through some perl code that extension writers provide.
 * 
 * Each script that is to be a shell extension must have its own CLSID : this is really the
 * CLSID of the shell extension, but unlike other shell extensions, these will always
 * use the same extension DLL, but have an additionnal key that allows the DLL to locate
 * the perl script it should invoke.
 *
 * To accomplish this, each extension script must be a subclass of Win32::ShellExt, which
 * provides some base capabilities, such as installing/deinstalling the extension, and also
 * defining a calling convention for the methods that are going to be called from the Explorer.
 *
 *
 * Look for 'FIXME' for places where things can be made better.
 *
 *
 * (C) 2001-2002 Jean-Baptiste Nivoit.
 */

#ifndef _Win32ShellExt_H
#define _Win32ShellExt_H

#ifndef STRICT
#define STRICT
#endif

#define INC_OLE2        // WIN32, get ole2 from windows.h

#include <windows.h>
#include <windowsx.h>
#include <shlobj.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
//#include <malloc.h>

#define ResultFromShort(i)  ResultFromScode(MAKE_SCODE(SEVERITY_SUCCESS, 0, (USHORT)(i)))

#include <shlguid.h>

#include "exports.h"

STDAPI DllCanUnloadNow(void);
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppvOut);


#endif
