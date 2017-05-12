/**********************************************************************/
/*                     C o n t a i n e r . x s                        */
/**********************************************************************/

/* $Id: AxWindow.xs,v 1.2 2006/06/11 15:46:49 robertemay Exp $ */

#include <atlbase.h>

CComModule _Module;

#include <atlcom.h>
#include <atlhost.h>
#include <atlctl.h>

#include <winbase.h>

/*====================================================================*/
/*                          Perl Compatibility                        */
/*====================================================================*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*====================================================================*/
/*                           Internal function                        */
/*====================================================================*/

//////////////////////////////////////////////////////////////////////
// Perl helper function
//////////////////////////////////////////////////////////////////////

SV**
hv_fetch_mg(HV *hv, char *key, U32 klen, I32 lval) {
        SV** tempsv;
        tempsv = hv_fetch(hv, key, klen, lval);
        if(SvMAGICAL(hv)) mg_get(*tempsv);
        return tempsv;
}

SV**
hv_store_mg(HV *hv, char *key, U32 klen, SV* val, U32 hash) {
        SV** tempsv;
        tempsv = hv_store(hv, key, klen, val, hash);
        if(SvMAGICAL(hv)) mg_set(val);
        return tempsv;
}

/*====================================================================*/
/*                           CMethod                                  */
/*====================================================================*/

typedef struct {
          VARTYPE vt;
          int flag;
        } ParamStruct;

class CMethod
{
public:
    // Constructeur
    CMethod::CMethod();
    CMethod(FUNCDESC* pfd, ITypeInfo* pTypeInfo);

    // Destructeur
    ~CMethod();

    // Member Access
    inline DISPID  GetDispId()         { return m_dispid;             }
    inline LPCSTR  GetName()           { return m_strName;            }
    inline LPCSTR  GetDesc()           { return m_strDesc;            }
    inline LPCSTR  GetProto()          { return m_strProto;           }
    inline short   GetParamOptCount()  { return m_iParamsOpt;         }
    inline WORD    GetInvokeFlag()     { return m_invokeflag;         }

    // FOR Properties
    inline void    SetInvokeFlag(WORD flag)     { m_invokeflag = flag; }

    short   GetParamCount()
    {
      return  (m_invokeflag <= DISPATCH_PROPERTYGET ? m_iParams : m_iParams + 1);
    }
    VARTYPE GetParamType(int i)
    {
      if (m_invokeflag <= DISPATCH_PROPERTYGET)
        return m_TypeParams[i].vt;
      else
        return (i > 0 ? m_TypeParams[i-1].vt : m_vtReturn);
    }
    int     GetParamFlag(int i)
    {
      if (m_invokeflag <= DISPATCH_PROPERTYGET)
        return m_TypeParams[i].flag;
      else
        return (i > 0 ? m_TypeParams[i-1].flag : 0);
    }
    VARTYPE GetReturnType()
    {
      return (m_invokeflag <= DISPATCH_PROPERTYGET ? m_vtReturn : VT_VOID);
    }

protected:
    DISPID        m_dispid;     // Member ID
    LPSTR         m_strName;    // Method Name
    LPSTR         m_strDesc;    // Method Description
    LPSTR         m_strProto;   // Method Prototype
    WORD          m_invokeflag; // Invoke methode flag

    short         m_iParams;    // Count of total number of parameters
    short         m_iParamsOpt; // Count of optional parameters
    VARTYPE       m_vtReturn;   // Return Type
    ParamStruct * m_TypeParams; // Paramype

private:
    LPSTR MakeProto (FUNCDESC* pfd, ITypeInfo* pTypeInfo);

private :
    static void GetTypeDesc(char * buffer, TYPEDESC* typeDesc, ITypeInfo* pTypeInfo);
    static void GetCustomType(char * buffer, HREFTYPE refType, ITypeInfo* pti);
};


//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CMethod::CMethod()
{
  m_strName    = NULL;
  m_strDesc    = NULL;
  m_strProto   = NULL;
  m_iParams    = 0;
  m_iParamsOpt = 0;
  m_TypeParams = NULL;
}

CMethod::CMethod(FUNCDESC* pfd, ITypeInfo* pTypeInfo)
{
    USES_CONVERSION;

    CComBSTR bstrName;
    CComBSTR bstrDesc;

    // Load documentation
    pTypeInfo->GetDocumentation(pfd->memid, &bstrName, &bstrDesc, NULL, NULL);

    m_strName    = strdup((!bstrName ? "" : OLE2T(bstrName)));
    m_strDesc    = strdup((!bstrDesc ? "" : OLE2T(bstrDesc)));
    m_strProto   = MakeProto (pfd, pTypeInfo);

    m_dispid     = pfd->memid;
    m_iParams    = pfd->cParams;
    m_iParamsOpt = pfd->cParamsOpt;

    m_invokeflag = DISPATCH_METHOD;

    // Return Type
    m_vtReturn    = pfd->elemdescFunc.tdesc.vt;
    if (m_vtReturn == VT_SAFEARRAY  || m_vtReturn == VT_PTR)
        m_vtReturn = VT_BYREF | pfd->elemdescFunc.tdesc.lptdesc->vt;

    // Init parameter structure call
    if (m_iParams != 0)
    {
        m_TypeParams        = new ParamStruct [m_iParams];

        // Param in reverse order
        for (int i = 0, j = m_iParams-1 ; i < m_iParams; ++i, --j)
        {
            m_TypeParams[j].vt   = pfd->lprgelemdescParam[i].tdesc.vt;
            m_TypeParams[j].flag = pfd->lprgelemdescParam[i].paramdesc.wParamFlags & PARAMFLAG_FOUT;

            if (m_TypeParams[j].vt == VT_SAFEARRAY  ||
                m_TypeParams[j].vt == VT_PTR)
                m_TypeParams[j].vt = VT_BYREF | pfd->lprgelemdescParam[i].tdesc.lptdesc->vt;
        }
    }
}

CMethod::~CMethod()
{
    if (m_iParams != 0)
    {
        delete [] m_TypeParams;
        m_iParams = 0;
    }

    delete m_strName;
    delete m_strDesc;
    delete m_strProto;
}


//////////////////////////////////////////////////////////////////////
// Génération du prototype
//////////////////////////////////////////////////////////////////////

char * CMethod::MakeProto (FUNCDESC* pfd, ITypeInfo* pTypeInfo)
{
    char buffer [32000];

    buffer [0] = '\0';
    GetTypeDesc(buffer, &pfd->elemdescFunc.tdesc, pTypeInfo);
    strcat (buffer, " ");
    strcat (buffer, m_strName);
    strcat (buffer, "(");

    for(short curParam = 0; curParam < pfd->cParams; ++curParam) {

        if (pfd->lprgelemdescParam[curParam].paramdesc.wParamFlags & PARAMFLAG_FIN)
            strcat (buffer, "in ");
        if (pfd->lprgelemdescParam[curParam].paramdesc.wParamFlags & PARAMFLAG_FOUT)
            strcat (buffer, "out ");
        if (pfd->lprgelemdescParam[curParam].paramdesc.wParamFlags & PARAMFLAG_FOPT)
            strcat (buffer, "optional ");
        if (pfd->lprgelemdescParam[curParam].paramdesc.wParamFlags & PARAMFLAG_FLCID)
            strcat (buffer, "LCID ");

        GetTypeDesc(buffer, &pfd->lprgelemdescParam[curParam].tdesc, pTypeInfo);

        if (pfd->lprgelemdescParam[curParam].paramdesc.wParamFlags & PARAMFLAG_FHASDEFAULT)
        {
            USES_CONVERSION;

            PARAMDESCEX & paramDescEx = *(pfd->lprgelemdescParam[curParam].paramdesc.pparamdescex);
            CComVariant v ((VARIANT &) paramDescEx.varDefaultValue);
            if (v.ChangeType(VT_BSTR) == S_OK)
            {
              strcat (buffer," = ");
              strcat (buffer, OLE2T(v.bstrVal));
            }
            else
              strcat (buffer," = ?");
        }

        if(curParam < pfd->cParams - 1) strcat (buffer, ", ");
    }

    strcat (buffer, ");");

    return strdup (buffer);
}

void CMethod::GetCustomType (LPSTR buffer, HREFTYPE refType, ITypeInfo* pti) {

    CComPtr<ITypeInfo> pTypeInfo(pti);
    CComPtr<ITypeInfo> pCustTypeInfo;

    HRESULT hr = pTypeInfo->GetRefTypeInfo(refType, &pCustTypeInfo);

    if (hr)
    {
      strcat (buffer, "UnknownCustomType");
      return;
    }

    CComBSTR bstrType;

    hr = pCustTypeInfo->GetDocumentation(-1, &bstrType, 0, 0, 0);

    if (hr)
    {
      strcat (buffer, "UnknownCustomType");
      return;
    }

    char ansiType[MAX_PATH];
    WideCharToMultiByte(CP_ACP, 0, bstrType, bstrType.Length() + 1, ansiType, MAX_PATH, 0, 0);
    strcat (buffer, ansiType);

    return;
}

