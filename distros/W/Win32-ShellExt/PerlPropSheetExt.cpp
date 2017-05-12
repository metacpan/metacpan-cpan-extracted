// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlDropTargetExt.h"

PerlPropSheetExt::PerlPropSheetExt(PerlShellExt *master) : PerlShellPropSheetExtImpl(master) {}
PerlPropSheetExt::~PerlPropSheetExt() {}

HRESULT PerlPropSheetExt::AddPages(LPFNSVADDPROPSHEETPAGE pfnAddPage, LPARAM lParam)
{
  return E_NOTIMPL;
}
  	  
HRESULT PerlPropSheetExt::ReplacePage(EXPPS uPageID,LPFNSVADDPROPSHEETPAGE pfnReplaceWith, LPARAM lParam)
{
  return E_NOTIMPL;
}
