/* -*- C++ -*- // old habits are hard to change ;-)
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
 * The code was initiated from one the samples Microsoft provides (SHELLEX in MSDN), even
 * though it does not bear much resemblance with it any more.
 *
 * Perl-related portions (C) 2001-2002 Jean-Baptiste Nivoit.
 *
 * The SHELLEX sample from Microsoft comes with the following notice:
 *
 * THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
 * ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 *
 * Copyright (C) 1993-1997  Microsoft Corporation.  All Rights Reserved.
 *
 */

#include "Win32ShellExt.h"
#include "debug.h"

//#include "PerlMenu.h"

// ATTENTION this block MUST be here, if there are any function seen by the compiler before it, 
// it crashes systematically at runtime.
// begin block
#pragma data_seg(".text")
#define INITGUID
#include <initguid.h>
#include <shlguid.h>
// {045DB10D-2728-4963-A11A-A626CC1B51C6}
DEFINE_GUID(CLSID_PerlMenu, 
0x45db10d, 0x2728, 0x4963, 0xa1, 0x1a, 0xa6, 0x26, 0xcc, 0x1b, 0x51, 0xc6);
#pragma data_seg()

#define win32_fopen fopen
#define win32_fclose fclose
#define win32_fprintf fprintf
#define win32_free free
#define malloc win32_malloc
#define free win32_free 
// end block

UINT      g_cRefThisDll = 0;    // Reference count of this DLL.
HINSTANCE g_hmodThisDll = NULL;	// Handle to this DLL itself.

extern "C" int APIENTRY
DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
  if (dwReason == DLL_PROCESS_ATTACH)
    {
      // Extension DLL one-time initialization

      g_hmodThisDll = hInstance;
    }

  return 1;   // ok
}

STDAPI DllCanUnloadNow(void)
{
  return (g_cRefThisDll == 0 ? S_OK : S_FALSE);
}

#include "PerlShellExtClassFactory.h"

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppvOut)
{
  *ppvOut = NULL;

  char buf0[100], buf1[100];
  memset(buf0,0,sizeof(buf0));  memset(buf1,0,sizeof(buf1));
  int r0 = PerlShellExtClassFactory::CLSID2String(rclsid,buf0);
  int r1 = PerlShellExtClassFactory::CLSID2String(riid,buf1);
  EXTDEBUG((f,"DllGetClassObject %s %s %d %d\n",buf0,buf1,r0,r1));
  //  EXTDEBUG((f,"DllGetClassObject %s %s %x\n",buf0,buf1,perl);
  
//    if(IsEqualIID(rclsid,CLSID_PerlMenu)) {
//      PerlMenuClassFactory *pcf = new PerlMenuClassFactory();
//      return pcf->QueryInterface(riid,ppvOut);
//    }

  PerlShellExtClassFactory *pcf = PerlShellExtClassFactory::FindClassFactory(rclsid);
  
  if(pcf==0)
    return CLASS_E_CLASSNOTAVAILABLE;
  return pcf->QueryInterface(riid, ppvOut);
}

#include "PerlShellExtClassFactory.cpp"

#include "PerlShellExt.cpp"
#include "PerlShellExtInit.cpp"
#include "PerlShellExtCtxtMenu.cpp"
#include "PerlQueryInfoExt.cpp"
#include "PerlPersistFileExt.cpp"
#include "PerlColumnProviderExt.cpp"
#include "PerlCopyHookExt.cpp"
#include "PerlDataObjectExt.cpp"
#include "PerlDropTargetExt.cpp"
#include "PerlPropSheetExt.cpp"
#include "PerlIconHandlerExt.cpp"

//#include "PerlMenu.cpp"

// the following compensates for the #define in PerlShellExtClassFactory.cpp
#undef Perl_get_context

#include "ShellExt/CopyHook.c"
