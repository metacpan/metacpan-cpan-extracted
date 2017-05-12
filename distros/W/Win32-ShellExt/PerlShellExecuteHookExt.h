// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
// 
// implementation of IShellExecuteHook
//

#ifndef _PerlShellExecuteHookExt_H
#define _PerlShellExecuteHookExt_H

#include <shlobj.h>

#include "PerlUnknownExt.h"
typedef perlUnknownExt(IShellExecuteHook) PerlShellExecuteHookImpl;

class PerlShellExecuteHookExt : public PerlShellExecuteHookImpl
{
  PerlShellExecuteHookExt(const PerlShellExecuteHookExt&);
  PerlShellExecuteHookExt& operator=(const PerlShellExecuteHookExt&);

public:
  PerlShellExecuteHookExt(PerlShellExt *master);
  ~PerlShellExecuteHookExt();

  STDMETHOD(Execute)(LPSHELLEXECUTEINFOA pei);
        
};

#endif


