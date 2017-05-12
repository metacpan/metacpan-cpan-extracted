/**********************************************************************/
/*                          G R I D . x s                             */
/**********************************************************************/

/* $Id */

//////////////////////////////////////////////////////////////////////
// Include
//////////////////////////////////////////////////////////////////////

//
// MFC
//

#define _AFX_NOFORCE_LIBS // not force library
#define _WINDLL         // Windows DLL
#define _USRDLL         //
#define _AFXDLL         // Use shared MFC
#define VC_EXTRALEAN    // Exclude rarely-used stuff from Windows headers

#include <afxwin.h>     // MFC core and standard components
#include <afxext.h>     // MFC extensions
#include <afxdtctl.h>   // MFC support for Internet Explorer 4 Common Controls
#include <afxcmn.h>     // MFC support for Windows Common Controls

//
// GridCtrl  Include
//

#include ".\MFCGrid\GridCtrl.h"
#include ".\MFCGrid\GridCell.h"
#include ".\MFCGrid\GridCellNumeric.h"
#include ".\MFCGrid\GridCellDateTime.h"
#include ".\MFCGrid\GridCellCheck.h"
#include ".\MFCGrid\GridCellCombo.h"
#include ".\MFCGrid\GridCellUrl.h"

//
// Perl Include
//

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

//////////////////////////////////////////////////////////////////////
// Win32::GUI helper function
//////////////////////////////////////////////////////////////////////

// Windows message for stop Win32::GUI message loop
#define WM_EXITLOOP   (WM_APP+1)

// Return a COLORREF from a SV
COLORREF SvCOLORREF(pTHX_ SV* c)
{
  SV** t;
  int r, g, b;
  char *p;

  // [R, G, B]
  if(SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVAV)
  {
    r = g = b = 0;
    t = av_fetch((AV*)SvRV(c), 0, 0);
    if (t != NULL) r = (int)SvIV(*t);
    t = av_fetch((AV*)SvRV(c), 1, 0);
    if (t != NULL) g = (int)SvIV(*t);
    t = av_fetch((AV*)SvRV(c), 2, 0);
    if(t != NULL) b = (int)SvIV(*t);
    return RGB((BYTE) r, (BYTE) g, (BYTE) b);
  }
  // HTML : #RRGGBB
  else if(SvPOK(c))
  {
    p = SvPV_nolen(c);
    if (strncmp(p, "#", 1) == 0)
    {
      sscanf(p+1, "%2x%2x%2x", &r, &g, &b);
      return RGB((BYTE) r, (BYTE) g, (BYTE) b);
    }
    else
      return (COLORREF) SvIV(c);
  }

  return (COLORREF) SvIV(c);
}

// Process Error Event
BOOL ProcessEventError(pTHX_ const char *Name, int* PerlResult)
{
    if(strncmp(Name, "main::", 6) == 0) Name += 6;
    if(SvTRUE(ERRSV))
    {
        MessageBeep(MB_ICONASTERISK);
        *PerlResult = MessageBox( NULL,
                                  SvPV_nolen(ERRSV),
                                  Name,
                                  MB_ICONERROR | MB_OKCANCEL);
        if(*PerlResult == IDCANCEL)
        {
          *PerlResult = -1;
        }
        return TRUE;
    }
    else
    {
      return FALSE;
    }
}

