/* -*- C++ -*- // old habits are hard to change ;-)
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
 * The code was initiated from one the samples Microsoft provides (SHELLEX in MSDN), even
 * though it does not bear much resemblance with it any more.
 *
 * Perl-related portions (C) 2001-2002 Jean-Baptiste Nivoit.
 *
 * The SHELLEX sample from Microsoft comes with the following notice:
 *
 * THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
 * ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 *
 * Copyright (C) 1993-1997  Microsoft Corporation.  All Rights Reserved.
 *
 */

#include "PerlShellExtClassFactory.h"
#include "debug.h"

#include "PerlShellExt.h"
#include "PerlShellExtCtxtMenu.h"
#include "PerlColumnProviderExt.h"

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void XS_Win32__ShellExt__CopyHook_constant (pTHX_ CV* cv);
//EXTERN_C void boot_Socket (pTHX_ CV* cv);
static void xs_init(pTHX)
{
  char *file = __FILE__;
  /* DynaLoader is a special case */
  newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
  newXS("Win32::ShellExt::CopyHook::constant", XS_Win32__ShellExt__CopyHook_constant, file);
  //newXS("Socket::bootstrap", boot_Socket, file);
}

PerlInterpreter *PerlShellExtClassFactory::m_interp=0;
static class InterpDestructor {
  PerlInterpreter **i;
public:
  InterpDestructor(PerlInterpreter **pi) : i(pi) {}
  ~InterpDestructor() {
    perl_destruct(*i);
    perl_free(*i);
    *i=0;
  }
} dest(&PerlShellExtClassFactory::m_interp);

#define Perl_get_context() m_interp

PerlShellExtClassFactory *PerlShellExtClassFactory::GetScriptForCLSID(REFCLSID clsid) {
  if(m_scripts==0) return 0;
  return m_scripts->find(clsid);
}

PerlShellExtClassFactory *PerlShellExtClassFactory::AddScriptForCLSID(REFCLSID clsid, char *pkg) {
  m_scripts = new PerlShellExtClassFactory::ScriptElem(clsid,pkg,m_scripts);
  m_scripts->m_factory->AddRef();
  return m_scripts->m_factory;
}

PerlShellExtClassFactory::ScriptElem::ScriptElem(REFCLSID clsid, 
						 char *pkg, class ScriptElem *nx)
  : m_next(nx), m_factory(new PerlShellExtClassFactory(clsid, pkg))
{}
PerlShellExtClassFactory::ScriptElem::~ScriptElem()
{
  m_factory->Release();
  m_factory=0; // freeing that probably already has occured, and it's not up to this object to take care of it.
  if(m_next!=0) delete m_next;
}
PerlShellExtClassFactory *PerlShellExtClassFactory::ScriptElem::find(REFCLSID clsid)
{
  if(IsEqualIID(clsid, m_factory->m_clsid)) {
    m_factory->AddRef();
    return m_factory;
  }
  if(m_next!=0)
    return m_next->find(clsid);
  return 0;
}

PerlShellExtClassFactory::ScriptElem *PerlShellExtClassFactory::m_scripts=0;
void PerlShellExtClassFactory::cleanup() {
  if(m_scripts==0) return;
  delete m_scripts;
  m_scripts=0;
}

