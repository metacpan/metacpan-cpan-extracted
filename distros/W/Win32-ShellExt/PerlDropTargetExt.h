// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
// 
// A Drop handler implements IPersistFile & IDropTarget, it converts icons into drop targets.  
//
#ifndef _PerlDropTargetExt_H
#define _PerlDropTargetExt_H

#include <objidl.h>
#include "PerlUnknownExt.h"
class PerlShellExt;

typedef perlUnknownExt(IDropTarget) PerlDropTargetImpl;

class PerlDropTargetExt : public PerlDropTargetImpl
{
  PerlDropTargetExt(const PerlDropTargetExt&);
  PerlDropTargetExt& operator=(const PerlDropTargetExt&);

public:
  PerlDropTargetExt(PerlShellExt *master);
  ~PerlDropTargetExt();

  HRESULT STDMETHODCALLTYPE DragEnter(IDataObject *pDataObj,
				      DWORD grfKeyState,
				      POINTL pt,
				      DWORD *pdwEffect);
        
  HRESULT STDMETHODCALLTYPE DragOver(DWORD grfKeyState,
				     POINTL pt,
				     DWORD *pdwEffect);
        
  HRESULT STDMETHODCALLTYPE DragLeave();
        
  HRESULT STDMETHODCALLTYPE Drop(IDataObject *pDataObj,
				 DWORD grfKeyState,
				 POINTL pt,
				 DWORD *pdwEffect);
};
#endif