void CMethod::GetTypeDesc(LPSTR buffer, TYPEDESC* typeDesc, ITypeInfo* pTypeInfo) {

    if(typeDesc->vt == VT_PTR)
    {
        strcat (buffer, "PTR[");
        GetTypeDesc(buffer, typeDesc->lptdesc, pTypeInfo);
        strcat (buffer, "]");
        return;
    }
    if(typeDesc->vt == VT_SAFEARRAY)
    {
        strcat (buffer, "SAFEARRAY[");
        GetTypeDesc(buffer, typeDesc->lptdesc, pTypeInfo);
        strcat (buffer, "]");
        return;
    }
    if(typeDesc->vt == VT_CARRAY)
    {
        char buf [100];

        GetTypeDesc(buffer, &typeDesc->lpadesc->tdescElem, pTypeInfo);
        for (int dim(0); typeDesc->lpadesc->cDims; ++dim)
        {
            sprintf (buf, "CARRAY[%i...%i]",
                     typeDesc->lpadesc->rgbounds[dim].lLbound,
                     (typeDesc->lpadesc->rgbounds[dim].cElements + typeDesc->lpadesc->rgbounds[dim].lLbound - 1));
            strcat(buffer, buf);
        }
        return;
    }
    if(typeDesc->vt == VT_USERDEFINED)
    {
        GetCustomType(buffer, typeDesc->hreftype, pTypeInfo);
        return;
    }

    switch(typeDesc->vt)
    {
      case VT_BOOL:     strcat (buffer, "BOOL");      break;
      case VT_I1:       strcat (buffer, "I1");        break;
      case VT_UI1:      strcat (buffer, "UI1");       break;
      case VT_I2:       strcat (buffer, "I2");        break;
      case VT_UI2:      strcat (buffer, "UI2");       break;
      case VT_I4:       strcat (buffer, "I4");        break;
      case VT_UI4:      strcat (buffer, "UI4");       break;
      case VT_INT:      strcat (buffer, "INT");       break;
      case VT_UINT:     strcat (buffer, "UINT");      break;
      case VT_I8:       strcat (buffer, "I8");        break;
      case VT_UI8:      strcat (buffer, "UI8");       break;
      case VT_R4:       strcat (buffer, "R4");        break;
      case VT_R8:       strcat (buffer, "R8");        break;
      case VT_CY:       strcat (buffer, "CY");        break;
      case VT_DECIMAL:  strcat (buffer, "DECIMAL");   break;
      case VT_DATE:     strcat (buffer, "DATE");      break;
      case VT_BSTR:     strcat (buffer, "BSTR");      break;
      case VT_LPSTR:    strcat (buffer, "LPSTR");     break;
      case VT_LPWSTR:   strcat (buffer, "LPWSTR");    break;
      case VT_VOID:     strcat (buffer, "VOID");      break;
      case VT_HRESULT:  strcat (buffer, "HRESULT");   break;
      case VT_ERROR:    strcat (buffer, "SCODE");     break;
      case VT_VARIANT:  strcat (buffer, "VARIANT");   break;
      case VT_DISPATCH: strcat (buffer, "IDispatch"); break;
      case VT_UNKNOWN:  strcat (buffer, "IUnknown");  break;
      default :         strcat (buffer, "$$$ERROR$$$");
    }
    return;
}

/*====================================================================*/
/*                           CProperty                                */
/*====================================================================*/

class CProperty : public CMethod
{
public:

    CProperty (FUNCDESC* pfd, ITypeInfo* pTypeInfo);
    CProperty (VARDESC* pvd, ITypeInfo* pTypeInfo);
    ~CProperty ();

    HRESULT EnumValues (LPSTR enumvalues);
    long GetEnumValue  (LPSTR enumvalue);

    inline VARTYPE GetVarType () { return m_vtReturn;       }
    inline BOOL    isReadOnly () { return m_bReadOnly;      }
    inline BOOL    isEnum     () { return m_spInfo != NULL; }

    inline void SetReadOnly (BOOL readonly) { m_bReadOnly = readonly; }

    LPCSTR  GetStrVarType  ();

private :

    BOOL               m_bReadOnly; // ReadOnly property
    CComPtr<ITypeInfo> m_spInfo;    // Enum type info

private :

    static HRESULT GetEnumTypeInfo (ITypeInfo *pTI, HREFTYPE hrt,
                                    ITypeInfo** ppEnumInfo);
    static VARTYPE GetUserDefinedType (ITypeInfo *pTI, HREFTYPE hrt);
};


//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CProperty::CProperty(FUNCDESC* pfd, ITypeInfo* pTypeInfo) : CMethod (pfd, pTypeInfo)
{

  // ReadOnly by default
  m_bReadOnly = TRUE;

  m_invokeflag = DISPATCH_PROPERTYGET;

  // Load user type Info
  if (pfd->elemdescFunc.tdesc.vt == VT_USERDEFINED)
  {
    HREFTYPE hrt = pfd->elemdescFunc.tdesc.hreftype;
    HRESULT hr = E_FAIL;
    hr = GetEnumTypeInfo(pTypeInfo, hrt, &m_spInfo);
    if(FAILED(hr))
      m_vtReturn = GetUserDefinedType(pTypeInfo, hrt);
  }

}

CProperty::CProperty(VARDESC* pvd, ITypeInfo* pTypeInfo)
{

  USES_CONVERSION;

  // Load documentation
  CComBSTR bstrName (" ");
  CComBSTR bstrDesc (" ");

  pTypeInfo->GetDocumentation(pvd->memid, &bstrName, &bstrDesc, NULL, NULL);

  // Init variable
  m_dispid    = pvd->memid;

  m_strName  = strdup(!bstrName ? "" : OLE2T(bstrName));
  m_strDesc  = strdup(!bstrDesc ? "" : OLE2T(bstrDesc));

  m_bReadOnly = (pvd->wVarFlags & VARFLAG_FREADONLY);
  m_invokeflag = DISPATCH_PROPERTYGET;

  m_vtReturn  = pvd->elemdescVar.tdesc.vt;

  // Load user type Info
  if (pvd->elemdescVar.tdesc.vt == VT_USERDEFINED)
  {
    HREFTYPE hrt = pvd->elemdescVar.tdesc.hreftype;
    HRESULT hr = E_FAIL;
    hr = GetEnumTypeInfo(pTypeInfo, hrt, &m_spInfo);
    if(FAILED(hr))
      m_vtReturn = GetUserDefinedType(pTypeInfo, hrt);
  }

  {
    char buffer [3000];
    strcpy (buffer, GetStrVarType ());
    strcat (buffer, " ");
    strcat (buffer, m_strName);
    strcat (buffer, "();");
    m_strProto = strdup(buffer);
  }
}

CProperty::~CProperty ()
{
    if (m_spInfo != NULL) m_spInfo.Release();
}

//////////////////////////////////////////////////////////////////////
// EnumValues :
//////////////////////////////////////////////////////////////////////

HRESULT CProperty::EnumValues(LPSTR enumvalues)
{
    USES_CONVERSION;

    enumvalues[0] = '\0';

    if (m_spInfo != NULL)
    {
        TYPEATTR *pta=NULL;
        m_spInfo->GetTypeAttr (&pta);
        if(pta && pta->typekind == TKIND_ENUM)
        {
            VARDESC* pvd=NULL;
            for (int i = 0; i < pta->cVars; i++)
            {
                m_spInfo->GetVarDesc(i, &pvd);
                CComBSTR bstrName;

                m_spInfo->GetDocumentation(pvd->memid, &bstrName, NULL, NULL, NULL);

                sprintf (&enumvalues[strlen(enumvalues)], "%s=%d",
                         OLE2T(bstrName),
                         pvd->lpvarValue->lVal);

                if (i != pta->cVars -1) strcat (enumvalues, ",");

                m_spInfo->ReleaseVarDesc(pvd);
            }
        }
        if(pta)
            m_spInfo->ReleaseTypeAttr(pta);
    }
    return S_OK;
}

//////////////////////////////////////////////////////////////////////
// EnumValues :
//////////////////////////////////////////////////////////////////////

long CProperty::GetEnumValue (LPSTR enumvalue)
{
    long result = -1;

    USES_CONVERSION;

    if (m_spInfo != NULL)
    {
        TYPEATTR *pta=NULL;
        m_spInfo->GetTypeAttr (&pta);
        if(pta && pta->typekind == TKIND_ENUM)
        {
            VARDESC* pvd=NULL;
            for (int i = 0; i < pta->cVars && result == -1; i++)
            {
                m_spInfo->GetVarDesc(i, &pvd);

                CComBSTR bstrName;

                m_spInfo->GetDocumentation(pvd->memid, &bstrName, NULL, NULL, NULL);

                if (strcmp (enumvalue, OLE2T(bstrName)) == 0)
                  result = pvd->lpvarValue->lVal;

                m_spInfo->ReleaseVarDesc(pvd);
            }
        }
        if(pta)
            m_spInfo->ReleaseTypeAttr(pta);
    }

    return result;
}

//////////////////////////////////////////////////////////////////////
// GetUserDefinedType :
//////////////////////////////////////////////////////////////////////

VARTYPE CProperty::GetUserDefinedType(ITypeInfo *pTI, HREFTYPE hrt)
{
    CComPtr<ITypeInfo> spTypeInfo;
    VARTYPE vt = VT_USERDEFINED;
    HRESULT hr = E_FAIL;
    hr = pTI->GetRefTypeInfo(hrt, &spTypeInfo);
    if(FAILED(hr))
        return vt;
    TYPEATTR *pta=NULL;

    spTypeInfo->GetTypeAttr(&pta);
    if(pta && pta->typekind == TKIND_ALIAS)
    {
        if (pta->tdescAlias.vt == VT_USERDEFINED)
            vt = GetUserDefinedType(spTypeInfo,pta->tdescAlias.hreftype);
        else
            vt = pta->tdescAlias.vt;
    }
    if (pta && (pta->typekind == TKIND_INTERFACE ||
                pta->typekind == TKIND_DISPATCH  ||
                pta->typekind == TKIND_COCLASS))
        vt = VT_DISPATCH;

    if(pta)
        spTypeInfo->ReleaseTypeAttr(pta);

    return vt;

}

