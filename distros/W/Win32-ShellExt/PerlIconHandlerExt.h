// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlIconHandlerExt_H
#define _PerlIconHandlerExt_H

#include "exports.h"
#include "PerlUnknownExt.h"

typedef perlUnknownExt(IUnknown) PerlIconHandlerImpl;

class PerlIconHandlerExt : public PerlIconHandlerImpl 
{
  PerlIconHandlerExt(const PerlIconHandlerExt&);
  PerlIconHandlerExt& operator=(const PerlIconHandlerExt&);
 public:
  PerlIconHandlerExt(PerlShellExt *master);
  ~PerlIconHandlerExt();
  
};

#endif

