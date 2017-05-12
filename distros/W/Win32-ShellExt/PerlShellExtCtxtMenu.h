// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlShellExtCtxtMenu_H
#define _PerlShellExtCtxtMenu_H

#include "exports.h"
#include "PerlUnknownExt.h"
class PerlShellExt;

typedef perlUnknownExt(IContextMenu) PerlContextMenuImpl;

// this is the actual OLE Shell context menu handler
class WIN32SHELLEXTAPI PerlShellExtCtxtMenu : public PerlContextMenuImpl
{
  // these are declared but never defined, i don't want the compiler to generate useless code for me, thank you.
  PerlShellExtCtxtMenu(const PerlShellExtCtxtMenu&);
  PerlShellExtCtxtMenu& operator=(const PerlShellExtCtxtMenu&);

  //friend class PerlShellExtCtxtMenuClassFactory;
  //friend class PerlShellExtInit;
  friend class PerlShellExt;
public:

  UINT m_count;
  char **m_files;

  inline SV *Object() { return m_master->Object(); }
  STDMETHODIMP DoCommand(HWND hParent, 
			 LPCSTR pszWorkingDir, 
			 LPCSTR pszCmd,
			 LPCSTR pszParam, 
			 int iShowCmd, UINT idCmd);

public:
  PerlShellExtCtxtMenu(PerlShellExt *master);
  ~PerlShellExtCtxtMenu();

  //IContextMenu members
  STDMETHODIMP			QueryContextMenu(HMENU hMenu,
	                                         UINT indexMenu, 
	                                         UINT idCmdFirst,
						 UINT idCmdLast, 
						 UINT uFlags);

  STDMETHODIMP			InvokeCommand(LPCMINVOKECOMMANDINFO lpcmi);

  STDMETHODIMP			GetCommandString(UINT idCmd, 
	                                         UINT uFlags, 
	                                         UINT FAR *reserved, 
						 LPSTR pszName, 
						 UINT cchMax);

  //IShellExtInit methods
  STDMETHODIMP		    Initialize(LPCITEMIDLIST pIDFolder, 
				       LPDATAOBJECT pDataObj, 
				       HKEY hKeyID);

  // this method is used for testing only.
  void Initialize(int c, char *items[]);
  
  unsigned char IsDndHandler() { return m_dnd; }

  void insert_command(HMENU hMenu, char *text, UINT& indexMenu,
		      UINT& idCmd,
		      UINT idCmdFirst,
		      UINT idCmdLast,
		      UINT uFlags, UINT with_sep=1);
  
private: void cleanup();
  unsigned char m_dnd;
};
#endif
