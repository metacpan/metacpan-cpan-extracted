// -*- C++ -*- 
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlShellExt.h"

#include "PerlColumnProviderExt.h"
#include "PerlCopyHookExt.h"
#include "PerlDataObjectExt.h"
#include "PerlDropTargetExt.h"
#include "PerlIconHandlerExt.h"
#include "PerlPersistFileExt.h"
#include "PerlPropSheetExt.h"
#include "PerlQueryInfoExt.h"
#include "PerlShellExtCtxtMenu.h"
#include "PerlShellExtInit.h"

PerlShellExt::PerlShellExt(PerlShellExtClassFactory *factory, SV *obj) : m_factory(factory), 
  m_cRefs(0L), // attention this is set to 0 on purpose, it avoids a Release call in PerlShellExtClassFactory::CreateInstance
               // we give out the ref acquired by the QueryInterface call instead.
  m_obj(obj)
{
  m_factory->AddRef();
  
  exts[0].m_type = Unknown;
  exts[0].m_impl.init = 0;
  exts[1].m_type = Unknown;
  exts[1].m_impl.init = 0;
}

PerlShellExt::~PerlShellExt()
{
  m_factory->Release();
  m_factory = 0;
  
  Release(exts[0]);
  Release(exts[1]);
}
void PerlShellExt::Release(Ext& e) {
  if(e.m_impl.unknown==0) return;
  e.m_impl.unknown->Release(); // no need to switch on the type since all our objects are instances of subclasses of IUnknown
  // let's reply on IUnknown's destructor which should be virtual ?
  
  /*
  switch(e.m_type) {
  case ShellExtInit: delete e.m_impl.init;     break;
  case ContextMenu:  delete e.m_impl.ctxtmenu; break;
  case QueryInfo:    delete e.m_impl. ; break;
  case PersistFile:  delete e.m_impl. ; break;
  case CopyHook:     delete e.m_impl. ; break;
  case DataObject:   delete e.m_impl. ; break;
  case DropTarget:   delete e.m_impl. ; break;
  case PropSheet:    delete e.m_impl. ; break;
  case Unknown:      delete e.m_impl. ; break;
  default:;
  }*/
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

STDMETHODIMP PerlShellExt::QueryInterface(REFIID riid, LPVOID FAR *ppv)
// This is a sort of a state machine, allowing only specific combinations
// of components in exts[0]/exts[1].
/*
                       +--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
		       |IShellExtInit |	IContextMenu |	ShellPropSheetExt | IPersistFile | IExtractIcon  | ICopyHook |	IDataObject | IDropTarget | IColumnProvider | IQueryInfo |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Context-menu handler  |	X     |		X    |	                  |		 |		 |	      |		    |		  |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Drag-drop handler     |  	X     |		X    |			  |		 |		 |	      |		    |		  |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Property-sheet handler|	X     |		     |		X	  |		 |		 |	      |		    |		  |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Icon handler	       |	      |		     |			  |	       X |	       X |	      |		    |		  |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Copy-hook handler     |	      |		     |			  |		 |	         |	X     |		    |		  |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Data handler 	       |	      |		     |			  |	       X |	         |	      |		X   |		  |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Drop handler	       |	      |		     |			  |	       X |	         |	      |		    |		X |                 |                 |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Column provider       |	      |		     |			  |		 |	         |	      |		    |		  |           X     |                |
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
|Infotip               |	      |		     |			  |	       X |	         |	      |		    |		  |                |            X    | 
+----------------------+--------------+--------------+--------------------+--------------+---------------+-----------+-------------+-------------+-----------------+ ----------------+ 
*/
{
  char buf[200];
  char klass[200];
  PerlShellExtClassFactory::CLSID2String(riid,&buf[0]);
  PerlShellExtClassFactory::CLSID2String(this->clsid(),&klass[0]);
  EXTDEBUG((f,"PerlShellExt::QueryInterface begin for %s %s on %s\n",buf,
	    PerlShellExtClassFactory::iid2string(riid),klass));

  HRESULT rc=S_OK;
  if(ppv==0) return E_POINTER;
  *ppv = 0;
  
  IUnknown *pv=0;
  if(IsEqualIID(riid, IID_IUnknown)) {
    pv = this;
  } else {
    if(IsEqualIID(riid,IID_IShellExtInit)) { // instead of this big succession of if/else, i'd rather have a rb tree.
      switch(exts[0].m_type) {
      case Unknown: // component created yet.
	pv = newPerlShellExtInit(exts[0]);
	break;
      case ShellExtInit: // component already present
	pv = exts[0].m_impl.init;
	break;
      case ContextMenu:
      case PropSheet:
	switch(exts[1].m_type) {
	case Unknown: // ContextMenu/PropSheet component but ShellExtInit not yet created.
	  pv = newPerlShellExtInit(exts[1]);
	  break;
	case ShellExtInit:
	  pv = exts[1].m_impl.init;
	  break;
	default:
	  return E_FAIL; // should never happen.
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IContextMenu)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlShellExtCtxtMenu(exts[0]);
	break;
      case ShellExtInit:
	switch(exts[1].m_type) {
	case Unknown:
	  pv = newPerlShellExtCtxtMenu(exts[1]);
	  break;
	case ContextMenu:
	  pv = exts[1].m_impl.ctxtmenu;
	  break;
	default:
	  return E_FAIL;
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IShellPropSheetExt)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlPropSheetExt(exts[0]);
	break;
      case ShellExtInit:
	switch(exts[1].m_type) {
	case Unknown:
	  pv = newPerlPropSheetExt(exts[1]);
	  break;
	default:
	  return E_FAIL;
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_ICopyHookA)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlCopyHookExt(exts[0]);
	break;
      case CopyHook:
	pv = exts[0].m_impl.copyhook;
	break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IColumnProvider)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlColumnProviderExt(exts[0]);
	break;
      case ColumnProvider:
	pv = exts[0].m_impl.column;
	break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IPersistFile)) {
      switch(exts[0].m_type) {
      case Unknown: // component created yet.
	pv = newPerlPersistFileExt(exts[0]);
	break;
      case PersistFile: // component already present
	pv = exts[0].m_impl.persistfile;
	break;
      case IconHandler:
      case DataObject:
      case DropTarget:
      case QueryInfo:
	switch(exts[1].m_type) {
	case Unknown: // ContextMenu/PropSheet component but PersistFile not yet created.
	  pv = newPerlPersistFileExt(exts[1]);
	  break;
	case PersistFile:
	  pv = exts[1].m_impl.persistfile;
	  break;
	default:
	  return E_FAIL; // should never happen.
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IExtractIcon)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlIconHandlerExt(exts[0]);
	break;
      case ShellExtInit:
	switch(exts[1].m_type) {
	case Unknown:
	  pv = newPerlIconHandlerExt(exts[1]);
	  break;
	default:
	  return E_FAIL;
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IDataObject)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlDataObjectExt(exts[0]);
	break;
      case ShellExtInit:
	switch(exts[1].m_type) {
	case Unknown:
	  pv = newPerlDataObjectExt(exts[1]);
	  break;
	default:
	  return E_FAIL;
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IQueryInfo)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlQueryInfoExt(exts[0]);
	break;
      case PersistFile:
	switch(exts[1].m_type) {
	case Unknown:
	  pv = newPerlQueryInfoExt(exts[1]);
	  break;
	default:
	  return E_FAIL;
	} break;
      default:
	;
      }
    } else if(IsEqualIID(riid,IID_IDropTarget)) {
      switch(exts[0].m_type) {
      case Unknown:
	pv = newPerlDropTargetExt(exts[0]);
	break;
      case ShellExtInit:
	switch(exts[1].m_type) {
	case Unknown:
	  pv = newPerlDropTargetExt(exts[1]);
	  break;
	default:
	  return E_FAIL;
	} break;
      default:
	;
      }
    }
  }
  EXTDEBUG((f,"PerlShellExt::QueryInterface end 0x%x\n",pv));
  if(pv!=0) {
    pv->AddRef();
    *ppv = pv;
    return NOERROR;
  } 
  return E_FAIL;
}

