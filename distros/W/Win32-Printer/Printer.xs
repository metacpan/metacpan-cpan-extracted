/*----------------------------------------------------------------------------*\
| Win32::Printer                                                               |
| V 0.9.1 (2008-04-28)                                                         |
| Copyright (C) 2003-2005 Edgars Binans                                        |
\*----------------------------------------------------------------------------*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef EBBL
#define EBBL_NAL
#include "ebblwc.h"
#endif

#ifdef FREE
#include "FreeImage.h"
#endif

#ifdef GHOST
#include "iapi.h"
#endif

#include <winspool.h>
#include <commdlg.h>

//----------------------------------------------------------------------------//

LPWSTR ToWide(
  LPCSTR lpString,
  int cbString,
  int* sz)
{
  LPWSTR lpwString;

  // Determine required buffer
  *sz = MultiByteToWideChar(CP_UTF8, 0, lpString, cbString, 0, 0);
  if (*sz == 0) { return 0; }

  // Allocate memory
  lpwString = (LPWSTR)malloc(*sz * sizeof(wchar_t));
  if (lpwString == 0) { return 0; }

  // Convert utf-8 to wide character
  *sz = MultiByteToWideChar(CP_UTF8, 0, lpString, cbString, lpwString, *sz);
  if (*sz == 0) {
    free(lpwString);
    return 0;
  }

  return lpwString;
}

//----------------------------------------------------------------------------//

BOOL GetTextExtentPoint32UTF8(
  HDC hdc,
  LPCSTR lpString,
  int cbString,
  LPSIZE lpSize)
{
  int sz;
  LPWSTR lpwString;
  BOOL retVal;

  lpwString = ToWide(lpString, cbString, &sz);

  // Do unicode GetTextExtentPoint32
  retVal = GetTextExtentPoint32W(hdc, lpwString, sz, lpSize);

  // Free buffer
  free(lpwString);

  return retVal;
}

//----------------------------------------------------------------------------//

BOOL
GetTextExtentExPointUTF8(
  HDC hdc,
  LPCSTR lpszStr,
  int cchString,
  int nMaxExtent,
  LPINT lpnFit,
  LPINT alpDx,
  LPSIZE lpSize)
{
  int sz;
  LPWSTR lpwString;
  BOOL retVal;

  lpwString = ToWide(lpszStr, cchString, &sz);

  // Do unicode GetTextExtentExPoint
  retVal = GetTextExtentExPointW(hdc, lpwString, sz, nMaxExtent, lpnFit, alpDx, lpSize);

  // Free buffer
  free(lpwString);

  return retVal;
}

//----------------------------------------------------------------------------//

BOOL
TabbedTextOutUTF8(
  HDC hdc,
  int nXStart,
  int nYStart,
  LPCSTR lpString,
  int cbString,
  int nTabPositions,
  CONST LPINT lpnTabStopPositions,
  int nTabOrigin)
{
  int sz;
  LPWSTR lpwString;
  BOOL retVal;

  // Correction for null
  int np = (cbString == -1) ? 1 : 0;

  lpwString = ToWide(lpString, cbString, &sz);

  // Do unicode TextOut
  retVal = TabbedTextOutW(hdc, nXStart, nYStart, lpwString, sz - np, nTabPositions, lpnTabStopPositions, nTabOrigin);

  // Free buffer
  free(lpwString);

  return retVal;
}

//----------------------------------------------------------------------------//

int
DrawTextExUTF8(
  HDC hdc,
  LPSTR lpchText,
  int cchText,
  LPRECT lprc,
  UINT dwDTFormat,
  LPDRAWTEXTPARAMS lpDTParams)
{
  int sz;
  LPWSTR lpwchText;
  BOOL retVal;

  // Correction for null
  int np = (cchText == -1) ? 1 : 0;

  lpwchText = ToWide(lpchText, cchText, &sz);

  // Do unicode DrawTextExW
  retVal = DrawTextExW(hdc, lpwchText, sz - np, lprc, dwDTFormat, lpDTParams);

  // Free buffer
  free(lpwchText);

  return retVal;
}

//----------------------------------------------------------------------------//

int __stdcall
EnumFontFamExProc(
  const LOGFONT* lpelfe,
  const TEXTMETRIC* lpntme,
  DWORD FontType,
  LPARAM lParam)
{
  char fStyle[12]; fStyle[0] = '\0';
  if      (lpelfe->lfItalic && lpelfe->lfWeight == 700)	{ sprintf(fStyle, "bold italic"); }
  else if (lpelfe->lfWeight == 700)			{ sprintf(fStyle, "bold"); }
  else if (lpelfe->lfItalic)				{ sprintf(fStyle, "italic"); }

  sv_catpvf((SV*)lParam, "%s\t%d\t%s\t%d\n",
			 lpelfe->lfFaceName,
			 lpelfe->lfCharSet,
			 fStyle,
			 FontType & 0x0FFFFFFF);
  return 1;
}

//----------------------------------------------------------------------------//

#define DI_ERR_SUCCESS	 1
#define DI_ERR_ALLOC	-1
#define DI_ERR_OPENF	-2
#define DI_ERR_OPENPRN	-3
#define DI_ERR_START	-4
#define DI_ERR_WRITE	-5
#define DI_ERR_END	-6
#define DI_ERR_CLOSE	-7

BOOL
printfile(char* printer, char* filename)
{
  HANDLE prnhandle;
  DOC_INFO_1 dci1;
  char* buffer;
  FILE* f;
  DWORD count;
  DWORD written;

  if ((buffer = malloc(4096)) == (char *)NULL) {
    return DI_ERR_ALLOC;
  }
	
  if ((f = fopen(filename, "rb")) == (FILE *)NULL) {
    free(buffer);
    return DI_ERR_OPENF;
  }

  if (!OpenPrinter(printer, &prnhandle, NULL)) {
    free(buffer);
    fclose(f);
    return DI_ERR_OPENPRN;
  }

  dci1.pDocName = filename;
  dci1.pOutputFile = NULL;
  dci1.pDatatype = "RAW";

  if (!StartDocPrinter(prnhandle, 1, (LPBYTE)&dci1)) {
    free(buffer);
    fclose(f);
    AbortPrinter(prnhandle);
    return DI_ERR_START;
  }

  while ((count = fread(buffer, 1, 4096, f)) != 0 ) {
    if (!WritePrinter(prnhandle, (LPVOID)buffer, count, &written)) {
      free(buffer);
      fclose(f);
      AbortPrinter(prnhandle);
      return DI_ERR_WRITE;
    }
  }
  free(buffer);
  fclose(f);

  if (!EndDocPrinter(prnhandle)) {
    AbortPrinter(prnhandle);
    return DI_ERR_END;
  }

  if (!ClosePrinter(prnhandle)) {
    return DI_ERR_CLOSE;
  }

  return DI_ERR_SUCCESS;

}

//----------------------------------------------------------------------------//

LONG
exfilt()
{
  return EXCEPTION_EXECUTE_HANDLER;
}

//----------------------------------------------------------------------------//

MODULE = Win32::Printer         PACKAGE = Win32::Printer

PROTOTYPES: DISABLE

#------------------------------------------------------------------------------#

int
_IsNo(pv)
  const char* pv;
  CODE:
    RETVAL = grok_number(pv, strlen(pv), NULL);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

LPSTR
_GetLastError()
  PREINIT:
    char msg[255];
  CODE:
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(), 0, msg, 255, NULL);
    RETVAL = msg;
  OUTPUT:
    RETVAL

unsigned int
_Get3PLibs()
  CODE:
    RETVAL  = 0x00000000;
#ifdef FREE
    RETVAL |= 0x00000001;
#endif
#ifdef GHOST
    RETVAL |= 0x00000002;
#endif
#ifdef EBBL
    RETVAL |= 0x00000004;
#endif
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HDC
_CreatePrinter(printer, dialog, Flags, copies, collate, minp, maxp, orient, papersize, duplex, source, color, height, width)
    LPSTR printer;
    BOOL dialog;
    int Flags;
    int copies;
    int collate;
    int minp;
    int maxp;
    int orient;
    int papersize;
    int duplex;
    int source;
    int color;
    int height;
    int width;
  PREINIT:
    DWORD error;
    PRINTDLG *lppd;
    DEVMODE *lpdm;
    DEVNAMES *lpdn;
    LPSTR pPrinterName;
    int printlen;
    HGLOBAL newDevNames;
    LPSTR dnch;
    LPSTR winspool = "winspool";
  CODE:
    RETVAL = (HDC) NULL;
    Newz(0, lppd, 1, PRINTDLG);
    lppd->lStructSize = sizeof(PRINTDLG);
    lppd->Flags = PD_RETURNDEFAULT;
    if (PrintDlg(lppd)) {
      lpdm = GlobalLock(lppd->hDevMode);
      if (height > 0 && width > 0) {
        lpdm->dmFields |= DM_PAPERLENGTH;
        lpdm->dmFields |= DM_PAPERWIDTH;
        lpdm->dmPaperLength = height;
        lpdm->dmPaperWidth = width;
      } else {
        lpdm->dmFields |= DM_PAPERSIZE;
        lpdm->dmPaperSize = papersize;
      }
      if (orient == 1 || orient == 2) {
        lpdm->dmFields |= DM_ORIENTATION;
        lpdm->dmOrientation = orient;
      }
      if (duplex == 1 || duplex == 2 || duplex == 3) {
        lpdm->dmFields |= DM_DUPLEX;
        lpdm->dmDuplex = duplex;
      }
      lpdm->dmFields |= DM_COPIES | DM_COLLATE | DM_DEFAULTSOURCE | DM_COLOR;
      lpdm->dmCopies = copies;
      lpdm->dmCollate = collate;
      lpdm->dmDefaultSource = source;
      lpdm->dmColor = color;
      if (dialog == 0) {
        lpdn = GlobalLock(lppd->hDevNames);
        if (strlen(printer) != 0) {
          RETVAL = CreateDC("winspool", printer, NULL, lpdm);
        } else {
          New(0, pPrinterName, lpdn->wOutputOffset - lpdn->wDeviceOffset, char);
          Copy((LPSTR )lpdn + lpdn->wDeviceOffset, pPrinterName, lpdn->wOutputOffset - lpdn->wDeviceOffset, char);
          RETVAL = CreateDC("winspool", pPrinterName, NULL, lpdm);
          Safefree(pPrinterName);
        }
      } else {
        lppd->nFromPage = minp;
        lppd->nToPage = maxp;
        lppd->nMinPage = minp;
        lppd->nMaxPage = maxp;
        printlen = strlen(printer) < 32 ? (strlen(printer) + 1) : 32;
        newDevNames = GlobalAlloc(GMEM_MOVEABLE, 17 + printlen);
        dnch = GlobalLock(newDevNames);
        Copy(winspool, dnch + 8, 9, char);
        Copy(printer, dnch + 17, printlen, char);
        dnch[17 + printlen] = '\0';
        lpdn = (DEVNAMES *)dnch;
        lpdn->wDriverOffset = 8;
        lpdn->wDeviceOffset = 17;
        lpdn->wOutputOffset = 17 + printlen;
        lpdn->wDefault = 1;
        lppd->hDevNames = newDevNames;
        Copy(printer, lpdm->dmDeviceName, printlen, char);
        lppd->Flags = PD_RETURNDC | Flags;
        if (PrintDlg(lppd)) {
          RETVAL = lppd->hDC;
          Flags = lppd->Flags;
          copies = lpdm->dmCopies;
          collate = lpdm->dmCollate;
          minp = lppd->nFromPage;
          maxp = lppd->nToPage;
        }
      }
      error = GetLastError();
      GlobalUnlock(lppd->hDevNames);
      GlobalUnlock(lppd->hDevMode);
    }
    Safefree(lppd);
    if (RETVAL) {
      SetGraphicsMode(RETVAL, GM_ADVANCED);
    } else {
      if (dialog == 0) {
        SetLastError(error);
      } else {
        if (CommDlgExtendedError()) {
          croak("Print dialog error!\n");
        } else {
          SetLastError(ERROR_CANCELLED);
        }
      }
    }
  OUTPUT:
    Flags
    copies
    collate
    minp
    maxp
    RETVAL

#------------------------------------------------------------------------------#

LPCSTR
_SaveAs(index, suggest, indir)
    int index;
    LPSTR suggest;
    LPCSTR indir;
  PREINIT:
    OPENFILENAME ofn;
    char file[MAX_PATH];
  CODE:
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = "Print files (*.prn, *.ps, *.pcl, *.afp)\0*.prn;*.ps;*.pcl;*.afp\0PDF files (*.pdf)\0*.pdf\0Enhenced Metafiles (*.emf)\0*.emf\0All files (*.*)\0*.*\0";
    ofn.lpstrCustomFilter = NULL;
    ofn.nFilterIndex = index;
    strcpy(file, suggest);
    ofn.lpstrFile = file;
    ofn.nMaxFile = MAX_PATH;
    ofn.lpstrFileTitle = NULL;
    if (indir[0] == '\0') {
      ofn.lpstrInitialDir = PerlEnv_get_childdir();
    } else {
      ofn.lpstrInitialDir = indir;
    }
    ofn.lpstrTitle = "Win32::Printer - Save As";
    ofn.Flags = OFN_NOCHANGEDIR | OFN_EXPLORER | OFN_PATHMUSTEXIST;
    if (index == 3) {
      ofn.Flags |= OFN_OVERWRITEPROMPT;
    }
    if (GetSaveFileName(&ofn)) {
      RETVAL = ofn.lpstrFile;
    } else {
      if (CommDlgExtendedError()) {
        croak("Save As dialog error!\n");
      } else {
        SetLastError(ERROR_CANCELLED);
      }
      RETVAL = "";
    }
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

LPCSTR
_Open(index, multi)
    int index;
    int multi;
  PREINIT:
    OPENFILENAME ofn;
    char file[MAX_PATH];
  CODE:
    int x = 0;
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = "Print files (*.prn, *.ps, *.pcl, *.afp)\0*.prn;*.ps;*.pcl;*.afp\0PDF files (*.pdf)\0*.pdf\0Enhenced Metafiles (*.emf)\0*.emf\0All files (*.*)\0*.*\0";
    ofn.lpstrCustomFilter = NULL;
    ofn.nFilterIndex = index;
    file[0] = '\0';
    ofn.lpstrFile = file;
    ofn.nMaxFile = 65535;
    ofn.lpstrFileTitle = NULL;
    ofn.lpstrInitialDir = NULL;
    ofn.lpstrTitle = "Win32::Printer - Open";
    ofn.Flags = OFN_NOCHANGEDIR | OFN_EXPLORER | OFN_HIDEREADONLY;
    if (multi == 1) {
      ofn.Flags |= OFN_ALLOWMULTISELECT;
    }
    if (GetOpenFileName(&ofn)) {
      if (multi == 1) {
        while (1) {
          if ((ofn.lpstrFile[x] == '\0') && (ofn.lpstrFile[x + 1] != '\0')) {
            ofn.lpstrFile[x] = 42;
          } else if ((ofn.lpstrFile[x] == '\0') && (ofn.lpstrFile[x + 1] == '\0')) {
            break;
          }
          x++;
        }
      }
      RETVAL = ofn.lpstrFile;
    } else {
      if (CommDlgExtendedError()) {
        croak("Open dialog error!\n");
      } else {
        SetLastError(ERROR_CANCELLED);
      }
      RETVAL = "";
    }
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_DeleteDC(hdc)
    HDC hdc;
  CODE:
    RETVAL = DeleteDC(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_StartDoc(hdc, DocName, FileName)
    HDC hdc;
    LPCSTR DocName;
    LPCSTR FileName;
  PREINIT:
    DOCINFO di;
  CODE:
    di.cbSize = sizeof(DOCINFO);
    di.lpszDocName = DocName;
    di.lpszOutput = FileName;
    di.lpszDatatype = NULL;
    di.fwType = 0;
    RETVAL = StartDoc(hdc, &di);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_EndDoc(hdc)
    HDC hdc;
  CODE:
    RETVAL = EndDoc(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_AbortDoc(hdc)
    HDC hdc;
  CODE:
    RETVAL = AbortDoc(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int 
_StartPage(hdc)
    HDC hdc;
  CODE:
    RETVAL = StartPage(hdc);
    SetBkMode(hdc, TRANSPARENT);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_EndPage(hdc)
    HDC hdc;
  CODE:
    RETVAL = EndPage(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HGDIOBJ 
_SelectObject(hdc, hgdiobj)
    HDC hdc;
    HGDIOBJ hgdiobj;
  CODE:
    RETVAL = SelectObject(hdc, hgdiobj);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HGDIOBJ 
_CopyObject(hdc1, hdc2, ot)
    HDC hdc1;
    HDC hdc2;
    UINT ot;
  CODE:
    RETVAL = SelectObject(hdc2, GetCurrentObject(hdc1, ot));
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#
BOOL
_DeleteObject(hObject);
    HGDIOBJ hObject;
  CODE:
    RETVAL = DeleteObject(hObject);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_GetDeviceCaps(hdc, nIndex)
    HDC hdc;
    int nIndex;
  CODE:
    RETVAL = GetDeviceCaps(hdc, nIndex);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_SetWorldTransform(hdc, eM11, eM12, eM21, eM22, eDx, eDy)
    HDC hdc;
    FLOAT eM11;
    FLOAT eM12;
    FLOAT eM21;
    FLOAT eM22;
    FLOAT eDx;
    FLOAT eDy;
  PREINIT:
    XFORM Xform;
  CODE:
    Xform.eM11 = eM11;
    Xform.eM12 = eM12;
    Xform.eM21 = eM21;
    Xform.eM22 = eM22;
    Xform.eDx = eDx;
    Xform.eDy = eDy;
    RETVAL = SetWorldTransform(hdc, &Xform);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_IsNT()
  CODE:
    OSVERSIONINFO osi;
    osi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
    GetVersionEx(&osi);
    if (osi.dwPlatformId == VER_PLATFORM_WIN32_NT) {
      RETVAL = 1;
    } else {
      RETVAL = 0;
    }
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HFONT
_CreateFont(Height, Escapement, Orientation, Weight, Italic, Underline, StrikeOut, CharSet, FaceName)
    long Height;
    long Escapement;
    long Orientation;
    long Weight;
    BYTE Italic;
    BYTE Underline;
    BYTE StrikeOut;
    BYTE CharSet;
    LPCSTR FaceName;
  CODE:
    LOGFONT lf;
    int len = strlen(FaceName);
    lf.lfHeight = -Height;
    lf.lfWidth = 0;
    lf.lfEscapement = Escapement;
    lf.lfOrientation = Orientation;
    lf.lfWeight = Weight;
    lf.lfItalic = Italic;
    lf.lfUnderline = Underline;
    lf.lfStrikeOut = StrikeOut;
    lf.lfCharSet = CharSet;
    lf.lfOutPrecision = OUT_DEFAULT_PRECIS;
    lf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
    lf.lfQuality = PROOF_QUALITY;
    lf.lfPitchAndFamily = DEFAULT_PITCH;
    if (len > 31) {
      memcpy(lf.lfFaceName, FaceName, 32);
    } else {
      memcpy(lf.lfFaceName, FaceName, len + 1);
    }
    RETVAL = CreateFontIndirect(&lf);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_GetTextFace(hdc)
    HDC hdc;
  CODE:
    char face[32];
    RETVAL = newSVpvn("", 0);
    GetTextFace(hdc, 32, face);
    sv_catpv(RETVAL, face);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_GetTextExtentPoint(vers, hdc, lpszStr, nMaxExtent, nFit, cx, cy)
    int vers;
    HDC hdc;
    LPCSTR lpszStr;
    int nMaxExtent;
    int nFit;
    LONG cx;
    LONG cy;
  PREINIT:
    SIZE Size;
  CODE:
    switch (vers) {
      case 1:
        RETVAL = GetTextExtentExPointUTF8(hdc, lpszStr, strlen(lpszStr), nMaxExtent, &nFit, NULL, &Size);
        break;
      default:
        RETVAL = GetTextExtentExPoint(hdc, lpszStr, strlen(lpszStr), nMaxExtent, &nFit, NULL, &Size);
    }
    cx = Size.cx;
    cy = Size.cy;
  OUTPUT:
    nFit
    cx
    cy
    RETVAL

#------------------------------------------------------------------------------#

LONG 
_TextOut(vers, hdc, nXStart, nYStart, lpString, align)
    int vers;
    HDC hdc;
    int nXStart;
    int nYStart;
    LPCSTR lpString;
    int align;
  CODE:
    SetTextAlign(hdc, align);
    switch (vers) {
      case 1:
        RETVAL = TabbedTextOutUTF8(hdc, nXStart, nYStart, lpString, strlen(lpString), 0, NULL, nXStart);
        break;
      default:
        RETVAL = TabbedTextOut(hdc, nXStart, nYStart, lpString, strlen(lpString), 0, NULL, nXStart);
    }
    SetTextAlign(hdc, TA_LEFT);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_DrawText(vers, hdc, lpString, x1, y1, x2, y2, uFormat, uiLengthDrawn, tabStop)
    int vers;
    HDC hdc;
    LPSTR lpString;
    LONG x1;
    LONG y1;
    LONG x2;
    LONG y2;
    UINT uFormat;
    UINT uiLengthDrawn;
    UINT tabStop;
  PREINIT:
    RECT Rect;
    DRAWTEXTPARAMS DTParams;
  CODE:
    Rect.left = x1;
    Rect.top = y1;
    Rect.right = x2;
    Rect.bottom = y2;
    DTParams.cbSize = sizeof(DRAWTEXTPARAMS);
    DTParams.iTabLength = tabStop;
    DTParams.iLeftMargin = 0;
    DTParams.iRightMargin = 0;
    switch (vers) {
      case 1:
        RETVAL = DrawTextExUTF8(hdc, lpString, -1, &Rect, uFormat | DT_TABSTOP | DT_NOPREFIX, &DTParams);
        break;
      default:
        RETVAL = DrawTextEx(hdc, lpString, -1, &Rect, uFormat | DT_TABSTOP | DT_NOPREFIX, &DTParams);
    }
    x2 = Rect.right;
    y2 = Rect.bottom;
    uiLengthDrawn = DTParams.uiLengthDrawn;
  OUTPUT:
    x2
    uiLengthDrawn
    lpString
    RETVAL

#------------------------------------------------------------------------------#

COLORREF
_SetTextColor(hdc, coloRef)
    HDC hdc;
    int coloRef;
  CODE:
    RETVAL = SetTextColor(hdc, coloRef);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

COLORREF
_CopyTextColor(hdc1, hdc2)
    HDC hdc1;
    HDC hdc2;
  CODE:
    RETVAL = SetTextColor(hdc2, GetTextColor(hdc1));
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_SetTextCharacterExtra(hdc, nCharExtra)
    HDC hdc;
    int nCharExtra;
  CODE:
    RETVAL = SetTextCharacterExtra(hdc, nCharExtra);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_SetJustify(vers, hdc, string, width)
    int vers;
    HDC hdc;
    LPCSTR string;
    int width;
  PREINIT:
    SIZE size;
    TEXTMETRIC tm;
    BOOL gtep = FALSE;
    int spaces = 0;
    int len = 0;
    LPCSTR str = string;
  CODE:
    if (width > -1) {
      GetTextMetrics(hdc, &tm);
      while (*str != '\0') {
        if (*str == tm.tmBreakChar) {
          spaces++;
        }
        str++;
        len++;
      }
      switch (vers) {
        case 1:
          gtep = GetTextExtentPoint32UTF8(hdc, string, len, &size);
          break;
        default:
          gtep = GetTextExtentPoint32(hdc, string, len, &size);
      }
      if (gtep) {
        RETVAL = SetTextJustification(hdc, width - size.cx, spaces);
      } else {
        RETVAL = FALSE;
      }
    } else {
      RETVAL = SetTextJustification(hdc, 0, 0);
    }
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HPEN
_CreatePen(fnPenStyle, nWidth, cRed, cGreen, cBlue)
    int fnPenStyle;
    int nWidth;
    BYTE cRed;
    BYTE cGreen;
    BYTE cBlue;
  PREINIT:
    LOGBRUSH lb;
  CODE:
    lb.lbStyle = BS_SOLID;
    lb.lbColor = RGB(cRed, cGreen, cBlue);
    lb.lbHatch = NULL;
    RETVAL = ExtCreatePen(fnPenStyle, nWidth, &lb, 0, NULL);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_MoveTo(hdc, X, Y)
    HDC hdc;
    int X;
    int Y;
  PREINIT:
    POINT Point;
  CODE:
    RETVAL = MoveToEx(hdc, X, Y, &Point);
    X = Point.x;
    Y = Point.y;
  OUTPUT:
    X
    Y
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Polyline(hdc, ...)
    HDC hdc;
  PREINIT:
    POINT *lpPoints;
    int i, j;
  CODE:
    New(0, lpPoints, items, POINT);
    i = 1; j = 0;
    while (i < items) {
      lpPoints[j].x = SvIV(ST(i));
      i++;
      lpPoints[j].y = SvIV(ST(i));
      i++; j++;
    }
    RETVAL = Polyline(hdc, lpPoints, (items-1) / 2);
    Safefree(lpPoints);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_PolylineTo(hdc, ...)
    HDC hdc;
  PREINIT:
    POINT *lpPoints;
    int i, j;
  CODE:
    New(0, lpPoints, items, POINT);
    i = 1; j = 0;
    while (i < items) {
      lpPoints[j].x = SvIV(ST(i));
      i++;
      lpPoints[j].y = SvIV(ST(i));
      i++; j++;
    }
    RETVAL = PolylineTo(hdc, lpPoints, (items - 1) / 2);
    Safefree(lpPoints);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HBRUSH 
_CreateBrushIndirect(lbStyle, lbHatch, cRed, cGreen, cBlue)
    UINT lbStyle;
    LONG lbHatch;
    BYTE cRed;
    BYTE cGreen;
    BYTE cBlue;
  PREINIT:
    LOGBRUSH lb;
  CODE:
    lb.lbStyle = lbStyle;
    lb.lbColor = RGB(cRed, cGreen, cBlue);
    lb.lbHatch = lbHatch;
    RETVAL = CreateBrushIndirect(&lb);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_SetPolyFillMode(hdc, iPolyFillMode)
    HDC hdc;
    int iPolyFillMode;
  CODE:
    RETVAL = SetPolyFillMode(hdc, iPolyFillMode);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Rectangle(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
  CODE:
    RETVAL = Rectangle(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_RoundRect(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nWidth, nHeight)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
    int nWidth;
    int nHeight;
  CODE:
    RETVAL = RoundRect(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nWidth, nHeight);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Ellipse(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
  CODE:
    RETVAL = Ellipse(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Chord(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
    int nXRadial1;
    int nYRadial1;
    int nXRadial2;
    int nYRadial2;
  CODE:
    RETVAL = Chord(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Pie(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
    int nXRadial1;
    int nYRadial1;
    int nXRadial2;
    int nYRadial2;
  CODE:
    RETVAL = Pie(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Polygon(hdc, ...)
    HDC hdc;
  PREINIT:
    POINT *Points;
    int i, j;
  CODE:
    New(0, Points, items, POINT);
    i = 1; j = 0;
    while (i < items) {
      Points[j].x = SvIV(ST(i));
      i++;
      Points[j].y = SvIV(ST(i));
      i++; j++;
    }
    RETVAL = Polygon(hdc, Points, (items-1) / 2);
    Safefree(Points);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_PolyBezier(hdc, ...)
    HDC hdc;
  PREINIT:
    POINT *Points;
    int i, j;
  CODE:
    New(0, Points, items, POINT);
    i = 1; j = 0;
    while (i < items) {
      Points[j].x = SvIV(ST(i));
      i++;
      Points[j].y = SvIV(ST(i));
      i++; j++;
    }
    RETVAL = PolyBezier(hdc, Points, (items-1) / 2);
    Safefree(Points);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_PolyBezierTo(hdc, ...)
    HDC hdc;
  PREINIT:
    POINT *Points;
    int i, j;
  CODE:
    New(0, Points, items, POINT);
    i = 1; j = 0;
    while (i < items) {
      Points[j].x = SvIV(ST(i));
      i++;
      Points[j].y = SvIV(ST(i));
      i++; j++;
    }
    RETVAL = PolyBezierTo(hdc, Points, (items-1) / 2);
    Safefree(Points);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_Arc(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
    int nXRadial1;
    int nYRadial1;
    int nXRadial2;
    int nYRadial2;
  CODE:
    RETVAL = Arc(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_ArcTo(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2)
    HDC hdc;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
    int nXRadial1;
    int nYRadial1;
    int nXRadial2;
    int nYRadial2;
  CODE:
    RETVAL = ArcTo(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nXRadial1, nYRadial1, nXRadial2, nYRadial2);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_BeginPath(hdc)
    HDC hdc;
  CODE:
    RETVAL = BeginPath(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_EndPath(hdc)
    HDC hdc;
  CODE:
    RETVAL = EndPath(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_AbortPath(hdc)
    HDC hdc;
  CODE:
    RETVAL = AbortPath(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_StrokeAndFillPath(hdc)
    HDC hdc;
  CODE:
    RETVAL = StrokeAndFillPath(hdc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_SelectClipPath(hdc, iMode)
    HDC hdc;
    int iMode;
  CODE:
    RETVAL = SelectClipPath(hdc, iMode);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_DeleteClipPath(hdc)
    HDC hdc;
  CODE:
    RETVAL = SelectClipRgn(hdc, NULL);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HENHMETAFILE
_GetWinMetaFile(hdc, lpszMetaFile)
    HDC hdc;
    LPCSTR lpszMetaFile;
  PREINIT:
    typedef struct {
       DWORD     key;
       WORD      hmf;
       _int16    left;
       _int16    top;
       _int16    right;
       _int16    bottom;
       WORD      inch;
       DWORD     reserved;
       WORD      checksum;
    } METAFILE_HEADER, *PMETAFILE_HEADER;
    HMETAFILE hmf;
    HENHMETAFILE hemf = NULL;
    LPVOID mfb;
    BYTE *Data;
    PerlIO *file;
    METAFILEPICT mfp;
    METAFILE_HEADER MfHdr;
    UINT nSize;
    LPCSTR lpPathName = PerlEnv_get_childdir();
  CODE:
    SetCurrentDirectory(lpPathName);
    hmf = GetMetaFile(lpszMetaFile);
    mfp.mm = MM_ANISOTROPIC;
    mfp.xExt = -1;
    mfp.yExt = -1;
    mfp.hMF  = NULL;
    if (hmf == NULL) {
      file = PerlIO_open(lpszMetaFile, "rb");
      if (file != NULL) {
        PerlIO_read(file, &MfHdr, sizeof(METAFILE_HEADER));
        mfp.xExt = (long)((MfHdr.right - MfHdr.left) * 2540.9836 / MfHdr.inch);
        mfp.yExt = (long)((MfHdr.bottom - MfHdr.top) * 2540.9836 / MfHdr.inch);
        PerlIO_seek(file, 0, SEEK_END);
        nSize = (UINT) PerlIO_tell(file) - 22;
        New(0, Data, nSize, BYTE);
        PerlIO_seek(file, 22, 0);
        PerlIO_read(file, Data, nSize);
        hmf = SetMetaFileBitsEx(nSize, Data);
        Safefree(Data);
        PerlIO_close(file);
      }
    }
    if (hmf != NULL) {
      nSize = GetMetaFileBitsEx(hmf, NULL, NULL);
      New(0, mfb, nSize, LPVOID);
      nSize = GetMetaFileBitsEx(hmf, nSize, mfb);
      hemf = SetWinMetaFileBits(nSize, mfb, hdc, &mfp);
      Safefree(mfb);
    }
    RETVAL = hemf;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_EBbl(hdc, emf, string, x, y, flags, baw, bah)
      HDC hdc;
      HENHMETAFILE emf;
      LPSTR string;
      int x;
      int y;
      unsigned flags;
      int baw;
      int bah;
    PREINIT:
#ifdef EBBL
      ebc_t ebc;
      HPEN pen;
      HPEN prepen;
      HFONT font;
      HBRUSH brush;
#endif
    CODE:
      RETVAL = NULL;
#ifdef EBBL
      ebc.flags = flags;
      ebc.baw = baw;
      ebc.bah = bah;
      __try {
         if (emf) {
           brush = GetCurrentObject(hdc, OBJ_BRUSH);
           font = GetCurrentObject(hdc, OBJ_FONT);
           hdc = CreateEnhMetaFile(hdc, NULL, NULL, NULL);
           SelectObject(hdc, brush);
           SelectObject(hdc, font);
           SetBkMode(hdc, TRANSPARENT);
         }
         pen = CreatePen(PS_NULL, 1, 0xFFFFFFFF);
         prepen = SelectObject(hdc, pen);
         ebc.hdc = hdc;
         RETVAL = EBbl(&ebc, string, x, y);
         SelectObject(hdc, prepen);
         DeleteObject(pen);
         if (emf) {
           emf = CloseEnhMetaFile(hdc);
         }
      }
      __except (exfilt()) {
         RETVAL = 64;
      }
#else
      croak("EBbl is not supported in this build!\n");
#endif
    OUTPUT:
      emf
      RETVAL

#------------------------------------------------------------------------------#

HENHMETAFILE
_GetEnhMetaFile(lpszMetaFile)
    LPCSTR lpszMetaFile;
  PREINIT:
    HENHMETAFILE hemf;
    LPSTR dir = PerlEnv_get_childdir();
  CODE:
    SetCurrentDirectory(dir);
    hemf = GetEnhMetaFile(lpszMetaFile);
    RETVAL = hemf;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HENHMETAFILE
_LoadBitmap(hdc, BmpFile, Type, du);
    HDC hdc;
    LPCSTR BmpFile;
    int Type;
    int du;
  PREINIT:
#ifdef FREE
    LPSTR dir = PerlEnv_get_childdir();
    FIBITMAP *Image;
    BITMAPINFO *lpbmi;
    double resolutionX = 72;
    double resolutionY = 72;
#endif
  CODE:
    RETVAL = NULL;
#ifdef FREE
    SetCurrentDirectory(dir);
    __try {
      if (Type == FIF_UNKNOWN) {
        Type = FreeImage_GetFIFFromFilename(BmpFile);
        if (Type == FIF_UNKNOWN) {
          Type = FreeImage_GetFileType(BmpFile, 16);
        }
      }
      if ((Type != FIF_UNKNOWN) && FreeImage_FIFSupportsReading(Type)) {
        Image = FreeImage_Load(Type, BmpFile, 0);
        if (Image) {
          lpbmi = (BITMAPINFO *) FreeImage_GetInfo(Image);
          hdc = CreateEnhMetaFile(hdc, NULL, NULL, NULL);
          if (du) {
            if (lpbmi->bmiHeader.biXPelsPerMeter && lpbmi->bmiHeader.biYPelsPerMeter) {
              resolutionX = lpbmi->bmiHeader.biXPelsPerMeter / 39.35483881;
              resolutionY = lpbmi->bmiHeader.biYPelsPerMeter / 39.35483881;
            }
            StretchDIBits(hdc, 0, 0, (int)(GetDeviceCaps(hdc, LOGPIXELSX) * lpbmi->bmiHeader.biWidth / resolutionX), (int)(GetDeviceCaps(hdc, LOGPIXELSY) * lpbmi->bmiHeader.biHeight / resolutionY), 0, 0, lpbmi->bmiHeader.biWidth, lpbmi->bmiHeader.biHeight, (CONST VOID *) FreeImage_GetBits(Image), lpbmi, DIB_RGB_COLORS, SRCCOPY);
          } else {
            StretchDIBits(hdc, 0, 0, lpbmi->bmiHeader.biWidth, lpbmi->bmiHeader.biHeight, 0, 0, lpbmi->bmiHeader.biWidth, lpbmi->bmiHeader.biHeight, (CONST VOID *) FreeImage_GetBits(Image), lpbmi, DIB_RGB_COLORS, SRCCOPY);
          }
          RETVAL = CloseEnhMetaFile(hdc);
          FreeImage_Unload(Image);
        } else {
          if (!GetLastError()) {
            SetLastError(ERROR_INVALID_DATA);
          }
        }
      } else {
        Image = 0;
      }
    }
    __except (exfilt()) {
      Image = 0;
    }
#else
    croak("FreeImage is not supported in this build!\n");
#endif
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

BOOL
_PlayEnhMetaFile(hdc, hemf, nLeftRect, nTopRect, nRightRect, nBottomRect)
    HDC hdc;
    HENHMETAFILE hemf;
    int nLeftRect;
    int nTopRect;
    int nRightRect;
    int nBottomRect;
  PREINIT:
    RECT Rect;
  CODE:
    Rect.left = nLeftRect;
    Rect.top = nTopRect;
    Rect.right = nRightRect;
    Rect.bottom = nBottomRect;
    RETVAL = PlayEnhMetaFile(hdc, hemf, &Rect);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

UINT
_GetEnhSize(hdc, hemf, right, bottom, du)
    HDC hdc;
    HENHMETAFILE hemf;
    double right;
    double bottom;
    int du;
  PREINIT:
    ENHMETAHEADER emh;
  CODE:
    RETVAL = GetEnhMetaFileHeader(hemf, sizeof(ENHMETAHEADER), &emh);
    if (du) {
      right = (emh.rclFrame.right - emh.rclFrame.left) * GetDeviceCaps(hdc, LOGPIXELSX) / 2540.9836;
      bottom = (emh.rclFrame.bottom - emh.rclFrame.top) * GetDeviceCaps(hdc, LOGPIXELSY) / 2540.9836;
    } else {
      right = (emh.rclBounds.right - emh.rclBounds.left);
      bottom = (emh.rclBounds.bottom - emh.rclBounds.top);
    }
  OUTPUT:
    right
    bottom

#------------------------------------------------------------------------------#

BOOL
_DeleteEnhMetaFile(hemf)
    HENHMETAFILE hemf;
  CODE:
    RETVAL = DeleteEnhMetaFile(hemf);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumPrinters(Flags, Server)
    int Flags;
    LPSTR Server;
  PREINIT:
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    PRINTER_INFO_2 *pri2;
    unsigned int i;
  CODE:
    SV* retval = newSVpvn("", 0);
    EnumPrinters(Flags, Server, 2, NULL, 0, &needed, &returned);
    New(0, buffer, needed, BYTE);
    rc = EnumPrinters(Flags, Server, 2, buffer, needed, &needed, &returned);
    pri2 = (PRINTER_INFO_2 *) buffer;
    if ((rc) && (returned)) {
      for (i = 0; i < returned; i++) {
           sv_catpvf(retval, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t\n",
           pri2[i].pServerName,
           pri2[i].pPrinterName,
           pri2[i].pShareName,
           pri2[i].pPortName,
           pri2[i].pDriverName,
           pri2[i].pComment,
           pri2[i].pLocation,
           pri2[i].pSepFile,
           pri2[i].pPrintProcessor,
           pri2[i].pDatatype,
           pri2[i].pParameters,
           pri2[i].Attributes,
           pri2[i].Priority,
           pri2[i].DefaultPriority,
           pri2[i].StartTime,
           pri2[i].UntilTime,
           pri2[i].Status,
           pri2[i].cJobs,
           pri2[i].AveragePPM
          );
      }
    }
    Safefree(buffer);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumPrinterDrivers(Server, Env)
    LPSTR Server;
    LPSTR Env;
  PREINIT:
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    DRIVER_INFO_3 *dri3;
    unsigned int i;
    unsigned int x = 0;
  CODE:
    SV* retval = newSVpvn("", 0);
    EnumPrinterDrivers(Server, Env, 3, NULL, 0, &needed, &returned);
    New(0, buffer, needed, BYTE);
    rc = EnumPrinterDrivers(Server, Env, 3, buffer, needed, &needed, &returned);
    dri3 = (DRIVER_INFO_3 *) buffer;
    if ((rc) && (returned)) {
      for (i = 0; i < returned; i++) {
        if (dri3[i].pDependentFiles != NULL) {
          while (1) {
            if ((dri3[i].pDependentFiles[x] == '\0') && (dri3[i].pDependentFiles[x + 1] != '\0')) {
              dri3[i].pDependentFiles[x] = 42;
            } else if ((dri3[i].pDependentFiles[x] == '\0') && (dri3[i].pDependentFiles[x + 1] == '\0')) {
              break;
            }
            x++;
          }
        }
        sv_catpvf(retval, "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                  dri3[i].cVersion,
                  dri3[i].pName,
                  dri3[i].pEnvironment,
                  dri3[i].pDriverPath,
                  dri3[i].pDataFile,
                  dri3[i].pConfigFile,
                  dri3[i].pHelpFile, 
                  dri3[i].pDependentFiles,
                  dri3[i].pMonitorName,
                  dri3[i].pDefaultDataType
                 );
      }
    }
    Safefree(buffer);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumPorts(Server)
    LPSTR Server;
  PREINIT:
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    PORT_INFO_2 *pi2;
    unsigned int i;
  CODE:
    SV* retval = newSVpvn("", 0);
    EnumPorts(Server, 2, NULL, 0, &needed, &returned);
    New(0, buffer, needed, BYTE);
    rc = EnumPorts(Server, 2, buffer, needed, &needed, &returned);
    pi2 = (PORT_INFO_2 *) buffer;
    if ((rc) && (returned)) {
      for (i = 0; i < returned; i++) {
        sv_catpvf(retval, "%s\t%s\t%s\t%d\n", 
                  pi2[i].pPortName,
                  pi2[i].pMonitorName,
                  pi2[i].pDescription,
                  pi2[i].fPortType
                 );
      }
    }
    Safefree(buffer);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumMonitors(Server)
    LPSTR Server;
  PREINIT:
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    MONITOR_INFO_2 *mi2;
    unsigned int i;
  CODE:
    SV* retval = newSVpvn("", 0);
    EnumMonitors(Server, 2, NULL, 0, &needed, &returned);
    New(0, buffer, needed, BYTE);
    rc = EnumMonitors(Server, 2, buffer, needed, &needed, &returned);
    mi2 = (MONITOR_INFO_2 *) buffer;
    if ((rc) && (returned)) {
      for (i = 0; i < returned; i++) {
        sv_catpvf(retval, "%s\t%s\t%s\n",
                  mi2[i].pName,
                  mi2[i].pEnvironment,
                  mi2[i].pDLLName
                 );
      }
    }
    Safefree(buffer);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumPrintProcessors(Server, Env)
    LPSTR Server;
    LPSTR Env;
  PREINIT:
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    PRINTPROCESSOR_INFO_1 *ppi1;
    unsigned int i;
  CODE:
    SV* retval = newSVpvn("", 0);
    EnumPrintProcessors(Server, Env, 1, NULL, 0, &needed, &returned);
    New(0, buffer, needed, BYTE);
    rc = EnumPrintProcessors(Server, Env, 1, buffer, needed, &needed, &returned);
    ppi1 = (PRINTPROCESSOR_INFO_1 *)buffer;
    if ((rc) && (returned)) {
      for (i = 0; i < returned; i++) {
        sv_catpvf(retval, "%s\n", ppi1[i].pName);
      }
    }
    Safefree(buffer);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumPrintProcessorDatatypes(Server, Processor)
    LPSTR Server;
    LPSTR Processor;
  PREINIT:
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    DATATYPES_INFO_1 *dti1;
    unsigned int i;
  CODE:
    SV* retval = newSVpvn("", 0);
    EnumPrintProcessorDatatypes(Server, Processor, 1, NULL, 0, &needed, &returned);
    New(0, buffer, needed, BYTE);
    rc = EnumPrintProcessorDatatypes(Server, Processor, 1, buffer, needed, &needed, &returned);
    dti1 = (DATATYPES_INFO_1 *)buffer;
    if ((rc) && (returned)) {
      for (i = 0; i < returned; i++) {
        sv_catpvf(retval, "%s\n", dti1[i].pName);
      }
    }
    Safefree(buffer);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_EnumJobs(EnPrinter, begin, end)
    LPSTR EnPrinter;
    int begin;
    int end;
  PREINIT:
    HANDLE hPrinter;
    int rc;
    LPBYTE buffer;
    DWORD needed, returned;
    JOB_INFO_2 *ji2;
    unsigned int i;
  CODE:
    SV* retval = newSVpvn("", 0);
    if (OpenPrinter(EnPrinter, &hPrinter, NULL)) {
      EnumJobs(hPrinter, begin, end, 2, NULL, 0, &needed, &returned);
      New(0, buffer, needed, BYTE);
      rc = EnumJobs(hPrinter, begin, end, 2, buffer, needed, &needed, &returned);
      ji2 = (JOB_INFO_2 *)buffer;
      if ((rc) && (returned)) {
        for (i = 0; i < returned; i++) {
          sv_catpvf(retval, "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
                    ji2[i].JobId,
                    ji2[i].pPrinterName,
                    ji2[i].pMachineName,
                    ji2[i].pUserName,
                    ji2[i].pDocument,
                    ji2[i].pNotifyName,
                    ji2[i].pDatatype,
                    ji2[i].pPrintProcessor,
                    ji2[i].pParameters,
                    ji2[i].pDriverName,
                    ji2[i].pStatus,
                    ji2[i].Status,
                    ji2[i].Priority,
                    ji2[i].Position,
                    ji2[i].StartTime,
                    ji2[i].UntilTime,
                    ji2[i].TotalPages,
                    ji2[i].Size,
                    ji2[i].PagesPrinted
                   );
         }
       }
       Safefree(buffer);
    }
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

SV*
_FontEnum(hdc, FaceName, ChSet)
    HDC hdc;
    LPCSTR FaceName;
    int ChSet;
  PREINIT:
    LOGFONT Logfont;
  CODE:
    SV* retval = newSVpvn("", 0);
    int len = strlen(FaceName);
    if (len > 31) {
      memcpy(Logfont.lfFaceName, FaceName, 32);
    } else {
      memcpy(Logfont.lfFaceName, FaceName, len + 1);
    }
    Logfont.lfCharSet = ChSet;
    Logfont.lfPitchAndFamily = 0;
    EnumFontFamiliesEx(hdc, &Logfont, EnumFontFamExProc, (LPARAM)retval, 0);
    RETVAL = retval;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

LPSTR 
_GetTempPath()
  PREINIT:
    char msg[MAX_PATH];
  CODE:
    GetTempPath(MAX_PATH, msg);
    RETVAL = msg;
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_GhostPDF(ps, pdf)
    LPSTR ps;
    LPSTR pdf;
  PREINIT:
#ifdef GHOST
    void *minst;
    int gsargc = 13;
    char pdfpath[MAX_PATH];
    LPSTR gsargv[] = {	"Printer",
			"-dORIENT1=true",
			"-dDOINTERPOLATE",
			"-sstdout=%stderr",
			"-dNOPAUSE",
			"-dBATCH",
			"-dSAFER",
			"-sDEVICE=pdfwrite",
			pdfpath,
			"-c",
			".setpdfwrite",
			"-f",
			ps };
#endif
  CODE:
    RETVAL = NULL;
#ifdef GHOST
    __try {
      if (gsapi_new_instance(&minst, NULL) == 0) {
        sprintf(pdfpath, "-sOutputFile=%s", pdf);
        if (gsapi_init_with_args(minst, gsargc, (LPSTR *)gsargv) == 0) {
          RETVAL = 1;
          gsapi_exit(minst);
        }
        gsapi_delete_instance(minst);
      }
    }
    __except (exfilt()) { }
#else
    croak("Ghostscript is not supported in this build!\n");
#endif
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HDC
_CreateMeta(hdc, file, right, bottom)
    HDC hdc;
    LPCSTR file;
    LONG right;
    LONG bottom;
  PREINIT:
    RECT rect;
  CODE:
    if (file[0] == '\0') { file = NULL; }
    if (right | bottom) {
      rect.left = 0;
      rect.top = 0;
      rect.right = right;
      rect.bottom = bottom;
      RETVAL = CreateEnhMetaFile(hdc, file, &rect, NULL);
    } else {
      RETVAL = CreateEnhMetaFile(hdc, file, NULL, NULL);
    }
    SetGraphicsMode(RETVAL, GM_ADVANCED);
    SetBkMode(RETVAL, TRANSPARENT);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

HENHMETAFILE
_CloseMeta(edc)
    HDC edc;
  CODE:
    RETVAL = CloseEnhMetaFile(edc);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_Inject(hdc, point, page, data)
    HDC hdc;
    int point;
    int page;
    LPSTR data;
  PREINIT:
    PSINJECTDATA psd;
    char* injdata;
    int len;
  CODE:
    DWORD psc = PSIDENT_PSCENTRIC;
    RETVAL = 0;
    len = strlen(data);
    psd.DataBytes = len;
    psd.InjectionPoint = point;
    psd.PageNumber = page;
    if (New(0, injdata, len + 1 + sizeof(PSINJECTDATA), char)) {
      memcpy(injdata, &psd, sizeof(PSINJECTDATA));
      memcpy(injdata + sizeof(PSINJECTDATA), data, len);
      ExtEscape(hdc, POSTSCRIPT_IDENTIFY, sizeof(DWORD), (LPCSTR)&psc, 0, NULL);
      RETVAL = ExtEscape(hdc, POSTSCRIPT_INJECTION, sizeof(PSINJECTDATA) + len, injdata, 0, NULL);
      Safefree(injdata);
    }
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_EmfH2BMP(hdc, enh, file, width, height, format, flag, bpp)
    HDC hdc;
    HENHMETAFILE enh;
    LPSTR file;
    int width;
    int height;
    int format;
    int flag;
    int bpp;
  PREINIT:
#ifdef FREE
    HDC memDC;
    HBITMAP memBM;
    RECT rect;
    FIBITMAP* fbmp;
    FIBITMAP* fbmp2;
    LOGBRUSH lb;
    HBRUSH brush;
    HBRUSH obrush;
#endif
  CODE:
    RETVAL = 0;
#ifdef FREE
    if (format == FIF_UNKNOWN) {
      format = FreeImage_GetFIFFromFilename(file);
    }
    if (format != FIF_UNKNOWN) {
      if (FreeImage_FIFSupportsExportBPP(format, bpp) && (bpp == 8 || bpp == 24)) {
        if(FreeImage_FIFSupportsWriting(format)) {
          rect.top  = 0; rect.bottom = height;
          rect.left = 0; rect.right  = width;
          if (memDC = CreateCompatibleDC(hdc)) {
            if (memBM = CreateCompatibleBitmap(hdc, width, height)) {
              if (SelectObject(memDC, memBM)) {
                lb.lbStyle = BS_SOLID;
                lb.lbColor = RGB(0xff, 0xff, 0xff);
                brush = CreateBrushIndirect(&lb);
                obrush = SelectObject(memDC, &brush);
                PatBlt(memDC, 0, 0, width, height, PATCOPY);
                DeleteObject(SelectObject(memDC, &obrush));
                if (PlayEnhMetaFile(memDC, enh, &rect)) {
                  if (fbmp = FreeImage_Allocate(width, height, 24, 0, 0, 0)) {
                    if (GetDIBits(memDC, memBM, 0,	FreeImage_GetHeight(fbmp),
							FreeImage_GetBits(fbmp),
							FreeImage_GetInfo(fbmp),
							DIB_RGB_COLORS)) {
                      if (bpp == 8) {
                        if (fbmp2 = FreeImage_ColorQuantize(fbmp, FIQ_WUQUANT)) {
                          FreeImage_Unload(fbmp);
                          fbmp = fbmp2;
                        }
                      }
                      if (FreeImage_Save(format, fbmp, file, flag)) {
                        FreeImage_Unload(fbmp);
                        RETVAL = 1;
                      }
                    }
                  }
                }
              }
              DeleteObject(memBM);
            }
            DeleteObject(memDC);
          }
        } else {
          RETVAL = -3; // not supported format
        }
      } else {
        RETVAL = -2; // not supported bit
      }
    } else {
      RETVAL = -1; // cannot guess
    }
#else
    croak("FreeImage is not supported in this build!\n");
#endif
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#

int
_Printfile(printer, filename)
    char* printer;
    char* filename;
  CODE:
    RETVAL = printfile(printer, filename);
  OUTPUT:
    RETVAL

#------------------------------------------------------------------------------#