// Call Generic Event
int DoEvent_Generic(const char *Name)
{
  dTHX;
  int PerlResult;
  int count;
  PerlResult = 1;

  if(perl_get_cv(Name, FALSE) != NULL)
  {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    count = perl_call_pv(Name, G_EVAL|G_NOARGS);
    SPAGAIN;
    if(!ProcessEventError(aTHX_ Name, &PerlResult)) {
      if(count > 0)
        PerlResult = POPi;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  return PerlResult;
}

int DoEvent_TwoLongs(const char *Name, long argone, long argtwo)
{
  dTHX;
  int PerlResult;
  int count;
  PerlResult = 1;
  if(perl_get_cv(Name, FALSE) != NULL) {
     dSP;
     ENTER ;
     SAVETMPS;
     PUSHMARK(SP) ;
     XPUSHs(sv_2mortal(newSViv(argone)));
     XPUSHs(sv_2mortal(newSViv(argtwo)));
     PUTBACK ;
     count = perl_call_pv(Name, G_EVAL|G_ARRAY);
     SPAGAIN ;
     if(!ProcessEventError(aTHX_ Name, &PerlResult))
     {
       if(count > 0)
         PerlResult = POPi;
     }
     PUTBACK ;
     FREETMPS ;
     LEAVE ;
  }
  return PerlResult;
}

int DoEvent_FourLongs(const char *Name, long arg1, long arg2, long arg3, long arg4)
{
  dTHX;
  int PerlResult;
  int count;
  PerlResult = 1;
  if(perl_get_cv(Name, FALSE) != NULL)
  {
     dSP;
     ENTER ;
     SAVETMPS;
     PUSHMARK(SP) ;
     XPUSHs(sv_2mortal(newSViv(arg1)));
     XPUSHs(sv_2mortal(newSViv(arg2)));
     XPUSHs(sv_2mortal(newSViv(arg3)));
     XPUSHs(sv_2mortal(newSViv(arg4)));
     PUTBACK ;
     count = perl_call_pv(Name, G_EVAL|G_ARRAY);
     SPAGAIN ;
     if(!ProcessEventError(aTHX_ Name, &PerlResult))
     {
       if(count > 0)
         PerlResult = POPi;
     }
     PUTBACK ;
     FREETMPS ;
     LEAVE ;
  }
  return PerlResult;
}

int DoEvent_TwoLongsAndString(const char *Name, long argone, long argtwo, const char *str)
{
  dTHX;
  int PerlResult;
  int count;
  PerlResult = 1;
  if(perl_get_cv(Name, FALSE) != NULL)
  {
     dSP;
     ENTER ;
     SAVETMPS;
     PUSHMARK(SP) ;
     XPUSHs(sv_2mortal(newSViv(argone)));
     XPUSHs(sv_2mortal(newSViv(argtwo)));
     XPUSHs(sv_2mortal(newSVpv(str, 0)));
     PUTBACK ;
     count = perl_call_pv(Name, G_EVAL|G_ARRAY);
     SPAGAIN ;
     if(!ProcessEventError(aTHX_ Name, &PerlResult))
     {
       if(count > 0)
         PerlResult = POPi;
     }
     PUTBACK ;
     FREETMPS ;
     LEAVE ;
  }

  return PerlResult;
}

//////////////////////////////////////////////////////////////////////
// Cell type
//////////////////////////////////////////////////////////////////////

#define GVIT_DEFAULT  0
#define GVIT_NUMERIC  1
#define GVIT_DATE     2
#define GVIT_TIME     3
#define GVIT_CHECK    4
#define GVIT_COMBO    5
#define GVIT_LIST     6
#define GVIT_URL      7
#define GVIT_DATECAL  8

CRuntimeClass*
GetRuntimeClassFromType (int iType)
{
  switch (iType)
  {
  case GVIT_DEFAULT :
    return RUNTIME_CLASS(CGridCell);
  case GVIT_NUMERIC :
    return RUNTIME_CLASS(CGridCellNumeric);
  case GVIT_DATE :
    return RUNTIME_CLASS(CGridCellDateTime);
  case GVIT_TIME :
    return RUNTIME_CLASS(CGridCellTime);
  case GVIT_CHECK :
    return RUNTIME_CLASS(CGridCellCheck);
  case GVIT_COMBO :
    return RUNTIME_CLASS(CGridCellCombo);
  case GVIT_LIST :
    return RUNTIME_CLASS(CGridCellList);
  case GVIT_URL :
    return RUNTIME_CLASS(CGridCellURL);
  case GVIT_DATECAL :
    return RUNTIME_CLASS(CGridCellDateCal);
  }
  return NULL;
}

//////////////////////////////////////////////////////////////////////
// Constant function
//////////////////////////////////////////////////////////////////////


#define CONSTANT(x) if(strEQ(name, #x)) return x

int constant (char * name, int arg)
{
  errno = 0;
  switch(name[2])
  {
  case 'L' :
    // Grid line/scrollbar selection
    CONSTANT(GVL_NONE);   // Neither
    CONSTANT(GVL_HORZ);   // Horizontal line or scrollbar
    CONSTANT(GVL_VERT);   // Vertical line or scrollbar
    CONSTANT(GVL_BOTH);   // Both
    break;
  case 'S':
    // Autosizing option
    CONSTANT(GVS_DEFAULT);
    CONSTANT(GVS_HEADER); // Size using column fixed cells data only
    CONSTANT(GVS_DATA);   // Size using column non-fixed cells data only
    CONSTANT(GVS_BOTH);   // Size using column fixed and non-fixed
    break;
  case 'N' :
    switch(name[3])
    {
    case 'I' :
      // Cell Searching options
      CONSTANT(GVNI_FOCUSED);
      CONSTANT(GVNI_SELECTED);
      CONSTANT(GVNI_DROPHILITED);
      CONSTANT(GVNI_READONLY);
      CONSTANT(GVNI_FIXED);
      CONSTANT(GVNI_MODIFIED);
      CONSTANT(GVNI_ABOVE);
      CONSTANT(GVNI_BELOW);
      CONSTANT(GVNI_TOLEFT);
      CONSTANT(GVNI_TORIGHT);
      CONSTANT(GVNI_ALL);
      CONSTANT(GVNI_AREA);
      break;
    case '_' :
      // Messages sent to the grid's parent (More will be added in future)
      CONSTANT(GVN_BEGINDRAG);
      CONSTANT(GVN_BEGINLABELEDIT);
      CONSTANT(GVN_BEGINRDRAG);
      CONSTANT(GVN_COLUMNCLICK);
      CONSTANT(GVN_DELETEITEM);
      CONSTANT(GVN_ENDLABELEDIT);
      CONSTANT(GVN_SELCHANGING);
      CONSTANT(GVN_SELCHANGED);
      CONSTANT(GVN_GETDISPINFO);
      CONSTANT(GVN_ODCACHEHINT);
      CONSTANT(GVN_CHANGEDLABELEDIT);
      break;
    }
    break;
  case 'H' :
    // Hit test values (not yet implemented)
    CONSTANT(GVHT_DATA);
    CONSTANT(GVHT_TOPLEFT);
    CONSTANT(GVHT_COLHDR);
    CONSTANT(GVHT_ROWHDR);
    CONSTANT(GVHT_COLSIZER);
    CONSTANT(GVHT_ROWSIZER);
    CONSTANT(GVHT_LEFT);
    CONSTANT(GVHT_RIGHT);
    CONSTANT(GVHT_ABOVE);
    CONSTANT(GVHT_BELOW);
    break;

  case 'I' :
    switch(name[3])
    {
    case 'S' :
      CONSTANT(GVIS_FOCUSED);
      CONSTANT(GVIS_SELECTED);
      CONSTANT(GVIS_DROPHILITED);
      CONSTANT(GVIS_READONLY);
      CONSTANT(GVIS_FIXED);
      CONSTANT(GVIS_FIXEDROW);
      CONSTANT(GVIS_FIXEDCOL);
      CONSTANT(GVIS_MODIFIED);
      break;
    case 'F' :
      CONSTANT(GVIF_TEXT);
      CONSTANT(GVIF_IMAGE);
      CONSTANT(GVIF_PARAM);
      CONSTANT(GVIF_STATE);
      CONSTANT(GVIF_BKCLR);
      CONSTANT(GVIF_FGCLR);
      CONSTANT(GVIF_FORMAT);
      CONSTANT(GVIF_FONT);
      CONSTANT(GVIF_MARGIN);
      CONSTANT(GVIF_ALL);
      break;
    case 'T' :
      CONSTANT(GVIT_DEFAULT);
      CONSTANT(GVIT_NUMERIC);
      CONSTANT(GVIT_DATE);
      CONSTANT(GVIT_TIME);
      CONSTANT(GVIT_CHECK);
      CONSTANT(GVIT_COMBO);
      CONSTANT(GVIT_LIST);
      CONSTANT(GVIT_URL);
      CONSTANT(GVIT_DATECAL);
      break;
    }
    break;

  case '_' :
    // DrawText() Format Flags
    CONSTANT(DT_TOP);
    CONSTANT(DT_LEFT);
    CONSTANT(DT_CENTER);
    CONSTANT(DT_RIGHT);
    CONSTANT(DT_VCENTER);
    CONSTANT(DT_BOTTOM);
    CONSTANT(DT_WORDBREAK);
    CONSTANT(DT_SINGLELINE);
    CONSTANT(DT_EXPANDTABS);
    CONSTANT(DT_TABSTOP);
    CONSTANT(DT_NOCLIP);
    CONSTANT(DT_EXTERNALLEADING);
    CONSTANT(DT_CALCRECT);
    CONSTANT(DT_NOPREFIX);
    CONSTANT(DT_INTERNAL);
    CONSTANT(DT_EDITCONTROL);
    CONSTANT(DT_PATH_ELLIPSIS);
    CONSTANT(DT_END_ELLIPSIS);
    CONSTANT(DT_MODIFYSTRING);
    CONSTANT(DT_RTLREADING);
    CONSTANT(DT_WORD_ELLIPSIS);
    break;
  }

  errno = EINVAL;
  return 0;
}

/////////////////////////////////////////////////////////////////////////////
// Sort Method
/////////////////////////////////////////////////////////////////////////////

static int CALLBACK pfnSortCompare(LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort)
{
  int count, result = 0;

  CGridCellBase* pCell1 = (CGridCellBase*) lParam1;
  CGridCellBase* pCell2 = (CGridCellBase*) lParam2;
  if (!pCell1 || !pCell2) return 0;

  dTHX;

  dSP;
  ENTER ;
  SAVETMPS ;

  PUSHMARK(SP) ;
  XPUSHs(sv_2mortal(newSVpv((char *) pCell1->GetText(), 0)));
  XPUSHs(sv_2mortal(newSVpv((char *) pCell2->GetText(), 0)));

  PUTBACK ;
  count = call_sv((SV*)lParamSort, G_EVAL | G_ARRAY);
  SPAGAIN ;
  if (count >= 0)
    result = POPi;

  FREETMPS ;
  LEAVE ;

  return result;
}

//////////////////////////////////////////////////////////////////////
// CWinApp instance (required).
//////////////////////////////////////////////////////////////////////

CWinApp theApp;

//////////////////////////////////////////////////////////////////////
// CGridCellBaseEx  Class ( force CGridCellBase class as friend )
//////////////////////////////////////////////////////////////////////

class CGridCellBaseEx : public CGridCellBase
{
  friend class CGridEx;
};

//////////////////////////////////////////////////////////////////////
// CGridEx  Class
//////////////////////////////////////////////////////////////////////

class CGridEx : public CGridCtrl
{
// Construction & Destructor
public:
    CGridEx (LPCSTR sName);
    virtual ~CGridEx();

// Attributes
public:
    // Control name
    CString csName;
    // Grid perl sort sub
    SV* m_SvSub;
    // Columns perl sort subs
    CPtrArray m_RowSortFunc;

// Operations
public:
    BOOL Create(const RECT& rect, CWnd* parent, DWORD dwStyle);

    inline CGridDefaultCell* GetDefaultCell(BOOL bFixedRow, BOOL bFixedCol) const
    {
      return (CGridDefaultCell*) CGridCtrl::GetDefaultCell(bFixedRow, bFixedCol);
    }

// Overrides
public:

    virtual BOOL SortItems(int nCol, BOOL bAscending, LPARAM data = 0);

protected:

    virtual void OnEndEditCell(int nRow, int nCol, CString str);

// Generated message map functions
protected:

   //{{AFX_MSG(CGridEx)
      afx_msg void OnNClick(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNRClick(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNDblClick(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNSelChanging(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNSelChanged(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNBeginLabelEdit(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNChangedLabelEdit(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNEndLabelEdit(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNBeginDrag(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNGetDispInfo(NMHDR *pNotifyStruct, LRESULT* pResult);
      afx_msg void OnNCacheHint(NMHDR *pNotifyStruct, LRESULT* pResult);
    //}}AFX_MSG

    DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
// CGridEx

CGridEx::CGridEx(LPCSTR sName):CGridCtrl(0,0,0,0)
{
  // Init control name
  csName = "main::";
  csName += sName;
  m_SvSub = NULL;
}

CGridEx::~CGridEx()
{
  // Force end editing cell
  EndEditing();

  // Release grid sort perl sub
  if (m_SvSub != NULL)
  {
    SvREFCNT_dec (m_SvSub);
    m_SvSub = NULL;
  }

  // Release column sort perl sub
  SV* pFun;
  for (int i = 0; i < m_RowSortFunc.GetSize(); i++)
  {
    pFun = (SV*) m_RowSortFunc.GetAt (i);
    if (pFun != NULL)
      SvREFCNT_dec (pFun);
  }
  m_RowSortFunc.RemoveAll();
}

// Create
BOOL CGridEx::Create(const RECT& rect, CWnd* parent, DWORD dwStyle)
{
  // Create base grid
  if (CGridCtrl::Create (rect, parent, 0, dwStyle))
  {
    // Force receive notification.
    SetOwner(this);
    return TRUE;
  }
  else
    return FALSE;
}

/////////////////////////////////////////////////////////////////////////////
// CGridEx virtual mode notification support

void CGridEx::OnEndEditCell(int nRow, int nCol, CString str)
{
  // Add text to EndEdit Event in virtual mode
  if (GetVirtualMode())
  {
    CString csEvent;
    csEvent = csName + "_EndEdit";

    if (ValidateEdit(nRow, nCol, str) &&
        DoEvent_TwoLongsAndString(csEvent, nRow, nCol, str) >= 0 )
    {
       SetModified(TRUE, nRow, nCol);
       RedrawCell(nRow, nCol);
    }

    CGridCellBaseEx* pCell = (CGridCellBaseEx *) GetCell(nRow, nCol);
    if (pCell)
        pCell->OnEndEdit();
  }
  else
    CGridCtrl::OnEndEditCell(nRow, nCol, str);
}

/////////////////////////////////////////////////////////////////////////////
// CGridEx Sort

// SortItems
BOOL CGridEx::SortItems(int nCol, BOOL bAscending, LPARAM data)
{
  SV* ColSvSub = ( nCol >= 0 && nCol < m_RowSortFunc.GetSize() ? (SV*) m_RowSortFunc.GetAt(nCol) : NULL );

  if (ColSvSub != NULL)
    return CGridCtrl::SortItems(pfnSortCompare, nCol, bAscending, (LPARAM) ColSvSub);
  else
    return CGridCtrl::SortItems(nCol, bAscending, (LPARAM) m_SvSub);
}

/////////////////////////////////////////////////////////////////////////////
// CGridEx Event

BEGIN_MESSAGE_MAP(CGridEx, CGridCtrl)
    //{{AFX_MSG_MAP(CGridEx)
      ON_NOTIFY(NM_CLICK,  0, OnNClick)
      ON_NOTIFY(NM_DBLCLK, 0, OnNDblClick)
      ON_NOTIFY(NM_RCLICK,  0, OnNRClick)
      ON_NOTIFY(GVN_SELCHANGING, 0, OnNSelChanging)
      ON_NOTIFY(GVN_SELCHANGED, 0, OnNSelChanged)
      ON_NOTIFY(GVN_BEGINLABELEDIT, 0, OnNBeginLabelEdit)
      ON_NOTIFY(GVN_CHANGEDLABELEDIT, 0, OnNChangedLabelEdit)
      ON_NOTIFY(GVN_ENDLABELEDIT, 0, OnNEndLabelEdit)
      ON_NOTIFY(GVN_BEGINDRAG, 0, OnNBeginDrag)
      ON_NOTIFY(GVN_GETDISPINFO, 0, OnNGetDispInfo)
      ON_NOTIFY(GVN_ODCACHEHINT, 0, OnNCacheHint)
    //}}AFX_MSG_MAP
END_MESSAGE_MAP()

// Simple click Event
void CGridEx::OnNClick(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_Click";

  if (DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn) == -1)
    PostMessage(WM_EXITLOOP, -1, 0);

  *pResult = 0;
}

// Simple right click Event
void CGridEx::OnNRClick(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_RClick";

  if (DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn) == -1)
    PostMessage(WM_EXITLOOP, -1, 0);

  *pResult = 0;
}

// Double click Event
void CGridEx::OnNDblClick(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_DblClick";

  if (DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn) == -1)
    PostMessage(WM_EXITLOOP, -1, 0);

  *pResult = 0;
}

// Selection changing
void CGridEx::OnNSelChanging(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_Changing";

  if (DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn) == -1)
    PostMessage(WM_EXITLOOP, -1, 0);

  *pResult = 0;
}

// Selection changed
void CGridEx::OnNSelChanged(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_Changed";

  if (DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn) == -1)
    PostMessage(WM_EXITLOOP, -1, 0);

  *pResult = 0;
}

// Begin Cell Edit event
void CGridEx::OnNBeginLabelEdit(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_BeginEdit";

  *pResult = DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn);
}

// Change Cell Edit event
void CGridEx::OnNChangedLabelEdit(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  GV_DISPINFO* pItem = (GV_DISPINFO*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_ChangedEdit";

  *pResult = DoEvent_TwoLongsAndString(csEvent, pItem->item.row, pItem->item.col, pItem->item.strText);
}

// End Cell Edit event
void CGridEx::OnNEndLabelEdit(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_EndEdit";

  *pResult = DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn);
}

// Begin Drag
void CGridEx::OnNBeginDrag(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  NM_GRIDVIEW* pItem = (NM_GRIDVIEW*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_BeginDrag";

  *pResult = DoEvent_TwoLongs(csEvent, pItem->iRow, pItem->iColumn);
}

// Get Data information
void CGridEx::OnNGetDispInfo(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  dTHX;

  GV_DISPINFO* pDispInfo = (GV_DISPINFO*) pNotifyStruct;

  CString csEvent;
  csEvent = csName + "_GetData";

  int PerlResult;
  int count;
  PerlResult = 1;
  if(perl_get_cv(csEvent , FALSE) != NULL) {
     dSP;
     ENTER ;
     SAVETMPS;
     PUSHMARK(SP) ;
     XPUSHs(sv_2mortal(newSViv(pDispInfo->item.row)));
     XPUSHs(sv_2mortal(newSViv(pDispInfo->item.col)));
     PUTBACK ;
     count = perl_call_pv(csEvent , G_EVAL|G_ARRAY);
     SPAGAIN ;
     if(!ProcessEventError(aTHX_ csEvent, &PerlResult)) {
       if(count == 1)
       {
         SV* sv = POPs;
         if (SvPOK(sv))
           pDispInfo->item.strText = SvPV_nolen(sv);
       }
     }
     PUTBACK ;
     FREETMPS ;
     LEAVE ;
  }

  *pResult = 0;
}

//
void CGridEx::OnNCacheHint(NMHDR *pNotifyStruct, LRESULT* pResult)
{
  GV_CACHEHINT* pCache = (GV_CACHEHINT*) pNotifyStruct;

  // Virtual get information by message
  CString csEvent;
  csEvent = csName + "_CacheHint";

  DoEvent_FourLongs(csEvent,
                    pCache->range.GetMinRow(),
                    pCache->range.GetMinCol(),
                    pCache->range.GetMaxRow(),
                    pCache->range.GetMaxCol());
  *pResult = 0;
}


/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

typedef CGridEx CMFCWnd;

/**********************************************************************/
/**********************************************************************/
/**********************************************************************/

MODULE = Win32::GUI::Grid       PACKAGE = Win32::GUI::Grid

PROTOTYPES: ENABLE

  ##################################################################
  #                                                                #
  #              Win32::GUI::Grid  package                         #
  #                                                                #
  ##################################################################

  ##################################################################
  #
  # Startup code
  #

  #
  # _Initialise (internal)
  #

void
_Initialise()
CODE:
  AfxWinInit(GetModuleHandle(NULL), NULL, _T(""), 0);
  OleInitialize(NULL);
  ::setlocale (LC_TIME, "");

  #
  # _UnInitialise (internal)
  #

void
_UnInitialise()
CODE:
  AfxWinTerm();

  #
  # constant
  #

int
constant(name,arg)
        char *          name
        int             arg

  #
  #
  ##################################################################


  ##################################################################
  #
  # _Create (internal)
  #

HWND
_Create(Self, hParent, szName, style, x, y, w, h)
  SV*     Self
  HWND    hParent
  LPCTSTR szName
  DWORD   style
  int     x
  int     y
  int     w
  int     h
PREINIT:
  HV*  hvSelf;
  SV** stored;
  SV*  storing;
  CMFCWnd* object;
  RECT     rect;
CODE:
  object = new CMFCWnd(szName);
  if (object != NULL)
  {
    rect.left   = x;
    rect.top    = y;
    rect.right  = x + w;
    rect.bottom = y + h;

    if (object->Create (rect, CWnd::FromHandle(hParent), style) )
    {
      // Store Object pointer
      hvSelf = (HV*) SvRV(ST(0));
      storing = newSViv(PTR2IV(object));
      stored  = hv_store_mg(hvSelf, "-CMFCWnd", 8, storing, 0);

      RETVAL = object->GetSafeHwnd();
    }
    else
      RETVAL = 0;
  }
  else
    RETVAL = 0;
OUTPUT:
  RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  # DESTROY
  #

void
DESTROY(object)
   CMFCWnd* object
CODE:
  delete object;

  #
  #
  ##################################################################

  ##################################################################
  #
  # Attribut
  #

  # int  GetRowCount() const;
int
GetRows(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetRowCount();
OUTPUT:
  RETVAL

  # int  GetColumnCount() const;
int
GetColumns(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetColumnCount();
OUTPUT:
  RETVAL

  # int  GetFixedRowCount() const;
int
GetFixedRows(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFixedRowCount();
OUTPUT:
  RETVAL

  # int  GetFixedColumnCount() const;
int
GetFixedColumns(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFixedColumnCount();
OUTPUT:
  RETVAL

  # BOOL SetRowCount(int nRows = 10);
BOOL
SetRows(object, nRows = 10)
  CMFCWnd* object
  int nRows
CODE:
  RETVAL = object->SetRowCount(nRows);
OUTPUT:
  RETVAL

  # BOOL SetColumnCount(int nCols = 10);
BOOL
SetColumns(object, nCols = 10)
   CMFCWnd* object
   int nCols
CODE:
  RETVAL = object->SetColumnCount(nCols);
OUTPUT:
  RETVAL

  # BOOL SetFixedRowCount(int nFixedRows = 1);
BOOL
SetFixedRows(object, nFixedRows = 1)
   CMFCWnd* object
   int nFixedRows
CODE:
  RETVAL = object->SetFixedRowCount(nFixedRows);
OUTPUT:
  RETVAL

  # BOOL SetFixedColumnCount(int nFixedCols = 1);
BOOL
SetFixedColumns(object, nFixedCols = 1)
   CMFCWnd* object
   int nFixedCols
CODE:
  RETVAL = object->SetFixedColumnCount(nFixedCols);
OUTPUT:
  RETVAL

  # int  GetRowHeight(int nRow) const;
int
GetRowHeight(object, nRow)
  CMFCWnd* object
  int nRow
CODE:
  RETVAL = object->GetRowHeight(nRow);
OUTPUT:
  RETVAL

  # BOOL SetRowHeight(int row, int height);
BOOL
SetRowHeight(object, row, height)
  CMFCWnd* object
  int row
  int height
CODE:
  RETVAL = object->SetRowHeight(row, height);
OUTPUT:
  RETVAL

  # int  GetColumnWidth(int nCol) const;
int
GetColumnWidth(object, nCol)
  CMFCWnd* object
  int nCol
CODE:
  RETVAL = object->GetColumnWidth(nCol);
OUTPUT:
  RETVAL

  # BOOL SetColumnWidth(int col, int width);
BOOL
SetColumnWidth(object, col, width)
  CMFCWnd* object
  int col
  int width
CODE:
  RETVAL = object->SetColumnWidth(col, width);
OUTPUT:
  RETVAL

  #  BOOL GetCellOrigin(const CCellID& cell, LPPOINT p);
  #  BOOL GetCellOrigin(int nRow, int nCol, LPPOINT p);
void
GetCellOrigin(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  POINT point;
PPCODE:
  if (object->GetCellOrigin(nRow, nCol, &point))
  {
    EXTEND(SP, 2);
    XST_mIV( 0, point.x);
    XST_mIV( 1, point.y);
    XSRETURN(2);
  }
  else
    XSRETURN_NO;

  #  BOOL GetCellRect(const CCellID& cell, LPRECT pRect);
  #  BOOL GetCellRect(int nRow, int nCol, LPRECT pRect);
void
GetCellRect(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  RECT rect;
PPCODE:
  if (object->GetCellRect(nRow, nCol, &rect))
  {
    EXTEND(SP, 4);
    XST_mIV( 0, rect.left);
    XST_mIV( 1, rect.top);
    XST_mIV( 2, rect.right);
    XST_mIV( 3, rect.bottom);
    XSRETURN(4);
  }
  else
    XSRETURN_NO;

  #  BOOL GetTextRect(const CCellID& cell, LPRECT pRect);
  #  BOOL GetTextRect(int nRow, int nCol, LPRECT pRect);
void
GetTextRect(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  RECT rect;
PPCODE:
  if (object->GetTextRect(nRow, nCol, &rect))
  {
    EXTEND(SP, 4);
    XST_mIV( 0, rect.left);
    XST_mIV( 1, rect.top);
    XST_mIV( 2, rect.right);
    XST_mIV( 3, rect.bottom);
    XSRETURN(4);
  }
  else
    XSRETURN_NO;

  #  CCellID GetCellFromPt(CPoint point, BOOL bAllowFixedCellCheck = TRUE);
void
GetCellFromPt(object, x, y, bAllowFixedCellCheck = TRUE)
  CMFCWnd* object
  int x
  int y
  BOOL bAllowFixedCellCheck
PREINIT:
  CPoint point(x,y);
  CCellID cellid;
PPCODE:
  cellid = object->GetCellFromPt(point, bAllowFixedCellCheck);
  if (object->IsValid(cellid))
  {
    EXTEND(SP, 2);
    XST_mIV( 0, cellid.row);
    XST_mIV( 1, cellid.col);
    XSRETURN(2);
  }
  else
    XSRETURN_NO;

  #  int  GetFixedRowHeight() const;
int
GetFixedRowsHeight(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFixedRowHeight();
OUTPUT:
  RETVAL

  #  int  GetFixedColumnWidth() const;
int
GetFixedColumnsWidth(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFixedColumnWidth();
OUTPUT:
  RETVAL

  #  long GetVirtualWidth() const;
long
GetVirtualWidth(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetVirtualWidth();
OUTPUT:
  RETVAL

  #  long GetVirtualHeight() const;
long
GetVirtualHeight(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetVirtualHeight();
OUTPUT:
  RETVAL

  #  CSize GetTextExtent(int nRow, int nCol, LPCTSTR str);
void
GetTextExtent(object, nRow, nCol, str)
  CMFCWnd* object
  int nRow
  int nCol
  LPCTSTR str
PREINIT:
  CSize mySize;
PPCODE:
  mySize = object->GetTextExtent(nRow, nCol, str);
  EXTEND(SP, 2);
  XST_mIV(0, mySize.cx);
  XST_mIV(1, mySize.cy);
  XSRETURN(2);

  #  inline CSize GetCellTextExtent(int nRow, int nCol);
void
GetCellTextExtent(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  CSize mySize;
PPCODE:
  mySize = object->GetCellTextExtent(nRow, nCol);
  EXTEND(SP, 2);
  XST_mIV(0, mySize.cx);
  XST_mIV(1, mySize.cy);
  XSRETURN(2);

  #  void     SetGridBkColor(COLORREF clr);
void
SetGridBkColor(object, clr)
  CMFCWnd* object
  COLORREF clr
CODE:
  object->SetGridBkColor(clr);

  #  COLORREF GetGridBkColor() const;
COLORREF
GetGridBkColor(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetGridBkColor();
OUTPUT:
  RETVAL

  #  void     SetGridLineColor(COLORREF clr);
void
SetGridLineColor(object, clr)
  CMFCWnd* object
  COLORREF clr
CODE:
  object->SetGridLineColor(clr);

  #  COLORREF GetGridLineColor() const;
COLORREF
GetGridLineColor(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetGridLineColor();
OUTPUT:
  RETVAL

  #  void     SetTitleTipBackClr(COLORREF clr = CLR_DEFAULT);
void
SetTitleTipBackClr(object, clr = CLR_DEFAULT)
  CMFCWnd* object
  COLORREF clr
CODE:
  object->SetTitleTipBackClr(clr);

  #  COLORREF GetTitleTipBackClr();
COLORREF
GetTitleTipBackClr(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetTitleTipBackClr();
OUTPUT:
  RETVAL

  #  void     SetTitleTipTextClr(COLORREF clr = CLR_DEFAULT);
void
SetTitleTipTextClr(object, clr = CLR_DEFAULT)
  CMFCWnd* object
  COLORREF clr
CODE:
  object->SetTitleTipTextClr(clr);

  #  COLORREF GetTitleTipTextClr();
COLORREF
GetTitleTipTextClr(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetTitleTipTextClr();
OUTPUT:
  RETVAL

  #
  # Deprecated
  #
  #    #  void     SetTextColor(COLORREF clr);
  #  void
  #  SetTextColor(object, clr)
  #    CMFCWnd* object
  #    COLORREF clr
  #  CODE:
  #    object->SetTextColor(clr);
  #
  #    #  COLORREF GetTextColor();
  #  COLORREF
  #  GetTextColor(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetTextColor();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetTextBkColor(COLORREF clr);
  #  void
  #  SetTextBkColor(object, clr)
  #    CMFCWnd* object
  #    COLORREF clr
  #  CODE:
  #    object->SetTextBkColor(clr);
  #
  #    #  COLORREF GetTextBkColor();
  #  COLORREF
  #  GetTextBkColor(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetTextBkColor();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetFixedTextColor(COLORREF clr);
  #  void
  #  SetFixedTextColor(object, clr)
  #    CMFCWnd* object
  #    COLORREF clr
  #  CODE:
  #    object->SetFixedTextColor(clr);
  #
  #    #  COLORREF GetFixedTextColor() const;
  #  COLORREF
  #  GetFixedTextColor(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetFixedTextColor();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetFixedBkColor(COLORREF clr);
  #  void
  #  SetFixedBkColor(object, clr)
  #    CMFCWnd* object
  #    COLORREF clr
  #  CODE:
  #    object->SetFixedBkColor(clr);
  #
  #    #  COLORREF GetFixedBkColor() const;
  #  COLORREF
  #  GetFixedBkColor(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetFixedBkColor();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetGridColor(COLORREF clr);
  #  void
  #  SetGridColor(object, clr)
  #    CMFCWnd* object
  #    COLORREF clr
  #  CODE:
  #    object->SetGridColor(clr);
  #
  #    #  COLORREF GetGridColor();
  #  COLORREF
  #  GetGridColor(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetGridColor();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetBkColor(COLORREF clr);
  #  void
  #  SetBkColor(object, clr)
  #    CMFCWnd* object
  #    COLORREF clr
  #  CODE:
  #    object->SetBkColor(clr);
  #
  #    #  COLORREF GetBkColor();
  #  COLORREF
  #  GetBkColor(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetBkColor();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetDefCellMargin( int nMargin);
  #  void
  #  SetDefCellMargin(object, nMargin)
  #    CMFCWnd* object
  #    int nMargin
  #  CODE:
  #    object->SetDefCellMargin(nMargin);
  #
  #    #  int      GetDefCellMargin() const;
  #  int
  #  GetDefCellMargin(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetDefCellMargin();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  int      GetDefCellHeight() const;
  #  int
  #  GetDefCellHeight(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetDefCellHeight();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetDefCellHeight(int nHeight);
  #  void
  #  SetDefCellHeight(object, nHeight)
  #    CMFCWnd* object
  #    int nHeight
  #  CODE:
  #    object->SetDefCellHeight(nHeight);
  #
  #    #  int      GetDefCellWidth() const;
  #  int
  #  GetDefCellWidth(object)
  #    CMFCWnd* object
  #  CODE:
  #    RETVAL = object->GetDefCellWidth();
  #  OUTPUT:
  #    RETVAL
  #
  #    #  void     SetDefCellWidth(int nWidth)
  #  void
  #  SetDefCellWidth(object, nWidth)
  #    CMFCWnd* object
  #    int nWidth
  #  CODE:
  #    object->SetDefCellWidth(nWidth);
  #

  #  int GetSelectedCount() const;
int
GetSelectedCount(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetSelectedCount();
OUTPUT:
  RETVAL

  #  CCellID SetFocusCell(CCellID cell);
  #  CCellID SetFocusCell(int nRow, int nCol);
void
SetFocusCell(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  CCellID cellid;
PPCODE:
  cellid = object->SetFocusCell(nRow, nCol);
  if (object->IsValid(cellid))
  {
    EXTEND(SP, 2);
    XST_mIV( 0, cellid.row);
    XST_mIV( 1, cellid.col);
    XSRETURN(2);
  }
  else
    XSRETURN_NO;

  #  CCellID GetFocusCell() const;
void
GetFocusCell(object)
  CMFCWnd* object
PREINIT:
  CCellID cellid;
PPCODE:
  cellid = object->GetFocusCell();
  if (object->IsValid(cellid))
  {
    EXTEND(SP, 2);
    XST_mIV( 0, cellid.row);
    XST_mIV( 1, cellid.col);
    XSRETURN(2);
  }
  else
    XSRETURN_NO;

  #  void SetVirtualMode(BOOL bVirtual);
void
SetVirtualMode(object, bVirtual=TRUE)
  CMFCWnd* object
  BOOL bVirtual
CODE:
  object->SetVirtualMode(bVirtual);

  #  BOOL GetVirtualMode() const;
BOOL
GetVirtualMode(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetVirtualMode();
OUTPUT:
  RETVAL

  #  void SetCallbackFunc(GRIDCALLBACK pCallback, LPARAM lParam);
  #  GRIDCALLBACK GetCallbackFunc();

  #  void SetImageList(CImageList* pList);
void
SetImageList(object, imagelist)
  CMFCWnd* object
  HIMAGELIST imagelist
CODE:
  object->SetImageList(CImageList::FromHandle(imagelist));

  #  CImageList* GetImageList() const;
HIMAGELIST
GetImageList(object, imagelist)
  CMFCWnd* object
CODE:
  RETVAL = (HIMAGELIST) object->GetImageList();
OUTPUT:
  RETVAL

  #  void SetGridLines(int nWhichLines = GVL_BOTH);
void
SetGridLines(object, nWhichLines = GVL_BOTH)
  CMFCWnd* object
  int nWhichLines
CODE:
  object->SetGridLines(nWhichLines);

  #  int  GetGridLines() const;
int
GetGridLines(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetGridLines();
OUTPUT:
  RETVAL

  #  void SetEditable(BOOL bEditable = TRUE)
void
SetEditable (object, bEditable = TRUE)
   CMFCWnd* object
   BOOL bEditable
CODE:
  object->SetEditable (bEditable);

  #  BOOL IsEditable() const;
BOOL
IsEditable(object)
  CMFCWnd* object
CODE:
  RETVAL = object->IsEditable();
OUTPUT:
  RETVAL

  #  void SetListMode(BOOL bEnableListMode = TRUE);
void
SetListMode (object, bEnableListMode =TRUE)
   CMFCWnd* object
   BOOL bEnableListMode
CODE:
  object->SetListMode (bEnableListMode);

  #  BOOL GetListMode() const;
BOOL
GetListMode(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetListMode();
OUTPUT:
  RETVAL

  #  void SetSingleRowSelection(BOOL bSing = TRUE);
void
SetSingleRowSelection(object, bSing = TRUE)
   CMFCWnd* object
   BOOL bSing
CODE:
  object->SetSingleRowSelection(bSing);

  #  BOOL GetSingleRowSelection();
BOOL
GetSingleRowSelection(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetSingleRowSelection();
OUTPUT:
  RETVAL

  #  void SetSingleColSelection(BOOL bSing = TRUE);
void
SetSingleColSelection(object, bSing = TRUE)
   CMFCWnd* object
   BOOL bSing
CODE:
  object->SetSingleColSelection(bSing);

  #  BOOL GetSingleColSelection();
BOOL
GetSingleColSelection(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetSingleColSelection();
OUTPUT:
  RETVAL

  #  void EnableSelection(BOOL bEnable = TRUE);
void
EnableSelection(object, bEnable = TRUE)
   CMFCWnd* object
   BOOL bEnable
CODE:
  object->EnableSelection(bEnable);

  #  BOOL IsSelectable() const;
BOOL
IsSelectable(object)
  CMFCWnd* object
CODE:
  RETVAL = object->IsSelectable();
OUTPUT:
  RETVAL

  #  void SetFixedColumnSelection(BOOL bSelect);
void
SetFixedColumnSelection(object, bSelect = TRUE)
   CMFCWnd* object
   BOOL bSelect
CODE:
  object->SetFixedColumnSelection(bSelect);

  #  BOOL GetFixedColumnSelection();
BOOL
GetFixedColumnSelection(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFixedColumnSelection();
OUTPUT:
  RETVAL

  #  void SetFixedRowSelection(BOOL bSelect);
void
SetFixedRowSelection(object, bSelect = TRUE)
   CMFCWnd* object
   BOOL bSelect
CODE:
  object->SetFixedRowSelection(bSelect);

  #  BOOL GetFixedRowSelection();
BOOL
GetFixedRowSelection(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFixedRowSelection();
OUTPUT:
  RETVAL

  #  void EnableDragAndDrop(BOOL bAllow = TRUE);
void
EnableDragAndDrop(object, bAllow = TRUE)
   CMFCWnd* object
   BOOL bAllow
CODE:
  object->EnableDragAndDrop(bAllow);

  #  BOOL GetDragAndDrop() const;
BOOL
GetDragAndDrop(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetDragAndDrop();
OUTPUT:
  RETVAL

  #  void SetRowResize(BOOL bResize = TRUE);
void
SetRowResize(object, bResize = TRUE)
   CMFCWnd* object
   BOOL bResize
CODE:
  object->SetRowResize(bResize);

  #  BOOL GetRowResize() const;
BOOL
GetRowResize(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetRowResize();
OUTPUT:
  RETVAL

  #  void SetColumnResize(BOOL bResize = TRUE);
void
SetColumnResize(object, bResize = TRUE)
   CMFCWnd* object
   BOOL bResize
CODE:
  object->SetColumnResize(bResize);

  #  BOOL GetColumnResize() const;
BOOL
GetColumnResize(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetColumnResize();
OUTPUT:
  RETVAL

  #  void SetHeaderSort(BOOL bSortOnClick = TRUE);
void
SetHeaderSort(object, bSortOnClick = TRUE)
   CMFCWnd* object
   BOOL bSortOnClick
CODE:
  object->SetHeaderSort(bSortOnClick);

  #  BOOL GetHeaderSort() const;
BOOL
GetHeaderSort(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetHeaderSort();
OUTPUT:
  RETVAL

  #  void SetHandleTabKey(BOOL bHandleTab = TRUE);
void
SetHandleTabKey(object, bHandleTab = TRUE)
   CMFCWnd* object
   BOOL bHandleTab
CODE:
  object->SetHandleTabKey(bHandleTab);

  #  BOOL GetHandleTabKey() const;
BOOL
GetHandleTabKey(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetHandleTabKey();
OUTPUT:
  RETVAL

  #  void SetDoubleBuffering(BOOL bBuffer = TRUE);
void
SetDoubleBuffering(object, bBuffer = TRUE)
   CMFCWnd* object
   BOOL bBuffer
CODE:
  object->SetDoubleBuffering(bBuffer);

  #  BOOL GetDoubleBuffering() const;
BOOL
GetDoubleBuffering(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetDoubleBuffering();
OUTPUT:
  RETVAL

  #  void EnableTitleTips(BOOL bEnable = TRUE);
void
EnableTitleTips(object, bEnable = TRUE)
   CMFCWnd* object
   BOOL bEnable
CODE:
  object->EnableTitleTips(bEnable);

  #  BOOL GetTitleTips();
BOOL
GetTitleTips(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetTitleTips();
OUTPUT:
  RETVAL

  #  void SetSortColumn(int nCol);
void
SetSortColumn(object, nCol)
   CMFCWnd* object
   int nCol
CODE:
  object->SetSortColumn(nCol);

  #  int  GetSortColumn() const;
int
GetSortColumn(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetSortColumn();
OUTPUT:
  RETVAL

  #  void SetSortAscending(BOOL bAscending);
void
SetSortAscending(object, bAscending = TRUE)
   CMFCWnd* object
   BOOL bAscending
CODE:
  object->SetSortAscending(bAscending);

  #  BOOL GetSortAscending() const;
BOOL
GetSortAscending(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetSortAscending();
OUTPUT:
  RETVAL

  #  void SetTrackFocusCell(BOOL bTrack);
void
SetTrackFocusCell(object, bTrack = TRUE)
   CMFCWnd* object
   BOOL bTrack
CODE:
  object->SetTrackFocusCell(bTrack);

  #  BOOL GetTrackFocusCell();
BOOL
GetTrackFocusCell(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetTrackFocusCell();
OUTPUT:
  RETVAL

  #  void SetFrameFocusCell(BOOL bFrame);
void
SetFrameFocusCell(object, bFrame = TRUE)
   CMFCWnd* object
   BOOL bFrame
CODE:
  object->SetFrameFocusCell(bFrame);

  #  BOOL GetFrameFocusCell();
BOOL
GetFrameFocusCell(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetFrameFocusCell();
OUTPUT:
  RETVAL

  #  void SetAutoSizeStyle(int nStyle = GVS_BOTH);
void
SetAutoSizeStyle(object, nStyle = GVS_BOTH)
   CMFCWnd* object
   int nStyle
CODE:
  object->SetAutoSizeStyle(nStyle);

  #  int  GetAutoSizeStyle();
int
GetAutoSizeStyle(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetAutoSizeStyle();
OUTPUT:
  RETVAL

  #  void EnableHiddenColUnhide(BOOL bEnable = TRUE);
void
EnableHiddenColUnhide(object, bEnable = TRUE)
   CMFCWnd* object
   BOOL bEnable
CODE:
  object->EnableHiddenColUnhide(bEnable);

  #  BOOL GetHiddenColUnhide();
BOOL
GetHiddenColUnhide(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetHiddenColUnhide();
OUTPUT:
  RETVAL

  #  void EnableHiddenRowUnhide(BOOL bEnable = TRUE);
void
EnableHiddenRowUnhide(object, bEnable = TRUE)
   CMFCWnd* object
   BOOL bEnable
CODE:
  object->EnableHiddenRowUnhide(bEnable);

  #  BOOL GetHiddenRowUnhide();
BOOL
GetHiddenRowUnhide(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetHiddenRowUnhide();
OUTPUT:
  RETVAL

  #  void EnableColumnHide(BOOL bEnable = TRUE);
void
EnableColumnHide(object, bEnable = TRUE)
   CMFCWnd* object
   BOOL bEnable
CODE:
  object->EnableColumnHide(bEnable);

  #  BOOL GetColumnHide();
BOOL
GetColumnHide(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetColumnHide();
OUTPUT:
  RETVAL

  #  void EnableRowHide(BOOL bEnable = TRUE);
void
EnableRowHide(object, bEnable = TRUE)
   CMFCWnd* object
   BOOL bEnable
CODE:
  object->EnableRowHide(bEnable);

  #  BOOL GetRowHide();
BOOL
GetRowHide(object)
  CMFCWnd* object
CODE:
  RETVAL = object->GetRowHide();
OUTPUT:
  RETVAL

  #
  #
  ##################################################################

  ##################################################################
  # default Grid cells. Use these for setting default values such as colors and fonts
  # CGridCellBase* GetDefaultCell(BOOL bFixedRow, BOOL bFixedCol) const;

void
SetDefCellTextColor(object, bFixedRow, bFixedCol, clr = CLR_DEFAULT)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
  COLORREF clr
CODE:
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetTextClr(clr);

COLORREF
GetDefCellTextColor(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
CODE:
  RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetTextClr();
OUTPUT:
  RETVAL

void
SetDefCellBackColor(object, bFixedRow, bFixedCol, clr = CLR_DEFAULT)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
  COLORREF clr
CODE:
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetBackClr(clr);

COLORREF
GetDefCellBackColor(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
CODE:
  RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetBackClr();
OUTPUT:
  RETVAL

void
SetDefCellWidth (object, bFixedRow, bFixedCol, nWidth)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
  int nWidth
CODE:
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetWidth(nWidth);

int
GetDefCellWidth(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
CODE:
  RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetWidth();
OUTPUT:
  RETVAL

void
SetDefCellHeight(object, bFixedRow, bFixedCol, height)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
  int height
CODE:
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetHeight(height);

int
GetDefCellHeight(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
CODE:
  RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetHeight();
OUTPUT:
  RETVAL

void
SetDefCellMargin(object, bFixedRow, bFixedCol, nMargin)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
  int nMargin
CODE:
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetMargin(nMargin);

int
GetDefCellMargin(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
CODE:
  RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetMargin();
OUTPUT:
  RETVAL

void
SetDefCellFormat(object, bFixedRow, bFixedCol, nFormat)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
  DWORD nFormat
CODE:
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetFormat(nFormat);

DWORD
GetDefCellFormat(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
CODE:
  RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetFormat();
OUTPUT:
  RETVAL

  # Not work
  # void
  # SetDefCellImage(object, bFixedRow, bFixedCol, nImage)
  #   CMFCWnd* object
  #   BOOL bFixedRow
  #   BOOL bFixedCol
  #   int nImage
  # CODE:
  #   object->GetDefaultCell(bFixedRow, bFixedCol)->SetImage(nImage);
  #
  # int
  # GetDefCellImage(object, bFixedRow, bFixedCol)
  #   CMFCWnd* object
  #   BOOL bFixedRow
  #   BOOL bFixedCol
  # CODE:
  #   RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetImage();
  # OUTPUT:
  #   RETVAL
  #
  # void
  # SetDefCellStyle(object, bFixedRow, bFixedCol, dwStyle)
  #   CMFCWnd* object
  #   BOOL bFixedRow
  #   BOOL bFixedCol
  #   DWORD dwStyle
  # CODE:
  #   object->GetDefaultCell(bFixedRow, bFixedCol)->SetStyle(dwStyle);
  #
  # int
  # GetDefCellStyle(object, bFixedRow, bFixedCol)
  #   CMFCWnd* object
  #   BOOL bFixedRow
  #   BOOL bFixedCol
  # CODE:
  #   RETVAL = object->GetDefaultCell(bFixedRow, bFixedCol)->GetStyle();
  # OUTPUT:
  #   RETVAL

#
# GetDefCellFont

void
SetDefCellFont(object, bFixedRow, bFixedCol, ...)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
PREINIT:
  LOGFONT logfont;
  int next_i;
  int i;
  char* option;
CODE:
  ZeroMemory(&logfont, sizeof(LOGFONT));

  logfont.lfWeight = 400;
  logfont.lfCharSet = DEFAULT_CHARSET;
  logfont.lfOutPrecision = OUT_DEFAULT_PRECIS;
  logfont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
  logfont.lfQuality = DEFAULT_QUALITY;
  logfont.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE;

  next_i = -1;
  for(i = 3; i < items; i++) {
    if (next_i == -1) {
      option = SvPV_nolen(ST(i));
      if (strcmp(option, "-height") == 0 || strcmp(option, "-size") == 0) {
        next_i = i + 1;
        logfont.lfHeight = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-width") == 0) {
        next_i = i + 1;
        logfont.lfWidth = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-escapement") == 0) {
        next_i = i + 1;
        logfont.lfEscapement = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-orientation") == 0) {
        next_i = i + 1;
        logfont.lfOrientation = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-weight") == 0) {
        next_i = i + 1;
        logfont.lfWeight = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-bold") == 0) {
        next_i = i + 1;
        if(SvIV(ST(next_i)) != 0) logfont.lfWeight = FW_BOLD;
      }
      if(strcmp(option, "-italic") == 0) {
        next_i = i + 1;
        logfont.lfItalic = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-underline") == 0) {
        next_i = i + 1;
        logfont.lfUnderline = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-strikeout") == 0) {
        next_i = i + 1;
        logfont.lfStrikeOut = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-charset") == 0) {
        next_i = i + 1;
        logfont.lfCharSet = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-outputprecision") == 0) {
        next_i = i + 1;
        logfont.lfOutPrecision = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-clipprecision") == 0) {
        next_i = i + 1;
        logfont.lfClipPrecision = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-quality") == 0) {
        next_i = i + 1;
        logfont.lfQuality = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-family") == 0) {
        next_i = i + 1;
        logfont.lfPitchAndFamily = (BYTE) SvIV(ST(next_i));
      }
      if (strcmp(option, "-name") == 0|| strcmp(option, "-face") == 0) {
        next_i = i + 1;
        strncpy(logfont.lfFaceName, SvPV_nolen(ST(next_i)), LF_FACESIZE);
      }
    }
    else
      next_i = -1;
  }
  object->GetDefaultCell(bFixedRow, bFixedCol)->SetFont(&logfont);

  # const LOGFONT* GetItemFont(int nRow, int nCol);
void
GetDefCellFont(object, bFixedRow, bFixedCol)
  CMFCWnd* object
  BOOL bFixedRow
  BOOL bFixedCol
PREINIT:
  const LOGFONT* logfont;
PPCODE:
  logfont = object->GetDefaultCell(bFixedRow, bFixedCol)->GetFont();
  if (logfont != NULL)
  {
    EXTEND(SP, 28);
    XST_mPV( 0, "-height");
    XST_mIV( 1, logfont->lfHeight);
    XST_mPV( 2, "-width");
    XST_mIV( 3, logfont->lfWidth);
    XST_mPV( 4, "-escapement");
    XST_mIV( 5, logfont->lfEscapement);
    XST_mPV( 6, "-orientation");
    XST_mIV( 7, logfont->lfOrientation);
    XST_mPV( 8, "-weight");
    XST_mIV( 9, logfont->lfWeight);
    XST_mPV(10, "-italic");
    XST_mIV(11, logfont->lfItalic);
    XST_mPV(12, "-underline");
    XST_mIV(13, logfont->lfUnderline);
    XST_mPV(14, "-strikeout");
    XST_mIV(15, logfont->lfStrikeOut);
    XST_mPV(16, "-charset");
    XST_mIV(17, logfont->lfCharSet);
    XST_mPV(18, "-outputprecision");
    XST_mIV(19, logfont->lfOutPrecision);
    XST_mPV(20, "-clipprecision");
    XST_mIV(21, logfont->lfClipPrecision);
    XST_mPV(22, "-quality");
    XST_mIV(23, logfont->lfQuality);
    XST_mPV(24, "-family");
    XST_mIV(25, logfont->lfPitchAndFamily);
    XST_mPV(26, "-name");
    XST_mPV(27, logfont->lfFaceName);
    XSRETURN(28);
  }
  else
    XSRETURN_NO;



  ##################################################################
  #
  # Grid cell Attributes
  #

  # CGridCellBase* GetCell(int nRow, int nCol) const;

  # void SetModified(BOOL bModified = TRUE, int nRow = -1, int nCol = -1);
void
SetModified(object, bModified = TRUE, nRow = -1, nCol = -1)
  CMFCWnd* object
  BOOL bModified
  int nRow
  int nCol
CODE:
  object->SetModified(bModified, nRow, nCol);

  # BOOL GetModified(int nRow = -1, int nCol = -1);
BOOL
GetModified(object, nRow = -1, nCol = -1)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetModified(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL IsCellFixed(int nRow, int nCol);
BOOL
IsCellFixed(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->IsCellFixed(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItem(const GV_ITEM* pItem);
  # BOOL   GetItem(GV_ITEM* pItem);

  # BOOL   SetItemText(int nRow, int nCol, LPCTSTR str);
BOOL
SetCellText(object, nRow, nCol, str)
  CMFCWnd* object
  int nRow
  int nCol
  LPCTSTR str
CODE:
  RETVAL = object->SetItemText(nRow, nCol, str);
OUTPUT:
  RETVAL

  # CString GetItemText(int nRow, int nCol) const;
LPCTSTR
GetCellText(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetItemText(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItemTextFmt(int nRow, int nCol, LPCTSTR szFmt, ...);
  # BOOL   SetItemTextFmtID(int nRow, int nCol, UINT nID, ...);

  # BOOL   SetItemData(int nRow, int nCol, LPARAM lParam);
BOOL
SetCellData(object, nRow, nCol, lParam)
  CMFCWnd* object
  int nRow
  int nCol
  SV* lParam
CODE:
  RETVAL = object->SetItemData(nRow, nCol, (LPARAM) lParam);
OUTPUT:
  RETVAL

  # LPARAM GetItemData(int nRow, int nCol) const;
SV*
GetCellData(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = (SV*) object->GetItemData(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItemImage(int nRow, int nCol, int iImage);
BOOL
SetCellImage(object, nRow, nCol, iImage)
  CMFCWnd* object
  int nRow
  int nCol
  int iImage
CODE:
  RETVAL = object->SetItemImage(nRow, nCol, iImage);
OUTPUT:
  RETVAL

  # int    GetItemImage(int nRow, int nCol) const;
int
GetCellImage(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetItemImage(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItemState(int nRow, int nCol, UINT state);
BOOL
SetCellState(object, nRow, nCol, state)
  CMFCWnd* object
  int nRow
  int nCol
  UINT state
CODE:
  RETVAL = object->SetItemState(nRow, nCol, state);
OUTPUT:
  RETVAL

  # UINT   GetItemState(int nRow, int nCol) const;
UINT
GetCellState(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetItemState(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItemFormat(int nRow, int nCol, UINT nFormat);
BOOL
SetCellFormat(object, nRow, nCol, nFormat)
  CMFCWnd* object
  int nRow
  int nCol
  UINT nFormat
CODE:
  RETVAL = object->SetItemFormat(nRow, nCol, nFormat);
OUTPUT:
  RETVAL

  # UINT   GetItemFormat(int nRow, int nCol) const;
UINT
GetCellFormat(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetItemFormat(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItemBkColour(int nRow, int nCol, COLORREF cr = CLR_DEFAULT);
BOOL
SetCellBkColor(object, nRow, nCol, cr = CLR_DEFAULT)
  CMFCWnd* object
  int nRow
  int nCol
  COLORREF cr
CODE:
  RETVAL = object->SetItemBkColour(nRow, nCol, cr);
OUTPUT:
  RETVAL

  # COLORREF GetItemBkColour(int nRow, int nCol) const;
COLORREF
GetCellBkColor(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetItemBkColour(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL   SetItemFgColour(int nRow, int nCol, COLORREF cr = CLR_DEFAULT);
BOOL
SetCellColor(object, nRow, nCol, cr = CLR_DEFAULT)
  CMFCWnd* object
  int nRow
  int nCol
  COLORREF cr
CODE:
  RETVAL = object->SetItemFgColour(nRow, nCol, cr);
OUTPUT:
  RETVAL

  # COLORREF GetItemFgColour(int nRow, int nCol) const;
COLORREF
GetCellColor(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->GetItemFgColour(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL SetItemFont(int nRow, int nCol, const LOGFONT* lf);
BOOL
SetCellFont(object, nRow, nCol, ...)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  LOGFONT logfont;
  int next_i;
  int i;
  char* option;
CODE:
  ZeroMemory(&logfont, sizeof(LOGFONT));

  logfont.lfWeight = 400;
  logfont.lfCharSet = DEFAULT_CHARSET;
  logfont.lfOutPrecision = OUT_DEFAULT_PRECIS;
  logfont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
  logfont.lfQuality = DEFAULT_QUALITY;
  logfont.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE;

  next_i = -1;
  for(i = 3; i < items; i++) {
    if (next_i == -1) {
      option = SvPV_nolen(ST(i));
      if (strcmp(option, "-height") == 0 || strcmp(option, "-size") == 0) {
        next_i = i + 1;
        logfont.lfHeight = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-width") == 0) {
        next_i = i + 1;
        logfont.lfWidth = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-escapement") == 0) {
        next_i = i + 1;
        logfont.lfEscapement = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-orientation") == 0) {
        next_i = i + 1;
        logfont.lfOrientation = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-weight") == 0) {
        next_i = i + 1;
        logfont.lfWeight = (LONG) SvIV(ST(next_i));
      }
      if(strcmp(option, "-bold") == 0) {
        next_i = i + 1;
        if(SvIV(ST(next_i)) != 0) logfont.lfWeight = FW_BOLD;
      }
      if(strcmp(option, "-italic") == 0) {
        next_i = i + 1;
        logfont.lfItalic = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-underline") == 0) {
        next_i = i + 1;
        logfont.lfUnderline = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-strikeout") == 0) {
        next_i = i + 1;
        logfont.lfStrikeOut = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-charset") == 0) {
        next_i = i + 1;
        logfont.lfCharSet = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-outputprecision") == 0) {
        next_i = i + 1;
        logfont.lfOutPrecision = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-clipprecision") == 0) {
        next_i = i + 1;
        logfont.lfClipPrecision = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-quality") == 0) {
        next_i = i + 1;
        logfont.lfQuality = (BYTE) SvIV(ST(next_i));
      }
      if(strcmp(option, "-family") == 0) {
        next_i = i + 1;
        logfont.lfPitchAndFamily = (BYTE) SvIV(ST(next_i));
      }
      if (strcmp(option, "-name") == 0|| strcmp(option, "-face") == 0) {
        next_i = i + 1;
        strncpy(logfont.lfFaceName, SvPV_nolen(ST(next_i)), LF_FACESIZE);
      }
    }
    else
      next_i = -1;
  }

  RETVAL = object->SetItemFont(nRow, nCol, &logfont);
OUTPUT:
  RETVAL

  # const LOGFONT* GetItemFont(int nRow, int nCol);
void
GetCellFont(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  const LOGFONT* logfont;
PPCODE:
  logfont = object->GetItemFont(nRow, nCol);
  if (logfont != NULL)
  {
    EXTEND(SP, 28);
    XST_mPV( 0, "-height");
    XST_mIV( 1, logfont->lfHeight);
    XST_mPV( 2, "-width");
    XST_mIV( 3, logfont->lfWidth);
    XST_mPV( 4, "-escapement");
    XST_mIV( 5, logfont->lfEscapement);
    XST_mPV( 6, "-orientation");
    XST_mIV( 7, logfont->lfOrientation);
    XST_mPV( 8, "-weight");
    XST_mIV( 9, logfont->lfWeight);
    XST_mPV(10, "-italic");
    XST_mIV(11, logfont->lfItalic);
    XST_mPV(12, "-underline");
    XST_mIV(13, logfont->lfUnderline);
    XST_mPV(14, "-strikeout");
    XST_mIV(15, logfont->lfStrikeOut);
    XST_mPV(16, "-charset");
    XST_mIV(17, logfont->lfCharSet);
    XST_mPV(18, "-outputprecision");
    XST_mIV(19, logfont->lfOutPrecision);
    XST_mPV(20, "-clipprecision");
    XST_mIV(21, logfont->lfClipPrecision);
    XST_mPV(22, "-quality");
    XST_mIV(23, logfont->lfQuality);
    XST_mPV(24, "-family");
    XST_mIV(25, logfont->lfPitchAndFamily);
    XST_mPV(26, "-name");
    XST_mPV(27, logfont->lfFaceName);
    XSRETURN(28);
  }
  else
    XSRETURN_NO;

  # BOOL IsItemEditing(int nRow, int nCol);
BOOL
IsCellEditing(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->IsItemEditing(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL SetCellType(int nRow, int nCol, CRuntimeClass* pRuntimeClass);

BOOL
SetCellType(object, nRow, nCol, iType = GVIT_DEFAULT)
  CMFCWnd* object
  int nRow
  int nCol
  int iType
PREINIT:
  CRuntimeClass* pRuntimeClass;
CODE:
  pRuntimeClass = GetRuntimeClassFromType(iType);
  if (pRuntimeClass != NULL)
    RETVAL = object->SetCellType(nRow, nCol, pRuntimeClass);
  else
    RETVAL = FALSE;
OUTPUT:
  RETVAL

# BOOL SetDefaultCellType( CRuntimeClass* pRuntimeClass);

BOOL
SetDefCellType(object, iType = GVIT_DEFAULT)
  CMFCWnd* object
  int iType
PREINIT:
  CRuntimeClass* pRuntimeClass;
CODE:
  pRuntimeClass = GetRuntimeClassFromType(iType);
  if (pRuntimeClass != NULL)
    RETVAL = object->SetDefaultCellType(pRuntimeClass);
  else
    RETVAL = FALSE;
OUTPUT:
  RETVAL

  # Option CGridCellCheck

BOOL
SetCellCheck(object, nRow, nCol, bChecked = TRUE)
  CMFCWnd* object
  int nRow
  int nCol
  BOOL bChecked
PREINIT:
  CGridCellBase* pCell;
CODE:
  pCell = object->GetCell(nRow, nCol);
  if (pCell && pCell->IsKindOf(RUNTIME_CLASS(CGridCellCheck)))
    RETVAL = ((CGridCellCheck*)pCell)->SetCheck(bChecked);
  else
    RETVAL = FALSE;
OUTPUT:
  RETVAL

BOOL
GetCellCheck(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  CGridCellBase* pCell;
CODE:
  pCell = object->GetCell(nRow, nCol);
  if (pCell && pCell->IsKindOf(RUNTIME_CLASS(CGridCellCheck)))
    RETVAL = ((CGridCellCheck*)pCell)->GetCheck();
  else
    RETVAL = FALSE;
OUTPUT:
  RETVAL

  # Option CGridCombo/CGridCellURL/CGridCellCheck

BOOL
SetCellOptions(object, nRow, nCol, ...)
  CMFCWnd* object
  int nRow
  int nCol
PREINIT:
  CGridCellBase* pCell;
  CStringArray csa;
  int i, next_i;
  char *option;
CODE:
  pCell = object->GetCell(nRow, nCol);
  if (pCell && pCell->IsKindOf(RUNTIME_CLASS(CGridCellCombo)))
  {
    if(SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVAV)
    {
      AV* av = (AV*) SvRV(ST(3));
      for (i = 0; i <= av_len(av); i++)
      {
        SV** sv = av_fetch(av, i, 0);
        csa.Add (SvPV_nolen(*sv));
      }
    }
    else
    {
      for (i = 3; i < items; i++)
        csa.Add (SvPV_nolen(ST(i)));
    }

    ((CGridCellCombo*)pCell)->SetOptions(csa);
    RETVAL = TRUE;
  }
  else if (pCell && pCell->IsKindOf(RUNTIME_CLASS(CGridCellURL)))
  {
    RETVAL = FALSE;
    next_i = -1;
    for(i = 3; i < items; i++) {
      if (next_i == -1) {
        option = SvPV_nolen(ST(i));
        if (strcmp(option, "-autolaunch") == 0) {
          next_i = i + 1;
          ((CGridCellURL*)pCell)->SetAutoLaunchUrl((LONG) SvIV(ST(next_i)));
          RETVAL = TRUE;
        }
      }
      else
        next_i = -1;
    }
  }
  else if (pCell && pCell->IsKindOf(RUNTIME_CLASS(CGridCellCheck)))
  {
    RETVAL = FALSE;
    next_i = -1;
    for(i = 3; i < items; i++) {
      if (next_i == -1) {
        option = SvPV_nolen(ST(i));
        if (strcmp(option, "-checked") == 0) {
          next_i = i + 1;
          ((CGridCellCheck*)pCell)->SetCheck((LONG) SvIV(ST(next_i)));
          RETVAL = TRUE;
        }
      }
      else
        next_i = -1;
    }
  }
  else
    RETVAL = FALSE;
OUTPUT:
  RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  # Operation
  #

  # int  InsertColumn(LPCTSTR strHeading, UINT nFormat = DT_CENTER|DT_VCENTER|DT_SINGLELINE, int nColumn = -1);
int
InsertColumn(object, strHeading, nFormat = DT_CENTER|DT_VCENTER|DT_SINGLELINE, nColumn = -1)
  CMFCWnd* object
  LPCTSTR strHeading
  UINT nFormat
  int nColumn
CODE:
  RETVAL = object->InsertColumn(strHeading, nFormat, nColumn);
OUTPUT:
  RETVAL

  # int  InsertRow(LPCTSTR strHeading, int nRow = -1);
int
InsertRow(object, strHeading, nRow = -1)
  CMFCWnd* object
  LPCTSTR strHeading
  int nRow
CODE:
  RETVAL = object->InsertRow(strHeading, nRow);
OUTPUT:
  RETVAL

  # BOOL DeleteColumn(int nColumn);
BOOL
DeleteColumn(object, nColumn)
  CMFCWnd* object
  int nColumn
CODE:
  RETVAL = object->DeleteColumn(nColumn);
OUTPUT:
  RETVAL

  # BOOL DeleteRow(int nRow);
BOOL
DeleteRow(object, nRow)
  CMFCWnd* object
  int nRow
CODE:
  RETVAL = object->DeleteRow(nRow);
OUTPUT:
  RETVAL

  # BOOL DeleteNonFixedRows();
BOOL
DeleteNonFixedRows(object)
  CMFCWnd* object
CODE:
  RETVAL = object->DeleteNonFixedRows();
OUTPUT:
  RETVAL

  # BOOL DeleteAllItems();
BOOL
DeleteAllCells(object)
  CMFCWnd* object
CODE:
  RETVAL = object->DeleteAllItems();
OUTPUT:
  RETVAL

  # void ClearCells(CCellRange Selection);
void
ClearCells (object, nMinRow, nMinCol, nMaxRow, nMaxCol)
  CMFCWnd* object
  int nMinRow
  int nMinCol
  int nMaxRow
  int nMaxCol
PREINIT:
  CCellRange selection (nMinRow, nMinCol, nMaxRow, nMaxCol);
PPCODE:
  object->ClearCells(selection);

  # BOOL AutoSizeRow(int nRow, BOOL bResetScroll = TRUE);
BOOL
AutoSizeRow(object, nRow, bResetScroll = TRUE)
  CMFCWnd* object
  int nRow
  BOOL bResetScroll
CODE:
  RETVAL = object->AutoSizeRow(nRow, bResetScroll);
OUTPUT:
  RETVAL

  # BOOL AutoSizeColumn(int nCol, UINT nAutoSizeStyle = GVS_DEFAULT, BOOL bResetScroll = TRUE);
BOOL
AutoSizeColumn(object, nCol, nAutoSizeStyle = GVS_DEFAULT, bResetScroll = TRUE)
  CMFCWnd* object
  int nCol
  UINT nAutoSizeStyle
  BOOL bResetScroll
CODE:
  RETVAL = object->AutoSizeColumn(nCol, nAutoSizeStyle, bResetScroll);
OUTPUT:
  RETVAL

  # void AutoSizeRows();
void
AutoSizeRows(object)
  CMFCWnd* object
CODE:
  object->AutoSizeRows();

  # void AutoSizeColumns(UINT nAutoSizeStyle = GVS_DEFAULT);
void
AutoSizeColumns(object, nAutoSizeStyle = GVS_DEFAULT)
  CMFCWnd* object
  UINT nAutoSizeStyle
CODE:
  object->AutoSizeColumns(nAutoSizeStyle);

  # void AutoSize(UINT nAutoSizeStyle = GVS_DEFAULT);
void
AutoSize(object, nAutoSizeStyle = GVS_DEFAULT)
  CMFCWnd* object
  UINT nAutoSizeStyle
CODE:
  object->AutoSize(nAutoSizeStyle);

  # void ExpandColumnsToFit(BOOL bExpandFixed = TRUE);
void
ExpandColumnsToFit(object, bExpandFixed = TRUE)
  CMFCWnd* object
  BOOL bExpandFixed
CODE:
  object->ExpandColumnsToFit(bExpandFixed);

  # void ExpandLastColumn();
void
ExpandLastColumn(object)
  CMFCWnd* object
CODE:
  object->ExpandLastColumn();

  # void ExpandRowsToFit(BOOL bExpandFixed = TRUE);
void
ExpandRowsToFit(object, bExpandFixed = TRUE)
  CMFCWnd* object
  BOOL bExpandFixed
CODE:
  object->ExpandRowsToFit(bExpandFixed);

  # void ExpandToFit(BOOL bExpandFixed = TRUE);
void
ExpandToFit(object, bExpandFixed = TRUE)
  CMFCWnd* object
  BOOL bExpandFixed
CODE:
  object->ExpandToFit(bExpandFixed);

  # void Refresh();
void
Refresh(object)
  CMFCWnd* object
CODE:
  object->Refresh();

  # void AutoFill(); // Fill grid with blank cells
void
AutoFill(object)
  CMFCWnd* object
CODE:
  object->AutoFill();

  # void EnsureVisible(CCellID &cell);
  # void EnsureVisible(int nRow, int nCol);
  # Duplicate of EnsureCellVisible??
  # void
  # EnsureVisible(object, nRow, nCol)
  # CMFCWnd* object
  #   int nRow
  #   int nCol
  # CODE:
  #   object->EnsureVisible(nRow, nCol);

void
EnsureCellVisible(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  object->EnsureVisible(nRow, nCol);

  # BOOL IsCellVisible(CCellID cell);
  # BOOL IsCellVisible(int nRow, int nCol);
BOOL
IsCellVisible(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->IsCellVisible(nRow, nCol);
OUTPUT:
  RETVAL

BOOL
SetCellEditable(object, nRow, nCol, bEditable = TRUE)
  CMFCWnd* object
  int nRow
  int nCol
  BOOL bEditable
PREINIT:
  UINT state;
CODE:
  state = object->GetItemState(nRow, nCol);
  if (bEditable)
    state &= ~GVIS_READONLY;
  else
    state |= GVIS_READONLY;
  RETVAL = object->SetItemState(nRow, nCol, state);
OUTPUT:
  RETVAL

  # BOOL IsCellEditable(CCellID &cell) const;
  # BOOL IsCellEditable(int nRow, int nCol) const;
BOOL
IsCellEditable(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->IsCellEditable(nRow, nCol);
OUTPUT:
  RETVAL

  # BOOL IsCellSelected(CCellID &cell) const;
  # BOOL IsCellSelected(int nRow, int nCol) const;
BOOL
IsCellSelected(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->IsCellSelected(nRow, nCol);
OUTPUT:
  RETVAL

  # void SetRedraw(BOOL bAllowDraw, BOOL bResetScrollBars = FALSE);
void
SetRedraw(object, bAllowDraw, bResetScrollBars = FALSE)
  CMFCWnd* object
  BOOL bAllowDraw
  BOOL bResetScrollBars
CODE:
  object->SetRedraw(bAllowDraw, bResetScrollBars);

  # BOOL RedrawCell(const CCellID& cell, CDC* pDC = NULL);
  # BOOL RedrawCell(int nRow, int nCol, CDC* pDC = NULL);
BOOL
RedrawCell(object, nRow, nCol, hDC=0)
  CMFCWnd* object
  int nRow
  int nCol
  HDC hDC
CODE:
  RETVAL = object->RedrawCell(nRow, nCol,
                              (hDC ? CDC::FromHandle(hDC) : NULL));
OUTPUT:
  RETVAL

  # BOOL RedrawRow(int row);
BOOL
RedrawRow(object, row)
  CMFCWnd* object
  int row
CODE:
  RETVAL = object->RedrawRow(row);
OUTPUT:
  RETVAL

  # BOOL RedrawColumn(int col);
BOOL
RedrawColumn(object, col)
  CMFCWnd* object
  int col
CODE:
  RETVAL = object->RedrawColumn(col);
OUTPUT:
  RETVAL

  # BOOL Save(LPCTSTR filename, TCHAR chSeparator = _T(','));
BOOL
Save(object, filename, chSeparator = ',')
  CMFCWnd* object
  LPCTSTR filename
  char chSeparator
CODE:
  RETVAL = object->Save(filename, chSeparator);
OUTPUT:
  RETVAL

  # BOOL Load(LPCTSTR filename, TCHAR chSeparator = _T(','));
BOOL
Load(object, filename, chSeparator = ',')
  CMFCWnd* object
  LPCTSTR filename
  char chSeparator
CODE:
  RETVAL = object->Load(filename, chSeparator);
OUTPUT:
  RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  # Cell Ranges
  #

  # CCellRange GetCellRange() const;
void
GetCellRange(object)
  CMFCWnd* object
PREINIT:
  CCellRange range;
CODE:
  range = object->GetCellRange();
  EXTEND(SP, 4);
  XST_mIV( 0, range.GetMinRow());
  XST_mIV( 1, range.GetMinCol());
  XST_mIV( 2, range.GetMaxRow());
  XST_mIV( 3, range.GetMaxCol());
  XSRETURN(4);

  # CCellRange GetSelectedCellRange() const;
void
GetSelectedCellRange(object)
  CMFCWnd* object
PREINIT:
  CCellRange range;
CODE:
  range = object->GetSelectedCellRange();
  if (object->IsValid(range))
  {
    EXTEND(SP, 4);
    XST_mIV( 0, range.GetMinRow());
    XST_mIV( 1, range.GetMinCol());
    XST_mIV( 2, range.GetMaxRow());
    XST_mIV( 3, range.GetMaxCol());
    XSRETURN(4);
  }
  else
    XSRETURN_NO;

  # void SetSelectedRange(const CCellRange& Range, BOOL bForceRepaint = FALSE, BOOL bSelectCells = TRUE);
  # void SetSelectedRange(int nMinRow, int nMinCol, int nMaxRow, int nMaxCol,
  #                       BOOL bForceRepaint = FALSE, BOOL bSelectCells = TRUE);
void
SetSelectedCellRange(object, nMinRow, nMinCol, nMaxRow, nMaxCol, bForceRepaint = FALSE, bSelectCells = TRUE)
  CMFCWnd* object
  int nMinRow
  int nMinCol
  int nMaxRow
  int nMaxCol
  BOOL bForceRepaint
  BOOL bSelectCells
CODE:
  object->SetSelectedRange(nMinRow, nMinCol, nMaxRow, nMaxCol, bForceRepaint, bSelectCells);

  # BOOL IsValid(const CCellRange& range) const;
  # BOOL IsValid(const CCellID& cell) const;
  # BOOL IsValid(int nRow, int nCol) const;
BOOL
IsValid(object, nRow, nCol)
  CMFCWnd* object
  int nRow
  int nCol
CODE:
  RETVAL = object->IsValid(nRow, nCol);
OUTPUT:
  RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  # Clipboard, Drag and Drop
  #

  #   # virtual void CutSelectedText();
  # void
  # CutSelectedText(object)
  #   CMFCWnd* object
  # CODE:
  #   object->CutSelectedText();

  # virtual COleDataSource* CopyTextFromGrid();
  # virtual BOOL PasteTextToGrid(CCellID cell, COleDataObject* pDataObject, BOOL bSelectPastedCells=TRUE);
  # virtual void OnBeginDrag();
  # virtual DROPEFFECT OnDragEnter(COleDataObject* pDataObject, DWORD dwKeyState, CPoint point);
  # virtual DROPEFFECT OnDragOver(COleDataObject* pDataObject, DWORD dwKeyState, CPoint point);
  # virtual void OnDragLeave();
  # virtual BOOL OnDrop(COleDataObject* pDataObject, DROPEFFECT dropEffect, CPoint point);

  # virtual void OnEditCut();
void
OnEditCut(object)
  CMFCWnd* object
CODE:
  object->OnEditCut();

  # virtual void OnEditCopy();
void
OnEditCopy(object)
  CMFCWnd* object
CODE:
  object->OnEditCopy();

  # virtual void OnEditPaste();
void
OnEditPaste(object)
  CMFCWnd* object
CODE:
  object->OnEditPaste();

  # virtual void OnEditSelectAll();
void
OnEditSelectAll(object)
  CMFCWnd* object
CODE:
  object->OnEditSelectAll();

  #
  #
  ##################################################################

  ##################################################################
  #
  # Search and Sort
  #

  # CCellID GetNextItem(CCellID& cell, int nFlags) const;

void
GetNextCell(object, nRow, nCol, nFlags)
  CMFCWnd* object
  int nRow
  int nCol
  int nFlags
PREINIT:
  CCellID cell;
PPCODE:
  cell = object->GetNextItem(CCellID(nRow, nCol), nFlags);
  if (object->IsValid(cell))
  {
    EXTEND(SP, 2);
    XST_mIV( 0, cell.row);
    XST_mIV( 1, cell.col);
    XSRETURN(2);
  }
  else
    XSRETURN_NO;

  #
  # BOOL SortItems(int nCol, BOOL bAscending, LPARAM data = 0);
  # BOOL SortItems(PFNLVCOMPARE pfnCompare, int nCol, BOOL bAscending, LPARAM data = 0);
BOOL
SortCells(object, nCol, bAscending, pfun = NULL)
  CMFCWnd* object
  int nCol
  BOOL bAscending
  SV* pfun
CODE:
  if (pfun != NULL)
    RETVAL = object->CGridCtrl::SortItems(pfnSortCompare, nCol, bAscending, (LPARAM) pfun);
  else
    RETVAL = object->SortItems(nCol, bAscending, 0);
OUTPUT:
  RETVAL

  # BOOL SortTextItems(int nCol, BOOL bAscending, LPARAM data = 0);
BOOL
SortTextCells(object, nCol, bAscending)
  CMFCWnd* object
  int nCol
  BOOL bAscending
CODE:
  RETVAL = object->CGridCtrl::SortItems(CMFCWnd::pfnCellTextCompare,
                                        nCol, bAscending, 0);
OUTPUT:
  RETVAL

BOOL
SortNumericCells(object, nCol, bAscending)
  CMFCWnd* object
  int nCol
  BOOL bAscending
CODE:
  RETVAL = object->CGridCtrl::SortItems(CMFCWnd::pfnCellNumericCompare,
                                        nCol, bAscending, 0);
OUTPUT:
  RETVAL

  # void SetCompareFunction(PFNLVCOMPARE pfnCompare);
void
SetSortFunction(object, pFun = NULL, nCol = -1)
  CMFCWnd* object
  SV* pFun
  int nCol
CODE:
  if (pFun != NULL) {
    if (nCol < 0) {
      object->m_SvSub = SvREFCNT_inc(pFun);
      object->SetCompareFunction(pfnSortCompare);
    }
    else if (nCol < object->GetColumnCount()) {
      object->m_RowSortFunc.SetAtGrow (nCol, SvREFCNT_inc(pFun));
    }
  }
  else {
    if (nCol < 0) {
      SvREFCNT_dec (object->m_SvSub);
      object->m_SvSub = NULL;
      object->SetCompareFunction(NULL);
    }
    else if (nCol < object->GetColumnCount()) {
      pFun = (SV*) object->m_RowSortFunc.GetAt (nCol);
      if (pFun != NULL) {
        SvREFCNT_dec (pFun);
        object->m_RowSortFunc.SetAtGrow(nCol, NULL);
      }
    }
  }

  # // in-built sort functions
  # static int CALLBACK pfnCellTextCompare(LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort);
  # static int CALLBACK pfnCellNumericCompare(LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort);

  #
  #
  ##################################################################

