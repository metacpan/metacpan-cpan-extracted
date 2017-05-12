// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlMenu.h"

class PerlMenuExtInit : public IShellExtInit
{
  PerlMenuExtInit(const PerlMenuExtInit&);
  PerlMenuExtInit& operator=(const PerlMenuExtInit&);
public:
  PerlMenuExtInit(class PerlMenuExt *master) : m_master(master) {}
  ~PerlMenuExtInit() {}
  
  //IUnknown members
  STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
  STDMETHODIMP_(ULONG)	AddRef();
  STDMETHODIMP_(ULONG)	Release();

  //IShellExtInit methods
  STDMETHODIMP		    Initialize(LPCITEMIDLIST pIDFolder, 
				       LPDATAOBJECT pDataObj, 
				       HKEY hKeyID);
private:
  PerlMenuExt *m_master; // here i can't have 'PerlMenuExt' as the master because i need to call PerlMenuExtCtxtMenu's methods from 'this'.
};

class PerlMenuExt : public IContextMenu
{
  ULONG	m_cRefs;
  PerlMenuExtInit m_init;
  UINT m_count;
  char **m_files;
private:
  PerlMenuExt(const PerlMenuExt&);
  PerlMenuExt& operator=(const PerlMenuExt&);
public:
  PerlMenuExt(PerlMenuExtClassFactory *factory, SV *obj);
  ~PerlMenuExt();
  
  //IUnknown members
  STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
  STDMETHODIMP_(ULONG)	AddRef();
  STDMETHODIMP_(ULONG)	Release();

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

public:
  STDMETHODIMP		    Initialize(LPCITEMIDLIST pIDFolder, 
				       LPDATAOBJECT pDataObj, 
				       HKEY hKeyID);

};

STDMETHODIMP PerlMenuExtInit::QueryInterface(REFIID riid, LPVOID FAR *ppv) {
  return m_master->QueryInterface(riid,ppv);
}
STDMETHODIMP_(ULONG)	PerlMenuExtInit::AddRef() { return m_master->AddRef(); }
STDMETHODIMP_(ULONG)	PerlMenuExtInit::Release() { return m_master->Release(); }

STDMETHODIMP		    PerlMenuExtInit::Initialize(LPCITEMIDLIST pIDFolder, 
							LPDATAOBJECT pDataObj, 
							HKEY hKeyID)
{
  return m_master->Initialize(pIDFolder,pDataObj,hKeyID);
}

// " 'this' : used in base member initializer list " is not a valid warning, as what follows is legal C++
#pragma warning(disable : 4355)
PerlMenuExt::PerlMenuExt() : m_cRefs(0L), m_init(this), m_count(0), m_files(0) {}
PerlMenuExt::~PerlMenuExt() {}
  
STDMETHODIMP PerlMenuExt::QueryInterface(REFIID riid, LPVOID FAR ppv)
{
  HRESULT rc=S_OK;
  if(ppv==0) return E_POINTER;
  *ppv = 0;

  if(IsEqualIID(riid, IID_IUnknown))
    {
      *ppv = this;
    }
  else {
    if (IsEqualIID(riid, IID_IShellExtInit))
      *ppv = (LPSHELLEXTINIT)&m_init;
    else if (IsEqualIID(riid, IID_IContextMenu))
      *ppv = (LPCONTEXTMENU)this;
  }
  
  if (*ppv)
    {
      AddRef(); // equivalent to AddRef()-ing whatever we stored in *ppv...
      return NOERROR;
    }
  
  return E_NOINTERFACE;
}
STDMETHODIMP_(ULONG)	PerlMenuExt::AddRef()
{
  return ++m_cRefs;
}
STDMETHODIMP_(ULONG)	PerlMenuExt::Release()
{
  if (--m_cRefs)
    return m_cRefs;

  delete this;
  return 0L;
}