int PerlShellExtClassFactory::CLSID2String(REFCLSID clsid, char *buf) { // hand-coded since i didn't find the corresponding API call in the docs...
  // 17/01/2002 i found the correct call : it should be 'UuidToString' from <rpcdce.h>
  // i hereby place this routine (this routine only) in the public domain.

// almost equivalent:
//	sprintf(buf,"{%X-%X-%X-%X-%X%X%X}",clsid.Data1,clsid.Data2,clsid.Data3);
//	return;

	char *p = buf;
	*p='{';
	p++;
#pragma warning(disable : 4244)
	static const char *alphabet="0123456789ABCDEF";

	unsigned char cur=0;
	cur = (clsid.Data1 & 0xf0000000) >> 28; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x0f000000) >> 24; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x00f00000) >> 20; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x000f0000) >> 16; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x0000f000) >> 12; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x00000f00) >> 8 ; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x000000f0) >> 4 ; *p=alphabet[cur%16]; p++;
	cur = (clsid.Data1 & 0x0000000f) >> 0 ; *p=alphabet[cur%16]; p++;
	
	*p='-';	p++;
    cur = (clsid.Data2 & 0xf000) >> 12; *p=alphabet[cur%16]; p++;
    cur = (clsid.Data2 & 0x0f00) >> 8 ; *p=alphabet[cur%16]; p++;
    cur = (clsid.Data2 & 0x00f0) >> 4 ; *p=alphabet[cur%16]; p++;
    cur = (clsid.Data2 & 0x000f) >> 0 ; *p=alphabet[cur%16]; p++;

	*p='-';	p++;
    cur = (clsid.Data3 & 0xf000) >> 12; *p=alphabet[cur%16]; p++;
    cur = (clsid.Data3 & 0x0f00) >> 8 ; *p=alphabet[cur%16]; p++;
    cur = (clsid.Data3 & 0x00f0) >> 4 ; *p=alphabet[cur%16]; p++;
    cur = (clsid.Data3 & 0x000f) >> 0 ; *p=alphabet[cur%16]; p++;

	*p='-';	p++;
	for(int i=0;i<8;i++)
	{
		cur = (clsid.Data4[i] & 0xf0) >> 4; *p = alphabet[cur%16]; p++;
		cur = (clsid.Data4[i] & 0x0f) >> 0; *p = alphabet[cur%16]; p++;
		if(i==1)
		{ *p='-'; p++;
		}
	}
	*p='}';
	p++;
	*p='\0';
	return p-buf; // say how many bytes we appended.
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
  int where = PerlShellExtClassFactory::CLSID2String(rclsid, subkey+6);
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

SV *PerlShellExtClassFactory::CreatePerlObject() {
  HV *hv = newHV();
  SV *sv = /*sv_newmortal();*/ newSV(0);
  sv_setref_pv(sv,m_pkg,hv);
  return sv;
}

void PerlShellExtClassFactory::SetContext() {
  PERL_SET_CONTEXT(m_interp);
}

STDMETHODIMP PerlShellExtClassFactory::GetInfoTip(IMalloc *iMalloc, SV *obj, wchar_t *filename, DWORD dwFlags, WCHAR **ppwszTip)
{
  HRESULT rc = NOERROR;
    I32 ax=0;
    dSP;
    ENTER; 
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(obj);
    
    char buf[MAX_PATH];
    sprintf(&buf[0],"%S",filename); // this is the only way i know to convert widechar data into the usual C string (potentially using information but i don't really care).
    XPUSHs(sv_2mortal(newSVpv(buf,0)));
    PUTBACK;
    int count = call_method("get_info_tip",G_SCALAR);
    SPAGAIN;
    SP -= count;

    ax = (SP - PL_stack_base) + 1 ;
    char *tmp = SvPV(ST(0),PL_na);
    size_t len = strlen(tmp);
    if(len==0 || (len==1 && *tmp==' ')) {
      *ppwszTip = 0;
      rc = E_FAIL;
    } else {
      WCHAR *c = *ppwszTip = (WCHAR*)iMalloc->Alloc(sizeof(OLECHAR)*len);
      memset(c,0,sizeof(OLECHAR)*len);
      //swprintf(c,L"%s",tmp);
      swprintf(c,L"%hs",tmp);
      //swprintf(c,L"test vraiment con");
    }
    EXTDEBUG((f,"PerlShellExtClassFactory::GetInfoTip '%s'=>'%s'\n",buf,tmp));
    /*{
      FILE *f=fopen("d:\\log8.txt","a+");
      if(f!=0) { 
	fwprintf(f,L"%d : %S\n",wcslen(c),c);
	fclose(f); 
      }
    }*/

    PUTBACK;
    FREETMPS; 
    LEAVE;
    return rc;
}