//////////////////////////////////////////////////////////////////////
// GetEnumTypeInfo :
//////////////////////////////////////////////////////////////////////

HRESULT CProperty::GetEnumTypeInfo(ITypeInfo *pTI, HREFTYPE hrt, ITypeInfo** ppEnumInfo)
{
    CComPtr<ITypeInfo> spTypeInfo;
    HRESULT hr = E_FAIL;
    hr = pTI->GetRefTypeInfo(hrt, &spTypeInfo);
    if(FAILED(hr))
        return hr;
    TYPEATTR *pta=NULL;

    spTypeInfo->GetTypeAttr(&pta);
    if(pta != NULL)
    {
        if (pta->typekind == TKIND_ALIAS)
        {
            if (pta->tdescAlias.vt == VT_USERDEFINED)
                return GetEnumTypeInfo(spTypeInfo,pta->tdescAlias.hreftype, ppEnumInfo);
        }
        else if (pta->typekind == TKIND_ENUM)
            spTypeInfo.CopyTo(ppEnumInfo);

        spTypeInfo->ReleaseTypeAttr(pta);
    }
    return (*ppEnumInfo != NULL) ? S_OK : E_FAIL;
}

//////////////////////////////////////////////////////////////////////
// GetStrVarType() :
//////////////////////////////////////////////////////////////////////

LPCSTR  CProperty::GetStrVarType()
{
    switch(m_vtReturn) {
      case VT_BOOL:        return ("BOOL");
      case VT_I1:          return ("I1");
      case VT_UI1:         return ("UI1");
      case VT_I2:          return ("I2");
      case VT_UI2:         return ("UI2");
      case VT_I4:          return ("I4");
      case VT_UI4:         return ("UI4");
      case VT_INT:         return ("INT");
      case VT_UINT:        return ("UINT");
      case VT_I8:          return ("I8");
      case VT_UI8:         return ("UI8");
      case VT_R4:          return ("R4");
      case VT_R8:          return ("R8");
      case VT_CY:          return ("CY");
      case VT_DECIMAL:     return ("DECIMAL");
      case VT_DATE:        return ("DATE");
      case VT_BSTR:        return ("BSTR");
      case VT_LPSTR:       return ("LPSTR");
      case VT_LPWSTR:      return ("LPWSTR");
      case VT_VOID:        return ("VOID");
      case VT_ERROR:       return ("SCODE");
      case VT_HRESULT:     return ("HRESULT");
      case VT_VARIANT:     return ("VARIANT");
      case VT_UNKNOWN:     return ("IUnknown");
      case VT_DISPATCH:    return ("IDispatch");
      case VT_USERDEFINED:
        if (m_spInfo != NULL)
          return ("ENUM");
        else
          return ("USERDEFINED");
    }

    return ("$$$ERROR$$$");
}


/*====================================================================*/
/*                              CEvent                                */
/*====================================================================*/

class CEvent : public CMethod
{
public :

    // Constructeur
    CEvent (FUNCDESC* pfd, ITypeInfo* pTypeInfo)
           : CMethod (pfd, pTypeInfo),
             m_callback((SV*)NULL) {}

    // Destructeur
    ~CEvent () {}

    void SetCallback (SV * callback);

    inline SV * GetCallback ()              { return m_callback;           }
    inline BOOL HaveCallback()              { return (m_callback != NULL); }

private :
   SV   * m_callback;
};

//////////////////////////////////////////////////////////////////////
// SetCallback
//////////////////////////////////////////////////////////////////////

void CEvent::SetCallback (SV * callback)
{

  if (m_callback == (SV*)NULL)
    m_callback = newSVsv(callback);
  else
    SvSetSV(m_callback, callback);

}

/*====================================================================*/
/*                           CEventMap                                */
/*====================================================================*/

class CEventMap : public IDispatch
{
public:
    // IUnknown methods
    STDMETHOD(QueryInterface)(REFIID riid, LPVOID *ppvObj);
    STDMETHOD_(ULONG, AddRef)(void);
    STDMETHOD_(ULONG, Release)(void);

    // IDispatch methods
    STDMETHOD(GetTypeInfoCount)(UINT *pctinfo);
    STDMETHOD(GetTypeInfo)(
        UINT itinfo,
        LCID lcid,
        ITypeInfo **pptinfo);
    STDMETHOD(GetIDsOfNames)(
        REFIID riid,
        OLECHAR **rgszNames,
        UINT cNames,
        LCID lcid,
        DISPID *rgdispid);
    STDMETHOD(Invoke)(
        DISPID dispidMember,
        REFIID riid,
        LCID lcid,
        WORD wFlags,
        DISPPARAMS *pdispparams,
        VARIANT *pvarResult,
        EXCEPINFO *pexcepinfo,
        UINT *puArgErr);

public:
    CEventMap(): m_Events(NULL),
        m_iEvents(0),
        m_dwMajor(0),
        m_dwMinor(0),
        m_libID(GUID_NULL),
        m_iidSrc(GUID_NULL),
        m_dwCookie(0xFFFFeeee),
        m_refcount(0),
        m_Self((SV *)NULL)
    {}

    ~CEventMap()
    {
     //  printf("CEventMap::~CEventMap\n");

        Clean();

        if (m_spTypeInfo != NULL) m_spTypeInfo.Release();

     //  printf("CEventMap::~CEventMap\n");
    }

    void Clean ()
    {

     //  printf("CEventMap::Clean\n");
       m_Self = NULL;

       // UnAdvise();

       if(m_Events)
       {
            for (ULONG i = 0; i < m_iEvents; i++)
                delete m_Events[i];

            delete [] m_Events;
            m_Events = NULL;
            m_iEvents = 0;
       }

     //  printf("CEventMap::Clean\n");
    }

public:

    HRESULT Init(IUnknown * spunk);

    HRESULT Advise(IUnknown * spunk)
    {
        return AtlAdvise(spunk, this, m_iidSrc, &m_dwCookie);
    }

    HRESULT UnAdvise(IUnknown * spunk)
    {
     //  printf("CEventMap::UnAdvise\n");
        if(m_dwCookie != 0xFFFFeeee)
        {
            AtlUnadvise(spunk,m_iidSrc,m_dwCookie);
            m_dwCookie = 0xFFFFeeee;
            return S_OK;
        }
        return S_FALSE;
    }

    BOOL RegisterEvent (SV * self, char * eventname, SV * callback);
    BOOL RegisterEvent (SV * self, DISPID eventid  , SV * callback);

    inline ULONG    EventCount()        { return m_iEvents;    }
    inline CEvent*  GetEvent(int i)     { return m_Events[i];  }

private:
    HRESULT GetEventTypeInfo(LPTYPEINFO *ppTypeInfo, IUnknown * spunk);

private:
    unsigned short          m_dwMajor;      // major version of typelib
    unsigned short          m_dwMinor;      // minor version of typelib
    GUID                    m_libID;        // LIBID
    IID                     m_iidSrc;       // IID of Event Source interafce

    ULONG                   m_iEvents;      // # of event functions
    CEvent**                m_Events;       // DISPID-FuncName array

    CComPtr<ITypeInfo>      m_spTypeInfo;   // TypeInfo of the Event IID
    DWORD                   m_dwCookie;
    unsigned int            m_refcount;

    SV *                    m_Self;
};

//////////////////////////////////////////////////////////////////////
// QueryInterface
//////////////////////////////////////////////////////////////////////

STDMETHODIMP CEventMap::QueryInterface(REFIID iid, void **ppv)
{

    if (iid == IID_IUnknown || iid == IID_IDispatch || iid == m_iidSrc)
        *ppv = this;
    else {
        *ppv = NULL;
        return E_NOINTERFACE;
    }
    AddRef();
    return S_OK;
}

//////////////////////////////////////////////////////////////////////
// AddRef
//////////////////////////////////////////////////////////////////////

STDMETHODIMP_(ULONG) CEventMap::AddRef(void)
{
    ++m_refcount;
    return m_refcount;
}

//////////////////////////////////////////////////////////////////////
// Release
//////////////////////////////////////////////////////////////////////

STDMETHODIMP_(ULONG) CEventMap::Release(void)
{
    --m_refcount;
    if (m_refcount)
        return m_refcount;
    m_refcount = 0;
    return 0;
}

//////////////////////////////////////////////////////////////////////
// GetTypeInfoCount
//////////////////////////////////////////////////////////////////////

STDMETHODIMP CEventMap::GetTypeInfoCount(UINT *pctinfo)
{
    *pctinfo = 0;
    return S_OK;
}

//////////////////////////////////////////////////////////////////////
// GetTypeInfo
//////////////////////////////////////////////////////////////////////

STDMETHODIMP CEventMap::GetTypeInfo(UINT itinfo, LCID lcid, ITypeInfo **pptinfo)
{
    *pptinfo = NULL;
    return DISP_E_BADINDEX;
}

//////////////////////////////////////////////////////////////////////
// GetIDsOfNames
//////////////////////////////////////////////////////////////////////

STDMETHODIMP CEventMap::GetIDsOfNames (REFIID riid, LPOLESTR* rgszNames,
                                       UINT cNames,LCID lcid, DISPID* rgdispid)
{
    return m_spTypeInfo->GetIDsOfNames(rgszNames, cNames, rgdispid);
}


//////////////////////////////////////////////////////////////////////
// Invoke
//////////////////////////////////////////////////////////////////////