STDMETHODIMP			PerlMenuExt::QueryContextMenu(HMENU hMenu,
	                                         UINT indexMenu, 
	                                         UINT idCmdFirst,
						 UINT idCmdLast, 
						 UINT uFlags)
{}

STDMETHODIMP			PerlMenuExt::InvokeCommand(LPCMINVOKECOMMANDINFO lpcmi)
{}
STDMETHODIMP			PerlMenuExt::GetCommandString(UINT idCmd, 
	                                         UINT uFlags, 
	                                         UINT FAR *reserved, 
						 LPSTR pszName, 
						 UINT cchMax)
{}
STDMETHODIMP		    PerlMenuExt::Initialize(LPCITEMIDLIST pIDFolder, 
				       LPDATAOBJECT pDataObj, 
				       HKEY hKeyID)
{}

PerlMenuClassFactory::PerlMenuClassFactory() : m_cRefs(0L)
{}
PerlMenuClassFactory::~PerlMenuClassFactory()
{}
  
STDMETHODIMP			PerlMenuClassFactory::QueryInterface(REFIID, LPVOID FAR *)
{
  *ppv = NULL;
  // Any interface on this object is the object pointer
  if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IClassFactory))
    {
      *ppv = (IClassFactory*)this;
      AddRef();
      return NOERROR;
    }

  return E_NOINTERFACE;
}
STDMETHODIMP_(ULONG)	PerlMenuClassFactory::AddRef()
{
  return ++m_cRefs;
}
STDMETHODIMP_(ULONG)	PerlMenuClassFactory::Release()
{
  if (--m_cRefs)
    return m_cRefs;

  delete this;
  return 0L;
}

STDMETHODIMP		PerlMenuClassFactory::CreateInstance(LPUNKNOWN pUnkOuter,
							     REFIID riid,
							     LPVOID *ppvObj)
{
  *ppvObj = NULL;

  if (pUnkOuter)
    return CLASS_E_NOAGGREGATION;

  PerlMenuExt *pPerlMenuExt = new PerlMenuExt();

  if (NULL == pPerlMenuExt)
    return E_OUTOFMEMORY;

  return pPerlMenuExt->QueryInterface(riid, ppvObj);
}
STDMETHODIMP		PerlMenuClassFactory::LockServer(BOOL)
{
  return NOERROR;
}




PerlShellExtClassFactory *PerlShellExtClassFactory::FindClassFactory(REFCLSID rclsid)
{
  if (IsEqualIID(rclsid, IID_IUnknown)) return 0; // don't really see how that could happen.
  
  PerlShellExtClassFactory *factory = PerlShellExtClassFactory::GetScriptForCLSID(rclsid); // linear search, could be improved (a hash mapping CLSID to factories..).
  if(factory!=0) return factory;
  
  // check that we really have an extension script registered for that CLSID:
  //HKEY key;
  char subkey[80]; // 80 ~79=strlen(CLSID)+ strlen("/CLSID//InProcServer32/PerlShellExtScript").
  memset(subkey,0,80);
  strcat(subkey,"CLSID\\");
  int where = CLSID2String(rclsid, subkey+6);
  strcat(subkey+6+/*skip over the non-null parts*/where,"\\InProcServer32");
  
  HKEY key;
  LONG rc = RegOpenKeyEx(HKEY_CLASSES_ROOT,subkey,0,KEY_READ|KEY_QUERY_VALUE,&key);
  
  DWORD type=REG_SZ;
  BYTE pkg[100];
  DWORD len= sizeof(pkg);
  rc = RegQueryValueExA(key,"PerlPackage",0,&type,pkg,&len);
  EXTDEBUG((f,"%s => %s\n",(const char*)subkey,(const char*)pkg));
  
  RegCloseKey(key);
  if(rc!=ERROR_SUCCESS) return 0;
  
//  \\PerlShellExtScript");
  
//    char path[50];
//    memset(path,0,sizeof(path));
//    LONG sz=50;
//    LONG rc = RegQueryValueA(HKEY_CLASSES_ROOT,subkey,&path[0], &sz);
//    EXTDEBUG((f,"%s => %s\n",subkey,path));
//    if(rc!=ERROR_SUCCESS) return 0;

//    where = strlen(subkey)-18;
//    subkey[where /*==strlen("PerlShellExtScript")*/]='\0';
//    strcat(subkey+where,"PerlPackage");

//    char pkg[50];
//    memset(pkg,0,sizeof(pkg));
//    sz=50; 
//    rc = RegQueryValueA(HKEY_CLASSES_ROOT,subkey,&pkg[0], &sz);
//    EXTDEBUG((f,"%s => %s\n",subkey,pkg);
//    if(rc!=ERROR_SUCCESS) return 0;
  
  return PerlShellExtClassFactory::AddScriptForCLSID(rclsid,(char*)pkg);
}