STDMETHODIMP PerlShellExtClassFactory::QueryContextMenu(PerlShellExtCtxtMenu *obj,
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

//    static int cnt=0;
//    if(cnt==0) {
//      cnt++;
//      return ResultFromShort(0);
//    }

  EXTDEBUG((f,"in QueryContextMenu\n"));

  unsigned char should_i_popup_the_menu=1;

  I32 ax=0;
  dSP;
  ENTER; 
  SAVETMPS;
  PUSHMARK(SP);				
  
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

  if(should_i_popup_the_menu==0)
    {
      EXTDEBUG((f,"not a file that i can handle, no menu!\n"));
      return ResultFromShort(0);
    }

  char *text = 0;//"&Rename using MP3 ID tag";

  int len = strlen(m_pkg);
  //char *buf = (char*)_alloca((len+8)*sizeof(char));
  char buf[100];
  memset(buf,0,sizeof(buf));
  strcat(buf,m_pkg);
  strcat(buf+len,"::COMMAND"); // the 'COMMAND' variable in the package can either be a scalar (only one command in that package) or a ref to a hash (then multiple commands in that package).
  SV *sv = perl_get_sv(buf, TRUE);
  UINT idCmd = idCmdFirst;
    
  if (!SvROK(sv)) {
    text = SvPV(sv, PL_na);
    EXTDEBUG((f,"text=%s\n",text));
    obj->insert_command(hMenu,text,indexMenu,idCmd,idCmdFirst,idCmdLast,uFlags);
    return ResultFromShort(idCmd-idCmdFirst);
  } else { // the sv is a reference

    sv = SvRV(sv);
    if(SvTYPE(sv)==SVt_PVHV) { // this allows you to specify a ref to a hash to have multiple commands in the same package.
      HV *hv = (HV*)sv;
      (void)hv_iterinit(hv);
      HE *he=0;
      m_sz=0;
      while(he=hv_iternext(hv)) { m_sz++; } // first pass to compute the number of commands in that package.
      
      if(m_sz!=0) {
	(void)hv_iterinit(hv);
	m_methods = new char*[m_sz];
	
	int i=0;
	UINT sep=0/*1*/;

	//FILE *f = fopen ("d:\\log13.txt","a");

	while(he=hv_iternext(hv)) {
	  char *key = HeKEY(he);
	  char *val = SvPV(HeVAL(he),PL_na);
	  m_methods[i] = strdup(key);
	  if(val!=0 && *val!=0)
	    obj->insert_command(hMenu,val,indexMenu,idCmd,idCmdFirst,idCmdLast,uFlags,sep);

	  //fprintf(f,"%s=>%s at %d\n",key,val,idCmd);

	  sep=0; // only insert separator the first time around.
	  i++;
	}

	//fprintf(f,"return %d %d\n",i,idCmd-idCmdFirst);
	//fclose(f);


      }
      return ResultFromShort(idCmd-idCmdFirst); // number of menu items we added
    }
  }
  return NOERROR;
  }

