// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlShellExtInit_H
#define _PerlShellExtInit_H

#include "exports.h"
#include "PerlUnknownExt.h"

// the only reason this class exists is to avoid using multiple inheritance for PerlShellExt
// (deriving from both IContextMenu and IShellExtInit). this class does nothing but delegate
// all its methods to the aggregating PerlShellExt object.

typedef perlUnknownExt(IShellExtInit) PerlShellExtInitImpl;

class WIN32SHELLEXTAPI PerlShellExtInit : public PerlShellExtInitImpl
{
  PerlShellExtInit(const PerlShellExtInit&);
  PerlShellExtInit& operator=(const PerlShellExtInit&);
public:
  PerlShellExtInit(PerlShellExt *master);
  ~PerlShellExtInit() {}
  
  //IShellExtInit methods
  STDMETHODIMP		    Initialize(LPCITEMIDLIST pIDFolder, 
				       LPDATAOBJECT pDataObj, 
				       HKEY hKeyID);
};

#endif