STDMETHODIMP CEventMap::Invoke(DISPID dispidMember, REFIID riid, LCID lcid, WORD wFlags,
                               DISPPARAMS* pdispparams, VARIANT* pvarResult,
                               EXCEPINFO* pexcepinfo, UINT* puArgErr)
{
    VARIANT *    pArg = NULL;
    SV      *    svref [200];
    int i;

    if (riid != IID_NULL) { return DISP_E_UNKNOWNINTERFACE;}
    if(!pdispparams)      { return E_POINTER; }

    if (m_Self != NULL)
    {
       for (UINT n=0; n < m_iEvents; n++)
       {
           if(dispidMember == m_Events[n]->GetDispId())
           {
               if (m_Events[n]->HaveCallback())
               {
                  dSP ;

                  ENTER ;
                  SAVETMPS ;

                  PUSHMARK(SP) ;
                  XPUSHs(m_Self);
                  XPUSHs(sv_2mortal(newSViv(dispidMember)));

                  for (i = pdispparams->cArgs - 1; i >= 0; --i)
                  {
                    pArg = &pdispparams->rgvarg[i];

                    if (pArg->vt == (VT_BYREF | VT_VARIANT))
                        pArg = pArg->pvarVal;

                    switch (pArg->vt)
                    {
                      case VT_I1 :
                      case VT_UI1:

                        svref[i] = sv_2mortal(newSViv(pArg->bVal));
                        break;

                      case VT_I2 :
                      case VT_UI2:

                        svref[i] = sv_2mortal(newSViv(pArg->iVal));
                        break;

                      case VT_I4 :
                      case VT_UI4:
                      case VT_INT:
                      case VT_UINT:

                        svref[i] = sv_2mortal(newSViv(pArg->lVal));
                        break;

                      case VT_R4 :

                        svref[i] = sv_2mortal(newSVnv(pArg->fltVal));
                        break;

                      case VT_R8 :

                        svref[i] = sv_2mortal(newSVnv(pArg->dblVal));
                        break;

                      case VT_BOOL:

                        svref[i] = sv_2mortal(newSViv(pArg->boolVal));
                        break;

                      case VT_BYREF | VT_I1 :
                      case VT_BYREF | VT_UI1:

                        svref[i] = sv_2mortal(newSViv(*pArg->pbVal));
                        break;

                      case VT_BYREF | VT_I2 :
                      case VT_BYREF | VT_UI2:

                        svref[i] = sv_2mortal(newSViv(*pArg->piVal));
                        break;

                      case VT_BYREF | VT_I4 :
                      case VT_BYREF | VT_UI4:
                      case VT_BYREF | VT_INT:
                      case VT_BYREF | VT_UINT:

                        svref[i] = sv_2mortal(newSViv(*pArg->piVal));
                        break;

                      case VT_BYREF | VT_R4 :

                        svref[i] = sv_2mortal(newSVnv(*pArg->pfltVal));
                        break;

                      case VT_BYREF | VT_R8 :

                        svref[i] = sv_2mortal(newSVnv(*pArg->pdblVal));
                        break;

                      case VT_BYREF | VT_BOOL :

                        svref[i] = sv_2mortal(newSViv(*pArg->pboolVal));
                        break;

                      case VT_BSTR :
                        {
                           USES_CONVERSION;

                           svref[i] = sv_2mortal(newSVpv((char *) OLE2T(pArg->bstrVal), 0));
                           break;
                        }
                      case VT_BYREF | VT_BSTR :
                        {
                           USES_CONVERSION;

                           svref[i] = sv_2mortal(newSVpv((char *) OLE2T(*pArg->pbstrVal), 0));
                           break;
                        }
                    }

                    XPUSHs(svref[i]);
                  }

                  PUTBACK ;

                  call_sv(m_Events[n]->GetCallback(), G_EVAL | G_DISCARD);

                  // Output parameter

                  for (i = pdispparams->cArgs - 1; i >= 0; --i)
                  {
                     pArg = &pdispparams->rgvarg[i];

                     if (pArg->vt & VT_BYREF)
                       continue;

                     if (pArg->vt == (VT_BYREF | VT_VARIANT))
                       pArg = pArg->pvarVal;

                     switch (pArg->vt)
                     {
                       case VT_I1 :
                       case VT_UI1:

                         pArg->bVal = (BYTE)SvIV(svref[i]);
                         break;

                       case VT_I2 :
                       case VT_UI2:

                         pArg->iVal = (SHORT)SvIV(svref[i]);
                         break;

                       case VT_I4 :
                       case VT_UI4:
                       case VT_INT:
                       case VT_UINT:

                         pArg->lVal = (LONG)SvIV(svref[i]);
                         break;

                       case VT_R4 :

                         pArg->fltVal = (FLOAT)SvNV(svref[i]);
                         break;

                       case VT_R8 :

                         pArg->dblVal = (DOUBLE)SvNV(svref[i]);
                         break;

                       case VT_BOOL:

                         pArg->boolVal = (VARIANT_BOOL)SvIV(svref[i]);
                         break;

                       case VT_BYREF | VT_I1 :
                       case VT_BYREF | VT_UI1:

                         *pArg->pbVal = (BOOL)SvIV(svref[i]);
                         break;

                       case VT_BYREF | VT_I2 :
                       case VT_BYREF | VT_UI2:

                         *pArg->piVal = (SHORT)SvIV(svref[i]);
                         break;

                       case VT_BYREF | VT_I4 :
                       case VT_BYREF | VT_UI4:
                       case VT_BYREF | VT_INT:
                       case VT_BYREF | VT_UINT:

                         *pArg->plVal = (LONG)SvIV(svref[i]);
                         break;

                       case VT_BYREF | VT_R4 :

                         *pArg->pfltVal = (FLOAT)SvNV(svref[i]);
                         break;

                       case VT_BYREF | VT_R8 :

                         *pArg->pdblVal = (DOUBLE)SvNV(svref[i]);
                         break;

                       case VT_BYREF | VT_BOOL :

                         *pArg->pboolVal = (VARIANT_BOOL)SvIV(svref[i]);
                         break;

                       case VT_BSTR :
                         {
                            CComBSTR bstr;

                            bstr.Attach (pArg->bstrVal);
                            bstr = (LPCSTR) SvPV_nolen (svref[i]);
                            bstr.Detach();

                            break;
                         }
                       case VT_BYREF | VT_BSTR :
                         {
                            CComBSTR bstr;

                            bstr.Attach (*pArg->pbstrVal);
                            bstr = (LPCSTR) SvPV_nolen (svref[i]);
                            bstr.Detach();

                            break;
                         }
                     }
                  }

                  FREETMPS ;

                  LEAVE ;
               }

               return S_OK;;
           }
       }
    }

    return S_OK;;
}

//////////////////////////////////////////////////////////////////////
// GetEventTypeInfo
//////////////////////////////////////////////////////////////////////

HRESULT CEventMap::GetEventTypeInfo (LPTYPEINFO *ppTypeInfo, IUnknown * spunk)
{
    if(!ppTypeInfo) { return E_POINTER; }

    // This gets the LIBID, IIDSrc, and version
    HRESULT hr = AtlGetObjectSourceInterface(spunk, &m_libID, &m_iidSrc, &m_dwMajor, &m_dwMinor);
    if(FAILED(hr)) return hr;

    CComPtr<IDispatch> spDispatch;
    hr = spunk->QueryInterface(&spDispatch);
    if(FAILED(hr)) return hr;

    CComPtr<ITypeInfo> spTypeInfo;
    hr = spDispatch->GetTypeInfo(0, 0, &spTypeInfo);
    if(FAILED(hr)) return hr;

    CComPtr<ITypeLib> spTypeLib;
    hr = spTypeInfo->GetContainingTypeLib(&spTypeLib, 0);
    if(FAILED(hr)) return hr;

    return spTypeLib->GetTypeInfoOfGuid(m_iidSrc, ppTypeInfo);
}


//////////////////////////////////////////////////////////////////////
// Init
//////////////////////////////////////////////////////////////////////

HRESULT CEventMap::Init (IUnknown * spunk)
{

    USES_CONVERSION;

    Clean();

    HRESULT hr = GetEventTypeInfo(&m_spTypeInfo, spunk);
    if(FAILED(hr)) return 0;           // Control without Event

    LPTYPEATTR       pta = 0;
    hr = m_spTypeInfo->GetTypeAttr(&pta);

    if(FAILED(hr))
    {
      m_spTypeInfo.Release();
      return hr;
    }

    if (pta->cFuncs != 0)
    {
        m_iEvents = 0;
        m_Events  = new CEvent* [pta->cFuncs];
        if(m_Events == NULL)
        {
            m_spTypeInfo->ReleaseTypeAttr(pta);
            return E_OUTOFMEMORY;
        }
        memset (m_Events, 0, sizeof (CEvent *) * pta->cFuncs);
    }

    for (UINT n = 0; n < pta->cFuncs; n++)
    {
        LPFUNCDESC pfd = 0;

        hr = m_spTypeInfo->GetFuncDesc (n, &pfd);
        if(FAILED(hr)) continue;

        m_Events[m_iEvents] = new CEvent (pfd, m_spTypeInfo);
        if (m_Events[m_iEvents] == NULL)
        {
          Clean();
          m_spTypeInfo->ReleaseFuncDesc(pfd);
          m_spTypeInfo->ReleaseTypeAttr(pta);
          return E_OUTOFMEMORY;
        }
        m_iEvents ++;

        m_spTypeInfo->ReleaseFuncDesc(pfd);
    }

    m_spTypeInfo->ReleaseTypeAttr(pta);

    return Advise(spunk);
}


//////////////////////////////////////////////////////////////////////
// RegisterEvent
//////////////////////////////////////////////////////////////////////

