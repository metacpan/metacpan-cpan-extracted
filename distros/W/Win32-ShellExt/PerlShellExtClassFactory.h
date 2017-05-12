/* -*- c++ -*- // old habits are hard to change ;-)
 *
 *
 * PerlShellExtClassFactory.cpp
 *
 * This is the main code for the perl-win32-shellext Shell extension DLL.
 * It embeds the perl interpreter into an extension to the Windows Explorer (also
 * called the Windows Shell). This is never used as an extension per se, but
 * always through some perl code that extension writers provide.
 * 
 * Each script that is to be a shell extension must have its own CLSID : this is really the
 * CLSID of the shell extension, but unlike other shell extensions, these will always
 * use the same extension DLL, but have an additionnal key that allows the DLL to locate
 * the perl script it should invoke.
 *
 * To accomplish this, each extension script must be a subclass of Win32::ShellExt, which
 * provides some base capabilities, such as installing/deinstalling the extension, and also
 * defining a calling convention for the methods that are going to be called from the Explorer.
 *
 *
 * Look for 'FIXME' for places where things can be made better.
 *
 *
 * (C) 2001-2002 Jean-Baptiste Nivoit.
 */

#ifndef _PerlShellExtClassFactory_H
#define _PerlShellExtClassFactory_H

#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
#include <XSUB.h>

#include "exports.h"

class PerlShellExt; // need a forward reference for methods that call into perl.
class PerlShellExtCtxtMenu;
class PerlQueryInfoExt;
class PerlColumnProviderExt;

// this class factory object creates context menu handlers for Windows 95 shell
class WIN32SHELLEXTAPI PerlShellExtClassFactory : public IClassFactory
// we have one instance of this class factory per CLSID that we handle.
{
protected:
  ULONG	m_cRefs;
public:
  static PerlInterpreter *m_interp; /* initially i made this a per-instance data member,
				     * but i may not have defined multiplicity properly in
				     * the way i built the perl interpreter, so that wouldn't
				     * work (well it would, but it would often freeze when
				     * invoking several commands on different interpreters).
				     */
protected:
  CLSID m_clsid;
  char *m_pkg;
  char **m_methods;
  int m_sz;
  
public:
  const CLSID& clsid() { return m_clsid; } 

  SV *CreatePerlObject();
  PerlInterpreter *interp() { return PerlShellExtClassFactory::m_interp; }
  void SetContext(); // attention, i did not use 'set_context' as an identifier on purpose, to avoid clashes with perl's.
  
  struct QueryInfo {
    QueryInfo(int c, char **f, SV *o) : m_count(c), m_files(f), m_obj(o) {}
    ~QueryInfo() {}
    
    int m_count;
    char **m_files;
    SV *m_obj;
  };

  PerlShellExtClassFactory(REFCLSID clsid, char *pkg);
  ~PerlShellExtClassFactory();

  static PerlShellExtClassFactory *FindClassFactory(REFCLSID rclsid);

  //IUnknown members
  STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
  STDMETHODIMP_(ULONG)	AddRef();
  STDMETHODIMP_(ULONG)	Release();

  //IClassFactory members
  STDMETHODIMP		CreateInstance(LPUNKNOWN, REFIID, LPVOID FAR *);
  STDMETHODIMP		LockServer(BOOL);

  static PerlShellExtClassFactory *GetScriptForCLSID(REFCLSID clsid);
  static PerlShellExtClassFactory *AddScriptForCLSID(REFCLSID clsid, char *pkg);

private:
  class ScriptElem {
    ScriptElem(const ScriptElem&);
    ScriptElem& operator=(const ScriptElem&);
  public:
    ScriptElem(REFCLSID clsid, char *pkg, class ScriptElem *nx=0);
    ~ScriptElem();
    PerlShellExtClassFactory *find(REFCLSID clsid);

    PerlShellExtClassFactory *m_factory;
    class ScriptElem *m_next;
  };
  static ScriptElem *m_scripts; // this must be a class variable (so as not to recalculate known scripts accross instances of PerlShellExtClassFactory

public:
  static void cleanup();

  static int CLSID2String(REFCLSID clsid, char *buf);
  static const char *iid2string(REFIID riid);

  unsigned char SubPackageOf(char *super);
  
  STDMETHODIMP			QueryContextMenu(PerlShellExtCtxtMenu *obj,
						 HMENU hMenu,
	                                         UINT indexMenu, 
	                                         UINT idCmdFirst,
						 UINT idCmdLast, 
						 UINT uFlags);

  STDMETHODIMP DoCommand(PerlShellExtCtxtMenu *obj,
			 HWND hParent,
			 LPCSTR pszWorkingDir,
			 LPCSTR pszCmd,
			 LPCSTR pszParam,
			 int iShowCmd, UINT idCmd);

  // for IQueryInfo
  STDMETHODIMP GetInfoTip(IMalloc *iMalloc, SV *obj, wchar_t *filename, DWORD dwFlags, WCHAR **ppwszTip);

  // for ICopyHook
  UINT CopyCallback (SV *obj, HWND hwnd, char *wFunc, char *wFlags, LPCSTR pszSrcFile, DWORD dwSrcAttribs, LPCSTR pszDestFile, DWORD dwDestAttribs);
  
  // for IColumnProvider
  void LoadColumnProvider(PerlColumnProviderExt *p);
  HRESULT GetItemData(SV *obj, char *cb, LPCSHCOLUMNDATA pscd, VARIANT *pvarData);



};
typedef PerlShellExtClassFactory *LPShellEXTCLASSFACTORY;

#endif



