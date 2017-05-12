// -*- c++ -*-

/*
 * Implementation of IQueryInfo and IPersist/IPersistFile
 * that calls Perl scripts.
 * This allows you to implement Perl script that put their own text
 * into the 'info tip' of the Shell.
 *
 *
 * (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
 *
 * See:
 * http://community.borland.com/article/0,1410,22987,00.html
 * http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/Shell/IFaces/IQueryInfo/IQueryInfo.asp
 * http://delphi.about.com/library/bluc/text/uc071701a.htm
 * http://msdn.microsoft.com/msdnmag/issues/0300/w2kui/w2kui.asp
 */

#include "PerlQueryInfoExt.h"
#include "Win32ShellExt.h"

#include <shlobj.h>

// " 'this' : used in base member initializer list " is not a valid warning, as what follows is legal C++
#pragma warning(disable : 4355)

PerlQueryInfoExt::PerlQueryInfoExt(PerlShellExt *master) : PerlQueryInfoImpl(master) {}
PerlQueryInfoExt::~PerlQueryInfoExt() {}

HRESULT PerlQueryInfoExt::GetClassID(CLSID *pClassID)
{
  if(pClassID==0) return E_POINTER;
  *pClassID = m_master->clsid();
  return S_OK;
}

HRESULT PerlQueryInfoExt::GetInfoTip(DWORD dwFlags, WCHAR **ppwszTip)
{
  if(ppwszTip==0) return E_POINTER;

  LPMALLOC iMalloc=0;
  HRESULT rc = SHGetMalloc(&iMalloc);
  if(FAILED(rc)) return rc;
  if(iMalloc==0) return E_POINTER;
#if 0
  wchar_t *s = L"un autre test a la con";
  size_t len = wcslen(s);
  //ec985cab-9c6c-49f5-b2ce-561e04d54e3d
  *ppwszTip = (WCHAR*)iMalloc->Alloc(sizeof(OLECHAR)*len);
  memcpy(*ppwszTip,s,len*sizeof(wchar_t));
#else
  
  SV *obj = m_master->Object();
  wchar_t *filename = m_master->FindPersistFileExt()->CurFile();
  m_master->factory()->GetInfoTip(iMalloc,obj,filename,dwFlags,ppwszTip);
  
  /*
  {
      FILE *f=fopen("d:\\log8.txt","a+");
      if(f!=0) { 
	WCHAR *c = *ppwszTip;
	fwprintf(f,L"%d : %S\n",wcslen(c),c);
	fclose(f); 
      }
  }
  */
#endif
  
 CLEANUP:
  iMalloc->Release();
  return S_OK;
}
HRESULT PerlQueryInfoExt::GetInfoFlags(DWORD *pdwFlags)
{
  if(pdwFlags==0) return E_POINTER;
  *pdwFlags=QITIPF_DEFAULT;
  return S_OK;
}
