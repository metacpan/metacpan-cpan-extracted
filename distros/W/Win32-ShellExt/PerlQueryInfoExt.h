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
 * http://www.codeguru.com/shell/infotip.shtml
 */

#ifndef _PerlQueryInfoExt_H
#define _PerlQueryInfoExt_H

#include <shlobj.h>

#include "exports.h"
#include "PerlUnknownExt.h"

typedef perlUnknownExt(IQueryInfo) PerlQueryInfoImpl;

class WIN32SHELLEXTAPI PerlQueryInfoExt : public PerlQueryInfoImpl
{
  PerlQueryInfoExt(const PerlQueryInfoExt&);
  PerlQueryInfoExt& operator=(const PerlQueryInfoExt&);

  friend class PerlShellExt;
public:
  PerlQueryInfoExt(PerlShellExt *master);
  ~PerlQueryInfoExt();

  // *** IQueryInfo methods ***
  STDMETHOD(GetInfoTip)(DWORD dwFlags, WCHAR **ppwszTip);
  STDMETHOD(GetInfoFlags)(DWORD *pdwFlags);

  HRESULT GetClassID(CLSID *pClassID);
};

#endif