#ifdef WITH_PERL
SV *PerlShellExtClassFactory::CreatePerlObject() {
  HV *hv = newHV();
  SV *sv = /*sv_newmortal();*/ newSV(0);
  sv_setref_pv(sv,m_pkg,hv);
  return sv;
}

void PerlShellExtClassFactory::SetContext() {
  PERL_SET_CONTEXT(m_interp);
}

#endif

STDMETHODIMP PerlShellExtCtxtMenu::QueryContextMenu(HMENU hMenu,
					    UINT indexMenu,
					    UINT idCmdFirst,
					    UINT idCmdLast,
					    UINT uFlags)
{
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
  PerlShellExtClassFactory::QueryInfo qi(m_count,m_files
#ifdef WITH_PERL
					 ,Object()
#endif
					 );
  EXTDEBUG((f,"PerlShellExt::QueryContextMenu this=0x%x\n",(long)this));

  // have to use an intermediary object to pass this info, cause i can't pass 'this' directly
  // as it has several addresses (because of multiple inheritance), and the compiler ends up passing
  // the wrong one..
  
  return m_master->factory()->QueryContextMenu(&qi,hMenu,indexMenu,idCmdFirst,idCmdLast,uFlags);
#endif
}

STDMETHODIMP PerlShellExtClassFactory::QueryContextMenu(QueryInfo *obj,
							HMENU hMenu,
							UINT indexMenu,
							UINT idCmdFirst,
							UINT idCmdLast,
							UINT uFlags)
{
  EXTDEBUG((f,"PerlShellExtClassFactory::QueryContextMenu this=0x%x\n",(long)this));
  if(obj==0) {
    EXTDEBUG((f,"PerlShellExtClassFactory::QueryContextMenu inactive\n"));
    return NOERROR;
  }

  if(obj->m_count<=0) {
    EXTDEBUG((f,"PerlShellExtClassFactory::QueryContextMenu no selection\n"));
    return NOERROR;
  }

  EXTDEBUG((f,"PerlShellExtClassFactory::QueryContextMenu begin\n"));
  UINT idCmd = idCmdFirst;
  char szMenuText[64];
  BOOL bAppendItems=TRUE;

//    static int cnt=0;
//    if(cnt==0) {
//      cnt++;
//      return ResultFromShort(0);
//    }

  EXTDEBUG((f,"in QueryContextMenu\n"));

  unsigned char should_i_popup_the_menu=1;

#ifdef WITH_PERL
  /*
  {
    SV *sv = sv_newmortal();
    char *req = "require Win32::ShellExt::RenameMP3 2.0";
    sv_setpvn(sv, req, strlen(req));
    eval_sv(sv,G_DISCARD);
  }
  int errorp = SvTRUE(ERRSV);
  if(errorp) {
    printf("toto");
    }*/

  EXTDEBUG((f,"in perl stack setup 0\n"));  
  /*char *tmp = (char*)malloc(sizeof(char)*12);
    free(tmp);*/
  I32 ax=0;
  EXTDEBUG((f,"in perl stack setup 1\n"));  
  dSP;
  EXTDEBUG((f,"in perl stack setup 2\n"));  
  ENTER; 
  EXTDEBUG((f,"in perl stack setup 3\n"));
  SAVETMPS;
  EXTDEBUG((f,"in perl stack setup 4\n"));
  PUSHMARK(SP);
  EXTDEBUG((f,"in perl stack setup 5\n"));
  
  //XPUSHs(sv_2mortal(newSVpv("Win32::ShellExt::RenameMP3",0)));
  //call_method("Win32::ShellExt::RenameMP3::new",G_SCALAR);
//    HV *hv = newHV();
//    SV *sv = sv_newmortal();
//    sv_setref_pv(sv,"Win32::ShellExt::RenameMP3",hv);
//    XPUSHs(sv);

  //Perl_debstack();

  XPUSHs(obj->m_obj); // push the SV of the extension on the stack.
  int c = obj->m_count;
  for(unsigned int i=0;i<c;i++) {
    XPUSHs(sv_2mortal(newSVpv(obj->m_files[i],0)));
  }
  PUTBACK;
  EXTDEBUG((f,"before perl call %d\n",c));
//    char buf[100];
//    memset(buf,0,sizeof(buf));
//    //strcat(buf,"&");
//          //strcat(buf,m_pkg);
//    strcat(buf,"Win32::ShellExt::RenameMP3");
//    strcat(buf,"::query_context_menu");
//    int count = call_method(buf,G_SCALAR);

  int count = call_method("query_context_menu",G_SCALAR);
  SPAGAIN;
  SP -= count ;
  ax = (SP - PL_stack_base) + 1 ;
  //should_i_popup_the_menu = SvIV(ST(0));
  char *tmp = SvPV(ST(0),PL_na);
  should_i_popup_the_menu= tmp!=0 && *tmp!=0;

  PUTBACK;

  EXTDEBUG((f,"after perl call '%s'\n",tmp));
  FREETMPS; LEAVE;
#endif

  if(should_i_popup_the_menu==0)
    {
      EXTDEBUG((f,"not a file that i can handle, no menu!\n"));
      return ResultFromShort(0);
    }

  char *text = "&Rename using MP3 ID tag";
#ifdef WITH_PERL
  int len = strlen(m_pkg);
  //char *buf = (char*)_alloca((len+8)*sizeof(char));
  char buf[100];
  memset(buf,0,sizeof(buf));
  strcat(buf,m_pkg);
  strcat(buf+len,"::TEXT");
  SV *sv = perl_get_sv(buf, TRUE);
  text = SvPV(sv, PL_na);
#endif
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

      switch (idCmd)
        {
	case 0:
	  hr = DoCommand(lpcmi->hwnd,
			 lpcmi->lpDirectory,
			 lpcmi->lpVerb,
			 lpcmi->lpParameters,
			 lpcmi->nShow);
	  // FIXME here using other 'case's or something more dynamic would allow to have several commands handled by one extension.
	  break;
        }
    }
  return hr;
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

