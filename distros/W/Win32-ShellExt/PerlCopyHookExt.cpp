// -*- c++ -*-
/*
 * (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
 */
#include "PerlCopyHookExt.h"

//
// See http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/Shell/reference/ifaces/icopyhook/CopyCallback.asp
// for details on the ICopyCallback interface.
//
//
// The Microsoft documentation specifies the following keys for copy hooks:
//
//  Copy hook handlers for folders are registered under the following key. 
//
//  HKEY_CLASSES_ROOT
//  	Directory
//  		Shellex
//  			CopyHookHandlers
//  				your_copyhook
//  					(Default) = {copyhook CLSID value}
//
//  Copy hook handlers for printers are registered under the following key. 
//
//  HKEY_CLASSES_ROOT
//  	Printers
//  		Shellex
//  			CopyHookHandlers
//  				your_copyhook
//  					(Default) = {copyhook CLSID value}
//
//
// printer copy hooks are not supported (merely because i dont need them) by
// the code (although there's probably more work to do on the Perl side than 
// on the C++ side).
//

PerlCopyHookExt::PerlCopyHookExt(PerlShellExt *master) : PerlCopyHookImpl(master) {}
PerlCopyHookExt::~PerlCopyHookExt() {}

UINT PerlCopyHookExt::CopyCallback (HWND hwnd, UINT wFunc, UINT wFlags, LPCSTR pszSrcFile, DWORD dwSrcAttribs, LPCSTR pszDestFile, DWORD dwDestAttribs)
  // this method determines whether the Shell will be allowed to move, copy, delete, or rename a folder or printer object. 
{
  char *func="";
  switch(wFunc) {
#define CASE(x) case x: func=#x; break
    CASE(FO_COPY);
    CASE(FO_DELETE);
    CASE(FO_MOVE);
    CASE(FO_RENAME);
  default:;
#undef CASE
  }
  
  char *flags="";
  switch(wFlags) {
#define CASE(x) case x: flags=#x; break
    CASE(FOF_ALLOWUNDO);
    CASE(FOF_CONFIRMMOUSE);
    CASE(FOF_FILESONLY);
    CASE(FOF_MULTIDESTFILES);
    CASE(FOF_NOCONFIRMATION);
    CASE(FOF_NOCONFIRMMKDIR);
#ifdef FOF_NO_CONNECTED_ELEMENTS
    CASE(FOF_NO_CONNECTED_ELEMENTS);
#endif
    CASE(FOF_NOCOPYSECURITYATTRIBS);
    CASE(FOF_NOERRORUI);
    CASE(FOF_NORECURSION);
#ifdef FOF_RECURSEREPARSE
    CASE(FOF_RECURSEREPARSE);
#endif
#ifdef FOF_NORECURSEREPARSE
    CASE(FOF_NORECURSEREPARSE);
#endif
    CASE(FOF_RENAMEONCOLLISION);
    CASE(FOF_SILENT);
    CASE(FOF_SIMPLEPROGRESS);
    CASE(FOF_WANTMAPPINGHANDLE);
#ifdef FOF_WANTNUKEWARNING
    CASE(FOF_WANTNUKEWARNING);
#endif
  default:;
#undef CASE    
  }
  return m_master->factory()->CopyCallback(m_master->Object(),hwnd,func,flags,pszSrcFile,dwSrcAttribs,pszDestFile,dwDestAttribs);
}
