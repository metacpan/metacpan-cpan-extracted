// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
// 
// you might want to look at:
// http://www.codeproject.com/atl/ctxmenuapp.asp
// (i haven't yet).
// 

//
// Also note that alternatively, it's possible to configure the Shell
// to expose additionnal commands in the context menu for directories, but adding
// to the registry : Classes/Directory/shell/<command name>/command=.exe
// This only works for external commands (i.e. the shell spawns a separate executable 
// with the command line specified in the registry key quoted above.
//

#include "PerlShellExtCtxtMenu.h"

PerlShellExtCtxtMenu::PerlShellExtCtxtMenu(PerlShellExt *master) 
  : m_count(0), m_files(0), m_dnd(0), PerlContextMenuImpl(master)
{
  SV *obj = master->Object();
  if(obj==0) return;
  
  m_dnd = master->factory()->SubPackageOf("Win32::ShellExt::DragAndDropHandler");
}

STDMETHODIMP PerlShellExtCtxtMenu::QueryContextMenu(HMENU hMenu,
					    UINT indexMenu,
					    UINT idCmdFirst,
					    UINT idCmdLast,
					    UINT uFlags)
{
  // handle DND handler case specially, as we're required to 
  if ( IsDndHandler() && (uFlags & CMF_DEFAULTONLY ))
    {
      return MAKE_HRESULT ( SEVERITY_SUCCESS, FACILITY_NULL, 0 );
    }

  m_master->SetContext();
#if 0 // this is for testing only
  UINT idCmd = idCmdFirst;
  char szMenuText[64];
  BOOL bAppendItems=TRUE;
  char *text = "jb's test";
  if ((uFlags & 0x000F) == CMF_NORMAL)  //Check == here, since CMF_NORMAL=0
    {
      lstrcpy(szMenuText, text /*(Normal File)*/);
    }
  else
    if (uFlags & CMF_VERBSONLY)
      {
	lstrcpy(szMenuText, text /*(Shortcut File)*/);
      }
    else
      if (uFlags & CMF_EXPLORE)
        {
	  lstrcpy(szMenuText, text /*(Normal File right click in Explorer)*/);
        }
      else
        if (uFlags & CMF_DEFAULTONLY)
	  {
            bAppendItems = FALSE;
	  }
	else
	  {
            char szTemp[32];

            wsprintf(szTemp, "uFlags==>%d\r\n", uFlags);
            bAppendItems = FALSE;
	  }

  if (bAppendItems)
    {
      InsertMenu(hMenu, indexMenu++, MF_SEPARATOR|MF_BYPOSITION, 0, NULL);
        
      InsertMenu(hMenu,
		 indexMenu++,
		 MF_STRING|MF_BYPOSITION,
		 idCmd++,
		 szMenuText);
        
      return ResultFromShort(idCmd-idCmdFirst); //Must return number of menu
      //items we added.
    }

  return NOERROR;


#else
  EXTDEBUG((f,"PerlShellExt::QueryContextMenu this=0x%x\n",(long)this));

  // have to use an intermediary object to pass this info, cause i can't pass 'this' directly
  // as it has several addresses (because of multiple inheritance), and the compiler ends up passing
  // the wrong one..
  
  return m_master->factory()->QueryContextMenu(this,hMenu,indexMenu,idCmdFirst,idCmdLast,uFlags);
#endif
}

STDMETHODIMP PerlShellExtCtxtMenu::InvokeCommand(LPCMINVOKECOMMANDINFO lpcmi)
{
  HRESULT hr = E_INVALIDARG;

  //If HIWORD(lpcmi->lpVerb) then we have been called programmatically
  //and lpVerb is a command that should be invoked.  Otherwise, the shell
  //has called us, and LOWORD(lpcmi->lpVerb) is the menu ID the user has
  //selected.  Actually, it's (menu ID - idCmdFirst) from QueryContextMenu().
  if (!HIWORD(lpcmi->lpVerb))
    {
      UINT idCmd = LOWORD(lpcmi->lpVerb);

      hr = DoCommand(lpcmi->hwnd,
		     lpcmi->lpDirectory,
		     lpcmi->lpVerb,
		     lpcmi->lpParameters,
		     lpcmi->nShow,idCmd);
    }
  return hr;
}

STDMETHODIMP PerlShellExtCtxtMenu::DoCommand(HWND hParent,
				     LPCSTR pszWorkingDir,
				     LPCSTR pszCmd,
				     LPCSTR pszParam,
				     int iShowCmd, UINT idCmd)
{
      //m_factory->SetContext();
  return m_master->factory()->DoCommand(this,hParent,pszWorkingDir,pszCmd,pszParam,iShowCmd,idCmd);
  //return NOERROR;
}