STDMETHODIMP PerlShellExtClassFactory::DoCommand(PerlShellExtCtxtMenu *obj,
						 HWND hParent,
						 LPCSTR pszWorkingDir,
						 LPCSTR pszCmd,
						 LPCSTR pszParam,
						 int iShowCmd, UINT idCmd)
{
//  #if defined(WITH_DEBUG) && defined(EXTDEBUG)
//    FILE *f=fopen(EXTDEBUG_DEV,"a+"); 
//    if(f!=0) { 
//      fprintf(f,"PerlShellExtClassFactory::DoCommand pszWorkingDir='%s', pszCmd='%s', pszParam='%s' idCmd=%d\n",pszWorkingDir,pszCmd,pszParam,idCmd);
//      for(UINT i=0;i<obj->m_count;i++)
//        fprintf(f,"PerlShellExtClassFactory::DoCommand m_files[%d]='%s'\n",i,obj->m_files[i]);
//      fclose(f); 
//    }
//  #endif

  EXTDEBUG((f,"here 0x%x\n",(long)obj));
  dSP;
  
  EXTDEBUG((f,"PerlShellExtClassFactory::DoCommand after dSP %d<%d\n",idCmd,m_sz));
  ENTER; SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(obj->m_master->Object()); // push the SV of the extension on the stack.
  int c = obj->m_count;
  for(unsigned int i=0;i<c;i++) {
    XPUSHs(sv_2mortal(newSVpv(obj->m_files[i],0)));
  }
  PUTBACK;
  if(m_sz==0) {
    if(idCmd==0) 
      call_method("action",G_DISCARD);
    else 
      ; // this would be an error, there's no other command if the m_sz is 0.
  } else {
    
    EXTDEBUG((f,"PerlShellExtClassFactory::DoCommand call_method: %d<%d\n",idCmd,m_sz));
    if(idCmd<m_sz) {
      EXTDEBUG((f,"calling '%s'\n",m_methods[idCmd]));
      call_method(m_methods[idCmd],G_DISCARD);
    }
  }
  
  FREETMPS; LEAVE;

  return NOERROR;
}

PerlShellExtClassFactory::PerlShellExtClassFactory(REFCLSID clsid, char *pkg)
  : m_clsid(clsid), m_pkg(strdup(pkg)), m_cRefs(1L), m_methods(0), m_sz(0)
{
  char cls[200];
  PerlShellExtClassFactory::CLSID2String(clsid,&cls[0]);
  EXTDEBUG((f,"PerlShellExtClassFactory::PerlShellExtClassFactory %s %s\n",pkg,cls));

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

  g_cRefThisDll++;	
}
static void dll_cleanup() {
  if(g_cRefThisDll!=0) return;
  PerlShellExtClassFactory::cleanup();
}

PerlShellExtClassFactory::~PerlShellExtClassFactory()				
{
  //perl_destruct(m_interp);
  //perl_free(m_interp);
  //m_interp=0;
  free(m_pkg);
  if(m_methods!=0) {
    for(int i=0;i<m_sz;i++) {
      free(m_methods[i]);
    }
    delete [] m_methods;
    m_methods=0;
    m_sz=0;
  }
  
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
  PerlShellExtClassFactory::CLSID2String(riid,&buf[0]);
  EXTDEBUG((f,"PerlShellExtClassFactory::CreateInstance %s\n",buf));
  *ppvObj = NULL;

  // Shell extensions typically don't support aggregation (inheritance)

  if (pUnkOuter)
    return CLASS_E_NOAGGREGATION;

  // Create the main shell extension object.  The shell will then call
  // QueryInterface with IID_IPerlShellExtInit--this is how shell extensions are
  // initialized.

  PerlShellExt *pPerlShellExt = new PerlShellExt(this,CreatePerlObject());  //Create the PerlShellExt object, sharing the interpreter accross instances of the shell extension

  if (NULL == pPerlShellExt)
    return E_OUTOFMEMORY;

  return pPerlShellExt->QueryInterface(riid, ppvObj);
}


STDMETHODIMP PerlShellExtClassFactory::LockServer(BOOL fLock)
{
  return NOERROR;
}

UINT PerlShellExtClassFactory::CopyCallback (SV *obj, HWND hwnd, char *wFunc, char *wFlags, 
					     LPCSTR pszSrcFile, DWORD dwSrcAttribs, LPCSTR pszDestFile, DWORD dwDestAttribs) 
{
#if 0
  dSP;
  ENTER; 
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(obj);
  XPUSHs(sv_2mortal(newSVpv(wFunc,0)));
  XPUSHs(sv_2mortal(newSVpv(wFlags,0)));
  XPUSHs(sv_2mortal(newSVpv(pszSrcFile,0)));
  XPUSHs(sv_2mortal(newSViv(dwSrcAttribs)));
  XPUSHs(sv_2mortal(newSVpv(pszDestFile,0)));
  XPUSHs(sv_2mortal(newSViv(dwDestAttribs)));
  
  call_method("copycb",G_SCALAR);
  
  FREETMPS; 
  LEAVE;
#else
  EXTDEBUG((f,"%s %s %s %s\n",wFunc,wFlags,pszSrcFile, pszDestFile));
#endif
  return IDYES;
}

