// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlPersistFileExt_H
#define _PerlPersistFileExt_H

#include "exports.h"
#include "PerlUnknownExt.h"

typedef perlUnknownExt(IPersistFile) PerlPersistFileImpl;

class WIN32SHELLEXTAPI PerlPersistFileExt : public PerlPersistFileImpl
{
  PerlPersistFileExt(const PerlPersistFileExt&);
  PerlPersistFileExt& operator=(const PerlPersistFileExt&); // declared but never defined, i don't want the compiler to generate this for me.
public:
  PerlPersistFileExt(PerlShellExt *master);
  ~PerlPersistFileExt();

  // IPersist
  STDMETHOD(GetClassID)(CLSID *pClassID);

  // IPersistFile
  STDMETHOD(IsDirty)();
  STDMETHOD(Load)(LPCOLESTR pszFileName, DWORD dwMode);
  STDMETHOD(Save)(LPCOLESTR pszFileName,BOOL fRemember);
  STDMETHOD(SaveCompleted)(LPCOLESTR pszFileName);
  STDMETHOD(GetCurFile)(LPOLESTR *ppszFileName);

  wchar_t *CurFile();
private:
  wchar_t m_filename[MAX_PATH];
};

#endif