static char *errno2string(int errn)
{
  switch(errn)
    {
    case EACCES: return "EACCES"; break;
    case ENOENT: return "ENOENT"; break;
    default:     return "??????"; break;
    }
  return "";
}

STDMETHODIMP PerlShellExtCtxtMenu::DoCommand(HWND hParent,
				     LPCSTR pszWorkingDir,
				     LPCSTR pszCmd,
				     LPCSTR pszParam,
				     int iShowCmd)
{
  //m_factory->SetContext();
  return m_master->factory()->DoCommand(this,hParent,pszWorkingDir,pszCmd,pszParam,iShowCmd);
}

STDMETHODIMP PerlShellExtClassFactory::DoCommand(PerlShellExtCtxtMenu *obj,
						 HWND hParent,
						 LPCSTR pszWorkingDir,
						 LPCSTR pszCmd,
						 LPCSTR pszParam,
						 int iShowCmd)
{

#if defined(WITH_DEBUG) && defined(EXTDEBUG)
  FILE *f=fopen(EXTDEBUG_DEV,"a+"); 
  if(f!=0) { 
    fprintf(f,"PerlShellExtClassFactory::DoCommand pszWorkingDir='%s', pszCmd='%s', pszParam='%s'\n",pszWorkingDir,pszCmd,pszParam);
    for(UINT i=0;i<obj->m_count;i++)
      fprintf(f,"PerlShellExtClassFactory::DoCommand m_files[%d]='%s'\n",i,obj->m_files[i]);
    fclose(f); 
  }
#endif

#ifdef WITH_PERL
  dSP;
  
  EXTDEBUG((f,"PerlShellExtClassFactory::DoCommand after dSP\n"));
  ENTER; SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(obj->m_master->Object()); // push the SV of the extension on the stack.
  int c = obj->m_count;
  for(unsigned int i=0;i<c;i++) {
    XPUSHs(sv_2mortal(newSVpv(obj->m_files[i],0)));
  }
  PUTBACK;
  call_method("action",G_DISCARD);
  
  FREETMPS; LEAVE;
#endif
  return NOERROR;
}

