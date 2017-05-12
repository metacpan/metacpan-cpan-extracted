// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlMenu_H
#define _PerlMenu_H

class PerlMenuClassFactory : public IClassFactory
// we have one instance of this class factory per CLSID that we handle.
{
  ULONG	m_cRefs;

  PerlMenuClassFactory(const PerlMenuClassFactory&);
  PerlMenuClassFactory& operator=(const PerlMenuClassFactory&);
public:
  PerlMenuClassFactory();
  ~PerlMenuClassFactory();

  //IUnknown members
  STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
  STDMETHODIMP_(ULONG)	AddRef();
  STDMETHODIMP_(ULONG)	Release();

  //IClassFactory members
  STDMETHODIMP		CreateInstance(LPUNKNOWN, REFIID, LPVOID FAR *);
  STDMETHODIMP		LockServer(BOOL);
};

#endif