BOOL CEventMap::RegisterEvent (SV * self, char * eventname, SV * callback)
{

  for(UINT n = 0; n < m_iEvents; n++)
  {
    if (strcmp (m_Events[n]->GetName(), eventname) == 0)
    {
       if (m_Self == NULL)
          m_Self = newSVsv(self);

       m_Events[n]->SetCallback (callback);

       return TRUE;
    }
  }

  return FALSE;
}

BOOL CEventMap::RegisterEvent (SV * self, DISPID eventid, SV * callback)
{

  for(UINT n = 0; n < m_iEvents; n++)
  {
    if (m_Events[n]->GetDispId() == eventid)
    {
       if (m_Self == NULL)
          m_Self = newSVsv(self);

       m_Events[n]->SetCallback (callback);

       return TRUE;
    }
  }

  return FALSE;
}

/*====================================================================*/
/*                           CContainer                               */
/*====================================================================*/

class CContainer
{
public:
    CContainer();
    ~CContainer();

    int Create (HWND hWndParent, LPRECT lpRect, LPCTSTR szControlName,
                                DWORD dwStyle = 0, DWORD dwExStyle = 0);
    void Clean ();

    CProperty * FindProperty (DISPID id);
    CProperty * FindProperty (LPSTR name);

    CMethod * FindMethod (DISPID id);
    CMethod * FindMethod (LPSTR name);

    CEvent * FindEvent  (DISPID id);
    CEvent * FindEvent  (LPSTR name);

    inline unsigned int MethodCount() { return m_iMethods; }
    inline unsigned int PropertyCount() { return m_iProperties; }

    inline CProperty * Property (unsigned int i) { return m_Properties[i]; }
    inline CMethod   * Method   (unsigned int i) { return m_Methods   [i]; }
    inline CEventMap * EventMap (void)           { return &m_EventMap; }


    inline IDispatch* GetIDispatch() { return m_spDispatch.p; }

    inline HRESULT Call (CMethod *method, VARIANT * value, DISPPARAMS * dispparams)
    {
      DISPID dispidPut = DISPID_PROPERTYPUT;

      if (method->GetInvokeFlag() >= DISPATCH_PROPERTYPUT)
      {
         dispparams->cNamedArgs = 1;
         dispparams->rgdispidNamedArgs = &dispidPut;
      }

      return m_spDispatch->Invoke (method->GetDispId(), IID_NULL,
                                   0, method->GetInvokeFlag(),
                                   dispparams, value, NULL, NULL);
    }

    inline HWND GethWnd() { return m_Wnd.m_hWnd; }

private :

    HRESULT LoadTypeInfo ();

protected :
    CAxWindow              m_Wnd;          // ActiveX hosting Window
    CComPtr<IDispatch>     m_spDispatch;   // IDispatch
    CProperty **           m_Properties;   // List of ActiveX Properties
    unsigned int           m_iProperties;
    CMethod  **            m_Methods;      // List of ActiveX Methods
    unsigned int           m_iMethods;

    CEventMap              m_EventMap;     // ActiveX Event Manager
};

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CContainer::CContainer()
{
    m_iProperties = m_iMethods = 0;
    m_Properties = NULL;
    m_Methods = NULL;
}

CContainer::~CContainer()
{
    // printf("CContainer::~CContainer\n");
    Clean ();
    // printf("CContainer::~CContainer\n");
}

void CContainer::Clean ()
{
    unsigned int i;

    // printf("CContainer::Clean\n");

    if (m_Properties != NULL)
    {
        for (i = 0; i < m_iProperties; i++)
            delete m_Properties[i];

        delete [] m_Properties; m_Properties = NULL;
        m_iProperties = 0;
    }

    if (m_Methods != NULL)
    {
        for (i = 0; i < m_iMethods; i++)
            delete m_Methods[i];

        delete [] m_Methods; m_Methods = NULL;
        m_iMethods = 0;
    }

  // printf("CContainer::Clean : Dispatch\n");

    if (m_spDispatch != NULL)
    {
        m_EventMap.UnAdvise(m_spDispatch.p);
        m_spDispatch.Release();
    }

    m_EventMap.Clean();

  //  printf("CContainer::Clean\n");
}

//////////////////////////////////////////////////////////////////////
// Create Container Control
//////////////////////////////////////////////////////////////////////

int CContainer::Create (HWND hWndParent, LPRECT lpRect, LPCTSTR szControlName,
                                                DWORD dwStyle, DWORD dwExStyle)
{
    HRESULT hr;
    Clean();

  // printf("CContainer::Create : CAxWindow Create \n");

   if (m_Wnd.Create (hWndParent, lpRect, szControlName, dwStyle, dwExStyle) == NULL)
     return -1;

  // printf("CContainer::Create : QueryControl\n");

    IDispatch * disp;
    hr = m_Wnd.QueryControl(IID_IDispatch, (void **)&disp);
    if (FAILED (hr)) return -2;
    m_spDispatch = disp;

  // printf("CContainer::Create : LoadTypeInfo \n");

    hr = LoadTypeInfo ();
    if (FAILED (hr)) return -3;

  // printf("CContainer::Create : m_EventMap\n");

    hr = m_EventMap.Init(m_spDispatch.p);
    if (FAILED (hr)) return -4;

  // printf("CContainer::Create\n");

    return 0;
}

//////////////////////////////////////////////////////////////////////
// LoadTypeInfo
//////////////////////////////////////////////////////////////////////

HRESULT CContainer::LoadTypeInfo()
{
    CComPtr<ITypeInfo> spTypeInfo;
    int i;

    if (m_spDispatch == NULL)
        return S_OK;

    // Get the type information interface
    m_spDispatch->GetTypeInfo(0, LOCALE_SYSTEM_DEFAULT, &spTypeInfo);

    if (spTypeInfo == NULL)
        return E_FAIL;

    TYPEATTR* pta;
    spTypeInfo->GetTypeAttr(&pta);

    // Must use dual type information interface ?
    if (pta->typekind == TKIND_INTERFACE)
    {
        CComPtr<ITypeInfo> spInfoTemp;
        HREFTYPE hRef;
        HRESULT hr = spTypeInfo->GetRefTypeOfImplType(-1, &hRef);
        if (FAILED(hr)) return E_FAIL;

        hr = spTypeInfo->GetRefTypeInfo(hRef, &spInfoTemp);
        if (FAILED(hr)) return E_FAIL;

        spTypeInfo->ReleaseTypeAttr(pta);
        spTypeInfo = spInfoTemp;
        spTypeInfo->GetTypeAttr(&pta);
    }

    // Allocate m_Methods and m_Properties
    if (pta->cFuncs + pta->cVars != 0)
    {
        m_Properties = new CProperty* [pta->cFuncs + pta->cVars];
        if (pta->cFuncs != 0)
          m_Methods    = new CMethod*   [pta->cFuncs];

        if (m_Properties == NULL || (m_Methods == NULL && pta->cFuncs != 0))
        {
            Clean ();
            spTypeInfo->ReleaseTypeAttr(pta);
            return E_OUTOFMEMORY;
        }

        memset (m_Properties, 0, sizeof (CProperty*) * pta->cFuncs + pta->cVars);
        if (pta->cFuncs != 0)
          memset (m_Methods,  0, sizeof (CMethod*) * pta->cFuncs);
    }

    // Check all Function
    for (i = 0; i < pta->cFuncs; i++)
    {
        FUNCDESC* pfd;
        spTypeInfo->GetFuncDesc(i, &pfd);

        // Property
        if ((pfd->invkind & DISPATCH_PROPERTYGET || pfd->invkind & DISPATCH_PROPERTYPUT) &&
           ((pfd->wFuncFlags & (FUNCFLAG_FRESTRICTED | FUNCFLAG_FHIDDEN)) == 0 ))
        {
            // Find if already load
            CProperty * property = FindProperty (pfd->memid);

            if (property == NULL)
            {
              // Add to Property list.
              property = new CProperty (pfd, spTypeInfo);
              m_Properties [m_iProperties] = property;

              if (m_Properties [m_iProperties] ==  NULL)
              {
                  Clean ();
                  spTypeInfo->ReleaseFuncDesc(pfd);
                  spTypeInfo->ReleaseTypeAttr(pta);
                   return E_OUTOFMEMORY;
              }
              m_iProperties ++;
            }

            if (pfd->invkind & DISPATCH_PROPERTYPUT)
              property->SetReadOnly (FALSE);
        }
        // A Method
        else if (pfd->invkind == DISPATCH_METHOD &&
                ((pfd->wFuncFlags & (FUNCFLAG_FRESTRICTED | FUNCFLAG_FHIDDEN)) == 0 ))
        {
            // Add Method to list
            m_Methods [m_iMethods] = new CMethod (pfd, spTypeInfo);
            if (m_Methods [m_iMethods] ==  NULL)
            {
                Clean ();
                spTypeInfo->ReleaseFuncDesc(pfd);
                spTypeInfo->ReleaseTypeAttr(pta);
                return E_OUTOFMEMORY;
            }
            m_iMethods ++;
        }

        spTypeInfo->ReleaseFuncDesc(pfd);
    }

    // Check all property Vars if exists
    for (i = 0; i < pta->cVars; i++)
    {
        VARDESC* pvd;
        spTypeInfo->GetVarDesc(i, &pvd);
        // Add to Property list.
        CProperty * property = new CProperty (pvd, spTypeInfo);
        m_Properties [m_iProperties] = property;

        if (m_Properties [m_iProperties] ==  NULL)
        {
            Clean ();
            spTypeInfo->ReleaseVarDesc(pvd);
            spTypeInfo->ReleaseTypeAttr(pta);
            return E_OUTOFMEMORY;
        }

        m_iProperties ++;

        spTypeInfo->ReleaseVarDesc(pvd);
    }

    spTypeInfo->ReleaseTypeAttr(pta);

    return S_OK;
}