void PerlShellExt::SetContext()
{
  m_factory->SetContext();
}

// FIXME a refaire a base de templates+macros.
PerlShellExtInit *PerlShellExt::FindShellExtInit() {
  if(exts[0].m_type==ShellExtInit) return exts[0].m_impl.init;
  if(exts[1].m_type==ShellExtInit) return exts[1].m_impl.init;
  return 0;
}
PerlShellExtCtxtMenu *PerlShellExt::FindCtxtMenuExt() {
  if(exts[0].m_type==ContextMenu) return exts[0].m_impl.ctxtmenu;
  if(exts[1].m_type==ContextMenu) return exts[1].m_impl.ctxtmenu;
  return 0;
}
PerlQueryInfoExt *PerlShellExt::FindQueryInfoExt() {
  if(exts[0].m_type==QueryInfo) return exts[0].m_impl.queryinfo;
  if(exts[1].m_type==QueryInfo) return exts[1].m_impl.queryinfo;
  return 0;
}
PerlPersistFileExt *PerlShellExt::FindPersistFileExt() {
  if(exts[0].m_type==PersistFile) return exts[0].m_impl.persistfile;
  if(exts[1].m_type==PersistFile) return exts[1].m_impl.persistfile;
  return 0;
}
PerlCopyHookExt *PerlShellExt::FindCopyHookExt() {
  if(exts[0].m_type==CopyHook) return exts[0].m_impl.copyhook;
  if(exts[1].m_type==CopyHook) return exts[1].m_impl.copyhook;
  return 0;
}
PerlDataObjectExt *PerlShellExt::FindDataObjectExt() {
  if(exts[0].m_type==DataObject) return exts[0].m_impl.dataobject;
  if(exts[1].m_type==DataObject) return exts[1].m_impl.dataobject;
  return 0;
}
PerlDropTargetExt *PerlShellExt::FindDropTargetExt() {
  if(exts[0].m_type==DropTarget) return exts[0].m_impl.droptarget;
  if(exts[1].m_type==DropTarget) return exts[1].m_impl.droptarget;
  return 0;
}
PerlPropSheetExt *PerlShellExt::FindShellPropSheetExt() {
  if(exts[0].m_type==PropSheet) return exts[0].m_impl.propsheet;
  if(exts[1].m_type==PropSheet) return exts[1].m_impl.propsheet;
  return 0;
}
/*
PerlShellExtCtxtMenu *PerlShellExt::LoadCtxtMenuExt()
{
  if(exts[0].m_type==Unknown) {
    exts[0].m_type = ContextMenu;
    return exts[0].m_impl.ctxtmenu = new PerlShellExtCtxtMenu(this);
  }
  if(exts[1].m_type==Unknown) {
    exts[1].m_type = ContextMenu;
    return exts[1].m_impl.ctxtmenu = new PerlShellExtCtxtMenu(this);
  }
  return 0;
}
*/