UINT      g_cRefThisDll = 0;    // Reference count of this DLL.
HINSTANCE g_hmodThisDll = NULL;	// Handle to this DLL itself.

extern "C" int APIENTRY
DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
  if (dwReason == DLL_PROCESS_ATTACH)
    {
      // Extension DLL one-time initialization

      g_hmodThisDll = hInstance;
    }

  return 1;   // ok
}

STDAPI DllCanUnloadNow(void)
{
  return (g_cRefThisDll == 0 ? S_OK : S_FALSE);
}

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppvOut)
{
  *ppvOut = NULL;

  char buf0[100], buf1[100];
  memset(buf0,0,sizeof(buf0));  memset(buf1,0,sizeof(buf1));
  int r0 = CLSID2String(rclsid,buf0);
  int r1 = CLSID2String(riid,buf1);
  EXTDEBUG((f,"DllGetClassObject %s %s %d %d\n",buf0,buf1,r0,r1));
  //  EXTDEBUG((f,"DllGetClassObject %s %s %x\n",buf0,buf1,perl);
  
  if(IsEqualIID(rclsid,CLSID_PerlMenu)) {
    PerlMenuClassFactory *pcf = new PerlMenuClassFactory();
    return pcf->QueryInterface(riid,ppvOut);
  }

  PerlShellExtClassFactory *pcf = PerlShellExtClassFactory::FindClassFactory(rclsid);
  
  if(pcf==0)
    return CLASS_E_CLASSNOTAVAILABLE;
  return pcf->QueryInterface(riid, ppvOut);
}

PerlShellExtClassFactory::PerlShellExtClassFactory(REFCLSID clsid, char *pkg)
  : 
  m_clsid(clsid), m_pkg(strdup(pkg)), m_cRefs(1L)
{
  char cls[200];
  CLSID2String(clsid,&cls[0]);
  EXTDEBUG((f,"PerlShellExtClassFactory::PerlShellExtClassFactory %s %s\n",pkg,cls));

#ifdef WITH_PERL

  if(m_interp==0) {
    m_interp =perl_alloc();
    perl_construct(m_interp);
    static int argc=3;
    static char *argv[] = { "perlshellext.dll", "-e", "0" }; //, "-MWin32::ShellExt::RenameMP3" };
    //, "-IC:\\Perl\\lib", "-IC:\\Perl\\site\\lib" };
  
    perl_parse(m_interp, xs_init, argc, argv, (char **)NULL);
    //perl_run(m_interp);
  }
  
//    // FIXME i think i don't need to do something more complex for now, as instances of PerlShellExt are guaranteed
//    // to have a shorter lifetime than the PerlShellExtClassFactory object that created them.
//    static unsigned char first=1;
//    if(first==1) {
//      first=0;
//    } else {
//      // changing interpreters after a PerlShellExtClassFactory instance was created and then destructed.
//      PERL_SET_CONTEXT(m_interp);
//    }
  SetContext();
  
    char buf[400];
    memset(buf,0,sizeof(buf));
    strcat(buf,"use ");
    strcat(buf,m_pkg);
    strcat(buf,"; ");
    (void)/*SV *sv =*/ eval_pv(buf, FALSE);

#endif
  g_cRefThisDll++;	
}
static void dll_cleanup() {
  if(g_cRefThisDll!=0) return;
  PerlShellExtClassFactory::cleanup();
}

