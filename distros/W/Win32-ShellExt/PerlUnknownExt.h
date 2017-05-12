// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlUnknownExt_H
#define _PerlUnknownExt_H

class PerlShellExt;

template <class T, const CLSID* Tiid>
class PerlUnknownExt : public T
// PerlUnknownExt is a template base class for implementation of the various shell
// extensions, for each interface that needs to be implemented I, just create a subclass of PerlUnknownExt<I>
// (that provides the implementation of the IUnknown methods) that implements the methods of I.
//
{
  friend class PerlShellExtClassFactory;

  PerlUnknownExt(const PerlUnknownExt&);
  PerlUnknownExt& operator=(const PerlUnknownExt&);
public:
  PerlUnknownExt(PerlShellExt *master) : m_master(master) {}
  virtual ~PerlUnknownExt() = 0 {}

  // *** IUnknown methods ***
  STDMETHOD(QueryInterface) (REFIID riid, void **ppv) { 
    if(ppv==0) return E_INVALIDARG;
    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, *Tiid)) {
      AddRef();
      *ppv = this;
      return NOERROR;
    } 
    return m_master->QueryInterface(riid,ppv);
  }
  STDMETHOD_(ULONG,AddRef) ()  { return m_master->AddRef (); }
  STDMETHOD_(ULONG,Release) () { return m_master->Release(); }
  
protected:
  PerlShellExt *m_master;
};

// easy short hand to instantiate this template
#define perlUnknownExt(X) PerlUnknownExt<X,&IID_##X>

#endif
