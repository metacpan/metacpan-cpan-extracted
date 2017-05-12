// -*- c++ -*-
/*
 * (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
 */
//
// Provides an IDataObject interface for a specific class type. 
// The shell passes this interface to the OLE DoDragDrop function.
//
#include "PerlDataObjectExt.h"

PerlDataObjectExt::PerlDataObjectExt(PerlShellExt *master) : PerlDataObjectImpl(master) {}
PerlDataObjectExt::~PerlDataObjectExt() {}

HRESULT PerlDataObjectExt::GetData(FORMATETC *pformatetcIn,
				   STGMEDIUM *pmedium)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::GetDataHere(FORMATETC *pformatetc,
				       STGMEDIUM *pmedium)
{			   
  return E_NOTIMPL;	   
}			   
       			   
HRESULT PerlDataObjectExt::QueryGetData(FORMATETC *pformatetc)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::GetCanonicalFormatEtc(FORMATETC *pformatectIn,
						 FORMATETC *pformatetcOut)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::SetData(FORMATETC *pformatetc,
				   STGMEDIUM *pmedium,
				   BOOL fRelease)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::EnumFormatEtc(DWORD dwDirection,
					 IEnumFORMATETC **ppenumFormatEtc)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::DAdvise(FORMATETC *pformatetc,
				   DWORD advf,
				   IAdviseSink *pAdvSink,
				   DWORD *pdwConnection)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::DUnadvise(DWORD dwConnection)
{			   
  return E_NOTIMPL;	   
}			   
        		   
HRESULT PerlDataObjectExt::EnumDAdvise(IEnumSTATDATA **ppenumAdvise)
{
  return E_NOTIMPL;
}

        