IUnknown *PerlShellExt::newPerlShellExtInit(Ext& e) 
{
  e.m_type = ShellExtInit;
  return e.m_impl.init = new PerlShellExtInit(this);
}
IUnknown *PerlShellExt::newPerlShellExtCtxtMenu(Ext& e)
{
  e.m_type = ContextMenu;
  return e.m_impl.ctxtmenu = new PerlShellExtCtxtMenu(this);
}
IUnknown *PerlShellExt::newPerlQueryInfoExt(Ext& e) 
{
  e.m_type = QueryInfo;
  return e.m_impl.queryinfo = new PerlQueryInfoExt(this);
}
IUnknown *PerlShellExt::newPerlPropSheetExt(Ext& e)
{
  e.m_type = PropSheet;
  return e.m_impl.propsheet = new PerlPropSheetExt(this);
}
IUnknown *PerlShellExt::newPerlCopyHookExt(Ext& e)
{
  e.m_type = CopyHook;
  return e.m_impl.copyhook = new PerlCopyHookExt(this);
}
IUnknown *PerlShellExt::newPerlPersistFileExt(Ext& e)
{
  e.m_type = PersistFile;
  return e.m_impl.persistfile = new PerlPersistFileExt(this);
}
IUnknown *PerlShellExt::newPerlIconHandlerExt(Ext& e)
{
  e.m_type = IconHandler;
  return e.m_impl.iconhandler = new PerlIconHandlerExt(this);
}
IUnknown *PerlShellExt::newPerlDataObjectExt(Ext& e)
{
  e.m_type = DataObject;
  return e.m_impl.dataobject = new PerlDataObjectExt(this);
}
IUnknown *PerlShellExt::newPerlDropTargetExt(Ext& e)
{
  e.m_type = DropTarget;
  return e.m_impl.droptarget = new PerlDropTargetExt(this);
}
IUnknown *PerlShellExt::newPerlColumnProviderExt(Ext& e) {
  e.m_type = ColumnProvider;
  return e.m_impl.column = new PerlColumnProviderExt(this);
}
