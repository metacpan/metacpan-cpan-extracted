// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlShellExtInit.h"
#include "PerlShellExtCtxtMenu.h"

PerlShellExtInit::PerlShellExtInit(PerlShellExt *master) : PerlShellExtInitImpl(master) {}

//PerlShellExtInit~PerlShellExtInit() {}
  
STDMETHODIMP		    PerlShellExtInit::Initialize(LPCITEMIDLIST pIDFolder, 
							 LPDATAOBJECT pDataObj, 
							 HKEY hKeyID) {
  PerlShellExtCtxtMenu *ctxtmenu = m_master->FindCtxtMenuExt();
  if(ctxtmenu==0)
    ctxtmenu = m_master->LoadCtxtMenuExt();
  return ctxtmenu->Initialize(pIDFolder,pDataObj,hKeyID);
}

