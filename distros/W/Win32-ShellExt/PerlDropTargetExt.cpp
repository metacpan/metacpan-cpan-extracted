// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlDropTargetExt.h"

PerlDropTargetExt::PerlDropTargetExt(PerlShellExt *master) : PerlDropTargetImpl(master) {}
PerlDropTargetExt::~PerlDropTargetExt() {}

HRESULT PerlDropTargetExt::DragEnter(IDataObject *pDataObj,
				      DWORD grfKeyState,
				      POINTL pt,
				      DWORD *pdwEffect)
{
  return E_NOTIMPL;
}
          
HRESULT PerlDropTargetExt::DragOver(DWORD grfKeyState,
				     POINTL pt,
				     DWORD *pdwEffect)
{
  return E_NOTIMPL;
}
          
HRESULT PerlDropTargetExt::DragLeave()
{
  return E_NOTIMPL;
}
          
HRESULT PerlDropTargetExt::Drop(IDataObject *pDataObj,
				 DWORD grfKeyState,
				 POINTL pt,
				 DWORD *pdwEffect)
{
  return E_NOTIMPL;
}

