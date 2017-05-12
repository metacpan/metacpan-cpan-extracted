// -*- c++ -*-

/*
 * Implementation of IColumnProvider that calls Perl scripts.
 * This allows you to implement Perl script that provide their own columns
 * to the Shell.
 *
 *
 * (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
 *
 * See:
 *    http://msdn.microsoft.com/msdnmag/issues/0300/w2kui/w2kui.asp
 */

#ifndef _PerlColumnProviderExt_H
#define _PerlColumnProviderExt_H

#include <shlobj.h>

#include "PerlUnknownExt.h"
#include "exports.h"

class PerlShellExt;

typedef perlUnknownExt(IColumnProvider) PerlColumnProviderImpl;

class WIN32SHELLEXTAPI PerlColumnProviderExt : public PerlColumnProviderImpl
{
  PerlColumnProviderExt(const PerlColumnProviderExt&);
  PerlColumnProviderExt& operator=(const PerlColumnProviderExt&);

  friend class PerlShellExt;
public:
  PerlColumnProviderExt(PerlShellExt *master);
  ~PerlColumnProviderExt();
  
  class ColumnInfo {
    ColumnInfo(const ColumnInfo&);
    ColumnInfo& operator=(const ColumnInfo&);
  public:
    ColumnInfo();
    ~ColumnInfo();

    WCHAR *title; // allocated at definition loading time by PerlShellExtClassFactory
    WCHAR *description;
    char *callback; // points to the string data loaded by perl.
  };

  // *** IColumnProvider methods ***
  STDMETHOD (Initialize)(LPCSHCOLUMNINIT psci);
  STDMETHOD (GetColumnInfo)(DWORD dwIndex, SHCOLUMNINFO *psci);
  STDMETHOD (GetItemData)(LPCSHCOLUMNID pscid, LPCSHCOLUMNDATA pscd, VARIANT *pvarData);

  // called back by the factory with the results of the perl call.
  void SetColumnInfo(DWORD sz, ColumnInfo *cols); // transfers ownership of 'cols' to 'this'.

private:
  WCHAR *m_folder;

  //DWORD m_current; // tracks the last accessed index in a series of GetColumnInfo calls.
  DWORD m_ncols;
  ColumnInfo *m_cols;
};

#endif
