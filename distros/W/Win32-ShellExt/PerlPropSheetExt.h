// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
// 
// a property sheet handler implements IShellExtInit & IShellPropSheetExt.
//
#ifndef _PerlPropSheetExt_H
#define _PerlPropSheetExt_H

#include <objidl.h>
#include "PerlUnknownExt.h"
class PerlShellExt;

typedef perlUnknownExt(IShellPropSheetExt) PerlShellPropSheetExtImpl;

// FIXME should have been named PerlShellPropSheetExt to conform to my naming convention.
class PerlPropSheetExt : public PerlShellPropSheetExtImpl
{
  PerlPropSheetExt(const PerlPropSheetExt&);
  PerlPropSheetExt& operator=(const PerlPropSheetExt&);

public:
  PerlPropSheetExt(PerlShellExt *master);
  ~PerlPropSheetExt();

  HRESULT STDMETHODCALLTYPE AddPages(LPFNSVADDPROPSHEETPAGE pfnAddPage,
				     LPARAM lParam);
  
  HRESULT STDMETHODCALLTYPE ReplacePage(EXPPS uPageID,
					LPFNSVADDPROPSHEETPAGE pfnReplaceWith,
					LPARAM lParam);

};
#endif
