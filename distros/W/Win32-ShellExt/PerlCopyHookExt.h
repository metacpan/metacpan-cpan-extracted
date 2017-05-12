// -*- c++ -*-
/*
 * (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
 */
#ifndef _PerlCopyHookExt_H
#define _PerlCopyHookExt_H

#include <shlobj.h>

#include "PerlUnknownExt.h"

class PerlShellExt;

typedef perlUnknownExt(ICopyHookA) PerlCopyHookImpl;

class WIN32SHELLEXTAPI PerlCopyHookExt : public PerlCopyHookImpl
{
  PerlCopyHookExt(const PerlCopyHookExt&);
  PerlCopyHookExt& operator=(const PerlCopyHookExt&);

  friend class PerlShellExt;
public:
  PerlCopyHookExt(PerlShellExt *master);
  ~PerlCopyHookExt();
  
  // *** ICopyHook methods ***
  STDMETHOD_(UINT,CopyCallback) (HWND hwnd, UINT wFunc, UINT wFlags, LPCSTR pszSrcFile, DWORD dwSrcAttribs, LPCSTR pszDestFile, DWORD dwDestAttribs);
};

#endif