void PerlShellExtClassFactory::LoadColumnProvider(PerlColumnProviderExt *p) {
  EXTDEBUG((f,"PerlShellExtClassFactory::LoadColumnProvider begin\n"));
  DWORD sz=0;

  int len = strlen(m_pkg);
  char buf[200]; // FIXME oflo.
  memset(buf,0,sizeof(buf));
  strcat(buf,m_pkg);
  strcat(buf+len,"::COLUMNS");
  SV *sv = perl_get_sv(buf, TRUE);

  PerlColumnProviderExt::ColumnInfo *cols = 0;
    
  if (SvROK(sv)) {
    sv = SvRV(sv);
    if(SvTYPE(sv)==SVt_PVHV) {
      HV *hv = (HV*)sv;
      (void)hv_iterinit(hv);
      HE *he=0;
      sz=0;
      while(he=hv_iternext(hv)) { sz++; } // first pass to compute the number of commands in that package.
      
      EXTDEBUG((f,"PerlShellExtClassFactory::LoadColumnProvider found %d columns\n",sz));
	
      if(sz!=0) {
	(void)hv_iterinit(hv);
	cols = new PerlColumnProviderExt::ColumnInfo[sz];
	
	int i=0;
	UINT sep=0/*1*/;

	//FILE *f = fopen ("d:\\log13.txt","a");

	while(he=hv_iternext(hv)) {
	  char *key = HeKEY(he);
	  SV *val = HeVAL(he);
	  EXTDEBUG((f,"PerlShellExtClassFactory::LoadColumnProvider col[%d]=%s\n",i,key));
	  
	  cols[i].title = (WCHAR*)malloc(sizeof(WCHAR)*(strlen(key)+1));
	  swprintf(cols[i].title,L"%hs",key);
	  val = SvRV(val);
	  HV *h = (HV*)val;
	  (void)hv_iterinit(h);
	  HE *iter=0;
	  while(iter = hv_iternext(h)) {
	    char *k = HeKEY(iter);
	    char *v = SvPV(HeVAL(iter),PL_na);
	    EXTDEBUG((f,"PerlShellExtClassFactory::LoadColumnProvider col[%d]=(%s,%s)\n",i,k,v));
	    
	    if(strcmp("description",k)==0) {
	      cols[i].description = (WCHAR*)malloc(sizeof(WCHAR)*(strlen(v)+1));
	      swprintf(cols[i].description,L"%hs",v);
	    } else if(strcmp("callback",k)==0) {
	      cols[i].callback = v;
	    } // FIXME add check that we really fill all the data members of the ColInfo struct.
	  }
	  i++;
	}
	
	//fprintf(f,"return %d %d\n",i,idCmd-idCmdFirst);
	//fclose(f);
      }
    }
    p->SetColumnInfo(sz,cols);
  }

  EXTDEBUG((f,"PerlShellExtClassFactory::LoadColumnProvider end\n"));
}

