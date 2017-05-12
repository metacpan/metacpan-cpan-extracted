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

#include <shlobj.h>
#include <tchar.h> // _tcscpy
#include "PerlColumnProviderExt.h"
#include "debug.h"

PerlColumnProviderExt::PerlColumnProviderExt(PerlShellExt *master) : PerlColumnProviderImpl(master), 
  m_folder(0), m_ncols(0), m_cols(0)
{
  master->factory()->LoadColumnProvider(this);
}
PerlColumnProviderExt::~PerlColumnProviderExt() { 
  m_master=0; 
  if(m_folder!=0) free(m_folder); 

  // FIXME add deletion of col info.
}

HRESULT PerlColumnProviderExt::Initialize(LPCSHCOLUMNINIT psci)
{
  //USES_CONVERSION;
  //_tcscpy(m_folder, OLE2T((WCHAR*)psci->wszFolder)); 

//FIXME
  //_tcscpy(m_folder, (WCHAR*)psci->wszFolder);
  if(m_folder!=0) free(m_folder);
  m_folder = _wcsdup((WCHAR*)psci->wszFolder);
  EXTDEBUG((f,"PerlColumnProviderExt::Initialize %S\n",m_folder));
  return S_OK;
}
HRESULT PerlColumnProviderExt::GetColumnInfo(DWORD dwIndex, SHCOLUMNINFO *psci)
{
  EXTDEBUG((f,"PerlColumnProviderExt::GetColumnInfo %d %d\n",dwIndex,m_ncols));
  if(psci==0) 
    return E_INVALIDARG;

  if(dwIndex>=m_ncols)
    return S_FALSE;
  
	// Now fills out the SHCOLUMNINFO structure to let the 
	// shell know about general-purpose features of the column

  psci->scid.fmtid = m_master->clsid();
  psci->scid.pid = 25+dwIndex;

  // these are not customizable by the perl code yet.
  psci->vt = VT_LPSTR;			// data is LPSTR
  psci->fmt = LVCFMT_LEFT;		// left alignment
#define DEFWIDTH 16
  psci->cChars = DEFWIDTH;		// default width in chars
	
  // Other flags
  psci->csFlags = SHCOLSTATE_TYPE_STR;
		
  EXTDEBUG((f,"PerlColumnProviderExt::GetColumnInfo (%S,%S)\n",m_cols[dwIndex].title,m_cols[dwIndex].description));
  // Caption and description
  wcsncpy(psci->wszTitle, m_cols[dwIndex].title, MAX_COLUMN_NAME_LEN);
  wcsncpy(psci->wszDescription, m_cols[dwIndex].description, MAX_COLUMN_DESC_LEN);
  return S_OK;
}
HRESULT PerlColumnProviderExt::GetItemData(LPCSHCOLUMNID pscid, LPCSHCOLUMNDATA pscd, VARIANT *pvarData)
{
  int idx = pscid->pid-25;
  EXTDEBUG((f,"PerlColumnProviderExt::GetItemData %d\n",idx));
  if(idx>=m_ncols) return E_FAIL;
  
  // note we ignore the SHCDF_UPDATEITEM flag value in 'pscd', thus explicitly not supporting caching of the 
  // informations in the perl code.
  char *cb = m_cols[idx].callback;

  return m_master->factory()->GetItemData(m_master->Object(),cb,pscd,pvarData);
}

void PerlColumnProviderExt::SetColumnInfo(DWORD sz, ColumnInfo *cols) {
  m_ncols = sz;
  if(m_cols!=0) delete [] m_cols;
  m_cols = cols;
}

PerlColumnProviderExt::ColumnInfo::ColumnInfo() :
  title(0), description(0), callback(0)
{}
PerlColumnProviderExt::ColumnInfo::~ColumnInfo() {}