//////////////////////////////////////////////////////////////////////
// FindProperty
//////////////////////////////////////////////////////////////////////

CProperty * CContainer::FindProperty (DISPID id)
{
  UINT i;

  for (i = 0; i < m_iProperties; i ++)
    if (m_Properties[i]->GetDispId() == id)
      return m_Properties[i];

  return NULL;
}

CProperty * CContainer::FindProperty (LPSTR name)
{
  UINT i;

  for (i = 0; i < m_iProperties; i ++)
    if (strcmp (m_Properties[i]->GetName(), name) == 0)
      return m_Properties[i];

  return NULL;
}

//////////////////////////////////////////////////////////////////////
// FindProperty
//////////////////////////////////////////////////////////////////////

CMethod * CContainer::FindMethod (DISPID id)
{
  UINT i;

  for (i = 0; i < m_iMethods; i ++)
    if (m_Methods[i]->GetDispId() == id)
      return m_Methods[i];

  return NULL;

}

CMethod * CContainer::FindMethod (LPSTR name)
{
  UINT i;

  for (i = 0; i < m_iMethods; i ++)
    if (strcmp (m_Methods[i]->GetName(), name) == 0)
      return m_Methods[i];

  return NULL;

}

//////////////////////////////////////////////////////////////////////
// FindEvent
//////////////////////////////////////////////////////////////////////

CEvent * CContainer::FindEvent  (DISPID id)
{
  UINT i;

  for (i = 0; i < m_EventMap.EventCount(); i ++)
    if (m_EventMap.GetEvent(i)->GetDispId() == id)
      return m_EventMap.GetEvent(i);

  return NULL;
}

CEvent * CContainer::FindEvent  (LPSTR name)
{
  UINT i;

  for (i = 0; i < m_EventMap.EventCount(); i ++)
    if (strcmp (m_EventMap.GetEvent(i)->GetName(), name) == 0)
      return m_EventMap.GetEvent(i);

  return NULL;

}

/*====================================================================*/
/*                Win32::GUI::AxWindow    package                     */
/*====================================================================*/


MODULE = Win32::GUI::AxWindow          PACKAGE = Win32::GUI::AxWindow

PROTOTYPES: ENABLE

  ##################################################################
  #                                                                #
  #              Win32::GUI::AxWindow    package                   #
  #                                                                #
  ##################################################################

  ##################################################################
  #
  # Initialise / DeInitialise
  #

  #
  # _Initialise (internal)
  #

void
_Initialise()
PREINIT:
  HINSTANCE hInstance;
CODE:
    // Initialize COM
    CoInitialize(0);

    // Initialize the ATL module
    hInstance = GetModuleHandle(NULL);
    _Module.Init(0, hInstance);

    // Initialize support for control containment
    AtlAxWinInit();

  #
  # _DeInitialise (internal)
  #

void
_DeInitialise()
CODE:
    // Initialize the ATL module
    _Module.Term();

    // Uninitialize COM
    CoUninitialize();

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  #  Creation
  #

  ##################################################################
  #
  #  Creation
  #

BOOL
_Create(Self, hParent, clsid, style, exstyle, x, y, w, h)
    SV*     Self
    HWND    hParent
    LPCTSTR clsid
    DWORD   style
    DWORD   exstyle
    int     x
    int     y
    int     w
    int     h
PREINIT:
    HV*  hvSelf;
    SV** stored;
    SV*  storing;
    CContainer * container;
    RECT rect;
    BOOL ret = FALSE;
CODE:
    // Get HV Self
    hvSelf = (HV*) SvRV(ST(0));

    container = new CContainer ();
    if (container != NULL)
    {
      rect.left   = x;
      rect.top    = y;
      rect.right  = x + w;
      rect.bottom = y + h;

      if (container->Create (hParent, &rect, clsid, style, exstyle) == 0)
      {

        // Store HWnd Handle
        storing = newSViv(PTR2IV(container->GethWnd()));
        stored  = hv_store_mg(hvSelf, "-handle", 7, storing, 0);

        ret = TRUE;
      }
      else
      {
        delete container;
        container = NULL;
      }
    }

    // Always store CContainer Object pointer (Avoid destroy problem)
    storing = newSViv(PTR2IV(container));
    stored  = hv_store_mg(hvSelf, "-CContainer", 11, storing, 0);

    RETVAL = ret;
OUTPUT:
  RETVAL

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  #  Property
  #

  #
  # EnumPropertyID
  #

void
EnumPropertyID (container)
   CContainer*  container
PREINIT:
   unsigned int i;
PPCODE:
   if (container->PropertyCount() != 0)
   {
      EXTEND(SP, container->PropertyCount());
      for (i = 0; i < container->PropertyCount(); i++)
        XST_mIV( i, container->Property(i)->GetDispId());
      XSRETURN(container->PropertyCount());
   }
   else
      XSRETURN_EMPTY;

  #
  # EnumPropertyName
  #

void
EnumPropertyName (container)
   CContainer*  container
PREINIT:
   unsigned int i;
PPCODE:
   if (container->PropertyCount() != 0)
   {
      EXTEND(SP, container->PropertyCount());
      for (i = 0; i < container->PropertyCount(); i++)
        XST_mPV( i, container->Property(i)->GetName());
      XSRETURN(container->PropertyCount());
   }
   else
      XSRETURN_EMPTY;

  #
  # GetPropertyInfo
  #

void
GetPropertyInfo (container, ID_Name)
   CContainer*  container
   SV * ID_Name
PREINIT:
   CProperty * property = NULL;
PPCODE:
   if(SvIOK(ID_Name))
      property = container->FindProperty ( (DISPID) SvIV(ID_Name) );
   else if(SvPOK(ID_Name))
      property = container->FindProperty ( SvPV_nolen(ID_Name) );

   if (property != NULL)
   {
      char buffer [32000];
      property->EnumValues (buffer);

      EXTEND(SP, 14);
      XST_mPV(  0, "-Name");
      XST_mPV(  1, property->GetName());
      XST_mPV(  2, "-Description");
      XST_mPV(  3, property->GetDesc());
      XST_mPV(  4, "-ID");
      XST_mIV(  5, property->GetDispId());
      XST_mPV(  6, "-ReadOnly");
      XST_mIV(  7, property->isReadOnly());
      XST_mPV(  8, "-VarType");
      XST_mPV(  9, property->GetStrVarType());
      XST_mPV( 10, "-EnumValue");
      XST_mPV( 11, buffer);
      XST_mPV( 12, "-Prototype");
      XST_mPV( 13, property->GetProto());
      XSRETURN(14);
   }
   else
   {
      XSRETURN_EMPTY;
   }

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  #  Method
  #

  #
  # EnumMethodID
  #

void
EnumMethodID (container)
   CContainer*  container
PREINIT:
   unsigned int i;
PPCODE:
   if (container->MethodCount() != 0)
   {
      EXTEND(SP, container->MethodCount());
      for (i = 0; i < container->MethodCount(); i++)
        XST_mIV( i, container->Method(i)->GetDispId());
      XSRETURN(container->MethodCount());
   }
   else
      XSRETURN_EMPTY;

  #
  # EnumMethodName
  #

void
EnumMethodName (container)
   CContainer*  container
PREINIT:
   unsigned int i;
PPCODE:
   if (container->MethodCount() != 0)
   {
      EXTEND(SP, container->MethodCount());
      for (i = 0; i < container->MethodCount(); i++)
        XST_mPV( i, container->Method(i)->GetName());
      XSRETURN(container->MethodCount());
   }
   else
      XSRETURN_EMPTY;

  #
  # GetMethodID
  #

void
GetMethodID (container, name)
   CContainer*  container
   char* name
PREINIT:
   CMethod * method = NULL;
PPCODE:
   method = container->FindMethod (name);
   if (method != NULL)
   {
      EXTEND(SP, 1);
      XST_mIV( 1, method->GetDispId());
      XSRETURN(1);
   }
   else
      XSRETURN_UNDEF;

  #
  # GetMethodInfo
  #

void
GetMethodInfo (container, ID_Name)
   CContainer*  container
   SV * ID_Name
PREINIT:
   CMethod * method = NULL;
PPCODE:
   if(SvIOK(ID_Name))
      method = container->FindMethod ( (DISPID) SvIV(ID_Name) );
   else if(SvPOK(ID_Name))
      method = container->FindMethod ( (char *) SvPV_nolen(ID_Name) );

   if (method != NULL)
   {
      EXTEND(SP, 8);
      XST_mPV(  0, "-Name");
      XST_mPV(  1, method->GetName());
      XST_mPV(  2, "-Description");
      XST_mPV(  3, method->GetDesc());
      XST_mPV(  4, "-ID");
      XST_mIV(  5, method->GetDispId());
      XST_mPV(  6, "-Prototype");
      XST_mPV(  7, method->GetProto());
      XSRETURN(8);
   }
   else
   {
      XSRETURN_EMPTY;
   }

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  #  INVOKE
  #

  #
  # Invoke : Generic interface for Method, Set and Get Property
  #

void
Invoke(container, type, ID_Name, ...)
   CContainer*  container
   int type
   SV * ID_Name
PREINIT:
   CMethod *    method = NULL;
   DISPPARAMS   dispparams;
   VARIANT *    pArg = NULL;
   SV*          value;
   char         buffer [2048];
   char *       stack = buffer;
   int          max;
   int          flag;
   VARIANT      m_value;
   HRESULT      hr = S_OK;