#include "ccomvariant.h"
HRESULT PerlShellExtClassFactory::GetItemData(SV *obj, char *cb, LPCSHCOLUMNDATA pscd, VARIANT *pvarData)
{
  if(pvarData==0) return E_INVALIDARG;
  if(pscd->pwszExt==0 || *pscd->pwszExt==0) return S_FALSE;
  
  HRESULT rc = S_OK;
  char ext[MAX_PATH];
  sprintf(&ext[0],"%S",pscd->pwszExt);

  char file[MAX_PATH];
  sprintf(&file[0],"%S",pscd->wszFile);
  EXTDEBUG((f,"PerlShellExtClassFactory::GetItemData(0x%x,%s,%s,%s)\n",obj,cb,ext,file));
  EXTDEBUG((f,"PerlShellExtClassFactory::GetItemData(0x%x,%s,%S,%S)\n",obj,cb,pscd->pwszExt,pscd->wszFile));

  dSP;
  ENTER; 
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(obj);
  //XPUSHs(sv_2mortal(newSVpv(ext,0)));
  XPUSHs(sv_2mortal(newSVpv(file,0)));

  PUTBACK;
  EXTDEBUG((f,"PerlShellExtClassFactory::GetItemData 1\n"));
  int count = call_method(cb,G_SCALAR);
  EXTDEBUG((f,"PerlShellExtClassFactory::GetItemData 2\n"));
  
  SPAGAIN;
  SP -= count ;
  I32 ax = (SP - PL_stack_base) + 1 ;

  char *val = SvPV(ST(0),PL_na);
  if(val==0 || *val=='\0')
    rc = S_FALSE;
  else {
#if 0
    // FIXME copy output to 'pvarData'.
    VariantClear(pvarData);
    pvarData->vt = VT_BSTR;
    WCHAR *w = (WCHAR*)malloc(sizeof(WCHAR)*strlen(val));
    swprintf(w,L"%hs",val);
    pvarData->bstrVal = SysAllocString(w);
    free(w);
#else

	// Reads dimensions and palette size from the BMP file
#define BMPCH_MAXSIZE 80
	WCHAR szBuf[BMPCH_MAXSIZE];
	ZeroMemory(szBuf, BMPCH_MAXSIZE);
	swprintf(szBuf,L"%hs",val);

	// The return value (a string in this case) must be 
	// packed as a Variant.
	MyCComVariant cv(szBuf);
	cv.Detach(pvarData); 
	
#endif
  }
  EXTDEBUG((f,"PerlShellExtClassFactory::GetItemData 3\n"));

  PUTBACK;

  FREETMPS; 
  LEAVE;
  EXTDEBUG((f,"PerlShellExtClassFactory::GetItemData 4\n"));

  return rc;
}
const char *PerlShellExtClassFactory::iid2string(REFIID riid) {
  // 'ToR' stands for 'test or return', for lack of a better name.
#define ToR(x,iid)  if(IsEqualIID(x, IID_##iid)) { return #iid; } else 
  ToR(riid,IUnknown)
    ToR(riid,IShellExtInit)
    ToR(riid,IContextMenu)
    ToR(riid,IShellPropSheetExt)
    ToR(riid,ICopyHookA)
    ToR(riid,IPersistFile)
    ToR(riid,IExtractIcon)
    ToR(riid,IDataObject)
    ToR(riid,IQueryInfo)
    ToR(riid,IDropTarget)
    ToR(riid,IColumnProvider)
    ToR(riid,IClassFactory)
    ToR(riid,IObjectWithSite) // ????
    return "????";
#undef ToR
}

unsigned char PerlShellExtClassFactory::SubPackageOf(char *super) {
  if(super==0 || *super==0) return 0;
  
  char buf[100];
  memset(buf,0,sizeof(buf));
  strcat(buf,m_pkg);
  strcat(buf+len,"::ISA");
  AV *av = perl_get_av(buf, TRUE);
  if(av==0) return 0;
  I32 len = Perl_av_len(av);
  for(int i=0;i<len;i++) {
    SV **svp = Perl_av_fetch(av,i,0);
    if(svp!=0) {
      SV *sv = *svp;
      if (!SvROK(sv)) {
	char *text = SvPV(sv, PL_na);
	if(text==0 || *text==0) continue;
	if(strcmp(text,super)==0) return 1; // FIXME this only allows for 1 deep hierarchy of packages, we should walk up the inheritance lattice to be rigorous.
      }
    }
  }
  return 0;
}