void PerlShellExtCtxtMenu::cleanup() {
  if(m_count!=0)
    {
      for(UINT i=0;i<m_count;i++)
	delete [] m_files[i];
      delete [] m_files;
    }
  m_files = 0;
  m_count = 0;
}

PerlShellExtCtxtMenu::~PerlShellExtCtxtMenu()
{
  
//  #ifdef WITH_PERL
//    SvREFCNT_dec(m_obj);
//    m_obj=0;
//  #endif
  cleanup();
}

STDMETHODIMP PerlShellExtCtxtMenu::Initialize(LPCITEMIDLIST pIDFolder, 
				      LPDATAOBJECT pDataObj, 
				      HKEY hRegKey)
{ 
   // FIXME maybe we need to support accumulation of data from the DataObject?
  if (pDataObj) 
    {       
      // Get the file associated with this object, if applicable.
      STGMEDIUM   medium;
      FORMATETC   fe = {CF_HDROP, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};

      HRESULT rc = pDataObj->GetData(&fe, &medium);
      if(SUCCEEDED(rc))
	{
	  char *s=0;
	  UINT i=0, uCount=0;
	  // Get the file name from the HDROP.
	  uCount = DragQueryFile((HDROP)medium.hGlobal, (UINT)-1, NULL, 0);
	  char m_szFile[256];
			
	  // 'uCount' is the number of files dropped...
	  cleanup();
	  if(uCount!=0)
	    {
	      m_count=uCount;
	      m_files = new char*[m_count];
	    }

	  for(;i<uCount;i++)
	    {
	      // FIXME here i can do better than this, by allocating 'm_files[i]' to a fixed size and copying the string 
	      // value in place, instead of having to perform a copy..
	      UINT len=DragQueryFile((HDROP)medium.hGlobal, i, m_szFile, sizeof(m_szFile));
	      m_files[i] = new char[len+1];
	      memcpy(&m_files[i][0],m_szFile,len);
	      m_files[i][len]='\0';
	      EXTDEBUG((f,"file[%d]='%s'\n",i,m_szFile));
	    }
	  ReleaseStgMedium(&medium);
	}
    }

  return NOERROR; 
} 

void PerlShellExtCtxtMenu::Initialize(int c, char *items[])
  // This does the same as the other Initialize method, except it does not require selection in the explorer of files.
  // This is for testing purposes only.
{
  EXTDEBUG((f,"this=0x%x\n",(long)this));

  //EXTDEBUG((f,"IContextMenu=0x%x, IShellExtInit=0x%x\n",(IContextMenu*)this,(IShellExtInit*)this);

  if(c<1) return;
  m_count = c;
  m_files = new char*[c];
  for(int i=0;i<c;i++) {
    int len = strlen(items[i]);
    m_files[i] = new char[len+1];
    memcpy(&m_files[i][0],items[i],len);
    m_files[i][len]='\0';
  }
}

STDMETHODIMP PerlShellExtCtxtMenu::GetCommandString(UINT idCmd,
					    UINT uFlags,
					    UINT FAR *reserved,
					    LPSTR pszName,
					    UINT cchMax)
{
  switch (idCmd)
    {
    case 0:
      lstrcpy(pszName, "Rename special"); // FIXME read the 'TEXT' variable in the package instead.
      break;

    }

  return NOERROR;
}

void PerlShellExtCtxtMenu::insert_command(HMENU hMenu, char *text,
					  UINT& indexMenu,
					  UINT& idCmd,
					  UINT idCmdFirst,
					  UINT idCmdLast,
					  UINT uFlags, UINT with_sep)
{
  char szMenuText[64];
  BOOL bAppendItems=TRUE;

    if ((uFlags & 0x000F) == CMF_NORMAL)  //Check == here, since CMF_NORMAL=0
      {
	lstrcpy(szMenuText, text /*(Normal File)*/);
      }
    else
      if (uFlags & CMF_VERBSONLY)
	{
	  lstrcpy(szMenuText, text /*(Shortcut File)*/);
	}
      else
	if (uFlags & CMF_EXPLORE)
	  {
	    lstrcpy(szMenuText, text /*(Normal File right click in Explorer)*/);
	  }
	else
	  if (uFlags & CMF_DEFAULTONLY)
	    {
	      bAppendItems = FALSE;
	    }
	  else
	    {
	      //char szTemp[32];
	      //wsprintf(szTemp, "uFlags==>%d\r\n", uFlags);
	      bAppendItems = FALSE;
	    }
    
    if (bAppendItems)
      {
	InsertMenu(hMenu,
		   indexMenu++,
		   MF_STRING|MF_BYPOSITION,
		   idCmd++,
		   szMenuText);
        
	if(with_sep)
	  InsertMenu(hMenu, indexMenu++, MF_SEPARATOR|MF_BYPOSITION, 0, NULL);
        
      }
}
