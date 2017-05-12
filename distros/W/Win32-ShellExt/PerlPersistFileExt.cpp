// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlPersistFileExt.h"

PerlPersistFileExt::PerlPersistFileExt(PerlShellExt *master) : PerlPersistFileImpl(master) {
  memset(&m_filename[0],0,sizeof(TCHAR));
}
PerlPersistFileExt::~PerlPersistFileExt() {
}

HRESULT PerlPersistFileExt::IsDirty()
{
  return E_NOTIMPL;
}
HRESULT PerlPersistFileExt::Load(LPCOLESTR pszFileName, DWORD dwMode)
{
  //  m_filename = _wcsdup(pszFileName);
  wcscpy(&m_filename[0],pszFileName);
  return S_OK;
}
HRESULT PerlPersistFileExt::Save(LPCOLESTR pszFileName,BOOL fRemember)
{
  return E_NOTIMPL;
}
HRESULT PerlPersistFileExt::SaveCompleted(LPCOLESTR pszFileName)
{
  return E_NOTIMPL;
}
HRESULT PerlPersistFileExt::GetCurFile(LPOLESTR *ppszFileName)
{
  if(ppszFileName==0) return E_POINTER;
  if(m_filename==0) return E_FAIL;
  *ppszFileName = _wcsdup(&m_filename[0]);
  return S_OK;
}

HRESULT PerlPersistFileExt::GetClassID(CLSID *pClassID) 
{
  return m_master->FindQueryInfoExt()->GetClassID(pClassID);
}

wchar_t *PerlPersistFileExt::CurFile() {
  return &m_filename[0];
}
