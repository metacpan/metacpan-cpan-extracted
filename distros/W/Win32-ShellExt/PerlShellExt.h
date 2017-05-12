// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _PerlShellExt_H
#define _PerlShellExt_H

class PerlShellExtClassFactory;

class PerlShellExtInit;
class PerlShellExtCtxtMenu;
class PerlColumnProviderExt;
class PerlQueryInfoExt;
class PerlPersistFileExt;
class PerlCopyHookExt;
class PerlDataObjectExt;
class PerlDropTargetExt;
class PerlPropSheetExt;
class PerlIconHandlerExt;

//
// This is the class that is the shell extension per se. Now this class knows its factory (which holds the clsid,
// that's just a way of sharing the clsid and perl interpreter objects amongst instances of the same COM class).
// Objects of this class morph into a context menu extension or a queryinfo extension object when the 
// QueryInterface that allows us to know what the caller wants occurs. This allows me to reuse the same factory
// code for both kinds of extension (it avoids creating 2 separate DLLs, each one with the factory code).
//
// Each extension class (PerlShellExtCtxtMenu, PerlQueryInfoExt) is written in the same fashion: whenever there
// are several interfaces to implement, instead of using multiple inheritance (or using the ugly MFC macros), i
// aggregate inside the main C++ class as many c++ classes each deriving from one of the additional interfaces,
// but delegating everything COM-related (i.e. IUnknown's members) back to the 'master' object.
//
class WIN32SHELLEXTAPI PerlShellExt : public IUnknown
{
  PerlShellExt(const PerlShellExt&);
  PerlShellExt& operator=(const PerlShellExt&);
public:
  PerlShellExt(PerlShellExtClassFactory *factory, SV *obj);
  ~PerlShellExt();
  
  //IUnknown members
  STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
  STDMETHODIMP_(ULONG)	AddRef();
  STDMETHODIMP_(ULONG)	Release();

  void SetContext();
  inline SV *Object() { return m_obj; }
  inline PerlShellExtClassFactory *factory() { return m_factory; }
  inline const CLSID& clsid() { return m_factory->clsid(); } 

  
  enum ExtType {
    Unknown,
    ShellExtInit,
    ContextMenu,
    ColumnProvider,
    QueryInfo,
    PersistFile,
    CopyHook,
    DataObject,
    DropTarget,
    PropSheet,
    IconHandler
  };

  // these are needed because some implementations work in pair,
  // so each one needs to be able to find the other.
  PerlShellExtInit *FindShellExtInit();
  PerlShellExtCtxtMenu *FindCtxtMenuExt();
  PerlQueryInfoExt *FindQueryInfoExt();
  PerlPersistFileExt *FindPersistFileExt();
  PerlCopyHookExt *FindCopyHookExt();
  PerlDataObjectExt *FindDataObjectExt();
  PerlDropTargetExt *FindDropTargetExt();
  PerlPropSheetExt *FindShellPropSheetExt();

  //PerlShellExtCtxtMenu *LoadCtxtMenuExt();
  
protected:
  ULONG        m_cRefs;
  SV *m_obj;
  PerlShellExtClassFactory *m_factory; // every instance of this class owns one reference to the factory that created it.
                                       // All instances of the same extension (same CLSID) have the same factory, since that's
                                       // the same script that is loaded.
  struct Ext {
    PerlShellExt::ExtType m_type;
    union {
      IUnknown *unknown;
      PerlShellExtInit *init;
      PerlShellExtCtxtMenu *ctxtmenu;
      PerlColumnProviderExt *column;
      PerlQueryInfoExt *queryinfo;
      PerlPersistFileExt *persistfile;
      PerlCopyHookExt *copyhook;
      PerlDataObjectExt *dataobject;
      PerlDropTargetExt *droptarget;
      PerlPropSheetExt *propsheet;
      PerlIconHandlerExt *iconhandler;
    } m_impl; // an extension cannot be at the same time a ContextMenu one and a QueryInfo one.
  };
  Ext exts[2]; // we allow at most 2 interfaces implemented per object. this wastes 8 bytes in PerlShellExt over having a list, but we avoid some dynamic allocation.


  IUnknown *newPerlShellExtInit(Ext& e);
  IUnknown *newPerlShellExtCtxtMenu(Ext& e);
  IUnknown *newPerlQueryInfoExt(Ext& e);
  IUnknown *newPerlPropSheetExt(Ext& e);
  IUnknown *newPerlCopyHookExt(Ext& e);
  IUnknown *newPerlColumnProviderExt(Ext& e);
  IUnknown *newPerlPersistFileExt(Ext& e);
  IUnknown *newPerlIconHandlerExt(Ext& e);
  IUnknown *newPerlDataObjectExt(Ext& e);
  IUnknown *newPerlDropTargetExt(Ext& e);
  
  void Release(Ext& e);
};
#endif