PerlShellExtClassFactory::~PerlShellExtClassFactory()				
{
#ifdef WITH_PERL
  //perl_destruct(m_interp);
  //perl_free(m_interp);
  //m_interp=0;
#endif
  free(m_pkg);
  
  g_cRefThisDll--;
  dll_cleanup();
}

STDMETHODIMP PerlShellExtClassFactory::QueryInterface(REFIID riid,
						      LPVOID FAR *ppv)
{
  *ppv = NULL;

  // Any interface on this object is the object pointer

  if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IClassFactory))
    {
      *ppv = (LPCLASSFACTORY)this;

      AddRef();

      return NOERROR;
    }

  return E_NOINTERFACE;
}	

STDMETHODIMP_(ULONG) PerlShellExtClassFactory::AddRef()
{
  return ++m_cRefs;
}

STDMETHODIMP_(ULONG) PerlShellExtClassFactory::Release()
{
  if (--m_cRefs)
    return m_cRefs;

  delete this;
  return 0L;
}

STDMETHODIMP PerlShellExtClassFactory::CreateInstance(LPUNKNOWN pUnkOuter,
						      REFIID riid,
						      LPVOID *ppvObj)
{
  char buf[200];
  CLSID2String(riid,&buf[0]);
  EXTDEBUG((f,"PerlShellExtClassFactory::CreateInstance %s",buf));
  *ppvObj = NULL;

  // Shell extensions typically don't support aggregation (inheritance)

  if (pUnkOuter)
    return CLASS_E_NOAGGREGATION;

  // Create the main shell extension object.  The shell will then call
  // QueryInterface with IID_IPerlShellExtInit--this is how shell extensions are
  // initialized.

  PerlShellExt *pPerlShellExt = new PerlShellExt(this
#ifdef WITH_PERL
						 ,CreatePerlObject()
#endif
						 );  //Create the PerlShellExt object, sharing the interpreter accross instances of the shell extension

  if (NULL == pPerlShellExt)
    return E_OUTOFMEMORY;

  return pPerlShellExt->QueryInterface(riid, ppvObj);
}


STDMETHODIMP PerlShellExtClassFactory::LockServer(BOOL fLock)
{
  return NOERROR;
}

// " 'this' : used in base member initializer list " is not a valid warning, as what follows is legal C++
#pragma warning(disable : 4355)