PPCODE:

   // A method
   if (type == DISPATCH_METHOD)
   {
      if(SvIOK(ID_Name))
         method = container->FindMethod ( (DISPID) SvIV(ID_Name) );
      else if(SvPOK(ID_Name))
         method = container->FindMethod ( (char *) SvPV_nolen(ID_Name) );
   }
   // Or a property (special method)
   else
   {
     if(SvIOK(ID_Name))
        method = container->FindProperty ( (DISPID) SvIV(ID_Name) );
     else if(SvPOK(ID_Name))
        method = container->FindProperty ( SvPV_nolen(ID_Name) );
   }

   if (method != NULL)
   {
      // Set InvokeFlag
      method->SetInvokeFlag(type);

      // Prepare Param call
      memset(&dispparams, 0, sizeof (DISPPARAMS));
      dispparams.cArgs = method->GetParamCount();

      if (method->GetParamCount() != 0)
      {

        // TODO : -1 GetParamOptCount

        // Allocate structure
        dispparams.rgvarg = new VARIANT [method->GetParamCount()];
        memset(dispparams.rgvarg, 0, sizeof(VARIANT) * method->GetParamCount());

        // Max imput param
        max = items - 3;
        if (max > method->GetParamCount())
          max = method->GetParamCount();
        else if (max < method->GetParamCount() - method->GetParamOptCount())
        {
          // printf ("Parametre max %d count %d optcount %d\n", max, method->GetParamCount(), method->GetParamOptCount());
          hr = E_FAIL;
        }

        // Param in reverse order
        for (int i = 0, j = method->GetParamCount() - 1;
             i < method->GetParamCount() && hr != E_FAIL; ++i, --j)
        {
          pArg = &dispparams.rgvarg[j];

          if (i >= max)
          {
            pArg->vt    = VT_ERROR;
            pArg->scode = DISP_E_PARAMNOTFOUND;
            // printf ("Parametre %i, max\n", i);
            continue;
          }

          pArg->vt = method->GetParamType(j);
          value    = ST(i+3);

          // printf ("Parametre %i, type = %i max = %i\n", i, pArg->vt, max);

          switch (pArg->vt)
          {
            case VT_I1 :
            case VT_UI1:

              if (SvIOK(value)) pArg->bVal = (BYTE) SvIV(value);
              else hr = E_FAIL;
              break;

            case VT_I2 :
            case VT_UI2:

              if (SvIOK(value)) pArg->iVal = (short) SvIV(value);
              else hr = E_FAIL;
              break;

            case VT_I4 :
            case VT_UI4:
            case VT_INT:
            case VT_UINT:

              if (SvIOK(value)) pArg->lVal = (long) SvIV(value);
              else hr = E_FAIL;
              break;

            case VT_R4 :

              if (SvNOK(value)) pArg->fltVal = (float) SvNV(value);
              else hr = E_FAIL;
              break;

            case VT_R8 :

              if (SvNOK(value)) pArg->dblVal = (double) SvNV(value);
              else hr = E_FAIL;
              break;

            case VT_CY :

              if (SvNOK(value))
              {
                pArg->dblVal = (double) SvNV(value);
                VariantChangeType (pArg, pArg, 0, VT_CY);
              }
              else hr = E_FAIL;
              break;

            case VT_BOOL:

              pArg->boolVal = (SvTRUE(value) ? 0xffff : 0);
              break;

            case VT_USERDEFINED :

              if (type != DISPATCH_METHOD) // A property Enum ????
              {
                 CProperty * property = (CProperty *) method;
                 if (property->isEnum())
                 {
                    pArg->vt = VT_I4;

                    if (SvIOKp(value))
                       pArg->lVal = (long) SvIV(value);
                    else if (SvPOKp(value))
                       pArg->lVal = (long) property->GetEnumValue (SvPV_nolen(value));
                    else
                       hr = E_FAIL;
                 }
                 else hr = E_FAIL;
              }
              else
              {
                pArg->vt = VT_I4;

                if (SvIOK(value)) pArg->lVal = (long) SvIV(value);
                else hr = E_FAIL;
              }
              break;

            case VT_BYREF | VT_I1 :
            case VT_BYREF | VT_UI1:

              if (SvIOK(value))
              {
                *((BYTE *)stack) = (BYTE) SvIV(value);
                pArg->pbVal = (BYTE *) stack;
                stack += sizeof(BYTE);
              }
              else hr = E_FAIL;
              break;

            case VT_BYREF | VT_I2 :
            case VT_BYREF | VT_UI2:

              if (SvIOK(value))
              {
                *((short *)stack) = (short) SvIV(value);
                pArg->piVal = (short *) stack;
                stack += sizeof(short);
              }
              else hr = E_FAIL;
              break;

            case VT_BYREF | VT_I4 :
            case VT_BYREF | VT_UI4:
            case VT_BYREF | VT_INT:
            case VT_BYREF | VT_UINT:

              if (SvIOK(value))
              {
                *((long *)stack) = (long) SvIV(value);
                pArg->plVal = (long *) stack;
                stack += sizeof(long);
              }
              else hr = E_FAIL;
              break;

            case VT_BYREF | VT_R4 :

              if (SvNOK(value))
              {
                *((float *)stack) = (float) SvNV(value);
                pArg->pfltVal = (float *) stack;
                stack += sizeof(float);
              }
              else hr = E_FAIL;
              break;

            case VT_BYREF | VT_R8 :

              if (SvNOK(value))
              {
                *((double *)stack) = (double) SvNV(value);
                pArg->pdblVal = (double *) stack;
                stack += sizeof(double);
              }
              else hr = E_FAIL;
              break;

            case VT_BYREF | VT_BOOL :

              *((VARIANT_BOOL *)stack) = (VARIANT_BOOL) (SvTRUE(value) ? 0xffff : 0);
              pArg->pboolVal = (VARIANT_BOOL *) stack;
              stack += sizeof(VARIANT_BOOL);
              break;

            case VT_BSTR :

            case VT_BYREF | VT_BSTR :

              if (SvPOKp(value))
              {
                CComBSTR bstr (SvPV_nolen(value));

                VariantInit (((VARIANT *) stack));
                ((VARIANT *) stack)->vt      = VT_BSTR;
                ((VARIANT *) stack)->bstrVal = bstr.Detach();

                if (pArg->vt == VT_BSTR)
                  pArg->bstrVal  = ((VARIANT *) stack)->bstrVal;
                else
                  pArg->pbstrVal = &(((VARIANT *) stack)->bstrVal);

                stack += sizeof(VARIANT);
              }
              else hr = E_FAIL;
              break;

            case VT_VARIANT :
            case VT_BYREF | VT_VARIANT :

              VariantInit (((VARIANT *) stack));
              if (SvIOKp(value))
              {
                ((VARIANT *) stack)->vt   = VT_I4;
                ((VARIANT *) stack)->lVal = (long) SvIV(value);
              }
              else if (SvNOKp(value))
              {
                ((VARIANT *) stack)->vt     = VT_R8;
                ((VARIANT *) stack)->dblVal = (double) SvNV(value);
              }
              else if (SvPOKp(value))
              {
                CComBSTR bstr (SvPV_nolen(value));

                ((VARIANT *) stack)->vt      = VT_BSTR;
                ((VARIANT *) stack)->bstrVal = bstr.Detach();
              }
   /*         else if (SvROK(value))
              {
                 // printf ("Param Reference\n);

                 SV* value2 = ;
                 switch (SvTYPE(SvRV(value)))
                 {
                    case SVt_IV :

                      ((VARIANT *) stack)->vt   = VT_I4;
                      ((VARIANT *) stack)->lVal = (long) SvIV(SvRV(value));
                      break;

                    case SVt_NV :

                      ((VARIANT *) stack)->vt     = VT_R8;
                      ((VARIANT *) stack)->dblVal = (double) SvNV(SvRV(value));
                      break;

                    case SVt_PV :
                      {
                        CComBSTR bstr (SvPV_nolen(SvRV(value)));

                        ((VARIANT *) stack)->vt      = VT_BSTR;
                        ((VARIANT *) stack)->bstrVal = bstr.Detach();
                      }
                      break;

                    case SVt_PVAV :
                      {
                         AV * array = (AV*) SvRV(value);
                         I32 len = av_len (array);
                         SV** elem;
                         I32 i;
                         SAFEARRAY FAR* psa;
                         SAFEARRAYBOUND rgsabound[1];
                         rgsabound[0].lLbound   = 0;
                         rgsabound[0].cElements = len;

                         psa = SafeArrayCreate(VT_VARIANT, 1, rgsabound);
                         if (psa == NULL) hr = E_FAIL;

                         for (i = 0; i < len && hr != E_FAIL; i++)
                         {
                           elem = av_fetch(array, i, 0);
                           if (elem != NULL)
                           {

                           }
                           else
                             hr = E_FAIL;
                         }
                      }
                      break;

                    default :
                       hr = E_FAIL;
                 }
              } */
              else {
                ((VARIANT *) stack)->vt      = VT_BOOL;
                ((VARIANT *) stack)->boolVal = (VARIANT_BOOL) (SvTRUE(value) ? 0xffff : 0);
              }

              pArg->pvarVal = (VARIANT *) stack;
              stack += sizeof(VARIANT);

              break;

            default :
              hr = E_FAIL;
              // printf ("Param Type Erreur");
          }
        }
      }

    //  printf ("Before CALL = %i\n", hr);

      if (SUCCEEDED(hr))
        hr = container->Call (method, &m_value, &dispparams);

    //  printf ("After CALL = %i\n", hr);

      if (method->GetParamCount() != 0)
      {
        stack = buffer;

        for (int i = 0, j = method->GetParamCount() - 1; i < max; ++i, --j)
        {
          pArg  = &dispparams.rgvarg[j];
          flag  = method->GetParamFlag(j);
          value = ST(i+3);

          switch (pArg->vt)
          {
            case VT_BYREF | VT_I1 :
            case VT_BYREF | VT_UI1:

              if (flag) sv_setiv(value, (IV) *((BYTE *)stack));
              stack += sizeof(BYTE);
              break;

            case VT_BYREF | VT_I2 :
            case VT_BYREF | VT_UI2:

              if (flag) sv_setiv(value, (IV) *((short *)stack));
              stack += sizeof(short);
              break;

            case VT_BYREF | VT_I4 :
            case VT_BYREF | VT_UI4:
            case VT_BYREF | VT_INT:
            case VT_BYREF | VT_UINT:

              if (flag) sv_setiv(value, (IV) *((long *)stack));
              stack += sizeof(long);
              break;

            case VT_BYREF | VT_R4 :

              if (flag) sv_setnv(value, (double) *((float *)stack));
              stack += sizeof(float);
              break;

            case VT_BYREF | VT_R8 :

              if (flag) sv_setnv(value, (double) *((double *)stack));
              stack += sizeof(double);
              break;

            case VT_BYREF | VT_BOOL :

              if (flag) sv_setiv(value, (IV) *((VARIANT_BOOL *)stack));
              stack += sizeof(VARIANT_BOOL);
              break;

            case VT_VARIANT :
            case VT_BYREF | VT_VARIANT :

              if (((VARIANT *) stack)->vt == VT_I1)
              {
                if (flag) sv_setiv(value, (IV) ((VARIANT *) stack)->bVal);
              }
              else if (((VARIANT *) stack)->vt == VT_I4)
              {
                if (flag) sv_setiv(value, (IV) ((VARIANT *) stack)->lVal);
              }
              else if (((VARIANT *) stack)->vt == VT_R4)
              {
                if (flag) sv_setnv(value, (double) ((VARIANT *) stack)->fltVal);
              }
              else if (((VARIANT *) stack)->vt == VT_R8)
              {
                if (flag) sv_setnv(value, (double) ((VARIANT *) stack)->dblVal);
              }

            case VT_BSTR :
            case VT_BYREF | VT_BSTR :

              if (((VARIANT *) stack)->vt == VT_BSTR)
              {
                CComBSTR bstr;
                bstr.Attach (((VARIANT *) stack)->bstrVal);
                if (flag)
                {
                  USES_CONVERSION;
                  sv_setpv (value, (char *) OLE2T(bstr));
                }

                bstr.Empty();
              }
              stack += sizeof(VARIANT);
              break;
          }
        }

        delete [] dispparams.rgvarg;
      }

      if (SUCCEEDED(hr))
      {
        switch (method->GetReturnType())
        {
          case VT_I1 :
          case VT_UI1:
            EXTEND(SP, 1);
            XST_mIV( 0, m_value.bVal);
            XSRETURN(1);
            break;
          case VT_I2 :
          case VT_UI2:
            EXTEND(SP, 1);
            XST_mIV( 0, m_value.iVal);
            XSRETURN(1);
            break;
          case VT_I4 :
          case VT_UI4:
          case VT_INT:
          case VT_UINT:
          case VT_USERDEFINED:
            EXTEND(SP, 1);
            XST_mIV( 0, m_value.lVal);
            XSRETURN(1);
            break;
          case VT_R4 :
            EXTEND(SP, 1);
            XST_mNV( 0, m_value.fltVal);
            XSRETURN(1);
            break;
          case VT_CY :
            VariantChangeType (&m_value,&m_value,0, VT_R8);
          case VT_R8 :
            EXTEND(SP, 1);
            XST_mNV( 0, m_value.dblVal);
            XSRETURN(1);
            break;
          case VT_DATE :
            EXTEND(SP, 1);
            XST_mNV( 0, m_value.date);
            XSRETURN(1);
            break;
          case VT_BSTR:
            {
              USES_CONVERSION;

              EXTEND(SP, 1);
              XST_mPV( 0, OLE2T (m_value.bstrVal));
              XSRETURN(1);
            }
            break;
          case VT_BOOL:
            EXTEND(SP, 1);
            XST_mIV( 0, m_value.boolVal);
            XSRETURN(1);
            break;
          case VT_LPSTR:
            EXTEND(SP, 1);
            XST_mPV( 0, (char *) m_value.pbVal);
            XSRETURN(1);
            break;
          default :
            XSRETURN_YES;
        }
      }
      else
        XSRETURN_UNDEF;
   }
   else
   {
      XSRETURN_UNDEF;
   }

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  #  EVENT
  #

  #
  # EnumEventID
  #

