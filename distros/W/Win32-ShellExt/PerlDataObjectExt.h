// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
// 
// a data handler implements IPersistFile & IDataObject, it exposes an object's data to drop-target objects.
//

#ifndef _PerlDataObjectExt_H
#define _PerlDataObjectExt_H

#include <objidl.h>

#include "PerlUnknownExt.h"
typedef perlUnknownExt(IDataObject) PerlDataObjectImpl;

class PerlDataObjectExt : public PerlDataObjectImpl
{
  PerlDataObjectExt(const PerlDataObjectExt&);
  PerlDataObjectExt& operator=(const PerlDataObjectExt&);

public:
  PerlDataObjectExt(PerlShellExt *master);
  ~PerlDataObjectExt();

  HRESULT STDMETHODCALLTYPE GetData(FORMATETC *pformatetcIn,
				    STGMEDIUM *pmedium);
        
  HRESULT STDMETHODCALLTYPE GetDataHere(FORMATETC *pformatetc,
					STGMEDIUM *pmedium);
        
  HRESULT STDMETHODCALLTYPE QueryGetData(FORMATETC *pformatetc);
        
  HRESULT STDMETHODCALLTYPE GetCanonicalFormatEtc(FORMATETC *pformatectIn,
						  FORMATETC *pformatetcOut);
        
  HRESULT STDMETHODCALLTYPE SetData(FORMATETC *pformatetc,
				    STGMEDIUM *pmedium,
				    BOOL fRelease);
        
  HRESULT STDMETHODCALLTYPE EnumFormatEtc(DWORD dwDirection,
					  IEnumFORMATETC **ppenumFormatEtc);
        
  HRESULT STDMETHODCALLTYPE DAdvise(FORMATETC *pformatetc,
				    DWORD advf,
				    IAdviseSink *pAdvSink,
				    DWORD *pdwConnection);
        
  HRESULT STDMETHODCALLTYPE DUnadvise(DWORD dwConnection);
        
  HRESULT STDMETHODCALLTYPE EnumDAdvise(IEnumSTATDATA **ppenumAdvise);
        
};

#endif