PerlShellExtCtxtMenu::PerlShellExtCtxtMenu(PerlShellExt *master) 
  : m_count(0), m_files(0), m_init(this), m_master(master)
{
  g_cRefThisDll++;
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
  g_cRefThisDll--;
  dll_cleanup();
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

PerlShellExt::PerlShellExt(PerlShellExtClassFactory *factory, SV *obj) : m_factory(factory), m_type(PerlShellExt::Unknown),
  m_cRefs(0L) // attention this is set to 0 on purpose, it avoids a Release call in PerlShellExtClassFactory::CreateInstance
             // we give out the ref acquired by the QueryInterface call instead.
#ifdef WITH_PERL
  , m_obj(obj)
#endif
{
  m_factory->AddRef();
  m_impl.ctxtmenu=0;
}

PerlShellExt::~PerlShellExt()
{
  m_factory->Release();
  m_factory = 0;
  
  switch(m_type) {
  case ContextMenu:
    delete m_impl.ctxtmenu;
    break;
  case QueryInfo:
    delete m_impl.queryinfo;
    break;
  default: // this is ugly
    delete (IUnknown*)m_impl.ctxtmenu;
  }
}
 
STDMETHODIMP_(ULONG)	PerlShellExt::AddRef()
{
  return ++m_cRefs;
}
STDMETHODIMP_(ULONG)	PerlShellExt::Release()
{
  --m_cRefs;
  if(m_cRefs==0) delete this;
  return m_cRefs;
}

HRESULT PerlShellExt::BuildCtxtMenu() {
  EXTDEBUG((f,"PerlShellExt::BuildCtxtMenu\n"));
  switch(m_type) {
  case Unknown:
    m_type = PerlShellExt::ContextMenu;
    m_impl.ctxtmenu = new PerlShellExtCtxtMenu(this);
    break;
  case ContextMenu: // extension code already loaded
    break;
  case QueryInfo:
  default:
    return E_FAIL; // can't morph a context menu ext into a queryinfo one at runtime, just refuse the QueryInterface.
  }
  return S_OK;
}
HRESULT PerlShellExt::BuildQueryInfo() {
  EXTDEBUG((f,"PerlShellExt::BuildQueryInfo\n"));
  switch(m_type) {
  case Unknown:
    m_type = PerlShellExt::QueryInfo; // it's a shame, but this should really be determined by c++ dispatch inside the PerlShellExtCtxtMenu/PerlQueryInfoExt classes.
    m_impl.queryinfo = new PerlQueryInfoExt(this);
    break;
  case QueryInfo: // nothing to do.
    break;
  case ContextMenu:
  default:
    return E_FAIL;
  }
  return S_OK;
}
 
STDMETHODIMP PerlShellExt::QueryInterface(REFIID riid, LPVOID FAR *ppv)
{
  HRESULT rc=S_OK;
  if(ppv==0) return E_POINTER;
  *ppv = 0;

  if(IsEqualIID(riid, IID_IUnknown))
    {
      *ppv = this;
    }
  else {
    // context menu extension
    if (IsEqualIID(riid, IID_IShellExtInit))
      {
	rc = BuildCtxtMenu();
	if(FAILED(rc)) return rc;
	*ppv = (LPSHELLEXTINIT)&(m_impl.ctxtmenu->m_init);
      }
    else if (IsEqualIID(riid, IID_IContextMenu))
      {
	rc = BuildCtxtMenu();
	if(FAILED(rc)) return rc;
	*ppv = (LPCONTEXTMENU)m_impl.ctxtmenu;
      }
    
    else 
      // queryinfo extension
      if(IsEqualIID(riid,IID_IQueryInfo))
	{
	  rc = BuildQueryInfo();
	  if(FAILED(rc)) return rc;
	  *ppv = (IQueryInfo*) m_impl.queryinfo;
	}
      else if(IsEqualIID(riid,IID_IPersist) || IsEqualIID(riid,IID_IPersistFile)) 
	{
	  rc = BuildQueryInfo();
	  if(FAILED(rc)) return rc;
	  *ppv = (IPersistFile*) &(m_impl.queryinfo->m_persist); // here i cheat a bit, because i know IPersistFile subclasses IPersist, so the vtable of IPersistFile is a valid IPersist vtable too...
	}
  }
  
  if (*ppv)
    {
      AddRef(); // equivalent to AddRef()-ing whatever we stored in *ppv...
      return NOERROR;
    }
  
  return E_NOINTERFACE;
}
void PerlShellExt::SetContext()
{
  m_factory->SetContext();
}


//  long __stdcall PerlShellExtInit::Initialize(struct _ITEMIDLIST const *,struct IDataObject *,void *) {
//    return 0;
//  }
STDMETHODIMP		    PerlShellExtInit::Initialize(LPCITEMIDLIST pIDFolder, 
							 LPDATAOBJECT pDataObj, 
							 HKEY hKeyID) {
  return m_master->Initialize(pIDFolder,pDataObj,hKeyID);
}

#include "PerlQueryInfoExt.cpp"

#include "PerlMenu.cpp"