void
EnumEventID (container)
   CContainer*  container
PREINIT:
   unsigned int i;
   CEventMap * map;
PPCODE:
   map = container->EventMap();
   if (map->EventCount() != 0)
   {
      EXTEND(SP, map->EventCount());
      for (i = 0; i < map->EventCount(); i++)
        XST_mIV( i, map->GetEvent(i)->GetDispId());
      XSRETURN(map->EventCount());
   }
   else
      XSRETURN_EMPTY;

  #
  # EnumEventName
  #

void
EnumEventName (container)
   CContainer*  container
PREINIT:
   unsigned int i;
   CEventMap * map;
PPCODE:
   map = container->EventMap();
   if (map->EventCount() != 0)
   {
      EXTEND(SP, map->EventCount());
      for (i = 0; i < map->EventCount(); i++)
        XST_mPV( i, map->GetEvent(i)->GetName());
      XSRETURN(map->EventCount());
   }
   else
      XSRETURN_EMPTY;


  #
  # GetEventInfo
  #

void
GetEventInfo (container, ID_Name)
   CContainer*  container
   SV * ID_Name
PREINIT:
   CEvent * event = NULL;
PPCODE:
   if(SvIOK(ID_Name))
      event = container->FindEvent ( (DISPID) SvIV(ID_Name) );
   else if(SvPOK(ID_Name))
      event = container->FindEvent ( (char *) SvPV_nolen(ID_Name) );

   if (event != NULL)
   {
      EXTEND(SP, 8);
      XST_mPV(  0, "-Name");
      XST_mPV(  1, event->GetName());
      XST_mPV(  2, "-Description");
      XST_mPV(  3, event->GetDesc());
      XST_mPV(  4, "-ID");
      XST_mIV(  5, event->GetDispId());
      XST_mPV(  6, "-Prototype");
      XST_mPV(  7, event->GetProto());
      XSRETURN(8);
   }
   else
   {
      XSRETURN_EMPTY;
   }

  #
  # RegisterEvent
  #

BOOL
RegisterEvent (container, ID_Name, callback)
   CContainer*  container
   SV * ID_Name
   SV * callback
PREINIT:
   CMethod * method = NULL;
CODE:
   RETVAL = 0;
   if(SvIOK(ID_Name))
      RETVAL = container->EventMap()->RegisterEvent(ST(0), (DISPID) SvIV(ID_Name),  callback);
   else if(SvPOK(ID_Name))
      RETVAL = container->EventMap()->RegisterEvent(ST(0), (char *) SvPV_nolen(ID_Name),  callback);
OUTPUT:
  RETVAL

  #
  #
  #
  ##################################################################


  ##################################################################
  #
  # GetOLE
  #

void
GetOLE (container)
   CContainer*  container
CODE:
{
#ifdef PERL_5005
  typedef SV* (*MYPROC)(CPERLarg_ HV *, IDispatch *, SV *);
#else
  typedef SV* (*MYPROC)(pTHX_ HV *, IDispatch *, SV *);
#endif

  HMODULE hmodule;
  MYPROC pCreatePerlObject;
  IDispatch * pDispatch;

  ST(0) = &PL_sv_undef;
  // Try to find OLE.dll
  hmodule = GetModuleHandle("OLE");
  if (hmodule == 0) {
    // Try to find using Dynaloader
    AV* av_modules = get_av("DynaLoader::dl_modules", FALSE);
    AV* av_librefs = get_av("DynaLoader::dl_librefs", FALSE);
    if (av_modules && av_librefs) {
      // Look at Win32::OLE package
      for (I32 i = 0; i < av_len(av_modules); i++) {
        SV** sv = av_fetch(av_modules, i, 0);
        if (sv && SvPOK (*sv) &&
            strEQ(SvPV_nolen(*sv), "Win32::OLE")) {
          // Tahe
          sv = av_fetch(av_librefs, i, 0);
          hmodule = (HMODULE) (sv && SvIOK (*sv) ? SvIV(*sv) : 0);
          break;
        }
      }
    }
  }

  if (hmodule != 0) {
    pCreatePerlObject = (MYPROC) GetProcAddress(hmodule, "CreatePerlObject");
    if (pCreatePerlObject != 0)  {
      HV *stash = gv_stashpv("Win32::OLE", TRUE);
      pDispatch = container->GetIDispatch();
      pDispatch->AddRef();
#ifdef PERL_5005
      ST(0) = (pCreatePerlObject)(PERL_OBJECT_THIS_ stash, pDispatch, NULL);
#else
      ST(0) = (pCreatePerlObject)(aTHX_ stash, pDispatch, NULL);
#endif
    }
  }
}

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  # Release
  #

void
Release (container)
   CContainer*  container
CODE:
  //  printf("Release\n");
   container->Clean();
  //  printf("Release\n");

  ##################################################################
  #
  # DESTROY
  #

void
DESTROY(container)
   CContainer*  container
CODE:
  // printf("DESTROY\n");
   delete container;
  // printf("DESTROY\n");
